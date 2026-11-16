local M = {}

local function move_match(command)
  local ok, err = pcall(vim.cmd, command)

  if not ok then
    vim.notify(tostring(err), vim.log.levels.INFO)
  end
end

function M.next_match()
  move_match("normal! n")
end

function M.prev_match()
  move_match("normal! N")
end

return M
