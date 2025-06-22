defmodule MessengerWeb.ChatHTML do
  use MessengerWeb, :html

  @doc """
  Renders the chat rooms index page.
  """
  def index(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-6">Chat Rooms</h1>
      
      <div class="mb-6">
        <.link href={~p"/chat/new"} class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
          Create New Room
        </.link>
      </div>
      
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <%= for room <- @rooms do %>
          <div class="bg-white shadow-md rounded-lg p-6 hover:shadow-lg transition-shadow">
            <h2 class="text-xl font-semibold mb-2"><%= room.name %></h2>
            <p class="text-gray-600 mb-4"><%= room.description %></p>
            <.link href={~p"/chat/#{room.id}"} class="text-blue-500 hover:text-blue-700">
              Join Room →
            </.link>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders the chat room page with message history and input form.
  """
  def show(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-gray-100" id="chat-container" 
         data-room-id={@room_id} 
         data-token={@token}
         data-user-id={@user_id}
         data-username={@username}>
      <header class="bg-white shadow-sm p-4 border-b">
        <div class="flex justify-between items-center">
          <div>
            <h1 class="text-xl font-semibold">Room: <%= @room_id %></h1>
            <p class="text-sm text-gray-500">
              Connected as: <span id="current-username"><%= @username %></span>
            </p>
          </div>
          <div>
            <.link href={~p"/chat"} class="text-blue-500 hover:text-blue-700">
              ← Back to Rooms
            </.link>
          </div>
        </div>
      </header>
      
      <div class="flex-1 overflow-hidden flex flex-col">
        <!-- Online users sidebar -->
        <div class="flex flex-1 overflow-hidden">
          <div class="w-64 bg-white border-r hidden md:block p-4">
            <h2 class="font-semibold text-lg mb-2">Online Users</h2>
            <ul id="online-users" class="space-y-1">
              <!-- Will be populated by JS -->
              <li class="text-gray-500 italic">Loading users...</li>
            </ul>
          </div>
          
          <!-- Chat messages -->
          <div class="flex-1 flex flex-col overflow-hidden">
            <div id="messages-container" class="flex-1 overflow-y-auto p-4 space-y-4">
              <%= for message <- @messages do %>
                <.message_item message={message} current_user_id={@user_id} />
              <% end %>
            </div>
            
            <!-- User is typing indicator -->
            <div id="typing-indicator" class="px-4 py-2 text-sm text-gray-500 italic hidden">
              Someone is typing...
            </div>
            
            <!-- Message input form -->
            <div class="border-t p-4 bg-white">
              <form id="message-form" class="flex space-x-2" phx-submit="send_message">
                <input type="text" 
                       id="message-input" 
                       placeholder="Type a message..." 
                       class="flex-1 border rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" 
                       autocomplete="off" />
                <button type="submit" 
                        class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg">
                  Send
                </button>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>

    <script>
      document.addEventListener("DOMContentLoaded", function() {
        // Initialize chat socket connection
        const container = document.getElementById("chat-container");
        const roomId = container.dataset.roomId;
        const token = container.dataset.token;
        const userId = container.dataset.userId;
        const username = container.dataset.username;
        
        // Connect to socket (this will be implemented in app.js)
        if (window.initChat) {
          window.initChat(roomId, token, userId, username);
        } else {
          console.error("Chat initialization function not found!");
        }
      });
    </script>
    """
  end

  @doc """
  Renders a single message item.
  """
  def message_item(assigns) do
    ~H"""
    <div class={[
      "flex", 
      "message-item", 
      @message.user_id == @current_user_id && "justify-end"
    ]}>
      <div class={[
        "max-w-[80%] rounded-lg px-4 py-2",
        @message.user_id == @current_user_id && "bg-blue-500 text-white",
        @message.user_id != @current_user_id && "bg-gray-200"
      ]}>
        <div class="flex items-baseline justify-between gap-2">
          <span class={[
            "font-semibold text-sm",
            @message.user_id == @current_user_id && "text-blue-100",
            @message.user_id != @current_user_id && "text-gray-700"
          ]}>
            <%= @message.username %>
          </span>
          <span class={[
            "text-xs",
            @message.user_id == @current_user_id && "text-blue-100",
            @message.user_id != @current_user_id && "text-gray-500"
          ]}>
            <%= format_timestamp(@message.timestamp) %>
          </span>
        </div>
        <p class="mt-1 break-words"><%= @message.text %></p>
      </div>
    </div>
    """
  end

  @doc """
  Renders the new chat room form.
  """
  def new(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-6">Create New Chat Room</h1>
      
      <div class="bg-white shadow-md rounded-lg p-6 max-w-md">
        <form action={~p"/chat"} method="post">
          <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
          
          <div class="mb-4">
            <label for="room_id" class="block text-gray-700 font-semibold mb-2">Room ID</label>
            <input type="text" 
                   id="room_id" 
                   name="room[id]" 
                   class="w-full border rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                   placeholder="e.g., general, tech-talk, etc."
                   required />
            <p class="text-sm text-gray-500 mt-1">
              This will be used in the URL. Use only letters, numbers, and hyphens.
            </p>
          </div>
          
          <div class="mb-4">
            <label for="room_name" class="block text-gray-700 font-semibold mb-2">Room Name</label>
            <input type="text" 
                   id="room_name" 
                   name="room[name]" 
                   class="w-full border rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                   placeholder="e.g., General Discussion"
                   required />
          </div>
          
          <div class="mb-6">
            <label for="room_description" class="block text-gray-700 font-semibold mb-2">Description</label>
            <textarea id="room_description" 
                      name="room[description]" 
                      class="w-full border rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                      rows="3"
                      placeholder="What's this room about?"></textarea>
          </div>
          
          <div class="flex justify-between">
            <.link href={~p"/chat"} class="text-blue-500 hover:text-blue-700">
              Cancel
            </.link>
            <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
              Create Room
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  @doc """
  Renders message history for AJAX loading.
  """
  def history(assigns) do
    ~H"""
    <%= for message <- @messages do %>
      <.message_item message={message} current_user_id={@current_user_id} />
    <% end %>
    """
  end

  # Helper function to format timestamp
  defp format_timestamp(timestamp) do
    case timestamp do
      %DateTime{} ->
        Calendar.strftime(timestamp, "%H:%M")
      %NaiveDateTime{} ->
        Calendar.strftime(timestamp, "%H:%M")
      _ ->
        "Unknown time"
    end
  end
end
