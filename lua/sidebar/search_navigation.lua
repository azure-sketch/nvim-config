local M = {}
local states = {}

local function state(buf)
  if not states[buf] then
    states[buf] = { input = false, request = 0 }
  end
  return states[buf]
end

-- 公開の入力移動APIで記録した位置だけで、入力復帰の可否を判断する。
-- マウス等で別の行へ移動した場合は、自動でInsertにしない。
function M.can_resume_input(buf)
  local s = states[buf]
  return s ~= nil and s.input
    and vim.api.nvim_get_current_buf() == buf
    and vim.api.nvim_get_current_win() == s.win
    and vim.api.nvim_win_get_cursor(0)[1] == s.row
end

local function with_instance(buf, action)
  local ok, instance = pcall(require("grug-far").get_instance, buf)
  if not ok or not instance or not instance:is_valid() then
    return
  end
  instance:when_ready(function()
    if instance:is_valid() and vim.api.nvim_get_current_buf() == buf then
      action(instance)
    end
  end)
end

local function begin_input(buf)
  local s = state(buf)
  s.input = true
  s.request = s.request + 1
  s.win = vim.api.nvim_get_current_win()
  s.row = vim.api.nvim_win_get_cursor(0)[1]
  local request = s.request
  local win = s.win

  vim.schedule(function()
    if states[buf] == s and s.request == request
        and vim.api.nvim_win_is_valid(win)
        and M.can_resume_input(buf)
    then
      vim.cmd("startinsert")
    end
  end)
end

local function leave_input(buf)
  local s = state(buf)
  s.input = false
  s.request = s.request + 1
end

function M.focus_input(buf)
  with_instance(buf, function(instance)
    -- ウィンドウの再配置を済ませてから最終的な入力先を記録する。
    if require("sidebar.search_target").prepare() then
      instance:goto_input("search")
      begin_input(buf)
    end
  end)
end

-- grug-farが既存のunlistedバッファを再利用しても通常ファイルとして扱う。
local function list_result(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local name = vim.api.nvim_buf_get_name(buf)
  if vim.bo[buf].buftype ~= "" or name == ""
      or name:match("^fugitive://") or vim.fn.isdirectory(name) == 1
  then
    return
  end
  vim.bo[buf].buflisted = true
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win)
        and vim.api.nvim_buf_is_valid(buf)
        and vim.api.nvim_win_get_buf(win) == buf
        and vim.bo[buf].buftype == ""
    then
      vim.bo[buf].buflisted = true
    end
  end)
end

function M.setup(buf)
  state(buf)
  local group = vim.api.nvim_create_augroup("SidebarSearchNavigation" .. buf, { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group,
    buffer = buf,
    callback = function()
      local s = states[buf]
      if not s or not s.input then
        return
      end
      if vim.api.nvim_get_current_win() ~= s.win then
        leave_input(buf)
      elseif vim.fn.mode():sub(1, 1) == "i" then
        s.row = vim.api.nvim_win_get_cursor(0)[1]
      elseif vim.api.nvim_win_get_cursor(0)[1] ~= s.row then
        leave_input(buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = buf,
    once = true,
    callback = function()
      states[buf] = nil
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })

  local function bind(modes, key, desc, action)
    vim.keymap.set(modes, key, function()
      with_instance(buf, action)
    end, { buffer = buf, silent = true, nowait = true, desc = desc })
  end

  bind({ "n", "i" }, "<Tab>", "Next search input", function(instance)
    instance:goto_next_input()
    begin_input(buf)
  end)
  bind({ "n", "i" }, "<S-Tab>", "Previous search input", function(instance)
    instance:goto_prev_input()
    begin_input(buf)
  end)
  bind({ "n", "i" }, "<C-Down>", "Focus first search result", function(instance)
    leave_input(buf)
    instance:goto_first_input()
    if instance:goto_next_match({ wrap = false, includeUncounted = false }) then
      vim.cmd("stopinsert")
    else
      begin_input(buf)
    end
  end)

  local function result_move(method)
    return function(instance)
      if M.can_resume_input(buf) then
        return
      end
      leave_input(buf)
      instance[method](instance, { wrap = false, includeUncounted = false })
    end
  end
  bind("n", "<Up>", "Previous search match", result_move("goto_prev_match"))
  bind("n", "<Down>", "Next search match", result_move("goto_next_match"))
  bind({ "n", "i" }, "<C-Up>", "Return to search input", function(instance)
    instance:goto_input("search")
    begin_input(buf)
  end)

  local function target_action(method, options)
    return function(instance)
      if M.can_resume_input(buf) then
        return
      end
      leave_input(buf)
      local target = require("sidebar.search_target")
      if target.prepare() then
        local win = target.editor()
        instance[method](instance, options)
        list_result(win)
      end
    end
  end
  bind("n", "<CR>", "Go to search location", target_action("goto_location"))
  bind("n", "<localleader>o", "Open search location", target_action("open_location"))
  bind("n", "<localleader>j", "Apply next search change", target_action("apply_next_change"))
  bind("n", "<localleader>k", "Apply previous search change", target_action("apply_prev_change"))
end

return M
