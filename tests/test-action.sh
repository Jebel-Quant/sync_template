#!/bin/bash
set -euo pipefail

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}Starting test for Sync Repository Template action${NC}"

# ------------------------------------------------------------
# Ensure uv / uvx is available (mirror action)
# ------------------------------------------------------------
if ! command -v uvx >/dev/null 2>&1; then
  echo -e "${YELLOW}Installing uv / uvx${NC}"

  curl -LsSf https://astral.sh/uv/install.sh | sh

  export PATH="$HOME/.local/bin:$PATH"
fi

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
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

# ------------------------------------------------------------
# Temp workspace
# ------------------------------------------------------------
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "${TEST_DIR}"' EXIT
echo "Using temp dir: ${TEST_DIR}"

# ------------------------------------------------------------
# Source repo (template)
# ------------------------------------------------------------
echo -e "${YELLOW}Setting up template repository${NC}"
SOURCE_REPO="${TEST_DIR}/template"
mkdir -p "${SOURCE_REPO}"
cd "${SOURCE_REPO}"

git init -q
git config user.name "Test User"
git config user.email "test@example.com"

cat > README.md <<EOF
# Template README
EOF

cat > CODE_OF_CONDUCT.md <<EOF
# Code of Conduct
EOF

cat > CONTRIBUTING.md <<EOF
# Contributing
EOF

mkdir -p .github/workflows
echo "name: Template Workflow" > .github/workflows/test.yml

cat > LICENSE <<EOF
Template License
EOF

git add .
git commit -qm "template: initial"
git branch -M main

# ------------------------------------------------------------
# Target repo
# ------------------------------------------------------------
echo -e "${YELLOW}Setting up target repository${NC}"
TARGET_REPO="${TEST_DIR}/target"
mkdir -p "${TARGET_REPO}"
cd "${TARGET_REPO}"

git init -q
git config user.name "Test User"
git config user.email "test@example.com"

cat > README.md <<EOF
# Target README
EOF

cat > LICENSE <<EOF
Target License
EOF

git add .
git commit -qm "target: initial"
git branch -M main

# ------------------------------------------------------------
# Rhiza config
# ------------------------------------------------------------
mkdir -p .github
cat > .github/template.yml <<EOF
template-repository: ${SOURCE_REPO}
template-branch: main
include:
  - CODE_OF_CONDUCT.md
  - CONTRIBUTING.md
  - .github/
exclude:
  - README.md
  - LICENSE
EOF

# ------------------------------------------------------------
# Run rhiza (this is what the action does)
# ------------------------------------------------------------
echo -e "${YELLOW}Running rhiza validate${NC}"
uvx rhiza validate .

echo -e "${YELLOW}Running rhiza materialize${NC}"
git checkout -B sync/template-update
uvx rhiza materialize .

git add -A
git commit -qm "chore: sync template"

# ------------------------------------------------------------
# Assertions
# ------------------------------------------------------------
echo -e "${YELLOW}Verifying results${NC}"

# Included
assert "[ -f CODE_OF_CONDUCT.md ]" "CODE_OF_CONDUCT.md exists"
assert "[ -f CONTRIBUTING.md ]" "CONTRIBUTING.md exists"
assert "[ -f .github/workflows/test.yml ]" "Workflow file exists"

# Excluded
assert "[ \"$(cat README.md)\" = \"# Target README\" ]" "README.md preserved"
assert "[ \"$(cat LICENSE)\" = \"Target License\" ]" "LICENSE preserved"

# Commit message
assert "[ \"$(git log -1 --pretty=%B)\" = \"chore: sync template\" ]" "Commit message correct"

# Branch
assert "[ \"$(git branch --show-current)\" = \"sync/template-update\" ]" "Correct branch used"

echo -e "${GREEN}All tests passed!${NC}"
