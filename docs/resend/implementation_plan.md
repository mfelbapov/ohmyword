# Resend Email Service Integration Plan

This plan outlines the complete setup process for integrating Resend email service into your Phoenix application for sending verification emails.

## Overview

Resend is a modern email API service that provides a simple way to send transactional emails. Your Phoenix app currently uses Swoosh with a local adapter for development. We'll integrate Resend as the production email provider while maintaining the local adapter for development.

## Resend Account Setup

### Step 1: Create Resend Account
1. Visit [https://resend.com](https://resend.com)
2. Click "Sign Up" or "Get Started"
3. Create an account using your email or GitHub
4. Verify your email address if required

### Step 2: Generate API Key
1. Once logged in, navigate to the [API Keys page](https://resend.com/api-keys)
2. Click "Create API Key"
3. Configure the API key:
   - **Name**: Give it a descriptive name (e.g., "Ohmyword Production" or "Ohmyword Development")
   - **Permissions**: Choose the appropriate permission level
     - **Full Access**: Can send emails and manage domains (recommended for production)
     - **Sending Access**: Can only send emails (more restrictive, good for security)
   - **Domain**: Select "All Domains" or specific domain once configured
4. Click "Create"
5. **IMPORTANT**: Copy the API key immediately - it will only be shown once
   - Format: `re_xxxxxxxxxxxxxxxxxxxxxxxxxx`
   - Store it securely (you'll add it to environment variables)

### Step 3: Domain Verification

#### Option A: Use Resend's Test Domain (For Dev/Staging)
Resend provides a pre-verified domain `onboarding@resend.dev` that works immediately without DNS configuration.

**How it works:**
- **Sender**: You MUST use `onboarding@resend.dev` as the "From" address.
- **Recipient**: You can ONLY send emails to the email address you used to sign up for Resend.
- **Usage**: Perfect for testing your integration in a "Dev Deployment" (e.g., a staging app on Fly.io) before you have configured your real domain.

**Configuration for Test Domain:**
- `RESEND_API_KEY`: Use your generated API key (same key works for test and prod).
- Sender Email in Code: `onboarding@resend.dev`

#### Option B: Verify Your Own Domain (For Production)
To send to *any* user and use your own domain (e.g., `hello@yourdomain.com`), you must verify ownership.

1. Navigate to [Domains page](https://resend.com/domains)
2. Click "Add Domain"
3. Enter your domain name (e.g., `yourdomain.com` or `mail.yourdomain.com`)
4. Resend will provide DNS records to add:

   **SPF Record** (Sender Policy Framework)
   - Type: `TXT`
   - Name: `@` (or your domain)
   - Value: `v=spf1 include:resend.com ~all` (or similar, Resend will provide exact value)
   - Purpose: Verifies that Resend is authorized to send emails from your domain

   **DKIM Records** (DomainKeys Identified Mail)
   - Type: `TXT`
   - Name: `resend._domainkey` (Resend will provide exact name)
   - Value: Long string provided by Resend
   - Purpose: Cryptographic signature to verify email authenticity

   **Custom Return Path** (Optional but recommended)
   - Type: `CNAME`
   - Name: Provided by Resend
   - Value: Provided by Resend
   - Purpose: Improves deliverability and bounce handling

5. Add these DNS records to your domain registrar/DNS provider:
   - **Cloudflare**: DNS → Add Record
   - **GoDaddy**: DNS Management → Add Record
   - **Namecheap**: Advanced DNS → Add New Record
   - **Route53**: Hosted Zones → Create Record

6. Wait for DNS propagation (can take 5 minutes to 48 hours, usually ~15 minutes)
7. Return to Resend dashboard and click "Verify" on your domain
8. Domain status should change to "Verified" with green checkmark

#### DNS Record Example
```
Type: TXT
Name: @
Value: v=spf1 include:resend.com ~all

Type: TXT  
Name: resend._domainkey
Value: p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC... (long string)

Type: CNAME
Name: resend
Value: feedback-smtp.resend.com
```

## Code Implementation

### Component 1: Dependencies

#### [MODIFY] [mix.exs](file:///Users/mfelbapov/Projects/ohmyword/mix.exs)

**Current state**: Your app already has `{:swoosh, "~> 1.16"}` installed.

**Required change**: Add the Resend package to your dependencies.

```elixir
defp deps do
  [
    # ... existing deps ...
    {:swoosh, "~> 1.16"},
    {:resend, "~> 0.4.0"},  # ADD THIS LINE
    {:req, "~> 0.5"},
    # ... rest of deps ...
  ]
end
```

**Why**: The `resend` package provides the Elixir client for Resend's API. While Swoosh has adapters for various email services, using the official Resend SDK provides better support and features.

---

### Component 2: Configuration

#### [MODIFY] [config/runtime.exs](file:///Users/mfelbapov/Projects/ohmyword/config/runtime.exs)

**Current state**: Lines 102-118 contain commented-out mailer configuration examples for Mailgun.

**Required change**: Replace the commented Mailgun example with Resend configuration in the production block.

```elixir
# Around line 102, replace the commented mailer section with:

# ## Configuring the mailer
#
# In production, configure the mailer to use Resend
resend_api_key =
  System.get_env("RESEND_API_KEY") ||
    raise """
    environment variable RESEND_API_KEY is missing.
    Get your API key from https://resend.com/api-keys
    """

config :ohmyword, Ohmyword.Mailer,
  adapter: Swoosh.Adapters.Resend,
  api_key: resend_api_key
```

**Environment Variables Required**:
- `RESEND_API_KEY`: Your Resend API key (format: `re_xxxxxxxxxx`)

**Where to set environment variables**:
- **Local development**: Create a `.env` file (add to `.gitignore`) or export in shell
- **Fly.io**: `fly secrets set RESEND_API_KEY=re_xxxxx`
- **Heroku**: Settings → Config Vars
- **Docker**: Pass via `-e` flag or docker-compose environment section
- **Systemd**: Environment file in service configuration

---

### Component 3: Email Sender Configuration

#### [MODIFY] [lib/ohmyword/accounts/user_notifier.ex](file:///Users/mfelbapov/Projects/ohmyword/lib/ohmyword/accounts/user_notifier.ex)

**Current state**: Line 11 has `from({"Ohmyword", "contact@example.com"})`.

**Required change**: Update the sender email.

**For Test Domain (Dev/Staging):**
```elixir
defp deliver(recipient, subject, body) do
  email =
    new()
    |> to(recipient)
    # MUST use this exact address for the test domain to work
    |> from({"Ohmyword", "onboarding@resend.dev"}) 
    |> subject(subject)
    |> text_body(body)
# ...
```

**For Production (Verified Domain):**
```elixir
defp deliver(recipient, subject, body) do
  email =
    new()
    |> to(recipient)
    # Use your verified domain
    |> from({"Ohmyword", "noreply@yourdomain.com"}) 
    |> subject(subject)
    |> text_body(body)
# ...
```

**Recommendation**: Use an environment variable for the sender address so you can switch easily.

```elixir
# In runtime.exs
config :ohmyword, :email_sender, System.get_env("EMAIL_SENDER") || "onboarding@resend.dev"

# In user_notifier.ex
@sender Application.compile_env(:ohmyword, :email_sender)
# ...
|> from({"Ohmyword", @sender})
```

---

### Component 4: Swoosh Adapter Configuration

#### [MODIFY] [config/prod.exs](file:///Users/mfelbapov/Projects/ohmyword/config/prod.exs)

**Current state**: Line 11 has `config :swoosh, api_client: Swoosh.ApiClient.Req`.

**Required change**: Ensure Swoosh is configured to use the Resend adapter (already configured correctly, but verify).

The existing configuration is correct:
```elixir
# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Req
```

**Note**: Swoosh needs an HTTP client. Your app uses `Req` which is already in dependencies. Alternative options are `Hackney` or `Finch`.

---

## Environment Variables Summary

| Variable | Required | Example Value | Where to Get |
|----------|----------|---------------|--------------|
| `RESEND_API_KEY` | Yes | `re_abc123xyz...` | [Resend API Keys](https://resend.com/api-keys) |

## Testing Plan

### Development Testing
1. Keep local adapter for development (already configured in `config/config.exs`)
2. Test emails appear in `/dev/mailbox` route
3. Verify email content and formatting

### Staging/Production Testing
1. Set `RESEND_API_KEY` environment variable
2. Deploy application
3. Trigger a verification email (register new user)
4. Check Resend dashboard for email logs
5. Verify email delivery to inbox
6. Check spam folder if not received
7. Verify links in email work correctly

### Resend Dashboard Monitoring
- Navigate to [Resend Emails](https://resend.com/emails)
- View sent emails, delivery status, and errors
- Check bounce rates and spam reports
- Monitor API usage and rate limits

## Alternative Approach: Using Swoosh's Resend Adapter

Instead of using the `resend` package directly, you can use Swoosh's built-in Resend adapter:

**Pros**:
- One less dependency
- Consistent with existing Swoosh setup
- Simpler configuration

**Cons**:
- May have fewer features than official SDK
- Updates might lag behind Resend's API

**Configuration** (if using Swoosh adapter):
```elixir
# In config/runtime.exs (production block)
config :ohmyword, Ohmyword.Mailer,
  adapter: Swoosh.Adapters.Resend,
  api_key: System.get_env("RESEND_API_KEY")
```

**Note**: Check Swoosh documentation to verify if `Swoosh.Adapters.Resend` exists. If not, you'll need to use the `resend` package approach.

## Rate Limits & Pricing

**Free Tier**:
- 100 emails/day
- 3,000 emails/month
- Good for testing and small applications

**Paid Plans**:
- Start at $20/month for 50,000 emails
- See [Resend Pricing](https://resend.com/pricing) for details

**Rate Limits**:
- Free tier: 2 emails/second
- Paid tiers: Higher limits based on plan

## Security Best Practices

1. **Never commit API keys** to version control
2. **Use environment variables** for all secrets
3. **Rotate API keys** periodically
4. **Use restricted permissions** when possible (sending-only keys)
5. **Monitor usage** in Resend dashboard for suspicious activity
6. **Set up alerts** for failed deliveries

## Rollback Plan

If issues arise with Resend:

1. **Quick rollback**: Comment out Resend config in `runtime.exs`
2. **Fallback to SMTP**: Configure Swoosh with SMTP adapter
3. **Use alternative service**: Switch to Mailgun, SendGrid, or Postmark

## Next Steps After Approval

1. Install dependencies: `mix deps.get`
2. Update configurations as outlined
3. Set environment variables
4. Test in development with local adapter
5. Deploy to staging with Resend
6. Verify domain and test email delivery
7. Monitor Resend dashboard for issues
8. Deploy to production

## Questions for Review

> [!IMPORTANT]
> Please confirm the following before implementation:

1. **Domain**: What domain will you use for sending emails?
   - Do you already own a domain?
   - Should we start with Resend's test domain for initial testing?

2. **Sender Address**: What email address should appear as the sender?
   - Common options: `noreply@yourdomain.com`, `hello@yourdomain.com`

3. **Environment**: Where will this be deployed?
   - Fly.io (based on `fly.toml` in your project)?
   - Other platform?

4. **Approach**: Which implementation approach do you prefer?
   - Option A: Use official `resend` package (recommended)
   - Option B: Use Swoosh's Resend adapter (if available)
