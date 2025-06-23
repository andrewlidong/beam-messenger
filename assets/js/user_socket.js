/*
 * Socket connection setup for the Messenger app
 *
 *  – Ensures **only one** WebSocket connection per browser session.
 *  – Provides helpers for getting / disconnecting the singleton.
 */

import { Socket } from "phoenix";

class SocketManager {
  // private static field holding the singleton
  static #socket = null;

  /**
   * Lazily create (or return existing) Phoenix.Socket instance.
   * @param {string} token – signed user token
   */
  static getSocket(token = window.userToken) {
    // If it already exists simply return it
    if (SocketManager.#socket) return SocketManager.#socket;

    // Otherwise create and connect
    const socket = new Socket("/socket", {
      params: { token },
      logger: (kind, msg, data) => console.log(`${kind}: ${msg}`, data)
    });

    // Optional event hooks for debugging
    socket.onOpen(() => console.log("Socket connection opened"));
    socket.onError((err) => console.error("Socket connection error", err));
    socket.onClose(() => console.log("Socket connection closed"));

    socket.connect(); // establish the connection once

    SocketManager.#socket = socket;
    // expose for console debugging
    window.socket = socket;
    return socket;
  }

  /**
   * Disconnect (and clear) the singleton socket.
   * Useful when doing a full sign-out.
   */
  static disconnect() {
    if (SocketManager.#socket) {
      SocketManager.#socket.disconnect();
      delete window.socket;
      SocketManager.#socket = null;
    }
  }
}

// Create / reuse the socket immediately so side-effects remain for legacy imports
const socket = SocketManager.getSocket();

// Default export kept for backward-compatibility
export default socket;

// Also export the manager in case callers need explicit control
export { SocketManager };
