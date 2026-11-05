# Projects and organizing sessions

Projects group your sessions in the sidebar. A project also decides which stored secrets its
sessions receive, lets its sessions read each other's files, and makes its sessions a fleet that
can find and message each other. This page covers creating projects, ordering and moving
sessions, and finding them again.

**Edition:** Community · **Who:** the project owner. Sharing a whole project with other people is
an Enterprise feature, see Sharing.

## Create a project

- In the sidebar, click **+ New project** and enter a name.
- Or, while creating a session, choose **Project → New project…** in the **New session** dialog
  and enter a **Project name**. The project is created with no colour and no selected secrets.
  If the session itself then fails to start, the project is kept and stays selected, so a retry
  does not create a second project.

Project names must be unique per owner, ignoring case.

## Project controls

Each project header in the sidebar has these controls:

| Control | What it does |
| --- | --- |
| **↑ / ↓** (Move up, Move down) | Change the order of the projects |
| **✎** (Rename) | Rename the project |
| **●** (Color) | Pick a colour for the project marker |
| **⚿** (Secrets) | Choose which stored secrets the project's sessions receive, see Secrets |
| **⇪** (Share project) | Share the project with a user or group (Enterprise), see Sharing |
| **×** (Delete project) | Delete the project; its sessions stay, ungrouped |

Click the project name to collapse or expand it.

## What a project gives its sessions

- **Secrets:** the project's secret selection is the default for every session in it and for the
  child sessions they start in it. A session can narrow the selection or receive extra grants of
  its own. See Secrets.
- **Files:** sessions of one project can list and fetch each other's files. See
  Session files.
- **A fleet:** sessions of one project can list each other and send each other messages with the
  built-in tools. The session **Description** tells the other agents what a session is for. See
  Built-in tools inside a session.

## Reorder sessions

Drag a session in the sidebar and drop it before another session to change the order. The order is
saved on the server for your account, so it is the same on every device, and new sessions follow
it.

Without a mouse, use the **Organize session** button on a session row: it offers **Move session
up**, **Move session down** and **Move to project** as ordinary buttons and a dialog, which works
with the keyboard and on touch screens.

Only your own sessions can be reordered or moved. Sessions shared with you stay in their own
group.

## Move a session to another project

Drop a session on a project header, or use **Organize session → Move to project**. The dialog says
what changes before you confirm:

- **Secrets:** how many project secrets are removed and added. A session whose selection you
  narrowed stays narrowed, and grants made for this session stay with it.
- **Files:** access to the old project's files ends and the destination project's files become
  available at once. The session's own files stay with it.
- **Settings:** the destination project's secrets and settings apply on the next start.

A **running session is paused first**, after you confirm. Environment variables cannot be removed
from a running process, so it would otherwise keep the old project's secrets next to the new
project's files. Resume it afterwards to load the new configuration. If the move fails after the
pause, the session stays paused and you can retry.

### Scheduled sessions

A scheduled session moves without pausing. Its schedule is suspended while the move rewrites it,
then continues unchanged; the next run starts with the destination project's secrets only, and
earlier runs keep their history.

If a run is in progress, the move is refused at first and the dialog offers **Stop run and move**.
Stopping ends that run, and its unfinished work is lost. If a move stops part-way, the sidebar
shows *Move unfinished · schedule paused* and the dialog offers **Finish move**; no run starts
until the move is finished.

## Find sessions

- **Find a session…** in the top bar searches your sessions as you type.
- The **Sessions** page groups the list by **Project**, **Repository**, **Status** or **None**, and
  filters it by **All**, **Running**, **Question open**, **Waiting**, **Scheduled**, **Paused**,
  **Done** or **Failed**.
- The home page lists what **needs you**: sessions with an open question or waiting for your reply.

## Related pages

- [Sessions](/sessions)
- Secrets
- Sharing (Enterprise)
