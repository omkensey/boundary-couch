resource "aws_iam_role" "boundary" {
  name = "${var.unique_name}-role"
  assume_role_policy = data.aws_iam_policy_document.boundary-assume-role.json
}

data "aws_iam_policy_document" "boundary-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_instance_profile" "boundary" {
  name = "${var.unique_name}-profile"
  role = aws_iam_role.boundary.name
}
