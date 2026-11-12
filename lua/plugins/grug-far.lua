return {
  {
    "MagicDuck/grug-far.nvim",
    lazy = false,

    init = function()
      require("sidebar.search").setup()
    end,

    opts = {},
  },
}
