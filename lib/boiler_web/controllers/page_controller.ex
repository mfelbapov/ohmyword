defmodule BoilerWeb.PageController do
  use BoilerWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
