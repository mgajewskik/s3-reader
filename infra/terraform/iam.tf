resource "aws_iam_role" "ec2" {
  name = "${local.prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# NOTE: could be customized to allow more granular permissions
resource "aws_iam_role_policy_attachment" "s3_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.ec2.name
}

resource "aws_iam_role_policy_attachment" "ssm_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_access" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.ec2.name
}

resource "aws_iam_role_policy_attachment" "ec2_instance_connect" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceConnect"
  role       = aws_iam_role.ec2.name
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.prefix}-ec2-profile"
  role = aws_iam_role.ec2.name
}
