local layout = require("layout")

return {
  {
    "folke/edgy.nvim",

    event = "VeryLazy",

    init = function()
      vim.opt.laststatus = 3
      vim.opt.splitkeep = "screen"
    end,

    opts = function()
      return {
        animate = {
          enabled = false,
        },

        options = {
          left = {
            size = layout.sidebar.width,
          },
        },

        left = require("sidebar").edgy_views(),

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
      }
    end,
  },
}
