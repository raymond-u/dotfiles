return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },
  {
  	"nvim-treesitter/nvim-treesitter",
  	opts = require "configs.treesitter",
  },
  {
  	"williamboman/mason.nvim",
  	opts = require "configs.mason",
  },
}
