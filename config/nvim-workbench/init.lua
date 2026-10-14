require("config.lazy")

-- Share the host's Python completion and Zellij-friendly shortcuts.
dofile(vim.fn.expand("~/.config/nvim/lua/python_lsp.lua"))
