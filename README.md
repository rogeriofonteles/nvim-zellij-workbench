# Neovim + Zellij workbench

An isolated, opt-in coding environment. It does not replace `~/.config/nvim`
or `~/.config/zellij`.

## Why this stack

- **LazyVim** supplies modern editing, completion, LSP, search, and navigation.
- **Gitsigns** provides inline changed-line signs, hunk actions, and blame.
- **Diffview** provides a changed-files view, file history, and a three-way
  merge/rebase conflict editor.
- **Neogit** provides a keyboard-oriented status screen for staging,
  committing, branching, merging, and interactive rebases.
- **Zellij** gives the complete workbench tab to Neovim. Codex, tests, Git
  commands, and general shell work can remain in your other terminal.

## Start

Open any repository in a new workbench session:

```sh
~/Projects/nvim-zellij-workbench/bin/workbench ~/Projects/my-repository
```

To open the complete two-window environment instead:

```sh
~/Projects/nvim-zellij-workbench/bin/dual-workbench ~/Projects/my-repository
```

This opens two persistent GNOME Terminal windows:

1. A full-screen Neovim Zellij session.
2. A separate Zellij session with Git/shell on the left and Codex on the
   right, launched as `codex --no-alt-screen --yolo`.

The windows attach to the long-lived `workbench-v2-editor` and `workbench-v2-agent`
Zellij sessions. Each repository gets a same-named tab in both sessions.
Running the command for another repository creates its two tabs; running it
again switches both windows back to those existing tabs without losing state.

To keep both work areas in one Zellij tab instead:

```sh
~/Projects/nvim-zellij-workbench/bin/surface-workbench ~/Projects/my-repository
```

This keeps Neovim on the tiled surface and Git/shell plus Codex in two
full-height halves on the floating surface. Together the two floating panes
cover Neovim while leaving Zellij's status bar visible at the bottom. Press
`Alt f` to show or hide the floating surface; its processes keep running while
it is hidden.

From Zellij, press `Alt w` to run `dual-workbench` for the focused pane's
current directory. Press `Alt Shift w` to open a terminal-native floating
picker inside Zellij. It lists project tabs that exist in both sessions, and
choosing one switches both sessions together. The picker uses `whiptail`, does
not require X or a desktop session, and works over SSH.

Press `Alt t` to open this repository in a single workbench tab.
The first press creates the tab; later presses switch back to it. Inside that
tab, `Alt f` toggles between full-size Neovim and the Git/Codex surface.

These bindings are not installed automatically. Add them inside the existing
`shared_except "locked"` block in `~/.config/zellij/config.kdl`, changing the
repository path if you cloned it somewhere else:

```kdl
bind "Alt w" {
    Run "/home/rogerio/Projects/nvim-zellij-workbench/bin/dual-workbench" {
        floating true
        close_on_exit true
    }
}

bind "Alt t" {
    Run "/home/rogerio/Projects/nvim-zellij-workbench/bin/surface-workbench" "/home/rogerio/Projects/nvim-zellij-workbench" {
        floating true
        close_on_exit true
    }
}

bind "Alt Shift w" {
    Run "/home/rogerio/Projects/nvim-zellij-workbench/bin/workbench-picker" {
        floating true
        close_on_exit true
        x "15%"
        y "15%"
        width "70%"
        height "70%"
    }
}
```

If run from inside Zellij, the command adds the workbench as a new tab. The
first Neovim launch downloads the official Neovim nightly build and plugins,
so it may take a minute. The nightly is isolated under
`~/.local/share/nvim-workbench/neovim-nightly` and includes the fix from
[Neovim PR #33410](https://github.com/neovim/neovim/pull/33410).

Update the workbench to the latest nightly at any time with:

```sh
~/Projects/nvim-zellij-workbench/bin/install-neovim-nightly
```

Optionally apply useful global Git defaults (review the script first):

```sh
~/Projects/nvim-zellij-workbench/bin/git-quality-setup
```

## Daily keys

LazyVim uses Space as `<leader>`.

| Key | Action |
| --- | --- |
| `Space Space` | Find files |
| `Space /` | Search text in the repository |
| `Space e` | File explorer |
| `Space E` | Return focus to the editor |
| `Space g g` | Neogit status and Git operations |
| `Space g d` | Review unstaged/staged changes in Diffview |
| `Space g m` | Open the merge/rebase conflict view |
| `Space g h` | History of the current file |
| `Space g H` | Repository history |
| `Space g b` | Blame the current line |
| `]c` / `[c` | Next/previous change in diff mode |
| `Tab` / `Shift-Tab` | Next/previous changed file in Diffview |

Run `:checkhealth` after first installation. Use `:Lazy` to inspect or update
plugins and `:Mason` to install language servers and formatters.

## Fast rebase / merge workflow

1. Start the operation from Neogit (`Space g g`) or the shell, for example
   `git rebase origin/main`.
2. If Git stops on conflicts, return to Neovim and press `Space g m`.
3. Select a conflicted file. Diffview opens its three-way merge editor with
   ours, the editable result, and theirs.
4. Use `]x` and `[x` to move between conflicts. Diffview's merge mappings are
   listed under `:help diffview-merge-tool`; `:diffget` and `:diffput` remain
   available from Neovim's native diff mode.
5. Save the result, stage it in Neogit, then continue the rebase or merge.

For a pull-request-style branch review, fetch the remote and run:

```vim
:DiffviewOpen origin/main...HEAD
```

This shows exactly what the branch contributes relative to its merge base.

## GitHub integration

The core setup intentionally works without GitHub CLI. For issue and pull
request comments inside Neovim, install and authenticate `gh`, then add
`pwntester/octo.nvim`. For most coding and conflict work, Diffview plus Neogit
is simpler and keeps the critical path local.

## Isolation and removal

Plugin data is stored under `~/.local/share/nvim-workbench`; the configuration
lives entirely in this folder. Remove those two directories to uninstall it.
