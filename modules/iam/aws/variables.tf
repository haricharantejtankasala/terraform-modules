# =======================================================================
# Variables — IAM Module (AWS)
#
# All variables use optional() where sensible so callers only need to
# provide what they actually use. For example, a module call that only
# creates roles does not need to pass users or groups at all.
# =======================================================================

# -----------------------------------------------------------------------
# Shared / Required
# -----------------------------------------------------------------------

variable "project_name" {
  description = "Project name used as a prefix in all resource names and tags (e.g. 'myapp')"
  type        = string
}

variable "environment" {
  description = "Deployment environment: dev, staging, or prod — included in resource names to prevent collisions"
  type        = string
}

# -----------------------------------------------------------------------
# IAM Roles
#
# Pass a map where each key becomes part of the role name.
#
# Example:
#   roles = {
#     ec2-app = {
#       description         = "Role for application EC2 instances"
#       trusted_services    = ["ec2.amazonaws.com"]
#       managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
#       create_instance_profile = true
#     }
#     lambda-processor = {
#       description      = "Role for the data processing Lambda"
#       trusted_services = ["lambda.amazonaws.com"]
#       custom_policies  = {
#         sqs-read = jsonencode({ Version = "2012-10-17", Statement = [...] })
#       }
#     }
#   }
# -----------------------------------------------------------------------

variable "roles" {
  description = "Map of IAM roles to create. The map key is used in the role name."
  type = map(object({
    # Human-readable description stored on the IAM role in AWS
    description = string

    # AWS service principals that can assume this role.
    # e.g. ["ec2.amazonaws.com"] for EC2, ["lambda.amazonaws.com"] for Lambda
    trusted_services = optional(list(string), [])

    # AWS account ARNs allowed to assume this role (cross-account access).
    # e.g. ["arn:aws:iam::123456789012:root"]
    trusted_accounts = optional(list(string), [])

    # ARNs of AWS-managed or customer-managed policies to attach to the role.
    # e.g. ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
    managed_policy_arns = optional(list(string), [])

    # Inline policies scoped to this role only. Key = policy name, value = JSON policy doc.
    # Use jsonencode() or the aws_iam_policy_document data source to build the doc.
    custom_policies = optional(map(string), {})

    # Set to true for roles used by EC2 instances.
    # Creates an aws_iam_instance_profile wrapping this role.
    create_instance_profile = optional(bool, false)
  }))
  default = {}
}

# -----------------------------------------------------------------------
# Standalone Managed Policies
#
# Creates reusable customer-managed policies that can be referenced by
# their ARN (via the policy_arns output) and attached to any role/user/group.
#
# Example:
#   policies = {
#     s3-data-write = {
#       description     = "Write access to the data S3 bucket"
#       policy_document = jsonencode({ Version = "2012-10-17", Statement = [...] })
#     }
#   }
# -----------------------------------------------------------------------

variable "policies" {
  description = "Map of standalone customer-managed IAM policies to create. The map key is used in the policy name."
  type = map(object({
    description = string
    # Must be a valid JSON IAM policy document string.
    policy_document = string
  }))
  default = {}
}

# -----------------------------------------------------------------------
# IAM Users
#
# Example:
#   users = {
#     ci-deployer = {
#       managed_policy_arns = ["arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"]
#     }
#     developer-alice = {
#       groups = ["developers"]
#     }
#   }
# -----------------------------------------------------------------------

variable "users" {
  description = "Map of IAM users to create. The map key is used in the user name."
  type = map(object({
    # List of group keys (from var.groups) this user should belong to
    groups = optional(list(string), [])

    # ARNs of policies to attach directly to this user.
    # Prefer group-based permissions over direct user attachments where possible.
    managed_policy_arns = optional(list(string), [])
  }))
  default = {}
}

# -----------------------------------------------------------------------
# IAM Groups
#
# Example:
#   groups = {
#     developers = {
#       managed_policy_arns = [
#         "arn:aws:iam::aws:policy/ReadOnlyAccess"
#       ]
#     }
#   }
# -----------------------------------------------------------------------

variable "groups" {
  description = "Map of IAM groups to create. The map key is used in the group name."
  type = map(object({
    # ARNs of policies to attach to this group.
    # All users in the group inherit these permissions.
    managed_policy_arns = optional(list(string), [])
  }))
  default = {}
}
