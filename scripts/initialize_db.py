import boto3
import time
import os

def initialize_database(cluster_arn, secret_arn, database_name, sql_file_path):
    rds_data = boto3.client('rds-data')
    
    print(f"Reading SQL from {sql_file_path}...")
    with open(sql_file_path, 'r') as f:
        # Split by semicolon to run statements individually, or run as one block
        # For simplicity and handling the DO block, we'll execute the whole file
        sql_script = f.read()

    print("Executing SQL via RDS Data API...")
    try:
        response = rds_data.execute_statement(
            resourceArn=cluster_arn,
            secretArn=secret_arn,
            database=database_name,
            sql=sql_script
        )
        print("Database initialized successfully.")
        return response
    except Exception as e:
        print(f"Error initializing database: {e}")
        # If the cluster is 'pausing' or 'starting', we might need to retry
        if "BadRequestException" in str(e) and "is not currently running" in str(e):
            print("Cluster is waking up... retrying in 15 seconds.")
            time.sleep(15)
            return initialize_database(cluster_arn, secret_arn, database_name, sql_file_path)
        raise e

if __name__ == "__main__":
    # In a real scenario, you'd fetch these from Terraform outputs 
    # or environment variables after running Stack 1.
    
    # You can get these values by running 'terraform output' in the stack1 directory
    CLUSTER_ARN = input("Enter your Aurora Cluster ARN: ")
    SECRET_ARN = input("Enter your Secrets Manager ARN: ")
    DB_NAME = "myapp"
    
    script_dir = os.path.dirname(__file__)
    sql_path = os.path.join(script_dir, "aurora_sql.sql")
    
    initialize_database(CLUSTER_ARN, SECRET_ARN, DB_NAME, sql_path)