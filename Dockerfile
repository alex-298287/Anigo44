# --- Build Stage for Frontend ---
FROM node:18-alpine AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ .
RUN npm run build

# --- Final Production Stage ---
FROM python:3.9-slim
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy backend requirements and install
COPY api/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install gunicorn

# Copy built frontend from previous stage
COPY --from=frontend-builder /app/frontend/dist ./frontend/dist

# Copy backend code
COPY api/ ./api/

# Set Environment Variables
ENV FLASK_APP=api/index.py
ENV PYTHONUNBUFFERED=1

# Expose port
EXPOSE 5002

# Start with Gunicorn (Production grade server)
CMD ["gunicorn", "--bind", "0.0.0.0:5002", "api.index:app", "--workers", "4", "--timeout", "120"]
