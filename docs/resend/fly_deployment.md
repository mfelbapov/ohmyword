# Fly.io Deployment Instructions for Resend

This guide covers how to configure your Fly.io application to work with Resend, manage secrets, and handle multiple environments.

## 1. Setting Environment Variables (Secrets)

Fly.io uses "secrets" for sensitive environment variables like API keys. These are encrypted and not stored in your `fly.toml`.

### For Production (Verified Domain)
Once you have verified your domain on Resend:

```bash
# Set the API Key
fly secrets set RESEND_API_KEY=re_123456789

# Set the Sender Address
fly secrets set EMAIL_SENDER=noreply@yourdomain.com
```

### For Staging / Dev Deployment (Test Domain)
If you are testing with Resend's `onboarding@resend.dev` domain:

```bash
# Set the API Key (same key works)
fly secrets set RESEND_API_KEY=re_123456789

# Set the Sender Address (MUST be this exact address)
fly secrets set EMAIL_SENDER=onboarding@resend.dev
```

### Verifying Secrets
To see what secrets are set:
```bash
fly secrets list
```

To check what the running app sees (via SSH):
```bash
fly ssh console
/app/bin/ohmyword remote
System.get_env("RESEND_API_KEY")
```

---

## 2. Handling Multiple Environments

Fly.io "Apps" are isolated. To have a Staging and Production environment, you create two separate apps.

### Step 1: Create a Staging App
```bash
fly apps create ohmyword-staging
```

### Step 2: Set Secrets for Staging
Use the `-a` flag to target the specific app:
```bash
fly secrets set RESEND_API_KEY=re_... EMAIL_SENDER=onboarding@resend.dev -a ohmyword-staging
```

### Step 3: Deploy to Staging
Override the app name defined in `fly.toml` during deployment:
```bash
fly deploy -a ohmyword-staging
```

**Pro Tip:** Create a `fly.staging.toml` if you need different configuration (like instance size or URL):
```bash
fly deploy -c fly.staging.toml
```

---

## 3. Renaming an App

You cannot rename a running Fly app directly. You must migrate to a new one.

1.  **Create New App**: `fly apps create my-new-name`
2.  **Update Config**: Change `app = 'my-new-name'` in your `fly.toml`.
3.  **Copy Secrets**: Secrets do not transfer. You must set them again:
    ```bash
    fly secrets set RESEND_API_KEY=... EMAIL_SENDER=... -a my-new-name
    ```
4.  **Deploy**: `fly deploy`
5.  **Cleanup**: Once verified, delete the old app:
    ```bash
    fly apps destroy old-name
    ```
