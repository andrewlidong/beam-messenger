defmodule MessengerWeb.UserSocket do
  use Phoenix.Socket

  # A Socket handler
  #
  # It's possible to control the websocket connection and
  # assign values that can be accessed by your channel topics.

  ## Channels
  # Register our chat channel to handle all chat:* topics
  channel "chat:*", MessengerWeb.ChatChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error` or `{:error, term}`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    # Max age of 2 weeks (1209600 seconds)
    max_age = 1_209_600
    
    case Phoenix.Token.verify(MessengerWeb.Endpoint, "user socket", token, max_age: max_age) do
      {:ok, user_data} ->
        # Extract user information from the verified token
        user_id = Map.get(user_data, "user_id")
        username = Map.get(user_data, "username", "user_#{user_id}")
        
        socket = socket
        |> assign(:user_id, user_id)
        |> assign(:username, username)
        
        {:ok, socket}
      
      {:error, _reason} ->
        # Allow anonymous connections but mark them as such
        random_id = "anon_#{System.unique_integer([:positive])}"
        socket = socket
        |> assign(:user_id, random_id)
        |> assign(:username, "Guest_#{random_id}")
        |> assign(:anonymous, true)
        
        {:ok, socket}
    end
  end

  # For connections without a token, assign a temporary guest user
  def connect(_params, socket, _connect_info) do
    random_id = "guest_#{System.unique_integer([:positive])}"
    socket = socket
    |> assign(:user_id, random_id)
    |> assign(:username, "Guest_#{random_id}")
    |> assign(:anonymous, true)
    
    {:ok, socket}
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     MessengerWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous
  @impl true
  def id(socket) do
    if Map.get(socket.assigns, :anonymous, false) do
      nil
    else
      "user_socket:#{socket.assigns.user_id}"
    end
  end

  # Sets the maximum timeout for socket connections
  # Default is 2 minutes (120000 ms)
  @impl true
  def connect_info(_opts) do
    %{transport_options: [timeout: 120_000]}
  end
end
