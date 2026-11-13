-- Neo-treeはfilesystemだけを対象にする。
local function is_filesystem(buf)
  return vim.bo[buf].filetype == "neo-tree"
    and vim.b[buf].neo_tree_source == "filesystem"
end

return {
  name = "files",
  key = "<C-S-e>",
  desc = "Focus files sidebar",

  match = is_filesystem,

  open = function()
    vim.cmd("Neotree action=focus source=filesystem position=left")
  end,

  close = function()
    vim.cmd("Neotree action=close source=filesystem")
  end,

  -- edgy.nvim 用の表示情報。
  edgy = {
    title = "Files",
    help = "?:Help",
    ft = "neo-tree",
    filter = is_filesystem,
  },
}
