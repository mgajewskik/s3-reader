# S3 Reader

Simple application that reads files from S3 bucket and prints them out.

## Usage

1. Add a commit conforming to [the conventional commits standard](https://www.conventionalcommits.org/en/v1.0.0/#summary), e.g. `feat` and `fix` to change the application code, `infra` and `build` to change the Packer and Terraform configurations so no new versions are created if we are only fixing the infrastructure configuration
2. Push the commit to the repository
3. If new release is created, the application will be deployed with a new version
4. If no new release is created, the application will be deployed with the last tagged version giving a chance to modify infrastructure configuration only
5. If the release is broken, it will be automatically rolled back to the previously working version
6. If the traffic increases, the application will be automatically scaled up to handle the load
7. If the deployment passes but the API is in fact broken, the dummy test in the CI will fail

## Testing

When running the application locally use helper `run` script that is also used in the CI/CD pipeline.

Running `./run` will display help message with available commands.

When deploying the Terraform configuration in your own AWS account make sure to change the Terraform backend first.

## Assumptions

- API is in the simplest possible form as the whole automation is more important
- GH Action is simplified leaving huge potential for additional validations and options
- using [mise](https://github.com/jdx/mise) for dependencies management and versioning
- single monorepo for API and infrastructure code
- conventional commits to automate releases creation and differentiate API versioning and infrastructure changes
- using Packer to build AMI declaratively with the latest version of the API
- using default VPC and subnets to simplify configuration
- using Application Load Balancer due to it's `RequestCountPerTarget` metric which allows for easy scaling based on the number of incoming requests
- using rolling release strategy which plays nicely with the AWS Auto Scaling Groups and monorepo where deployments are fully automated
- logs are streamed to CloudWatch Logs for easy access and monitoring

## Improvements

- add auto generation of GitHub releases with changelog
- Go binary caching for faster builds when no new release is triggered
- more parametrization options for the AMI builds and Terraform configuration
- enable deployments to multiple environments with parametrized options
- refactor Terraform code into modules for better reusability between environments
- S3 state backend needs DynamoDB locks
- S3 storage bucket should be kept in a separate state to avoid deletion when infrastructure will have to be destroyed
- implement AMI cleanup for old code versions
- add proper tagging to all Terraform resources
- add custom IAM policies for more fine-grained permissions
- harden AMIs with proper security settings
- fix SSM connection issue
- implement log file rotation, maybe use something like Fluent Bit
- add TLS encryption for the ALB traffic
- refactor run helper script to be more robust and handle more cases
- add automated way for destroying the infrastructure
- add way to deploy the infrastructure from the specific tag
- could change the deployment strategy to canary but then it would require more manual intervention or more complex automation
