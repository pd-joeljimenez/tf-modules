// -----------------------------
// Variables
// -----------------------------

variable "ami_filter" {
  type        = string
  description = "AMI filter for AMI searching "
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "deployment_name" {
  type        = string
  description = "Deployment name - used as prefix/suffix for resource naming"
}

variable "vpc_id" {
  type        = string
  description = "VPC id"
}

variable "min_size" {
  type        = string
  description = "ASG minimum # of instances"
}

variable "max_size" {
  type        = string
  description = "ASG maximum # of instances"
}

variable "public_subnets" {
  type = map(object({
    id = string
  }))
}

variable "private_subnets" {
  type = map(object({
    id = string
  }))
  description = "Private subnet mapping"
}

variable "desired_capacity" {
  type        = string
  description = "ASG desired ec instance capacity"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet ids"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet ids"
}

variable "linux_user_data" {
  type        = string
  description = "Linux user data"
}

variable "security_group_ids" {
  type        = list(any)
  description = "sg ids"
}

variable "security_group_names" {
  type        = list(any)
  description = "sg group names"
}


// -----------------------------
// Data
// -----------------------------

data "aws_ami" "ami" {
  most_recent = true
  owners = [
    "amazon",
  ]

  filter {
    name   = "name"
    values = [local.ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {

  ami_name_filter = var.ami_filter

}

//--------------------
// EC2 - Key/Pair
//--------------------

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "private-key-${var.deployment_name}"
  public_key = tls_private_key.pk.public_key_openssh

  tags = {
    Name = "private-key-${var.deployment_name}"
  }
}

// -----------------------------
// Launch Template
// -----------------------------

resource "aws_launch_template" "t" {
  name          = "lt-${var.deployment_name}"
  instance_type = var.instance_type
  key_name      = aws_key_pair.kp.key_name
  image_id      = data.aws_ami.ami.id

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.security_group_ids[1]]
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "root-volume-${var.deployment_name}"
    }
  }

  user_data = base64encode(var.linux_user_data)
}

// -----------------------------
// Autoscaling Groups
// -----------------------------

resource "aws_autoscaling_group" "asg" {

  // for_each = var.public_subnets
  for_each = var.private_subnets

  name = "asg-${var.deployment_name}-${each.key}"

  vpc_zone_identifier = [each.value.id]

  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size

  protect_from_scale_in = true

  launch_template {
    id      = aws_launch_template.t.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.lb_tg.arn]
}

// -----------------------------
// Load Balancer
// -----------------------------

resource "aws_lb" "lb" {

  name                       = "${var.deployment_name}-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.security_group_ids[0]]
  subnets                    = concat(var.public_subnet_ids)
  enable_deletion_protection = false
  drop_invalid_header_fields = true


  tags = {
    Name = "lb-${var.deployment_name}"
  }
}

// -----------------------------
// Target Groups
// -----------------------------

resource "aws_lb_target_group" "lb_tg" {
  name     = "lb-tg-${var.deployment_name}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "HTTP"
    port                = 80
    path                = "/"
    matcher             = "200,302"
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "lb-tg-${var.deployment_name}"
  }
}

// -----------------------------
// LB Listener
// -----------------------------

resource "aws_lb_listener" "ext_lb_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}