# Theme Toggle in Navigation - Technical Implementation

## Parent Story
[specs/features/po/theme-toggle-navigation.md](../po/theme-toggle-navigation.md)

## Technical Approach

### LiveView Components
- [x] Existing `theme_toggle/1` component in `lib/ohmyword_web/components/layouts.ex` (lines 123-153)
- No new components needed

### Schema/Context Changes
- No schema or context changes required
- No migrations needed

### Frontend (LiveView/HEEX)
- [x] Modified `root.html.heex` to include theme toggle in navigation (line 35-37)
- [x] Removed theme toggle from `home.html.heex` (previously line 5)
- Event handlers already implemented via `phx-click={JS.dispatch("phx:set-theme")}`
- No additional JS Hooks needed

### Backend Logic
- No backend logic changes required
- Theme management is purely client-side via JavaScript and localStorage
- Theme state persisted in localStorage with key `"phx:theme"`

## Testing Strategy
- [ ] Manual testing: Verify theme toggle appears in navigation on all pages
- [ ] Manual testing: Verify theme switching works (System/Light/Dark)
- [ ] Manual testing: Verify theme persists across page refreshes
- [ ] Manual testing: Verify no duplicate theme toggles on home page

## Technical Considerations
- **Performance implications**: None - component already exists and is lightweight
- **Security concerns**: None - theme preference is client-side only
- **Dependencies/libraries needed**: None - uses existing Phoenix.JS and localStorage

## Implementation Steps
1. Add `<Layouts.theme_toggle />` to navigation in `root.html.heex`
2. Remove theme toggle from `home.html.heex`
3. Verify changes via hot reload in development server

## Estimated Complexity
Low - Simple component relocation, no new logic or dependencies required

## Files Modified
- `lib/ohmyword_web/components/layouts/root.html.heex` (added theme toggle to navigation)
- `lib/ohmyword_web/controllers/page_html/home.html.heex` (removed theme toggle from content)
