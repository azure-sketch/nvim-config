local M = {}

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

-- キーの割り当ては editor/keymaps.lua にある。
M.show = show_problems

return M
