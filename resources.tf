resource "aws_cloudwatch_log_group" "extract_data_lambda_logs" {
  name              = "/aws/lambda/${var.project_name}_lambda"
  retention_in_days = 14
}
data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir = "Lambda/"
  output_path = "tmp/zip_files/Lambda.zip"
}
 
resource "aws_lambda_function" "extract_data_lambda_func" {
filename                       = data.archive_file.zip_the_python_code.output_path
function_name                  = "extract_data"
role                           = aws_iam_role.lambda_role.arn
handler                        = "index.lambda_handler"
runtime                        = "python3.8"
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

resource "aws_secretsmanager_secret" "spotify_credential_secret" {
  name = "${var.project_name}_spotifySecret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "spotify_credential_sversion" {
  secret_id = aws_secretsmanager_secret.spotify_credential_secret.id
  secret_string = <<EOF
   {
    "client_id": "${var.client_id}",
    "client_secret": "${var.client_secret}"
   }
EOF
}

data "aws_secretsmanager_secret" "spotify_credential_secret" {
  arn = aws_secretsmanager_secret.spotify_credential_secret.arn
}
 
# Importing the AWS secret version created previously using arn.
 
data "aws_secretsmanager_secret_version" "spotify_creds" {
  secret_id = data.aws_secretsmanager_secret.spotify_credential_secret.arn
  depends_on = [aws_secretsmanager_secret_version.spotify_credential_sversion,
  aws_secretsmanager_secret.spotify_credential_secret
  ]
}