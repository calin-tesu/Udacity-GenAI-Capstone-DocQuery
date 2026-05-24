.PHONY: all bootstrap config stack1 init-db stack2 ingest destroy help

help:
	@echo "Available commands:"
	@echo "  make deploy-all  - Run the entire deployment sequence"
	@echo "  make bootstrap   - Deploy the S3/DynamoDB state backend"
	@echo "  make config      - Update account IDs in TF files"
	@echo "  make stack1      - Deploy VPC, RDS, and S3"
	@echo "  make init-db     - Initialize the Aurora Database schema"
	@echo "  make stack2      - Deploy Bedrock Knowledge Base"
	@echo "  make ingest      - Upload documents and sync"
	@echo "  make destroy     - Tear down all infrastructure"

bootstrap:
	@echo "--- Deploying Bootstrap Stack ---"
	cd bootstrap && terraform init && terraform apply -auto-approve

config:
	@echo "--- Configuring Remote Backends ---"
	python scripts/setup_backends.py

stack1:
	@echo "--- Deploying Stack 1 (Foundation) ---"
	cd stack1 && terraform init && terraform apply -auto-approve

init-db:
	@echo "--- Initializing Aurora Database ---"
	$(eval CLUSTER_ARN := $(shell cd stack1 && terraform output -raw aurora_arn))
	$(eval SECRET_ARN := $(shell cd stack1 && terraform output -raw rds_secret_arn))
	python scripts/initialize_db.py $(CLUSTER_ARN) $(SECRET_ARN)

stack2:
	@echo "--- Deploying Stack 2 (Bedrock AI) ---"
	cd stack2 && terraform init && terraform apply -auto-approve

ingest:
	@echo "--- Ingesting Data ---"
	python scripts/upload_s3.py
	@echo "Manual Step Required: Log into AWS Console and trigger 'Sync' on Bedrock Knowledge Base."

deploy-all: bootstrap config stack1 init-db stack2 ingest
	@echo "--- Full Deployment Complete ---"

destroy:
	@echo "--- Destroying Everything (Reverse Order) ---"
	-cd stack2 && terraform destroy -auto-approve
	-cd stack1 && terraform destroy -auto-approve
	-cd bootstrap && terraform destroy -auto-approve