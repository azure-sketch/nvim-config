---@type LazySpec
return {
  "AstroNvim/astrolsp",

  ---@type AstroLSPOpts
  opts = {
    -- 有効にする言語サーバー（サーバー固有の設定は after/lsp/ に置く）
    servers = { "vtsls" },

    -- LSP のファイル操作通知（import 自動更新などに必要）
    file_operations = {
      operations = {
        dynamicRegistration = true,
        willRename = true,
        didRename = true,
        willCreate = true,
        didCreate = true,
        willDelete = true,
        didDelete = true,
      },
    },
  },
}
