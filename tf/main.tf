provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

/* Virtual Private Cloud */
resource "aws_vpc" "marvin" {
  cidr_block            = "172.32.0.0/16"
  instance_tenancy      = "default"
  enable_dns_hostnames  = "true"

  tags = {
    Name = "marvin"
  }
}

/* Subnet for the VPC */
resource "aws_subnet" "marvin" {
  vpc_id                  = aws_vpc.marvin.id
  cidr_block              = "172.32.0.0/20"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "marvin"
  }
}

/* Security Group with Inbount and Outbound Rules */
resource "aws_security_group" "marvin" {
  name        = "allow_some_ports"
  description = "Allow inbound/outbound traffic"
  vpc_id      = aws_vpc.marvin.id

  ingress {
    description = "TLS from any to nginx"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Web from any to nginx"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Web from any to jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Grafana Monitoring"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow from mine"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["191.185.112.43/32"]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

/* Auto-Scaling for reliability */
resource "aws_autoscaling_group" "marvin" {
  vpc_zone_identifier = [aws_subnet.marvin.id]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = aws_launch_template.marvin.id
    version = "$Latest"
  }
}

/* Ubuntu Template */
resource "aws_launch_template" "marvin" {
  name_prefix            = "marvin"
  image_id               = "ami-0ac80df6eff0e70b5"
  instance_type          = "t2.micro"
  key_name               = "herculano-certified"
  vpc_security_group_ids = [aws_security_group.marvin.id]
  iam_instance_profile {
    name = "marvin_profile"
  }
}

/* Internet Gateway for the instances in the Subnet going to the internet */
resource "aws_internet_gateway" "marvin" {
  vpc_id = aws_vpc.marvin.id

  tags = {
    Name = "marvin_internet_gateway"
  }
}

/* Egress Only Internet Gateway */
resource "aws_egress_only_internet_gateway" "marvin" {
  vpc_id = aws_vpc.marvin.id

  tags = {
    Name = "marvin_egress_only_internet_gateway"
  }
}

/* Route Table to receive make the instances reacheable */
resource "aws_route_table" "marvin" {
  vpc_id = aws_vpc.marvin.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.marvin.id
  }
  
    route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.marvin.id
  }

  tags = {
    Name = "marvin_route_table"
  }
}

/* Association subnet with route table */
resource "aws_route_table_association" "marvin" {
  subnet_id      = aws_subnet.marvin.id
  route_table_id = aws_route_table.marvin.id
}

/* Network Interface with two private_ips */
resource "aws_network_interface" "marvin" {
  subnet_id   = aws_subnet.marvin.id
  private_ips = ["172.32.0.10", "172.32.0.11"]
}

/* Setup Elastic Ip */
resource "aws_eip" "marvin2" {
  vpc                       = true
  network_interface         = aws_network_interface.marvin.id
  associate_with_private_ip = "172.32.0.10"
}

/* Setup Elastic Ip */
resource "aws_eip" "marvin1" {
  vpc                       = true
  network_interface         = aws_network_interface.marvin.id
  associate_with_private_ip = "172.32.0.10"
}


/* Create Instance Profile to pass information for the instance*/
resource "aws_iam_instance_profile" "test_profile" {
  name = "marvin_provile"
  role = aws_iam_role.role.name
}

/* Create IAM Role for the Instance Profile*/
resource "aws_iam_role" "role" {
  name = "marvin_iam_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

