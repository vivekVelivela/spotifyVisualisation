resource "aws_cloudwatch_log_group" "extract_data_lambda_logs" {
  name              = "/aws/lambda/${var.project_name}_get_leaderboard_${var.env}"
  retention_in_days = 14
}
data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir = "/Data"
  output_path = "tmp/zip_files/getLeaderBoard.zip"
}
 
resource "aws_lambda_function" "extract_data_lambda_func" {
filename                       = data.archive_file.zip_the_python_code.output_path
function_name                  = "extract_data"
role                           = aws_iam_role.lambda_role.arn
handler                        = "index.lambda_handler"
runtime                        = "python3.8"
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}