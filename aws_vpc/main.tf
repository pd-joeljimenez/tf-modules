// -----------------------------
// Variables
// -----------------------------

variable "cidr_block" {
  type        = string
  description = "CIDR blocks for this VPC"
}

variable "public_subnets" {
  type        = map(string)
  description = "Map of availability zones - subnet CIDR blocks"
}

variable "private_subnets" {
  type        = map(string)
  description = "Map of availability zones - subnet CIDR blocks"
}

variable "vpc_region" {
  type = string
  description = "VPC region"
}

variable "deployment_name" {
  type = string
  description = "Deployment name - used as prefix/suffix for resource naming"
}

variable "security_group_ids" {
  type = list
  description = "sg ids"
}

variable "security_group_names" {
  type = list
  description = "sg group names"
}

// -----------------------------
// Resources
// -----------------------------

resource "aws_vpc" "v" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  tags = {
    Name : "vpc-${var.deployment_name}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.v.id
}


// -----------------------------
// Public Subnets
// -----------------------------

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.v.id
  availability_zone = each.key
  cidr_block        = each.value

  map_public_ip_on_launch = true

  tags = {
    Name = "public-${each.key}-${var.deployment_name}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.v.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "main-rt-${var.deployment_name}"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_main_route_table_association" "public" {
  vpc_id         = aws_vpc.v.id
  route_table_id = aws_route_table.public.id
}

// -----------------------------
// Private Subnets
// -----------------------------

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.v.id
  availability_zone = each.key
  cidr_block        = each.value

  map_public_ip_on_launch = false

  tags = {
    Name = "private-${each.key}-${var.deployment_name}"
  }
}

resource "aws_eip" "nat" {
  for_each = var.private_subnets
  domain   = "vpc"

  tags = {
    Name = "nat-${each.key}"
  }
}

resource "aws_nat_gateway" "ng" {
  for_each = var.private_subnets

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "nat-${each.key}"
  }
}

resource "aws_route_table" "private" {
  for_each = var.private_subnets

  vpc_id = aws_vpc.v.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ng[each.key].id
  }

  tags = {
    Name = "${each.key}-private-${var.deployment_name}"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route_table_association" "private" {
  for_each = var.private_subnets

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

// -----------------------------
// Outputs
// -----------------------------

output "vpc" {
  value = aws_vpc.v
}

output "vpc_id" {
  value = aws_vpc.v.id
}

output "public_subnets" {
  value = aws_subnet.public
}

output "private_subnets" {
  value = aws_subnet.private
}
