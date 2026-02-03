# Post-Rename Setup Guide

The `rename_project.sh` script handles renaming files, updating modules, cleaning up build artifacts, and updating the Fly.io app name.

## 1. Git Repository Setup

The script does **not** reset your Git history. You should do this manually for a fresh project.

### Option A: Fresh Start (Recommended)
Use this if you want to start with a clean commit history for your new project.

1.  **Remove the old Git history and initialize new repo:**
    ```bash
    rm -rf .git
    git init
    git add .
    git commit -m "Initial commit"
    git branch -M main
    ```

2.  **Initialize a new Git repository:**
    ```bash
    git init
    git add .
    git commit -m "Initial commit"
    git branch -M main
    ```

3.  **Create a new repository on GitHub.**

4.  **Link and push:**
    ```bash
    git remote add origin https://github.com/YOUR_USERNAME/NEW_REPO_NAME.git
    git push -u origin main
    ```

### Option B: Keep History
Use this if you want to preserve the history of the ohmywordplate.

1.  **Rename the remote URL:**
    ```bash
    git remote set-url origin https://github.com/YOUR_USERNAME/NEW_REPO_NAME.git
    ```

2.  **Push to the new repository:**
    ```bash
    git push -u origin main
    ```

## 2. Fly.io Deployment Setup

The rename script automatically updates the app name in `fly.toml` to kebab-case (e.g., `my_app` -> `my-app`).

> [!WARNING]
> **Check `fly.toml` Version Path**: The `guest_path` setting (line 38) contains a version number (e.g., `/app/lib/my_app-0.1.0/...`). If you change the version in `mix.exs`, you **must** manually update this path in `fly.toml`.

### Step 1: Launch the App
Run the following command to set up the app on Fly.io. This will detect the existing `fly.toml` and ask if you want to copy the configuration.

```bash
fly launch
```

- **Choose an app name:** Enter your new project name (e.g., `my-cool-app`).
- **Select Organization:** Choose your personal or team org.
- **Select Region:** Choose a region close to your users (e.g., `iad`, `sjc`).
- **Setup Postgres:** **YES**. This will create a new database for your new app.
- **Setup Redis:** No (unless you added Redis).
- **Deploy now?** **NO**. We need to set secrets first.

### Step 2: Set Secrets
You need to generate a new `SECRET_KEY_BASE` and set other environment variables.

1.  **Generate a Secret Key:**
    ```bash
    mix phx.gen.secret
    ```
    *Copy the output string.*

2.  **Set Secrets on Fly.io:**
    Replace `YOUR_GENERATED_SECRET` with the string you just copied.
    ```bash
    fly secrets set SECRET_KEY_BASE=YOUR_GENERATED_SECRET
    ```

    *Note: `DATABASE_URL` is automatically set by Fly.io when you attach the Postgres database.*

### Step 3: Deploy
Now you can deploy your application.

```bash
fly deploy
```

## 3. Environment Variables Reference

To match the "ohmyword" project's deployment level, ensure these environment variables are set.

| Variable | Description | Required? | How to Set |
| :--- | :--- | :--- | :--- |
| `SECRET_KEY_BASE` | Signs/encrypts cookies. | **Yes** | `fly secrets set ...` |
| `DATABASE_URL` | Connection string for the DB. | **Yes** | Auto-set by Fly Postgres. |
| `PHX_HOST` | The public hostname. | **Yes** | Set in `fly.toml` or `fly secrets set PHX_HOST=...` |
| `MAILER_API_KEY` | API Key for email service (e.g., Resend). | If using email | `fly secrets set MAILER_API_KEY=...` |
| `POOL_SIZE` | DB Connection pool size. | No (Default: 10) | `fly secrets set POOL_SIZE=...` |

## 4. Third-Party Services (Optional)

If you are using services like Resend or Mailgun:

1.  **Create a new project/domain** in the service's dashboard.
2.  **Get the API Key**.
3.  **Set the secret:**
    ```bash
    fly secrets set MAILER_API_KEY=re_123456789
    ```
