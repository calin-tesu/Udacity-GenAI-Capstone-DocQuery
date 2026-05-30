import boto3
import time
import os
import sys

# Parameter Injection: I added max_retries=10 as an optional parameter.
# This allows you to override it later if you find the database takes longer
# to wake up in certain regions without changing the function's internal logic.
def initialize_database(cluster_arn, secret_arn, database_name, sql_file_path, max_retries=10):
    rds_data = boto3.client('rds-data')
    
    print(f"Reading SQL from {sql_file_path}...")
    # The RDS Data API has a limit on the size of the sql string parameter (usually around 64KB). 
    # For this project, aurora_sql.sql is small, so it's fine. 
    # However, as you grow as a developer, keep in mind that if you ever have a massive migration script, 
    # you would need to split the file and execute statements one by one in a loop rather than 
    # reading the whole file at once
    with open(sql_file_path, 'r') as f:
        sql_script = f.read()

    for attempt in range(max_retries):
        print(f"Executing SQL via RDS Data API (Attempt {attempt + 1}/{max_retries})...")
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
            # Check if the error is specifically about the cluster not being running
            is_retryable = "BadRequestException" in str(e) and "is not currently running" in str(e)
            
            if is_retryable and attempt < max_retries - 1:
                print(f"Cluster is waking up... retrying in 15 seconds.")
                time.sleep(15)
                continue
            
            print(f"Error initializing database: {e}")
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