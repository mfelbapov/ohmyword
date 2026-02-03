# Feature Specification: Issue Reporting & AI Summarization

## 1. Overview
This feature allows authenticated users to submit feedback or report issues. Administrators can then use an AI-powered interface to analyze these submissions, asking for summaries, common trends, or specific insights.

## 2. User Stories

### Standard User (Logged In)
- **Access**: Can access a "Leave Feedback" or "Report Issue" page/modal.
- **Action**: Enters text content describing their issue or feedback.
- **Feedback**: Receives confirmation that the issue has been submitted.
- **Restrictions**: Must be logged in.

### Admin User
- **Access**: Can access a dedicated "Issue Insights" dashboard (protected by admin role).
- **Action**:
    - View a list of recent issues (optional, but good for context).
    - Interact with an AI Assistant interface.
    - **Example Prompts**:
        - "Summarize the issues from the last 24 hours."
        - "What is the most common complaint regarding the login flow?"
        - "Are there any critical bugs reported recently?"
- **Feedback**: Receives a text response from the AI based on the database of user issues.

## 3. Technical Architecture

### Database Schema
**Table**: `issues` (or `feedback`)
- `id`: UUID
- `user_id`: References `users.id`
- `content`: Text (The user's message)
- `inserted_at`: Timestamp
- `status`: Enum (e.g., `new`, `reviewed`, `archived`) - *Optional for V1*

### Frontend (Phoenix LiveView)
1.  **User View**: `OhmywordWeb.IssueLive.New`
    - Simple form with a text area.
    - Real-time validation (min length).
2.  **Admin View**: `OhmywordWeb.Admin.IssueInsightsLive`
    - **Chat Interface**: A chat-like UI where the admin types a prompt.
    - **Context Loading**: The backend fetches relevant (or recent) issues from the database to construct the prompt context for the LLM.

### AI Integration
- **Service Module**: `Ohmyword.AI` context.
- **Provider**: OpenAI (GPT-4o/GPT-3.5), Anthropic (Claude), or Gemini.
- **Mechanism**:
    - When Admin asks a question, the system retrieves the last $N$ issues (or issues within a timeframe).
    - Constructs a system prompt: "You are a helpful assistant analyzing user feedback. Here is the data: [List of issues]. Answer the user's question: [Admin Query]"
    - Returns the LLM response to the LiveView.

## 4. Configuration & Assumptions
1.  **AI Provider**: OpenAI (GPT-4o or similar). API Key management via `runtime.exs`.
2.  **Context Strategy**: "Recent History" approach. We will send the last 50 issues to the LLM for summarization. RAG can be added later if volume increases.
3.  **Privacy**: Basic PII scrubbing (emails/phones) recommended before sending to AI.
4.  **UI Location**:
    -   **User**: Standalone page `/issues/new` (simplest for V1).
    -   **Admin**: Dashboard page `/admin/issues`.

## 5. Architectural Decisions: Library Selection
To ensure a robust, maintainable, and scalable implementation, the following libraries have been selected:

### AI & LLM Integration: `openai`
- **Decision**: Adopt the `openai` community wrapper.
- **Rationale**: While direct HTTP calls via `req` are possible, utilizing a dedicated wrapper provides standardized error handling, type safety for configuration, and simplified streaming capabilities. This abstraction layer decouples our business logic from the raw API details, facilitating easier updates or provider switches in the future.

### Data Management & Presentation: `flop` + `flop_phoenix`
- **Decision**: Integrate `flop` for query composition and `flop_phoenix` for UI components.
- **Rationale**: As the volume of reported issues grows, efficient data retrieval becomes critical. `flop` provides a declarative way to handle filtering, sorting, and pagination at the Ecto level without ohmywordplate. `flop_phoenix` complements this by offering pre-built, accessible LiveView components for data tables, ensuring a consistent and high-quality admin experience with minimal custom frontend code.
