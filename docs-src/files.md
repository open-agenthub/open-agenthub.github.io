# Session files

Every session has a **Files** pane: a shared shelf for images, documents, videos and any other
file that you and the agent hand to each other. You upload into it from the browser, the agent
uploads into it through its built-in `agenthub_files` tools, and both sides can open, preview and
download what is there. Sessions of the same project can also read each other's files.

**Edition:** Community (collaborator access needs Enterprise sharing) · **Who:** session owner;
Collaborators of a shared session; Viewers read only

## Opening the Files pane

Click **Files** in the session bar. The pane opens beside the Workspace or Terminal, with the file
list on the left and a preview on the right. Drag the seam between the pane and the conversation
to resize it (25 to 75 %), and close it with the **×** on its tab or Esc. On a phone the panes
become tabs: **Files**, **Browser**, **Agent**.

Above the list, **Files** and **Changes** switch between the session's files and the per-file diff
of the agent's work (see [Workspace](/workspace)).

## Uploading files

| Where | How |
| --- | --- |
| Files pane | **Upload**, or drop files anywhere in the pane |
| Workspace composer | **＋** (*Attach files*), paste an image, or drag and drop |
| Agent terminal | Paste an image: it is uploaded and its path is pasted into the CLI |

Composer attachments are sent with your next message, so the agent sees them as part of the turn.
In the terminal, Claude Code, Codex, OpenCode and OpenClaw turn the pasted path into an image of
their own. Not tested: image paste and video upload with Cursor. In a plain shell tab, Ctrl+V
pastes text only.

Any file with a safe name can be uploaded — archives, source files, extensionless files. Files
without a known preview type are stored as opaque downloads; their content is never guessed into
a previewable type.

### Size limits

The defaults, which your operator can change in the chart (`files.*`):

| Limit | Default |
| --- | --- |
| Images, including SVG | 20 MiB |
| Documents and other files | 50 MiB |
| Video (MP4, WebM) | 100 MiB with object storage; 50 MiB without |
| Per message | 5 files, 50 MiB in total |
| Per session | 200 files, 1 GiB |

Uploads from the browser go through the ingress and the upload queue, which holds every file to
the 50 MiB message limit — a larger video can only come from the agent, which uploads inside the
cluster.

## Previews

| Type | Preview |
| --- | --- |
| PNG, JPEG, WebP, GIF | Image |
| SVG | Image only — scripts and external resources inside the SVG never run |
| PDF | The browser's PDF viewer |
| Markdown, plain text | Rendered text (first 1 MiB) |
| MP4 (H.264/AAC), WebM (VP8/VP9/AV1, Opus/Vorbis) | The browser's video player, with seeking |
| DOCX, PPTX, XLSX | A PDF preview, only if the operator enabled Office previews |
| Anything else | *No safe inline preview is available*, with a download link |

Videos are checked by content when the upload completes: a renamed file, an HEVC MP4 or a
Matroska file renamed to `.webm` is refused rather than shown as a broken player.

Office previews need a separate renderer. While it is off, the pane says *Preview for Office
documents is switched off* and offers the download. Operators enable it with
`files.officePreview.enabled: true` (see [Chart values](/chart-values)). The converted PDF belongs
to its document: it is deleted with it and cannot be deleted on its own.

## Where files are stored

With object storage configured, session files are persistent. Without it, a file lives only in
the running session pod; once the pod is gone it shows *This temporary file has expired*, and the
agent has to create or upload it again.

## Downloading

Use **↓** on a row, or **Download** in the preview toolbar. Every file can be downloaded,
whatever its type. Opaque files and SVG are always delivered as a download, never opened as a
page of the app.

## Deleting a file

Click **×** on a completed file. The row asks for confirmation — *Delete* followed by the file name and *It is removed for everyone
with access to this session.* — with **Keep** and **Delete**; Esc keeps the file.
The row also tells you if the file is being presented, has a PDF preview, or is visible to other
sessions of the project.

| Who | Can delete |
| --- | --- |
| Session owner | Yes |
| Collaborator (Enterprise direct share) | Yes |
| Viewer | No |
| Anyone opening a share link | No — share links are read-only |

Removing a row that is still uploading cancels the upload instead; only its uploader or the
session owner can do that.

**What a delete removes:** the file from the list, its stored content, its Office preview, and an
open presentation of it.

**What it does not remove:** copies the agent already has in its workspace, copies other sessions
of the project already fetched, older object versions on a versioned bucket, and backups.

## Files from the agent

Every supported agent gets the same `agenthub_files` MCP tools:

| Tool | What it does |
| --- | --- |
| `list_display_capabilities` | Which types can be previewed, and the active limits and storage mode |
| `list_files` | The session's ready files: id, name, type, size |
| `read_file` | Copies a file onto the pod's disk and returns its path; small images and text also come back inline |
| `upload_file` | Uploads a file from the workspace into the Files pane |
| `present_file` | Shows a file to everyone watching — uploads it first if given a local path |
| `dismiss_presentation` | Ends the presentation |
| `list_project_files` | Files of the other sessions in this project |
| `fetch_project_file` | Copies one of those files onto this pod's disk |

When the agent **presents** a file, the Files pane opens with that file selected for everyone who
has the session open. The owner and Collaborators can close it for all with **Dismiss for
everyone**.

## Sharing files between sessions of a project

Sessions with the **same owner** and the **same project** can read each other's ready files with
`list_project_files` and `fetch_project_file`. Nothing has to be switched on: putting sessions into
one project is the opt-in. Fetched files land on disk as a path, not in the agent's context.

- Read-only: a session can never upload, delete or present another session's files.
- A session without a project has no siblings.
- A session that is shared with anybody (Enterprise) reads no project files at all, so a share
  never exposes files from sessions that were not shared. Other sessions can still read its files.
- The project's files are not shown in the Files pane; open the session that made them.

::: warning Untrusted input
An agent that is misled — say by a web page or repository it reads — can read its project
siblings' files. Keep sessions that handle untrusted input and sessions holding sensitive files in
separate projects. See [Projects](/projects).
:::

## Shared sessions

Through Enterprise [sharing](/sharing), Collaborators can upload, delete, and dismiss
presentations; Viewers and share-link visitors can list, preview and download.
