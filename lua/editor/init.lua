local M = {}

local input = require("editor.scope")
local keymaps = require("editor.keymaps")

local is_editable = input.is_editable
local resume_input = input.resume

-- quick_open と toggle_sidebar は setup() の中で設定されるため、
-- キーを押した時点で参照する。
local workspace_actions = {
  quick_open = function()
    if M.quick_open then
      M.quick_open()
    end
  end,

  toggle_sidebar = function()
    if M.toggle_sidebar then
      M.toggle_sidebar()
    end
  end,
}

local function configure_buffer(buf)
  if not is_editable(buf) then
    return
  end

  -- 通常の編集ファイルだけを対象にする。
  -- grug-farなどの専用画面には適用しない。
  if input.is_file_editor(buf) then
    keymaps.apply_file(buf, resume_input)
  end

  -- 通常ファイルとgrug-farの両方に共通のキー。
  keymaps.apply_area(buf, resume_input)

  -- ワークスペース共通のキー。
  keymaps.apply_workspace(buf, workspace_actions)
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

    keymaps.refresh_quick_open(buf, workspace_actions)
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
  require("editor.global.options").setup()
  require("editor.global.trim").setup()
  require("editor.global.autosave").setup()

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

  local quick_open = require("editor.global.quick_open")

  M.quick_open = function()
    quick_open.open(resume_input)
  end

  keymaps.apply_global(M.quick_open)

  local sidebar_actions = require("sidebar").setup_actions(resume_input)
  M.toggle_sidebar = sidebar_actions.toggle_sidebar

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      configure_buffer(buf)
    end
  end

  resume_input()
end

return M
