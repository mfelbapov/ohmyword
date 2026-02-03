#!/bin/bash
#
# rename_project.sh - Rename this Phoenix boilerplate to your project name
#
# Usage:
#   1. Use GitHub "Use this template" to create your new repo (e.g., "my_cool_app")
#   2. Clone your new repo locally
#   3. cd into the project directory
#   4. Run: ./docs/scripts/rename_project.sh
#
# The script will:
#   - Detect your project name from the directory name
#   - Rename all Boiler/boiler references to YourApp/your_app
#   - Clean up build artifacts
#   - Delete itself when done
#!/bin/bash
#
# rename_project.sh - Rename this Phoenix boilerplate to your project name
#
# Usage:
#   1. Use GitHub "Use this template" to create your new repo (e.g., "my_cool_app")
#   2. Clone your new repo locally
#   3. cd into the project directory
#   4. Run: ./docs/scripts/rename_project.sh
#
# The script will:
#   - Detect your project name from the directory name
#   - Rename all Boiler/boiler references to YourApp/your_app
#   - Clean up build artifacts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

# Convert snake_case to PascalCase: my_cool_app -> MyCoolApp
to_pascal_case() {
  local input="$1"
  local result=""
  local capitalize_next=true

  for (( i=0; i<${#input}; i++ )); do
    char="${input:$i:1}"
    if [[ "$char" == "_" ]]; then
      capitalize_next=true
    elif [[ "$capitalize_next" == true ]]; then
      # Uppercase the character
      result+=$(echo "$char" | tr '[:lower:]' '[:upper:]')
      capitalize_next=false
    else
      result+="$char"
    fi
  done

  echo "$result"
}

# Convert snake_case to kebab-case: my_cool_app -> my-cool-app
to_kebab_case() {
  echo "$1" | tr '_' '-'
}

# Check if string is valid snake_case
is_valid_snake_case() {
  [[ "$1" =~ ^[a-z][a-z0-9]*(_[a-z0-9]+)*$ ]]
}

# Print error and exit
error() {
  echo -e "${RED}Error: $1${NC}" >&2
  exit 1
}

# Print warning
warn() {
  echo -e "${YELLOW}Warning: $1${NC}"
}

# Print success
success() {
  echo -e "${GREEN}$1${NC}"
}

#------------------------------------------------------------------------------
# Validation
#------------------------------------------------------------------------------

# Ensure we're in the project root
if [ ! -f "mix.exs" ]; then
  error "Please run this script from the project root directory (where mix.exs is located)."
fi

# Get the new name from the directory
NEW_NAME=$(basename "$(pwd)")

# Detect current names from mix.exs
CURRENT_MODULE=$(grep 'defmodule' mix.exs | head -n 1 | sed -e 's/defmodule //' -e 's/\.MixProject do//' | tr -d ' ')
CURRENT_NAME=$(grep 'app:' mix.exs | head -n 1 | sed -e 's/.*app: ://' -e 's/,.*//' | tr -d ' ')

if [ -z "$CURRENT_MODULE" ] || [ -z "$CURRENT_NAME" ]; then
  error "Could not detect current app/module name from mix.exs."
fi

# Check if already renamed (nothing to do)
if [ "$NEW_NAME" == "$CURRENT_NAME" ]; then
  error "Directory name '$NEW_NAME' matches current app name. Nothing to rename.

If you just cloned this boilerplate, rename your directory first:
  cd ..
  mv $CURRENT_NAME my_new_app
  cd my_new_app
  ./docs/scripts/rename_project.sh"
fi

# Validate snake_case
if ! is_valid_snake_case "$NEW_NAME"; then
  error "Directory name '$NEW_NAME' is not valid snake_case.

Valid examples: my_app, cool_project, phoenix_app
Invalid: MyApp, my-app, 123app, my__app

Rename your directory to a valid snake_case name and try again."
fi

# Generate module name and kebab-case
NEW_MODULE=$(to_pascal_case "$NEW_NAME")
NEW_KEBAB=$(to_kebab_case "$NEW_NAME")
CURRENT_KEBAB=$(to_kebab_case "$CURRENT_NAME")

echo "=============================================="
echo "  Phoenix Boilerplate Renamer"
echo "=============================================="
echo ""
echo "  Detected current project: $CURRENT_NAME ($CURRENT_MODULE)"
echo ""
echo "  Renaming to:"
echo "    App name:    $CURRENT_NAME -> $NEW_NAME"
echo "    Module name: $CURRENT_MODULE -> $NEW_MODULE"
echo "    Fly.io name: $CURRENT_KEBAB-production -> $NEW_KEBAB-production"
echo ""

#------------------------------------------------------------------------------
# OS Detection for sed compatibility
#------------------------------------------------------------------------------

OS="$(uname)"
if [ "$OS" == "Darwin" ]; then
  SED_OPTS=(-i '')
  # Fix for macOS sed "illegal byte sequence" error with UTF-8 files
  export LC_ALL=C
  export LANG=C
else
  SED_OPTS=(-i)
fi

#------------------------------------------------------------------------------
# Get version from mix.exs for fly.toml static path
#------------------------------------------------------------------------------

VERSION=$(grep 'version:' mix.exs | head -1 | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')
if [ -z "$VERSION" ]; then
  VERSION="0.1.0"
  warn "Could not extract version from mix.exs, using default: $VERSION"
fi

#------------------------------------------------------------------------------
# Step 1: Cleanup build artifacts first
#------------------------------------------------------------------------------

echo "Step 1/5: Cleaning build artifacts..."

if [ -d "_build" ]; then
  rm -rf _build
  echo "  Removed _build/"
fi

if [ -d "deps" ]; then
  rm -rf deps
  echo "  Removed deps/"
fi

success "  Cleanup complete."

#------------------------------------------------------------------------------
# Step 2: Replace content in files
#------------------------------------------------------------------------------

echo "Step 2/5: Replacing text in files..."

# Replace Module Name first (Boiler -> NewModule)
find . -type f \
  -not -path "./.git/*" \
  -not -path "./_build/*" \
  -not -path "./deps/*" \
  -not -path "./.elixir_ls/*" \
  -not -path "./docs/scripts/rename_project.sh" \
  -exec grep -I -q "$CURRENT_MODULE" {} \; \
  -print0 | xargs -0 sed "${SED_OPTS[@]}" "s/$CURRENT_MODULE/$NEW_MODULE/g"

# Replace App Name (boiler -> new_name)
find . -type f \
  -not -path "./.git/*" \
  -not -path "./_build/*" \
  -not -path "./deps/*" \
  -not -path "./.elixir_ls/*" \
  -not -path "./docs/scripts/rename_project.sh" \
  -exec grep -I -q "$CURRENT_NAME" {} \; \
  -print0 | xargs -0 sed "${SED_OPTS[@]}" "s/$CURRENT_NAME/$NEW_NAME/g"

success "  Text replacement complete."

#------------------------------------------------------------------------------
# Step 3: Fix fly.toml with kebab-case and correct version
#------------------------------------------------------------------------------

echo "Step 3/5: Updating fly.toml..."

if [ -f "fly.toml" ]; then
  # Fix app name to use kebab-case (my_app-production -> my-app-production)
  sed "${SED_OPTS[@]}" "s/${NEW_NAME}-production/${NEW_KEBAB}-production/g" fly.toml

  # Fix PHX_HOST to use kebab-case
  sed "${SED_OPTS[@]}" "s/${NEW_NAME}\.fly\.dev/${NEW_KEBAB}-production.fly.dev/g" fly.toml
  sed "${SED_OPTS[@]}" "s/${NEW_NAME}-production\.fly\.dev/${NEW_KEBAB}-production.fly.dev/g" fly.toml

  # Update the static path with correct version
  sed "${SED_OPTS[@]}" "s|/app/lib/${NEW_NAME}-[0-9.]*|/app/lib/${NEW_NAME}-${VERSION}|g" fly.toml

  success "  fly.toml updated."
else
  warn "  fly.toml not found, skipping."
fi

#------------------------------------------------------------------------------
# Step 4: Rename files
#------------------------------------------------------------------------------

echo "Step 4/5: Renaming files..."

find . -type f -name "*${CURRENT_NAME}*" \
  -not -path "./.git/*" \
  -not -path "./_build/*" \
  -not -path "./deps/*" \
  -not -path "./.elixir_ls/*" \
  -not -path "./docs/scripts/rename_project.sh" -print0 | while IFS= read -r -d '' file; do
  # Only replace in basename, not the full path (parent dirs aren't renamed yet)
  dir=$(dirname "$file")
  base=$(basename "$file")
  new_base=$(echo "$base" | sed "s/$CURRENT_NAME/$NEW_NAME/g")
  new_file="$dir/$new_base"
  if [ "$file" != "$new_file" ]; then
    echo "  $file -> $new_file"
    mv "$file" "$new_file"
  fi
done

success "  Files renamed."

#------------------------------------------------------------------------------
# Step 5: Rename directories (deepest first)
#------------------------------------------------------------------------------

echo "Step 5/5: Renaming directories..."

find . -type d -name "*${CURRENT_NAME}*" \
  -not -path "./.git/*" \
  -not -path "./_build/*" \
  -not -path "./deps/*" \
  -not -path "./.elixir_ls/*" | sort -r | while read -r dir; do
  # Only replace in basename, not the full path (avoids issues with nested dirs)
  parent=$(dirname "$dir")
  base=$(basename "$dir")
  new_base=$(echo "$base" | sed "s/$CURRENT_NAME/$NEW_NAME/g")
  new_dir="$parent/$new_base"
  if [ "$dir" != "$new_dir" ]; then
    echo "  $dir -> $new_dir"
    mv "$dir" "$new_dir"
  fi
done

success "  Directories renamed."

#------------------------------------------------------------------------------
# Done!
#------------------------------------------------------------------------------

echo ""
echo "=============================================="
success "  Rename complete!"
echo "=============================================="
echo ""
echo "  Your project is now: $NEW_NAME ($NEW_MODULE)"
echo ""
echo "  Next steps:"
echo "    1. mix setup          # Install deps, create DB, build assets"
echo "    2. mix test           # Verify everything works (should pass ~198 tests)"
echo "    3. mix phx.server     # Start the server"
echo ""
echo "  For Fly.io deployment:"
echo "    - Run 'fly launch' to create your app (or update fly.toml manually)"
echo "    - The app name will be: $NEW_KEBAB-production"
echo ""

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

# Convert snake_case to PascalCase: my_cool_app -> MyCoolApp
to_pascal_case() {
  local input="$1"
  local result=""
  local capitalize_next=true

  for (( i=0; i<${#input}; i++ )); do
    char="${input:$i:1}"
    if [[ "$char" == "_" ]]; then
      capitalize_next=true
    elif [[ "$capitalize_next" == true ]]; then
      # Uppercase the character
      result+=$(echo "$char" | tr '[:lower:]' '[:upper:]')
      capitalize_next=false
    else
      result+="$char"
    fi
  done

  echo "$result"
}

# Convert snake_case to kebab-case: my_cool_app -> my-cool-app
to_kebab_case() {
  echo "$1" | tr '_' '-'
}

# Check if string is valid snake_case
is_valid_snake_case() {
  [[ "$1" =~ ^[a-z][a-z0-9]*(_[a-z0-9]+)*$ ]]
}

# Print error and exit
error() {
  echo -e "${RED}Error: $1${NC}" >&2
  exit 1
}

# Print warning
warn() {
  echo -e "${YELLOW}Warning: $1${NC}"
}

# Print success
success() {
  echo -e "${GREEN}$1${NC}"
}

#------------------------------------------------------------------------------
# Validation
#------------------------------------------------------------------------------

# Ensure we're in the project root
if [ ! -f "mix.exs" ]; then
  error "Please run this script from the project root directory (where mix.exs is located)."
fi

# Get the new name from the directory
NEW_NAME=$(basename "$(pwd)")

# Detect current names from mix.exs
CURRENT_MODULE=$(grep 'defmodule' mix.exs | head -n 1 | sed -e 's/defmodule //' -e 's/\.MixProject do//' | tr -d ' ')
CURRENT_NAME=$(grep 'app:' mix.exs | head -n 1 | sed -e 's/.*app: ://' -e 's/,.*//' | tr -d ' ')

if [ -z "$CURRENT_MODULE" ] || [ -z "$CURRENT_NAME" ]; then
  error "Could not detect current app/module name from mix.exs."
fi

# Check if already renamed (nothing to do)
if [ "$NEW_NAME" == "$CURRENT_NAME" ]; then
  error "Directory name '$NEW_NAME' matches current app name. Nothing to rename.

If you just cloned this boilerplate, rename your directory first:
  cd ..
  mv $CURRENT_NAME my_new_app
  cd my_new_app
  ./docs/scripts/rename_project.sh"
fi

# Validate snake_case
if ! is_valid_snake_case "$NEW_NAME"; then
  error "Directory name '$NEW_NAME' is not valid snake_case.

Valid examples: my_app, cool_project, phoenix_app
Invalid: MyApp, my-app, 123app, my__app

Rename your directory to a valid snake_case name and try again."
fi

# Generate module name and kebab-case
NEW_MODULE=$(to_pascal_case "$NEW_NAME")
NEW_KEBAB=$(to_kebab_case "$NEW_NAME")
CURRENT_KEBAB=$(to_kebab_case "$CURRENT_NAME")

echo "=============================================="
echo "  Phoenix Boilerplate Renamer"
echo "=============================================="
echo ""
echo "  Detected current project: $CURRENT_NAME ($CURRENT_MODULE)"
echo ""
echo "  Renaming to:"
echo "    App name:    $CURRENT_NAME -> $NEW_NAME"
echo "    Module name: $CURRENT_MODULE -> $NEW_MODULE"
echo "    Fly.io name: $CURRENT_KEBAB-production -> $NEW_KEBAB-production"
echo ""

#------------------------------------------------------------------------------
# OS Detection for sed compatibility
#------------------------------------------------------------------------------

OS="$(uname)"
if [ "$OS" == "Darwin" ]; then
  SED_OPTS=(-i '')
else
  SED_OPTS=(-i)
fi

#------------------------------------------------------------------------------
# Get version from mix.exs for fly.toml static path
#------------------------------------------------------------------------------

VERSION=$(grep 'version:' mix.exs | head -1 | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')
if [ -z "$VERSION" ]; then
  VERSION="0.1.0"
  warn "Could not extract version from mix.exs, using default: $VERSION"
fi

#------------------------------------------------------------------------------
# Step 1: Cleanup build artifacts first
#------------------------------------------------------------------------------

echo "Step 1/5: Cleaning build artifacts..."

if [ -d "_build" ]; then
  rm -rf _build
  echo "  Removed _build/"
fi

if [ -d "deps" ]; then
  rm -rf deps
  echo "  Removed deps/"
fi

success "  Cleanup complete."

#------------------------------------------------------------------------------
# Step 2: Replace content in files
#------------------------------------------------------------------------------

echo "Step 2/5: Replacing text in files..."

# Replace Module Name first (Boiler -> NewModule)
find . -type f \
  -not -path "./.git/*" \
  -not -path "./_build/*" \
  -not -path "./deps/*" \
  -not -path "./.elixir_ls/*" \
  -not -path "./docs/scripts/rename_project.sh" \
  -exec grep -I -q "$CURRENT_MODULE" {} \; \
  -print0 | xargs -0 sed "${SED_OPTS[@]}" "s/$CURRENT_MODULE/$NEW_MODULE/g"

# Replace App Name (boiler -> new_name)
find . -type f \
  -not -path "./.git/*" \
  -not -path "./_build/*" \
  -not -path "./deps/*" \
  -not -path "./.elixir_ls/*" \
  -not -path "./docs/scripts/rename_project.sh" \
  -exec grep -I -q "$CURRENT_NAME" {} \; \
  -print0 | xargs -0 sed "${SED_OPTS[@]}" "s/$CURRENT_NAME/$NEW_NAME/g"

success "  Text replacement complete."

#------------------------------------------------------------------------------
# Step 3: Fix fly.toml with kebab-case and correct version
#------------------------------------------------------------------------------

echo "Step 3/5: Updating fly.toml..."

if [ -f "fly.toml" ]; then
  # Fix app name to use kebab-case (my_app-production -> my-app-production)
  sed "${SED_OPTS[@]}" "s/${NEW_NAME}-production/${NEW_KEBAB}-production/g" fly.toml

  # Fix PHX_HOST to use kebab-case
  sed "${SED_OPTS[@]}" "s/${NEW_NAME}\.fly\.dev/${NEW_KEBAB}-production.fly.dev/g" fly.toml
  sed "${SED_OPTS[@]}" "s/${NEW_NAME}-production\.fly\.dev/${NEW_KEBAB}-production.fly.dev/g" fly.toml

  # Update the static path with correct version
  sed "${SED_OPTS[@]}" "s|/app/lib/${NEW_NAME}-[0-9.]*|/app/lib/${NEW_NAME}-${VERSION}|g" fly.toml

  success "  fly.toml updated."
else
  warn "  fly.toml not found, skipping."
fi

#------------------------------------------------------------------------------
# Step 4: Rename files
#------------------------------------------------------------------------------

echo "Step 4/5: Renaming files..."

find . -type f -name "*${CURRENT_NAME}*" \
  -not -path "./.git/*" \
  -not -path "./_build/*" \
  -not -path "./deps/*" \
  -not -path "./.elixir_ls/*" \
  -not -path "./docs/scripts/rename_project.sh" -print0 | while IFS= read -r -d '' file; do
  # Only replace in basename, not the full path (parent dirs aren't renamed yet)
  dir=$(dirname "$file")
  base=$(basename "$file")
  new_base=$(echo "$base" | sed "s/$CURRENT_NAME/$NEW_NAME/g")
  new_file="$dir/$new_base"
  if [ "$file" != "$new_file" ]; then
    echo "  $file -> $new_file"
    mv "$file" "$new_file"
  fi
done

success "  Files renamed."

#------------------------------------------------------------------------------
# Step 5: Rename directories (deepest first)
#------------------------------------------------------------------------------

echo "Step 5/5: Renaming directories..."

find . -type d -name "*${CURRENT_NAME}*" \
  -not -path "./.git/*" \
  -not -path "./_build/*" \
  -not -path "./deps/*" \
  -not -path "./.elixir_ls/*" | sort -r | while read -r dir; do
  # Only replace in basename, not the full path (avoids issues with nested dirs)
  parent=$(dirname "$dir")
  base=$(basename "$dir")
  new_base=$(echo "$base" | sed "s/$CURRENT_NAME/$NEW_NAME/g")
  new_dir="$parent/$new_base"
  if [ "$dir" != "$new_dir" ]; then
    echo "  $dir -> $new_dir"
    mv "$dir" "$new_dir"
  fi
done

success "  Directories renamed."

#------------------------------------------------------------------------------
# Done!
#------------------------------------------------------------------------------

echo ""
echo "=============================================="
success "  Rename complete!"
echo "=============================================="
echo ""
echo "  Your project is now: $NEW_NAME ($NEW_MODULE)"
echo ""
echo "  Next steps:"
echo "    1. mix setup          # Install deps, create DB, build assets"
echo "    2. mix test           # Verify everything works (should pass ~198 tests)"
echo "    3. mix phx.server     # Start the server"
echo ""
echo "  For Fly.io deployment:"
echo "    - Run 'fly launch' to create your app (or update fly.toml manually)"
echo "    - The app name will be: $NEW_KEBAB-production"
echo ""

# Self-delete
SCRIPT_PATH="./docs/scripts/rename_project.sh"
if [ -f "$SCRIPT_PATH" ]; then
  rm -- "$SCRIPT_PATH"
  echo "  (This script has been removed)"
fi
echo ""
