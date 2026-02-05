# Standardize DaisyUI Button Components

## User Story
As a developer
I want a comprehensive, consistent button component system using DaisyUI
So that I can easily create buttons with proper styling without writing manual CSS classes

## Problem Statement
DaisyUI is already installed and configured in the project, but the button component implementation is limited:
- Only supports 2 variants (primary and soft-primary) out of 9+ available DaisyUI variants
- Inconsistent usage across the codebase (manual `class="btn btn-primary w-full"` vs component attributes)
- No support for DaisyUI button sizes (xs, sm, md, lg)
- No support for DaisyUI button modifiers (outline, wide, block, circle, square)
- Custom `btn-soft` class not documented or clearly defined
- Developers bypass the component system to get the styling they need

## Acceptance Criteria

### Button Variant Support
- [ ] Support all DaisyUI color variants:
  - [ ] `primary` - Primary theme color
  - [ ] `secondary` - Secondary theme color
  - [ ] `accent` - Accent theme color
  - [ ] `ghost` - Transparent with hover effect
  - [ ] `link` - Styled as a link (underline on hover)
  - [ ] `info` - Info color (blue)
  - [ ] `success` - Success color (green)
  - [ ] `warning` - Warning color (yellow/orange)
  - [ ] `error` - Error/danger color (red)
  - [ ] `neutral` - Neutral/default color
- [ ] Default variant when none specified should be neutral or ghost

### Button Size Support
- [ ] Support all DaisyUI sizes via `size` attribute:
  - [ ] `xs` - Extra small
  - [ ] `sm` - Small
  - [ ] `md` - Medium (default if not specified)
  - [ ] `lg` - Large

### Button Modifier Support
- [ ] Support common DaisyUI modifiers via boolean attributes:
  - [ ] `outline` - Outlined style (transparent with border)
  - [ ] `wide` - Extra horizontal padding
  - [ ] `block` - Full width (replaces manual `w-full` classes)
  - [ ] `circle` - Circular button (for icons)
  - [ ] `square` - Square button (for icons)

### Loading & Disabled States
- [ ] Support `disabled` attribute (already works with Phoenix forms)
- [ ] Support `phx-disable-with` for loading states (already works)
- [ ] Loading spinner integration (optional enhancement)

### Navigation Support
- [ ] Maintain current smart rendering: `<.link>` for navigation, `<button>` for actions
- [ ] Support `href`, `navigate`, `patch` attributes (already working)
- [ ] Support `method` for form submissions (already working)

### Code Consistency
- [ ] Remove all manual button class overrides from LiveView files
- [ ] Update all button usages to use component attributes instead
- [ ] Remove or document `btn-soft` custom class
- [ ] Consistent API across all button instances

### Developer Experience
- [ ] Clear component documentation with examples
- [ ] Intuitive attribute names matching DaisyUI conventions
- [ ] Backward compatible with existing button usages where possible

## Business Value
- **Developer Productivity**: Faster development with clear, reusable component API
- **Design Consistency**: Uniform button styling across entire application
- **Maintainability**: Centralized button logic easier to update and maintain
- **DaisyUI Leverage**: Fully utilize the already-installed DaisyUI library
- **Code Quality**: Cleaner templates without repetitive CSS class strings

## Technical Implementation Guide

### Current State Analysis

**Existing Setup**:
- DaisyUI: Already installed via vendor plugin (`assets/vendor/daisyui.js`)
- Tailwind v4: Latest version configured
- Custom Themes: Light (Phoenix orange) and Dark (Elixir purple) themes defined
- Component Location: `lib/ohmyword_web/components/core_components.ex`
- Current Variants: Only `primary` and `nil` (soft-primary)

**Current Button Component** (`core_components.ex` lines 83-117):
```elixir
variants = %{"primary" => "btn-primary", nil => "btn-primary btn-soft"}
```

**Problem Pattern** (found in auth LiveViews):
```heex
<!-- Manual class override bypassing variant system -->
<.button class="btn btn-primary w-full">Log in</.button>

<!-- Correct usage but limited variants -->
<.button variant="primary" phx-disable-with="Changing...">Change Email</.button>
```

### Implementation Steps

#### 1. Update Button Component (`lib/ohmyword_web/components/core_components.ex`)

**New Attribute Support**:
```elixir
attr :variant, :string, default: nil, values: ~w(primary secondary accent ghost link info success warning error neutral)
attr :size, :string, default: "md", values: ~w(xs sm md lg)
attr :outline, :boolean, default: false
attr :wide, :boolean, default: false
attr :block, :boolean, default: false
attr :circle, :boolean, default: false
attr :square, :boolean, default: false
```

**Class Building Logic**:
- Base: `"btn"`
- Variant: `"btn-{variant}"` (e.g., `btn-primary`, `btn-ghost`)
- Size: `"btn-{size}"` (e.g., `btn-sm`, `btn-lg`) - only if not `md`
- Modifiers: Add `btn-outline`, `btn-wide`, `btn-block`, `btn-circle`, `btn-square` when true
- Custom classes: Merge with user-provided `class` attribute
- Remove `btn-soft` unless it's documented as needed

**Example Implementation**:
```elixir
defp build_button_classes(variant, size, modifiers, custom_class) do
  base = ["btn"]

  variant_class = if variant, do: ["btn-#{variant}"], else: []
  size_class = if size != "md", do: ["btn-#{size}"], else: []

  modifier_classes =
    modifiers
    |> Enum.filter(fn {_key, value} -> value end)
    |> Enum.map(fn {key, _} -> "btn-#{key}" end)

  [base, variant_class, size_class, modifier_classes, custom_class]
  |> List.flatten()
  |> Enum.join(" ")
end
```

#### 2. Update Authentication Flow Files

**Files to Update**:
- `lib/ohmyword_web/live/user_live/login.ex`
- `lib/ohmyword_web/live/user_live/registration.ex`
- `lib/ohmyword_web/live/user_live/resend_confirmation.ex`
- `lib/ohmyword_web/live/user_live/settings.ex`

**Migration Pattern**:
```heex
<!-- BEFORE -->
<.button class="btn btn-primary w-full">Log in</.button>

<!-- AFTER -->
<.button variant="primary" block>Log in</.button>
```

```heex
<!-- BEFORE -->
<.button variant="primary" phx-disable-with="Changing...">Change Email</.button>

<!-- AFTER (no change, already correct) -->
<.button variant="primary" phx-disable-with="Changing...">Change Email</.button>
```

#### 3. Update Layout Navigation

**File**: `lib/ohmyword_web/components/layouts.ex`

**Current Pattern**:
```heex
<a href="..." class="btn btn-ghost">Website</a>
```

**After Migration**:
```heex
<.button href="..." variant="ghost">Website</.button>
```

#### 4. Handle `btn-soft` Custom Class

**Investigation Needed**:
- Check if `btn-soft` exists in custom theme configuration
- Check if it's used in the custom CSS files
- If not defined anywhere, remove it from the variant map
- If needed, document its purpose or add proper theme support

### Database/Schema Changes
No database changes required - this is purely a component/UI update.

### Security Considerations
- Ensure XSS protection remains intact (Phoenix escapes by default)
- Verify button `href` navigation still respects CSRF tokens
- No security impact expected - purely presentational changes

## Testing Requirements

### Component Tests
- [ ] Test all 10 color variants render correct classes
- [ ] Test all 4 sizes render correct classes
- [ ] Test all modifiers (outline, wide, block, circle, square) render correct classes
- [ ] Test combining variant + size + modifiers works correctly
- [ ] Test `class` attribute merging with component classes
- [ ] Test navigation attributes (href, navigate, patch) still work
- [ ] Test smart rendering (link vs button element)

### Integration Tests
- [ ] All existing LiveView tests pass
- [ ] Auth flow tests pass (login, registration, confirmation)
- [ ] Settings page tests pass
- [ ] No visual regressions in button appearance

### Manual Testing Checklist
- [ ] Visual inspection of all button variants in Storybook or demo page
- [ ] Test light and dark theme rendering
- [ ] Test disabled state appearance
- [ ] Test loading state (`phx-disable-with`) appearance
- [ ] Test responsive behavior on mobile

## Success Metrics
- [ ] Zero instances of manual `class="btn btn-*"` overrides in LiveView files
- [ ] All existing tests passing
- [ ] Component supports 10+ variants (vs current 2)
- [ ] Component supports 4 sizes (vs current 1)
- [ ] Component supports 5+ modifiers (vs current 0)
- [ ] Code reduction: Less repetitive CSS classes in templates

## User Flows

### Developer Using New Button Component

#### Creating a Primary Action Button
```heex
<!-- Simple primary button -->
<.button variant="primary">Submit</.button>

<!-- Primary button with size -->
<.button variant="primary" size="lg">Big Submit Button</.button>

<!-- Primary outlined button -->
<.button variant="primary" outline>Cancel</.button>

<!-- Full-width primary button (common in forms) -->
<.button variant="primary" block>Log In</.button>
```

#### Creating Secondary/Utility Buttons
```heex
<!-- Ghost button (common in nav) -->
<.button variant="ghost">Menu</.button>

<!-- Link-styled button -->
<.button variant="link" navigate={~p"/help"}>Learn More</.button>

<!-- Small icon button -->
<.button variant="ghost" size="sm" circle>
  <.icon name="hero-x-mark" />
</.button>
```

#### Creating Semantic Action Buttons
```heex
<!-- Destructive action -->
<.button variant="error" outline>Delete Account</.button>

<!-- Success confirmation -->
<.button variant="success">Confirm</.button>

<!-- Warning action -->
<.button variant="warning">Proceed with Caution</.button>

<!-- Informational action -->
<.button variant="info">View Details</.button>
```

#### Navigation Buttons
```heex
<!-- Internal navigation (SPA-style) -->
<.button variant="primary" navigate={~p"/dashboard"}>Go to Dashboard</.button>

<!-- External link -->
<.button variant="ghost" href="https://example.com">External Link</.button>

<!-- Patch navigation (updates URL without full page load) -->
<.button variant="secondary" patch={~p"/users/#{@user.id}/edit"}>Edit</.button>
```

### Migration Path for Existing Code

**Step 1**: Update `core_components.ex` with new attributes and class building
**Step 2**: Update one LiveView at a time (start with login)
**Step 3**: Run tests after each file update
**Step 4**: Update layouts last
**Step 5**: Global search for `class="btn ` to find any missed instances

## Examples of DaisyUI Button Variants

### Color Variants (from DaisyUI docs)
```html
<!-- Primary: Main brand color (Phoenix orange in light, Elixir purple in dark) -->
<button class="btn btn-primary">Primary</button>

<!-- Secondary: Secondary brand color -->
<button class="btn btn-secondary">Secondary</button>

<!-- Accent: Accent color for highlights -->
<button class="btn btn-accent">Accent</button>

<!-- Ghost: Transparent, visible on hover -->
<button class="btn btn-ghost">Ghost</button>

<!-- Link: Styled as underlined text -->
<button class="btn btn-link">Link</button>

<!-- Info: Informational actions (blue) -->
<button class="btn btn-info">Info</button>

<!-- Success: Success actions (green) -->
<button class="btn btn-success">Success</button>

<!-- Warning: Warning actions (yellow/orange) -->
<button class="btn btn-warning">Warning</button>

<!-- Error: Destructive actions (red) -->
<button class="btn btn-error">Error</button>

<!-- Neutral: Default/neutral styling -->
<button class="btn btn-neutral">Neutral</button>
```

### Size Variants
```html
<button class="btn btn-xs">Extra Small</button>
<button class="btn btn-sm">Small</button>
<button class="btn btn-md">Medium (default)</button>
<button class="btn btn-lg">Large</button>
```

### Modifiers
```html
<!-- Outlined buttons -->
<button class="btn btn-outline btn-primary">Outlined</button>

<!-- Wide buttons (extra padding) -->
<button class="btn btn-wide">Wide Button</button>

<!-- Block buttons (full width) -->
<button class="btn btn-block">Full Width</button>

<!-- Icon buttons -->
<button class="btn btn-circle btn-ghost">
  <svg>...</svg>
</button>

<button class="btn btn-square">
  <svg>...</svg>
</button>
```

### Combined Usage
```html
<!-- Large outlined primary button -->
<button class="btn btn-primary btn-outline btn-lg">Get Started</button>

<!-- Small ghost icon button -->
<button class="btn btn-ghost btn-sm btn-circle">×</button>

<!-- Full-width primary button (common in forms) -->
<button class="btn btn-primary btn-block">Submit Form</button>
```

## Explicitly Out of Scope
- ❌ Adding new DaisyUI components (cards, modals, etc.) - separate feature
- ❌ Installing DaisyUI (already installed)
- ❌ Theme customization (themes already configured)
- ❌ Button loading spinner component (can be added later)
- ❌ Icon integration (icons already working with hero-icons)
- ❌ Button groups/dropdown buttons (separate components)
- ❌ Tooltip integration for buttons (separate feature)
- ✅ Standardizing button component only

## Implementation Notes

### What's Already Working
- DaisyUI installed and configured
- Tailwind v4 with vendor plugin system
- Custom light/dark themes
- Theme toggle functionality
- Basic button component with smart link/button rendering
- Phoenix form integration (`phx-disable-with`, etc.)

### What Needs to Change
- Expand variant support from 2 to 10 variants
- Add size attribute (4 sizes)
- Add modifier attributes (5+ modifiers)
- Update ~15-20 button instances across auth LiveViews
- Update navigation buttons in layouts
- Remove manual `class="btn ..."` overrides

### Breaking Changes
- Removing `btn-soft` variant (if not documented/needed)
  - Migration: Replace with `outline` or `ghost` variant
- Default variant changing from `soft-primary` to `neutral` or `ghost`
  - Migration: Explicitly add `variant="primary"` where needed

## Related Documentation
- DaisyUI Buttons: https://daisyui.com/components/button/
- Tailwind CSS v4: https://tailwindcss.com/docs
- Phoenix Components: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html
- Current Implementation: `lib/ohmyword_web/components/core_components.ex:83-117`

## Future Enhancements (Not in This Card)
- Button loading spinner component
- Button group component (for grouped actions)
- Split button with dropdown
- Floating action button (FAB)
- Icon-only button helper
- Button with badge
- Social login buttons with brand colors

---

## Button Variant Color Mappings

This section documents the exact color values used by each button variant in both light and dark themes. All colors are defined using the OKLCH color space (a modern, perceptually uniform color format) in `assets/css/app.css`.

### Understanding OKLCH Format
OKLCH format: `oklch(L% C H)` where:
- **L** = Lightness (0-100%)
- **C** = Chroma/saturation (0-0.4+)
- **H** = Hue (0-360 degrees)

### Color Variant Reference Table

| Variant | CSS Class | CSS Variable | Light Theme Color | Dark Theme Color | Description |
|---------|-----------|--------------|-------------------|------------------|-------------|
| **primary** | `btn-primary` | `--color-primary` | `oklch(70% 0.213 47.604)` | `oklch(58% 0.233 277.117)` | **Light**: Phoenix orange/coral<br>**Dark**: Elixir purple |
| **secondary** | `btn-secondary` | `--color-secondary` | `oklch(55% 0.027 264.364)` | `oklch(58% 0.233 277.117)` | **Light**: Purple/blue<br>**Dark**: Elixir purple (same as primary) |
| **accent** | `btn-accent` | `--color-accent` | `oklch(0% 0 0)` | `oklch(60% 0.25 292.717)` | **Light**: Black<br>**Dark**: Pink/magenta |
| **neutral** | `btn-neutral` | `--color-neutral` | `oklch(44% 0.017 285.786)` | `oklch(37% 0.044 257.287)` | **Light**: Dark gray<br>**Dark**: Dark blue-gray |
| **info** | `btn-info` | `--color-info` | `oklch(62% 0.214 259.815)` | `oklch(58% 0.158 241.966)` | **Light**: Bright blue<br>**Dark**: Medium blue |
| **success** | `btn-success` | `--color-success` | `oklch(70% 0.14 182.503)` | `oklch(60% 0.118 184.704)` | **Light**: Bright green<br>**Dark**: Medium green |
| **warning** | `btn-warning` | `--color-warning` | `oklch(66% 0.179 58.318)` | `oklch(66% 0.179 58.318)` | **Light/Dark**: Yellow/amber (same in both themes) |
| **error** | `btn-error` | `--color-error` | `oklch(58% 0.253 17.585)` | `oklch(58% 0.253 17.585)` | **Light/Dark**: Red (same in both themes) |
| **ghost** | `btn-ghost` | N/A | Transparent | Transparent | Transparent background, visible on hover |
| **link** | `btn-link` | N/A | Styled as link | Styled as link | No background, underline on hover |

### Content (Text) Colors

Each variant also has a corresponding `-content` variable for optimal text contrast:

| Variant | CSS Variable | Light Theme | Dark Theme | Usage |
|---------|--------------|-------------|------------|-------|
| **primary-content** | `--color-primary-content` | `oklch(98% 0.016 73.684)` | `oklch(96% 0.018 272.314)` | Text on primary buttons |
| **secondary-content** | `--color-secondary-content` | `oklch(98% 0.002 247.839)` | `oklch(96% 0.018 272.314)` | Text on secondary buttons |
| **accent-content** | `--color-accent-content` | `oklch(100% 0 0)` | `oklch(96% 0.016 293.756)` | Text on accent buttons |
| **neutral-content** | `--color-neutral-content` | `oklch(98% 0 0)` | `oklch(98% 0.003 247.858)` | Text on neutral buttons |
| **info-content** | `--color-info-content` | `oklch(97% 0.014 254.604)` | `oklch(97% 0.013 236.62)` | Text on info buttons |
| **success-content** | `--color-success-content` | `oklch(98% 0.014 180.72)` | `oklch(98% 0.014 180.72)` | Text on success buttons |
| **warning-content** | `--color-warning-content` | `oklch(98% 0.022 95.277)` | `oklch(98% 0.022 95.277)` | Text on warning buttons |
| **error-content** | `--color-error-content` | `oklch(96% 0.015 12.422)` | `oklch(96% 0.015 12.422)` | Text on error buttons |

### Theme Philosophy

**Light Theme**:
- Primary uses **Phoenix orange** (warm, energetic) to match Phoenix Framework branding
- Secondary uses **purple/blue** tones
- Accent is **black** for high contrast
- Semantic colors (info/success/warning/error) use standard web conventions

**Dark Theme**:
- Primary uses **Elixir purple** to match Elixir language branding
- Secondary also uses purple for consistency
- Accent is **pink/magenta** for vibrant contrast against dark backgrounds
- Semantic colors maintain similar hues but adjusted for dark mode readability

### Usage Examples with Colors

```heex
<!-- Primary button: Orange in light theme, Purple in dark theme -->
<.button variant="primary">Submit</.button>

<!-- Success button: Green in both themes -->
<.button variant="success">Confirm</.button>

<!-- Error button: Red in both themes -->
<.button variant="error" outline>Delete</.button>

<!-- Ghost button: Transparent, inherits text color -->
<.button variant="ghost">Cancel</.button>

<!-- Neutral button: Dark gray in light, blue-gray in dark -->
<.button variant="neutral">Settings</.button>
```

### Color Source Reference

All color values are defined in `/Users/mfelbapov/Projects/ohmyword/assets/css/app.css` using Tailwind CSS v4's `@theme` directive:

```css
@theme {
  /* Light theme colors */
  --color-primary: oklch(70% 0.213 47.604);
  /* ... etc */

  /* Dark theme colors (in @media (prefers-color-scheme: dark)) */
  --color-primary: oklch(58% 0.233 277.117);
  /* ... etc */
}
```

DaisyUI automatically applies these colors to button variants using the `btn-{variant}` classes, handling hover states, focus states, and accessibility automatically.

---

## Flash/Alert Component Color Mappings

The Flash component uses DaisyUI's alert variants to display toast notifications. Each variant uses semantic colors that automatically adapt to light/dark themes.

### Alert Variant Reference Table

| Variant | CSS Class | CSS Variable | Light Theme Color | Dark Theme Color | Icon | Description |
|---------|-----------|--------------|-------------------|------------------|------|-------------|
| **info** | `alert-info` | `--color-info` | `oklch(62% 0.214 259.815)` | `oklch(58% 0.158 241.966)` | `hero-information-circle` | **Light**: Bright blue<br>**Dark**: Medium blue |
| **success** | `alert-success` | `--color-success` | `oklch(70% 0.14 182.503)` | `oklch(60% 0.118 184.704)` | `hero-check-circle` | **Light**: Bright green<br>**Dark**: Medium green |
| **warning** | `alert-warning` | `--color-warning` | `oklch(66% 0.179 58.318)` | `oklch(66% 0.179 58.318)` | `hero-exclamation-triangle` | **Light/Dark**: Yellow/amber (same in both) |
| **error** | `alert-error` | `--color-error` | `oklch(58% 0.253 17.585)` | `oklch(58% 0.253 17.585)` | `hero-exclamation-circle` | **Light/Dark**: Red (same in both) |

### Flash Usage Examples

```heex
<!-- Info flash: Blue notification -->
<.flash kind={:info} flash={@flash} />
<.flash kind={:info}>Account created successfully!</.flash>

<!-- Success flash: Green confirmation -->
<.flash kind={:success}>Changes saved!</.flash>

<!-- Warning flash: Yellow/amber caution -->
<.flash kind={:warning}>Your session will expire in 5 minutes</.flash>

<!-- Error flash: Red alert -->
<.flash kind={:error}>Invalid credentials</.flash>

<!-- With custom title -->
<.flash kind={:success} title="Success">Your payment was processed</.flash>
```

### Flash Component Implementation

```elixir
# In lib/ohmyword_web/components/core_components.ex
attr :kind, :atom, values: [:info, :success, :warning, :error]
# Renders as:
<div class="toast toast-top toast-end">
  <div class="alert alert-{kind}">
    <!-- Icon and message -->
  </div>
</div>
```

---

## Input/Select/Textarea Component Color Mappings

Form input components support DaisyUI variants for consistent styling and visual feedback. Inputs automatically show error states in red when validation fails.

### Input Variant Reference Table

| Variant | CSS Classes | CSS Variable | Light Theme Color | Dark Theme Color | Use Case |
|---------|-------------|--------------|-------------------|------------------|----------|
| **bordered** | `input-bordered`<br>`select-bordered`<br>`textarea-bordered` | N/A | Border with base color | Border with base color | Default bordered style |
| **ghost** | `input-ghost`<br>`select-ghost`<br>`textarea-ghost` | N/A | Transparent until focus | Transparent until focus | Minimal, subtle inputs |
| **primary** | `input-primary`<br>`select-primary` | `--color-primary` | `oklch(70% 0.213 47.604)` | `oklch(58% 0.233 277.117)` | Highlighted input (orange/purple) |
| **secondary** | `input-secondary` | `--color-secondary` | `oklch(55% 0.027 264.364)` | `oklch(58% 0.233 277.117)` | Secondary emphasis |
| **accent** | `input-accent` | `--color-accent` | `oklch(0% 0 0)` | `oklch(60% 0.25 292.717)` | Accent highlight (black/pink) |
| **info** | `input-info` | `--color-info` | `oklch(62% 0.214 259.815)` | `oklch(58% 0.158 241.966)` | Informational input (blue) |
| **success** | `input-success` | `--color-success` | `oklch(70% 0.14 182.503)` | `oklch(60% 0.118 184.704)` | Valid/success state (green) |
| **warning** | `input-warning` | `--color-warning` | `oklch(66% 0.179 58.318)` | `oklch(66% 0.179 58.318)` | Warning state (yellow/amber) |
| **error** | `input-error`<br>`select-error`<br>`textarea-error` | `--color-error` | `oklch(58% 0.253 17.585)` | `oklch(58% 0.253 17.585)` | Error/invalid state (red) - **auto-applied on validation errors** |

### Input Size Reference Table

| Size | CSS Class | Visual Size | Use Case |
|------|-----------|-------------|----------|
| **xs** | `input-xs`, `select-xs`, `textarea-xs` | Extra small | Compact forms, inline inputs |
| **sm** | `input-sm`, `select-sm`, `textarea-sm` | Small | Dense layouts |
| **md** | (default) | Medium | Standard form inputs |
| **lg** | `input-lg`, `select-lg`, `textarea-lg` | Large | Prominent forms, accessibility |

### Input Usage Examples

```heex
<!-- Standard text input -->
<.input field={@form[:email]} type="email" label="Email" />

<!-- Bordered variant input -->
<.input field={@form[:username]} type="text" variant="bordered" label="Username" />

<!-- Large primary input -->
<.input field={@form[:search]} type="search" variant="primary" size="lg" label="Search" />

<!-- Small ghost select -->
<.input
  field={@form[:role]}
  type="select"
  variant="ghost"
  size="sm"
  label="Role"
  options={["Admin", "User", "Guest"]}
/>

<!-- Success state textarea (explicitly set) -->
<.input
  field={@form[:bio]}
  type="textarea"
  variant="success"
  label="Biography"
/>

<!-- Input with validation errors (automatically shows error variant) -->
<.input field={@form[:password]} type="password" label="Password" />
<!-- If @form[:password].errors present, automatically renders with input-error -->

<!-- Checkbox with variant -->
<.input field={@form[:terms]} type="checkbox" variant="primary" label="I agree to terms" />
```

### Input Component Implementation

```elixir
# In lib/ohmyword_web/components/core_components.ex
attr :variant, :string, values: ~w(bordered ghost primary secondary accent info success warning error)
attr :size, :string, default: "md", values: ~w(xs sm md lg)

# Automatically builds classes:
# - Base: "input" / "select" / "textarea" / "checkbox"
# - Variant: "{base}-{variant}" (e.g., "input-primary")
# - Size: "{base}-{size}" for non-md sizes (e.g., "input-lg")
# - Error: "{base}-error" when validation errors present (overrides variant)
```

### Automatic Error Handling

**Important**: When a form field has validation errors (`@errors != []`), the component automatically applies the error variant (red), regardless of the specified variant. This ensures consistent error indication across all forms.

```heex
<!-- This input will show in red if validation fails, even though variant="primary" -->
<.input field={@form[:email]} type="email" variant="primary" label="Email" />
```

---

## Table Component Size & Modifier Mappings

Tables support size variants and modifier flags for flexible data display. Tables don't have color variants but use theme base colors.

### Table Size Reference

| Size | CSS Class | Row Height | Font Size | Use Case |
|------|-----------|------------|-----------|----------|
| **xs** | `table-xs` | Extra compact | Smaller text | Dense data tables, dashboards |
| **sm** | `table-sm` | Compact | Small text | Space-efficient tables |
| **md** | (default) | Standard | Normal text | General purpose tables |
| **lg** | `table-lg` | Spacious | Larger text | Readable, prominent tables |

### Table Modifier Reference

| Modifier | CSS Class | Attribute | Description | Visual Effect |
|----------|-----------|-----------|-------------|---------------|
| **zebra** | `table-zebra` | `zebra={true}` (default) | Alternating row colors | Improves row scanning, enabled by default |
| **pin-rows** | `table-pin-rows` | `pin_rows={true}` | Sticky header/footer | Header stays visible on scroll |
| **pin-cols** | `table-pin-cols` | `pin_cols={true}` | Sticky first column | First column stays visible on horizontal scroll |

### Table Usage Examples

```heex
<!-- Standard table with zebra striping (default) -->
<.table id="users" rows={@users}>
  <:col :let={user} label="Name">{user.name}</:col>
  <:col :let={user} label="Email">{user.email}</:col>
</.table>

<!-- Small table without zebra striping -->
<.table id="compact-users" rows={@users} size="sm" zebra={false}>
  <:col :let={user} label="Name">{user.name}</:col>
</.table>

<!-- Extra small table with pinned header -->
<.table id="dashboard-stats" rows={@stats} size="xs" pin_rows={true}>
  <:col :let={stat} label="Metric">{stat.metric}</:col>
  <:col :let={stat} label="Value">{stat.value}</:col>
</.table>

<!-- Large table with pinned first column -->
<.table id="wide-data" rows={@data} size="lg" pin_cols={true}>
  <:col :let={row} label="ID">{row.id}</:col>
  <:col :let={row} label="Data1">{row.data1}</:col>
  <:col :let={row} label="Data2">{row.data2}</:col>
  <:col :let={row} label="Data3">{row.data3}</:col>
</.table>

<!-- All features combined -->
<.table
  id="full-featured"
  rows={@records}
  size="sm"
  zebra={true}
  pin_rows={true}
  pin_cols={true}
  row_click={&JS.navigate(~p"/records/#{&1.id}")}
>
  <:col :let={record} label="ID">{record.id}</:col>
  <:col :let={record} label="Status">{record.status}</:col>
  <:action :let={record}>
    <.button variant="ghost" size="sm">Edit</.button>
  </:action>
</.table>
```

### Table Component Implementation

```elixir
# In lib/ohmyword_web/components/core_components.ex
attr :size, :string, default: "md", values: ~w(xs sm md lg)
attr :zebra, :boolean, default: true
attr :pin_rows, :boolean, default: false
attr :pin_cols, :boolean, default: false

# Renders as:
<table class="table table-{size} table-zebra table-pin-rows table-pin-cols">
  <!-- Only includes classes where attributes are true or size != "md" -->
</table>
```

---

## Complete Theme Color Reference

All component colors are defined in `/Users/mfelbapov/Projects/ohmyword/assets/css/app.css` using the `@theme` directive for Tailwind CSS v4.

### Base/Background Colors

These colors form the foundation of the UI and don't typically have variant classes:

| Variable | Light Theme | Dark Theme | Usage |
|----------|-------------|------------|-------|
| `--color-base-100` | `oklch(98% 0 0)` | `oklch(30.33% 0.016 252.42)` | Main background |
| `--color-base-200` | `oklch(96% 0.001 286.375)` | `oklch(25.26% 0.014 253.1)` | Secondary background |
| `--color-base-300` | `oklch(92% 0.004 286.32)` | `oklch(20.15% 0.012 254.09)` | Borders, dividers |
| `--color-base-content` | `oklch(21% 0.006 285.885)` | `oklch(97.807% 0.029 256.847)` | Primary text color |

### Complete Variant Colors

All semantic color variants used across Button, Flash, and Input components:

| Variant | Light Theme | Dark Theme | Light Description | Dark Description |
|---------|-------------|------------|-------------------|------------------|
| **primary** | `oklch(70% 0.213 47.604)` | `oklch(58% 0.233 277.117)` | Phoenix orange | Elixir purple |
| **secondary** | `oklch(55% 0.027 264.364)` | `oklch(58% 0.233 277.117)` | Purple/blue | Elixir purple |
| **accent** | `oklch(0% 0 0)` | `oklch(60% 0.25 292.717)` | Black | Pink/magenta |
| **neutral** | `oklch(44% 0.017 285.786)` | `oklch(37% 0.044 257.287)` | Dark gray | Dark blue-gray |
| **info** | `oklch(62% 0.214 259.815)` | `oklch(58% 0.158 241.966)` | Bright blue | Medium blue |
| **success** | `oklch(70% 0.14 182.503)` | `oklch(60% 0.118 184.704)` | Bright green | Medium green |
| **warning** | `oklch(66% 0.179 58.318)` | `oklch(66% 0.179 58.318)` | Yellow/amber | Yellow/amber |
| **error** | `oklch(58% 0.253 17.585)` | `oklch(58% 0.253 17.585)` | Red | Red |

### Design System Summary

**Components with Full Variant Support**:
- ✅ **Button**: All 9 semantic variants + neutral + sizes + modifiers
- ✅ **Flash/Alert**: 4 semantic variants (info, success, warning, error)
- ✅ **Input/Select/Textarea**: All 9 variants (including bordered/ghost) + sizes

**Components with Size/Modifier Support**:
- ✅ **Table**: 4 sizes + 3 modifiers (zebra, pin-rows, pin-cols)

**Theme Toggle**:
- ✅ Three-way toggle: System / Light / Dark
- ✅ Persists preference in localStorage
- ✅ Automatic theme switching based on `data-theme` attribute

**Color Philosophy**:
- Light theme emphasizes **Phoenix Framework** (orange primary)
- Dark theme emphasizes **Elixir** (purple primary)
- Semantic colors (info/success/warning/error) maintain web standards
- All colors use OKLCH for perceptual uniformity and wide color gamut
- Automatic content (text) colors ensure WCAG contrast compliance
