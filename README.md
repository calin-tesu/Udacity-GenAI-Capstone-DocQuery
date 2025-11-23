# Udacity GenAI Capstone: Intelligent Document Query System

This repository contains the capstone project for the Udacity "Future AWS AI Engineer - Generative AI" nanodegree, which I completed as a recipient of a scholarship sponsored by Amazon AWS.

The project is an end-to-end Retrieval-Augmented Generation (RAG) system that creates a conversational knowledge base from documents stored in an AWS S3 bucket. It allows users to ask questions in natural language and receive accurate, context-aware answers synthesized directly from the source documents, demonstrating key skills in generative AI, cloud architecture, and large language models.

## Table of Contents

1. [Project Overview](#project-overview)
   - [Udacity Nanodegree Context](#udacity-nanodegree-context)
2. [Architecture](#architecture)
3. [Application Demo](#application-demo)
2. [Prerequisites](#prerequisites)
3. [Project Structure](#project-structure)
4. [Deployment Steps](#deployment-steps)
5. [Using the Scripts](#using-the-scripts)
6. [Customization](#customization)
7. [Troubleshooting](#troubleshooting)

## Project Overview

This project demonstrates the implementation of a full Retrieval-Augmented Generation (RAG) pipeline using AWS services. The goal is to create a Bedrock Knowledge Base that can leverage data stored in an Aurora Serverless database, with the ability to easily upload supporting documents to S3. This allows a Large Language Model (LLM) to answer questions using information from a private document collection.

### Udacity Nanodegree Context
This project serves as the capstone requirement for the "Future AWS AI Engineer - Generative AI" nanodegree from Udacity. The scholarship for this program was provided by Amazon AWS, focusing on practical, hands-on skills in building and deploying generative AI applications on the AWS cloud.

## Architecture
The infrastructure is deployed using Terraform and is divided into two main stacks:
- **Stack 1:** Sets up the foundational resources, including a VPC, an Aurora Serverless PostgreSQL cluster (for vector storage), an S3 bucket for documents, and the necessary IAM roles.
- **Stack 2:** Deploys the AI components, including the Bedrock Knowledge Base and its associated IAM roles, linking it to the resources created in Stack 1.

## Application Demo

The project features a simple and intuitive web interface built with Streamlit, allowing users to interact with the knowledge base in a conversational manner.

![Streamlit Application UI](https://github.com/calin-tesu/Udacity-GenAI-Capstone-DocQuery/blob/main/Screenshots/streamlit%20interface.png)


## Prerequisites

Before you begin, ensure you have the following:

- AWS CLI installed and configured with appropriate credentials
- Terraform installed (version 0.12 or later)
- Python 3.10 or later
- pip (Python package manager)

## Project Structure

```
project-root/
│
├── stack1
|   ├── main.tf
|   ├── outputs.tf
|   └── variables.tf
|
├── stack2
|   ├── main.tf
|   ├── outputs.tf
|   └── variables.tf
|
├── modules/
│   ├── aurora_serverless/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── bedrock_kb/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── scripts/
│   ├── aurora_sql.sql
│   └── upload_to_s3.py
│
├── spec-sheets/
│   └── machine_files.pdf
│
└── README.md
```

## Deployment Steps

1. Clone this repository to your local machine.

2. Navigate to the project Stack 1. This stack includes VPC, Aurora servlerless and S3

3. Initialize Terraform:
   ```
   terraform init
   ```

4. Review and modify the Terraform variables in `main.tf` as needed, particularly:
   - AWS region
   - VPC CIDR block
   - Aurora Serverless configuration
   - s3 bucket

5. Deploy the infrastructure:
   ```
   terraform apply
   ```
   Review the planned changes and type "yes" to confirm.

6. After the Terraform deployment is complete, note the outputs, particularly the Aurora cluster endpoint.

7. Prepare the Aurora Postgres database. This is done by running the sql queries in the script/ folder. This can be done through Amazon RDS console and the Query Editor.

8. Navigate to the project Stack 2. This stack includes Bedrock Knowledgebase

9. Initialize Terraform:
   ```
   terraform init
   ```

10. Use the values outputs of the stack 1 to modify the values in `main.tf` as needed:
     - Bedrock Knowledgebase configuration

11. Deploy the infrastructure:
      ```
      terraform apply
      ```
      - Review the planned changes and type "yes" to confirm.


12. Upload pdf files to S3, place your files in the `spec-sheets` folder and run:
      ```
      python scripts/upload_to_s3.py
      ```
      - Make sure to update the S3 bucket name in the script before running.

13. Sync the data source in the knowledgebase to make it available to the LLM.

## Using the Scripts

### S3 Upload Script

The `upload_to_s3.py` script does the following:
- Uploads all files from the `spec-sheets` folder to a specified S3 bucket
- Maintains the folder structure in S3

To use it:
1. Update the `bucket_name` variable in the script with your S3 bucket name.
2. Optionally, update the `prefix` variable if you want to upload to a specific path in the bucket.
3. Run `python scripts/upload_to_s3.py`.

## Complete chat app

### Complete invoke model and knoweldge base code
- Open the bedrock_utils.py file and the following functions:
  - query_knowledge_base
  - generate_response

### Complete the prompt validation function
- Open the bedrock_utils.py file and the following function:
  - valid_prompt

  Hint: categorize the user prompt

## Troubleshooting

- If you encounter permissions issues, ensure your AWS credentials have the necessary permissions for creating all the resources.
- For database connection issues, check that the security group allows incoming connections on port 5432 from your IP address.
- If S3 uploads fail, verify that your AWS credentials have permission to write to the specified bucket.
- For any Terraform errors, ensure you're using a compatible version and that all module sources are correctly specified.

For more detailed troubleshooting, refer to the error messages and logs provided by Terraform and the Python scripts.
