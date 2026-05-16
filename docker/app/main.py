from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/health")
def health():
    return jsonify({
        "status": "healthy",
        "service": os.environ.get("SERVICE_NAME", "unknown"),
        "environment": os.environ.get("APP_ENV", "dev")
    })

@app.route("/")
def index():
    return jsonify({
        "message": f"Oceans Across Payroll Platform",
        "service": os.environ.get("SERVICE_NAME", "unknown")
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)