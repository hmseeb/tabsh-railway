// Keeps the tabsh board current: tabsh status, by OpenCode session.
// OpenCode 1.x shape (an exported async function returning hooks).
import { execFile } from "node:child_process"

function status(sessionID, ...args) {
  const event = JSON.stringify({ session_id: sessionID })
  execFile("/usr/local/bin/tabsh", ["status", ...args, "--hook", event], () => {})
}

// OpenCode repeats session.status busy for every step of a turn: only the
// first one after idle is the user's prompt, or a later step would undo the
// agent marking its card completed.
const busy = new Set()

export const TabshBoard = async () => ({
  event: async ({ event }) => {
    const id = event?.properties?.sessionID
    if (typeof id !== "string") return
    if (event.type === "session.status" && event.properties.status?.type === "busy") {
      if (!busy.has(id)) status(id, "in_progress")
      busy.add(id)
    }
    else if (event.type === "permission.asked" || event.type === "permission.updated")
      status(id, "needs_input", "--if-not", "completed", "--note", "OpenCode needs your permission")
    else if (event.type === "session.idle") {
      busy.delete(id)
      status(id, "needs_input", "--if-not", "completed", "--note", "Agent finished its turn")
    }
  },
})
