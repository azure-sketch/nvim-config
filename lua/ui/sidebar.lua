local M = {}

local views = require("ui.sidebar.views")

local instance_name = "sidebar-search"

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
        and not views.is_view(buf, "git")
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
  if name ~= "files"
      and name ~= "search"
      and name ~= "git"
  then
    error("Unknown sidebar view: " .. tostring(name))
  end

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

return M
