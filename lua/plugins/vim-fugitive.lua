return {
  {
    "tpope/vim-fugitive",
    lazy = false,

    keys = {
      {
        "<leader>zm",
        function()
          require("sidebar.git_merge").open()
        end,
        desc = "Sidebar: Open merge editor",
      },
      {
        "<leader>zd",
        function()
          require("sidebar.git_diff").close()
        end,
        desc = "Sidebar: Close diff, keep working file",
      },
    },

    init = function()
      require("sidebar.git").setup()
    end,
  },
}
