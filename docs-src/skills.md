# Skill library

The skill library keeps reusable agent skills — a `SKILL.md` with instructions, plus helper
scripts and other files — for all your sessions. Every save is a new version, and older versions can
be restored. Sessions put the matching skills into the agent's own skill directory and keep it up
to date while they run, and agents can search, read and save skills themselves, so what one session
works out is there for the next.

**Edition:** Community · Enterprise for sharing with other users, groups or everyone ·
**Who:** every user for their own skills; admins for sharing and publishing settings

## Managing skills in Settings

Open **Settings → Skills**. The list shows each skill with its version (`v3`), its project if it
has one, and *shared · owner* (with the owner's name) for skills other users shared with you. **Search skills…** filters
the list.

**Add skill** opens the form:

| Field | Meaning |
| --- | --- |
| **Name** | kebab-case: lowercase letters, digits, hyphens, e.g. `review-checklist` |
| **Description** | When the agent should use it — this is what the agent sees when choosing a skill |
| **Scope** | **Personal (all my sessions)** or **Project:** and the project name — a project skill is only loaded into that project's sessions |
| **Content** | The `SKILL.md` Markdown |

**Edit** changes a skill and takes an optional **Change note** for the history. Files that came
with the skill (scripts, assets) are listed and kept on save; agents manage them through the
library tools. **Delete** removes the skill. Skills shared with you are read-only.

### Versions and restore

**History** lists every version with time, author and change note. **View** shows that version's
content; **Restore** makes it the new latest version, content and files together, so restoring is
itself a new version and nothing is lost.

## Which skills a session gets

There is no per-session list to manage. A session receives:

- your personal skills,
- the skills of the session's project, if it has one,
- skills shared with you (Enterprise).

When two have the same name, the project skill wins over a personal one, and your own skill wins
over a shared one.

## Skills stay in sync while sessions run

The session writes its skills into `~/.claude/skills` at start (Codex, Cursor and OpenClaw read the
same directory as `~/.agents/skills`) and checks the library for changes every minute. A skill saved
in Settings or by another session therefore reaches running sessions:

| Agent | A new or changed skill appears |
| --- | --- |
| Claude Code | On the next turn |
| Codex | On the next turn |
| OpenCode | When the agent is idle, before its next turn |
| OpenClaw | At the next start of the session |
| Cursor | Not verified — assume the next start |

If the agent edits a library skill in place, the session keeps its edit rather than overwriting it
with the library's version; the agent is told to save the edit with `upload_skill` to share it.

### Skills the agent creates

A skill the agent creates as a new directory under `~/.claude/skills` is imported into the library
automatically — within about a minute and when the session ends. It lands in the session's project,
or in your personal library when the session has none. Unchanged skills do not create new versions.

### The end-of-turn reminder

Claude Code, Codex and Cursor sessions get a reminder at the end of a turn that edited files or ran
commands: is there a reusable procedure or script that belongs in the library? The agent saves it
or says in one line that there is nothing. Turns that only answered a question are left alone.

## The agent's library tools

Every session gets the built-in `skill-library` MCP server:

| Tool | What it does |
| --- | --- |
| `search_skills` | Search project, personal and shared skills by keywords — and by meaning if the operator configured embeddings |
| `get_skill` | Read a skill, a single file of it, or an older version; with `out_dir`, write the whole skill to disk |
| `upload_skill` | Create or update a skill, with an optional change note; takes a local `path` (a directory, a file or a `.tar.gz`) so large scripts never pass through the agent's context |
| `list_skill_versions` | A skill's history, newest first |
| `restore_skill_version` | Restore an older version of one of your own skills as the new latest |

Uploads go to the session's project, or to your personal library when the session has no project.

## Sharing skills (Enterprise)

On the Enterprise edition, admins see **Sharing** on their own skills in Settings → Skills: **Share
with everyone**, with selected **Users**, or with **Groups** from your OIDC provider. Recipients get
the skill read-only, in Settings and in their sessions.

Under **Settings → Skill publishing**, an admin can tick **Allow users to publish skills to
everyone**. Users then see **Publish to everyone** on their own skills. Without an Enterprise
licence these controls show a licence notice instead.

## For operators

| Value | Default | Meaning |
| --- | --- | --- |
| `skillLibrary.mcp` | `true` | Give sessions the `skill-library` MCP server |
| `skillLibrary.embeddings.endpoint` | `""` | An `/embeddings` HTTP endpoint for search by meaning; empty means keyword search only |
| `skillLibrary.embeddings.model` | `""` | The embedding model to request |
| `skillLibrary.embeddings.apiKey` | `""` | Key for that endpoint |

See [Chart values](/chart-values).
