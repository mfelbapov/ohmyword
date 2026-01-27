defmodule Boiler.Policy.Checks do
  @moduledoc """
  Authorization checks for Boiler.Policy.
  """

  def role_is(actor, _object, roles) do
    normalized_role = actor.role |> to_string() |> String.downcase()
    normalized_roles = Enum.map(roles, &(&1 |> to_string() |> String.downcase()))
    normalized_role in normalized_roles
  end
end
