local last_editor_win

local function focus_explorer()
  local current = vim.api.nvim_get_current_win()
  local buffer = vim.api.nvim_win_get_buf(current)
  if vim.bo[buffer].buftype == "" then
    last_editor_win = current
  end

  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  if explorer then
    explorer:focus("list", { show = true })
  else
    Snacks.explorer({ cwd = LazyVim.root() })
  end
end

local function focus_editor()
  if last_editor_win and vim.api.nvim_win_is_valid(last_editor_win) then
    vim.api.nvim_set_current_win(last_editor_win)
    return
  end

  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  if explorer and explorer.main and vim.api.nvim_win_is_valid(explorer.main) then
    vim.api.nvim_set_current_win(explorer.main)
    return
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buffer = vim.api.nvim_win_get_buf(win)
    if vim.bo[buffer].buftype == "" then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
end

return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>e", focus_explorer, desc = "Focus explorer" },
      { "<leader>E", focus_editor, desc = "Focus editor" },
    },
  },
}
