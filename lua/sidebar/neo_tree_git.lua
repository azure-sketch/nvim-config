local M = {}

local decorations = {
  ["?"] = { "U", "NeoTreeGitUntracked" },
  ["!"] = { "", "NeoTreeGitIgnored" },
  A = { "A", "NeoTreeGitAdded" },
  M = { "M", "NeoTreeGitModified" },
  T = { "M", "NeoTreeGitModified" },
  D = { "D", "NeoTreeGitDeleted" },
  R = { "R", "NeoTreeGitRenamed" },
  -- Reserve C for conflicts; display Git-detected copies as additions.
  C = { "A", "NeoTreeGitAdded" },
}

-- The name component also calls this function to obtain its Git highlight.
function M.git_status(config, node, state)
  if node.type == "message" or not node.path then
    return {}
  end
  if config.hide_when_expanded and node.type == "directory" and node:is_expanded() then
    return {}
  end

  local status = require("neo-tree.git").find_existing_status_code(node.path, state.git_base_by_worktree)
  if type(status) == "table" then
    status = status[1]
  end
  if not status or status == "" then
    return {}
  end

  local x, y = status:sub(1, 1), status:sub(2, 2)
  local decoration
  if require("neo-tree.git.parser").status_code_is_conflict(x, y) then
    decoration = { "C", "NeoTreeGitConflict" }
  else
    -- Worktree changes take precedence over index changes; never show two badges.
    local code = y ~= "" and y ~= "." and y ~= " " and y or x
    decoration = decorations[code]
  end
  if not decoration then
    return {}
  end

  return {
    text = decoration[1] == "" and "" or decoration[1] .. " ",
    highlight = decoration[2],
  }
end

-- VS Code Tokyo Night: themes/tokyo-night-color-theme.json, gitDecoration.*.
function M.highlights(hl, colors)
  hl.NeoTreeDirectoryName = { link = "NeoTreeFileName" }
  hl.NeoTreeRootName = { link = "NeoTreeFileName" }
  hl.NeoTreeGitModified = { fg = "#6183bb" }
  hl.NeoTreeGitAdded = { fg = "#449dab" }
  hl.NeoTreeGitUntracked = { fg = "#449dab" }
  hl.NeoTreeGitRenamed = { fg = "#449dab" }
  hl.NeoTreeGitDeleted = { fg = "#914c54" }
  hl.NeoTreeGitIgnored = { fg = "#515670" }
  -- Composite #e0af68cc against Neo-tree's background instead of dropping alpha.
  local background = hl.NeoTreeNormal and hl.NeoTreeNormal.bg or colors.bg_sidebar
  if not background or background == "NONE" then
    background = colors.bg
  end
  hl.NeoTreeGitConflict = {
    fg = require("tokyonight.util").blend("#e0af68", 0xcc / 0xff, background),
  }
end

return M
