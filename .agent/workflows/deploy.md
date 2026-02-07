---
description: Deploys the application to production
---

## Deployment Steps

1. Check if the git working directory is clean.
2. Run `mix precommit` to ensure code quality and tests pass.
3. If successful, push to the `main` branch to trigger the CD pipeline: `git push origin main`
4. (IMPORTANT) Never deploy immediately by running `fly deploy`.

---

## Domain Setup (One-time)

### 1. Allocate IPs on Fly.io

```bash
fly ips allocate-v4
fly ips allocate-v6
```

### 2. Add SSL Certificates

```bash
fly certs create stasta.world
fly certs create www.stasta.world
```

---

## GoDaddy DNS Configuration

### Root Domain (stasta.world)

| Type  | Name | Value              |
|-------|------|--------------------|
| A     | @    | <IPv4 from fly ips list> |
| AAAA  | @    | <IPv6 from fly ips list> |

### WWW Subdomain

| Type  | Name | Value              |
|-------|------|--------------------|
| CNAME | www  | ohmyword.fly.dev   |

### ACME Challenge (for SSL validation)

| Type  | Name                           | Value                                    |
|-------|--------------------------------|------------------------------------------|
| CNAME | _acme-challenge                | stasta.world.<app>.fly.dev.              |
| CNAME | _acme-challenge.www            | www.stasta.world.<app>.fly.dev.          |

---

## Verification

```bash
fly certs show stasta.world
fly certs show www.stasta.world
fly ips list
```

---

## Tips

- **DNS propagation**: Typically 15-30 minutes, but can take up to 48 hours
- **Remove conflicting records**: Delete any existing A/AAAA/CNAME records for the same hostname before adding new ones
- **SSL is automatic**: Fly.io uses Let's Encrypt for free SSL certificates once DNS is properly configured

---
