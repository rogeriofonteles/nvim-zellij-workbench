local root = vim.env.CODEX_TEST_DIR
vim.opt.rtp:prepend(vim.env.CODEX_TEST_ROOT .. "/config/nvim-workbench")
LazyVim = { root = { git = function() return root end } }
local codex = require("config.codex")
local editor = vim.api.nvim_get_current_win()

local function file(name)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, root .. "/" .. name)
  return buf
end

local a = file("file ' $a.py")
local b = file("other.py")
local function switch(buf, windows)
  vim.cmd.stopinsert()
  vim.api.nvim_set_current_win(editor)
  vim.api.nvim_win_set_buf(editor, buf)
  vim.wait(50, function() return false end)
  assert(vim.wait(2000, function() return #vim.api.nvim_list_wins() == windows end), "wrong split count")
end

local function terminal()
  local buf = vim.api.nvim_get_current_buf()
  assert(vim.bo[buf].buftype == "terminal")
  assert(vim.bo[buf].bufhidden == "hide", "terminal will be destroyed when hidden")
  assert(not vim.bo[buf].buflisted, "terminal appears among file tabs")
  return buf, vim.b[buf].terminal_job_id
end

switch(a, 1)
codex.open()
local ta, ja = terminal()
assert(#vim.api.nvim_list_wins() == 2)
assert(vim.wait(2000, function() return #vim.fn.glob(root .. "/*.json", false, true) == 1 end))
local data = vim.json.decode(table.concat(vim.fn.readfile(vim.fn.glob(root .. "/*.json", false, true)[1]), "\n"))
assert(data.cwd == root)
assert(data.argv[1] == "--no-alt-screen" and data.argv[2] == "--yolo")
assert(#data.argv == 3 and data.argv[3]:find(vim.api.nvim_buf_get_name(a), 1, true))
assert(vim.fn.maparg("]w", "t", false, true).buffer == 1)
codex.toggle_focus()
assert(vim.api.nvim_get_current_win() == editor, "toggle did not focus file")
codex.toggle_focus()
assert(terminal() == ta, "toggle did not reuse Codex")

-- File changes hide the session without stopping it.
switch(b, 1)
assert(vim.api.nvim_buf_is_valid(ta))
assert(vim.fn.jobwait({ ja }, 0)[1] == -1, "hidden session stopped")
codex.open()
local tb, jb = terminal()
assert(tb ~= ta and jb ~= ja, "files shared a session")
switch(a, 2)
local shown = false
for _, win in ipairs(vim.api.nvim_list_wins()) do
  shown = shown or vim.api.nvim_win_get_buf(win) == ta
end
assert(shown, "returning to file did not restore session")
assert(vim.fn.jobwait({ jb }, 0)[1] == -1)
codex.open()
assert(terminal() == ta, "shortcut created duplicate session")

-- Focusing a picker must not hide the attached split.
vim.cmd.stopinsert()
vim.api.nvim_set_current_win(editor)
local picker = vim.api.nvim_create_buf(false, true)
local popup = vim.api.nvim_open_win(picker, true, {
  relative = "editor", row = 0, col = 0, width = 10, height = 2,
})
vim.wait(50, function() return false end)
assert(#vim.api.nvim_list_wins() == 3)
vim.api.nvim_win_close(popup, true)

-- Closing only the split keeps Codex alive and shortcut reuses it.
codex.open()
vim.cmd.stopinsert()
vim.api.nvim_win_close(vim.api.nvim_get_current_win(), true)
vim.wait(50, function() return false end)
assert(#vim.api.nvim_list_wins() == 1)
assert(vim.fn.jobwait({ ja }, 0)[1] == -1)
codex.open()
assert(terminal() == ta)
switch(b, 2)
codex.open()
assert(terminal() == tb)

-- Choosing a file while the terminal is focused redirects to its editor.
vim.cmd.stopinsert()
local third = file("third.py")
vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), third)
assert(vim.wait(2000, function() return #vim.api.nvim_list_wins() == 1 end))
assert(vim.api.nvim_win_get_buf(editor) == third)
assert(vim.fn.jobwait({ jb }, 0)[1] == -1)

local jobstart = vim.fn.jobstart
local notify = vim.notify
vim.notify = function() end
vim.fn.jobstart = function() error("simulated failure") end
codex.open()
assert(#vim.api.nvim_list_wins() == 1, "failed launch left a split")
vim.fn.jobstart = jobstart
local executable = vim.fn.executable
vim.fn.executable = function() return 0 end
codex.open()
assert(#vim.api.nvim_list_wins() == 1)
vim.fn.executable = executable
vim.notify = notify

print("Codex checks passed: file ownership, live hidden sessions, reuse, picker focus, arguments, failure cleanup")
vim.cmd("qa!")
