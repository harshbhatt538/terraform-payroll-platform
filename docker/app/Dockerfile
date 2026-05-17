# Use a specific slim image version to reduce attack surface and avoid known vulnerabilities
FROM python:3.11.15-slim

# Create non-root user — never run containers as root
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy requirements first — better layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# Switch to non-root user
USER appuser

EXPOSE 8080

# Use gunicorn for production — not flask dev server
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "main:app"]
