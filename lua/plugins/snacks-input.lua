return {
  "folke/snacks.nvim",
  opts = {
    styles = {
      input = {
        keys = {
          -- 入力中でも、Escを1回でキャンセルする。
          i_esc = {
            "<Esc>",
            "cancel",
            mode = "i",
            expr = false,
          },

          -- 通常モード側もキャンセルに統一する。
          n_esc = {
            "<Esc>",
            "cancel",
            mode = "n",
            expr = false,
          },
        },
      },
    },
  },
}
