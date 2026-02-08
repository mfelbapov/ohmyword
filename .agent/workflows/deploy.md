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

## Phoenix + Fly.io Best Practices

### Compile-time vs Runtime Config

Some Phoenix endpoint options must be set at **compile time** in `config/prod.exs`, not in `config/runtime.exs`. If set at runtime, the release will crash with a config mismatch error.

**Must be in `prod.exs` (compile-time):**
```elixir
config :ohmyword, OhmywordWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"
```

### Do NOT use `force_ssl` with Fly.io

Fly.io terminates SSL at the edge and forwards HTTP to your app. If you enable `force_ssl: [hsts: true]` in Phoenix, it will cause a redirect loop because Phoenix sees HTTP requests and keeps redirecting.

Instead, use `force_https: true` in `fly.toml` (under `[http_service]`) - Fly handles HTTPS redirection at the proxy level.

**Can be in `runtime.exs` (runtime):**
- `secret_key_base`
- `url: [host: host, port: 443, scheme: "https"]`
- `http: [ip: ..., port: ...]`

### GitHub Actions + Fly.io

1. Add `FLY_API_TOKEN` to GitHub repository secrets
2. Generate token: `fly tokens create deploy -x 999999h`
3. CD workflow triggers on tags (`v*`), not pushes to main
