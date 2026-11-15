---@type LazySpec
return {
  "mrcjkb/rustaceanvim",
  -- 破壊的変更に備えてメジャーバージョンを固定する
  version = "^9",
  -- プラグイン自身が遅延初期化するため、lazy.nvim による遅延は不要
  lazy = false,
  init = function()
    vim.g.rustaceanvim = {
      tools = {
        -- テストをバックグラウンドで実行し、失敗を診断として表示する
        test_executor = "background",
      },
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            -- 保存時のチェックに clippy を使う
            check = { command = "clippy" },
          },
        },
      },
    }
  end,
}
