# =======================================================================
# Outputs — IAM Module (AWS)
#
# All outputs are maps keyed by the same keys used in the input variables,
# so callers can look up a specific resource by name.
#
# Example — referencing a role ARN in another module:
#   module.iam.role_arns["ec2-app"]
#
# Example — passing an instance profile to the compute module:
#   iam_instance_profile_arn = module.iam.instance_profile_arns["ec2-app"]
# =======================================================================

# -----------------------------------------------------------------------
# Role outputs
# -----------------------------------------------------------------------

output "role_arns" {
  description = "Map of role key to ARN — use this when another resource needs to reference the role (e.g. EKS node group, Lambda function)"
  value       = { for k, v in aws_iam_role.this : k => v.arn }
}

output "role_names" {
  description = "Map of role key to name — use this when an AWS resource expects the role name string rather than the full ARN"
  value       = { for k, v in aws_iam_role.this : k => v.name }
}

# -----------------------------------------------------------------------
# Instance Profile outputs
#
# Only populated for roles where create_instance_profile = true.
# Pass instance_profile_arns or instance_profile_names to the compute
# module so EC2 instances can assume the role at launch.
# -----------------------------------------------------------------------

output "instance_profile_arns" {
  description = "Map of role key to instance profile ARN — pass to EC2 launch templates or ASG configurations"
  value       = { for k, v in aws_iam_instance_profile.this : k => v.arn }
}

output "instance_profile_names" {
  description = "Map of role key to instance profile name — alternative to ARN when the resource expects a name string"
  value       = { for k, v in aws_iam_instance_profile.this : k => v.name }
}

# -----------------------------------------------------------------------
# Standalone Policy outputs
#
# Use policy_arns to attach a module-created policy to resources outside
# this module (e.g. roles in another module call or another Terraform root).
# -----------------------------------------------------------------------

output "policy_arns" {
  description = "Map of standalone policy key to ARN — use to attach these policies to roles or users created outside this module"
  value       = { for k, v in aws_iam_policy.standalone : k => v.arn }
}

# -----------------------------------------------------------------------
# User outputs
# -----------------------------------------------------------------------

output "user_arns" {
  description = "Map of user key to ARN — useful for referencing users in resource-based policies (e.g. S3 bucket policies)"
  value       = { for k, v in aws_iam_user.this : k => v.arn }
}

# -----------------------------------------------------------------------
# Group outputs
# -----------------------------------------------------------------------

output "group_arns" {
  description = "Map of group key to ARN — useful for referencing groups in resource-based policies"
  value       = { for k, v in aws_iam_group.this : k => v.arn }
}
