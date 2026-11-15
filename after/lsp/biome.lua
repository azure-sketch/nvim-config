local TIMEOUT_MS = 2000

-- Biome のインポート整列を適用する（VS Code の source.organizeImports.biome 相当）。
-- .astro はフロントマターだけが JS として解析されるため、範囲はバッファ全体を指定する。
local function organize_imports(client, bufnr)
  local response = client:request_sync("textDocument/codeAction", {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = {
      start = { line = 0, character = 0 },
      ["end"] = { line = vim.api.nvim_buf_line_count(bufnr), character = 0 },
    },
    context = { only = { "source.organizeImports.biome" }, diagnostics = {} },
  }, TIMEOUT_MS, bufnr)

  if not response or not response.result then
    return
  end

  for _, action in ipairs(response.result) do
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    end
  end
end

---@type vim.lsp.Config
return {
  -- :BiomeOrganizeImports で手動実行できる（キーの割り当ては editor/keymaps.lua）。
  -- 保存前（自動保存を含む）にも自動で実行する。失敗しても保存は止めない。
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, "BiomeOrganizeImports", function()
      organize_imports(client, bufnr)
    end, { desc = "Organize imports with Biome" })

    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("BiomeOrganizeImportsOnSave" .. bufnr, { clear = true }),
      buffer = bufnr,
      desc = "Organize imports with Biome before saving",
      callback = function()
        if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable then
          return
        end

        local ok, err = pcall(organize_imports, client, bufnr)
        if not ok then
          vim.notify("biome organize imports on save failed: " .. tostring(err), vim.log.levels.WARN)
        end
      end,
    })
  end,
}
