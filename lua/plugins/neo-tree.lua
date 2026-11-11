local layout = require("layout")
local bindings = require("bindings")

return {
  {
    "nvim-neo-tree/neo-tree.nvim",

    opts = function(_, opts)
      opts.window = opts.window or {}
      opts.window.position = "left"
      opts.window.width = layout.sidebar.width
      opts.window.mappings = opts.window.mappings or {}
      opts.window.mappings[bindings.lhs("toggle_sidebar")] = function()
        require("editor").toggle_sidebar()
      end
      opts.window.mappings[bindings.lhs("quick_open")] = function()
        require("editor").quick_open()
      end
      opts.window.mappings["<space>"] = "none"

      opts.filesystem = opts.filesystem or {}
      opts.filesystem.hijack_netrw_behavior = "open_default"
      opts.filesystem.window = opts.filesystem.window or {}
      opts.filesystem.window.position = "left"
      opts.filesystem.window.mappings =
          opts.filesystem.window.mappings or {}

      local mappings = opts.filesystem.window.mappings
      mappings["<F2>"] = "rename"
      mappings["<C-c>"] = "copy_to_clipboard"
      mappings["<C-x>"] = "cut_to_clipboard"
      mappings["<C-v>"] = "paste_from_clipboard"
      mappings["<Del>"] = "delete"
      mappings["<F5>"] = "refresh"

      opts.source_selector = opts.source_selector or {}
      opts.source_selector.winbar = false
      opts.source_selector.statusline = false

      opts.open_files_do_not_replace_types =
          opts.open_files_do_not_replace_types or {}

      for _, filetype in ipairs({ "neo-tree", "edgy" }) do
        if not vim.tbl_contains(
              opts.open_files_do_not_replace_types,
              filetype
            ) then
          table.insert(
            opts.open_files_do_not_replace_types,
            filetype
          )
        end
      end
    end,
  },
}
