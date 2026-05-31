.PHONY: all bootstrap config stack1 init-db stack2 ingest config-app destroy help

help:
	@echo "Available commands:"
	@echo "  make deploy-all  - Run the entire deployment sequence"
	@echo "  make bootstrap   - Deploy the S3/DynamoDB state backend"
	@echo "  make config      - Update account IDs in TF files"
	@echo "  make stack1      - Deploy VPC, RDS, and S3"
	@echo "  make init-db     - Initialize the Aurora Database schema"
	@echo "  make stack2      - Deploy Bedrock Knowledge Base"
	@echo "  make ingest      - Upload documents and sync"
	@echo "  make config-app  - Generate .env for Streamlit"
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
	$(eval DB_NAME := $(shell cd stack1 && terraform output -raw db_name))
	$(eval TABLE_NAME := $(shell cd stack1 && terraform output -raw aurora_table_name))
	python scripts/initialize_db.py $(CLUSTER_ARN) $(SECRET_ARN) $(DB_NAME) $(TABLE_NAME)

stack2:
	@echo "--- Deploying Stack 2 (Bedrock AI) ---"
	cd stack2 && terraform init && terraform apply -auto-approve

ingest:
	@echo "--- Ingesting Data ---"
	$(eval BUCKET_NAME := $(shell cd stack1 && terraform output -raw s3_bucket_name))
	S3_BUCKET_NAME=$(BUCKET_NAME) python scripts/upload_s3.py
	@echo "Manual Step Required: Log into AWS Console and trigger 'Sync' on Bedrock Knowledge Base."

config-app:
	@echo "--- Generating .env file for Streamlit ---"
	$(eval KB_ID := $(shell cd stack2 && terraform output -raw bedrock_knowledge_base_id))
	$(eval REGION := $(shell cd stack1 && terraform output -raw aws_region 2>/dev/null || echo "us-west-2"))
	@echo "KNOWLEDGE_BASE_ID=$(KB_ID)" > .env
	@echo "AWS_REGION=$(REGION)" >> .env
	@echo ".env file generated successfully."

deploy-all: bootstrap config stack1 init-db stack2 ingest config-app
	@echo "--- Full Deployment Complete ---"

destroy:
	@echo "--- Destroying Everything (Reverse Order) ---"
	-cd stack2 && terraform destroy -auto-approve
	-cd stack1 && terraform destroy -auto-approve
	-cd bootstrap && terraform destroy -auto-approve