vim.api.nvim_create_autocmd("FileType", {
  pattern = { "DiffviewFiles", "DiffviewFileHistory" },
  callback = function(event)
    vim.keymap.set("n", "q", "<cmd>DiffviewClose<cr>", { buffer = event.buf, desc = "Close diff view" })
  end,
})
