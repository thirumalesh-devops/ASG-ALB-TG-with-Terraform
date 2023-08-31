terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = " 5.14.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
  access_key = "xxxxxxxxxxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxxxx"
}

resource "aws_security_group" "alb-sec-group" {
  name = "alb-sec-group"
  description = "Security Group for the ELB (ALB)"
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "asg_sec_group" {
  name = "asg_sec_group"
  description = "Security Group for the ASG"
  tags = {
    name = "name"
  }
  
  egress {
    from_port = 0
    protocol = "-1" 
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    security_groups = [aws_security_group.alb-sec-group.id] 
  }
}

resource "aws_launch_configuration" "ec2_template" {
  image_id = "ami-06f621d90fa29f6d0"
  instance_type = "t2.micro"
  user_data = <<-EOF
            #!/bin/bash
              yum update -y
              yum install httpd -y
              systemctl enable httpd
              systemctl start httpd
              echo "<html><h1>Welcome to my web page. You are getting this page from $(hostname -f) server. </h1><br>Your 🌏 server configured successfully with full of LOVE ❤........</html>">/var/www/html/index.html
              yum install sed -y
              systemctl enable sed
              useradd book
              echo "book:root123" | chpasswd
              echo "root:root123" | chpasswd
              sed -i '/PasswordAuthentication no/d' /etc/ssh/sshd_config    
              echo "PermitRootLogin Yes">>/etc/ssh/sshd_config
              echo "PasswordAuthentication Yes">>/etc/ssh/sshd_config
              systemctl restart sshd
            EOF
  security_groups = [aws_security_group.asg_sec_group.id]
 
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "default" {
  default = true
}
data "aws_availability_zones" "azs" {}

resource "aws_autoscaling_group" "Practice_ASG" {
  max_size = 5
  min_size = 2
  launch_configuration = aws_launch_configuration.ec2_template.name
  health_check_grace_period = 300 
  health_check_type = "ELB" 
  #availability_zones = aws_availability_zones.azs
  vpc_zone_identifier = ["subnet-01e2519a1f893b7aa"]
  target_group_arns = [aws_lb_target_group.asg.arn]

  tag {
    key = "name"
    propagate_at_launch = false
    value = "Practice_ASG"
  }
  lifecycle {
  create_before_destroy = true
  }
}

resource "aws_lb" "ELB" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets  = ["subnet-01e2519a1f893b7aa", "subnet-09731ae49b596ff16"]
  security_groups = [aws_security_group.alb-sec-group.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ELB.arn 
  port = 80
  protocol = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "asg" {
  name = "asg-example"
  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
