local M = {}

local function keycode(key)
  return vim.api.nvim_replace_termcodes(key, true, true, true)
end

local function active()
  return vim.bo.filetype == "neo-tree"
    and vim.b.neo_tree_source == "filesystem"
    and vim.api.nvim_get_mode().mode == "n"
end

-- Read labels from registered mappings, falling back to Neo-tree's own help text.
local function entries(state)
  local actual = {}
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(0, "n")) do
    actual[keycode(mapping.lhs)] = mapping
  end

  local configured = {}
  for key, binding in pairs(state.window and state.window.mappings or {}) do
    if type(key) == "string" then
      configured[keycode(key)] = binding
    end
  end

  local result = {}
  for key, resolved in pairs(state.resolved_mappings or {}) do
    local code = keycode(key)
    local registered = actual[code]
    local binding = configured[code]
    local command = type(binding) == "table" and binding[1] or binding
    local config = type(binding) == "table" and binding.config or nil
    if registered and type(command) == "string" and not key:lower():find("mouse", 1, true) then
      local text = registered.desc or resolved.text
      if type(text) == "string" and text ~= "" and not (config and config.prefix_key) then
        result[#result + 1] = {
          key = vim.fn.keytrans(code),
          text = text,
          command = command,
          special = key:sub(1, 1) == "<",
        }
      end
    end
  end

  -- Prefer special-key aliases (F2, Ctrl+C, etc.) without defining their labels here.
  table.sort(result, function(a, b)
    if a.special ~= b.special then
      return a.special
    end
    if #a.key ~= #b.key then
      return #a.key < #b.key
    end
    return a.key < b.key
  end)
  return result
end

local function pick(mappings, commands)
  for _, command in ipairs(commands) do
    for _, mapping in ipairs(mappings) do
      if mapping.command == command then
        return mapping
      end
    end
  end
end

local function label(mapping)
  return mapping and (mapping.key .. " " .. mapping.text:gsub("[\r\n]", " ")) or ""
end

local function provider()
  local state = require("neo-tree.sources.manager").get_state_for_window()
  if not state then
    return ""
  end
  local mappings = entries(state)
  local node = state.tree and state.tree:get_node()
  local help = pick(mappings, { "show_help" })
  local actions = {}
  local used = {}
  local function add(commands)
    local mapping = pick(mappings, commands)
    if mapping and not used[mapping.key] then
      used[mapping.key] = true
      actions[#actions + 1] = label(mapping)
    end
  end

  local has_clipboard = state.clipboard and next(state.clipboard) ~= nil
  local is_item = node and (node.type == "file" or node.type == "directory")
  if is_item then
    if has_clipboard then
      add({ "paste_from_clipboard" })
    end
    if node.type == "directory" and node:is_expanded() then
      add({ "parent_or_close", "close_node", "toggle_node" })
    else
      add({ "open", "child_or_open", "toggle_node" })
    end
    add({ "add" })
    add({ "add_directory" })
    if node.path ~= state.path then
      add({ "rename" })
      add({ "delete" })
      add({ "copy_to_clipboard" })
      add({ "cut_to_clipboard" })
    end
    if node.type == "file" then
      add({ "open_vsplit" })
      add({ "open_split" })
    end
  end
  add({ "refresh" })
  add({ "fuzzy_finder" })
  add({ "toggle_hidden" })

  local width = math.max(0, vim.o.columns - 2)
  local right = label(help)
  if vim.fn.strdisplaywidth(right) > width then
    right = help and help.key or ""
  end
  local available = math.max(0, width - vim.fn.strdisplaywidth(right) - 3)
  local left = ""
  for _, action in ipairs(actions) do
    local candidate = left == "" and action or (left .. " | " .. action)
    if vim.fn.strdisplaywidth(candidate) <= available then
      left = candidate
    end
  end
  -- Escape statusline directives in descriptions; only our alignment marker is active.
  return " " .. left:gsub("%%", "%%%%") .. "%=" .. right:gsub("%%", "%%%%") .. " "
end

function M.wrap(statusline)
  local group = vim.api.nvim_create_augroup("NeoTreeActionGuide", { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter", "WinEnter", "ModeChanged", "VimResized" }, {
    group = group,
    callback = function(event)
      if event.event ~= "CursorMoved" or vim.bo.filetype == "neo-tree" then
        vim.cmd.redrawstatus()
      end
    end,
  })

  return {
    fallthrough = false,
    {
      condition = active,
      provider = provider,
      hl = { fg = "fg", bg = "bg" },
    },
    statusline,
  }
end

return M
