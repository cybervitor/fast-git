# Fast-GIT

A suite of fast, custom bash utilities designed to seamlessly bridge your local Git workflow with GitLab issue tracking. 

Built for speed and trunk-based development, these tools eliminate the friction of creating tickets, syncing branches, and checking team status without ever leaving the terminal.

---

## Prerequisites & Setup

Before installing, ensure you have the required dependencies installed and authenticated on your system.

### 1. GitLab CLI (`glab`)
Used for querying the GitLab API and generating tickets.
* **Install:** [GitLab CLI Documentation](https://docs.gitlab.com/cli/)
* **Setup:** You will need a Personal Access Token with `api` and `write_repository` scopes.
* **Authenticate:** Run `glab auth login` to configure your connection.

### 2. Git Town
Used by the `ticket` command to safely sync your local `master`/`main` branch and cut a clean working branch.
* **Install:** [Git Town Installation](https://www.git-town.com/install.html)
* **Setup:** Run `git-town init` in your repository at least once to configure your branch structure.

### 3. jq
A lightweight and flexible command-line JSON processor used internally to parse API responses.
* **Install:** Available via most package managers (e.g., `apt install jq`, `brew install jq`).

### 4. GitLab VS Code Extension (Recommended)
Highly recommended for tying this CLI workflow directly into your editor environment.
* **Install:** [GitLab Workflow Extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
* **Setup:** Requires a Personal Access Token with `api` scope.

---

## Installation

You can install `fast-git` globally for all users, or locally in your home directory.

**For a system-wide installation (requires sudo):**
```bash
sudo ./install.sh
```

**For a local user installation (no sudo required):**
```bash
PREFIX=~/.local ./install.sh
```

> **Note:** If installing locally, ensure `~/.local/bin` is in your system's `$PATH`.

---

## Commands

All utilities are accessed via the `fast` command dispatcher[cite: 1].

### `fast ticket "Title" "Optional Description"`
A tool for quickly scaffolding new work. It interacts with GitLab to create a new ticket[cite: 4], grabs the newly generated Issue ID, and runs `git-town hack` to safely branch off your main trunk[cite: 4]. Finally, it publishes the branch upstream so the rest of the team can see it immediately[cite: 4].
* **Usage:** `fast ticket "Fix database index" "Addresses the slow query issue on the user table"`

### `fast ongoing`
A pulse-check on active development. This command scans the repository's remote branches, extracts any ticket IDs[cite: 3], and cross-references them against GitLab's open issues[cite: 3]. It outputs a clean, terminal-friendly dashboard grouped by developer, showing you exactly what work is *currently* happening[cite: 3].
* **Usage:** `fast ongoing`

### `fast backlog`
The complete team view. It pulls down all open issues for the project and maps them to their assigned developers, clearly tagging which tickets are currently `[ONGOING]` based on active branches. It also outputs the unassigned "Team Backlog" so developers know exactly what to pull from next.
* **Usage:** `fast backlog`