local layout = require("layout")

return {
  {
    "folke/edgy.nvim",

    event = "VeryLazy",

    init = function()
      vim.opt.laststatus = 3
      vim.opt.splitkeep = "screen"
    end,

    opts = {
      animate = {
        enabled = false,
      },

      options = {
        left = {
          size = layout.sidebar.width,
        },
      },

      left = {
        {
          title = "Files",
          wo = { winbar = " Files%= ?:Help " },
          ft = "neo-tree",
          filter = function(buf)
            return vim.b[buf].neo_tree_source == "filesystem"
          end,
        },
        {
          title = "Search",
          wo = { winbar = " Search%= F1:Help " },
          ft = "grug-far",
        },
        {
          title = "Git",
          wo = { winbar = " Git%= g?:Help " },
          ft = "fugitive",
        },
      },

      bottom = {
        {
          ft = "snacks_terminal",
          size = { height = layout.terminal.height },
          title = "Terminal",
          filter = function(_, win)
            return vim.w[win].snacks_win
                and vim.w[win].snacks_win.position == "bottom"
                and vim.w[win].snacks_win.relative == "editor"
          end,
        },
      },
    },
  },
}
