# Terraform AWS Microservices Deployment Assignment

This project contains complete, human-readable Terraform Infrastructure as Code (IaC) configurations and application source files to deploy a **Flask Backend API** (Python, Port 5000) and an **Express Frontend UI** (Node.js, Port 3000) across three progressive AWS deployment architectures.

---

## Architecture Flowcharts

### Part 1: Single EC2 Instance Architecture
Both Flask backend (Port 5000) and Express frontend (Port 3000) run on a single EC2 instance provisioned via Terraform and initialized with `user_data.sh`.

```text
               +----------------------------------+
               |        AWS Cloud / VPC           |
               |                                  |
[ User ] ----->|   EC2 Instance (Ubuntu 22.04)    |
               |   +--------------------------+   |
  Port 3000 -->|   |  Express Frontend (3000) |   |
               |   +--------------------------+   |
  Port 5000 -->|   |  Flask Backend API (5000)|   |
               |   +--------------------------+   |
               +----------------------------------+
```

---

### Part 2: Decoupled EC2 Instances in Custom VPC
Flask backend and Express frontend are deployed on separate EC2 instances in a custom VPC. Security groups restrict Flask backend access so it accepts requests from the Express frontend security group.

```text
                               +---------------------------------------------------+
                               | VPC (10.0.0.0/16)                                 |
                               |                                                   |
[ User ] ---> (Port 3000) ---->|  +---------------------+   (5000)   +---------------+
                               |  | Express Frontend    |----------->| Flask Backend |
                               |  | Security Group      |  Private   | Sec Group     |
                               |  +---------------------+    IP      +---------------+
                               +---------------------------------------------------+
```

---

### Part 3: Containerized Microservices on ECS Fargate behind ALB
Flask backend and Express frontend are packaged into Docker containers, pushed to AWS ECR, and managed by ECS Fargate services. An Application Load Balancer (ALB) routes public traffic across Availability Zones.

```text
                                  +-----------------------------------------------------+
                                  | AWS VPC (Multi-AZ)                                  |
                                  |                                                     |
[ User ] ---> (Ports 80/3000/5000)-->  Application Load Balancer (ALB)                 |
                                  |            /                 \                      |
                                  |           /                   \                     |
                                  |          v                     v                    |
                                  |   Express Target Group    Flask Target Group        |
                                  |       (Port 3000)             (Port 5000)           |
                                  |            |                       |                |
                                  |            v                       v                |
                                  |   +-----------------+     +-----------------+       |
                                  |   | ECS Task        |     | ECS Task        |       |
                                  |   | (Express Container)|  | (Flask Container)       |
                                  |   +-----------------+     +-----------------+       |
                                  +-----------------------------------------------------+
```

---

## Directory Structure

```text
Terraform_Assignment/
├── Part1_Single_EC2/
│   ├── main.tf              # Single EC2 instance & security group definition
│   ├── variables.tf         # Region and instance configuration
│   ├── outputs.tf           # EC2 public IP and access URLs
│   └── user_data.sh         # Shell script to install dependencies and run apps
│
├── Part2_Separate_EC2/
│   ├── main.tf              # Custom VPC, 2 EC2 instances, and 2 security groups
│   ├── variables.tf         # Network and EC2 variables
│   ├── outputs.tf           # Frontend/Backend IPs and application URLs
│   ├── user_data_flask.sh   # Automated Flask backend setup
│   └── user_data_express.sh.tftpl # Templated Express frontend setup
│
├── Part3_Docker_ECS/
│   ├── main.tf              # Multi-AZ VPC, ECR repos, ALB, ECS Cluster & Fargate Services
│   ├── variables.tf         # Port definitions and AWS region
│   ├── outputs.tf           # ECR Repository URLs and ALB DNS endpoint
│   ├── backend/             # Python Flask microservice source
│   │   ├── app.py           # Flask REST API code
│   │   ├── requirements.txt # Python package dependencies
│   │   └── Dockerfile       # Docker container manifest for Flask
│   └── frontend/            # Node.js Express web application source
│       ├── server.js        # Express application server
│       ├── package.json     # Node package manifest
│       └── Dockerfile       # Docker container manifest for Express
│
├── backend.tf.example       # Example S3 backend configuration for state locking
└── README.md                # Project documentation and execution guide
```

---

## Prerequisites

Before deploying any part of this project, ensure you have the following installed on your machine:
1. **Terraform CLI** (v1.0.0 or higher)
2. **AWS CLI** (v2.0 or higher) configured with credentials (`aws configure`)
3. **Docker Desktop** running locally (required for Part 3)

Verify your AWS CLI login credentials:
```bash
aws sts get-caller-identity
```

---

## Deployment Instructions

### Part 1: Deploying on a Single EC2 Instance

1. Navigate to the Part 1 directory:
   ```bash
   cd Part1_Single_EC2
   ```

2. Initialize Terraform providers:
   ```bash
   terraform init
   ```

3. Generate and review the execution plan:
   ```bash
   terraform plan
   ```

4. Apply the configuration to create the EC2 instance:
   ```bash
   terraform apply
   ```

5. Verify output:
   After deployment, Terraform will print `express_frontend_url` and `flask_backend_url`.

---

### Part 2: Deploying on Separate EC2 Instances in VPC

1. Navigate to the Part 2 directory:
   ```bash
   cd Part2_Separate_EC2
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the execution plan:
   ```bash
   terraform plan
   ```

4. Deploy the infrastructure:
   ```bash
   terraform apply
   ```

5. Verification:
   Open your browser and navigate to `http://<express_frontend_public_ip>:3000` to test connection to the Flask backend.

---

### Part 3: Deploying Containerized Microservices on ECS Fargate

1. Navigate to the Part 3 directory:
   ```bash
   cd Part3_Docker_ECS
   ```

2. Initialize Terraform and create AWS resources (VPC, ECR repos, ALB, ECS Cluster):
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. Authenticate Docker with your AWS ECR Registry:
   ```bash
   # Replace <AWS_ACCOUNT_ID> and <AWS_REGION> with your actual details
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
   ```

4. Build and Push the Flask Backend Docker Image:
   ```bash
   cd backend
   docker build -t flask-backend .
   docker tag flask-backend:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/flask-backend:latest
   docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/flask-backend:latest
   cd ..
   ```

5. Build and Push the Express Frontend Docker Image:
   ```bash
   cd frontend
   docker build -t express-frontend .
   docker tag express-frontend:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/express-frontend:latest
   docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/express-frontend:latest
   cd ..
   ```

6. Refresh ECS Service Deployment:
   ```bash
   terraform apply
   ```

---

## Deployment Verification

You can test your live endpoints using `curl` or in a web browser:

```bash
# Test Express Frontend
curl -i http://<ALB_DNS_NAME>:3000/health

# Test Flask Backend
curl -i http://<ALB_DNS_NAME>:5000/health

# Test Frontend to Backend Integration
curl -i http://<ALB_DNS_NAME>:3000/api-check
```

---

## Terraform State Management (S3 Backend)

To use remote state management as required by AWS DevOps best practices, see `backend.tf.example`. You can enable it in any directory by adding a `backend.tf` file:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "devops-assignment/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}
```

---

## Teardown / Cleanup Instructions

To remove all AWS resources and prevent unwanted charges:

```bash
# Part 3 Cleanup
cd Part3_Docker_ECS && terraform destroy -auto-approve

# Part 2 Cleanup
cd ../Part2_Separate_EC2 && terraform destroy -auto-approve

# Part 1 Cleanup
cd ../Part1_Single_EC2 && terraform destroy -auto-approve
```

---

## Note for Submission & Verification Screenshots

When submitting your assignment doc:
1. Run `terraform plan` and `terraform apply` in your terminal for Part 1, Part 2, and Part 3.
2. Capture real screenshots of your terminal showing the successfully applied Terraform resources and output variables (`ec2_public_ip`, `alb_dns_name`).
3. Include screenshots of `curl` or browser output showing the response from both applications.
