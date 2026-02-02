defmodule Ohmyword.PolicyTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Policy
  alias Ohmyword.Accounts.User

  describe "view_admin_dashboard" do
    test "allows admin user" do
      user = %User{role: :admin}
      assert Policy.authorize_action?(:view_admin_dashboard, user, user)
    end

    test "denies non-admin user" do
      user = %User{role: :member}
      refute Policy.authorize_action?(:view_admin_dashboard, user, user)
    end
  end
end
