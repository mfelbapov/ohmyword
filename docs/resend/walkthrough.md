# Resend Integration Walkthrough

I have successfully integrated the Resend email service into your Phoenix application. This setup allows you to send transactional emails using Resend's API, with a configuration that supports both development (using Resend's test domain) and production (using your verified domain).

## Changes Implemented

### 1. Dependencies
Added the `resend` package to `mix.exs` to enable Resend API integration.

### 2. Configuration
Updated `config/runtime.exs` to configure the mailer for production:
- **Adapter**: Set to `Resend.Swoosh.Adapter`
- **API Key**: Reads from `RESEND_API_KEY` environment variable
- **Sender**: Reads from `EMAIL_SENDER` environment variable, defaulting to `onboarding@resend.dev`

### 3. Email Sender
Modified `lib/ohmyword/accounts/user_notifier.ex` to dynamically fetch the sender email address from the configuration. This ensures you can easily switch between the test domain and your production domain without changing code.

## Verification Steps

### 1. Local Development (Existing Behavior)
Your local development environment continues to use the `Swoosh.Adapters.Local` adapter (as configured in `config/config.exs`).
- **Action**: Register a new user or trigger an email.
- **Verification**: Check `/dev/mailbox` in your browser to see the sent email.

### 2. Resend Test Domain (Staging/Dev Deployment)
To test with Resend's `onboarding@resend.dev` domain:
1. **Set Environment Variables**:
   - `RESEND_API_KEY`: Your Resend API key (starts with `re_`)
   - `EMAIL_SENDER`: `onboarding@resend.dev` (optional, as it's the default)
2. **Deploy**: Deploy your application (e.g., to Fly.io).
3. **Action**: Trigger an email (e.g., "Resend Confirmation Instructions").
4. **Verification**: Check the inbox of the email address you used to sign up for Resend.

### 3. Production (Verified Domain)
Once you have verified your domain on Resend:
1. **Set Environment Variables**:
   - `RESEND_API_KEY`: Your Resend API key
   - `EMAIL_SENDER`: `noreply@yourdomain.com` (or your preferred sender)
2. **Deploy**: Deploy your application.
3. **Action**: Trigger an email.
4. **Verification**: Check the recipient's inbox.

## Next Steps
- **Get API Key**: Log in to [Resend](https://resend.com/api-keys) and generate an API key.
- **Verify Domain**: If you want to send to users other than yourself, verify your domain in the [Resend Dashboard](https://resend.com/domains).
- **Set Secrets**: Add `RESEND_API_KEY` to your deployment secrets (e.g., `fly secrets set RESEND_API_KEY=...`).
