# Setting Up Your GoDaddy Domain with Fly.io

This guide outlines the steps to connect your GoDaddy domain to your Fly.io application (`ohmyword-production`) and enable SSL.

## Prerequisites

- You have the Fly CLI installed and are logged in (`fly auth login`).
- You have access to your GoDaddy account.
- Your app is deployed on Fly.io.

## Step 1: Allocate an IP Address (Fly.io)

First, ensure your Fly application has a dedicated IPv4 address. This is required for A records.

1.  Open your terminal in your project directory.
2.  Run the following command to check your IPs:
    ```bash
    fly ips list
    ```
3.  If you do not see a `v4` address, allocate one:
    ```bash
    fly ips allocate-v4
    ```
    *Note the IPv4 address returned (e.g., `1.2.3.4`).*

4.  Also, note your IPv6 address from the list (e.g., `2a09:...`).

## Step 2: Register the Domain (Fly.io)

Tell Fly.io which domain you want to use.

1.  Run the following command (replace `yourdomain.com` with your actual domain):
    ```bash
    fly certs add yourdomain.com
    ```
2.  If you also want `www.yourdomain.com`, run:
    ```bash
    fly certs add www.yourdomain.com
    ```

Fly will output information about the **DNS records** you need to create. Pay attention to the "DNS Validation" or "Hostname" and "Type" and "Value" fields.

## Step 3: Configure DNS (GoDaddy)

Now, point your domain to Fly.io using GoDaddy's DNS management.

1.  **Log in** to your GoDaddy account.
2.  Navigate to your **My Products** page.
3.  Scroll down to the **All Products and Services** section.
4.  Find your domain name in the list.
5.  Click the **DNS** button next to your domain (or click "Manage" then "DNS").
6.  You will see a list of "Records". You need to **Edit** existing records or **Add** new ones.

> [!IMPORTANT]
> **Delete or Edit Existing Records**: If you see an existing **A** record with the name `@` pointing to "Parked" or a different IP, you must **Edit** it to match the Fly IP. Do not create a duplicate `@` record.

### A. Point the Root Domain (`yourdomain.com`)

1.  Look for an **A** record with Name `@`.
    *   If it exists, click the **Pencil icon** to edit.
    *   If it doesn't exist, click **Add New Record**, choose **A** for Type.
2.  **Enter these details**:
    *   **Name**: `@`
    *   **Value**: `[Your Fly IPv4 Address]` (e.g., `1.2.3.4` from Step 1)
    *   **TTL**: `600` (or "Custom" -> 600 seconds, or 1/2 Hour)
3.  Click **Save**.

4.  Now, look for an **AAAA** record with Name `@`.
    *   **Type**: `AAAA`
    *   **Name**: `@`
    *   **Value**: `[Your Fly IPv6 Address]` (e.g., `2a09:...` from Step 1)
    *   **TTL**: `600`
5.  Click **Save**.

### B. Point the `www` Subdomain (`www.yourdomain.com`)

1.  Look for a **CNAME** record with Name `www`.
2.  **Edit** or **Add** it:
    *   **Type**: `CNAME`
    *   **Name**: `www`
    *   **Value**: `[Your App Name].fly.dev` (e.g., `ohmyword-production.fly.dev`)
    *   **TTL**: `600`
3.  Click **Save**.

### C. SSL Validation (If Required)

If `fly certs add` gave you a validation record (usually for the first time setup):

1.  Click **Add New Record**.
2.  **Type**: `CNAME`
3.  **Name**: `_acme-challenge` (Copy this exactly from the Fly output)
4.  **Value**: `[The long validation string Fly provided]`
5.  Click **Save**.

## Step 4: Verify and Issue SSL (Fly.io)

Fly.io automatically handles SSL (Let's Encrypt) once the DNS records are propagated.

1.  Wait a few minutes (DNS propagation can take time, usually 5-15 mins, but sometimes longer).
2.  Check the status of your certificates:
    ```bash
    fly certs check yourdomain.com
    fly certs check www.yourdomain.com
    ```
3.  Once the output says "The certificate for ... has been issued", HTTPS will work automatically.

## Summary of Commands

```bash
# 1. Get IP
fly ips list

# 2. Add Domain
fly certs add yourdomain.com
fly certs add www.yourdomain.com

# 3. Check Status (after updating GoDaddy DNS)
fly certs check yourdomain.com
```

## Troubleshooting

-   **"Not Secure"**: If you visit the site immediately, you might see a certificate error. Wait for `fly certs check` to confirm issuance.
-   **DNS Not Updating**: Use a tool like [whatsmydns.net](https://whatsmydns.net) to check if your A/AAAA/CNAME records are visible globally.



```bash
## Check ssl certs
fly certs check yourdomain.com
```