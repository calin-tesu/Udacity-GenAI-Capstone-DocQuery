import boto3
import time
import os
import sys

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
    # Check if arguments are provided via CLI, otherwise fallback to help
    if len(sys.argv) < 3:
        print("Usage: python initialize_db.py <CLUSTER_ARN> <SECRET_ARN>")
        sys.exit(1)

    CLUSTER_ARN = sys.argv[1]
    SECRET_ARN = sys.argv[2]
    DB_NAME = "myapp"
    
    script_dir = os.path.dirname(__file__)
    sql_path = os.path.join(script_dir, "aurora_sql.sql")
    
    if not os.path.exists(sql_path):
        print(f"Error: SQL file not found at {sql_path}")
        sys.exit(1)

    initialize_database(CLUSTER_ARN, SECRET_ARN, DB_NAME, sql_path)