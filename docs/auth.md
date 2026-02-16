# Authentication & Authorization Audit

## Authentication

### Overview

Full `phx.gen.auth` system is implemented and **all backend code is active**. The only disabled part is the **navbar UI** — login/register/logout links are commented out in the layout, but all routes, controllers, and LiveViews remain functional and reachable via direct URL.

### What's Active

| Component | Location | Status |
|-----------|----------|--------|
| User registration | `UserLive.Registration` → `POST /users/log-in` | Active (route works) |
| Login | `UserLive.Login` → `UserSessionController.create` | Active (route works) |
| Logout | `DELETE /users/log-out` → `UserSessionController.delete` | Active (route works) |
| Email confirmation | `UserLive.Confirmation` — token-based | Active |
| Resend confirmation | `UserLive.ResendConfirmation` | Active |
| User settings | `UserLive.Settings` — email & password change | Active (requires sudo mode) |
| Password update | `POST /users/update-password` | Active |
| Session management | DB-backed tokens, remember-me cookie | Active |

### What's Commented Out (UI Only)

**Navbar auth links** (`lib/ohmyword_web/components/layouts/root.html.heex:114-133`):
```heex
<%!-- DO NOT REMOVE
<%= if @current_scope do %>
  ... Settings, Log out links ...
<% else %>
  ... Register, Log in links ...
<% end %>
--%>
```

Also commented out in the same file: theme toggle (lines 109-113). Both marked with `DO NOT REMOVE`.

**Impact**: Users have no visible way to reach auth pages from the UI, but navigating to `/users/register` or `/users/log-in` directly works.

### Authentication Flow

1. **Registration**: User submits email + username + password → account created (unconfirmed) → confirmation email sent
2. **Email confirmation**: User clicks token link → `confirmed_at` timestamp set → can now log in
3. **Login**: Email + password validated → session token generated (stored in DB) → optional remember-me cookie (14 days)
4. **Session lifecycle**: Tokens auto-reissue after 7 days, expire after 14 days
5. **Sudo mode**: Sensitive operations (password/email change) require re-authentication within 20 minutes
6. **Logout**: Session token deleted from DB, all LiveSockets disconnected

### Key Modules

- **`Ohmyword.Accounts`** (`lib/ohmyword/accounts.ex`) — context module: registration, login, token management, email operations
- **`Accounts.User`** (`lib/ohmyword/accounts/user.ex`) — schema: email (citext), username (citext), role (enum), hashed_password (bcrypt), confirmed_at
- **`Accounts.UserToken`** (`lib/ohmyword/accounts/user_token.ex`) — session/confirmation/email-change tokens with expiry
- **`Accounts.Scope`** (`lib/ohmyword/accounts/scope.ex`) — wraps user into `current_scope` assign (used instead of `current_user`)
- **`Accounts.UserNotifier`** (`lib/ohmyword/accounts/user_notifier.ex`) — Swoosh emails for confirmation and email change
- **`OhmywordWeb.UserAuth`** (`lib/ohmyword_web/user_auth.ex`) — plugs and LiveView on_mount hooks
- **`UserSessionController`** (`lib/ohmyword_web/controllers/user_session_controller.ex`) — login/logout/password-update actions
- **LiveViews**: `UserLive.Login`, `UserLive.Registration`, `UserLive.Confirmation`, `UserLive.ResendConfirmation`, `UserLive.Settings`

### Security Features

- **Bcrypt password hashing** (72-byte max, log_rounds=1 in test)
- **Email confirmation required** before login
- **User enumeration prevention** — generic error on invalid credentials
- **CSRF protection** — session renewal on login prevents fixation attacks
- **Session tokens in DB** — enables server-side revocation (not just signed cookies)
- **Email tokens hashed (SHA256)** — confirmation/change tokens not stored in plaintext
- **Sudo mode** — re-auth within 20 min for password/email changes
- **Remember-me cookie** — signed, Lax same-site, 14-day max-age
- **Password change invalidates all sessions** — deletes all tokens, broadcasts disconnect

### Database Tables

- **`users`**: id, email (citext, unique), username (citext, unique), role (string, default "member"), hashed_password, confirmed_at, timestamps
- **`users_tokens`**: id, user_id (FK), token (binary), context (string), sent_to (string), authenticated_at, inserted_at

---

## Authorization

### Overview

Role-based access control with two roles: `:member` (default) and `:admin`. Uses the **LetMe** policy library for declarative rule definitions. Admin access is protected by a three-layer "defense in depth" strategy.

### Roles

| Role | Assigned via | Capabilities |
|------|-------------|--------------|
| `:member` | Default on registration | Access authenticated routes (settings) |
| `:admin` | Manual DB update | All member capabilities + admin dashboard + Kaffy admin panel |

### Route Protection

| Route pattern | Protection | Hook/Plug |
|---------------|-----------|-----------|
| `/`, `/flashcards`, `/dictionary/*`, `/write` | Public (optional auth) | `mount_current_scope` |
| `/users/register`, `/users/log-in`, `/users/confirm/*` | Public | `mount_current_scope` |
| `/users/settings`, `/users/update-password` | Authenticated | `require_authenticated` + `require_sudo_mode` |
| `/admin/dashboard` | Admin | `require_admin_user` (on_mount) |
| `/admin/kaffy/*` | Admin | `:admins_only` pipeline (plug-based) |

### LiveView Hooks (`OhmywordWeb.UserAuth`)

1. **`:mount_current_scope`** — assigns `current_scope` (nil if no user), continues
2. **`:require_authenticated`** — redirects to `/users/log-in` if no user
3. **`:require_sudo_mode`** — redirects to `/users/log-in` if last auth > 20 min ago
4. **`:require_admin_user`** — checks admin role via Policy, redirects to `/` if not admin

### Admin Defense in Depth (3 layers)

1. **Router pipeline** (`:admins_only`): `require_authenticated_user` plug + `RequireAdmin` plug
2. **`RequireAdmin` plug** (`lib/ohmyword_web/plugs/require_admin.ex`): checks `user.role == :admin`
3. **Kaffy authorization callback** (`lib/ohmyword_web/admin.ex`): `authorize_resource/1` calls `Policy.authorize_action?(:view_admin_dashboard, user, :user)`

### Policy Module

**`Ohmyword.Policy`** (`lib/ohmyword/policy.ex`) — LetMe-based:

```elixir
object :user do
  action :view_admin_dashboard do
    allow({:role_is, [:admin]})
  end
end
```

Single policy rule currently. `Policy.Checks.role_is/3` does case-insensitive role comparison.

### Key Authorization Files

- **`Ohmyword.Policy`** (`lib/ohmyword/policy.ex`) — LetMe policy rules
- **`Policy.Checks`** (`lib/ohmyword/policy/checks.ex`) — role_is check implementation
- **`Plugs.RequireAdmin`** (`lib/ohmyword_web/plugs/require_admin.ex`) — Kaffy admin plug
- **`OhmywordWeb.Admin`** (`lib/ohmyword_web/admin.ex`) — Kaffy authorization callback
