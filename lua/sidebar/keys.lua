local M = {}

local sidebar = require("sidebar")
local views = require("sidebar.views")

local function eligible(buf)
  if not vim.api.nvim_buf_is_valid(buf)
      or not vim.api.nvim_buf_is_loaded(buf)
  then
    return false
  end

  if views.name_of(buf) then
    return true
  end

  return vim.bo[buf].buftype == ""
      and vim.bo[buf].modifiable
      and not vim.api.nvim_buf_get_name(buf):match("^fugitive://")
end

local function attach(buf)
  if not eligible(buf) then
    return
  end

  local function map(lhs, callback, desc)
    vim.keymap.set({ "n", "i", "s", "x" }, lhs, callback, {
      buffer = buf,
      silent = true,
      desc = desc,
    })
  end

  for _, name in ipairs(views.names()) do
    local spec = views.get(name)

    map(spec.key, function()
      sidebar.focus(name)
    end, spec.desc or ("Focus " .. name .. " sidebar"))
  end

  map("<C-0>", sidebar.focus_last, "Focus sidebar")
end

local function schedule_configuration(event)
  local buf = event.buf

  sidebar.remember_buffer(buf)

  vim.schedule(function()
    attach(buf)
  end)
end

function M.setup()
  local group = vim.api.nvim_create_augroup(
    "SidebarKeys",
    { clear = true }
  )

  vim.api.nvim_create_autocmd({
    "BufEnter",
    "WinEnter",
    "FileType",
    "InsertEnter",
  }, {
    group = group,
    callback = schedule_configuration,
  })

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    attach(buf)
  end
end

return M
