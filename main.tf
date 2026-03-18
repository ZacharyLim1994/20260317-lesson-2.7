# 20260317-lesson-2.7 assignment

# backend

terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.36.0"
    }
  }
  backend "s3" {
    bucket = "sctp-ce12-tfstate-bucket"        #Change to your S3 bucket name, e.g. sctp-ce12-tfstate-bucket
    key    = "zaclim-sctp-ce12-mod2_7.tfstate" #Path within the bucket, e.g. ec2-example/terraform.tfstate. REMEMBER TO CHANGE THE FILENAME TO YOUR OWN, e.g. zaclim-sctp-ce12-mod2_2.tfstate
    region = "ap-southeast-1"                  #Change to your S3 bucket region, e.g., ap-southeast-1
  }
}

# ----------------------------------------------------------------------

# Providers
provider "aws" {
  region = "ap-southeast-1"
}

# ----------------------------------------------------------------------

# Data
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["ce-learner-vpc"] # to be replaced with your VPC name
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-6.1-x86_64"] # Amazon Linux 2023 AMI
  }
  owners = ["amazon"] # Only consider AMIs owned by Amazon
}

data "aws_subnets" "example" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

# ----------------------------------------------------------------------
# Variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# ----------------------------------------------------------------------

# Resources

resource "aws_instance" "public" {

  ami                         = data.aws_ami.amazon_linux.id    #Amazon Linux 2023 AMI ID, e.g. ami-xxxxxxxxxxxx
  instance_type               = var.instance_type               #EC2 instance type, e.g. t2.micro
  subnet_id                   = data.aws_subnets.example.ids[0] #Public Subnet ID, e.g. subnet-xxxxxxxxxxx
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  key_name                    = "zaclim-assign2_7" # to be replaced with your key pair name 

  tags = {
    Name = "zaclim-2.7-assignment" #Prefix your own name, e.g. jazeel-ec2-dev-1
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "zaclim-tf-sg" #Security group name, e.g. jazeel-terraform-security-group
  description = "Allow SSH inbound"
  vpc_id      = data.aws_vpc.selected.id #VPC ID (Same VPC as your EC2 subnet above), E.g. vpc-xxxxxxx
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


resource "aws_ebs_volume" "my_ebs" {
  availability_zone = aws_instance.public.availability_zone
  size              = 1

  tags = {
    Name = "zachary-ebs"
  }
}

resource "aws_volume_attachment" "my_ebs_attach" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.my_ebs.id
  instance_id = aws_instance.public.id
}

# ----------------------------------------------------------------------

output "my_vpc_id" {
  value = data.aws_vpc.selected.id
}

output "ami_id" {
  value = data.aws_ami.amazon_linux.id
}

output "subnet_ids" {
  value = data.aws_subnets.example.ids
}

output "public_dns" {
  value = aws_instance.public[*].public_dns # Get the Public DNS of the instance that you just created.
}

output "instance_id" {
  value = aws_instance.public.id
}
