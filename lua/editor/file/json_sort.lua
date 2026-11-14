local M = {}

local MAX_INDENT = 7

-- 並べ替えできるバッファか確認する。問題があれば (メッセージ, レベル) を返す
local function check_buffer(bufnr)
  local ft = vim.bo[bufnr].filetype
  if ft ~= "json" and ft ~= "jsonc" then
    return "JSON ファイルではありません", vim.log.levels.WARN
  end

  if vim.fn.executable("jq") == 0 then
    return "jq が見つかりません", vim.log.levels.ERROR
  end
end

-- インデントはバッファの設定に合わせる。jq の引数と、1段分の文字列を返す
local function indent_style(bufnr)
  if vim.bo[bufnr].expandtab then
    local width = math.min(math.max(vim.fn.shiftwidth(), 1), MAX_INDENT)
    return { "--indent", tostring(width) }, string.rep(" ", width)
  end

  return { "--tab" }, "\t"
end

-- jq --sort-keys に text を渡す。成功すれば行の配列、失敗すれば nil とエラーを返す
local function jq_sort(text, indent_args)
  local cmd = vim.list_extend({ "jq", "--sort-keys" }, indent_args)
  table.insert(cmd, ".")

  local result = vim.system(cmd, { stdin = text .. "\n", text = true }):wait()
  if result.code ~= 0 or not result.stdout or result.stdout == "" then
    return nil, result.stderr
  end

  local lines = vim.split(result.stdout, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

local function fail(err)
  vim.notify("並べ替えに失敗しました:\n" .. (err or ""), vim.log.levels.ERROR)
end

-- 範囲なし: バッファ全体を並べ替える
local function sort_buffer(bufnr, indent_args)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local sorted, err = jq_sort(table.concat(lines, "\n"), indent_args)
  if not sorted then
    return fail(err)
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, sorted)
end

-- プロパティの並びを {} で包んで並べ替え、外側の {} と1段分のインデントを取り除く
local function sort_members(text, indent_args, unit)
  local sorted = jq_sort("{" .. text .. "}", indent_args)
  if not sorted then
    return nil
  end

  table.remove(sorted, 1)
  table.remove(sorted)
  for i, line in ipairs(sorted) do
    if vim.startswith(line, unit) then
      sorted[i] = line:sub(#unit + 1)
    end
  end
  return sorted
end

-- 範囲あり: 選択行だけを並べ替える。先頭行のインデントと末尾のカンマは保つ
local function sort_range(bufnr, first, last, indent_args, unit)
  local lines = vim.api.nvim_buf_get_lines(bufnr, first - 1, last, false)
  local base_indent = lines[1]:match("^%s*")
  local trailing_comma = lines[#lines]:match(",%s*$") and "," or ""
  lines[#lines] = (lines[#lines]:gsub(",%s*$", ""))
  local text = table.concat(lines, "\n")

  -- 値として解釈できなければ、プロパティの並びとして試す
  local sorted, err = jq_sort(text, indent_args)
  if not sorted then
    sorted = sort_members(text, indent_args, unit)
  end
  if not sorted then
    return fail(err)
  end
  if #sorted == 0 then
    return
  end

  for i, line in ipairs(sorted) do
    sorted[i] = base_indent .. line
  end
  sorted[#sorted] = sorted[#sorted] .. trailing_comma

  vim.api.nvim_buf_set_lines(bufnr, first - 1, last, false, sorted)
end

-- :JsonSortKeys の本体。範囲指定があればその行だけを対象にする
function M.run(args)
  local bufnr = vim.api.nvim_get_current_buf()

  local message, level = check_buffer(bufnr)
  if message then
    return vim.notify(message, level)
  end

  local indent_args, unit = indent_style(bufnr)
  if args.range == 0 then
    sort_buffer(bufnr, indent_args)
  else
    sort_range(bufnr, args.line1, args.line2, indent_args, unit)
  end
end

return M
