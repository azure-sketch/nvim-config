return {
  name = "files",
  key = "<C-S-e>",
  desc = "Focus files sidebar",

  -- Neo-treeはfilesystemだけを対象にする。
  match = function(buf)
    return vim.bo[buf].filetype == "neo-tree"
      and vim.b[buf].neo_tree_source == "filesystem"
  end,

  open = function()
    vim.cmd("Neotree action=focus source=filesystem position=left")
  end,

  close = function()
    vim.cmd("Neotree action=close source=filesystem")
  end,
}
