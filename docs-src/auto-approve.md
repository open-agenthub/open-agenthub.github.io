# Auto approve

Normally every tool a session wants to use raises a permission prompt — in the web app,
and in your messenger if you set one up. **Auto approve** answers those prompts with
"allow" automatically, so the agent works without stopping to ask.

## Turning it on

**For a new session** — tick *Auto approve* in the new-session dialog.

**Straight from a prompt** — when the agent asks for permission, the prompt offers
**Allow everything** next to *Allow* and *Allow (don't ask again)*. This is the quickest
path: you are already looking at the prompt, and it answers this one along with every
prompt after it.

**For a session that is already running** — the *Auto approve* toggle in *Edit session*.

Either way it takes effect immediately, with no restart: the backend evaluates the flag on
every permission request rather than baking it into the pod.

Switching it on also clears the prompts that are already waiting. Without that they would
keep the agent blocked for the rest of its poll window, because auto approve only
short-circuits *new* requests.

While it is on, a banner sits above the terminal with a **Turn off** button. The next
request after that prompts as usual.

## When to use it

Recommended for **non-root containers**.

With *Run as root*, the agent may run any command as root inside that container,
unattended — combine the two only for a container you would have handed over anyway. The
UI warns when both are on.

What does not change: the session's own container is still the boundary. Network policies,
the unprivileged pod spec, and the per-user secret mounts all still apply, so the blast
radius stays that one container. Auto approve grants nothing outside it.

A reasonable rule of thumb:

| Situation | Auto approve |
| --- | --- |
| Throwaway container, scratch repo | Fine |
| Long-running session on a repo you care about | Prefer *Allow (don't ask again)* per tool |
| `Run as root` enabled | Only if you would hand the container over anyway |
| Session reachable by a linked Telegram group | Remember everyone in that group could have approved anyway |

## Related: allow always

**Allow (don't ask again)**, right next to it in the prompt, is the narrower tool. It
whitelists that one tool for the rest of the session and keeps prompting for everything
else. If you find yourself approving the same two tools over and over, that is usually the
better answer than auto approve.
