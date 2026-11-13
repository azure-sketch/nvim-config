local M = {}

local function trim(buf)
  if vim.bo[buf].buftype ~= ""
      or not vim.bo[buf].modifiable
      or vim.bo[buf].binary
  then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- 行末の空白・タブを削除する。
  for i, line in ipairs(lines) do
    local trimmed = line:gsub("[ \t]+$", "")
    if trimmed ~= line then
      vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { trimmed })
      lines[i] = trimmed
    end
  end

  -- 末尾の余分な空行を削除し、最後の1行だけ残す。
  local last = #lines
  while last > 1 and lines[last] == "" do
    last = last - 1
  end
  if last < #lines then
    vim.api.nvim_buf_set_lines(buf, last, -1, false, {})
  end

  -- 最終行に改行を付けて書き込む。
  vim.bo[buf].fixeol = true
  vim.bo[buf].endofline = true
end

function M.setup()
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("TrimOnSave", { clear = true }),
    desc = "Trim trailing whitespace and final blank lines",
    callback = function(event)
      trim(event.buf)
    end,
  })
end

return M
