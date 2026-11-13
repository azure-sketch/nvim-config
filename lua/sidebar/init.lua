local M = {}

local views = require("sidebar.views")

-- 有効にするプロバイダ。追加時はここに1行足す。表示順・キー登録順もこの順。
local PROVIDERS = { "files", "search", "git" }

local last_view
local initialized = false

local function provider(name)
  local spec = views.get(name)

  if not spec then
    error("Unknown sidebar view: " .. tostring(name))
  end

  return spec
end

local function is_sidebar(buf)
  return views.name_of(buf) ~= nil
end

local function goto_editor()
  require("edgy").goto_main()

  local current = vim.api.nvim_get_current_win()

  if not is_sidebar(vim.api.nvim_win_get_buf(current)) then
    return current
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local b = vim.api.nvim_win_get_buf(win)

    if vim.api.nvim_win_get_config(win).relative == ""
        and vim.bo[b].buftype == ""
        and not is_sidebar(b)
    then
      vim.api.nvim_set_current_win(win)
      return win
    end
  end

  error("サイドバー以外の編集ウィンドウが見つかりません")
end

local function close_views()
  for _, name in ipairs(views.names()) do
    local win = views.find(name)

    if win then
      local spec = views.get(name)

      if spec.close then
        spec.close(win)
      elseif vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, false)
      end
    end
  end
end

-- プロバイダを登録し、キー割り当てと各ビューの初期化を行う。
function M.setup()
  if initialized then
    return
  end
  initialized = true

  for _, name in ipairs(PROVIDERS) do
    views.register(require("sidebar.providers." .. name))
  end

  last_view = PROVIDERS[1]

  for _, name in ipairs(views.names()) do
    local spec = views.get(name)

    if spec.setup then
      spec.setup()
    end
  end

  require("sidebar.keys").setup()
end

function M.toggle(name)
  local spec = provider(name)
  last_view = name

  local was_visible = views.find(name) ~= nil
  local editor = goto_editor()

  close_views()

  if vim.api.nvim_win_is_valid(editor) then
    vim.api.nvim_set_current_win(editor)
  end

  if not was_visible then
    spec.open()
  end
end

-- イベント対象のバッファがサイドバーなら、その種類を記憶する。
function M.remember_buffer(buf)
  local name = views.name_of(buf)

  if name then
    last_view = name
  end
end

-- 現在表示されているサイドバーの種類を記憶する。
function M.remember_visible()
  local _, name = views.find()

  if name then
    last_view = name
  end
end

-- 表示中なら閉じ、非表示なら最後に使った種類を開く。
-- 編集領域への復帰は呼び出し側が担当する。
function M.toggle_last()
  local _, name = views.find()
  M.toggle(name or last_view)
end

-- 指定したサイドバーへフォーカスする。
-- 表示中の場合は閉じず、非表示の場合だけ開く。
function M.focus(name)
  local spec = provider(name)

  vim.cmd("stopinsert")
  last_view = name

  local win = views.find(name)

  if win then
    vim.api.nvim_set_current_win(win)
  else
    M.toggle(name)
  end

  if spec.on_focus then
    spec.on_focus(vim.api.nvim_get_current_buf())
  end
end

-- 表示中のサイドバー、なければ最後に使った種類へフォーカスする。
function M.focus_last()
  local _, name = views.find()
  M.focus(name or last_view)
end

return M
