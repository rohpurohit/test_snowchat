# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt .

# Install system dependencies
RUN apt-get update && apt-get install -y \
  libmagic1 \
  && rm -rf /var/lib/apt/lists/*

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the current directory contents into the container at /app
COPY . .

# Set environment variables
ENV OPENAI_API_KEY=""
ENV ACCOUNT=""
ENV USER_NAME=""
ENV PASSWORD=""
ENV ROLE=""
ENV DATABASE=""
ENV SCHEMA=""
ENV WAREHOUSE=""
ENV SUPABASE_URL=""
ENV SUPABASE_SERVICE_KEY=""
ENV REPLICATE_API_TOKEN=""

# Run ingest.py to convert to embeddings and store as an index file
RUN python ingest.py

# Make port 8501 available to the world outside this container
EXPOSE 8501

# Run the Streamlit app when the container launches
CMD ["streamlit", "run", "main.py"]
