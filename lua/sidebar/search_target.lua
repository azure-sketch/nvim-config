local M = {}
local views = require("sidebar.views")

local instance
local bound_win
local busy = false
local queued = false
local clock = 0
local recent = {}

local function is_editor(win)
  if not vim.api.nvim_win_is_valid(win)
      or vim.api.nvim_win_get_tabpage(win) ~= vim.api.nvim_get_current_tabpage()
      or vim.api.nvim_win_get_config(win).relative ~= ""
  then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  if views.name_of(buf) then
    return false
  end
  return vim.bo[buf].filetype == "snacks_dashboard"
    or (vim.bo[buf].buftype == ""
      and not vim.api.nvim_buf_get_name(buf):match("^fugitive://"))
end

-- 通常ファイルと起動画面を対象に、現在または最後に操作した編集窓を選ぶ。
function M.editor()
  local current = vim.api.nvim_get_current_win()
  if is_editor(current) then
    return current
  end
  local best
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_editor(win)
        and (not best or (recent[win] or 0) > (recent[best] or 0))
    then
      best = win
    end
  end
  return best
end

local function search_window()
  if not instance or not instance:is_valid() then
    return
  end
  local buf = instance:get_buf()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

local function rebind(target)
  local old_search = search_window()
  if not old_search or target == bound_win then
    return
  end
  local origin = vim.api.nvim_get_current_win()
  local return_to_search = origin == old_search
  local was_insert = vim.fn.mode():sub(1, 1) == "i"
  local view = vim.api.nvim_win_call(old_search, vim.fn.winsaveview)

  instance:hide()
  target = is_editor(target) and target or M.editor()
  if not target then
    error("検索結果の表示先となる編集ウィンドウがありません")
  end
  vim.api.nvim_set_current_win(target)
  instance:open()
  bound_win = target
  local new_search = search_window()
  if new_search then
    vim.api.nvim_win_call(new_search, function()
      vim.fn.winrestview(view)
    end)
  end
  if not return_to_search and vim.api.nvim_win_is_valid(origin) then
    vim.api.nvim_set_current_win(origin)
  end
  if was_insert then
    vim.cmd("startinsert")
  end
end

-- 再配置に失敗しても、可能なら検索を再表示してフォーカスを戻す。
local function guarded(action)
  if busy then
    return
  end
  busy = true
  local origin = vim.api.nvim_get_current_win()
  local ok, result = xpcall(action, debug.traceback)
  if not ok then
    pcall(function()
      if instance and instance:is_valid() and not instance:is_open() then
        local target = M.editor()
        if target then
          vim.api.nvim_set_current_win(target)
          instance:open()
          bound_win = target
        end
      end
      if vim.api.nvim_win_is_valid(origin) then
        vim.api.nvim_set_current_win(origin)
      end
    end)
  end
  busy = false
  if not ok then
    vim.notify(result, vim.log.levels.ERROR, { title = "Search target" })
    return false
  end
  return true, result
end

-- キー操作からも同期的に確認し、予約処理待ちの表示先を更新する。
function M.prepare()
  local target = M.editor()
  if not target or not search_window() then
    return false
  end
  if target == bound_win then
    return true
  end
  return guarded(function()
    rebind(target)
  end)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("SidebarSearchTarget", { clear = true })
  vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "WinClosed", "TabEnter" }, {
    group = group,
    desc = "Follow the last editor using public search APIs",
    callback = function()
      if busy then
        return
      end
      local current = vim.api.nvim_get_current_win()
      if is_editor(current) then
        clock = clock + 1
        recent[current] = clock
      end
      if queued then
        return
      end
      queued = true
      vim.schedule(function()
        queued = false
        M.prepare()
      end)
    end,
  })
end

function M.open(options)
  return guarded(function()
    local target = M.editor()
    if not target then
      error("サイドバー以外の編集ウィンドウが見つかりません")
    end
    local grug = require("grug-far")
    if grug.has_instance(options.instanceName) then
      instance = grug.get_instance(options.instanceName)
      if search_window() then
        rebind(target)
        instance:open()
      else
        vim.api.nvim_set_current_win(target)
        instance:open()
        bound_win = target
      end
    else
      vim.api.nvim_set_current_win(target)
      instance = grug.open(options)
      bound_win = target
    end
    clock = clock + 1
    recent[target] = clock
  end)
end

return M
