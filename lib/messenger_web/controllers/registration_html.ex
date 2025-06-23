defmodule MessengerWeb.RegistrationHTML do
  use MessengerWeb, :html

  @doc """
  Renders the registration form for new users.
  """
  def new(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
          Create your account
        </h2>
        <p class="mt-2 text-center text-sm text-gray-600">
          Already have an account?
          <.link href={~p"/login"} class="font-medium text-blue-600 hover:text-blue-500">
            Sign in
          </.link>
        </p>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          <.form :let={f} for={@changeset} action={~p"/register"} method="post" class="space-y-6">
            <%= if @changeset.action do %>
              <div class="rounded-md bg-red-50 p-4 mb-4">
                <div class="flex">
                  <div class="flex-shrink-0">
                    <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
                    </svg>
                  </div>
                  <div class="ml-3">
                    <p class="text-sm font-medium text-red-800">
                      Please check the errors below.
                    </p>
                  </div>
                </div>
              </div>
            <% end %>

            <div>
              <label for="username" class="block text-sm font-medium text-gray-700">
                Username
              </label>
              <div class="mt-1">
                <%= text_input f, :username, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" %>
                <%= error_tag f, :username %>
              </div>
            </div>

            <div>
              <label for="email" class="block text-sm font-medium text-gray-700">
                Email address
              </label>
              <div class="mt-1">
                <%= email_input f, :email, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" %>
                <%= error_tag f, :email %>
              </div>
            </div>

            <div>
              <label for="password" class="block text-sm font-medium text-gray-700">
                Password
              </label>
              <div class="mt-1">
                <%= password_input f, :password, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" %>
                <%= error_tag f, :password %>
              </div>
              <p class="mt-1 text-xs text-gray-500">
                Password must be at least 8 characters long.
              </p>
            </div>

            <div>
              <button type="submit" class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                Create account
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the confirmation page after successful registration.
  """
  def confirmation(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <div class="text-center">
          <svg class="mx-auto h-12 w-12 text-green-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Account created successfully!
          </h2>
          <p class="mt-2 text-center text-sm text-gray-600">
            You're now ready to start messaging.
          </p>
        </div>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10 text-center">
          <p class="mb-4">
            Your account has been created and you're now signed in.
          </p>
          <div class="mt-6">
            <.link href={~p"/"} class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
              Go to chat rooms
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the profile edit form.
  """
  def edit(assigns) do
    ~H"""
    <div class="py-10">
      <header class="mb-8">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <h1 class="text-3xl font-bold leading-tight text-gray-900">
            Account Settings
          </h1>
        </div>
      </header>
      <main>
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <div class="grid grid-cols-1 gap-6">
                <div class="col-span-1">
                  <.form :let={f} for={@changeset} action={~p"/profile"} method="put" class="space-y-6">
                    <%= if @changeset.action do %>
                      <div class="rounded-md bg-red-50 p-4 mb-4">
                        <div class="flex">
                          <div class="flex-shrink-0">
                            <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
                            </svg>
                          </div>
                          <div class="ml-3">
                            <p class="text-sm font-medium text-red-800">
                              Please check the errors below.
                            </p>
                          </div>
                        </div>
                      </div>
                    <% end %>

                    <div>
                      <label for="username" class="block text-sm font-medium text-gray-700">
                        Username
                      </label>
                      <div class="mt-1">
                        <%= text_input f, :username, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" %>
                        <%= error_tag f, :username %>
                      </div>
                    </div>

                    <div>
                      <label for="email" class="block text-sm font-medium text-gray-700">
                        Email address
                      </label>
                      <div class="mt-1">
                        <%= email_input f, :email, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" %>
                        <%= error_tag f, :email %>
                      </div>
                    </div>

                    <div class="flex items-center justify-between">
                      <div>
                        <button type="submit" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                          Update profile
                        </button>
                      </div>
                      <div>
                        <.link href={~p"/profile/password"} class="text-sm text-blue-600 hover:text-blue-500">
                          Change password
                        </.link>
                      </div>
                    </div>
                  </.form>
                </div>
              </div>
            </div>
          </div>

          <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Delete account
              </h3>
              <div class="mt-2 max-w-xl text-sm text-gray-500">
                <p>
                  Once you delete your account, all of your data will be permanently removed.
                  This action cannot be undone.
                </p>
              </div>
              <div class="mt-5">
                <.form :let={f} for={%{}} action={~p"/profile/#{@user.id}"} method="delete">
                  <button type="submit" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                          onclick="return confirm('Are you sure you want to delete your account? This action cannot be undone.')">
                    Delete account
                  </button>
                </.form>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  @doc """
  Renders the password change form.
  """
  def edit_password(assigns) do
    ~H"""
    <div class="py-10">
      <header class="mb-8">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <h1 class="text-3xl font-bold leading-tight text-gray-900">
            Change Password
          </h1>
        </div>
      </header>
      <main>
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <.form :let={f} for={@changeset} action={~p"/profile/password"} method="put" class="space-y-6">
                <%= if @changeset.action do %>
                  <div class="rounded-md bg-red-50 p-4 mb-4">
                    <div class="flex">
                      <div class="flex-shrink-0">
                        <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
                        </svg>
                      </div>
                      <div class="ml-3">
                        <p class="text-sm font-medium text-red-800">
                          Please check the errors below.
                        </p>
                      </div>
                    </div>
                  </div>
                <% end %>

                <div>
                  <label for="current_password" class="block text-sm font-medium text-gray-700">
                    Current password
                  </label>
                  <div class="mt-1">
                    <input type="password" name="current_password" id="current_password" required
                          class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm">
                  </div>
                </div>

                <div>
                  <label for="user_password" class="block text-sm font-medium text-gray-700">
                    New password
                  </label>
                  <div class="mt-1">
                    <%= password_input f, :password, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" %>
                    <%= error_tag f, :password %>
                  </div>
                </div>

                <div class="flex items-center justify-between">
                  <button type="submit" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                    Update password
                  </button>
                  <.link href={~p"/profile"} class="text-sm text-gray-600 hover:text-gray-500">
                    Back to profile
                  </.link>
                </div>
              </.form>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  @doc """
  Generates HTML for form error messages.
  """
  defp error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(:span, translate_error(error),
        class: "block mt-1 text-sm text-red-600",
        phx_feedback_for: input_name(form, field)
      )
    end)
  end

  @doc """
  Translates an error message.
  """
  defp translate_error({msg, opts}) do
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end
end
