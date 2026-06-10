# backend/Dockerfile
# Builds the TaskFlow FastAPI backend into a container.
# Run from the backend/ folder: docker build -t taskflow-backend .

FROM python:3.13-slim

# Set working directory inside the container
WORKDIR /app

# Copy dependencies first — cached unless requirements.txt changes
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the app
COPY . .

# Expose the port uvicorn runs on
EXPOSE 8000

# Start the server — host 0.0.0.0 makes it accessible outside the container
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]