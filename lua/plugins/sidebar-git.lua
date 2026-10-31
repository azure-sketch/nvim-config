return {
  {
    "tpope/vim-fugitive",
    lazy = false,

    keys = {
      {
        "<leader>zm",
        function()
          require("ui.git_merge").open()
        end,
        desc = "Sidebar: Open merge editor",
      },
      {
        "<leader>zd",
        function()
          local current = vim.api.nvim_get_current_win()

          if not vim.wo[current].diff then
            vim.notify("差分表示中の作業ファイルで実行してください")
            return
          end

          local buf = vim.api.nvim_win_get_buf(current)
          local name = vim.api.nvim_buf_get_name(buf)

          if vim.bo[buf].buftype ~= ""
              or name:match("^fugitive://")
          then
            vim.notify("右側の作業ファイルへ移動して実行してください")
            return
          end

          local targets = {}

          for _, win in ipairs(
            vim.api.nvim_tabpage_list_wins(0)
          ) do
            if win ~= current and vim.wo[win].diff then
              local other = vim.api.nvim_win_get_buf(win)

              if vim.bo[other].modified then
                vim.notify(
                  "比較側に未保存の変更があります。保存・確認してから閉じてください",
                  vim.log.levels.WARN
                )
                return
              end

              table.insert(targets, win)
            end
          end

          for _, win in ipairs(targets) do
            vim.api.nvim_win_close(win, false)
          end

          vim.api.nvim_set_current_win(current)
          vim.cmd("diffoff")
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

      require("ui.git_diff").setup()
    end,
  },
}
