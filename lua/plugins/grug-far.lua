return {
  {
    "MagicDuck/grug-far.nvim",
    lazy = false,

    opts = {
      keymaps = {
        -- 割り当てのないAlt+↑↓をInsertモードで押すと、
        -- 既定の <up>/<down> が「前/次の結果を開く」を実行する。
        -- この2つのキーを空にして、プラグイン側で無効にする。
        openNextLocation = { n = "" },
        openPrevLocation = { n = "" },
      },
    },
  },
}
