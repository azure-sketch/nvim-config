local M = {}

local keymap = require("ui.vscode.keymap")

local bindings = {
  quick_open = {
    lhs = "<C-p>",
    modes = { "n", "i", "s", "x" },
    desc = "Quick open file",
  },
  toggle_sidebar = {
    lhs = "<C-b>",
    modes = { "n", "i", "s", "x" },
    desc = "Toggle sidebar visibility",
  },
}

local function binding_of(name)
  return assert(
    bindings[name],
    "Unknown workspace binding: " .. tostring(name)
  )
end

-- プラグイン固有の設定テーブルへ登録するときに使う。
function M.lhs(name)
  return binding_of(name).lhs
end

-- Neovimのキーマップとして直接登録するときに使う。
function M.apply(name, callback, opts)
  local binding = binding_of(name)

  local options = vim.tbl_extend("force", {}, opts or {})
  local modes = options.modes or binding.modes

  options.modes = nil
  options.desc = binding.desc

  keymap.set(modes, binding.lhs, callback, options)
end

return M
