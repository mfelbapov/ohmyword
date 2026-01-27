# Optimizing AI in Your Developer Workflow: MCP & Agents

This document explains how **you** (the developer) can use MCP Servers and Agents to build features faster, using the `issue_reporting_ai.md` feature as our example.

## 1. Using MCP Servers (Giving the AI "Senses")

**The Problem:**
Normally, when you ask an AI to write code, it is "blind." It doesn't know your database schema, it can't see your terminal errors, and it doesn't know what libraries you have installed unless you copy-paste that information.

**The Solution (MCP):**
You run MCP servers locally to give the AI direct access to your development environment.

### Example: Building the `issues` table
You are implementing the database schema from `issue_reporting_ai.md`.

*   **Without MCP (The Old Way):**
    1.  You copy your `users` migration file.
    2.  You paste it into the chat: "Here is my users table. Write a migration for issues that references it."
    3.  The AI guesses the types.
    4.  You copy the code back and run `mix ecto.migrate`.

*   **With MCP (The Optimal Way):**
    1.  You have a **Postgres MCP Server** running and connected to your local dev database.
    2.  You simply say: *"Write a migration for the `issues` table. It needs to reference the existing `users` table."*
    3.  **What happens:** The AI uses the MCP server to *inspect* your actual running database. It sees that `users.id` is a `uuid`. It sees you are using `utc_datetime`.
    4.  **Result:** It generates a perfect migration using `references(:users, type: :binary_id)` without you ever pasting context.

**Key Takeaway:** Use MCP servers to **eliminate context copying**. Connect your Database, GitHub, and Terminal so the AI has the same "context" you do.

## 2. Using Agents (Giving the AI "Hands")

**The Problem:**
Standard AI is "chat-only." It gives you a snippet, and you have to implement it, run it, debug it, and come back.

**The Solution (Agents):**
You use an Agent to **offload the loop** of coding and testing.

### Example: Implementing the "Admin View" LiveView
You need to build the `BoilerWeb.Admin.IssueInsightsLive` page.

*   **Without Agents (The Old Way):**
    1.  You ask: "Generate the LiveView code."
    2.  AI generates code. You paste it.
    3.  You run the server. It crashes because of a missing alias.
    4.  You paste the error back to the AI.
    5.  AI fixes it. You paste it again.

*   **With Agents (The Optimal Way):**
    1.  You treat the AI as a **Junior Developer**.
    2.  You say: *"Create the `IssueInsightsLive` module based on the spec. Ensure it compiles and the route is accessible."*
    3.  **The Agent Loop:**
        *   **Action:** Creates the file `issue_insights_live.ex`.
        *   **Action:** Edits `router.ex` to add the route.
        *   **Action:** Runs `mix compile` (via Terminal MCP).
        *   **Observation:** Sees a compilation error: `module Flop is not available`.
        *   **Action:** Adds `{:flop, ...}` to `mix.exs` and runs `mix deps.get`.
        *   **Action:** Compiles again. Success.
    4.  **Result:** The Agent reports: "I've created the page and verified it compiles. You can see it at /admin/issues."

**Key Takeaway:** Use Agents to **delegate complete tasks**. Instead of asking for code snippets, ask for *outcomes* (e.g., "Make the tests pass," "Refactor this module").

## 3. "Training" and Specializing Agents

**Can I train agents?**
You generally do not "train" agents (in the machine learning sense of updating weights) for day-to-day development. Instead, you **configure** them using **Context** and **System Prompts**.

**Should I create specialized agents (e.g., "Styling Agent", "LiveView Agent")?**
You *can*, but it is often better to have **One Smart Agent** that you give **Specific Instructions** (Playbooks) to.

### The "Playbook" Approach (Recommended)
Instead of creating a separate "bot" for styling, you create a **Style Guide** file (e.g., `docs/guides/style_guide.md`).

*   **Scenario:** You want to style the Admin Dashboard.
*   **Bad Approach:** "Hey StylingBot, make this look good." (The bot guesses what "good" means).
*   **Good Approach:** "Read `docs/guides/style_guide.md` and apply our design system to the Admin Dashboard."

By documenting your preferences in markdown files, you "train" the agent on *your* specific stack and preferences.

### When to use Specialized Agents
Specialized agents are useful when the **tools** differ significantly.
*   **Dev Agent:** Has access to Terminal, Filesystem, Postgres. (Focus: Coding, Debugging).
*   **QA Agent:** Has access to Browser Testing tools, Cypress/Playwright. (Focus: Clicking buttons, finding bugs).
*   **Deployment Agent:** Has access to AWS/Fly.io CLI, GitHub Actions. (Focus: Infrastructure).

## Summary Checklist for Your Workflow

1.  **Setup Phase (MCP):**
    *   [ ] Connect **Postgres MCP** (so AI knows your schema).
    *   [ ] Connect **Filesystem MCP** (so AI can read/write files).
    *   [ ] Connect **Terminal MCP** (so AI can run mix commands/tests).

2.  **Execution Phase (Agents):**
    *   [ ] **Don't** ask: "How do I write this function?"
    *   [ ] **Do** ask: "Read `docs/feature/issue_reporting_ai.md` and scaffold the database migration and schema. Run the migration and verify it works."

3.  **"Training" Phase (Documentation):**
    *   [ ] Create `docs/guides/frontend_rules.md` (Your "Frontend Agent" brain).
    *   [ ] Create `docs/guides/testing_rules.md` (Your "QA Agent" brain).
    *   [ ] **Instruction:** Always tell the agent to read the relevant guide before starting a task.
