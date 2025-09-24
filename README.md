# Sync Template

A GitHub Action to sync files from a template repository 
into other repositories.

## Usage

```yaml
name: Sync Template Files

on:
  schedule:
    - cron: '0 0 * * 0'  # Run weekly on Sunday at midnight
  workflow_dispatch:  # Allow manual triggering

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Sync Template
        uses: jebel-quant/sync_template@main
        with:
          template-repository: 'organization/template-repo'
          template-branch: 'main'  # Use 'master' for older repositories
          branch: 'sync/update-configs'
          commit-message: 'chore: sync template files'
          include: |
            .github
            .devcontainer
            CODE_OF_CONDUCT.md
          exclude: |
            README.md
            LICENSE
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `template-repository` | Repository to sync from | Yes | - |
| `template-branch` | Branch to sync from in the template repo | No | `main` |
| `branch` | Branch to sync changes to in the target repo | No | `sync/update-configs` |
| `commit-message` | Commit message for sync | No | `chore: sync template` |
| `include` | List of files and folders to include (multi-line) | No | See action.yml |
| `exclude` | List of files and folders to exclude (multi-line) | No | See action.yml |

## Testing

The action includes comprehensive testing to ensure it works correctly:

### Automated Tests

1. **Unit Tests**: A bash script (`tests/test-action.sh`) that simulates the action's functionality by:
   - Setting up source and target repositories
   - Performing the sync operations
   - Validating the results with assertions

2. **Integration Tests**: GitHub workflow files that test the action:
   - `.github/workflows/test.yml`: Basic test of the action functionality
   - `.github/workflows/integration-test.yml`: Runs the test script and tests the action in a workflow

### Test Mode

The action supports a test mode that can be enabled by setting the `TEST_MODE` environment variable to `true`. In test mode, the action will perform all operations except the final git push, making it safe to test in CI environments.

Example:

```yaml
- name: Test Sync Template Action
  uses: jebel-quant/sync_template@main
  with:
    template-repository: 'organization/template-repo'
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    TEST_MODE: "true"
```

### Running Tests Locally

To run the test script locally:

```bash
chmod +x ./tests/test-action.sh
./tests/test-action.sh
```
