# ssm-secrets-sync-action
Synchronizes GitHub secrets to AWS per the Admin Systems secrets management strategy. 

This action can synchronize from GitHub repository secrets to AWS SSM Parameter Store, AWS Secrets Manager, and Laravel Vapor.

You should review the [Terraform setup for building SSM parameters](https://nit-administrative-systems.github.io/AS-CloudDocs/infrastructure/secrets.html#terraform-setup). This action espects the `parameters` output from your terraform module.

You will need to set up your secrets on your GitHub repository. Keep in mind that you will need to enter your dev/qa/prod secrets, so you may wish to name things `{ENV}_{SECRET NAME}`.

## Usage
To use this action, you should already have Terraform set up with the [`hashicorp/setup-terraform` action](https://github.com/hashicorp/setup-terraform). Since you are mapping the secret values, you will likely need several copies of this step. You can select which to run with the `if` statement.

```yaml
    - uses: nit-administrative-systems/aws-secrets-sync-action@v2.0.0
      if: github.ref == 'refs/heads/develop'
      env: 
        AWS_ACCESS_KEY_ID: ${{ secrets.TF_KEY_ACCT_ENV }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.TF_SECRET_ACCT_ENV }} 
      with:
        to: ssm
        region: us-east-2
        tf-module-path: iac/
        secret-values: |
          {
            "APIGEE_KEY": "${{ secrets.dev_apigee_key }}",
            "DB_PASSWORD": "${{ secrets.dev_db_password }}"
          }
```

### Inputs
- `to` - (required) The AWS service you want to publish to. Supported values are `ssm` for AWS SSM Parameter Store.
- `tf-module-path` - (required) The path to your Terraform module that defines the `parameters` output.
- `secret-values` - (required) A JSON object with each key being a parameter name from your TF module, and each value being the value. Values should be a GitHub actions expression loading a secret value. These will be obfuscated in the logs.
- `region` - (optional) The AWS region in which your parameters exist. This defaults to `us-east-2`.

### Outputs
There are no outputs from this action.

## Releasing
To release an update, run `npm run package` and commit the new `dist/` files. Then, tag the repo.