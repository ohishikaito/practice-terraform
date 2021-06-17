data "aws_iam_policy_document" "allow_describe_regions" {
  statement {
    effect = "Allow"
    actions = ["ec2:DescribeRegions"]
    resources = [ "*" ]
  }
}

# # allow_describe_regions.json
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": ["ec2:DescribeRegions"],
#       "Resource": ["*"]
#     }
#   ]
# }