#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- 1. Initial Setup ---
# Ensure the .claude directory is owned by the correct user.
if [ -d /home/ubuntu/.claude ]; then
    echo "Updating .claude directory permissions..."
    sudo chown -R ubuntu:ubuntu /home/ubuntu/.claude
fi

# --- 2. Validate Environment Variables ---
echo "Validating environment variables..."
: "${GITHUB_OWNER?GITHUB_OWNER is required}"
: "${GITHUB_REPOSITORY?GITHUB_REPOSITORY is required}"
: "${GITHUB_BRANCH?GITHUB_BRANCH is required}"
: "${GITHUB_TOKEN?GITHUB_TOKEN is required}"
: "${PROMPT?PROMPT is required}"

# --- 3. Set Claude Model ---
# The CLAUDE_MODEL variable is optional. If set, it will be passed to the claude CLI.
if [ -n "${CLAUDE_MODEL}" ]; then
    echo "Using specified Claude model: ${CLAUDE_MODEL}"
else
    echo "Using the default model configured in the claude tool."
fi

# --- 4. Configure Git Authentication ---
echo "Authenticating with GitHub CLI..."
GITHUB_TOKEN_STRING="${GITHUB_TOKEN}"
unset GITHUB_TOKEN
gh auth login --with-token <<< "${GITHUB_TOKEN_STRING}"
gh auth setup-git
echo "Git authentication configured."

# --- 5. Source NVM ---
# Sourcing nvm is required to make node and npm available in the script's session.
echo "Sourcing nvm to ensure node and npm are in the PATH..."
export NVM_DIR="/home/ubuntu/.nvm"
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
echo "Node.js environment is ready."

# --- 6. Clone Repository ---
REPO_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}.git"
CLONE_DIR="/app/repo" # Clone into a dedicated 'repo' subdirectory
echo "Cloning repository from ${REPO_URL} into ${CLONE_DIR}..."
git clone --depth 1 --branch "${GITHUB_BRANCH}" "${REPO_URL}" "${CLONE_DIR}"
cd "${CLONE_DIR}"

# --- 7. Setup Git Ignore Rules ---
# Use .git/info/exclude to ignore AI context files locally
EXCLUDE_FILE=".git/info/exclude"
echo "Excluding AI context files from Git tracking in ${EXCLUDE_FILE}..."
echo "" >> "${EXCLUDE_FILE}"
echo "# AI-generated context files (ignored locally)" >> "${EXCLUDE_FILE}"
echo "CLAUDE.md" >> "${EXCLUDE_FILE}"
echo ".claude/settings.json" >> "${EXCLUDE_FILE}"

# Update .gitignore using the dedicated Node.js script
if [ -n "${GITIGNORE}" ]; then
    node /app/upsert-gitignore.js
fi

# --- 8. Create a New Branch ---
BRANCH_PREFIX="${BRANCH_PREFIX:-claude}"
NEW_BRANCH_NAME="${BRANCH_PREFIX}/run-$(date +%Y%m%d-%H%M%S)"
echo "Creating and switching to new branch: ${NEW_BRANCH_NAME}"
git checkout -b "${NEW_BRANCH_NAME}"

# --- 9. Create AI Context Files ---
# Copy base CLAUDE.md and append user-provided content if it exists.
if [ -f /app/BASE_CLAUDE.md ]; then
    echo "Copying base CLAUDE.md..."
    cp /app/BASE_CLAUDE.md ./CLAUDE.md
fi
if [ -n "${CLAUDE_MD}" ]; then
    echo "Appending user-provided CLAUDE.md..."
    echo ""                                     >> CLAUDE.md
    echo "---"                                  >> CLAUDE.md
    echo "## User-Provided Instructions"        >> CLAUDE.md
    echo "---"                                  >> CLAUDE.md
    echo "${CLAUDE_MD}"                         >> CLAUDE.md
fi

# Create .claude/settings.json by merging base and user-provided settings.
mkdir -p .claude
BASE_JSON=$(cat /app/BASE_claude_settings.json)
USER_JSON="${CLAUDE_SETTINGS_JSON:-'{}'}"
echo "${BASE_JSON}" | jq --argjson user_settings "${USER_JSON}" '. * $user_settings' > .claude/settings.json
echo "Created .claude/settings.json:"
cat .claude/settings.json

# --- 10. Configure Git and Run AI ---
echo "Configuring git user for AI commits..."
git config user.name "Claude Code Bot"
git config user.email "claude-code-bot@users.noreply.github.com"

echo "----------------------------------------------------"
echo "Starting Claude Code session..."
echo "Prompt:"
printf "%s\n" "${PROMPT}"
echo "----------------------------------------------------"

# Build the claude command
CLAUDE_CMD_ARGS=()
CLAUDE_CMD_ARGS+=("--print")
CLAUDE_CMD_ARGS+=("--output-format=stream-json")
CLAUDE_CMD_ARGS+=("--verbose")
if [ -n "${CLAUDE_MODEL}" ]; then
    CLAUDE_CMD_ARGS+=("--model" "${CLAUDE_MODEL}")
fi

# Execute the claude tool and pipe the parsed output to a log file and stdout
LOG_FILE=$(mktemp)
claude "${CLAUDE_CMD_ARGS[@]}" "${PROMPT}" | node /app/json-stream-parser.js | tee "${LOG_FILE}"

echo "----------------------------------------------------"
echo "Claude Code session finished."

# --- 11. Commit Remaining Changes ---
echo "Checking for any remaining uncommitted changes..."
if [[ -n "$(git status --porcelain)" ]]; then
    echo "Uncommitted changes found. Staging and committing..."
    git add -A
    git commit -m "chore: Apply remaining file changes" -m "This commit includes files that were created or modified by the AI but not explicitly committed."
else
    echo "No remaining uncommitted changes found."
fi

# --- 12. Create Pull Request ---
# Check if there are any new commits on this branch compared to the base branch.
git fetch origin "${GITHUB_BRANCH}"
if [[ $(git rev-list --count "origin/${GITHUB_BRANCH}..HEAD") -eq 0 ]]; then
    echo "No new commits detected. Skipping Pull Request creation."
else
    echo "New commits found. Pushing branch and creating Pull Request..."
    git push --set-upstream origin "${NEW_BRANCH_NAME}"

    # Determine the PR title
    PR_TITLE_FILE="../PULL_REQUEST_TITLE"
    if [ -f "${PR_TITLE_FILE}" ]; then
        PR_TITLE=$(cat "${PR_TITLE_FILE}")
        echo "Using AI-generated PR title: ${PR_TITLE}"
    else
        PR_TITLE="Claude Code: Automated Changes for ${NEW_BRANCH_NAME}"
        echo "AI-generated PR title not found. Using default title: ${PR_TITLE}"
    fi

    # Prepare the PR body
    PR_BODY_CONTENT_FILE="../PULL_REQUEST_BODY"
    if [ -f "${PR_BODY_CONTENT_FILE}" ]; then
        PR_BODY=$(cat "${PR_BODY_CONTENT_FILE}")
        echo "Using AI-generated PR body."
    else
        PR_BODY="AI-generated description not provided."
        echo "AI-generated PR body not found. Using default description."
    fi

    # Combine all parts into the final PR body file
    PR_BODY_FILE=$(mktemp)
    
    echo "${PR_BODY}"                                                                           >> "${PR_BODY_FILE}"
    echo ""                                                                                     >> "${PR_BODY_FILE}"
    echo "---"                                                                                  >> "${PR_BODY_FILE}"
    echo "🤖 This PR was automatically generated by the **Claude Code Agent**."                 >> "${PR_BODY_FILE}"
    echo ""                                                                                     >> "${PR_BODY_FILE}"
    echo "![Automation](https://img.shields.io/badge/Generated%20by-Claude%20Agent-blueviolet)" >> "${PR_BODY_FILE}"
    echo ""                                                                                     >> "${PR_BODY_FILE}"
    echo "<details>"                                                                            >> "${PR_BODY_FILE}"
    echo "<summary>Execution Details (Click to expand)</summary>"                               >> "${PR_BODY_FILE}"
    echo ""                                                                                     >> "${PR_BODY_FILE}"
    echo "**Model Used:** ${CLAUDE_MODEL:-Default}"                                             >> "${PR_BODY_FILE}"
    echo ""                                                                                     >> "${PR_BODY_FILE}"
    echo "**Prompt:**"                                                                          >> "${PR_BODY_FILE}"
    echo '```'                                                                                  >> "${PR_BODY_FILE}"
    echo "${PROMPT}"                                                                            >> "${PR_BODY_FILE}"
    echo '```'                                                                                  >> "${PR_BODY_FILE}"
    echo ""                                                                                     >> "${PR_BODY_FILE}"
    echo "**Full Execution Log:**"                                                              >> "${PR_BODY_FILE}"
    echo '```'                                                                                  >> "${PR_BODY_FILE}"
    cat  "${LOG_FILE}"                                                                          >> "${PR_BODY_FILE}"
    echo '```'                                                                                  >> "${PR_BODY_FILE}"
    echo ""                                                                                     >> "${PR_BODY_FILE}"
    echo "</details>"                                                                           >> "${PR_BODY_FILE}"

    # Create the PR.
    gh pr create \
        --title "${PR_TITLE}" \
        --body-file "${PR_BODY_FILE}" \
        --base "${GITHUB_BRANCH}" \
        --head "${NEW_BRANCH_NAME}"

    rm "${LOG_FILE}"
    rm "${PR_BODY_CONTENT_FILE}" 2>/dev/null || true
    rm "${PR_TITLE_FILE}" 2>/dev/null || true
    rm "${PR_BODY_FILE}"
    echo "✅ Pull Request created successfully!"
fi

echo "Container task finished."

# Generated by Gemini

