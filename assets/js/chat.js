// Chat functionality for the Messenger app
import { Socket, Presence } from "phoenix";

// Main chat initialization function that will be called from the chat page
window.initChat = function(roomId, token, userId, username) {
  // Initialize the Phoenix Socket with authentication token
  const socket = new Socket("/socket", {
    params: { token: token }
  });
  
  // Connect to the socket
  socket.connect();
  
  // Initialize chat with the connected socket
  const chat = new Chat(socket, roomId, userId, username);
  chat.init();
  
  // Make chat instance available globally for debugging
  window.chatInstance = chat;
  
  return chat;
};

class Chat {
  constructor(socket, roomId, userId, username) {
    this.socket = socket;
    this.roomId = roomId;
    this.userId = userId;
    this.username = username;
    this.channel = null;
    this.presence = null;
    this.typingTimeout = null;
    this.isTyping = false;
    
    // DOM elements
    this.messageContainer = document.getElementById("messages-container");
    this.messageForm = document.getElementById("message-form");
    this.messageInput = document.getElementById("message-input");
    this.onlineUsers = document.getElementById("online-users");
    this.typingIndicator = document.getElementById("typing-indicator");
  }
  
  init() {
    this.joinChannel();
    this.setupEventListeners();
    console.log(`Chat initialized for room: ${this.roomId} as user: ${this.username}`);
  }
  
  joinChannel() {
    // Join the chat channel for the specific room
    const channelTopic = `chat:${this.roomId}`;
    this.channel = this.socket.channel(channelTopic, {});
    
    // Handle channel join
    this.channel.join()
      .receive("ok", resp => {
        console.log(`Joined channel ${channelTopic} successfully`, resp);
        this.scrollToBottom();
      })
      .receive("error", resp => {
        console.error(`Unable to join ${channelTopic}`, resp);
        this.showError(`Failed to join chat: ${resp.reason || 'Unknown error'}`);
      });
    
    // Set up event listeners for channel events
    this.setupChannelEventListeners();
    
    // Initialize presence tracking
    this.presence = new Presence(this.channel);
    this.setupPresenceTracking();
  }
  
  setupChannelEventListeners() {
    // Listen for new messages
    this.channel.on("new_message", payload => {
      this.receiveMessage(payload);
    });
    
    // Listen for user joined notifications
    this.channel.on("user_joined", payload => {
      this.showNotification(`${payload.username} joined the room`);
    });
    
    // Listen for user left notifications
    this.channel.on("user_left", payload => {
      // Find the username from presence if available
      const username = this.getUsernameById(payload.user_id) || "Someone";
      this.showNotification(`${username} left the room`);
    });
    
    // Listen for typing indicators
    this.channel.on("user_typing", payload => {
      if (payload.user_id !== this.userId) {
        this.showTypingIndicator(payload);
      }
    });
  }
  
  setupPresenceTracking() {
    // Set up presence callbacks
    this.presence.onSync(() => {
      this.renderOnlineUsers();
    });
    
    // Listen for presence state changes
    this.channel.on("presence_state", state => {
      this.presence.syncState(state);
    });
    
    // Listen for presence diff changes
    this.channel.on("presence_diff", diff => {
      this.presence.syncDiff(diff);
    });
  }
  
  setupEventListeners() {
    // Handle message form submission
    this.messageForm.addEventListener("submit", e => {
      e.preventDefault();
      this.sendMessage();
    });
    
    // Handle typing events
    this.messageInput.addEventListener("input", () => {
      this.handleTyping();
    });
    
    // Handle keydown for Enter key
    this.messageInput.addEventListener("keydown", e => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        this.sendMessage();
      }
    });
  }
  
  sendMessage() {
    const text = this.messageInput.value.trim();
    if (!text) return;
    
    // Send message to the server
    this.channel.push("new_message", { text })
      .receive("ok", response => {
        // Message sent successfully, clear input
        this.messageInput.value = "";
        this.messageInput.focus();
        
        // Reset typing indicator
        this.isTyping = false;
        this.channel.push("typing", { typing: false });
        
        // Scroll to bottom to see new message
        this.scrollToBottom();
      })
      .receive("error", response => {
        console.error("Failed to send message", response);
        this.showError("Failed to send message. Please try again.");
      });
  }
  
  receiveMessage(message) {
    // Create message element
    const messageEl = this.createMessageElement(message);
    
    // Add message to container
    this.messageContainer.appendChild(messageEl);
    
    // Scroll to bottom if user was already at bottom
    if (this.isUserAtBottom()) {
      this.scrollToBottom();
    } else {
      this.showNewMessageIndicator();
    }
  }
  
  createMessageElement(message) {
    const isCurrentUser = message.user_id === this.userId;
    
    // Create message container
    const messageEl = document.createElement("div");
    messageEl.className = `flex ${isCurrentUser ? "justify-end" : ""} message-item`;
    
    // Create message bubble
    const bubble = document.createElement("div");
    bubble.className = `max-w-[80%] rounded-lg px-4 py-2 ${
      isCurrentUser ? "bg-blue-500 text-white" : "bg-gray-200"
    }`;
    
    // Create header with username and timestamp
    const header = document.createElement("div");
    header.className = "flex items-baseline justify-between gap-2";
    
    const username = document.createElement("span");
    username.className = `font-semibold text-sm ${
      isCurrentUser ? "text-blue-100" : "text-gray-700"
    }`;
    username.textContent = message.username;
    
    const timestamp = document.createElement("span");
    timestamp.className = `text-xs ${
      isCurrentUser ? "text-blue-100" : "text-gray-500"
    }`;
    timestamp.textContent = this.formatTimestamp(message.timestamp);
    
    header.appendChild(username);
    header.appendChild(timestamp);
    
    // Create message text
    const text = document.createElement("p");
    text.className = "mt-1 break-words";
    text.textContent = message.text;
    
    // Assemble message
    bubble.appendChild(header);
    bubble.appendChild(text);
    messageEl.appendChild(bubble);
    
    return messageEl;
  }
  
  handleTyping() {
    // Don't send typing events if nothing has changed
    if (!this.isTyping) {
      this.isTyping = true;
      this.channel.push("typing", { typing: true });
    }
    
    // Clear existing timeout
    if (this.typingTimeout) {
      clearTimeout(this.typingTimeout);
    }
    
    // Set new timeout to stop typing indicator after 2 seconds
    this.typingTimeout = setTimeout(() => {
      this.isTyping = false;
      this.channel.push("typing", { typing: false });
    }, 2000);
  }
  
  showTypingIndicator(payload) {
    if (payload.typing) {
      // Get username from presence data
      const username = this.getUsernameById(payload.user_id) || "Someone";
      this.typingIndicator.textContent = `${username} is typing...`;
      this.typingIndicator.classList.remove("hidden");
    } else {
      // Check if anyone else is typing
      const stillTyping = Object.values(this.presence.state)
        .some(presences => 
          presences.some(p => 
            p.metas.some(m => m.typing && m.user_id !== this.userId)
          )
        );
      
      if (!stillTyping) {
        this.typingIndicator.classList.add("hidden");
      }
    }
  }
  
  renderOnlineUsers() {
    // Clear current list
    this.onlineUsers.innerHTML = "";
    
    // Get presence information
    const presences = this.presence.list((id, { metas: [first, ...rest] }) => {
      const count = rest.length + 1;
      const status = first.status || "online";
      
      return {
        id,
        username: first.username || id,
        count,
        status
      };
    });
    
    if (presences.length === 0) {
      const emptyEl = document.createElement("li");
      emptyEl.className = "text-gray-500 italic";
      emptyEl.textContent = "No users online";
      this.onlineUsers.appendChild(emptyEl);
      return;
    }
    
    // Sort by username
    presences.sort((a, b) => a.username.localeCompare(b.username));
    
    // Create list items for each user
    presences.forEach(presence => {
      const userEl = document.createElement("li");
      userEl.className = "flex items-center space-x-2";
      
      // Status indicator
      const statusDot = document.createElement("span");
      statusDot.className = `inline-block w-2 h-2 rounded-full ${
        presence.status === "away" ? "bg-yellow-500" : "bg-green-500"
      }`;
      
      // Username
      const usernameEl = document.createElement("span");
      usernameEl.className = presence.id === this.userId ? "font-semibold" : "";
      usernameEl.textContent = presence.username;
      
      // Count badge for multiple connections
      if (presence.count > 1) {
        const countBadge = document.createElement("span");
        countBadge.className = "bg-gray-200 text-gray-700 text-xs rounded-full px-2";
        countBadge.textContent = presence.count;
        userEl.appendChild(countBadge);
      }
      
      userEl.appendChild(statusDot);
      userEl.appendChild(usernameEl);
      this.onlineUsers.appendChild(userEl);
    });
  }
  
  getUsernameById(userId) {
    // Find username from presence data
    const userPresence = this.presence.state[userId];
    if (userPresence && userPresence.length > 0) {
      return userPresence[0].metas[0].username;
    }
    return null;
  }
  
  showNotification(message) {
    // Create notification element
    const notificationEl = document.createElement("div");
    notificationEl.className = "text-center text-sm text-gray-500 my-2";
    notificationEl.textContent = message;
    
    // Add to message container
    this.messageContainer.appendChild(notificationEl);
    
    // Scroll to bottom if user was already at bottom
    if (this.isUserAtBottom()) {
      this.scrollToBottom();
    }
  }
  
  showError(message) {
    // Create error notification
    const errorEl = document.createElement("div");
    errorEl.className = "text-center text-sm text-red-500 my-2 p-2 bg-red-100 rounded";
    errorEl.textContent = message;
    
    // Add to message container
    this.messageContainer.appendChild(errorEl);
    this.scrollToBottom();
  }
  
  showNewMessageIndicator() {
    // In a real app, you would show a "new messages" button
    // that scrolls to bottom when clicked
    console.log("New messages received");
  }
  
  isUserAtBottom() {
    const container = this.messageContainer;
    const threshold = 100; // pixels from bottom
    return container.scrollHeight - container.scrollTop - container.clientHeight < threshold;
  }
  
  scrollToBottom() {
    this.messageContainer.scrollTop = this.messageContainer.scrollHeight;
  }
  
  formatTimestamp(timestamp) {
    if (!timestamp) return "";
    
    // Convert to Date object if it's a string
    const date = typeof timestamp === "string" ? new Date(timestamp) : new Date(timestamp);
    
    // Format as HH:MM
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  }
  
  // Update user status (away/online)
  updateStatus(status) {
    this.channel.push("status", { status });
  }
  
  // Cleanup when leaving the page
  destroy() {
    if (this.channel) {
      this.channel.leave();
    }
    
    if (this.typingTimeout) {
      clearTimeout(this.typingTimeout);
    }
    
    console.log("Chat destroyed");
  }
}

// Initialize chat when page loads if the container exists
document.addEventListener("DOMContentLoaded", () => {
  const chatContainer = document.getElementById("chat-container");
  if (chatContainer) {
    const roomId = chatContainer.dataset.roomId;
    const token = chatContainer.dataset.token;
    const userId = chatContainer.dataset.userId;
    const username = chatContainer.dataset.username;
    
    if (roomId && token) {
      window.initChat(roomId, token, userId, username);
    }
  }
});

// Handle page visibility changes to update status
document.addEventListener("visibilitychange", () => {
  const chat = window.chatInstance;
  if (chat) {
    if (document.hidden) {
      chat.updateStatus("away");
    } else {
      chat.updateStatus("online");
    }
  }
});
