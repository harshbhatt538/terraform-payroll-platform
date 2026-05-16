import boto3
import json
import os

def get_db_credentials():
    """
    Fetch DB credentials from Secrets Manager at runtime.
    Never reads from environment variables or config files.
    Secret name is injected via environment variable — not hardcoded.
    """
    secret_name = os.environ["DB_SECRET_NAME"]
    region = os.environ.get("AWS_REGION", "eu-west-2")

    client = boto3.client("secretsmanager", region_name=region)

    response = client.get_secret_value(SecretId=secret_name)
    secret = json.loads(response["SecretString"])

    return {
        "host": os.environ["DB_HOST"],      # injected via terraform output
        "port": 5432,
        "database": secret["dbname"],
        "user": secret["username"],
        "password": secret["password"]      # never logged, never printed
    }