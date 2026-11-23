-- カラーコードの横に色見本(■)を表示する。文字の背景は塗らない。
-- 対象: hex / rgb / hsl / CSS変数 / Tailwind(LSPのdocumentColor)。
return {
  "brenoprata10/nvim-highlight-colors",
  event = "VeryLazy",
  opts = {
    render = "virtual",
    virtual_symbol = "■", -- 丸にするなら "●"
    virtual_symbol_position = "inline", -- 値の左にVS Code風に表示
    virtual_symbol_prefix = "",
    virtual_symbol_suffix = " ",
    enable_named_colors = true,
    enable_tailwind = true,
  },
  config = function(_, opts)
    -- Neovim標準のdocument_color(既定は背景塗り)と二重表示になるため無効化する。
    if vim.lsp.document_color then
      vim.lsp.document_color.enable(false)
    end
    require("nvim-highlight-colors").setup(opts)
  end,
}
