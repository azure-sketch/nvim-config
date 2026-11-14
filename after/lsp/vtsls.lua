---@type vim.lsp.Config
return {
  settings = {
    typescript = {
      updateImportsOnFileMove = { enabled = "always" },
      -- 型エラーなどの診断メッセージを日本語で表示する
      locale = "ja",
    },
    javascript = { updateImportsOnFileMove = { enabled = "always" } },
    vtsls = { autoUseWorkspaceTsdk = true },
  },
}
