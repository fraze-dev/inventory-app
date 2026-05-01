# USF Inventory Management System

A containerized inventory management web application built with Flask and MongoDB,
deployed on AWS EC2 using a fully automated Jenkins CI/CD pipeline.
Built as a final project for CIS 4930.

---

## Tools and Technologies

| Tool | Purpose |
|---|---|
| Flask | Python web framework serving the inventory application |
| MongoDB | NoSQL database storing product inventory data |
| Docker | Containerizes the Flask app for consistent deployments |
| Gunicorn | Production-grade WSGI server running the Flask app inside Docker |
| Jenkins | CI/CD pipeline automating build, verify, and deploy stages |
| Terraform | Infrastructure as Code provisioning the AWS EC2 instances |
| GitHub | Version control and source of truth for the pipeline |
| AWS EC2 | Cloud infrastructure hosting Jenkins, the app, and MongoDB |
| Docker Hub | Remote image registry storing built Flask app images |

---

## Architecture

```
GitHub → Jenkins → Docker Hub → App Server (EC2)
                                      ↕
                              MongoDB (EC2, internal only)
```

Three EC2 instances are provisioned via Terraform in AWS us-east-1:

- **Jenkins Server** — Runs the CI/CD pipeline on port 8080
- **App Server** — Hosts the Flask container on port 5000
- **MongoDB Server** — Runs MongoDB in Docker, accessible only within the VPC on port 27017

---

## App.py Routes

| Route | Method | Description |
|---|---|---|
| `/` | GET | Displays current inventory table |
| `/order` | GET, POST | Place an order, decrements stock |
| `/restock` | GET, POST | Restock a product, increments stock |

---

## Jenkins Pipeline Stages

1. **Checkout** — Pulls the latest code from GitHub
2. **Build** — Builds the Docker image and tags it with the build number and `latest`
3. **Verify** — Runs a test to confirm the container starts successfully
4. **Deploy** — Pushes the image to Docker Hub and SSHs into the app server to restart the container

---

## Project Structure

```
inventory-app/
├── app.py                  # Flask application and route definitions
├── Dockerfile              # Container build instructions using python:3.12-slim and Gunicorn
├── requirements.txt        # Python dependencies (Flask, PyMongo, Gunicorn)
├── docker-compose.yml      # Local development stack (Flask + MongoDB)
├── Jenkinsfile             # CI/CD pipeline definition
├── templates/
│   ├── index.html          # Inventory view
│   ├── order.html          # Order placement form
│   └── restock.html        # Restock form
├── main.tf                 # Terraform EC2 and security group definitions
├── variables.tf            # Terraform variable declarations
├── outputs.tf              # Terraform output values
└── terraform.tfvars        # Terraform variable values (not committed)
```

---

## Setup and Deployment

### Prerequisites
- AWS account with EC2 access
- Terraform installed
- Docker and Docker Hub account
- Jenkins instance with the following credentials configured:
  - `dockerhub-creds` — Docker Hub username and password
  - `app-server-ssh-key` — SSH private key for the app server
  - `app-server-ip` — App server public IP address

### 1. Provision Infrastructure
```bash
# Export AWS credentials
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret

# Initialize and apply Terraform
terraform init
terraform apply
```

### 2. Configure Jenkins
- Navigate to `http://<jenkins-ip>:8080`
- Install recommended plugins plus the SSH Agent plugin
- Add the credentials listed above to the Jenkins credentials store
- Create a pipeline job pointing to this GitHub repository

### 3. Run the Pipeline
- Trigger a build manually or push to the `main` branch
- Jenkins will build, verify, and deploy the app automatically
- Once complete, the app is live at `http://<app-server-ip>:5000`

### 4. Local Development (Optional)
```bash
# Create a .env file with your credentials first
cp .env.example .env

# Start the full stack locally
docker-compose up --build
```

---

## Security Notes

- MongoDB port 27017 is restricted to the VPC CIDR block and is not publicly accessible
- Jenkins credentials store is used for all secrets — no passwords are hardcoded in the pipeline
- Docker Compose credentials are managed via a `.env` file which is excluded from version control via `.gitignore`
- Hardcoded credentials in `main.tf` and `Jenkinsfile` are dev placeholders — production deployments should use AWS Secrets Manager

---

## Future Improvements

- Add Nginx with SSL/TLS for HTTPS support
