---@type LazySpec
return {
  "AstroNvim/astrolsp",

  ---@type AstroLSPOpts
  opts = {
    -- 有効にする言語サーバー（サーバー固有の設定は after/lsp/ に置く）
    -- eslint・biome は、プロジェクトに設定ファイルがあるときだけ起動する（nvim-lspconfig の root_dir）
    servers = { "vtsls", "eslint", "biome" },

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

    -- 整形は Biome だけが担当する。保存時の整形（既定の有効）は変更しない。
    formatting = {
      disabled = { "vtsls", "eslint" },
    },
  },
}
