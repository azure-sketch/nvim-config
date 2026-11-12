local M = {}

local keymap = require("keymap")
local bindings = require("bindings")

function M.setup(resume_input)
  local actions = {}

  actions.quick_open = function()
    vim.cmd("stopinsert")

    local ok, picker = pcall(require, "snacks.picker")
    if ok then
      picker.files()
      return
    end

    vim.notify(
      "Snacks Picker が見つかりません",
      vim.log.levels.WARN
    )
    resume_input()
  end

  bindings.apply("quick_open", actions.quick_open)

  keymap.set({ "n", "i", "s", "x" }, "<C-S-p>", "<Esc>:", {
    desc = "Command line",
  })

  return actions
end

return M
