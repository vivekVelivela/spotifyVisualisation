resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.extract_data_lambda_func.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.every_thousand_minutes.arn}"
}

# Declare a new API Gateway REST API
resource "aws_api_gateway_rest_api" "rest_api" {
  # The name of the REST API
  name = "test_api_${var.env}"

  # An optional description of the REST API
  description = "A Prototype REST API for testing"
}


# Set permissions on the lambda function, allowing API Gateway to invoke the function
resource "aws_lambda_permission" "allow_api_gateway" {
  # The action this permission allows is to invoke the function
  action = "lambda:InvokeFunction"

  # The name of the lambda function to attach this permission to
  function_name = "${aws_lambda_function.extract_data_lambda_func.function_name}"

  # An optional identifier for the permission statement
  statement_id = "AllowExecutionFromApiGateway"

  # The item that is getting this lambda permission
  principal = "apigateway.amazonaws.com"

  # /*/*/* sets this permission for all stages, methods, and resource paths in API Gateway to the lambda
  # function. - https://bit.ly/2NbT5V5
  source_arn = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"

  depends_on = [
    aws_api_gateway_rest_api.rest_api
  ]
}
