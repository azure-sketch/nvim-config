local M = {}

local keymap = require("ui.vscode.keymap")

function M.attach(buf, resume_input)
  local map = keymap.for_buffer(buf)

  -- 保存。検索画面の保存とは区別する。
  local function save_as()
    local target = vim.api.nvim_get_current_buf()

    if vim.bo[target].buftype ~= "" then
      vim.notify(
        "通常の編集ファイルで実行してください",
        vim.log.levels.INFO
      )
      return
    end

    local name = vim.api.nvim_buf_get_name(target)
    local default = name ~= ""
        and name
        or (vim.fn.getcwd() .. "/")

    vim.ui.input({
      prompt = "名前を付けて保存: ",
      default = default,
      completion = "file",
    }, function(path)
      if not path or path == "" then
        resume_input()
        return
      end

      if not vim.api.nvim_buf_is_valid(target) then
        return
      end

      local ok, err = pcall(function()
        vim.api.nvim_buf_call(target, function()
          -- 保存前から存在するバッファは対象外にする。
          local existing = {}

          for _, id in ipairs(vim.api.nvim_list_bufs()) do
            existing[id] = true
          end

          local was_unnamed =
              vim.api.nvim_buf_get_name(target) == ""

          vim.cmd(
            "saveas " .. vim.fn.fnameescape(path)
          )

          if not was_unnamed then
            return
          end

          local alternate = vim.fn.bufnr("#")

          if alternate < 1
              or alternate == target
              or existing[alternate]
              or not vim.api.nvim_buf_is_valid(alternate)
          then
            return
          end

          -- 新しく発生した、名前なし・未変更・非表示の
          -- 通常バッファだけを確認する。
          if vim.api.nvim_buf_get_name(alternate) ~= ""
              or vim.bo[alternate].buftype ~= ""
              or vim.bo[alternate].modified
              or #vim.fn.win_findbuf(alternate) > 0
          then
            return
          end

          -- 読み込み済みなら、本文が空であることも確認。
          if vim.api.nvim_buf_is_loaded(alternate) then
            local lines = vim.api.nvim_buf_get_lines(
              alternate, 0, -1, false
            )

            if #lines > 1
                or (#lines == 1 and lines[1] ~= "")
            then
              return
            end
          end

          -- 削除はせず、上部のファイル一覧からだけ外す。
          vim.bo[alternate].buflisted = false
        end)
      end)

      if not ok then
        vim.notify(tostring(err), vim.log.levels.WARN)
      end

      resume_input()
    end)
  end

  local function save()
    if vim.bo.filetype == "grug-far" then
      vim.notify(
        "検索・置換画面では Ctrl+S で保存しません",
        vim.log.levels.INFO
      )
      return
    end

    if vim.api.nvim_buf_get_name(0) == "" then
      save_as()
      return
    end

    local ok, err = pcall(vim.cmd, "write")

    if not ok then
      vim.notify(tostring(err), vim.log.levels.WARN)
    end
  end

  map({ "n", "i", "s", "x" }, "<C-s>", save, "Save file")
  map({ "n", "i" }, "<C-S-s>",
    save_as,
    "Save file as")

end

return M
