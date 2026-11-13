-- フォーカス喪失・バッファ離脱時に、変更済みの通常ファイルを自動保存する。
-- 保存時の BufWritePre(global/trim.lua)を発火させるため、nested = true にする。
local M = {}

function M.setup()
  vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
    group = vim.api.nvim_create_augroup("EditorAutoSave", { clear = true }),
    desc = "Save the current modified file buffer",
    nested = true,
    callback = function(event)
      local buf = event.buf
      if vim.bo[buf].buftype == ""
          and vim.bo[buf].modifiable
          and vim.bo[buf].modified
          and vim.api.nvim_buf_get_name(buf) ~= ""
      then
        vim.api.nvim_buf_call(buf, function() vim.cmd "silent! update" end)
      end
    end,
  })
end

return M
