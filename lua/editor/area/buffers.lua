local M = {}

-- 名前付きの通常ファイル、または変更済みの無名バッファが残っているか。
local function has_file_buffer()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and vim.bo[buf].buftype == "" then
      if vim.api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified then
        return true
      end
    end
  end

  return false
end

function M.close()
  local ok, err = pcall(function()
    require("astrocore.buffer").close()
  end)

  if not ok then
    vim.notify(tostring(err), vim.log.levels.WARN)
    return
  end

  -- 閉じた結果ファイルが1つも残らないときだけ、起動画面を表示する。
  vim.schedule(function()
    if not has_file_buffer() then
      require("editor.global.dashboard").show()
    end
  end)
end

return M
