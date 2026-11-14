---@type vim.lsp.Config
return {
  settings = {
    typescript = { updateImportsOnFileMove = { enabled = "always" } },
    javascript = { updateImportsOnFileMove = { enabled = "always" } },
    vtsls = { autoUseWorkspaceTsdk = true },
  },
}
