terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }
  }
  required_version = ">= 1.3.0"
}

# Define Variables the values are outside this file 
variable "aws_region" {
  description = "AWS region"
  default     = "us-west-2"
}

variable "project_name" {
  description = "Assignment2"
  default = "Assignment2"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  default     = "192.168.0.0/16"
}

variable "priv_subnet_cidr" {
  description = "a02_priv_subnet"
  default     = "192.168.1.0/24"
}

variable "pub_subnet_cidr" {
  description = "a02_pub_subnet"
  default     = "192.168.2.0/25"
}

variable "default_route"{
  description = "Default route"
  default     = "0.0.0.0/0"
}

variable "home_net" {
  description = "Home network"
  # default     = "192.168.1.0/24"
  default     = "24.85.106.4/32"
}

variable "bcit_net" {
  description = "BCIT network"
  default     = "142.232.0.0/16"
  
}

variable "ami_id" {
  description = "AMI ID"
  default = "ami-04203cad30ceb4a0c"
}

variable "ssh_key_name"{
  description = "AWS SSH key name"
  default = "acit_4640"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "a02_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true
  tags = {
    Name    = "a02_vpc"
    Project = var.project_name
  }
}

resource "aws_subnet" "a02_priv_subnet" {
  vpc_id                  = aws_vpc.a02_vpc.id
  cidr_block              = var.priv_subnet_cidr
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name    = "a02_priv_subnet"
    Project = var.project_name
  }
}

resource "aws_subnet" "a02_pub_subnet" {
  vpc_id                  = aws_vpc.a02_vpc.id
  cidr_block              = var.pub_subnet_cidr
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name    = "a02_pub_subnet"
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "a02_internet_gateway" {
  vpc_id = aws_vpc.a02_vpc.id
  tags = {
    Name    = "a02_internet_gateway"
    Project = var.project_name
  }
}

resource "aws_route_table" "a02_route_table" {
  vpc_id = aws_vpc.a02_vpc.id

  route {
    cidr_block = var.default_route
    gateway_id = aws_internet_gateway.a02_internet_gateway.id
  }

  tags = {
    Name    = "a02_route_table"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "web_rt_assoc_pub" {
  subnet_id      = aws_subnet.a02_pub_subnet.id
  route_table_id = aws_route_table.a02_route_table.id
}

resource "aws_route_table_association" "web_rt_assoc_priv" {
  subnet_id      = aws_subnet.a02_priv_subnet.id
  route_table_id = aws_route_table.a02_route_table.id
}

resource "aws_security_group" "a02_priv_sg" {
  name        = "a02_priv_sg"
  description = "Allow http and ssh access to ec2 from home and bcit and allow all traffic from a02_pub_sg"
  vpc_id      = aws_vpc.a02_vpc.id
}

resource "aws_vpc_security_group_egress_rule" "priv_egress_rule" {
  security_group_id = aws_security_group.a02_priv_sg.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name    = "a02_priv_sg"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "priv_ssh_home_rule" {
  security_group_id = aws_security_group.a02_priv_sg.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.home_net
  tags = {
    Name    = "a02_priv_sg"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "priv_ssh_bcit_rule" {
  security_group_id = aws_security_group.a02_priv_sg.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.bcit_net
  tags = {
    Name    = "a02_priv_sg"
    Project = var.project_name
  }
}

resource "aws_security_group" "a02_pub_sg" {
  name        = "a02_pub_sg"
  description = "Allow http and ssh access to ec2 from home and bcit and allow all traffic from a02_priv_sg"
  vpc_id      = aws_vpc.a02_vpc.id
}

resource "aws_vpc_security_group_egress_rule" "pub_egress_rule" {
  security_group_id = aws_security_group.a02_pub_sg.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name    = "a02_pub_sg"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "pub_port_443_rule" {
  security_group_id = aws_security_group.a02_pub_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name    = "a02_pub_sg"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "pub_port_80_rule" {
  security_group_id = aws_security_group.a02_pub_sg.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name    = "a02_pub_sg"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "pub_ssh_bcit_rule" {
  security_group_id = aws_security_group.a02_pub_sg.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.bcit_net
  tags = {
    Name    = "a02_pub_sg"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "pub_ssh_home_rule" {
  security_group_id = aws_security_group.a02_pub_sg.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.home_net
  tags = {
    Name    = "a02_pub_sg"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "pub_allow_priv_rule" {
  security_group_id = aws_security_group.a02_pub_sg.id
  ip_protocol       = "-1"
  from_port         = 0
  to_port           = 0
  # cidr_ipv4         = var.home_net
  referenced_security_group_id = aws_security_group.a02_priv_sg.id
  description = "Allow all traffic from a02_priv_sg"
  tags = {
    Name    = "a02_pub_sg"
    Project = var.project_name
  }
}


resource "aws_vpc_security_group_ingress_rule" "priv_allow_pub_rule" {
  security_group_id = aws_security_group.a02_priv_sg.id
  ip_protocol       = "-1"
  from_port         = 0
  to_port           = 0
  # cidr_ipv4         = var.home_net
  referenced_security_group_id = aws_security_group.a02_pub_sg.id
  description = "Allow all traffic from a02_pub_sg"
  tags = {
    Name    = "a02_priv_sg"
    Project = var.project_name
  }
}

resource "aws_instance" "a02_backend" {
  ami             = var.ami_id
  instance_type   = "t2.micro"
  key_name        = var.ssh_key_name
  subnet_id       = aws_subnet.a02_priv_subnet.id
  security_groups = [aws_security_group.a02_priv_sg.id]
  associate_public_ip_address = true
  tags = {
    Name    = "a02_backend"
    Project = var.project_name
    # Type = "demo"
  }
}

resource "aws_instance" "a02_db" {
  ami             = var.ami_id
  instance_type   = "t2.micro"
  key_name        = var.ssh_key_name
  subnet_id       = aws_subnet.a02_priv_subnet.id
  security_groups = [aws_security_group.a02_priv_sg.id]
  associate_public_ip_address = true
  tags = {
    Name    = "a02_db"
    Project = var.project_name
    # Type = "demo"
  }
}

resource "aws_instance" "a02_web" {
  ami             = var.ami_id
  instance_type   = "t2.micro"
  key_name        = var.ssh_key_name
  subnet_id       = aws_subnet.a02_pub_subnet.id
  security_groups = [aws_security_group.a02_pub_sg.id]
  associate_public_ip_address = true
  tags = {
    Name    = "a02_web"
    Project = var.project_name
    # Type = "demo"
  }
}

resource "local_file" "webservers" {

  content = <<EOF

all:
  vars:
    priv_db_ip_address: "${aws_instance.a02_db.private_ip}"
    pub_db_ip_address: "${aws_instance.a02_db.public_ip}"
    priv_backend_ip_address: "${aws_instance.a02_backend.private_ip}"

backend:
  hosts:
    ${aws_instance.a02_backend.public_dns}

web:
  hosts:
    ${aws_instance.a02_web.public_dns}

db:
  hosts:
    ${aws_instance.a02_db.public_dns}
EOF

  filename = "../service/inventory/webservers.yml"

}

# resource "local_file" "web" {

#   content = <<EOF
# webservers:
#   hosts:
#     ${aws_instance.a02_web.public_dns}
# EOF

#   filename = "../service/inventory/web.yml"

# }

# resource "local_file" "db" {

#   content = <<EOF
# webservers:
#   hosts:
#     ${aws_instance.a02_db.public_dns}
# EOF

#   filename = "../service/inventory/db.yml"

# }

# resource "local_file" "inventory_file" {
#   content = templatefile("${path.module}/templates/inventory.tpl", {
#     backend_instance_dns = aws_instance.a02_backend.public_dns
#     web_instance_dns = aws_instance.a02_web.public_dns
#     backend_instance_dns = aws_instance.a02_backend.public_dns
#   })

#   filename = "../service/inventory/ec2_inventory.yml"
# }

# # https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file
# resource "local_file" "backend_file" {

#   content = <<EOF
# ec2_instance_public_dns: ${aws_instance.a02_backend.public_dns}
# EOF

#   filename = "backend_file.yml"

# }

# # https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file
# resource "local_file" "script_file" {

#   content = <<EOF
# ec2_instance_id="${aws_instance.a02_backend.id}"
# EOF

#   filename = "backend_script.sh"

# }