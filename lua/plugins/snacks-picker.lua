return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      win = {
        input = {
          keys = {
            -- 入力中でもEscを1回で閉じる。
            ["<Esc>"] = {
              "close",
              mode = { "n", "i" },
            },

            -- 検索語の入力状態を維持して候補を移動。
            ["<Down>"] = {
              "list_down",
              mode = { "n", "i" },
            },
            ["<Up>"] = {
              "list_up",
              mode = { "n", "i" },
            },

            ["<CR>"] = {
              "confirm",
              mode = { "n", "i" },
            },
          },
        },

        list = {
          keys = {
            ["<Esc>"] = {
              "close",
              mode = { "n", "i" },
            },
          },
        },
      },
    },
  },
}
