defmodule Boiler.Policy do
  use LetMe.Policy, check_module: Boiler.Policy.Checks

  def get_object_name(%Boiler.Accounts.User{}), do: :user
  def get_object_name(:user), do: :user
  def get_object_name(_other), do: nil

  def authorize_action?(action, actor, object) do
    object_name = get_object_name(object)
    rule_name = :"#{object_name}_#{action}"
    authorize?(rule_name, actor, object)
  end

  object :user do
    action :view_admin_dashboard do
      allow({:role_is, [:admin]})
    end
  end
end
