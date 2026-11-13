local M = {}

local function format_document(resume_input)
  vim.cmd("stopinsert")

  if vim.fn.exists(":Format") ~= 2 then
    vim.notify(
      "AstroNvimのFormatコマンドが利用できません",
      vim.log.levels.WARN
    )
    resume_input()
    return
  end

  local ok, err = pcall(vim.cmd, "Format")

  if not ok then
    vim.notify(tostring(err), vim.log.levels.WARN)
  end

  resume_input()
end

-- キーの割り当ては editor/keymaps.lua にある。
M.document = format_document

return M
