locals {
  policies = {
       one = aws_iam_policy.lambda_policy.arn,
       two = aws_iam_policy.lambda_secret_policy.arn,

  }
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {   
    for_each = {for i, val in local.policies: i => val}
       role        = aws_iam_role.lambda_role.name
       policy_arn  = each.value
       depends_on = [
        aws_iam_policy.lambda_policy,aws_iam_policy.lambda_secret_policy,aws_iam_policy.lambda_secret_policy
 ]
}

