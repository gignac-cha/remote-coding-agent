#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# This script supports two authentication methods for Claude:
# 1. API Key: Set the ANTHROPIC_API_KEY environment variable.
# 2. Plan (Volume Mount): Your local ~/.claude directory will be mounted.

GITHUB_TOKEN="YOUR_GITHUB_TOKEN_HERE"
ANTHROPIC_API_KEY="YOUR_ANTHROPIC_API_KEY_HERE"

# GitHub token is always required.
if [ -z "${GITHUB_TOKEN}" ]; then
  echo "❌ ERROR: GITHUB_TOKEN environment variable is not set."
  exit 1
fi

# Build the docker command dynamically.
DOCKER_CMD="docker run --rm"

# Add auth method
if [ -n "${ANTHROPIC_API_KEY}" ]; then
    echo "🔑 Using API Key authentication."
    DOCKER_CMD="${DOCKER_CMD} -e ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}"
else
    echo "📁 Using Plan (volume mount) authentication."
    # Note for Windows Users: Adjust the path if not using Git Bash.
    # e.g., "%USERPROFILE%\.claude"
    DOCKER_CMD="${DOCKER_CMD} -v ${HOME}/.claude:/home/ubuntu/.claude"
fi

# --- Dynamic Values ---
CONTAINER_NAME="claude-run-$(date +%s)"
echo "📦 Using container name: ${CONTAINER_NAME}"
DOCKER_CMD="${DOCKER_CMD} --name ${CONTAINER_NAME}"

# --- Add other environment variables ---
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export GITHUB_TOKEN
export GITHUB_OWNER='gignac-cha'
export GITHUB_REPOSITORY='remote-claude-code-test'
export GITHUB_BRANCH='main'
export PROMPT="$(cat "${SCRIPT_DIR}/test_prompt.txt")"
export CLAUDE_MD="$(cat "${SCRIPT_DIR}/test_CLAUDE.md")"
export CLAUDE_SETTINGS_JSON="$(cat "${SCRIPT_DIR}/test_claude_settings.json")"
export GITIGNORE="$(cat "${SCRIPT_DIR}/test_gitignore")"
export GITIGNORE_MODE="merge"

DOCKER_CMD="${DOCKER_CMD} \
    -e GITHUB_TOKEN \
    -e GITHUB_OWNER \
    -e GITHUB_REPOSITORY \
    -e GITHUB_BRANCH \
    -e PROMPT \
    -e CLAUDE_MD \
    -e CLAUDE_SETTINGS_JSON \
    -e GITIGNORE \
    -e GITIGNORE_MODE"

# --- Final command ---
DOCKER_CMD="${DOCKER_CMD} claude-code-runner"

# --- Execute ---
echo "🚀 Starting container '${CONTAINER_NAME}'..."
echo "--------------------------------------------------------"
${DOCKER_CMD}
echo "--------------------------------------------------------"
echo "✅ Container '${CONTAINER_NAME}' finished its task."