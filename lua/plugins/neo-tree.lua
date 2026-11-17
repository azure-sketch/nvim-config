local layout = require("layout")
local bindings = require("bindings")

return {
  {
    "nvim-neo-tree/neo-tree.nvim",

    opts_extend = { "open_files_do_not_replace_types" },

    opts = {
      default_component_configs = {
        name = {
          use_git_status_colors = true,
          highlight_opened_files = false,
        },
      },

      window = {
        position = "left",
        width = layout.sidebar.width,
        mappings = {
          [bindings.lhs("toggle_sidebar")] = function()
            require("editor").toggle_sidebar()
          end,
          [bindings.lhs("quick_open")] = function()
            require("editor").quick_open()
          end,
          ["<space>"] = "none",
        },
      },

      filesystem = {
        components = {
          git_status = require("sidebar.neo_tree_git").git_status,
        },
        hijack_netrw_behavior = "open_default",
        window = {
          position = "left",
          mappings = {
            ["<F2>"] = "rename",
            ["<C-c>"] = "copy_to_clipboard",
            ["<C-x>"] = "cut_to_clipboard",
            ["<C-v>"] = "paste_from_clipboard",
            ["<Del>"] = "delete",
            ["<F5>"] = "refresh",
          },
        },
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
          never_show = { ".git" },
        },
      },

      source_selector = {
        winbar = false,
        statusline = false,
      },

      open_files_do_not_replace_types = { "neo-tree", "edgy" },
    },
  },
}
