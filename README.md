# Infrastructure Scanner

This repository contains all of the code necessary to scan infra in AWS with [Cloudsploit](https://github.com/aquasecurity/cloudsploit).

It orchestrates AWS Step Functions, Lambda, and ECS to do all the heavy lifting around CSPM scanning.

## Features

- [x] List the child-accounts in the Organization (excluding the payer account).
- [x] Create an ECS task to scans your infrastruture with Cloudsploit.
- [x] Assume `OrganizationAccountAccessRole` to scan child accounts.
- [x] Write the scan reports to `s3://$S3_BUCKET/$DATE/$ACCOUNT.json`.
- [x] Trigger the step function daily on a cronjob.
- [x] Add GH Actions pipeline to continuously deploy to AWS account.
- [ ] Add a way to exclude accounts.
- [ ] Soft fail when `OrganizationAccountAccessRole` is not present.
- [x] Gather the scan reports from all accounts in a single report.
- [x] Transform the unified scan report into a nice HTML view.
- [x] Add a static S3+Cloudfront site displaying the scan results.
- [x] Add simple HTTP auth for the scan result site

## Requirements

- Latest stable terraform, e.g. `brew install terraform`
- Python 3.11
- `pipenv`, ideally together with `pyenv`
- `pre-commit install` to have pre-commit hooks run before committing
- `colima start --arch x86_64` to build x64 docker images on Apple Silicon.

## Nota bene

There are a couple of things you need to know about this repository.

### Stages and Organizations

For simplicity's sake, this codebase ignores the notion of multiple stages. Best practice dictates that separate stages should be deployed in separate AWS accounts. However, this project is meant to be deployed into the **Organization's payer account**. In earlier iterations of this project, this infrastructure was deployed to a child-account in the AWS Organization. The complexity overhead of using a trampoline role in the Organization's payer account just to be able to assume the `OrganizationAccountAccessRole` in the child accounts through in the code was not deemed to be worth it. It is possible and I've used it elsewhere, but chose not to here. If you would like to bring this in, please let me know.

### Always use `make`

Please make sure to always use `make`. It orchestrates the entire build process and sets up the environments correctly.

- `make`: Default target that builds everything
- `make clean`: Removes the `build` folder.
- `make format`: Formats Python and Terraform
- `make test-format`: Checks format for Python and Terraform
- `make test-unit`: Runs Python unit tests
- `make docker`: Builds the docker containers (requires ECR to have been created!)
- `make python`: Builds the Python lambdast
- `make terraform-plan`: (Optional) Runs `terraform plan`
- `make terraform-apply`: Runs `terraform apply`
- `make backend`: Runs `backend-plan` and `backend-apply`.
- `make backend-plan`: Runs `terraform plan` for the backend and stores the Terraform state and plan in the `.tf-backend` folder
- `make backend-apply`: Runs `terraform apply` for the backend and stores the Terraform state and plan in the `.tf-backend` folder. Requires `make backend-plan` to have run before!

### `infra/.tf-backend`

This builds the Terraform backend for the whole operation. It is **not a module**, hence it does not contain a `main.tf` to avoid confusion. This needs to be applied first, but it needs to be applied only once **from within the `infra/.tf-backend` directory**. Once applied, you're done. It creates the backend for Terraform to put its state for all future operations in DynamoDB of the account you are authenticated with. This is being run on a developer's machine. The `.tfstate` *should* be kept safe somewhere, albeit it's just an S3 bucket and a DynamoDB table.

If you require multiple backends for multiple organizations, please feel free to use `terraform workspace`, albeit this is not covered in the Makefile.

The files `infra/.tf-backend/backend.tfplan` and `infra/.tf-backend/backend.tfstate` are ignored from version control.

### `infra/main.tf`

This is the root of the infrastructure orchestration. Everything interesting has been packaged up into modules as far as possible.

### `steps`

Here are the AWS Lambda Functions and ECS tasks. This directory includes all the steps within the step function.

* List: Python lambda that lists out the sub-accounts in the org.
* Scan: ECS task that scans your infrastruture with Cloudsploit and writes the result to `s3://$S3_BUCKET/$DATE/$ACCOUNT.json`

If you have any suggestions about what to do with the scan data, please let me know.
