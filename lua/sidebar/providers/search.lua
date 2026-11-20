local navigation = require("sidebar.search_navigation")
local INSTANCE = "sidebar-search"
local FILETYPE = "grug-far"

return {
  name = "search",
  key = "<C-S-f>",
  desc = "Focus search sidebar",

  input = true,
  can_resume_input = navigation.can_resume_input,

  match = function(buf)
    return vim.bo[buf].filetype == FILETYPE
  end,

  open = function()
    require("sidebar.search_target").open({ instanceName = INSTANCE, staticTitle = "Search" })
  end,

  on_focus = function(buf)
    if vim.bo[buf].modifiable then
      navigation.focus_input(buf)
    end
  end,

  edgy = { title = "Search", help = "F1:Help", ft = FILETYPE },

  setup = function()
    require("sidebar.search_target").setup()

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("SidebarSearchBuffer", { clear = true }),
      pattern = FILETYPE,
      callback = function(event)
        local buf = event.buf
        vim.bo[buf].buflisted = false

        -- grug-far側のキー設定が終わってから登録する。
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(buf) then
            return
          end

          local opts = { buffer = buf, silent = true, remap = true, desc = "Show grug-far help" }
          vim.keymap.set("i", "<F1>", "<C-o>g?", opts)
          vim.keymap.set("n", "<F1>", "g?", opts)

          -- 入力中に矢印キーで結果欄へ入り込まないようにする。
          for _, key in ipairs({ "<Up>", "<Down>" }) do
            vim.keymap.set("i", key, "<Nop>", { buffer = buf, silent = true })
          end
          navigation.setup(buf)
        end)
      end,
    })
  end,
}
