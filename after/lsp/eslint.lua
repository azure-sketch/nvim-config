local TIMEOUT_MS = 2000

-- ESLint の自動修正をすべて適用する（lspconfig の :LspEslintFixAll と同じ要求）。
local function fix_all(client, bufnr)
  client:request_sync("workspace/executeCommand", {
    command = "eslint.applyAllFixes",
    arguments = {
      {
        uri = vim.uri_from_bufnr(bufnr),
        version = vim.lsp.util.buf_versions[bufnr],
      },
    },
  }, TIMEOUT_MS, bufnr)
end

---@type vim.lsp.Config
return {
  -- lspconfig の on_attach を置き換えるため、:LspEslintFixAll もここで作り直す。
  -- 保存前（自動保存を含む）にも自動修正を適用する。失敗しても保存は止めない。
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, "LspEslintFixAll", function()
      fix_all(client, bufnr)
    end, { desc = "Apply all ESLint fixes" })

    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("EslintFixOnSave" .. bufnr, { clear = true }),
      buffer = bufnr,
      desc = "Apply all ESLint fixes before saving",
      callback = function()
        if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable then
          return
        end

        local ok, err = pcall(fix_all, client, bufnr)
        if not ok then
          vim.notify("eslint fix on save failed: " .. tostring(err), vim.log.levels.WARN)
        end
      end,
    })
  end,
}
