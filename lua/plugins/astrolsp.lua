---@type LazySpec
return {
  "AstroNvim/astrolsp",

  ---@type AstroLSPOpts
  opts = {
    -- 有効にする言語サーバー（サーバー固有の設定は after/lsp/ に置く）
    -- eslint・biome は、プロジェクトに設定ファイルがあるときだけ起動する（nvim-lspconfig の root_dir）
    -- Rust の rust-analyzer は rustaceanvim が起動するので、ここには書かない
    servers = { "vtsls", "eslint", "biome", "jsonls", "taplo", "astro", "html", "cssls", "tailwindcss", "bashls", "yamlls" },

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

    -- 整形を担当するサーバー
    --   JS/TS: Biome のみ
    --   astro: Biome のみ（html.experimentalFullSupportEnabled が必要。astro サーバーは Prettier がないため使わない）
    --   html: html サーバーのみ（Biome は整形しない）
    --   css・JSON: Biome が接続していれば Biome、なければ cssls・jsonls
    -- 保存時の整形（既定の有効）は変更しない。
    formatting = {
      disabled = { "vtsls", "eslint" },
      filter = function(client)
        local bufnr = vim.api.nvim_get_current_buf()
        local filetype = vim.bo[bufnr].filetype
        if filetype == "astro" then return client.name == "biome" end
        if filetype == "html" then return client.name == "html" end
        if client.name == "jsonls" or client.name == "cssls" then
          return #vim.lsp.get_clients { bufnr = bufnr, name = "biome" } == 0
        end
        return true
      end,
    },
  },
}
