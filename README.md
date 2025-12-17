# Sync Repository Template

A GitHub Action that synchronizes your repository with a template using [rhiza](https://github.com/jebel-quant/rhiza-cli). This action validates your rhiza configuration, materializes template changes, and optionally creates a pull request with the updates.

## Quick Start

```yaml
name: Sync Template

on:
  schedule:
    - cron: '0 0 * * 0'  # Run weekly on Sunday at midnight
  workflow_dispatch:      # Allow manual triggering

permissions:
  contents: write         # Needed to push commits
  pull-requests: write    # Needed to create pull requests
  
jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Sync Repository Template
        uses: jebel-quant/sync_template@main
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          branch: sync/template-update
          commit-message: 'chore: sync template'
```

## What This Action Does

This action automates template synchronization in repositories that use [rhiza](https://github.com/rhiza-lab/rhiza) for template management. It:

1. **Validates** your rhiza configuration using `uvx rhiza validate .`
2. **Materializes** template changes using `uvx rhiza materialize .`
3. **Commits** any detected changes to a specified branch
4. **Creates a pull request** (optional) for reviewing and merging the changes

## Prerequisites

Your repository must be configured to use **rhiza** for template management. Rhiza is a tool for maintaining multiple repositories from a common template, allowing you to keep shared files synchronized while preserving repository-specific customizations.

To use this action, ensure your repository has the necessary rhiza configuration files that define which template to use and how to apply it.

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `token` | GitHub token or PAT for authentication | **Yes** | N/A |
| `branch` | Target branch for the sync | No | `sync/template-update` |
| `commit-message` | Commit message for the sync | No | `chore: sync template` |
| `create-pr` | Whether to create a pull request if changes are detected | No | `true` |

## Outputs

| Output | Description |
|--------|-------------|
| `changes-detected` | Whether changes were detected during the sync (`true` or `false`) |

### Using Outputs

You can use the `changes-detected` output to conditionally run subsequent steps:

```yaml
jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Sync Repository Template
        id: sync
        uses: jebel-quant/sync_template@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Notify if changes detected
        if: steps.sync.outputs.changes-detected == 'true'
        run: echo "Template changes were synchronized!"
```

## How It Works

The action executes the following workflow:

1. **Checkout**: Checks out your repository with full history
2. **Install Tools**: Installs `uv` (Python package installer) via `astral-sh/setup-uv`
3. **Validate**: Runs `uvx rhiza validate .` to ensure your rhiza configuration is valid
4. **Create Branch**: Creates or updates the target branch
5. **Materialize**: Runs `uvx rhiza materialize .` to apply template changes
6. **Detect Changes**: Checks if any files were modified
7. **Commit & Push**: If changes exist, commits them with the specified message and pushes to the branch
8. **Create PR**: If `create-pr` is enabled and changes exist, creates a pull request using `peter-evans/create-pull-request`

### Workflow File Detection

The action automatically detects when workflow files (`.github/workflows/`) are modified and warns you if additional permissions may be required:

```
⚠️ Workflow files modified — PAT with workflow scope may be required.
```

### GitHub Token Permissions

For most files, the default `GITHUB_TOKEN` is sufficient. However, when syncing workflow files, you may need additional permissions:

1. **Default `GITHUB_TOKEN`**: Works for most files but cannot modify workflow files without additional repository settings.

2. **Repository Settings** (Recommended): Enable workflow modifications by:
   - Go to Settings → Actions → General
   - Under "Workflow permissions", select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"

3. **Personal Access Token (PAT)**: Alternatively, use a PAT with `workflow` scope:

   ```yaml
   with:
     token: ${{ secrets.PAT_WITH_WORKFLOW_SCOPE }}
   ```

## Examples

### Basic Usage

Sync template weekly and create a pull request:

```yaml
name: Sync Template

on:
  schedule:
    - cron: '0 0 * * 0'

permissions:
  contents: write
  pull-requests: write

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: jebel-quant/sync_template@main
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
```

### Custom Branch and Commit Message

```yaml
- uses: jebel-quant/sync_template@main
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    branch: template-updates
    commit-message: 'chore(template): sync latest changes'
```

### Without Creating Pull Requests

If you want to push changes directly without a PR:

```yaml
- uses: jebel-quant/sync_template@main
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    create-pr: 'false'
```

### Conditional Actions Based on Changes

```yaml
- name: Sync Template
  id: sync
  uses: jebel-quant/sync_template@main
  with:
    token: ${{ secrets.GITHUB_TOKEN }}

- name: Run additional tasks
  if: steps.sync.outputs.changes-detected == 'true'
  run: |
    echo "Template was updated, running additional tasks..."
    # Add your custom logic here
```

## Testing

The action includes testing to ensure it works correctly:

### Integration Tests

The repository includes an integration test workflow (`.github/workflows/integration-test.yml`) that:

1. Runs the test script (`tests/test-action.sh`) to verify rhiza commands work
2. Executes the action in a workflow environment
3. Validates the `changes-detected` output

### Running Tests Locally

To test the rhiza commands locally:

```bash
chmod +x ./tests/test-action.sh
./tests/test-action.sh
```

This script mirrors the action's behavior by running:
- `uvx rhiza validate .`
- `uvx rhiza materialize .`

## About Rhiza

[Rhiza](https://github.com/rhiza-lab/rhiza) is a template synchronization tool that helps maintain consistency across multiple repositories. It allows you to:

- Define a template repository with shared configurations
- Customize which files to sync and which to keep repository-specific
- Automatically apply template updates while preserving local changes

For more information about rhiza and how to configure it, visit the [rhiza documentation](https://github.com/rhiza-lab/rhiza).

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run the tests to ensure everything works
5. Commit your changes (`git commit -m 'feat: add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

Please ensure your changes are tested and follow the existing code style.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Thomas Schmelzer
