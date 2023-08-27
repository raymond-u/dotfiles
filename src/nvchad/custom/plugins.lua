local plugins = {
    {
        "neovim/nvim-lspconfig",
        config = function()
            require "plugins.configs.lspconfig"
            require "custom.configs.lspconfig"
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = require "custom.configs.treesitter",
    },
    {
        "williamboman/mason.nvim",
        opts = require "custom.configs.mason",
    },
}

return plugins
