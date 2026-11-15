---@type LazySpec
return {
  "saecki/crates.nvim",
  event = "BufRead Cargo.toml",
  ---@type crates.UserConfig
  opts = {
    -- Cargo.toml を開いたら、依存の最新バージョンを自動で表示する（autoload の既定値）
    -- 補完・ホバー・コードアクションは LSP として提供する。補完は blink.cmp の lsp ソースに出る
    lsp = {
      enabled = true,
      actions = true,
      completion = true,
      hover = true,
    },
  },
}
