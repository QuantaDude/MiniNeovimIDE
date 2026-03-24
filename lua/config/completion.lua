vim.cmd.packadd("vim-dadbod-completion")

-- Native LSP completion
vim.lsp.completion.enable = true

local PAIRS = {
  ["{"] = "}",
  ["("] = ")",
  ["["] = "]",
  ["<"] = ">",
  ["'"] = "'",
  ['"'] = '"',
  ["`"] = "`",
}

local function next_char_is(char)
  local col = vim.fn.col(".")
  local line = vim.api.nvim_get_current_line()
  return line:sub(col, col) == char
end

-- count occurrences of a char in a string
local function count_char(str, char)
  local _, count = str:gsub(vim.pesc(char), "")
  return count
end

-- check if quote should be paired (odd count on line)
local function should_pair_quote(char)
  local line = vim.api.nvim_get_current_line()
  return count_char(line, char) % 2 == 0
end

-- =========================
-- Tree-sitter helpers
-- =========================

local function ts_node_at_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  return vim.treesitter.get_node({
    pos = { row - 1, col },
    ignore_injections = false,
  })
end

local function in_ts_node(types)
  local node = ts_node_at_cursor()
  while node do
    if vim.tbl_contains(types, node:type()) then
      return true
    end
    node = node:parent()
  end
  return false
end

local function in_comment()
  return in_ts_node({ "comment", "line_comment", "block_comment" })
end

local function in_string()
  return in_ts_node({
    "string",
    "string_fragment",
    "template_string",
    "interpreted_string_literal",
  })
end


local function autopair(char)
  local close = PAIRS[char]

  -- never autopair inside comments
  if in_comment() then
    return char
  end

  -- skip duplicate closers
  if next_char_is(close) then
    return char
  end

  -- quotes: only pair inside strings or code, never blindly
  if char == "'" or char == '"' or char == "`" then
    -- inside string: only close if unmatched
    if in_string() then
      if not should_pair_quote(char) then
        return char
      end
    end
  end

  return char .. close .. "<Left>"
end


-- insert-mode mappings
for open, _ in pairs(PAIRS) do
  vim.keymap.set("i", open, function()
    return autopair(open)
  end, { expr = true, noremap = true })
end
