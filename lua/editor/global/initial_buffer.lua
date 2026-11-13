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
  then
    return false
  end

  local name = vim.api.nvim_buf_get_name(buf)
  return name ~= "" and vim.fn.isdirectory(name) == 0
end

-- いずれかのウィンドウに、名前付きの通常ファイルが表示されているか。
local function has_visible_file()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if is_named_file(vim.api.nvim_win_get_buf(win)) then
      return true
    end
  end

  return false
end

-- `nvim .` の起動直後に現れる空バッファ(Untitled)を記憶し、
-- ウィンドウから外れた時点で、ファイルが表示されていれば削除する。
--
-- Neo-tree はディレクトリを開いた後に空バッファを作るため、
-- setup() 時点では存在しないことがある。BufEnter でも記憶する。
-- 最初のファイルを開いた後に作られたバッファ(Ctrl+N など)は対象にしない。
function M.setup()
  -- ファイルを指定して起動した場合は、起動時の空バッファが無い。
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and is_named_file(buf) then
      return
    end
  end

  local pending = {}
  local settled = false

  local group = vim.api.nvim_create_augroup(
    "EditorInitialBuffer",
    { clear = true }
  )

  local function stop()
    pcall(vim.api.nvim_del_augroup_by_id, group)
  end

  local function remember(buf)
    if vim.bo[buf].buflisted and is_blank(buf) then
      pending[buf] = true
    end
  end

  -- 記憶した空バッファを、条件を満たすときだけ削除する。
  local function sweep(buf)
    if not pending[buf] then
      return
    end

    if not is_blank(buf) then
      -- 入力済み、または削除済みなら、対象から外す。
      pending[buf] = nil
    elseif #vim.fn.win_findbuf(buf) == 0 and has_visible_file() then
      pending[buf] = nil
      settled = true
      pcall(vim.api.nvim_buf_delete, buf, {})
    end

    if next(pending) == nil then
      stop()
    end
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    remember(buf)
  end

  -- 最初のファイルを開くまでの間だけ、空バッファを記憶する。
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    desc = "Remember startup empty buffers",
    callback = function(event)
      if settled then
        return
      end

      if is_named_file(event.buf) then
        settled = true
      else
        remember(event.buf)
      end
    end,
  })

  -- 記憶したバッファがウィンドウから外れたときに、状態を確認して削除する。
  vim.api.nvim_create_autocmd({ "BufWinLeave", "BufHidden" }, {
    group = group,
    desc = "Discard startup empty buffers after a file replaces them",
    callback = function(event)
      local buf = event.buf

      if pending[buf] then
        vim.schedule(function()
          sweep(buf)
        end)
      end
    end,
  })
end

return M
