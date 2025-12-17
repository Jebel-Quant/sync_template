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

## ------------------------------------------------------------
## Clone the jebel-quant/rhiza repository to test with
## ------------------------------------------------------------
#TEST_DIR="$(mktemp -d)"
#trap 'rm -rf "${TEST_DIR}"' EXIT
#echo "Using temp dir: ${TEST_DIR}"

#echo -e "${YELLOW}Cloning tschm/monkeys repository${NC}"
#cd "${TEST_DIR}"
#git clone --quiet https://github.com/jebel-quant/sync_template.git
#cd sync_template

# ------------------------------------------------------------
# Run rhiza commands (mirror what the action does)
# ------------------------------------------------------------
echo -e "${YELLOW}Running rhiza validate${NC}"
uvx rhiza validate .

echo -e "${YELLOW}Running rhiza materialize${NC}"
# git checkout -B sync/template-update
uvx rhiza materialize .

# ------------------------------------------------------------
# Verify basic functionality
# ------------------------------------------------------------
echo -e "${YELLOW}Verifying results${NC}"

if git diff --cached --quiet && git diff --quiet; then
  echo -e "${GREEN}✅ PASS: rhiza commands executed successfully${NC}"
else
  echo -e "${YELLOW}ℹ️  Changes detected (this is expected if template has updates)${NC}"
fi

echo -e "${GREEN}All tests passed!${NC}"
