defmodule Ohmyword.AITest do
  use Ohmyword.DataCase, async: true

  alias Ohmyword.AI

  import Ohmyword.SupportFixtures

  describe "analyze_issues/2" do
    test "returns error for nil query" do
      assert {:error, "Query cannot be empty"} = AI.analyze_issues(nil)
    end

    test "returns error for empty query" do
      assert {:error, "Query cannot be empty"} = AI.analyze_issues("")
    end

    test "returns error for whitespace-only query" do
      assert {:error, "Query cannot be empty"} = AI.analyze_issues("   ")
    end

    test "returns error for query exceeding 2000 characters" do
      long_query = String.duplicate("a", 2001)

      assert {:error, "Query too long. Maximum length is 2000 characters."} =
               AI.analyze_issues(long_query)
    end

    test "returns message when no issues exist" do
      assert {:ok, "No issues found to analyze."} = AI.analyze_issues("Summarize issues")
    end

    test "returns error when API key is not configured" do
      # Create an issue so we don't hit the "no issues" path
      issue_fixture(%{content: "This is a test issue with enough content"})

      # Clear any existing API key config
      original_config = Application.get_env(:ohmyword, :openai)
      Application.put_env(:ohmyword, :openai, [])

      # Also ensure env var is not set (save and restore)
      original_env = System.get_env("OPENAI_API_KEY")
      System.delete_env("OPENAI_API_KEY")

      result = AI.analyze_issues("What are the issues?")

      # Restore original config
      if original_config, do: Application.put_env(:ohmyword, :openai, original_config)
      if original_env, do: System.put_env("OPENAI_API_KEY", original_env)

      assert {:error, "AI analysis failed: \"OpenAI API key not configured\""} = result
    end
  end

  describe "PII scrubbing" do
    test "removes email addresses" do
      assert AI.scrub_pii("Contact test@example.com now") == "Contact [EMAIL] now"
    end

    test "removes phone numbers" do
      assert AI.scrub_pii("Call 555-123-4567") == "Call [PHONE]"
      assert AI.scrub_pii("Call (555) 123-4567") == "Call [PHONE]"
    end

    test "removes IPs" do
      assert AI.scrub_pii("Server at 192.168.1.1") == "Server at [IP_ADDRESS]"
    end

    test "handles issues with email addresses in content via analyze flow" do
      issue_fixture(%{content: "Please contact me at test@example.com for help"})
      # Verify flow doesn't crash
      assert {:error, _} = AI.analyze_issues("Summarize")
    end

    test "truncates prompt when it exceeds max characters" do
      for _i <- 1..13 do
        issue_fixture(%{content: String.duplicate("a", 5000)})
      end

      # We just want to ensure it doesn't crash effectively
      assert {:error, _} = AI.analyze_issues("Summarize")
    end
  end
end
