resource "aws_cloudwatch_log_group" "extract_data_lambda_logs" {
  name              = "/aws/lambda/${var.project_name}_lambda"
  retention_in_days = 14
}
data "archive_file" "zip_the_python_code" {
  depends_on = [null_resource.install_dependencies]
  excludes   = [
    "__pycache__",
    "venv",
  ]

  source_dir  = var.lambda_root
  output_path = "${random_uuid.lambda_src_hash.result}.zip"
  type        = "zip"
}

resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r ${var.lambda_root}/requirements.txt -t ${var.lambda_root}/"
  }
  
  triggers = {
    dependencies_versions = filemd5("${var.lambda_root}/requirements.txt")
    source_versions = filemd5("${var.lambda_root}/main.py")
  }
}

resource "random_uuid" "lambda_src_hash" {
  keepers = {
    for filename in setunion(
      fileset(var.lambda_root, "function.py"),
      fileset(var.lambda_root, "requirements.txt")
    ):
        filename => filemd5("${var.lambda_root}/${filename}")
  }
}
 
resource "aws_lambda_function" "extract_data_lambda_func" {
filename                       = data.archive_file.zip_the_python_code.output_path
function_name                  = "extract_data"
role                           = aws_iam_role.lambda_role.arn
handler                        = "index.lambda_handler"
runtime                        = "python3.8"
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
environment {
    variables = {
      SECRET_ARN = aws_secretsmanager_secret.spotify_credential_secret.arn
      region = var.region
    }
}
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