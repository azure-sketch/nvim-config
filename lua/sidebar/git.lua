local M = {}

function M.setup()
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
end

return M
