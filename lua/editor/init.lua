local M = {}

local bindings = require("bindings")
local input = require("editor.input")

local is_editable = input.is_editable
local resume_input = input.resume

local function quick_open()
  if M.quick_open then
    M.quick_open()
  end
end

local function toggle_sidebar()
  if M.toggle_sidebar then
    M.toggle_sidebar()
  end
end

local function configure_buffer(buf)
  if not is_editable(buf) then
    return
  end

  -- 通常の編集ファイルだけを対象にする。
  -- grug-farなどの専用画面には適用しない。
  if input.is_file_editor(buf) then
    require("editor.lines").attach(buf)
    require("editor.lsp").attach(buf, resume_input)
    require("editor.navigation").attach_file(buf, resume_input)
    require("editor.buffers").attach_file(buf, resume_input)
    require("editor.comment").attach(buf)
    require("editor.diagnostics").attach(buf, resume_input)
    require("editor.format").attach(buf, resume_input)
    require("editor.find").attach_file(buf, resume_input)
    require("editor.selection").attach_file(buf)
  end

  require("editor.save").attach(buf, resume_input)

  bindings.apply("quick_open", quick_open, {
    buffer = buf,
    silent = true,
  })

  bindings.apply("toggle_sidebar", toggle_sidebar, {
    buffer = buf,
    silent = true,
  })

  require("editor.history").attach(buf)
  require("editor.selection").attach(buf)
  require("editor.navigation").attach(buf)
  require("editor.find").attach(buf)
  require("editor.buffers").attach(buf)
end

-- 入力開始後に、プラグイン初期化で上書きされ得るキーを再設定する。
local function schedule_quick_open_refresh(buf)
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    if not is_editable(buf) then
      return
    end

    bindings.apply("quick_open", quick_open, {
      modes = "i",
      buffer = buf,
      silent = true,
    })
  end)
end

-- 編集設定を適用した後、従来どおり入力復帰を予約する。
-- イベントごとの予約回数と処理順は変更しない。
local function schedule_editor_configuration(buf)
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) then
      configure_buffer(buf)
    end

    resume_input()
  end)
end

function M.setup()
  require("editor.options").setup()

  local group = vim.api.nvim_create_augroup(
    "Editor",
    { clear = true }
  )

  -- 入力開始時のプラグイン初期化が終わった後にも、
  -- ファイル検索キーを割り当て直す。
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = function(event)
      schedule_quick_open_refresh(event.buf)
    end,
  })

  -- 新しく表示された編集バッファへ設定する。
  vim.api.nvim_create_autocmd({
    "BufEnter",
    "WinEnter",
    "FileType",
    "LspAttach",
  }, {
    group = group,
    callback = function(event)
      schedule_editor_configuration(event.buf)
    end,
  })

  -- Escや選択解除などでNormalへ戻っても、
  -- 編集領域なら入力状態へ戻す。
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    pattern = "*:n",
    callback = resume_input,
  })

  local editor_actions = require("editor.quick_open").setup(resume_input)
  local sidebar_actions = require("sidebar.actions").setup(resume_input)

  M.quick_open = editor_actions.quick_open
  M.toggle_sidebar = sidebar_actions.toggle_sidebar

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      configure_buffer(buf)
    end
  end

  resume_input()
end

return M
