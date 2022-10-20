# Provider information.

provider "aws" {
  region  = "us-east-1"
  profile = "KS-profile"
}


# Create a VPC-1

resource "aws_vpc" "vpc-1" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC-3TA" 
  }
#   enable_ipv6 = true
#   enable_nat_gateway = false
#   single_nat_gateway = true
}



# Create a public subnet in vpc-1

resource "aws_subnet" "web-public-subnet1" {
  vpc_id                  = aws_vpc.vpc-1.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Web-pub-subnet1"
  }
}

output "ps1" {
    value = aws_subnet.public-subnet_1.id
  
}

# Create a public subnet in vpc-1

resource "aws_subnet" "web-public-subnet2" {
  vpc_id                  = aws_vpc.vpc-1.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Web-pub-subnet2"
  }
}

output "ps2" {
    value = aws_subnet.public-subnet_2.id
  
}

# Create Application Public Subnet in vpc-1

resource "aws_subnet" "App-private-subnet" {
  vpc_id                  = aws_vpc.vpc-1.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "App-private-subnet-1a"
  }
}

resource "aws_subnet" "App-private-subnet" {
  vpc_id                  = aws_vpc.vpc-1.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "App-private-subnet-1b"
  }
}

# Create a Database Private Subnet
resource "aws_subnet" "Database-Subnet-1" {
  vpc_id                  = aws_vpc.vpc-1.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.5.0/24"
 

  tags = {
    Name = "Database-1a"
  }
}

resource "aws_subnet" "Database-Subnet-2" {
  vpc_id                  = aws_vpc.vpc-1.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.0.6.0/24"
 

  tags = {
    Name = "Database-2b"
  }
}

resource "aws_subnet" "Database-Subnet" {
  vpc_id                  = aws_vpc.vpc-1.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.7.0/24"
 

  tags = {
    Name = "Database"
  }
}

# Create a igw for vpc1

resource "aws_internet_gateway" "gw-vpc1" {
  vpc_id       = aws_vpc.vpc-1.id

  tags = {
    Name       = "igw-vpc1"
  }
}

# Create Web Layer Route Table
resource "aws_route_table" "web-rt" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw-vpc1.id
  }

  tags = {
    Name = "WebRT"
  }
}


# Create Web Subnet association with Web route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.web-public-subnet1.id
  route_table_id = aws_route_table.web-rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.web-public-subnet2.id
  route_table_id = aws_route_table.web-rt.id
}

#Create EC2 Instance
resource "aws_instance" "webserver1" {
  ami                    = "ami-0d5eff06f840b45e9"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  subnet_id              = aws_subnet.web-public-subnet1.id
  user_data              = file("install_apache.sh")

  tags = {
    Name = "Web Server 1"
  }

}

#Create EC2 Instance
resource "aws_instance" "webserver2" {
  ami                    = "ami-0d5eff06f840b45e9"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1b"
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  subnet_id              = aws_subnet.web-public-subnet2.id
  user_data              = file("install_apache.sh")

  tags = {
    Name = "Web Server 2"
  }

}


# Create a webserver for Security Group
resource "aws_security_group" "web-sg" {
  name        = "Web-SG"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.vpc-1.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"] 
  }

  tags = {
    Name = "Web-SG"
  }
}

# Create Application Security Group
resource "aws_security_group" "webserver-sg" {
  name        = "Webserver-SG"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.vpc-1.id

  ingress {
    description      = "Allow traffic from web layer"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [aws_security_group.web-sg.id] 
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "Webserver-SG"
  }
}


# Create Datbase Security Group
resource "aws_security_group" "database-sg" {
  name        = "Database-SG"
  description = "Allow inbound traffic from application layer"
  vpc_id      = aws_vpc.vpc-1.id

  ingress {
    description      = "Allow traffic from application layer"
    from_port        = "3306" 
    to_port          = "3306"
    protocol         = "tcp"
    security_groups  = [aws_security_group.webserver-sg.id] 
    
  }

  egress {
    from_port        = 32768
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "Database-SG"
  }
}

# Create a Application   Load Balancer

resource "aws_lb" "external-lb" {
  name               = "External-LB"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.web-public-subnet1.id, aws_subnet.web-public-subnet2.id]
  security_groups    = [aws_security_group.web-sg.id] 
  tags = {
    Environment = "external-lb"
  }
}

resource "aws_lb_target_group" "external-elb" {
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc-1.id
}

resource "aws_lb_target_group_attachment" "external-elb1" {
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.webserver1.id
  port             = 80

  depends_on = [
    aws_instance.webserver1,
  ]
}

resource "aws_lb_target_group_attachment" "external-elb2" {
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.webserver2.id
  port             = 80

  depends_on = [
    aws_instance.webserver2,
  ]
}

resource "aws_lb_listener" "external-elb" {
  load_balancer_arn = aws_lb.external-lb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-elb.arn
  }
}




# Create a RDS Database

resource "aws_db_instance" "default" {
   
  allocated_storage      = 10
  db_name                = "mydb"
  engine                 = "mysql"
  engine_version         = "8.0.20"
  instance_class         = "db.t2.micro"
  username               = "username"
  password               = "password"
  skip_final_snapshot    = true
  multi_az               = true
  vpc_security_group_ids = [aws_security_group.database-sg.id]
  tags = {
    Name = "Database"
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.Database-Subnet-1.id, aws_subnet.Database-Subnet-2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.external-elb.dns_name
}