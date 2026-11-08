# Switch agent provider

::: warning Experimental, off by default
The operator must enable switching for the workspace type: repository-backed temporary workspaces (`agent.repositoryProviderSwitchEnabled`) or persistent session workspaces (`agent.workspaceVolume.persistent`). Recovery needs a valid native checkpoint and either fetchable recorded repository commits or the original workspace volume. Native archives do not back up uncommitted code. Keep the option off in production while evaluating the tested recovery limits and your backup procedure. Node and volume loss are not covered.
:::

The owner can replace Claude with Codex, or Codex with Claude, keeping the same session and
visible Workspace conversation. The target starts fresh native context with only the reviewed
handover. Switching back also starts fresh context. Temporary workspaces restore clean, pushed
repository commits on their recorded local branches. Persistent workspaces keep their original
volume, including dirty and untracked files saved there. Processes and memory do not transfer.

This is a **Community** feature. Only the **owner** can review, start, cancel or retry a switch.
Enterprise sharing links and roles stay attached to the session. Collaborators and Viewers
can continue to read permitted history, but sharing grants no switching authority. Peer
agents and parent sessions cannot switch another owner's session through MCP.

## Before switching

Use a packaged Claude or Codex **Interactive** session with the **Terminal** interface,
running without root privileges. Temporary `emptyDir` workspaces need repository-backed
switching enabled, configured object storage and fetchable repository commits. Existing
supported sessions can use it after updating their runtime; no PVC migration is needed.

Configure the target provider's usable subscription account or API key first in
[Provider login](/provider-login). Custom model endpoints need a known, sufficiently large
context window. A missing optional context-window value does not block the pinned native
default or discovered built-in models: admission uses a conservative 100,000-token minimum.
A reported window takes precedence, including a smaller one. Unknown custom capacity is refused.
An **unknown model** means the selected model ID is not in AgentHub's catalogue for the target
agent/account or endpoint. Catalogue membership does not check provider entitlement or prove
that the account can use the model.

Finish the current turn, resolve approvals and questions, clear draft input and CLI menus,
and close shell terminals and helper containers. Busy or uncertain runtime state is refused.
Keep the target account available until the replacement finishes; a rejected login or
exhausted account must be fixed before retrying.

## Save code before switching a temporary workspace

Choose **Check again** in **Switch provider**. AgentHub checks every configured repository:
its local branch and exact commit, staged and unstaged tracked changes, non-ignored untracked
files, and whether the commit is available from its remote branch using the Git credentials
selected for the session. Read-only repositories are ready when the commit is already there.
Missing remotes, unpublished commits and failed fetches block switching with a reason;
unavailable comparisons are shown as unknown. Git access is separate from model-account login.

Commit and push intended work yourself, or choose **Ask the agent to commit and push**.
Review or edit the prepared message and choose **Send this request**. It proposes a task branch,
asks for a normal push without force, and requires your explicit confirmation before committing
or pushing directly to main or the remote default branch. The source uses its ordinary tools
and approvals. If push fails, unpublished work still blocks switching. The message does not
approve a switch: wait for the source turn to finish, then **Check again** and review the handover.

Ignored files do **not** block switching. The dialog shows counts and a bounded sample of names
per repository. Acknowledge that these files and listed files outside repositories **will not
carry over**. File contents are not included. The new agent must recreate dependencies (for
example, run `npm install`) and build output. Ignored `.env` files and similar local configuration
do not carry over; supply needed configuration through your intended process. Switching is
not a secret boundary.

The target clones the selected remote branch and checks out the **recorded commit on the
recorded local branch**, with its upstream set. It does not use detached HEAD or silently
choose a newer remote tip. Changed repository or omitted-file checks require another check
and review. Initially, the repository path supports 1–32 configured repositories with bounded
metadata. Submodules, large-file filters, detached HEAD, unsupported checkout layouts and
index flags that hide tracked changes are refused. Local Git configuration, unpublished
branches, patches, bundles and workspace files are not added to native state archives.

## Review and start

1. Open **Switch provider** in the session's Workspace controls. If the panel says
   **The session is still starting. Try again in a moment.**, wait and reopen it. A visible
   answer can arrive before startup checks finish; review becomes available once the session is ready.
2. For temporary workspaces, check repositories and acknowledge omitted files first. Select the other provider, its authentication mode and account, and the model settings.
3. Enter the instructions, current task, decisions, pending work and references the next agent
   needs. Review the exact framed handover, including its omission note.
4. Start the reviewed replacement. Editing the selection invalidates the review.

Only the reviewed text becomes the new agent's first native user turn. The complete text,
including framing and the request marker, is limited to **16,000 characters**. Oversized
selections are refused rather than silently shortened. References stay plain text; they do
not fetch files or attach their contents. Do not include credentials in the handover.

Earlier native messages, raw tool output, attachments, hidden reasoning and native resume
files are omitted from the handover. Visible history is not the target model's context.
The new agent can inspect the preserved workspace through its normal permitted tools.
Only recorded repository commits or files on the persistent volume carry over. Processes and
memory from the old pod are not transferred.
Stop background services before switching and restart needed services in the new runtime.

The source agent checkpoints and exits before its pod is removed. AgentHub waits for the source pod
(and, for a persistent volume, all consumers) to disappear, then starts the other provider in a replacement pod.
The replacement has a fresh home and only the selected target provider's credentials; source
native state is never translated or restored into it. Approval mode, tool restrictions, MCP
access, selected session secrets and network policy remain in effect. Old approvals are not
carried over as permission for new calls.

## During replacement and on failure

Workspace input and competing maintenance actions are held while the switch is pending.
Fleet messages remain queued until the target handover is committed. Cancelling before
source shutdown releases queued messages back to the original agent. The target's initial
input cannot be replaced by a queued message.

Cancel is available only before native source shutdown begins. Afterwards, use **Retry**
when the reported problem is fixed. A retry checks the same durable operation and target;
it does not retype an uncertain handover or automatically create a second target. If native
shutdown, storage, pod identity or delivery cannot be confirmed, the switch stays held with
an explanation. There is no automatic rollback to the source agent.

When the hold means agent state is uncertain, diagnose it with your administrator and make an
operator decision before taking further action. **Deleting is destructive**: it removes the session and its workspace claim, and depending on the storage policy
can delete the underlying volume and lose data. Deletion provides no restore path. Preserve
and verify needed data independently before an operator chooses deletion.

Before retrying a held switch:

1. Read the reason and repair provider credentials, Git fetch access, storage or runtime state.
   A removed or rewritten remote branch may require restoring the recorded commit; retry never
   substitutes another commit.
2. Keep the same target selection and reviewed handover. Retry continues the existing operation.
3. If the target pod disappeared after startup might have begun, leave the operation held and
   ask your administrator to inspect it. A missing pod does not prove the handover never ran.
4. If the operator decides the session cannot be recovered, preserve and verify workspace
   files before deletion. Native state archives do not contain dirty repositories, and
   deleting the session does not restore or recover them.

A retry cannot recover an unavailable native archive, unfetchable recorded commit, missing workspace claim or expired
credential by using another execution's state. Do not edit native resume files or replace
an uncertain target manually to make a retry proceed.

The session keeps one visible conversation with provider boundaries. Combined history has
retention limits and explicit omission notes; see [Handover preview](/handover-preview#conversation-history).
Completed execution usage is shown separately by provider/account where available.

## Resume after a completed switch

From **1.21.1**, resuming a completed switch requires the saved native conversation for
its current provider and execution. If that archive is missing or cannot be restored,
resume refuses to start. The persistent workspace is retained, and the original task is
not submitted again. Runtime maintenance uses the current execution's archive too.

After an explicit context clear, resume follows the saved current native conversation.
Clearing context does not erase earlier visible Workspace history or make that history part
of the new model context.

Recovery was tested for backend restarts, container/pod crashes after an acknowledged
checkpoint, temporary state-storage or scheduling failures, and source/target pod-loss holds.
These results require the workspace volume to remain available and the current checkpoint
to be valid. They do not cover node or volume loss. **Resume** after a completed switch uses
the latest successfully saved native checkpoint. Only data saved on the workspace volume
survives; application-buffered or in-memory writes are not preserved. Recent turns that had not been saved
may be absent from model context even when their saved repository edits remain on the volume.
The visible conversation does not reconstruct missing native context. A native agent process failure is reported
separately from a container or pod crash.

Restore the current archive and retry **Resume**. A previous provider's archive, an earlier
execution of the same provider, or the visible conversation cannot replace the missing
native state. If it cannot be recovered, ask your administrator to preserve the workspace
before an operator decides whether to delete the session. Deletion removes its workspace
claim, may delete the volume, and supplies no restore path.

A repository-backed resume also restores the current execution's recorded commit and branch
before native resume. Missing repository checkpoint metadata holds restoration. Work created
after that code checkpoint is still temporary: uncommitted or unpushed changes, ignored files
and files outside repositories are not backed up by native archive saves. Keep important code
pushed. A later switch records a new verified code checkpoint. Visible history cannot
reconstruct missing code or native model context.

## Known limits

A broken checkpoint file stops resume of a completed switch. The session reports that its
saved native checkpoint metadata is invalid or does not match the committed conversation.
Ask your administrator to recover a valid current archive; do not replace it with another
execution's native state. Ordinary sessions can still save their native archive and pause
when optional checkpoint metadata is damaged.

## Operator storage settings

To allow repository-backed switching without a PVC:

```yaml
agent:
  repositoryProviderSwitchEnabled: true
  workspaceVolume:
    persistent: false
```

The admission flag defaults to `false` and is independent of PVC allocation. Configure object
storage and Git access for the selected repositories. Disabling admission blocks new switches;
current execution checkpoints are still required for resume. A repository outage or deleted
remote commit can block restoration, so repository retention is part of recovery availability.

Alternatively, enable persistent workspaces for newly created supported sessions:

```yaml
agent:
  workspaceVolume:
    persistent: true
    size: 10Gi
    storageClass: ""
```

An empty `storageClass` uses the cluster default. Choose a class supporting writable
filesystem claims and suitable capacity for each session. Each new supported session gets
its own claim; existing temporary workspaces are unchanged. Disabling the flag stops new
admission but existing recorded claims still mount on resume and are cleaned up on deletion.

Pause and failed switches retain the claim. Session deletion stops producers and deletes the
owned claim before removing its registry record. A storage class with a **Retain** reclaim
policy can leave the underlying volume for operator cleanup and associated storage charges.

A persistent workspace is **not a backup**. Native state archives contain provider state,
not dirty repositories. Back up a quiesced workspace together with consistent session database,
execution history and object-storage artifacts. Restoring a missing claim from a native state
archive cannot reconstruct the workspace. Volume snapshot automation and migration of old
`emptyDir` sessions are outside this feature.
