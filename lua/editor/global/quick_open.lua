local M = {}

-- ファイル検索（Snacks Picker）を開く。
-- キーの割り当ては editor/keymaps.lua にある。
function M.open(resume_input)
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

return M
