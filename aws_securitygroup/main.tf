// -----------------------------
// Variables
// -----------------------------

variable "security_groups" {
  description = "List of security group configurations"
  type        = list(object({
    sg_name        = string
    sg_description = string
    vpc_id         = string
    ingress_rules  = list(object({
      from_port          = number
      to_port            = number
      protocol           = string
      cidr_blocks        = list(string)
      self               = bool

    }))
    egress_rules   = list(object({
      from_port          = number
      to_port            = number
      protocol           = string
      cidr_blocks        = list(string)
    }))
  }))
  default     = []
}

// -----------------------------
// Security Groups
// -----------------------------

resource "aws_security_group" "sg" {
  count       = length(var.security_groups)
  name        = var.security_groups[count.index].sg_name
  description = var.security_groups[count.index].sg_description
  vpc_id      = var.security_groups[count.index].vpc_id

  dynamic "ingress" {
    for_each = var.security_groups[count.index].ingress_rules

    content {
      from_port          = ingress.value.from_port
      to_port            = ingress.value.to_port
      protocol           = ingress.value.protocol
      cidr_blocks        = ingress.value.cidr_blocks
      self = ingress.value.self ? true : false
    }
  }

  dynamic "egress" {
    for_each = var.security_groups[count.index].egress_rules

    content {
      from_port          = egress.value.from_port
      to_port            = egress.value.to_port
      protocol           = egress.value.protocol
      cidr_blocks        = egress.value.cidr_blocks
    }
  }
}

// -----------------------------
// Outputs
// -----------------------------

output "security_group_ids" {
  value = [for sg in aws_security_group.sg : sg.id]
}

output "security_group_names" {
  value = [for sg in aws_security_group.sg : sg.name]
}
