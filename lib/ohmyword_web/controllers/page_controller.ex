defmodule OhmywordWeb.PageController do
  use OhmywordWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
