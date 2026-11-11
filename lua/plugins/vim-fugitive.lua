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
      local group = vim.api.nvim_create_augroup(
        "SidebarGitBuffer",
        { clear = true }
      )

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "fugitive",
        callback = function(event)
          vim.bo[event.buf].buflisted = false
        end,
      })

      vim.api.nvim_create_autocmd("BufWinEnter", {
        group = group,
        pattern = "fugitive://*",
        callback = function(event)
          vim.bo[event.buf].buflisted = false
          vim.cmd("redrawtabline")
        end,
      })

      require("sidebar.git_diff").setup()
    end,
  },
}
