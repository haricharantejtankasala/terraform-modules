# =======================================================================
# IAM Module — AWS
#
# Creates and manages AWS Identity and Access Management (IAM) resources:
#   - Roles with trust policies (for services or cross-account access)
#   - Managed and inline policy attachments on roles
#   - EC2 instance profiles (wraps a role so EC2 can assume it)
#   - Standalone customer-managed policies
#   - IAM users with optional group membership
#   - IAM groups with managed policy attachments
#
# All resource names are prefixed with "<project_name>-<environment>"
# to avoid collisions across environments and projects.
# =======================================================================

locals {
  # Prefix applied to every resource name, e.g. "myapp-dev"
  name_prefix = "${var.project_name}-${var.environment}"

  # Tags merged onto every resource for cost tracking and governance
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------
# IAM Roles
#
# An IAM Role is an identity with permissions that can be assumed by:
#   - AWS services (e.g. EC2, Lambda, EKS) via trusted_services
#   - Other AWS accounts                   via trusted_accounts
#
# The trust policy (assume_role_policy) defines WHO can assume the role.
# Permissions are added separately via policy attachments below.
# -----------------------------------------------------------------------

resource "aws_iam_role" "this" {
  # for_each iterates over the var.roles map, creating one role per entry.
  # The map key (each.key) becomes part of the role name.
  for_each = var.roles

  name        = "${local.name_prefix}-${each.key}"
  description = each.value.description

  # The trust policy is built dynamically using jsonencode + concat.
  # concat() merges two lists so we can support both service and
  # cross-account trust in the same role without hardcoding either.
  # Each block is only included when its list is non-empty.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Trust statement for AWS services (e.g. "ec2.amazonaws.com")
      length(each.value.trusted_services) > 0 ? [{
        Effect    = "Allow"
        Principal = { Service = each.value.trusted_services }
        Action    = "sts:AssumeRole"
      }] : [],

      # Trust statement for cross-account access (e.g. another AWS account ARN)
      length(each.value.trusted_accounts) > 0 ? [{
        Effect    = "Allow"
        Principal = { AWS = each.value.trusted_accounts }
        Action    = "sts:AssumeRole"
      }] : []
    )
  })

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-${each.key}" })
}

# -----------------------------------------------------------------------
# Managed Policy Attachments on Roles
#
# Attaches AWS-managed (e.g. AmazonS3ReadOnlyAccess) or customer-managed
# policy ARNs to roles. Because one role can have many policies, we use
# a double for loop to "flatten" the role → policy pairs into a single map
# that for_each can iterate over.
#
# Key format: "<role_key>__<policy_arn>" — the double underscore makes the
# key unique even when an ARN contains forward slashes.
# -----------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = {
    for pair in flatten([
      for role_key, role in var.roles : [
        for arn in role.managed_policy_arns : {
          key        = "${role_key}__${arn}"
          role_key   = role_key
          policy_arn = arn
        }
      ]
    ]) : pair.key => pair
  }

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.policy_arn
}

# -----------------------------------------------------------------------
# Inline Policies on Roles
#
# Inline policies are embedded directly into a role and are deleted when
# the role is deleted. Use these for permissions that are unique to one
# role and should not be shared. For shared permissions use standalone
# managed policies (aws_iam_policy) instead.
#
# custom_policies is a map(string) where the key is the policy name and
# the value is a raw JSON policy document string.
# -----------------------------------------------------------------------

resource "aws_iam_role_policy" "custom" {
  for_each = {
    for pair in flatten([
      for role_key, role in var.roles : [
        for policy_name, policy_doc in role.custom_policies : {
          key         = "${role_key}__${policy_name}"
          role_key    = role_key
          policy_name = policy_name
          policy_doc  = policy_doc
        }
      ]
    ]) : pair.key => pair
  }

  name   = each.value.policy_name
  role   = aws_iam_role.this[each.value.role_key].id
  policy = each.value.policy_doc
}

# -----------------------------------------------------------------------
# EC2 Instance Profiles
#
# An instance profile is a container for an IAM role that EC2 uses to
# pass the role to an instance at launch. Without an instance profile,
# an EC2 instance cannot assume an IAM role.
#
# Only created for roles where create_instance_profile = true.
# The conditional filter ( if role.create_instance_profile ) avoids
# creating unnecessary profiles for Lambda or EKS roles.
# -----------------------------------------------------------------------

resource "aws_iam_instance_profile" "this" {
  # Filter: only process roles that opted in to an instance profile
  for_each = {
    for role_key, role in var.roles : role_key => role
    if role.create_instance_profile
  }

  name = "${local.name_prefix}-${each.key}-profile"
  role = aws_iam_role.this[each.key].name

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-${each.key}-profile" })
}

# -----------------------------------------------------------------------
# Standalone Customer-Managed Policies
#
# Unlike inline policies, standalone managed policies are independent
# resources with their own ARN. They can be attached to multiple roles,
# users, or groups. Use these for permissions shared across resources.
#
# Output: policy_arns — lets other modules reference these ARNs directly.
# -----------------------------------------------------------------------

resource "aws_iam_policy" "standalone" {
  for_each = var.policies

  name        = "${local.name_prefix}-${each.key}"
  description = each.value.description
  # policy_document must be a valid JSON IAM policy string.
  # Use Terraform's jsonencode() or the aws_iam_policy_document data source
  # to generate the document before passing it to this module.
  policy = each.value.policy_document

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-${each.key}" })
}

# -----------------------------------------------------------------------
# IAM Users
#
# IAM users represent individual people or service accounts that need
# long-term AWS credentials. For human access prefer IAM Identity Center
# (SSO); use IAM users for programmatic / CI service accounts.
# -----------------------------------------------------------------------

resource "aws_iam_user" "this" {
  for_each = var.users

  name = "${local.name_prefix}-${each.key}"

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-${each.key}" })
}

# Attach managed policies directly to users.
# Same double-loop flattening pattern used for role policy attachments.
resource "aws_iam_user_policy_attachment" "this" {
  for_each = {
    for pair in flatten([
      for user_key, user in var.users : [
        for arn in user.managed_policy_arns : {
          key        = "${user_key}__${arn}"
          user_key   = user_key
          policy_arn = arn
        }
      ]
    ]) : pair.key => pair
  }

  user       = aws_iam_user.this[each.value.user_key].name
  policy_arn = each.value.policy_arn
}

# -----------------------------------------------------------------------
# IAM Groups
#
# Groups let you manage permissions for multiple users at once.
# Attach policies to the group instead of each user individually —
# any user added to the group inherits its permissions automatically.
# -----------------------------------------------------------------------

resource "aws_iam_group" "this" {
  for_each = var.groups

  # Groups are global in AWS (not region-specific), so we still prefix
  # the name to keep them organised by project and environment.
  name = "${local.name_prefix}-${each.key}"
}

# Attach managed policies to groups using the same flattening pattern.
resource "aws_iam_group_policy_attachment" "this" {
  for_each = {
    for pair in flatten([
      for group_key, group in var.groups : [
        for arn in group.managed_policy_arns : {
          key        = "${group_key}__${arn}"
          group_key  = group_key
          policy_arn = arn
        }
      ]
    ]) : pair.key => pair
  }

  group      = aws_iam_group.this[each.value.group_key].name
  policy_arn = each.value.policy_arn
}

# -----------------------------------------------------------------------
# User → Group Membership
#
# Assigns users to the groups listed in their var.users entry.
# The filter ( if length(user.groups) > 0 ) skips users that have no
# group assignments, avoiding an empty resource with nothing to do.
# -----------------------------------------------------------------------

resource "aws_iam_user_group_membership" "this" {
  for_each = {
    for user_key, user in var.users : user_key => user
    if length(user.groups) > 0
  }

  user = aws_iam_user.this[each.key].name
  # Resolve group names from the aws_iam_group resources created above
  # rather than using raw strings, so Terraform tracks the dependency.
  groups = [for g in each.value.groups : aws_iam_group.this[g].name]
}
