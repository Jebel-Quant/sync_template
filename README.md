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
    # Optional: Add permissions for the default GITHUB_TOKEN
    # permissions:
    #   contents: write
    #   workflows: write  # Required to modify workflow files
    steps:
      - name: Checkout
        uses: actions/checkout@v5

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
          # Option 1: Use default GITHUB_TOKEN (won't work for workflow files unless permissions are set above)
          token: ${{ secrets.GITHUB_TOKEN }}
          
          # Option 2: Use a PAT with workflow permissions (recommended for syncing workflow files)
          # token: ${{ secrets.PAT_WITH_WORKFLOW_SCOPE }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|


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

The action supports a test mode that can be enabled by setting the `TEST_MODE` environment variable to `true`. 
In test mode, the action will perform all operations 
except the final git push, making it safe to test 
in CI environments.

Example:

```yaml
- name: Test Sync Template Action
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
