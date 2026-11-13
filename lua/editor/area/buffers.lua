local M = {}

function M.close()
  local ok, err = pcall(function()
    require("astrocore.buffer").close()
  end)

  if not ok then
    vim.notify(tostring(err), vim.log.levels.WARN)
  end
end

return M
