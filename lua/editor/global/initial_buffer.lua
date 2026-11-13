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

-- 名前付きの通常ファイルか判定する。ディレクトリのバッファは含めない。
local function is_named_file(buf)
  if not vim.api.nvim_buf_is_valid(buf)
      or vim.bo[buf].buftype ~= ""
      or not vim.bo[buf].buflisted
  then
    return false
  end

  local name = vim.api.nvim_buf_get_name(buf)
  return name ~= "" and vim.fn.isdirectory(name) == 0
end

-- `nvim .` の起動直後に現れる空バッファ(Untitled)を記憶し、
-- 最初に名前付きファイルを開いた後で削除する。
--
-- Neo-tree はディレクトリを開いた後に空バッファを作るため、
-- setup() 時点では存在しないことがある。BufEnter でも記憶する。
-- 最初のファイルを開いた後に作られたバッファ(Ctrl+N など)は対象にしない。
function M.setup()
  -- ファイルを指定して起動した場合は、起動時の空バッファが無い。
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_named_file(buf) then
      return
    end
  end

  local pending = {}
  local settled = false

  local function remember(buf)
    if vim.bo[buf].buflisted and is_blank(buf) then
      pending[buf] = true
    end
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    remember(buf)
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
    desc = "Discard startup empty buffers after the first file is opened",
    callback = function(event)
      if not is_named_file(event.buf) then
        if not settled then
          remember(event.buf)
        end
        return
      end

      settled = true

      vim.schedule(function()
        for buf in pairs(pending) do
          if not is_blank(buf) then
            -- 入力済み、または削除済みなら対象から外す。
            pending[buf] = nil
          elseif #vim.fn.win_findbuf(buf) == 0 then
            pending[buf] = nil
            pcall(vim.api.nvim_buf_delete, buf, {})
          end
          -- 表示中なら、次のファイルを開いたときまで待つ。
        end

        if next(pending) == nil then
          stop()
        end
      end)
    end,
  })
end

return M
