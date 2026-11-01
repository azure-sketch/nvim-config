local M = {}

local names_by_filetype = {
  ["neo-tree"] = "files",
  ["grug-far"] = "search",
  ["fugitive"] = "git",
}

-- バッファがサイドバーなら種類を返す。
-- Neo-treeはfilesystemだけを対象にする。
function M.name_of(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end

  local ft = vim.bo[buf].filetype
  local name = names_by_filetype[ft]

  if name == "files"
      and vim.b[buf].neo_tree_source ~= "filesystem"
  then
    return nil
  end

  return name
end

-- 指定した種類のサイドバーかを判定する。
function M.is_view(buf, name)
  return M.name_of(buf) == name
end

-- 現在のタブからサイドバーを探す。
-- name省略時は、最初に見つかったサイドバーを返す。
-- 戻り値: win, name。見つからなければnil。
function M.find(name)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local view = M.name_of(buf)

    if view and (name == nil or view == name) then
      return win, view
    end
  end

  return nil
end

return M
