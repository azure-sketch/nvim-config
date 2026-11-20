return {
  {
    "MagicDuck/grug-far.nvim",
    lazy = false,

    opts = {
      helpLine = { enabled = false },
      centerOnNavigation = false,
      engines = {
        ripgrep = {
          defaults = { flags = "--fixed-strings --ignore-case" },
        },
      },
      -- 公開設定で元の編集窓を使用。非公開scratchフラグは参照しない。
      openTargetWindow = { preferredLocation = "prev", useScratchBuffer = false },
      keymaps = {
        -- 文字入力と競合しないよう、Insert / Normal で同じキーを使う。
        replace = "<C-M-CR>",
        -- 割り当てのないAlt+↑↓から前後の結果を開かないようにする。
        openNextLocation = { n = "" },
        openPrevLocation = { n = "" },
      },
    },
  },
}
