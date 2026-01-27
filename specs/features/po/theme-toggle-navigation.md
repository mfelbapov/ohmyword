# Theme Toggle in Navigation

## User Story
As a user of the application
I want to access the theme toggle from the navigation bar
So that I can easily switch between light, dark, and system themes from any page

## Acceptance Criteria
- [ ] Theme toggle appears in the navigation bar on all pages
- [ ] Theme toggle is positioned consistently (before authentication links)
- [ ] Clicking theme options (System/Light/Dark) changes the theme immediately
- [ ] Selected theme persists across page refreshes and browser sessions
- [ ] Theme toggle is removed from the home page content area

## Business Value
Improves user experience by providing consistent, easy access to theme preferences from any location in the application. Users no longer need to navigate to a specific page to change their theme preference.

## Success Metrics
- Theme toggle is accessible from navigation on 100% of pages
- User theme preferences are persisted in localStorage
- No duplicate theme toggles appear on any page

## Notes/Context
Previously, the theme toggle was embedded in the home page content. Moving it to the root layout's navigation ensures it's available globally and provides a more intuitive, consistent user experience.
