local lspconfig = require "lspconfig"
local configs = require "plugins.configs.lspconfig"

local on_attach = configs.on_attach
local capabilities = configs.capabilities

lspconfig.bashls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
}

lspconfig.jsonls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
}

lspconfig.lua_ls.setup {
    on_attach = on_attach,
    capabilities = capabilities,

    settings = {
        Lua = {
            telemetry = {
                enable = false
            }
        }
    }
}

lspconfig.marksman.setup {
    on_attach = on_attach,
    capabilities = capabilities,
}

lspconfig.pyright.setup {
    on_attach = on_attach,
    capabilities = capabilities,
}

lspconfig.rust_analyzer.setup {
    on_attach = on_attach,
    capabilities = capabilities,

    settings = {
        ['rust-analyzer'] = {
            diagnostics = {
                enable = false
            }
        }
    }
}
