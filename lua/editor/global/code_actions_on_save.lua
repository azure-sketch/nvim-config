-- 保存時（BufWritePre）に、LSP のコードアクションを同期で適用する。
-- VS Code の source.fixAll.eslint と source.organizeImports.biome に相当する。
-- 自動保存（global/autosave.lua）も BufWritePre を発火させるため、すべての保存で動く。
-- 適用順は ACTIONS の並び順（ESLint の修正 → インポート整列）。整形は AstroLSP の保存時整形が後で行う。
local M = {}

local TIMEOUT_MS = 2000

-- ESLint の自動修正をすべて適用する（lspconfig の :LspEslintFixAll と同じ要求）。
local function eslint_fix_all(buf, client)
  client:request_sync("workspace/executeCommand", {
    command = "eslint.applyAllFixes",
    arguments = {
      {
        uri = vim.uri_from_bufnr(buf),
        version = vim.lsp.util.buf_versions[buf],
      },
    },
  }, TIMEOUT_MS, buf)
end

-- Biome のインポート整列を適用する。
local function organize_imports(buf, client)
  local origin = { line = 0, character = 0 }
  local response = client:request_sync("textDocument/codeAction", {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    range = { start = origin, ["end"] = origin },
    context = { only = { "source.organizeImports.biome" }, diagnostics = {} },
  }, TIMEOUT_MS, buf)

  if not response or not response.result then
    return
  end

  for _, action in ipairs(response.result) do
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    end
  end
end

local ACTIONS = {
  { client = "eslint", run = eslint_fix_all },
  { client = "biome", run = organize_imports },
}

local function run(buf)
  if vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable then
    return
  end

  for _, action in ipairs(ACTIONS) do
    for _, client in ipairs(vim.lsp.get_clients { bufnr = buf, name = action.client }) do
      -- 失敗しても保存は止めない。
      local ok, err = pcall(action.run, buf, client)
      if not ok then
        vim.notify(("%s on save failed: %s"):format(action.client, err), vim.log.levels.WARN)
      end
    end
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("CodeActionsOnSave", { clear = true }),
    desc = "Apply eslint fixes and organize imports before saving",
    callback = function(event)
      run(event.buf)
    end,
  })
end

return M
