---
description: Deploys the application to production
---

1. Check if the git working directory is clean.
2. Run `mix precommit` to ensure code quality and tests pass.
3. If successful, push to the `main` branch to trigger the CD pipeline: `git push origin main`
4. (IMPORTANT) Never deploy immediately by running `fly deploy`.
