# main.tf
# Terraform configuration for cis4930 final project.
# Provisions three EC2 instances on AWS: Jenkins, App Server, and MongoDB.
# Amazon Linux 2 in us-east-1.

terraform {
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

# --- SSH Key Pair ---
resource "aws_key_pair" "inventory_key" {
  key_name   = "inventory-app-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKqB9yM8VwCqtzBX6WqsG29SuILa5ZzL/YByax1u4pcA aaron.fraze2@gmail.com"
}

# --- Security Group: Jenkins ---
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Jenkins server security group"

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Security Group: App Server ---
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Flask app server security group"

  ingress {
    description = "HTTP public"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask direct access"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32", "172.31.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Security Group: MongoDB ---
resource "aws_security_group" "mongo_sg" {
  name        = "mongo-sg"
  description = "MongoDB server security group"

  ingress {
    description = "MongoDB from app server"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- EC2: Jenkins ---
resource "aws_instance" "jenkins" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2 us-east-1
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.inventory_key.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker git
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    # Install Jenkins
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    yum install -y java-17-amazon-corretto jenkins
    systemctl start jenkins
    systemctl enable jenkins

    # Allow Jenkins to use Docker
    usermod -aG docker jenkins
    systemctl restart jenkins
  EOF

  tags = {
    Name = "inventory-jenkins"
  }
}

# --- EC2: App Server ---
resource "aws_instance" "app" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.inventory_key.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
  EOF

  tags = {
    Name = "inventory-app"
  }
}

# --- EC2: MongoDB ---
resource "aws_instance" "mongodb" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.inventory_key.key_name
  vpc_security_group_ids = [aws_security_group.mongo_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    # Start MongoDB container
    docker run -d \
      --name mongo \
      --restart always \
      -p 27017:27017 \
      -e MONGO_INITDB_ROOT_USERNAME=admin \
      -e MONGO_INITDB_ROOT_PASSWORD=${var.mongo_root_password} \
      -v mongo_data:/data/db \
      mongo:7
  EOF

  tags = {
    Name = "inventory-mongodb"
  }
}