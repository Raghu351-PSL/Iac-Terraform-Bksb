provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::069705096352:role/Raghu-OA"
  }
}

data "aws_iam_role" "instance_profile_name"{
  name = var.instnace_profile_name
  
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.internet_gateway_name
  }
}

resource "aws_subnet" "nat" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.nat_subnet_cidr
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = true

  tags = {
    Name = var.nat_subnet_name
  }
}

resource "aws_subnet" "firewall" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.firewall_subnet_cidr
  availability_zone = var.availability_zone_b

  tags = {
    Name = var.firewall_subnet_name
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.nat.id

  tags = {
    Name = var.nat_gateway_name
  }
}

resource "aws_route_table" "nat" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.nat_subnet_name}-rt"
  }
}

resource "aws_route" "nat_to_igw" {
  route_table_id         = aws_route_table.nat.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [destination_cidr_block]
  }
}
resource "aws_route_table_association" "nat" {
  subnet_id      = aws_subnet.nat.id
  route_table_id = aws_route_table.nat.id
}

resource "aws_route_table" "firewall" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.firewall_subnet_name}-rt"
  }
}

resource "aws_route" "firewall_to_nat" {
  route_table_id         = aws_route_table.firewall.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [destination_cidr_block]
  }
}
resource "aws_route_table_association" "firewall" {
  subnet_id      = aws_subnet.firewall.id
  route_table_id = aws_route_table.firewall.id
}

# RDS SG
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "RDS SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

# RDS Subnet Group (requires two AZs)
resource "aws_db_subnet_group" "default" {
  name       = var.rds_db_subnet_group_name
  subnet_ids = [aws_subnet.nat.id, aws_subnet.firewall.id]

#   tags = {
#     Name = var.rds_db_subnet_group_name
#   }
}

resource "aws_db_instance" "default" {
  identifier              = var.rds_instance_name
  engine                  = var.rds_engine
  engine_version          = var.rds_engine_version
  instance_class          = var.rds_instance_class
  username                = var.rds_username
  password                = var.rds_password
  allocated_storage       = var.rds_allocated_storage
  db_subnet_group_name    = aws_db_subnet_group.default.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false

   tags = {
     Name = var.rds_instance_name
   }
}