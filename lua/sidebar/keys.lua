local M = {}

local sidebar = require("sidebar")
local views = require("sidebar.views")

local MODES = { "n", "i", "s", "x" }

-- 割り当てるキーの定義。登録先（グローバル／サイドバーのバッファ）は共通。
local function entries()
  local list = {}

  for _, name in ipairs(views.names()) do
    local spec = views.get(name)

    list[#list + 1] = {
      spec.key,
      function()
        sidebar.focus(name)
      end,
      spec.desc or ("Focus " .. name .. " sidebar"),
    }
  end

  list[#list + 1] = { "<C-0>", sidebar.focus_last, "Focus sidebar" }

  return list
end

local function map_all(opts)
  for _, entry in ipairs(entries()) do
    vim.keymap.set(MODES, entry[1], entry[2], vim.tbl_extend("force", {
      silent = true,
      desc = entry[3],
    }, opts or {}))
  end
end

-- サイドバーのバッファだけに、プラグインのバッファローカルなキーより優先して付ける。
local function attach(buf)
  if not vim.api.nvim_buf_is_valid(buf)
      or not vim.api.nvim_buf_is_loaded(buf)
      or not views.name_of(buf)
  then
    return
  end

  map_all({ buffer = buf })
end

local function schedule_configuration(event)
  local buf = event.buf

  sidebar.remember_buffer(buf)

  vim.schedule(function()
    attach(buf)
  end)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("SidebarKeys", { clear = true })

  vim.api.nvim_create_autocmd({
    "BufEnter",
    "WinEnter",
    "FileType",
    "InsertEnter",
  }, {
    group = group,
    callback = schedule_configuration,
  })

  -- どのバッファでも使えるワークスペース共通のキー。
  map_all()

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    attach(buf)
  end
end

return M
