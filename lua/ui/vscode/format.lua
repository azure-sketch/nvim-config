local M = {}

local keymap = require("ui.vscode.keymap")

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

function M.attach(buf, resume_input)
  local map = keymap.for_buffer(buf)

  map({ "n", "i" }, "<A-S-f>", function()
    format_document(resume_input)
  end, "Format document")
end

return M
