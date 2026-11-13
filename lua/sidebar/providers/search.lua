local INSTANCE = "sidebar-search"
local FILETYPE = "grug-far"

return {
  name = "search",
  key = "<C-S-f>",
  desc = "Focus search sidebar",

  -- 入力できる領域。editor はこの宣言を見て入力領域と判定する。
  input = true,

  match = function(buf)
    return vim.bo[buf].filetype == FILETYPE
  end,

  open = function()
    local grug = require("grug-far")

    if grug.has_instance(INSTANCE) then
      grug.get_instance(INSTANCE):open()
    else
      grug.open({ instanceName = INSTANCE, staticTitle = "Search" })
    end
  end,

  -- 検索画面では、そのまま入力できる状態にする。
  on_focus = function(buf)
    if vim.bo[buf].filetype == FILETYPE and vim.bo[buf].modifiable then
      vim.cmd("startinsert")
    end
  end,

  -- edgy.nvim 用の表示情報。
  edgy = { title = "Search", help = "F1:Help", ft = FILETYPE },

  setup = function()
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
        end)
      end,
    })
  end,
}
