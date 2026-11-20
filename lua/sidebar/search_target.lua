local M = {}

local installed = false

-- 起動画面だけが編集領域に残っている場合、そのウィンドウを返す。
local function find_dashboard_target(search_buf)
  local search_win = vim.fn.bufwinid(search_buf)

  if search_win == -1 or not vim.api.nvim_win_is_valid(search_win) then
    return
  end

  local tab = vim.api.nvim_win_get_tabpage(search_win)
  local dashboard_win

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    if win ~= search_win
        and vim.api.nvim_win_get_config(win).relative == ""
    then
      local buf = vim.api.nvim_win_get_buf(win)

      if vim.bo[buf].filetype == "snacks_dashboard" then
        dashboard_win = dashboard_win or win
      elseif vim.bo[buf].buftype == ""
          or vim.b[buf].__grug_far_scratch_buf
      then
        -- 編集先が既にあれば、grug-far の通常の選択処理を維持する。
        return
      end
    end
  end

  return dashboard_win
end

function M.setup()
  if installed then
    return
  end

  local utils = require("grug-far.utils")
  local original = utils.getOpenTargetWin

  utils.getOpenTargetWin = function(context, buf)
    if context.options.instanceName == "sidebar-search" then
      local win = find_dashboard_target(buf)

      if win then
        return win, false
      end
    end

    return original(context, buf)
  end

  installed = true
end

return M
