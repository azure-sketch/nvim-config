local M = {}

---@class SidebarProvider
---@field name string
---@field key string
---@field desc? string
---@field match fun(buf: integer): boolean
---@field open fun()
---@field close? fun(win: integer)
---@field on_focus? fun(buf: integer)
---@field setup? fun()
---@field edgy? { title: string, help?: string, ft: string, filter?: fun(buf: integer): boolean }

local specs = {}
local order = {}

function M.register(spec)
  assert(type(spec.name) == "string", "provider.name is required")
  assert(type(spec.key) == "string", "provider.key is required: " .. spec.name)
  assert(type(spec.match) == "function", "provider.match is required: " .. spec.name)
  assert(type(spec.open) == "function", "provider.open is required: " .. spec.name)
  assert(not specs[spec.name], "Duplicate sidebar view: " .. spec.name)

  specs[spec.name] = spec
  order[#order + 1] = spec.name
end

function M.get(name)
  return specs[name]
end

-- 登録順の名前一覧。
function M.names()
  return vim.list_slice(order)
end

-- バッファがサイドバーなら種類を返す。
function M.name_of(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end

  for _, name in ipairs(order) do
    if specs[name].match(buf) then
      return name
    end
  end

  return nil
end

function M.is_view(buf, name)
  return M.name_of(buf) == name
end

-- 現在のタブからサイドバーを探す。name省略時は最初に見つかったもの。
-- 戻り値: win, name。見つからなければnil。
function M.find(name)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local view = M.name_of(vim.api.nvim_win_get_buf(win))

    if view and (name == nil or view == name) then
      return win, view
    end
  end

  return nil
end

return M
