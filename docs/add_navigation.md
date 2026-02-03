# Add Flashcards Navigation

## Goal
Add a "Flashcards" link to the top navigation bar so users can navigate to `/flashcards` without typing the URL.

## Change

**File**: `lib/ohmyword_web/components/layouts/root.html.heex`

Add a `<li>` with a link to `/flashcards` before the theme toggle, visible to all users. Placed outside the `if @current_scope` block since the route is public.

## Verification
1. Run `mix test`
2. Start server, verify link appears for both logged-in and logged-out users
3. Confirm clicking the link navigates to `/flashcards`
