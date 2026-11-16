-- SchemaStore のスキーマを yamlls に渡す。プラグインは lazy なので、読み込んでから使う。
require("lazy").load { plugins = { "schemastore.nvim" } }

---@type vim.lsp.Config
return {
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      -- 内蔵の SchemaStore 取得は止め、schemastore.nvim に一本化する
      schemaStore = { enable = false, url = "" },
      schemas = require("schemastore").yaml.schemas(),
      validate = true,
    },
  },
}
