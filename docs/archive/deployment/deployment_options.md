# Deployment Options: Tag-based Deployment

This document outlines the strategy to deploy the application **only** when a specific git tag is pushed. This prevents accidental deployments on merges to `main` and provides a strict release process.

## Complete Development & Deployment Lifecycle

Here is the step-by-step workflow you will follow with this setup:

### 1. Feature Development
*   Create a new branch for your work: `git checkout -b feature/my-new-feature`
*   Make changes and commit them.
*   Push to GitHub: `git push origin feature/my-new-feature`
*   **Automated Action**: The `CI` workflow (`ci.yml`) runs tests on your Pull Request.

### 2. Merge to Main
*   Once tests pass and code is reviewed, merge your Pull Request into `main`.
*   **Automated Action**: No deployment happens. You can safely merge multiple PRs without worrying about releasing unfinished states.

### 3. Prepare Release (The "Then ?" Step)
*   When you are ready to deploy what is currently on `main`:
    1.  Switch to main and pull the latest changes:
        ```bash
        git checkout main
        git pull origin main
        ```
    2.  Create a version tag (e.g., `v1.0.0`):
        ```bash
        git tag v1.0.0
        ```

### 4. Trigger Deployment
*   Push the tag to GitHub to start the deployment:
    ```bash
    git push origin v1.0.0
    ```
*   **Automated Action**: The `CD` workflow (`cd.yml`) detects the `v*` tag. It runs the tests one last time (safety check) and then deploys to Fly.io.

---

## Implementation Plan

To enable this workflow, we need to modify `.github/workflows/cd.yml`.

### Changes to `.github/workflows/cd.yml`

Current behavior: Deploys on push to `main`.
New behavior: Deploys only on push of tags like `v*`.

```yaml
name: CD

on:
  push:
    tags:
      - "v*" # Triggers deployment only on tags like v1.0, v2.3.4

env:
  MIX_ENV: test

jobs:
  test:
    name: Test & Code Quality
    runs-on: ubuntu-latest
    # ... (Test steps remain the same to ensure the tagged commit is good)

  deploy:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: test
    # Ensure we only deploy if the ref is a tag
    if: startsWith(github.ref, 'refs/tags/v')
    
    steps:
      # ... (Deployment steps remain the same)
```

### Summary of Benefits

*   **Explicit Control**: You decide exactly when a release happens.
*   **Batching**: You can merge 5 different features into `main` over a week, and deploy them all at once on Friday.
*   **Rollback Safety**: If `v1.1.0` has a bug, you can re-deploy `v1.0.0` easily.

---

## Git Tag Management Cheat Sheet

### 1. List Tags
See what tags you already have.
```bash
git tag
# Output:
# v1.0.0
# v1.0.1
```

### 2. Create a Tag
Create a tag for the current commit.
```bash
git tag v1.0.0
```
*Tip: You can also annotate it with a message (like a commit message) using `-a` and `-m`:*
```bash
git tag -a v1.0.0 -m "Initial release"
```

### 3. Push Tags
Tags are **not** pushed automatically when you run `git push`. You must push them explicitly.
```bash
# Push a specific tag
git push origin v1.0.0

# OR Push ALL your local tags at once
git push origin --tags
```

### 4. Delete a Tag (Local & Remote)
If you made a mistake (e.g., tagged the wrong commit), you need to delete it in two places.

**Step 1: Delete locally**
```bash
git tag -d v1.0.0
```

**Step 2: Delete from GitHub (Remote)**
```bash
git push origin --delete v1.0.0
```

### 5. Checkout a Tag
If you want to go back in time to see exactly what the code looked like at `v1.0.0`:
```bash
git checkout v1.0.0
```
*(Note: This puts you in a "detached HEAD" state. To work from there, create a new branch: `git checkout -b fix-old-bug v1.0.0`)*
