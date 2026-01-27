defmodule BoilerWeb.AdminDashboardLive do
  use BoilerWeb, :live_view
  import Ecto.Query

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl">
      <.header>
        Admin Dashboard
        <:subtitle>Welcome, {@current_scope.user.username}!</:subtitle>
      </.header>

      <div class="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2">
        <.link
          navigate={~p"/admin/kaffy"}
          class="group relative block rounded-lg border border-zinc-300 bg-white p-6 shadow-sm hover:border-zinc-400 hover:shadow-md dark:border-zinc-700 dark:bg-zinc-900 dark:hover:border-zinc-600"
        >
          <div class="flex items-center">
            <div class="shrink-0">
              <.icon name="hero-cog-6-tooth" class="h-8 w-8 text-zinc-600 dark:text-zinc-400" />
            </div>
            <div class="ml-4">
              <h3 class="text-lg font-medium text-zinc-900 dark:text-zinc-100">
                Kaffy Admin
              </h3>
              <p class="mt-1 text-sm text-zinc-600 dark:text-zinc-400">
                Manage database records, users, and system data
              </p>
            </div>
          </div>
        </.link>

        <div class="group relative block rounded-lg border border-zinc-300 bg-white p-6 shadow-sm dark:border-zinc-700 dark:bg-zinc-900">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <.icon name="hero-chart-bar" class="h-8 w-8 text-zinc-600 dark:text-zinc-400" />
            </div>
            <div class="ml-4">
              <h3 class="text-lg font-medium text-zinc-900 dark:text-zinc-100">
                Analytics
              </h3>
              <p class="mt-1 text-sm text-zinc-600 dark:text-zinc-400">
                Coming soon - View system analytics and reports
              </p>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-8">
        <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">Quick Stats</h2>
        <div class="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-3">
          <div class="rounded-lg border border-zinc-300 bg-white p-4 dark:border-zinc-700 dark:bg-zinc-900">
            <p class="text-sm text-zinc-600 dark:text-zinc-400">Total Users</p>
            <p class="mt-1 text-2xl font-semibold text-zinc-900 dark:text-zinc-100">
              {@user_count}
            </p>
          </div>
          <div class="rounded-lg border border-zinc-300 bg-white p-4 dark:border-zinc-700 dark:bg-zinc-900">
            <p class="text-sm text-zinc-600 dark:text-zinc-400">Admin Users</p>
            <p class="mt-1 text-2xl font-semibold text-zinc-900 dark:text-zinc-100">
              {@admin_count}
            </p>
          </div>
          <div class="rounded-lg border border-zinc-300 bg-white p-4 dark:border-zinc-700 dark:bg-zinc-900">
            <p class="text-sm text-zinc-600 dark:text-zinc-400">Your Role</p>
            <p class="mt-1 text-2xl font-semibold text-zinc-900 dark:text-zinc-100">
              {Phoenix.Naming.humanize(@current_scope.user.role)}
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user_count = Boiler.Repo.aggregate(Boiler.Accounts.User, :count, :id)

    admin_count =
      from(u in Boiler.Accounts.User, where: u.role == :admin)
      |> Boiler.Repo.aggregate(:count, :id)

    {:ok, socket |> assign(user_count: user_count, admin_count: admin_count)}
  end
end
