local M = {}
local sessions = {}
local editors = {}
local busy = false
local pending = false

local function file_in(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" then
    return
  end
  local name = vim.api.nvim_buf_get_name(buf)
  return name ~= "" and vim.fn.fnamemodify(name, ":p") or nil
end

local function hide(editor)
  local win = editor.terminal
  editor.terminal = nil
  if win and vim.api.nvim_win_is_valid(win) and editor.session
    and vim.api.nvim_win_get_buf(win) == editor.session.buffer then
    if #vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(win)) == 1 then
      vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(true, false))
    else
      vim.api.nvim_win_close(win, true)
    end
  end
  editor.session = nil
end

local function show(win, editor, session)
  if editor.terminal and vim.api.nvim_win_is_valid(editor.terminal)
    and vim.api.nvim_win_get_buf(editor.terminal) == session.buffer then
    return editor.terminal
  end
  hide(editor)
  local terminal
  vim.api.nvim_win_call(win, function()
    vim.cmd("rightbelow vsplit")
    terminal = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(terminal, session.buffer)
  end)
  editor.terminal = terminal
  editor.session = session
  return terminal
end

local function reconcile()
  if busy then
    return
  end
  busy = true
  local tab = vim.api.nvim_get_current_tabpage()
  for win, editor in pairs(editors) do
    if not vim.api.nvim_win_is_valid(win) then
      hide(editor)
      editors[win] = nil
    elseif vim.api.nvim_win_get_tabpage(win) == tab then
      -- File-tab clicks can replace the focused terminal. Move that file
      -- into its editor so navigation still leaves one file window.
      local terminal = editor.terminal
      if terminal and vim.api.nvim_win_is_valid(terminal) and file_in(terminal) then
        local buf = vim.api.nvim_win_get_buf(terminal)
        local focused = vim.api.nvim_get_current_win() == terminal
        editor.terminal = nil
        editor.session = nil
        vim.api.nvim_win_set_buf(win, buf)
        vim.api.nvim_win_close(terminal, true)
        if focused then
          vim.api.nvim_set_current_win(win)
        end
      end
      local file = file_in(win)
      -- Picker focus and terminal focus don't change the owning file.
      if file ~= editor.file then
        hide(editor)
        editor.file = file
        local session = file and sessions[file]
        if session and vim.api.nvim_buf_is_valid(session.buffer) then
          show(win, editor, session)
        end
      end
    end
  end
  busy = false
end

local function schedule()
  if busy or pending then
    return
  end
  pending = true
  vim.schedule(function()
    pending = false
    reconcile()
  end)
end

local function terminal_keys(buf)
  for _, key in ipairs({ "]w", "[w" }) do
    vim.keymap.set("t", key,
      [[<C-\><C-n><cmd>lua require("config.codex").toggle_focus()<cr>]],
      { buffer = buf, desc = "Switch Codex / file" })
  end
end

function M.toggle_focus()
  local current = vim.api.nvim_get_current_win()
  for win, editor in pairs(editors) do
    if editor.terminal == current and vim.api.nvim_win_is_valid(win) then
      vim.cmd.stopinsert()
      vim.api.nvim_set_current_win(win)
      return
    end
  end
  M.open()
end

function M.setup()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.b[buf].codex_file then
      terminal_keys(buf)
    end
  end
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinClosed", "TabEnter" }, {
    group = vim.api.nvim_create_augroup("WorkbenchFileCodex", { clear = true }),
    callback = schedule,
  })
end

function M.open(opts)
  opts = opts or {}
  local win = vim.api.nvim_get_current_win()
  local file = file_in(win)
  if not file then
    vim.notify("Open a named file before starting its Codex session", vim.log.levels.WARN)
    return
  end
  local editor = editors[win] or {}
  editors[win] = editor
  local session = sessions[file]
  if session and vim.api.nvim_buf_is_valid(session.buffer) then
    busy = true
    editor.file = file
    local terminal = show(win, editor, session)
    busy = false
    vim.api.nvim_set_current_win(terminal)
    vim.cmd("startinsert")
    return
  end
  if vim.fn.executable("codex") ~= 1 then
    vim.notify("codex is not on PATH", vim.log.levels.ERROR)
    return
  end

  local cwd = LazyVim.root.git()
  local command = { "codex", "--no-alt-screen", "--yolo" }
  if opts.resume then
    vim.list_extend(command, { "resume", opts.resume })
  else
    command[#command + 1] = "I'm working on the file " .. file
      .. ". Use this file as the starting context for my requests. "
      .. "Read it first, then wait for my instructions before making changes."
  end
  session = { buffer = vim.api.nvim_create_buf(false, true) }
  vim.bo[session.buffer].bufhidden = "hide"
  vim.b[session.buffer].codex_file = file
  busy = true
  editor.file = file
  local terminal = show(win, editor, session)
  vim.api.nvim_set_current_win(terminal)
  local ok, job = pcall(vim.fn.jobstart, command, { cwd = cwd, term = true })
  -- Terminal creation may change 'buflisted'; keep it out of file tabs.
  vim.bo[session.buffer].buflisted = false
  terminal_keys(session.buffer)
  if not ok or job <= 0 then
    hide(editor)
    vim.api.nvim_buf_delete(session.buffer, { force = true })
    busy = false
    vim.notify("Could not start Codex: " .. tostring(job), vim.log.levels.ERROR)
    return
  end
  session.job = job
  sessions[file] = session
  busy = false
  vim.cmd("startinsert")
end

M.setup()
return M
