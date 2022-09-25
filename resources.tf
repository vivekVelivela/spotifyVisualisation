### Creating Cloudwatch log group to store lambda Logs
resource "aws_cloudwatch_log_group" "extract_data_lambda_logs" {
  name              = "/aws/lambda/${var.project_name}_lambda_${var.env}"
  retention_in_days = 7
}

#### Zip file archive for lambda deployment package
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

### null resouce uses local-exec provisioner to download necessary packages for lambda(This truggers when there is a change in requirements.txt or main.py or any other change in hasing of lambda)
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


#### random_uuid generates a random ID with the hash of lambda deployment package 
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

#### s3 bucket to store the zip file fo lambda
resource "aws_s3_bucket" "spotify_visualisation_deployment_pack" {
  bucket = "spotify-visualisation-deployment-pack-${var.env}"
}

##### uploads the deployment pack to s3
resource "aws_s3_bucket_object" "file_upload_pack" {
  bucket = "${aws_s3_bucket.spotify_visualisation_deployment_pack.id}"
  key    = "lambda-functions/Lambda.zip"
  source = "${data.archive_file.zip_the_python_code.output_path}" # it means it depended on zip
}
 

#### LAMBDA FUNCTION
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


#### secrets manager for storing spotify app credentials
resource "aws_secretsmanager_secret" "spotify_credential_secret" {
  name = "${var.project_name}_spotifySecret_${var.env}"
  recovery_window_in_days = 0
}


##### aws_secretsmanager_secret_version stores the env variable client_id and client_secret in secrets manager
resource "aws_secretsmanager_secret_version" "spotify_credential_sversion" {
  secret_id = aws_secretsmanager_secret.spotify_credential_secret.id
  secret_string = <<EOF
   {
    "client_id": "${var.client_id}",
    "client_secret": "${var.client_secret}"
   }
EOF
}

#### This is used to assign as env variable inside lambda 
data "aws_secretsmanager_secret" "spotify_credential_secret" {
  arn = aws_secretsmanager_secret.spotify_credential_secret.arn
}
 
# Importing the AWS secret version created previously using arn.
 
# data "aws_secretsmanager_secret_version" "spotify_creds" {
#   secret_id = data.aws_secretsmanager_secret.spotify_credential_secret.arn
#   depends_on = [aws_secretsmanager_secret_version.spotify_credential_sversion,
#   aws_secretsmanager_secret.spotify_credential_secret
#   ]
# }

###### declaring cloudwatch event rule with a schedule
resource "aws_cloudwatch_event_rule" "every_thousand_minutes" {
  name                = "every-Thousand-minutes_${var.env}"
  description         = "Fires every thousand minutes"
  schedule_expression = "rate(1 minutes)"
}


##### This attaches the cluodwatch event rule with lambda.
resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = "${aws_cloudwatch_event_rule.every_thousand_minutes.name}"
  target_id = "lambda"
  arn       = "${aws_lambda_function.extract_data_lambda_func.arn}"
}



  
