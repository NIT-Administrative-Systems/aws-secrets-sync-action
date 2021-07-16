# Make this a list of your secrets. These names should match the Jenkins credential IDs.
locals {
    parameters = ["nickTest", "jasonTest"]
}

resource "aws_ssm_parameter" "secure_param" {
  count = length(local.parameters)

  name        = "/action-ssm-secrets-sync-action/tech-demo/${local.parameters[count.index]}"
  description = "Demo secret: ${local.parameters[count.index]}"
  type        = "SecureString"
  value       = "SSM parameter store not populated from Jenkins"
  key_id      = aws_kms_key.key.arn

  # The parameter will be created with a dummy value. Jenkins will update it with 
  # the final value in a subsequent pipeline step.
  #
  # TF will not override the parameter once it has been created.
  lifecycle {
    ignore_changes = [value]
  }
}

output "parameters" {
    value = zipmap(local.parameters, slice(aws_ssm_parameter.secure_param.*.name, 0, length(local.parameters)))
}

resource "aws_kms_key" "key" {
  description = "action-ssm-secrets-sync-action"
}