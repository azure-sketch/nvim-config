local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup(
    "SidebarSearchBuffer",
    { clear = true }
  )

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "grug-far",
    callback = function(event)
      local buf = event.buf
      vim.bo[buf].buflisted = false

      -- grug-far側のキー設定が終わってから登録する。
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end

        -- 入力中から、標準のg?を呼び出す。
        vim.keymap.set("i", "<F1>", "<C-o>g?", {
          buffer = buf,
          silent = true,
          remap = true,
          desc = "Show grug-far help",
        })

        -- ノーマル状態でも同じ入口を使えるようにする。
        vim.keymap.set("n", "<F1>", "g?", {
          buffer = buf,
          silent = true,
          remap = true,
          desc = "Show grug-far help",
        })
      end)
    end,
  })
end

return M
