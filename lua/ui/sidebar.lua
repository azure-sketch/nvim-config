local M = {}

local instance_name = "sidebar-search"

local function is_view(buf, name)
  local ft = vim.bo[buf].filetype

  if name == "files" then
    return ft == "neo-tree"
      and vim.b[buf].neo_tree_source == "filesystem"
  end

  if name == "search" then
    return ft == "grug-far"
  end

  if name == "git" then
    return ft == "fugitive"
  end

  return false
end

local function find_view(name)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)

    if is_view(buf, name) then
      return win
    end
  end
end

local function goto_editor()
  require("edgy").goto_main()

  local current = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(current)

  if not is_view(buf, "files") and not is_view(buf, "search") and not is_view(buf, "git") then
    return current
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local b = vim.api.nvim_win_get_buf(win)

    if vim.api.nvim_win_get_config(win).relative == ""
      and vim.bo[b].buftype == ""
      and not is_view(b, "files")
      and not is_view(b, "search")
      and not is_view(buf, "git")
    then
      vim.api.nvim_set_current_win(win)
      return win
    end
  end

  error("サイドバー以外の編集ウィンドウが見つかりません")
end

local function close_views()
  if find_view("files") then
    vim.cmd("Neotree action=close source=filesystem")
  end

  for _, name in ipairs({ "search", "git" }) do
    local win = find_view(name)

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

  local was_visible = find_view(name) ~= nil
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
