# Sync Template

A GitHub Action to sync files from a template repository 
into other repositories.

## Usage

```yaml
# Workflow: Sync
# Purpose: This workflow synchronizes configuration files from the template repository
#          to other repositories, creating a pull request with the changes.
#
# Trigger: This workflow runs manually via workflow_dispatch
#
# Components:
#   - 📥 Checkout the target repository
#   - 🔄 Sync configuration templates
#   - 📝 Create a pull request with the changes

name: SYNC

on:
  workflow_dispatch:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday at midnight

permissions:
  contents: write  # Needed to create releases

env:
  TEMPLATE_REPO: 'tschm/latex'
  TEMPLATE_BRANCH: 'main'
  TARGET_BRANCH: 'sync/update'

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout the target repo
        uses: actions/checkout@v5
        with:
          token: ${{ secrets.PAT_TOKEN }}
          fetch-depth: 0
          persist-credentials: 'false'

      - name: Sync Template
        id: sync
        uses: jebel-quant/sync_template@main
        with:
          token: ${{ secrets.PAT_TOKEN }}
          template-repository: ${{ env.TEMPLATE_REPO }}
          template-branch: ${{ env.TEMPLATE_BRANCH }}
          branch: ${{ env.TARGET_BRANCH }}
          commit-message: "chore: sync template files"
          include: |
            .github
            templates
            .gitignore
            .markdownlint.yaml
            .editorconfig
            .pre-commit-config.yaml
            Makefile
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| token | GitHub token or PAT for authentication | Yes | N/A |
| template-repository | Template repository to sync from | Yes | N/A |
| template-branch | Branch in the template repo | No | main |
| branch | Target branch in the current repo | No | sync/update |
| commit-message | Commit message for sync | No | chore: sync template |
| include | Files and folders to include (multi-line) | No | (empty) |
| exclude | Files and folders to exclude (multi-line) | No | (empty) |
| test-mode | If true, skip push and PR creation | No | false |

## How It Works

This action performs the following steps:

1. Checks out the template repository with sparse checkout to only include the specified files/folders
2. Removes excluded files/folders from the template
3. Copies the template files into the target repository
4. Commits and pushes the changes to the specified branch in the target repository
5. Optionally creates a pull request for the changes

The action uses sparse checkout to minimize the amount of data that needs to be downloaded, making it efficient even with large template repositories. 

The pull request creation step uses GitHub's REST API to check if a PR already exists for the branch and creates one if needed. This ensures that multiple workflow runs don't create duplicate PRs.

### GitHub Token Permissions

When using this action to sync workflow files (files in `.github/workflows/`), you need to be aware of GitHub's token permission restrictions:

1. **Default `GITHUB_TOKEN`**: Does not have permission to update workflow files in a repository. If you try to sync workflow files using the default token, you'll get an error like:
   ```
   ! [remote rejected] HEAD -> sync/update (refusing to allow a GitHub App to create or update workflow without `workflows` permission)
   ```

2. **Personal Access Token (PAT)**: To sync workflow files, you must use a PAT with the `workflow` scope. Configure this in your workflow:
   ```yaml
   with:
     token: ${{ secrets.PAT_WITH_WORKFLOW_SCOPE }}
   ```

3. **Repository Settings**: Alternatively, you can modify the default token permissions in your repository settings:
   - Go to Settings > Actions > General
   - Under "Workflow permissions", select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"

The action will automatically detect when workflow files are being modified and provide appropriate warnings.

### Include and Exclude Parameters

- **Include**: Specifies which files and folders to sync from the template repository. This uses Git's sparse checkout feature to only download the specified files.

- **Exclude**: Allows you to remove specific files or subdirectories from folders that were included. 
For example, if you include `.github` folder but want to exclude `.github/workflows/sync.yml`, 
you can list this specific file in the exclude parameter. 
This is particularly useful when you want most files from 
a directory but need to exclude a few specific files.

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

The action supports a test mode that can be enabled by setting the `test-mode` input parameter to `true`. 
In test mode, the action will perform all operations 
except the final git push, making it safe to test 
in CI environments.

Example:

```yaml
- name: Test Sync Template Actio
  uses: jebel-quant/sync_template@main
  with:
    template-repository: 'organization/template-repo'
    token: ${{ secrets.GITHUB_TOKEN }}
    test-mode: "true"
```

### Running Tests Locally

To run the test script locally:

```bash
chmod +x ./tests/test-action.sh
./tests/test-action.sh
```

## Contributing

Contributions are welcome! Here's how you can contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run the tests to ensure everything works
5. Commit your changes (`git commit -m 'Add some amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

Please make sure to update tests as appropriate and adhere to the existing coding style.
