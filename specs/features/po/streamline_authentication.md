# Streamline Authentication to Email/Password Only

## User Story
As a product owner
I want a clean, standard email/password authentication flow
So that users have a simple, secure registration and login experience without unnecessary authentication options

## Problem Statement
The default `mix phx.gen.auth` generates multiple authentication methods (passwordless login, magic links for login, etc.) that we don't need. We want only:
1. Registration with email/password
2. Email confirmation via magic link (one-time use)
3. Login with confirmed email/password only

## Acceptance Criteria

### Registration Flow
- [x] User can register with email and password
- [x] Password must meet minimum security requirements (length min: 12, max: 72 characters)
- [x] Upon registration, user account is created but unconfirmed
- [x] Confirmation email is sent immediately after registration
- [x] User sees message: "Please check your email to confirm your account"
- [x] User cannot log in until email is confirmed
- [x] Local mail adapter notification shown in development

### Email Confirmation Flow
- [x] User receives email with confirmation link (magic link)
- [x] Clicking the confirmation link confirms the email and marks account as active
- [x] Confirmation link can be clicked multiple times (idempotent)
- [x] Confirmation link expires after 7 days
- [x] After confirmation, user sees success message and can log in
- [x] If link is expired or invalid, user sees appropriate error message

### Login Flow
- [x] User can log in ONLY with confirmed email and correct password
- [x] Unconfirmed users attempting to login are redirected to resend confirmation page
- [x] Unconfirmed users see message: "You must confirm your email before logging in. Please check your email for confirmation instructions."
- [x] Invalid credentials show: "Invalid email or password"
- [x] Successful login redirects to dashboard/home page
- [x] User session is maintained across requests
- [x] "Keep me logged in" checkbox available (remember me)

### Resend Confirmation Flow
- [x] Dedicated page at `/users/resend-confirmation` for resending confirmation emails
- [x] Email field pre-filled when redirected from login attempt
- [x] User can manually enter email to resend confirmation
- [x] Resending to unconfirmed email: sends new confirmation email
- [x] Resending to already-confirmed email shows: "This email is already confirmed. You can log in now."
- [x] Resending to non-existent email shows same generic message (prevents user enumeration)
- [x] Generic success message: "If your email is in our system, you will receive confirmation instructions shortly"
- [x] Local mail adapter notification shown in development

### Removed Features
- [x] No passwordless/magic link login option (only for confirmation)
- [x] No "login without password" flows
- [x] No alternative authentication methods
- [x] Clean UI with only necessary forms
- [x] Removed dual login buttons ("login and stay logged in" vs "login only this time")

## Technical Implementation Guide

### Core Changes Required

#### 1. Accounts Context (`lib/ohmyword/accounts.ex`)
- **Modified**: `get_user_by_email_and_password/2`
  - Now checks `confirmed_at` field
  - Returns `{:error, :unconfirmed}` for valid credentials but unconfirmed email
  - Returns `%User{}` for valid confirmed credentials
  - Returns `nil` for invalid credentials
- **Kept**: `deliver_user_confirmation_instructions/2` for sending confirmation emails
- **Kept**: `confirm_user/1` for confirming user accounts (made idempotent)

#### 2. Session Controller (`lib/ohmyword_web/controllers/user_session_controller.ex`)
- **Modified**: `create/2` action
  - Added case handling for `{:error, :unconfirmed}`
  - Redirects unconfirmed users to `/users/resend-confirmation`
  - Passes email in flash for pre-filling resend form
  - Shows appropriate error messages for each case

#### 3. New LiveView (`lib/ohmyword_web/live/user_live/resend_confirmation.ex`)
- **Created**: New LiveView for resending confirmation emails
  - Form to enter email address
  - Sends new confirmation email via `deliver_user_confirmation_instructions/2`
  - Prevents user enumeration (same message for all cases)
  - Shows local mail adapter notification in dev
  - Pre-fills email from flash when redirected from login

#### 4. Router (`lib/ohmyword_web/router.ex`)
- **Added**: `live "/users/resend-confirmation", UserLive.ResendConfirmation, :new`

#### 5. UI Updates
- **Modified**: Login page - removed dual buttons, added single button with checkbox
- **Modified**: Registration page - added local mail adapter notification
- **Modified**: Login page - added local mail adapter notification

### Database Schema
- `users.confirmed_at` - `utc_datetime` field (already exists from phx.gen.auth)
  - Set to `nil` on registration
  - Set to current timestamp when confirmation link is clicked
  - Used to check if user can log in

### Security Considerations
- **User Enumeration Prevention**: Don't reveal whether email exists when:
  - Resending confirmation (always show generic success message)
  - Invalid login attempts (always show "Invalid email or password")
- **Token Security**:
  - Confirmation tokens expire after 7 days
  - Tokens are single-use in practice but safe to click multiple times (idempotent)
- **Password Security**:
  - Hashed using Bcrypt
  - Minimum 12 characters
  - Maximum 72 characters (Bcrypt limitation)

## Testing Requirements

### Unit Tests (`test/ohmyword/accounts_test.exs`)
- [x] `get_user_by_email_and_password/2` returns error for unconfirmed user
- [x] `get_user_by_email_and_password/2` returns user for confirmed user
- [x] `confirm_user/1` is idempotent (can be called multiple times)
- [x] All existing user tests pass

### Controller Tests (`test/ohmyword_web/controllers/user_session_controller_test.exs`)
- [x] Unconfirmed user login redirects to resend page
- [x] Confirmed user login succeeds
- [x] Invalid credentials show generic error
- [x] All existing session tests pass

### LiveView Tests (`test/ohmyword_web/live/user_live/resend_confirmation_test.exs`)
- [x] Resend confirmation page renders correctly
- [x] Resend sends email for unconfirmed user
- [x] Resend shows appropriate message for confirmed user
- [x] Email pre-fills when redirected from login
- [x] No user enumeration (same message for all cases)
- [x] Resend for non-existent email shows generic message

### Test Results
- [x] All 109 tests passing (added 7 new tests)

## Business Value
- **Security**: Clear authentication boundaries reduce attack surface
- **User Experience**: Simpler flow is easier to understand and use
- **Maintainability**: Less code to maintain and test
- **Compliance**: Standard email confirmation meets most regulatory requirements
- **Developer Experience**: Clear local mail testing with notifications

## User Flows

### Happy Path - New User
1. User visits registration page
2. Enters email and password
3. Submits form
4. Sees confirmation message with local mail notification (dev only)
5. Checks email (or `/dev/mailbox` in development)
6. Clicks confirmation link
7. Sees success message
8. Returns to site and logs in
9. Successfully accesses authenticated areas

### Edge Case: Unconfirmed User Tries to Login
```
User → Login Form (email + password)
  ↓ (submit with valid credentials)
Check if confirmed?
  ↓ NO
Error: "You must confirm your email before logging in"
  ↓
Redirect to /users/resend-confirmation (email pre-filled)
  ↓
User → Resend Form → New confirmation email sent
  ↓
Message: "If your email is in our system, you will receive confirmation instructions shortly"
  ↓
User checks email → Clicks link → Account confirmed
  ↓
User → Login → Success
```

### Edge Case: Lost Confirmation Email
```
User → Can't find confirmation email
  ↓
User → Tries to login
  ↓ (blocked because unconfirmed)
Redirected to /users/resend-confirmation
  ↓
Enter email → New confirmation sent
  ↓
Check email → Click link → Confirmed
```

### Edge Case: User Tries to Register with Existing Email
```
User → Registration Form
  ↓ (enters already-registered email)
Submit
  ↓
Error: "Email has already been taken"
  ↓
User corrects or goes to login
```

### Edge Case: Confirmation Link Clicked Multiple Times
```
User → Clicks confirmation link
  ↓
Account confirmed ✓
  ↓
User → Clicks same link again (e.g., refreshes page)
  ↓
Still shows success (idempotent - no error)
```

## Development Environment

### Local Mail Testing
- [x] Local mail adapter notification shown on registration page
- [x] Local mail adapter notification shown on login page
- [x] Local mail adapter notification shown on resend confirmation page
- [x] Notification includes link to `/dev/mailbox` for viewing emails
- [x] Only shown when `Swoosh.Adapters.Local` is configured
- [x] Helper function `local_mail_adapter?/0` in each LiveView

### Development Workflow
1. User registers → Email appears in `/dev/mailbox`
2. Click confirmation link from mailbox → Account confirmed
3. User can now log in

## Explicitly Out of Scope
- ❌ Magic link LOGIN (only magic links for email confirmation)
- ❌ Passwordless authentication
- ❌ Password reset (separate feature card)
- ❌ Two-factor authentication (future enhancement)
- ❌ Social login / OAuth (future enhancement)
- ❌ Account deletion
- ❌ Email change functionality (already exists in settings)
- ✅ Remember me checkbox (already exists, kept as-is)

## Implementation Notes

### What Was Removed
- Magic link login functionality
- `get_user_by_magic_link_token/1` function
- `login_user_by_magic_link/1` function
- `deliver_login_instructions/2` function
- Magic link login email templates
- Dual login buttons ("login and stay" vs "login once")

### What Was Kept
- Password-based authentication
- Email confirmation via magic link
- Session management
- User settings page
- Password change functionality
- Remember me checkbox

### What Was Added
- Email confirmation enforcement before login
- Resend confirmation page
- Pre-filled email on resend page when redirected from login
- Local mail adapter notifications
- Security: prevention of user enumeration
- Idempotent confirmation (safe to click link multiple times)
- 7 new tests covering the new functionality

## Success Metrics
- ✅ All 109 tests passing
- ✅ No regression in existing functionality
- ✅ Clean, simple user experience
- ✅ Secure authentication flow
- ✅ Easy local development with mail preview

## Related Documentation
- Phoenix Authentication: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html
- Swoosh Adapters: https://hexdocs.pm/swoosh/Swoosh.Adapters.Local.html
- Security Best Practices: Prevent user enumeration, use bcrypt for passwords
