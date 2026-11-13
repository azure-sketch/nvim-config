local M = {}

local function is_blank(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  if vim.bo[buf].buftype ~= ""
      or vim.api.nvim_buf_get_name(buf) ~= ""
      or vim.bo[buf].modified
  then
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return #lines <= 1 and (lines[1] or "") == ""
end

-- 起動時に自動で作られた、名前なし・空・未変更のバッファを探す。
local function find_initial()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and is_blank(buf) then
      return buf
    end
  end
end

-- 起動直後の空バッファ(Untitled)だけを記憶し、
-- 名前付きのファイルを開いた後で削除する。
-- Ctrl+N で作った新規バッファは対象にしない。
function M.setup()
  local initial = find_initial()

  if not initial then
    return
  end

  local group = vim.api.nvim_create_augroup(
    "EditorInitialBuffer",
    { clear = true }
  )

  local function stop()
    pcall(vim.api.nvim_del_augroup_by_id, group)
  end

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    desc = "Discard the initial empty buffer after a file is opened",
    callback = function(event)
      -- 名前付きの通常ファイルに入ったときだけ対象にする。
      if event.buf == initial
          or vim.bo[event.buf].buftype ~= ""
          or not vim.bo[event.buf].buflisted
          or vim.api.nvim_buf_get_name(event.buf) == ""
      then
        return
      end

      vim.schedule(function()
        -- 削除済み、または入力済みなら、以後は対象にしない。
        if not is_blank(initial) then
          stop()
          return
        end

        -- まだ表示中なら、次の機会まで待つ。
        if #vim.fn.win_findbuf(initial) > 0 then
          return
        end

        vim.api.nvim_buf_delete(initial, {})
        stop()
      end)
    end,
  })
end

return M
