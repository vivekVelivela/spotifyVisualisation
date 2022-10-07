

resource "aws_api_gateway_resource" "proxy" {
  # The id of the associated REST API and parent API resource are required
  rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
  parent_id = "${aws_api_gateway_rest_api.rest_api.root_resource_id}"

  # The last segment of the URL path for this API resource
  path_part = "{proxy+}"
}

# Provide an HTTP method to a API Gateway resource (REST endpoint)
resource "aws_api_gateway_method" "proxy" {
  # The ID of the REST API and the resource at which the API is invoked
  rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"

  # The verb of the HTTP request
  http_method = "ANY"

  # Whether any authentication is needed to call this endpoint
  authorization = "NONE"
}



resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.extract_data_lambda_func.invoke_arn}"
}
resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.rest_api.id}"
  resource_id   = "${aws_api_gateway_rest_api.rest_api.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.extract_data_lambda_func.invoke_arn}"
}


resource "aws_api_gateway_deployment" "rest_api" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
  stage_name  = "test"
}

output "url" {
  value = "${aws_api_gateway_deployment.rest_api.invoke_url}"
}