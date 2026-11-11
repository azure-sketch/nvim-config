local M = {}

local keymap = require("ui.vscode.keymap")

local function snapshot_buffers()
  local existing = {}

  for _, id in ipairs(vim.api.nvim_list_bufs()) do
    existing[id] = true
  end

  return existing
end

-- 無名ファイルの保存によって新しく発生した、
-- 空の補助バッファだけを一覧から外す。
--
-- 保存対象のnvim_buf_call()内から呼び出し、
-- alternate bufferの取得元を従来どおり維持する。
local function unlist_empty_alternate(target, existing)
  local alternate = vim.fn.bufnr("#")

  if alternate < 1
      or alternate == target
      or existing[alternate]
      or not vim.api.nvim_buf_is_valid(alternate)
  then
    return
  end

  -- 名前なし・未変更・非表示の通常バッファだけを対象にする。
  if vim.api.nvim_buf_get_name(alternate) ~= ""
      or vim.bo[alternate].buftype ~= ""
      or vim.bo[alternate].modified
      or #vim.fn.win_findbuf(alternate) > 0
  then
    return
  end

  -- 読み込み済みなら、本文が空であることも確認する。
  if vim.api.nvim_buf_is_loaded(alternate) then
    local lines = vim.api.nvim_buf_get_lines(
      alternate, 0, -1, false
    )

    if #lines > 1
        or (#lines == 1 and lines[1] ~= "")
    then
      return
    end
  end

  -- 削除はせず、上部のファイル一覧からだけ外す。
  vim.bo[alternate].buflisted = false
end

local function save_as_target(target, path)
  vim.api.nvim_buf_call(target, function()
    -- スナップショットは、保存対象のコンテキストで
    -- saveasを実行する直前に取得する。
    local existing = snapshot_buffers()
    local was_unnamed = vim.api.nvim_buf_get_name(target) == ""

    vim.cmd(
      "saveas " .. vim.fn.fnameescape(path)
    )

    if not was_unnamed then
      return
    end

    unlist_empty_alternate(target, existing)
  end)
end

local function save_as(resume_input)
  local target = vim.api.nvim_get_current_buf()

  if vim.bo[target].buftype ~= "" then
    vim.notify(
      "通常の編集ファイルで実行してください",
      vim.log.levels.INFO
    )
    return
  end

  local name = vim.api.nvim_buf_get_name(target)
  local default = name ~= ""
      and name
      or (vim.fn.getcwd() .. "/")

  vim.ui.input({
    prompt = "名前を付けて保存: ",
    default = default,
    completion = "file",
  }, function(path)
    if not path or path == "" then
      resume_input()
      return
    end

    if not vim.api.nvim_buf_is_valid(target) then
      return
    end

    local ok, err = pcall(function()
      save_as_target(target, path)
    end)

    if not ok then
      vim.notify(tostring(err), vim.log.levels.WARN)
    end

    resume_input()
  end)
end

local function save(resume_input)
  if vim.bo.filetype == "grug-far" then
    vim.notify(
      "検索・置換画面では Ctrl+S で保存しません",
      vim.log.levels.INFO
    )
    return
  end

  if vim.api.nvim_buf_get_name(0) == "" then
    save_as(resume_input)
    return
  end

  local ok, err = pcall(vim.cmd, "write")

  if not ok then
    vim.notify(tostring(err), vim.log.levels.WARN)
  end
end

function M.attach(buf, resume_input)
  local map = keymap.for_buffer(buf)

  map({ "n", "i", "s", "x" }, "<C-s>", function()
    save(resume_input)
  end, "Save file")

  map({ "n", "i" }, "<C-S-s>", function()
    save_as(resume_input)
  end, "Save file as")
end

return M
