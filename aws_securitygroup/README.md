<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_security_group.sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | List of security group configurations | <pre>list(object({<br>    sg_name        = string<br>    sg_description = string<br>    vpc_id         = string<br>    ingress_rules  = list(object({<br>      from_port          = number<br>      to_port            = number<br>      protocol           = string<br>      cidr_blocks        = list(string)<br>      self               = bool<br><br>    }))<br>    egress_rules   = list(object({<br>      from_port          = number<br>      to_port            = number<br>      protocol           = string<br>      cidr_blocks        = list(string)<br>    }))<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_security_group_ids"></a> [security\_group\_ids](#output\_security\_group\_ids) | n/a |
| <a name="output_security_group_names"></a> [security\_group\_names](#output\_security\_group\_names) | n/a |
<!-- END_TF_DOCS -->