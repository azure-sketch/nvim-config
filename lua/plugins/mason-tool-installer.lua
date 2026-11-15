---@type LazySpec
return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  optional = true,
  opts = function(_, opts)
    -- biome はプロジェクトごとの node_modules を使うので、Mason では入れない
    -- rust-analyzer は rustup 版を使うので、Mason では入れない
    opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed or {}, {
      "vtsls",
      "eslint-lsp",
      "json-lsp",
      "taplo",
      "astro-language-server",
      "html-lsp",
      "css-lsp",
      "tailwindcss-language-server",
    })
  end,
}
