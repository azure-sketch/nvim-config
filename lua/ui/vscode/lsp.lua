local M = {}

local keymap = require("ui.vscode.keymap")

local function keycode(keys)
  return vim.api.nvim_replace_termcodes(
    keys, true, false, true
  )
end

-- キーを押した時点のバッファで、
-- 必要なLSP機能が使えるか確認する。
local function lsp_action(method, action)
  return function()
    local clients = vim.lsp.get_clients({
      bufnr = vim.api.nvim_get_current_buf(),
    })

    for _, client in ipairs(clients) do
      if client:supports_method(method) then
        action()
        return
      end
    end

    vim.notify(
      "このファイルでは、対応する言語サーバーが"
      .. "未接続、またはこの機能に未対応です",
      vim.log.levels.INFO
    )
  end
end

local function open_symbol_picker(source, resume_input)
  local ok, picker = pcall(require, "snacks.picker")

  if not ok then
    vim.notify(
      "Snacks Pickerが見つかりません",
      vim.log.levels.WARN
    )
    return
  end

  vim.cmd("stopinsert")

  local opened, err = pcall(function()
    picker[source]()
  end)

  if not opened then
    vim.notify(tostring(err), vim.log.levels.WARN)
    resume_input()
  end
end

local function handle_hover_prefix(show_hover)
  vim.api.nvim_echo({
    {
      "Ctrl+K → Ctrl+I: 説明を表示 / Esc: キャンセル",
      "ModeMsg",
    },
  }, false, {})

  -- 2つ目のキーを時間制限なしで待つ。
  local ok, key = pcall(vim.fn.getcharstr)

  vim.api.nvim_echo({}, false, {})

  -- メッセージ消去とキー処理が終わった後に、
  -- 画面とステータスラインを更新する。
  vim.schedule(function()
    vim.cmd("redraw")
    vim.cmd("redrawstatus!")
  end)

  if not ok or key == keycode("<Esc>") then
    return
  end

  -- 端末によってCtrl+IはTabと同じ入力になる。
  if key == keycode("<C-i>")
      or key == keycode("<Tab>")
  then
    show_hover()
    return
  end

  vim.notify(
    "このCtrl+Kの組み合わせには操作を設定していません",
    vim.log.levels.INFO
  )
end

function M.attach(buf, resume_input)
  local map = keymap.for_buffer(buf)

  local show_hover = lsp_action(
    "textDocument/hover",
    function()
      vim.lsp.buf.hover()
    end
  )

  map({ "n", "i" }, "<C-.>",
    lsp_action(
      "textDocument/codeAction",
      function()
        vim.lsp.buf.code_action()
      end
    ),
    "Show code actions")

  map({ "n", "i" }, "<C-k>", function()
    handle_hover_prefix(show_hover)
  end, "VS Code-style Ctrl+K prefix")

  map({ "n", "i" }, "<F12>",
    lsp_action(
      "textDocument/definition",
      function()
        vim.lsp.buf.definition()
      end
    ),
    "Go to definition")

  map({ "n", "i" }, "<F24>",
    lsp_action(
      "textDocument/references",
      function()
        vim.lsp.buf.references()
      end
    ),
    "Find references")

  map({ "n", "i" }, "<F2>",
    lsp_action(
      "textDocument/rename",
      function()
        vim.lsp.buf.rename()
      end
    ),
    "Rename symbol")

  map({ "n", "i" }, "<C-S-o>",
    lsp_action(
      "textDocument/documentSymbol",
      function()
        open_symbol_picker("lsp_symbols", resume_input)
      end
    ),
    "Go to symbol in file")

  map({ "n", "i" }, "<C-t>",
    lsp_action(
      "workspace/symbol",
      function()
        open_symbol_picker("lsp_workspace_symbols", resume_input)
      end
    ),
    "Go to symbol in workspace")
end

return M
