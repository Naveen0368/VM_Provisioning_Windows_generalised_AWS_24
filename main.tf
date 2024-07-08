provider "aws" {
  region     = "us-west-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

variable "instance_name" {
  type        = string
  description = "Name of the EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "storage_type" {
  type        = string
  description = "EBS volume type"
  default     = "gp2"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "key_name" {
  type        = string
  description = "Name of the existing key pair to use"
}

variable "aws_access_key" {
  type        = string
  description = "AWS Access Key"
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret Key"
  sensitive   = true
}

# Create a VPC
resource "aws_vpc" "custom_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = var.vpc_name
  }
}

# Create a subnet
resource "aws_subnet" "custom_subnet" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "${var.vpc_name}-subnet"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "custom_igw" {
  vpc_id = aws_vpc.custom_vpc.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# Create a route table
resource "aws_route_table" "custom_route_table" {
  vpc_id = aws_vpc.custom_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custom_igw.id
  }
  tags = {
    Name = "${var.vpc_name}-route-table"
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "custom_route_table_association" {
  subnet_id      = aws_subnet.custom_subnet.id
  route_table_id = aws_route_table.custom_route_table.id
}

# Create a security group
resource "aws_security_group" "custom_security_group" {
  vpc_id = aws_vpc.custom_vpc.id
  ingress {
    from_port   = 3389
    to_port     = 3389
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
    Name = "${var.vpc_name}-security-group"
  }
}

# Create an EC2 instance
resource "aws_instance" "custom_instance" {
  ami                    = "ami-07e278fe6c43b6aba" # Windows Server AMI
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.custom_subnet.id
  vpc_security_group_ids = [aws_security_group.custom_security_group.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type = var.storage_type
    volume_size = 30 # Windows instances typically require larger root volumes
  }

  tags = {
    Name = var.instance_name
  }
}

output "vpc_id" {
  value = aws_vpc.custom_vpc.id
}

output "subnet_id" {
  value = aws_subnet.custom_subnet.id
}

output "instance_id" {
  value = aws_instance.custom_instance.id
}

output "public_ip" {
  value = aws_instance.custom_instance.public_ip
}
