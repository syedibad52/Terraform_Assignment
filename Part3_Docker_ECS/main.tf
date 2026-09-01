terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Fetch Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# -------------------------------------------------------------
# VPC and Networking Setup (Multi-AZ for ALB)
# -------------------------------------------------------------
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "part3-ecs-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "part3-igw"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "part3-public-subnet-a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "part3-public-subnet-b"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "part3-public-rt"
  }
}

resource "aws_route_table_association" "assoc_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "assoc_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# -------------------------------------------------------------
# Security Groups
# -------------------------------------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "part3-alb-sg"
  description = "Allow public inbound HTTP traffic to ALB"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "HTTP Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Express Port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask Port 5000"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "part3-alb-sg"
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "part3-ecs-sg"
  description = "Allow inbound traffic to ECS tasks ONLY from ALB"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description     = "Express Port 3000 from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "Flask Port 5000 from ALB"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "part3-ecs-sg"
  }
}

# -------------------------------------------------------------
# ECR Repositories
# -------------------------------------------------------------
resource "aws_ecr_repository" "flask" {
  name                 = "flask-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "flask-backend-ecr"
  }
}

resource "aws_ecr_repository" "express" {
  name                 = "express-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "express-frontend-ecr"
  }
}

# -------------------------------------------------------------
# Application Load Balancer & Target Groups
# -------------------------------------------------------------
resource "aws_lb" "main_alb" {
  name               = "part3-main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]

  tags = {
    Name = "part3-main-alb"
  }
}

resource "aws_lb_target_group" "express_tg" {
  name        = "part3-express-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "flask_tg" {
  name        = "part3-flask-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

# ALB Listeners
resource "aws_lb_listener" "http_80" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.express_tg.arn
  }
}

resource "aws_lb_listener" "express_3000" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.express_tg.arn
  }
}

resource "aws_lb_listener" "flask_5000" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = 5000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_tg.arn
  }
}

# -------------------------------------------------------------
# IAM Role for ECS Execution
# -------------------------------------------------------------
resource "aws_iam_role" "ecs_execution_role" {
  name = "part3_ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -------------------------------------------------------------
# ECS Cluster, Task Definitions, and Services
# -------------------------------------------------------------
resource "aws_ecs_cluster" "main_cluster" {
  name = "part3-ecs-cluster"
}

resource "aws_ecs_task_definition" "flask_task" {
  family                   = "flask-backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name      = "flask-backend"
    image     = "${aws_ecr_repository.flask.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = var.flask_container_port
      hostPort      = var.flask_container_port
    }]
  }])
}

resource "aws_ecs_task_definition" "express_task" {
  family                   = "express-frontend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name      = "express-frontend"
    image     = "${aws_ecr_repository.express.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = var.express_container_port
      hostPort      = var.express_container_port
    }]
    environment = [{
      name  = "BACKEND_URL"
      value = "http://${aws_lb.main_alb.dns_name}:5000"
    }]
  }])
}

resource "aws_ecs_service" "flask_service" {
  name            = "flask-backend-service"
  cluster         = aws_ecs_cluster.main_cluster.id
  task_definition = aws_ecs_task_definition.flask_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.flask_tg.arn
    container_name   = "flask-backend"
    container_port   = var.flask_container_port
  }

  depends_on = [aws_lb_listener.flask_5000]
}

resource "aws_ecs_service" "express_service" {
  name            = "express-frontend-service"
  cluster         = aws_ecs_cluster.main_cluster.id
  task_definition = aws_ecs_task_definition.express_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.express_tg.arn
    container_name   = "express-frontend"
    container_port   = var.express_container_port
  }

  depends_on = [aws_lb_listener.express_3000, aws_lb_listener.http_80]
}
