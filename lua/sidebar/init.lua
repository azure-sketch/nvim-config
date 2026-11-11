local M = {}

local views = require("sidebar.views")

local instance_name = "sidebar-search"
local last_view = "files"

local function validate_name(name)
  if name ~= "files"
      and name ~= "search"
      and name ~= "git"
  then
    error("Unknown sidebar view: " .. tostring(name))
  end
end

local function goto_editor()
  require("edgy").goto_main()

  local current = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(current)

  if not views.is_view(buf, "files") and not views.is_view(buf, "search") and not views.is_view(buf, "git") then
    return current
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local b = vim.api.nvim_win_get_buf(win)

    if vim.api.nvim_win_get_config(win).relative == ""
        and vim.bo[b].buftype == ""
        and not views.is_view(b, "files")
        and not views.is_view(b, "search")
        and not views.is_view(b, "git")
    then
      vim.api.nvim_set_current_win(win)
      return win
    end
  end

  error("サイドバー以外の編集ウィンドウが見つかりません")
end

local function close_views()
  if views.find("files") then
    vim.cmd("Neotree action=close source=filesystem")
  end

  for _, name in ipairs({ "search", "git" }) do
    local win = views.find(name)

    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, false)
    end
  end
end

local function open_search()
  local grug = require("grug-far")

  if grug.has_instance(instance_name) then
    grug.get_instance(instance_name):open()
  else
    grug.open({
      instanceName = instance_name,
      staticTitle = "Search",
    })
  end
end

function M.toggle(name)
  validate_name(name)
  last_view = name

  local was_visible = views.find(name) ~= nil
  local editor = goto_editor()

  close_views()

  if vim.api.nvim_win_is_valid(editor) then
    vim.api.nvim_set_current_win(editor)
  end

  if was_visible then
    return
  end

  if name == "files" then
    vim.cmd(
      "Neotree action=focus source=filesystem position=left"
    )
  elseif name == "search" then
    open_search()
  else
    vim.cmd("Git")
  end
end

-- イベント対象のバッファがサイドバーなら、その種類を記憶する。
function M.remember_buffer(buf)
  local name = views.name_of(buf)

  if name then
    last_view = name
  end
end

-- 現在表示されているサイドバーの種類を記憶する。
function M.remember_visible()
  local _, name = views.find()

  if name then
    last_view = name
  end
end

-- 表示中なら閉じ、非表示なら最後に使った種類を開く。
-- 編集領域への復帰は呼び出し側が担当する。
function M.toggle_last()
  local _, name = views.find()
  M.toggle(name or last_view)
end

-- 指定したサイドバーへフォーカスする。
-- 表示中の場合は閉じず、非表示の場合だけ開く。
function M.focus(name)
  validate_name(name)

  vim.cmd("stopinsert")
  last_view = name

  local win = views.find(name)

  if win then
    vim.api.nvim_set_current_win(win)
  else
    M.toggle(name)
  end

  -- 検索画面では、そのまま入力できる状態にする。
  if name == "search" then
    local buf = vim.api.nvim_get_current_buf()

    if vim.bo[buf].filetype == "grug-far"
        and vim.bo[buf].modifiable
    then
      vim.cmd("startinsert")
    end
  end
end

-- 表示中のサイドバー、なければ最後に使った種類へフォーカスする。
function M.focus_last()
  local _, name = views.find()
  M.focus(name or last_view)
end

return M
