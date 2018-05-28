resource "aws_lambda_function" "autospotting" {
  count = "${var.lambda_s3_bucket == "" ? 1 : 0}"

  function_name    = "autospotting"
  filename         = "${path.module}/${var.lambda_zipname}"
  source_code_hash = "${base64sha256(file("${path.module}/${var.lambda_zipname}"))}"
  role             = "${aws_iam_role.autospotting_role.arn}"
  runtime          = "${var.lambda_runtime}"
  timeout          = "${var.lambda_timeout}"
  handler          = "autospotting"
  memory_size      = "${var.lambda_memory_size}"
  tags             = "${var.lambda_tags}"

  environment {
    variables = {
      ALLOWED_INSTANCE_TYPES       = "${var.autospotting_allowed_instance_types}"
      DISALLOWED_INSTANCE_TYPES    = "${var.autospotting_disallowed_instance_types}"
      MIN_ON_DEMAND_NUMBER         = "${var.autospotting_min_on_demand_number}"
      MIN_ON_DEMAND_PERCENTAGE     = "${var.autospotting_min_on_demand_percentage}"
      ON_DEMAND_PRICE_MULTIPLIER   = "${var.autospotting_on_demand_price_multiplier}"
      SPOT_PRICE_BUFFER_PERCENTAGE = "${var.autospotting_spot_price_buffer_percentage}"
      SPOT_PRODUCT_DESCRIPTION     = "${var.autospotting_spot_product_description}"
      BIDDING_POLICY               = "${var.autospotting_bidding_policy}"
      REGIONS                      = "${var.autospotting_regions_enabled}"
      TAG_FILTERS                  = "${var.autospotting_tag_filters}"
      TAG_FILTERING_MODE           = "${var.autospotting_tag_filtering_mode}"
    }
  }
}

resource "aws_lambda_function" "autospotting_from_s3" {
  count = "${var.lambda_s3_bucket == "" ? 0 : 1}"

  function_name = "autospotting"
  s3_bucket     = "${var.lambda_s3_bucket}"
  s3_key        = "${var.lambda_s3_key}"
  role          = "${aws_iam_role.autospotting_role.arn}"
  runtime       = "${var.lambda_runtime}"
  timeout       = "${var.lambda_timeout}"
  handler       = "autospotting"
  memory_size   = "${var.lambda_memory_size}"
  tags          = "${var.lambda_tags}"

  environment {
    variables = {
      ALLOWED_INSTANCE_TYPES       = "${var.autospotting_allowed_instance_types}"
      DISALLOWED_INSTANCE_TYPES    = "${var.autospotting_disallowed_instance_types}"
      MIN_ON_DEMAND_NUMBER         = "${var.autospotting_min_on_demand_number}"
      MIN_ON_DEMAND_PERCENTAGE     = "${var.autospotting_min_on_demand_percentage}"
      ON_DEMAND_PRICE_MULTIPLIER   = "${var.autospotting_on_demand_price_multiplier}"
      SPOT_PRICE_BUFFER_PERCENTAGE = "${var.autospotting_spot_price_buffer_percentage}"
      SPOT_PRODUCT_DESCRIPTION     = "${var.autospotting_spot_product_description}"
      BIDDING_POLICY               = "${var.autospotting_bidding_policy}"
      REGIONS                      = "${var.autospotting_regions_enabled}"
      TAG_FILTERS                  = "${var.autospotting_tag_filters}"
      TAG_FILTERING_MODE           = "${var.autospotting_tag_filtering_mode}"
    }
  }
}


resource "aws_iam_role" "autospotting_role" {
  name                  = "autospotting"
  path                  = "/lambda/"
  assume_role_policy    = "${file("${path.module}/lambda-policy.json")}"
  force_detach_policies = true
}

resource "aws_iam_role_policy" "autospotting_policy" {
  name   = "policy_for_autospotting"
  role   = "${aws_iam_role.autospotting_role.id}"
  policy = "${file("${path.module}/autospotting-policy.json")}"
}

resource "aws_lambda_permission" "cloudwatch_events_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${module.aws_lambda_function.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.cloudwatch_frequency.arn}"
}

resource "aws_cloudwatch_event_target" "cloudwatch_target" {
  rule      = "${aws_cloudwatch_event_rule.cloudwatch_frequency.name}"
  target_id = "run_autospotting"
  arn       = "${module.aws_lambda_function.arn}"
}

resource "aws_cloudwatch_event_rule" "cloudwatch_frequency" {
  name                = "autospotting_frequency"
  schedule_expression = "${var.lambda_run_frequency}"
}

resource "aws_cloudwatch_log_group" "log_group_autospotting" {
  name              = "/aws/lambda/${module.aws_lambda_function.function_name}"
  retention_in_days = 7
}
