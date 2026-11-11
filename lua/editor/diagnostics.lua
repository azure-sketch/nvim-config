local M = {}

local keymap = require("editor.keymap")

local function show_problems(resume_input)
  vim.cmd("stopinsert")

  local ok, picker = pcall(require, "snacks.picker")

  if not ok then
    vim.notify(
      "Snacks Pickerが見つかりません",
      vim.log.levels.WARN
    )
    resume_input()
    return
  end

  picker.diagnostics()
end

function M.attach(buf, resume_input)
  local map = keymap.for_buffer(buf)

  map({ "n", "i" }, "<C-S-m>", function()
    show_problems(resume_input)
  end, "Show problems")
end

return M
