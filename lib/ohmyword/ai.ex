defmodule Ohmyword.AI do
  @moduledoc """
  The AI context for analyzing user issues using OpenAI.
  """

  require Logger
  alias Ohmyword.Support

  @doc """
  Analyzes issues using AI based on the user's query.

  ## Options

    * `:limit` - Number of recent issues to include in context (default: 50)

  ## Examples

      iex> analyze_issues("Summarize the recent issues")
      {:ok, "Here is a summary..."}

      iex> analyze_issues("What are common problems?", limit: 100)
      {:ok, "The most common problems are..."}

  """
  def analyze_issues(user_query, opts \\ []) do
    # Validate query length to prevent excessive API costs
    cond do
      is_nil(user_query) or String.trim(user_query) == "" ->
        {:error, "Query cannot be empty"}

      String.length(user_query) > 2000 ->
        {:error, "Query too long. Maximum length is 2000 characters."}

      true ->
        limit = Keyword.get(opts, :limit, 50)
        issues = Support.list_recent_issues(limit)

        if issues == [] do
          {:ok, "No issues found to analyze."}
        else
          system_prompt = build_system_prompt(issues)

          # Max characters approx 16k tokens
          max_chars = 64_000

          if String.length(system_prompt) > max_chars do
            # Simple truncation strategy: reduce number of issues
            # Recursive approach isn't needed if we just slice the list,
            # but to be safe we can just slice the prompt itself or reduce issues.
            # Better: retake fewer issues.

            # safe_count = div(max_chars, 500) # Assumes avg 500 chars/issue to be safe?
            # Or just simple truncation of the text for now as a quick fix,
            # warning: might cut off JSON/structure if we were using it,
            # but here it is just text.

            # Re-building with fewer issues if needed is cleaner but more expensive.
            # Let's just slice existing text for "the user's most critical fix" which is stopping crash.

            truncated_prompt = String.slice(system_prompt, 0, max_chars) <> "\n...[TRUNCATED]"
            query_openai(truncated_prompt, user_query)
          else
            query_openai(system_prompt, user_query)
          end
          |> case do
            {:ok, response} -> {:ok, response}
            {:error, reason} -> {:error, "AI analysis failed: #{inspect(reason)}"}
          end
        end
    end
  end

  # Builds the system prompt with issue data
  defp build_system_prompt(issues) do
    issues_text =
      issues
      |> Enum.map(&format_issue/1)
      |> Enum.join("\n\n")

    """
    You are a helpful assistant analyzing user feedback and issues.

    Here is the data from recent user submissions:

    #{issues_text}

    Please analyze this data and answer the user's question. Be concise and focus on actionable insights.
    """
  end

  # Formats a single issue for the AI context
  defp format_issue(issue) do
    content = scrub_pii(issue.content)
    username = if issue.user, do: issue.user.username, else: "unknown"
    inserted_at = Calendar.strftime(issue.inserted_at, "%Y-%m-%d %H:%M")

    """
    Issue ##{issue.id}
    User: #{username}
    Date: #{inserted_at}
    Status: #{issue.status}
    Content: #{content}
    """
  end

  # Enhanced PII scrubbing - removes various patterns of sensitive information
  @doc "Scrubs PII from text. Public for testing."
  def scrub_pii(text) do
    text
    # Email addresses
    |> String.replace(~r/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/, "[EMAIL]")
    # US phone numbers (various formats)
    |> String.replace(~r/(?<!\w)(?:\+?1[-.]?)?\(?\d{3}\)?[-. ]?\d{3}[-. ]?\d{4}\b/, "[PHONE]")
    # Social Security Numbers (XXX-XX-XXXX)
    |> String.replace(~r/\b\d{3}-\d{2}-\d{4}\b/, "[SSN]")
    # Credit card numbers (various formats, 13-19 digits)
    |> String.replace(~r/\b(?:\d[ -]*?){13,19}\b/, "[CREDIT_CARD]")
    # IPv4 addresses
    |> String.replace(~r/\b(?:\d{1,3}\.){3}\d{1,3}\b/, "[IP_ADDRESS]")
    # IPv6 addresses (simplified pattern)
    |> String.replace(~r/\b(?:[a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}\b/, "[IP_ADDRESS]")
    # API keys (common patterns like sk-..., api_key_..., etc.)
    |> String.replace(~r/\b(?:sk-|pk-|api[_-]?key[_-]?)[a-zA-Z0-9]{20,}\b/i, "[API_KEY]")
    # JWT tokens (simplified pattern)
    |> String.replace(~r/\beyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\b/, "[JWT_TOKEN]")
    # US ZIP codes with optional +4
    |> String.replace(~r/\b\d{5}(?:-\d{4})?\b/, "[ZIP_CODE]")
  end

  # Makes the OpenAI API call
  defp query_openai(system_prompt, user_query) do
    config = Application.get_env(:ohmyword, :openai, [])
    api_key = Keyword.get(config, :api_key) || System.get_env("OPENAI_API_KEY")

    if is_nil(api_key) or api_key == "" do
      {:error, "OpenAI API key not configured"}
    else
      messages = [
        %{role: "system", content: system_prompt},
        %{role: "user", content: user_query}
      ]

      request_body = %{
        model: "gpt-4o-mini",
        messages: messages,
        temperature: 0.7,
        max_tokens: 1000
      }

      case OpenAI.chat_completion(request_body, api_key: api_key) do
        {:ok, %{choices: [%{"message" => %{"content" => content}} | _]}} ->
          {:ok, content}

        {:ok, response} ->
          Logger.warning("OpenAI unexpected response format",
            response: inspect(response, limit: 500)
          )

          {:error, "Unexpected API response format: #{inspect(response)}"}

        {:error, reason} ->
          Logger.error("OpenAI API call failed", reason: inspect(reason, limit: 500))
          {:error, reason}
      end
    end
  end
end
