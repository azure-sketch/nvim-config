local TIMEOUT_MS = 2000

-- リクエストの結果を返す。エラーやタイムアウトは例外にする。
local function request(client, bufnr, method, params)
  local response = client:request_sync(method, params, TIMEOUT_MS, bufnr)

  if not response then
    error(method .. " timed out")
  end

  if response.err then
    error(method .. ": " .. (response.err.message or vim.inspect(response.err)))
  end

  return response.result
end

-- Biome のインポート整列を適用する（VS Code の source.organizeImports.biome 相当）。
-- .astro はフロントマターだけが JS として解析されるため、範囲はバッファ全体（最終行の末尾まで）を指定する。
-- Biome はクライアントが codeAction/resolve に対応していると、一覧では edit を空にして返すため、
-- edit が無いアクションは resolve してから適用する。
local function organize_imports(client, bufnr)
  local last_line = vim.api.nvim_buf_line_count(bufnr) - 1
  local last_text = vim.api.nvim_buf_get_lines(bufnr, last_line, last_line + 1, false)[1] or ""

  local actions = request(client, bufnr, "textDocument/codeAction", {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = {
      start = { line = 0, character = 0 },
      ["end"] = { line = last_line, character = #last_text },
    },
    context = { only = { "source.organizeImports.biome" }, diagnostics = {} },
  })

  for _, action in ipairs(actions or {}) do
    local resolved = action

    if not resolved.edit and resolved.data then
      resolved = request(client, bufnr, "codeAction/resolve", action) or action
    end

    if resolved.edit then
      vim.lsp.util.apply_workspace_edit(resolved.edit, client.offset_encoding)
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
