return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      on_highlights = function(hl, colors)
        require("sidebar.neo_tree_git").highlights(hl, colors)
        require("sidebar.search_highlights").apply(hl)
      end,
    },
  },
}
