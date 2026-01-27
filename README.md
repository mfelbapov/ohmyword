# Boiler

**Boiler** is a production-ready Phoenix starter kit designed to jumpstart your Elixir development. It comes pre-configured with authentication, an admin interface, and modern frontend tooling.

## Features

- **Phoenix 1.8+** & **Elixir 1.15+**
- **Tailwind CSS 4.x** (via esbuild)
- **Authentication**: Custom scope-based auth with email confirmation & "remember me"
- **Admin Interface**: [Kaffy](https://github.com/aesmail/kaffy) integrated
- **Filtering/Sorting**: [Flop](https://github.com/flop-elixir/flop) integrated
- **Deployment Ready**: Dockerfile & `fly.toml` included
- **AI Ready**: OpenAI client configured

## Getting Started

### Using as a Template

1.  **Clone & Rename**:
    Use the included workflow script to rename the project to your desired application name.
    
    ```bash
    ./docs/scripts/rename_project.sh my_app_name MyAppModule
    ```

    See `.agent/workflows/start_new_project.md` for a standardized workflow.

2.  **Setup**:
    ```bash
    mix setup
    ```

3.  **Run**:
    ```bash
    mix phx.server
    ```

## Documentation

- **[CLAUDE.md](CLAUDE.md)**: detailed architectural overview and command reference.
- **[Post-Rename Guide](docs/guides/post_rename_setup.md)**: steps for Git reset and deployment.
