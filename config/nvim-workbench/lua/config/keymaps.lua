local map = vim.keymap.set

map("n", "<C-z>", "u", { desc = "Undo" })
map("i", "<C-z>", "<C-o>u", { desc = "Undo" })

map("n", "<leader>ac", function()
  require("config.codex").open()
end, { desc = "Codex for current file" })
for _, key in ipairs({ "]w", "[w" }) do
  map("n", key, function()
    require("config.codex").toggle_focus()
  end, { desc = "Switch file / Codex" })
end

map("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Git status / operations" })
map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Diff working tree" })
map("n", "<leader>gD", "<cmd>DiffviewClose<cr>", { desc = "Close diff view" })
map("n", "<leader>gm", "<cmd>DiffviewOpen<cr>", { desc = "Resolve merge / rebase" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "Current file history" })
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "Repository history" })
map("n", "<leader>gb", function()
  require("gitsigns").blame_line({ full = true })
end, { desc = "Git blame line" })
