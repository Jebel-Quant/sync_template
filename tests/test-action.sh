#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting test for Sync Template Action${NC}"

# Create test directory
TEST_DIR=$(mktemp -d)
echo -e "Using temporary directory: ${TEST_DIR}"

# Cleanup function
cleanup() {
  echo -e "${YELLOW}Cleaning up test environment${NC}"
  rm -rf "${TEST_DIR}"
}

# Register cleanup function to run on exit
trap cleanup EXIT

# Function to check if a test passes
assert() {
  local condition=$1
  local message=$2
  
  if eval "${condition}"; then
    echo -e "${GREEN}✅ PASS: ${message}${NC}"
  else
    echo -e "${RED}❌ FAIL: ${message}${NC}"
    exit 1
  fi
}

# Setup source repository (template)
echo -e "${YELLOW}Setting up source repository${NC}"
SOURCE_REPO="${TEST_DIR}/source-repo"
mkdir -p "${SOURCE_REPO}"
cd "${SOURCE_REPO}"

git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create template files
echo "# Template README" > README.md
echo "# Code of Conduct" > CODE_OF_CONDUCT.md
echo "# Contributing Guide" > CONTRIBUTING.md
mkdir -p .github/workflows
echo "name: Test Workflow" > .github/workflows/test.yml
echo "# License" > LICENSE

git add .
git commit -m "Initial commit"

# Create a main branch (default in newer repos)
git branch -m main

# Setup target repository
echo -e "${YELLOW}Setting up target repository${NC}"
TARGET_REPO="${TEST_DIR}/target-repo"
mkdir -p "${TARGET_REPO}"
cd "${TARGET_REPO}"

git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create initial files in target repo
echo "# Target README" > README.md
echo "# Target License" > LICENSE
git add .
git commit -m "Initial commit"

# Create test branch
git checkout -b sync/update-configs

# Simulate running the action
echo -e "${YELLOW}Simulating action execution${NC}"
# Save the branch name to ensure we stay on it
BRANCH_NAME="sync/update-configs"

# Create template.yml file
echo "Creating template.yml file"
cat > template.yml << EOF
template-repository: ${SOURCE_REPO}
template-branch: main
include: |
  CODE_OF_CONDUCT.md
  CONTRIBUTING.md
  .github/
exclude: |
  README.md
  LICENSE
EOF

# Step 1: Sparse checkout from template repo
echo "Performing sparse checkout"
git remote add template "${SOURCE_REPO}"
git fetch template

# Create a temporary directory for template files
mkdir -p .template-temp
cd .template-temp

# Clone specific files from template
git init
git config user.name "Test User"
git config user.email "test@example.com"
git remote add origin "${SOURCE_REPO}"
git config core.sparseCheckout true

# Read include patterns from template.yml file
while IFS= read -r pattern; do
  pattern="$(echo "$pattern" | xargs)"
  [ -z "$pattern" ] || echo "$pattern" >> .git/info/sparse-checkout
done < <(grep -A 10 "^include: |" ../template.yml | tail -n +2 | grep -v "^exclude:")

git pull origin main --depth=1

# Step 2: Apply excludes
echo "Applying excludes"
# First, remove the .git directory
rm -rf .git

# Read exclude patterns from template.yml file and remove files
while IFS= read -r pattern; do
  pattern="$(echo "$pattern" | xargs)"
  [ -z "$pattern" ] || rm -rf "$pattern" 2>/dev/null || true
done < <(grep -A 10 "^exclude: |" ../template.yml | tail -n +2)

# Make sure we're on the sync/update-configs branch before copying files
cd "${TARGET_REPO}"
git checkout sync/update-configs

# Step 3: Copy template files to target repo
echo "Copying template files"
# Copy all files from template temp directory
cp -R .template-temp/. .
rm -rf .template-temp

# Step 4: Commit and push changes
git checkout "${BRANCH_NAME}"
git add CODE_OF_CONDUCT.md CONTRIBUTING.md .github
git commit -m "chore: sync template"

# Verify results
echo -e "${YELLOW}Verifying results${NC}"

# Check that files were synced correctly
assert "[ -f CODE_OF_CONDUCT.md ]" "CODE_OF_CONDUCT.md exists"
assert "[ -f CONTRIBUTING.md ]" "CONTRIBUTING.md exists"
assert "[ -d .github ]" ".github directory exists"
assert "[ -f .github/workflows/test.yml ]" "Workflow file exists"

# Check that excluded files were not synced
assert "[ \"$(cat README.md)\" = \"# Target README\" ]" "README.md was not overwritten"
assert "[ \"$(cat LICENSE)\" = \"# Target License\" ]" "LICENSE was not overwritten"

# Check commit message
assert "[ \"$(git log -1 --pretty=%B)\" = \"chore: sync template\" ]" "Commit message is correct"

echo -e "${GREEN}All tests passed!${NC}"