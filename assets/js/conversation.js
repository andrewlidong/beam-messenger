import {Socket, Presence} from "phoenix"

class ConversationChat {
  constructor() {
    this.socket = null;
    this.channel = null;
    this.presences = {};
    this.typingTimer = null;
    
    this.init();
  }

  init() {
    // Wait for ConversationChat data to be available
    if (typeof window.ConversationChat === 'undefined') {
      setTimeout(() => this.init(), 100);
      return;
    }

    const { conversationId, userId, username, token } = window.ConversationChat;
    
    this.conversationId = conversationId;
    this.userId = userId;
    this.username = username;

    this.setupSocket(token);
    this.joinConversation();
    this.setupEventListeners();
  }

  setupSocket(token) {
    this.socket = new Socket("/socket", {
      params: { token: token }
    });

    this.socket.connect();
  }

  joinConversation() {
    this.channel = this.socket.channel(`conversation:${this.conversationId}`, {});
    
    this.channel.join()
      .receive("ok", resp => {
        console.log("Joined conversation successfully", resp);
      })
      .receive("error", resp => {
        console.log("Unable to join conversation", resp);
      });

    // Handle incoming messages
    this.channel.on("new_message", message => {
      this.addMessage(message);
    });

    // Handle message history
    this.channel.on("message_history", payload => {
      this.loadMessageHistory(payload.messages);
    });

    // Handle presence
    this.channel.on("presence_state", state => {
      this.presences = Presence.syncState(this.presences, state);
      this.updateOnlineUsers();
    });

    this.channel.on("presence_diff", diff => {
      this.presences = Presence.syncDiff(this.presences, diff);
      this.updateOnlineUsers();
    });

    // Handle typing indicators
    this.channel.on("user_typing", payload => {
      this.updateTypingIndicator(payload);
    });

    // Handle user join/leave
    this.channel.on("user_joined", payload => {
      console.log(`${payload.username} joined the conversation`);
    });

    this.channel.on("user_left", payload => {
      console.log(`User ${payload.user_id} left the conversation`);
    });
  }

  setupEventListeners() {
    const messageInput = document.getElementById('message-input');
    const sendButton = document.getElementById('send-button');

    // Send message on button click
    sendButton?.addEventListener('click', () => {
      this.sendMessage();
    });

    // Send message on Enter key
    messageInput?.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        this.sendMessage();
      }
    });

    // Handle typing indicators
    messageInput?.addEventListener('input', () => {
      this.handleTyping();
    });

    messageInput?.addEventListener('blur', () => {
      this.stopTyping();
    });
  }

  sendMessage() {
    const messageInput = document.getElementById('message-input');
    const text = messageInput?.value.trim();

    if (!text || !this.channel) return;

    this.channel.push("new_message", { text: text })
      .receive("ok", () => {
        messageInput.value = '';
        this.stopTyping();
      })
      .receive("error", (err) => {
        console.error("Failed to send message:", err);
      });
  }

  addMessage(message) {
    const messagesContainer = document.getElementById('messages');
    if (!messagesContainer) return;

    const messageElement = this.createMessageElement(message);
    messagesContainer.appendChild(messageElement);
    this.scrollToBottom();
  }

  createMessageElement(message) {
    const isOwnMessage = message.sender_id === this.userId;
    const timestamp = new Date(message.timestamp).toLocaleTimeString([], { 
      hour: '2-digit', 
      minute: '2-digit' 
    });

    const messageDiv = document.createElement('div');
    messageDiv.className = `flex ${isOwnMessage ? 'justify-end' : 'justify-start'}`;

    const bubbleClass = isOwnMessage 
      ? 'bg-blue-600 text-white' 
      : 'bg-white dark:bg-gray-800 text-gray-900 dark:text-white border border-gray-200 dark:border-gray-700';

    messageDiv.innerHTML = `
      <div class="max-w-xs lg:max-w-md px-4 py-2 rounded-lg ${bubbleClass}">
        ${!isOwnMessage && this.isGroupConversation() ? `
          <p class="text-xs font-medium mb-1 opacity-75">
            ${message.username}
          </p>
        ` : ''}
        <p class="text-sm">${this.escapeHtml(message.text)}</p>
        <p class="text-xs mt-1 ${isOwnMessage ? 'text-blue-100' : 'text-gray-500 dark:text-gray-400'}">
          ${timestamp}
        </p>
      </div>
    `;

    return messageDiv;
  }

  loadMessageHistory(messages) {
    const messagesContainer = document.getElementById('messages');
    if (!messagesContainer) return;

    // Clear existing messages
    messagesContainer.innerHTML = '';

    // Add all messages
    messages.forEach(message => {
      this.addMessage(message);
    });
  }

  handleTyping() {
    if (!this.channel) return;

    // Send typing indicator
    this.channel.push("typing", { typing: true });

    // Clear existing timer
    if (this.typingTimer) {
      clearTimeout(this.typingTimer);
    }

    // Set timer to stop typing after 3 seconds
    this.typingTimer = setTimeout(() => {
      this.stopTyping();
    }, 3000);
  }

  stopTyping() {
    if (!this.channel) return;

    this.channel.push("typing", { typing: false });
    
    if (this.typingTimer) {
      clearTimeout(this.typingTimer);
      this.typingTimer = null;
    }
  }

  updateTypingIndicator(payload) {
    const typingIndicator = document.getElementById('typing-indicator');
    if (!typingIndicator || payload.user_id === this.userId) return;

    if (payload.typing) {
      typingIndicator.textContent = 'Someone is typing...';
      typingIndicator.classList.remove('hidden');
    } else {
      typingIndicator.textContent = '';
      typingIndicator.classList.add('hidden');
    }
  }

  updateOnlineUsers() {
    const onlineUsersContainer = document.getElementById('online-users');
    if (!onlineUsersContainer) return;

    const users = Presence.list(this.presences, (id, { metas }) => {
      return { id, username: metas[0].username };
    });

    onlineUsersContainer.innerHTML = '';
    
    users.forEach(user => {
      if (user.id !== this.userId) {
        const userElement = document.createElement('div');
        userElement.className = 'flex items-center space-x-1';
        userElement.innerHTML = `
          <div class="h-2 w-2 bg-green-500 rounded-full"></div>
          <span class="text-xs text-gray-600 dark:text-gray-400">${user.username}</span>
        `;
        onlineUsersContainer.appendChild(userElement);
      }
    });
  }

  isGroupConversation() {
    // In a real app, you'd get this from the conversation data
    // For now, assume it's a group if there are more than 2 participants
    return Object.keys(this.presences).length > 2;
  }

  scrollToBottom() {
    const messagesContainer = document.getElementById('messages');
    if (messagesContainer) {
      messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
}

// Initialize conversation chat when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  if (window.location.pathname.includes('/conversations/') && 
      !window.location.pathname.includes('/new-group')) {
    new ConversationChat();
  }
});

export default ConversationChat;