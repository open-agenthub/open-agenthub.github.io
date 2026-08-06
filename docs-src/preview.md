# Previewing a page the agent is building

An agent can serve a page from its own session pod and open it in the integrated browser.
Nothing is published anywhere: the page never leaves the session, and the browser reaches
it directly by pod address.

## How it works

Start a server on one of the allowed ports, then point the browser at it. The session's own
address is in `AGENTHUB_POD_IP`:

```bash
python3 -m http.server 8000 --directory ./site
```

```text
browser_navigate  http://$AGENTHUB_POD_IP:8000
```

That is the whole flow. A real dev server works just as well, which is usually what you
want because you keep hot reload:

```bash
npm run dev -- --host 0.0.0.0 --port 5173
```

::: tip Bind to 0.0.0.0
Dev servers that default to `localhost` are unreachable from the browser pod. Vite needs
`--host`, Next.js `-H 0.0.0.0`, Python's `http.server` already binds everywhere.
:::

## Allowed ports

Session pods deny all traffic by default, so only these ports are opened, and only between
the browser and its own session:

| Port | Typical use |
| --- | --- |
| 3000 | Next.js, Create React App |
| 4173 | Vite preview |
| 5173 | Vite dev server |
| 8000 | `python -m http.server` |
| 8080 | Anything generic |

Change them with `browser.previewPorts`, or set it to `[]` to switch the feature off:

```yaml
browser:
  previewPorts: [3000, 5173, 9000]
```

The rules are created per browser lease and removed with it, so nothing outlives the
session — and no other session, or anything else in the cluster, can reach that server.

## What this is not

The preview lives and dies with the session. It is for looking at what the agent is
building, not for hosting. If you want a page to outlive the session, have the agent write
it to the session's files and download it from there, or publish it somewhere you control.

Serving agent-generated HTML from the hub's own domain would put it on the same origin as
the app, where it could read tokens and session data — which is exactly why the preview
stays inside the pod network.
