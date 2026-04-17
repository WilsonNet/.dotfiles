import { execSync } from "child_process"

const EMOJI = {
  working: "\u{1F41D}",
  permission: "\u26A0\uFE0F",
  error: "\u274C",
  question: "\u2753",
}

const PRIORITY = {
  idle: 0,
  working: 1,
  error: 2,
  question: 3,
  permission: 4,
}

function findWindowByPid(pid) {
  try {
    const panes = execSync('tmux list-panes -a -F "#{pane_id} #{pane_pid} #{window_index}"', { encoding: "utf-8" })
    const paneMap = new Map()
    
    for (const line of panes.trim().split('\n')) {
      const [paneId, panePid, windowIdx] = line.split(' ')
      if (paneId && panePid) {
        paneMap.set(parseInt(panePid), { paneId, windowIdx })
      }
    }
    
    let currentPid = pid
    let iterations = 0
    while (currentPid > 1 && iterations < 50) {
      if (paneMap.has(currentPid)) {
        return paneMap.get(currentPid).windowIdx
      }
      
      try {
        const stat = execSync(`cat /proc/${currentPid}/stat 2>/dev/null || echo ""`, { encoding: "utf-8" })
        const match = stat.match(/^\d+ \S+ \S (\d+)/)
        if (!match) break
        currentPid = parseInt(match[1])
      } catch {
        break
      }
      iterations++
    }
  } catch {}
  return null
}

export const TmuxEmojiStatus = async ({ $ }) => {
  try {
    await $`tmux -V`.quiet()
  } catch {
    return {}
  }

  const windowIdx = findWindowByPid(process.pid)
  if (!windowIdx) return {}

  let target = ""
  try {
    const session = (await $`tmux display-message -p "#S"`.quiet().text()).trim()
    target = `${session}:${windowIdx}`
  } catch {
    return {}
  }

  let currentPriority = 0

  function clean(n) { 
    return n.replace(/^(?:[^\x00-\x7F]+\s*)+/, "") 
  }
  
  async function setEmoji(emoji, priority) {
    if (priority < currentPriority) return
    
    try {
      const cur = (await $`tmux display-message -t ${target} -p "#W"`.quiet().text()).trim()
      const base = clean(cur)
      const name = emoji ? `${emoji} ${base}` : base
      
      if (name !== cur) {
        await $`tmux rename-window -t ${target} ${name}`.quiet()
      }
      
      currentPriority = priority
    } catch {}
  }

  return {
    event: async ({ event }) => {
      const t = event?.type
      
      if (t === "session.status" && event.properties?.status?.type === "busy") {
        await setEmoji(EMOJI.working, PRIORITY.working)
      }
      else if (t === "session.idle") {
        currentPriority = PRIORITY.idle
        await setEmoji(null, PRIORITY.idle)
      }
      else if (t === "permission.asked" || t === "permission.ask") {
        await setEmoji(EMOJI.permission, PRIORITY.permission)
      }
      else if (t === "session.error") {
        await setEmoji(EMOJI.error, PRIORITY.error)
      }
      else if (t === "message.part.updated") {
        for (const part of event.properties?.parts || []) {
          if (part?.type === "tool-use" && part?.tool === "question") {
            await setEmoji(EMOJI.question, PRIORITY.question)
            return
          }
        }
      }
    },
  }
}
