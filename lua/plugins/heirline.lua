return {
  {
    "rebelot/heirline.nvim",

    opts = function(_, opts)
      opts.winbar = nil
      opts.statusline = require("sidebar.neo_tree_guide").wrap(opts.statusline)
      opts.statusline = require("sidebar.search_guide").wrap(opts.statusline)
    end,
  },
}
