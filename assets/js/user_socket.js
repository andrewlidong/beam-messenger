// Socket connection setup for the Messenger app
import { Socket } from "phoenix";

// Create a new Phoenix Socket instance
// This creates the socket but doesn't connect yet
let socket = new Socket("/socket", {
  // Optional params to send when connecting
  params: { token: window.userToken },
  
  // Logger configuration
  logger: (kind, msg, data) => { console.log(`${kind}: ${msg}`, data); }
});

// You can set up hooks to handle different socket lifecycle events
socket.onOpen(() => console.log("Socket connection opened"));
socket.onError((error) => console.error("Socket connection error", error));
socket.onClose(() => console.log("Socket connection closed"));

// When you're ready to connect to the server (usually done in the chat.js module)
// socket.connect();

// Export the socket for use in other modules
export default socket;

// You can also expose it on window for debugging
window.socket = socket;
