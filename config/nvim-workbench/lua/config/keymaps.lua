local map = vim.keymap.set

map("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Git status / operations" })
map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Diff working tree" })
map("n", "<leader>gD", "<cmd>DiffviewClose<cr>", { desc = "Close diff view" })
map("n", "<leader>gm", "<cmd>DiffviewOpen<cr>", { desc = "Resolve merge / rebase" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "Current file history" })
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "Repository history" })
map("n", "<leader>gb", function()
  require("gitsigns").blame_line({ full = true })
end, { desc = "Git blame line" })
