-- SchemaStore のスキーマを jsonls に渡す。プラグインは lazy なので、読み込んでから使う。
require("lazy").load { plugins = { "schemastore.nvim" } }

---@type vim.lsp.Config
return {
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
}
