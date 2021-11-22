data "aws_iam_policy_document" "policy_document" {
  statement {
    actions   = ["kms:*"]
    resources = ["*"] # tfsec:ignore:AWS097
    principals {
      type = "AWS"
      identifiers = [
        local.role.admin,
        local.role.drone,
      ]
    }
  }
}

resource "aws_kms_key" "key" {
  description         = format("%s %s", var.environment, var.service_name)
  enable_key_rotation = true
}

resource "aws_kms_alias" "alias" {
  name          = format("alias/%s-%s", var.environment, var.service_name)
  target_key_id = aws_kms_key.key.key_id
}
