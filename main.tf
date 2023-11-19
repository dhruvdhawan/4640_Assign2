provider "aws" {
  # Define your region, e.g. "us-east-1"
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "a02_vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "a02_vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "a02_igw" {
  vpc_id = aws_vpc.a02_vpc.id

  tags = {
    Name = "a02_igw"
  }
}

# Create a Public Subnet
resource "aws_subnet" "a02_pub_subnet" {
  vpc_id            = aws_vpc.a02_vpc.id
  cidr_block        = "192.168.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "a02_pub_subnet"
  }
}

# Create a Private Subnet
resource "aws_subnet" "a02_priv_subnet" {
  vpc_id     = aws_vpc.a02_vpc.id
  cidr_block = "192.168.1.0/24"

  tags = {
    Name = "a02_priv_subnet"
  }
}

# Create a Route Table and associate it with the public subnet
resource "aws_route_table" "a02_route_table" {
  vpc_id = aws_vpc.a02_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.a02_igw.id
  }

  tags = {
    Name = "a02_route_table"
  }
}

resource "aws_route_table_association" "a02_rta_pub" {
  subnet_id      = aws_subnet.a02_pub_subnet.id
  route_table_id = aws_route_table.a02_route_table.id
}

# Create a Public Security Group
resource "aws_security_group" "a02_pub_sg" {
  name        = "a02_pub_sg"
  description = "Public security group for web access"
  vpc_id      = aws_vpc.a02_vpc.id

  # Allow HTTP and HTTPS inbound traffic from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH inbound traffic from specific IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["207.23.215.100/32"] # Replace with your actual IP address
  }

  # Default egress rule: Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a Private Security Group
resource "aws_security_group" "a02_priv_sg" {
  name        = "a02_priv_sg"
  description = "Private security group for backend and database"
  vpc_id      = aws_vpc.a02_vpc.id

  # Allow internal communication within the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Default egress rule: Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a Web EC2 Instance
resource "aws_instance" "a02_web" {
  ami           = "ami-0e83be366243f524a"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.a02_pub_subnet.id
  key_name      = "my_key_2" # Replace with your actual key pair name
  vpc_security_group_ids = [aws_security_group.a02_pub_sg.id]

  tags = {
    Name = "a02_web_ec2_instance"
  }
}

# Create a Backend EC2 Instance
resource "aws_instance" "a02_backend" {
  ami           = "ami-0e83be366243f524a"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.a02_priv_subnet.id
  key_name      = "my_key_2" # Replace with your actual key pair name
  vpc_security_group_ids = [aws_security_group.a02_priv_sg.id]

  tags = {
    Name = "a02_backend_ec2_instance"
  }
}

# Create a DB EC2 Instance
resource "aws_instance" "a02_db" {
  ami           = "ami-0e83be366243f524a"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.a02_priv_subnet.id
  key_name      = "my_key_2" # Replace with your actual key pair name
  vpc_security_group_ids = [aws_security_group.a02_priv_sg.id]

  tags = {
    Name = "a02_db_ec2_instance"
  }
}

# Output blocks to display the public IP and private IPs of instances
output "web_instance_public_ip" {
  value = aws_instance.a02_web.public_ip
}

output "backend_instance_private_ip" {
  value = aws_instance.a02_backend.private_ip
}

output "db_instance_private_ip" {
  value = aws_instance.a02_db.private_ip
}

