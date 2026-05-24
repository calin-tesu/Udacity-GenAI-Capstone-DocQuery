# DocQuery — Intelligent Document Query System

An end-to-end **Retrieval-Augmented Generation (RAG)** system built on AWS. Upload your documents to S3, and ask questions in plain language — DocQuery retrieves the relevant context and generates accurate answers from your private document collection.

Built as the capstone project for Udacity's *AWS AI Engineer* Nanodegree (Amazon AWS-sponsored scholarship).

📜 [View Verified Certificate](https://www.udacity.com/certificate/e/b15cc804-8152-11f0-b385-4b316d10a96c)

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Tech Stack](#tech-stack)
4. [Demo](#demo)
5. [Quick Start](#quick-start)
6. [Make Commands](#make-commands)
7. [Project Structure](#project-structure)
8. [Customization](#customization)
9. [Troubleshooting](#troubleshooting)

---

## Overview

DocQuery answers questions from your own documents — PDFs, specs, manuals, reports — without exposing them to public models or third-party services. The entire pipeline runs inside your AWS account.

**What it does:**
- Ingests documents from S3 into a vector store (Aurora Serverless PostgreSQL with pgvector)
- Uses AWS Bedrock Knowledge Base to retrieve semantically relevant chunks at query time
- Passes retrieved context to a Bedrock LLM to generate accurate, grounded answers
- Exposes a simple conversational UI via Streamlit

---

## Architecture

The infrastructure is split into two Terraform stacks connected via a shared S3/DynamoDB remote state backend, deployed automatically in sequence.

```
┌─────────────────────────────────────────────────────────┐
│                        Stack 1                          │
│   VPC  →  Aurora Serverless PostgreSQL (pgvector)       │
│        →  S3 Bucket (document storage)                  │
│        →  IAM Roles                                     │
└────────────────────┬────────────────────────────────────┘
                     │ Remote State
┌────────────────────▼────────────────────────────────────┐
│                        Stack 2                          │
│   Bedrock Knowledge Base  →  Bedrock LLM (Claude)       │
│   (reads Stack 1 outputs automatically via remote state)│
└─────────────────────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                    Streamlit UI                          │
│   Conversational interface → Bedrock Knowledge Base API  │
└─────────────────────────────────────────────────────────┘
```

**Remote state backend** (S3 + DynamoDB) is bootstrapped first, enabling Stack 2 to read Stack 1 outputs without any manual variable copying.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Infrastructure as Code | Terraform (modular, two-stack) |
| Vector Store | Aurora Serverless v2 PostgreSQL + pgvector |
| Document Storage | AWS S3 |
| RAG Orchestration | AWS Bedrock Knowledge Base |
| LLM | Amazon Bedrock (Claude) |
| UI | Streamlit |
| Automation | GNU Make + Python scripts |
| State Backend | S3 + DynamoDB (Terraform remote state) |

---

## Demo

![Streamlit Application UI](Screenshots/streamlit%20interface.png)

---

## Quick Start

### Prerequisites

- AWS CLI configured with appropriate credentials and permissions
- Terraform ≥ 1.0
- Python 3.10+
- GNU Make

### One-command deployment

```bash
make deploy-all
```

This single command runs the full deployment sequence:

1. **Bootstrap** — creates the S3 bucket and DynamoDB table for Terraform remote state
2. **Config** — injects your AWS account ID into all Terraform backend configurations
3. **Stack 1** — deploys VPC, Aurora Serverless PostgreSQL, S3 bucket, and IAM roles
4. **Init DB** — connects to Aurora and initialises the pgvector schema (ARNs are read automatically from Stack 1 outputs)
5. **Stack 2** — deploys the Bedrock Knowledge Base, linked to Stack 1 resources via remote state
6. **Ingest** — uploads documents from `spec-sheets/` to S3

> **Note:** After `make ingest` completes, log into the AWS Console and trigger a **Sync** on the Bedrock Knowledge Base data source to make your documents available for querying. This step requires a manual action in the AWS Console as the Bedrock sync API does not yet support full programmatic triggering via Terraform.

### Run the UI

```bash
pip install -r requirements.txt
streamlit run app.py
```

### Tear down

```bash
make destroy
```

Destroys all infrastructure in reverse order (Stack 2 → Stack 1 → Bootstrap).

---

## Make Commands

```
make deploy-all   Run the entire deployment sequence (recommended)
make bootstrap    Deploy the S3/DynamoDB Terraform state backend
make config       Inject AWS account ID into Terraform backend configs
make stack1       Deploy VPC, Aurora Serverless, and S3
make init-db      Initialise the Aurora pgvector schema
make stack2       Deploy Bedrock Knowledge Base
make ingest       Upload documents to S3
make destroy      Tear down all infrastructure in reverse order
make help         Show this command list
```

---

## Project Structure

```
project-root/
│
├── bootstrap/                  # S3 + DynamoDB remote state backend
│
├── stack1/                     # Foundation infrastructure
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
│
├── stack2/                     # Bedrock AI layer
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
│
├── modules/
│   ├── aurora_serverless/      # Aurora Serverless PostgreSQL module
│   └── bedrock_kb/             # Bedrock Knowledge Base module
│
├── scripts/
│   ├── setup_backends.py       # Injects account ID into TF backend configs
│   ├── aurora_sql.sql          # pgvector schema — executed automatically by initialize_db.py
│   ├── initialize_db.py        # Initialises pgvector schema via RDS Data API (reads aurora_sql.sql)
│   └── upload_s3.py            # Uploads documents from spec-sheets/ to S3
│
├── spec-sheets/                # Place your PDF documents here before ingesting
│
├── app.py                      # Streamlit UI
├── bedrock_utils.py            # Bedrock Knowledge Base query logic
├── requirements.txt
└── Makefile                    # Orchestrates the full deployment
```

---

## Customization

All key parameters are set in `stack1/variables.tf` and `stack2/variables.tf`:

- **AWS region** — defaults to `us-east-1`
- **VPC CIDR block**
- **Aurora Serverless capacity** — min/max ACUs
- **S3 bucket name**
- **Bedrock model ID** — swap the LLM without changing anything else

To add your own documents: place PDF files in the `spec-sheets/` folder and run `make ingest`, then trigger a sync in the AWS Console.

---

## Troubleshooting

**Permissions errors during `terraform apply`**
Ensure your AWS credentials have permissions for VPC, RDS, S3, IAM, and Bedrock. A broad `AdministratorAccess` policy works for development.

**Database connection issues**
Check that the Aurora security group allows inbound connections on port 5432 from the Lambda or script executing `initialize_db.py`.

**`make config` fails**
Ensure Python 3.10+ is active and `boto3` is installed (`pip install boto3`).

**S3 upload fails**
Verify your credentials have `s3:PutObject` on the target bucket.

**`make init-db` hangs or retries**
Aurora Serverless may be in a paused state after inactivity. The script detects this automatically and retries after 15 seconds. Allow up to a minute for the cluster to wake up before assuming a failure.

**Bedrock Knowledge Base returns no results after ingestion**
Confirm you triggered a **Sync** on the data source in the AWS Console after uploading documents.

---

## License

MIT License