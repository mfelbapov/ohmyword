---
description: Start a new project using this boilerplate
---

# Start a New Project

This workflow guides you through cloning the boilerplate, renaming it, and setting it up for development.

## 1. Clone the boilerplate
Clone the repository to a new directory with your desired project name.
Replace `new_project_name` with your desired directory name.

```bash
git clone https://github.com/your-repo/boiler.git new_project_name
cd new_project_name
```

## 2. Rename the project
// turbo
Run the rename script to replace 'boiler' with your new application name.
Usage: `./docs/scripts/rename_project.sh <app_name_snake_case> <AppModuleCamelCase>`

```bash
# Example: ./docs/scripts/rename_project.sh my_app MyApp
./docs/scripts/rename_project.sh new_app_name NewAppModule
```

## 3. Reset Git History (Optional but Recommended)
If you want a fresh start without the boilerplate's commit history:

```bash
rm -rf .git
git init
git add .
git commit -m "Initial commit from boilerplate"
```

## 4. Setup Dependencies and Resources
Install dependencies, setup the database, and build assets.

```bash
mix setup
```

## 5. Verify Installation
Run the tests to make sure everything is working correctly.

```bash
mix test
```

## 6. Start the Server
Start the Phoenix server to confirm the app is running.

```bash
mix phx.server
```
