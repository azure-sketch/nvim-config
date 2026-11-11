local M = {}

local keymap = require("keymap")

local bindings = {
  undo = {
    lhs = "<C-z>",
    desc = "Undo",
  },
  redo = {
    lhs = "<C-y>",
    desc = "Redo",
  },
}

function M.attach(buf)
  local map = keymap.for_buffer(buf)

  local function register(modes, undo_rhs, redo_rhs)
    map(modes, bindings.undo.lhs, undo_rhs, bindings.undo.desc)
    map(modes, bindings.redo.lhs, redo_rhs, bindings.redo.desc)
  end

  register("i", "<C-o>u", "<C-o><C-r>")
  register("n", "u", "<C-r>")
  register({ "s", "x" }, "<Esc>u", "<Esc><C-r>")
end

return M
