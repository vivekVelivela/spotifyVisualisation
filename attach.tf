resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
       depends_on = [
        aws_iam_policy.lambda_policy,aws_iam_policy.lambda_secret_policy,aws_iam_policy.lambda_secret_policy
 ]
    for_each = toset([aws_iam_policy.lambda_policy.arn,aws_iam_policy.lambda_secret_policy.arn])
 role        = aws_iam_role.lambda_role.name
 policy_arn  = each.key
 
}