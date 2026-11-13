return {
  name = "git",
  key = "<C-S-g>",
  desc = "Focus Git sidebar",

  match = function(buf)
    return vim.bo[buf].filetype == "fugitive"
  end,

  open = function()
    vim.cmd("Git")
  end,

  -- edgy.nvim 用の表示情報。
  edgy = { title = "Git", help = "g?:Help", ft = "fugitive" },

  setup = function()
    local group = vim.api.nvim_create_augroup("SidebarGitBuffer", { clear = true })

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
}
