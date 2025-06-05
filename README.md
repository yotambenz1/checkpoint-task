## Overview 📝
This repository contains a complete solution for deploying two Python microservices (a Flask REST API and a worker) on AWS using ECS Fargate, S3, SQS, and an Application Load Balancer (ALB). Infrastructure is managed with Terraform.

---

## Prerequisites ⚡
- [Terraform](https://www.terraform.io/downloads.html) (v1.0+ recommended)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (configured with appropriate credentials)
- [Docker](https://docs.docker.com/get-docker/) (for building images)
- Python 3.8+

---

## Directory Structure 🗂️
```
.
├── apps/
│   ├── flask-app/
│   │   └── app.py
│   └── worker-app/
│       └── worker.py
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   │   └── main.tf
│   │   └── prod/
│   │       └── main.tf
│   └── modules/
│       ├── alb/
│       ├── ecs/
│       ├── s3/
│       ├── sqs/
│       └── ...
├── .github/
│   └── workflows/
│       └── pipeline.yaml
└── README.md
```
---
## Infrastructure Components 🛠️

### Networking (VPC Module) 🌐
- 🏗️ VPC with public and private subnets across two Availability Zones
- 🌉 NAT Gateway for private subnet internet access
- 🔒 Security groups for application and database access

### Compute (ECS Module) 🖥️
- 🐳 ECS Fargate cluster
- 🧩 Separate ECS services and task definitions for Flask app and worker app
- 🔑 IAM roles for task execution and resource access

### Load Balancing (ALB Module) ⚖️
- 🌐 Application Load Balancer (ALB) in public subnets
- 🎯 Target group forwarding to Flask app on ECS

### Storage (S3 Module) 🗄️
- 📦 S3 bucket for storing processed email data

### Messaging (SQS Module) 📬
- 📨 FIFO SQS queue for decoupling API and worker
- 🛑 Dead-letter queue (DLQ) for failed messages

### Parameter Store (SSM Module) 🔒
- 🔐 SSM Parameter Store for securely storing API tokens

---

## Setup Instructions 🧰

### 1. Clone the Repository 🌀
```sh
git clone <your-repo-url>
cd checkpoint-task
```

### 2. Configure AWS Credentials 🔑
Ensure your AWS CLI is configured:
```sh
aws configure
```

### 3. Bootstrap Step 🚀
Before deploying the main infrastructure, you may need to bootstrap your AWS account for Terraform state management (e.g., S3 backend, DynamoDB table for state locking).

#### Example Bootstrap
```sh
cd terraform/bootstrap
terraform init
terraform apply
```
- 🪣 This will create the S3 bucket and DynamoDB table for remote state and locking.
- 📝 Update your `backend` configuration in environment Terraform files as needed.

### 4. Build and Push Docker Images 🐳
You need to build your Docker images locally and push them to your AWS ECR repositories.  
**Replace** `<account-id>`, `<region>`, and `<repo>` with your actual AWS account ID, region, and ECR repository names.

#### 1. Authenticate Docker to ECR
```sh
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
```

#### 2. Build Images
```sh
# Flask app
docker build -t flask-app:latest ./apps/flask-app
# Worker app
docker build -t worker-app:latest ./apps/worker-app
```

#### 3. Tag Images
```sh
docker tag flask-app:latest <account-id>.dkr.ecr.<region>.amazonaws.com/flask-app:latest
docker tag worker-app:latest <account-id>.dkr.ecr.<region>.amazonaws.com/worker-app:latest
```

#### 4. Push Images to ECR
```sh
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/flask-app:latest
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/worker-app:latest
```

> **Note:**
> - 🏷️ Make sure your ECR repositories (`flask-app` and `worker-app`) exist. You can create them with:
>   ```sh
>   aws ecr create-repository --repository-name flask-app --region <region>
>   aws ecr create-repository --repository-name worker-app --region <region>
>   ```
> - 🚫 If you get a `denied: requested access to the resource is denied` error, check your IAM permissions and repository names.

### 5. Deploy Infrastructure with Terraform 🌍
```sh
cd terraform/environments/dev  # or prod
terraform init
terraform apply
```

This will provision the VPC, ALB, ECS cluster/services, S3, SQS, and SSM parameter.

---

## Environment Variables 🌱
Environment variables for each service are set via the ECS task definition in Terraform. For local development, you can use a `.env` file in each app directory.

**Flask app:**
- 📬 `SQS_QUEUE_URL` – SQS queue URL
- 🔒 `TOKEN_PARAM_NAME` – SSM parameter name for the token
- 🌎 `AWS_REGION` – AWS region

**Worker app:**
- 📬 `SQS_QUEUE_URL` – SQS queue URL
- 🗄️ `S3_BUCKET` – S3 bucket name
- 🌎 `AWS_REGION` – AWS region
- 📁 `S3_PREFIX` – S3 key prefix (default: `emails/`)
- ⏲️ `POLL_INTERVAL` – Polling interval in seconds (default: `10`)

---

## Running Locally (for testing) 🧪

### Flask App
```sh
cd apps/flask-app
pip install -r requirements.txt
export SQS_QUEUE_URL=...  # Set your test SQS URL
export TOKEN_PARAM_NAME=...  # Set your test SSM parameter name
export AWS_REGION=us-west-2
python app.py
```

### Worker App
```sh
cd apps/worker-app
pip install -r requirements.txt
export SQS_QUEUE_URL=...  # Set your test SQS URL
export S3_BUCKET=...      # Set your test S3 bucket
export AWS_REGION=us-west-2
python worker.py
```

---

## Testing the Solution 🧪
- **API:** Send a POST request to the ALB endpoint `/email` with a JSON payload as described in the Flask app.
- **Worker:** The worker will automatically poll SQS and upload messages to S3.

---

## Pipeline Workflow (CI/CD) 🚀

This repository includes a GitHub Actions workflow for Continuous Integration and Continuous Deployment (CI/CD), located at `.github/workflows/pipeline.yaml`.

### What the Pipeline Does 🛠️
- 🐳 **Builds Docker images** for both the Flask app and the worker app.
- 🔐 **Authenticates to AWS ECR** and pushes the latest images to the appropriate ECR repositories.
- 📥 **Downloads the current ECS task definition** and updates it with the new image tags.
- 🔄 **Registers the new ECS task definition** and triggers a new deployment of the ECS service, ensuring the latest code is running in your cluster.
- ✅ **Runs on push or pull request** to main branches, automating the deployment process.

### How It Fits Into Deployment 📦
- ⏩ When you push changes to the repository (e.g., after merging a feature branch), the pipeline automatically builds and deploys your updated microservices to AWS ECS.
- 🔄 This ensures that your infrastructure and application code are always in sync and up-to-date with the latest changes.

### Customization ⚙️
- 🧪 You can modify the workflow file to add steps for testing, linting, or other deployment environments as needed.
- 🔑 Make sure your GitHub repository secrets are configured with the necessary AWS credentials for deployment.

---

## Cleanup 🧹
To destroy all resources:
```sh
cd terraform/environments/dev  # or prod
terraform destroy
```

---

## Troubleshooting 🆘

### Common Issues
- 🔒 **State locking conflicts:** Check the DynamoDB table used for state locking. Release any stuck locks before retrying.
- 🛂 **Permission issues:** Verify your AWS credentials and IAM permissions. Ensure your user/role can create and manage all required AWS resources.
- 🌐 **Network issues:** Check security group rules and VPC/subnet settings. Ensure resources are in the correct subnets and have the necessary access.
- 🐳 **Image pull errors:** Make sure your ECS task role has access to ECR and that images are pushed to the correct repository.
- 🔑 **SSM parameter not found:** Confirm the parameter name and value are set correctly in Terraform and exist in AWS SSM Parameter Store.

---

## Notes 💡
- For production, use secure values for tokens and secrets.
- Review and update the Terraform variables as needed for your environment.