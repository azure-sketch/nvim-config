local M = {}

local bindings = require("ui.vscode.workspace_bindings")
local input = require("ui.vscode.input")

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
    require("ui.vscode.lines").attach(buf)
    require("ui.vscode.lsp").attach(buf, resume_input)
    require("ui.vscode.navigation").attach(buf, resume_input)
    require("ui.vscode.comment").attach(buf)
    require("ui.vscode.diagnostics").attach(buf, resume_input)
    require("ui.vscode.format").attach(buf, resume_input)
    require("ui.vscode.find").attach_file(buf, resume_input)
    require("ui.vscode.selection").attach_file(buf)
  end

  require("ui.vscode.save").attach(buf, resume_input)

  bindings.apply("quick_open", quick_open, {
    buffer = buf,
    silent = true,
  })

  bindings.apply("toggle_sidebar", toggle_sidebar, {
    buffer = buf,
    silent = true,
  })

  require("ui.vscode.history").attach(buf)
  require("ui.vscode.selection").attach(buf)
  require("ui.vscode.navigation").attach_common(buf)
  require("ui.vscode.find").attach(buf)
  require("ui.vscode.buffers").attach(buf)
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
  require("ui.vscode.options").setup()

  local group = vim.api.nvim_create_augroup(
    "VSCodeEditing",
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

  local actions = require("ui.vscode.workspace").setup(
    resume_input,
    group
  )

  M.quick_open = actions.quick_open
  M.toggle_sidebar = actions.toggle_sidebar

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      configure_buffer(buf)
    end
  end

  resume_input()
end

return M
