local M = {}

-- オプションを変えずに、共通の入口から登録する。
function M.set(modes, lhs, rhs, opts)
  vim.keymap.set(modes, lhs, rhs, opts)
end

-- 通常のバッファ用マッピング。個別オプションも指定できる。
function M.for_buffer(buf)
  return function(modes, lhs, rhs, desc, opts)
    local options = { silent = true, desc = desc }
    for key, value in pairs(opts or {}) do
      options[key] = value
    end
    options.buffer = buf
    M.set(modes, lhs, rhs, options)
  end
end

return M
