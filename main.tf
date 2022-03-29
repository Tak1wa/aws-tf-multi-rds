provider "aws" {
  region  = "ap-northeast-1"
  profile = "hoge-tf"
}

terraform {
  backend "s3" {
    bucket  = "iwasa-terraform-state-bucket"
    key     = "aws-tf-multi-rds"
    region  = "ap-northeast-1"
    profile = "hoge-tf"
  }
}

#--------------------------------------------------------------
# VPC
#--------------------------------------------------------------

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

#--------------------------------------------------------------
# Internet Gateway
#--------------------------------------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

#--------------------------------------------------------------
# Public subnet
#--------------------------------------------------------------

resource "aws_subnet" "public-1a-subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public-1c-subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public-rtb-as1" {
  subnet_id      = aws_subnet.public-1a-subnet.id
  route_table_id = aws_route_table.public-rtb.id
}
resource "aws_route_table_association" "public-rtb-as2" {
  subnet_id      = aws_subnet.public-1c-subnet.id
  route_table_id = aws_route_table.public-rtb.id
}

#--------------------------------------------------------------
# Security group
#--------------------------------------------------------------

resource "aws_security_group" "rds-sg" {
  name        = "hoge-rds-sg"
  description = "hoge-rds-sg"
  vpc_id      = aws_vpc.vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "rds-sg-rule" {
  security_group_id = aws_security_group.rds-sg.id
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
}

#--------------------------------------------------------------
# Subnet group
#--------------------------------------------------------------

resource "aws_db_subnet_group" "rds-subnet-group" {
  name        = "hoge-rds-subnet"
  description = "hoge-rds-subnet"
  subnet_ids  = [aws_subnet.public-1a-subnet.id, aws_subnet.public-1c-subnet.id]
}

#--------------------------------------------------------------
# RDS
#--------------------------------------------------------------
resource "aws_db_instance" "hoge-rds1" {
  allocated_storage      = 20
  engine                 = "sqlserver-ex"
  engine_version         = "15.00.4153.1.v1"
  instance_class         = "db.t3.small"
  identifier             = "hoge-mssql-1"
  username               = "iwasa"
  password               = "password"
  parameter_group_name   = "default.sqlserver-ex-15.0"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds-subnet-group.name
  publicly_accessible    = true
}

resource "aws_db_instance" "hoge-rds2" {
  allocated_storage      = 20
  engine                 = "sqlserver-ex"
  engine_version         = "15.00.4153.1.v1"
  instance_class         = "db.t3.small"
  identifier             = "hoge-mssql-2"
  username               = "iwasa"
  password               = "password"
  parameter_group_name   = "default.sqlserver-ex-15.0"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds-subnet-group.name
  publicly_accessible    = true
}
