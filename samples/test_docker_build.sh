#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Build the Docker Image ---
echo "🚀 Starting Docker image build for 'claude-code-runner'..."
echo "--------------------------------------------------------"

docker build -t claude-code-runner agents/claude

echo "--------------------------------------------------------"
echo "✅ Docker image 'claude-code-runner' built successfully!"
echo "You can now run the test execution script."
