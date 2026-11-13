local M = {}

function M.open(resume_input)
  local buf = vim.api.nvim_get_current_buf()
  local tick = vim.api.nvim_buf_get_changedtick(buf)

  local function finish()
    resume_input()
  end

  local function unchanged()
    return vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].modifiable
        and vim.api.nvim_buf_get_changedtick(buf) == tick
  end

  local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO)
    finish()
  end

  vim.ui.input({
    prompt = "置換する文字列: ",
  }, function(search)
    if not search or search == "" then
      finish()
      return
    end

    vim.ui.input({
      prompt = "置換後の文字列（空欄なら削除）: ",
    }, function(replacement)
      -- nilはキャンセル。空文字列は削除として受け付ける。
      if replacement == nil then
        finish()
        return
      end

      if search:find("\n", 1, true)
          or replacement:find("\n", 1, true)
      then
        notify("今回は改行を含む置換には対応していません")
        return
      end

      if not unchanged() then
        notify(
          "入力中にファイルが変更されたため、置換を中止しました",
          vim.log.levels.WARN
        )
        return
      end

      local lines = vim.api.nvim_buf_get_lines(
        buf, 0, -1, false
      )

      local result = {}
      local count = 0

      -- 正規表現を使わず、文字列をそのまま検索する。
      for index, line in ipairs(lines) do
        local parts = {}
        local from = 1

        while true do
          local first, last = line:find(search, from, true)

          if not first then
            parts[#parts + 1] = line:sub(from)
            break
          end

          parts[#parts + 1] = line:sub(from, first - 1)
          parts[#parts + 1] = replacement
          from = last + 1
          count = count + 1
        end

        result[index] = table.concat(parts)
      end

      if count == 0 then
        notify("一致する文字列がありません")
        return
      end

      vim.ui.select({ "置換する", "キャンセル" }, {
        prompt = ("%d件をすべて置換しますか？"):format(count),
      }, function(choice)
        if choice ~= "置換する" then
          finish()
          return
        end

        if not unchanged() then
          notify(
            "確認中にファイルが変更されたため、置換を中止しました",
            vim.log.levels.WARN
          )
          return
        end

        local ok, err = pcall(
          vim.api.nvim_buf_set_lines,
          buf, 0, -1, false, result
        )

        if not ok then
          notify(tostring(err), vim.log.levels.WARN)
          return
        end

        notify(("%d件を置換しました。未保存です"):format(count))
      end)
    end)
  end)
end

return M
