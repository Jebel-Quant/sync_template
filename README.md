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
| `token` | Token to use for authentication | No | `${{ github.token }}` |

## How It Works

This action performs the following steps:

1. Checks out the template repository with sparse checkout to only include the specified files/folders
2. Removes excluded files/folders from the template
3. Copies the template files into the target repository
4. Commits and pushes the changes to the specified branch in the target repository

The action uses sparse checkout to minimize the amount of data that needs to be downloaded, making it efficient even with large template repositories.

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
