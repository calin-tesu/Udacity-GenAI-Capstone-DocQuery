import boto3
import os
import sys

def get_aws_account_id():
    """Fetches the current AWS Account ID using STS."""
    try:
        sts = boto3.client('sts')
        return sts.get_caller_identity()['Account']
    except Exception as e:
        print(f"Error fetching AWS Account ID: {e}")
        sys.exit(1)

def update_terraform_files(root_dir, search_text, replace_text):
    """
    Iterates through .tf files and replaces a placeholder with the actual ID.
    """
    files_updated = 0
    
    # We walk the directory to find all .tf files
    for root, dirs, files in os.walk(root_dir):
        # Efficiency: Skip the .terraform directory if it exists
        if '.terraform' in dirs:
            dirs.remove('.terraform')
            
        for file in files:
            if file.endswith(".tf"):
                file_path = os.path.join(root, file)
                
                # Read the file content
                with open(file_path, 'r') as f:
                    content = f.read()
                
                # Check if the placeholder exists
                if search_text in content:
                    print(f"Updating: {file_path}")
                    new_content = content.replace(search_text, replace_text)
                    
                    # Write the updated content back
                    with open(file_path, 'w') as f:
                        f.write(new_content)
                    files_updated += 1

    return files_updated

if __name__ == "__main__":
    # 1. Get the real ID from your current AWS session
    account_id = get_aws_account_id()
    placeholder = "YOUR_AWS_ACCOUNT_ID"
    
    # 2. Define the project root (one level up from this script)
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    
    print(f"Detected Account ID: {account_id}")
    print(f"Scanning files in: {project_root}...")
    
    # 3. Perform the replacement
    count = update_terraform_files(project_root, placeholder, account_id)
    
    if count > 0:
        print(f"Successfully updated {count} files.")
    else:
        print("No placeholders found. Your files are likely already configured.")