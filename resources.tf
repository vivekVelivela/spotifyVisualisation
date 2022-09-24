resource "aws_cloudwatch_log_group" "extract_data_lambda_logs" {
  name              = "/aws/lambda/${var.project_name}_lambda_${var.env}"
  retention_in_days = 7
}
data "archive_file" "zip_the_python_code" {
  depends_on = [null_resource.install_dependencies]
  excludes   = [
    "venv",
    "__pycache__",
    "core/__pycache__",
    "requirements.txt"
  ]

  source_dir  = var.lambda_root
  output_path = "${random_uuid.lambda_src_hash.result}.zip"
  type        = "zip"
}

resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r ${var.lambda_root}/requirements.txt --no-deps --ignore-installed -t ${var.lambda_root}/ --upgrade"
  }
  
  triggers = {
    dependencies_versions = filemd5("${var.lambda_root}/requirements.txt")
    source_versions = filemd5("${var.lambda_root}/main.py")
    source_code_hash = random_uuid.lambda_src_hash.result
  }
}

resource "random_uuid" "lambda_src_hash" {
  keepers = {
    for filename in setunion(
      fileset(var.lambda_root, "*.py"),
      fileset(var.lambda_root, "requirements.txt"),
      fileset(var.lambda_root, "core/**/*.py")

    ):
        filename => filemd5("${var.lambda_root}/${filename}")
  }
}

resource "aws_s3_bucket" "spotify_visualisation_deployment_pack" {
  bucket = "spotify-visualisation-deployment-pack-${var.env}"
}

resource "aws_s3_bucket_object" "file_upload_pack" {
  bucket = "${aws_s3_bucket.spotify_visualisation_deployment_pack.id}"
  key    = "lambda-functions/Lambda.zip"
  source = "${data.archive_file.zip_the_python_code.output_path}" # its mean it depended on zip
}
 
resource "aws_lambda_function" "extract_data_lambda_func" {
function_name                  = "${var.project_name}_extract_data_${var.env}"
s3_bucket                      = aws_s3_bucket.spotify_visualisation_deployment_pack.bucket
s3_key                         = aws_s3_bucket_object.file_upload_pack.key
role                           = aws_iam_role.lambda_role.arn
handler                        = "main.lambda_handler"
runtime                        = "python3.8"
memory_size                    = 10240
source_code_hash               = filebase64sha256("${data.archive_file.zip_the_python_code.output_path}")
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
timeout                        = 900
environment {
    variables = {
      SECRET_ARN = aws_secretsmanager_secret.spotify_credential_secret.arn
      region = var.region
    }
}
}

resource "aws_secretsmanager_secret" "spotify_credential_secret" {
  name = "${var.project_name}_spotifySecret_${var.env}"
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


resource "aws_cloudwatch_event_rule" "every_thousand_minutes" {
  name                = "every-Thousand-minutes_${var.env}"
  description         = "Fires every thousand minutes"
  schedule_expression = "rate(10000 minutes)"
}

resource "aws_cloudwatch_event_target" "check_foo_every_one_minute" {
  rule      = "${aws_cloudwatch_event_rule.every_thousand_minutes.name}"
  target_id = "lambda"
  arn       = "${aws_lambda_function.extract_data_lambda_func.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_foo" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.extract_data_lambda_func.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.every_thousand_minutes.arn}"
}