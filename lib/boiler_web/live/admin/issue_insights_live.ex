defmodule BoilerWeb.Admin.IssueInsightsLive do
  use BoilerWeb, :live_view

  alias Boiler.AI

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl">
        <.header>
          Issue Insights
          <:subtitle>Use AI to analyze user feedback and identify common patterns.</:subtitle>
        </.header>

        <div class="mt-8 space-y-6">
          <%!-- Recent Issues Summary --%>
          <div class="rounded-lg border border-zinc-300 bg-white p-6 dark:border-zinc-700 dark:bg-zinc-900">
            <h3 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              Recent Issues
            </h3>
            <p class="mt-1 text-sm text-zinc-600 dark:text-zinc-400">
              {@issue_count} issues in the database. Recent {@recent_count} will be used for AI analysis.
            </p>
          </div>

          <%!-- AI Query Interface --%>
          <div class="rounded-lg border border-zinc-300 bg-white p-6 dark:border-zinc-700 dark:bg-zinc-900">
            <h3 class="mb-4 text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              Ask AI
            </h3>

            <.form for={@query_form} id="ai-query-form" phx-submit="analyze">
              <div class="flex gap-2">
                <.input
                  field={@query_form[:query]}
                  type="text"
                  placeholder="e.g., 'Summarize recent issues' or 'What are the most common problems?'"
                  class="flex-1"
                  phx-mounted={JS.focus()}
                  required
                />
                <.button variant="primary" phx-disable-with="Analyzing...">
                  <.icon name="hero-sparkles" class="mr-2 h-5 w-5" /> Analyze
                </.button>
              </div>
            </.form>

            <%!-- Suggested Prompts --%>
            <div class="mt-4">
              <p class="mb-2 text-xs font-medium text-zinc-600 dark:text-zinc-400">
                Suggested questions:
              </p>
              <div class="flex flex-wrap gap-2">
                <button
                  :for={
                    prompt <- [
                      "Summarize the issues from the last 24 hours",
                      "What are the most common complaints?",
                      "Are there any critical bugs reported?",
                      "What features are users requesting?"
                    ]
                  }
                  type="button"
                  phx-click="use-prompt"
                  phx-value-prompt={prompt}
                  class="rounded-md bg-zinc-100 px-3 py-1.5 text-xs text-zinc-700 hover:bg-zinc-200 dark:bg-zinc-800 dark:text-zinc-300 dark:hover:bg-zinc-700"
                >
                  {prompt}
                </button>
              </div>
            </div>
          </div>

          <%!-- Loading State --%>
          <div
            :if={@loading}
            class="rounded-lg border border-blue-300 bg-blue-50 p-6 dark:border-blue-700 dark:bg-blue-950"
          >
            <div class="flex items-center">
              <.icon
                name="hero-sparkles"
                class="mr-3 h-6 w-6 animate-pulse text-blue-600 dark:text-blue-400"
              />
              <p class="text-sm text-blue-900 dark:text-blue-100">
                Analyzing issues with AI...
              </p>
            </div>
          </div>

          <%!-- AI Response --%>
          <div
            :if={@ai_response}
            class="rounded-lg border border-green-300 bg-green-50 p-6 dark:border-green-700 dark:bg-green-950"
          >
            <div class="mb-2 flex items-center justify-between">
              <h4 class="font-semibold text-green-900 dark:text-green-100">
                AI Analysis
              </h4>
              <.icon name="hero-check-circle" class="h-5 w-5 text-green-600 dark:text-green-400" />
            </div>
            <div class="prose prose-sm max-w-none dark:prose-invert">
              <p class="whitespace-pre-wrap text-sm text-green-900 dark:text-green-100">
                {@ai_response}
              </p>
            </div>
          </div>

          <%!-- Error State --%>
          <div
            :if={@error}
            class="rounded-lg border border-red-300 bg-red-50 p-6 dark:border-red-700 dark:bg-red-950"
          >
            <div class="flex items-center">
              <.icon
                name="hero-exclamation-circle"
                class="mr-3 h-6 w-6 text-red-600 dark:text-red-400"
              />
              <div>
                <h4 class="font-semibold text-red-900 dark:text-red-100">Error</h4>
                <p class="mt-1 text-sm text-red-700 dark:text-red-200">
                  {@error}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    issue_count = count_all_issues()
    recent_count = min(issue_count, 50)

    {:ok,
     socket
     |> assign(
       issue_count: issue_count,
       recent_count: recent_count,
       query_form: to_form(%{"query" => ""}, as: "query"),
       ai_response: nil,
       error: nil,
       loading: false
     )}
  end

  @impl true
  def handle_event("analyze", %{"query" => %{"query" => query}}, socket) do
    {:noreply,
     socket
     |> assign(loading: true, ai_response: nil, error: nil)
     |> start_async(:ai_analysis, fn -> AI.analyze_issues(query) end)}
  end

  def handle_event("use-prompt", %{"prompt" => prompt}, socket) do
    {:noreply, assign(socket, query_form: to_form(%{"query" => prompt}, as: "query"))}
  end

  @impl true
  def handle_async(:ai_analysis, {:ok, {:ok, response}}, socket) do
    {:noreply,
     socket
     |> assign(loading: false, ai_response: response)
     |> put_flash(:info, "Analysis complete!")}
  end

  def handle_async(:ai_analysis, {:ok, {:error, reason}}, socket) do
    error_message = "Failed to analyze issues: #{reason}"

    {:noreply,
     socket
     |> assign(loading: false, error: error_message)
     |> put_flash(:error, error_message)}
  end

  def handle_async(:ai_analysis, {:exit, reason}, socket) do
    error_message = "AI analysis crashed: #{inspect(reason)}"

    {:noreply,
     socket
     |> assign(loading: false, error: error_message)
     |> put_flash(:error, error_message)}
  end

  defp count_all_issues do
    Boiler.Repo.aggregate(Boiler.Support.Issue, :count, :id)
  end
end
