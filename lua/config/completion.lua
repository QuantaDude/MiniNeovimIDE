local function map(mode, lhs, rhs, desc, extra)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", {
    noremap = true,
    silent = true,
    desc = desc,
  }, extra or {}))
end

local function setup_snippets()
  local ls = require("luasnip")
  local s = ls.snippet
  local i = ls.insert_node
  local f = ls.function_node
  local fmt = require("luasnip.extras.fmt").fmt
  local rep = require("luasnip.extras").rep



  ls.config.set_config({
    history = true,
    updateevents = "TextChanged,TextChangedI",
    enable_autosnippets = false,
  })


  require("luasnip.loaders.from_vscode").lazy_load()
  require("luasnip.loaders.from_lua").lazy_load({
    paths = vim.fn.stdpath("config") .. "/lua/snippets",
  })
  local function file_component_name()
    local name = vim.fn.expand("%:t:r")
    if name == "" then
      return "Component"
    end

    return name:gsub("[-_](%w)", function(char)
      return char:upper()
    end):gsub("^%l", string.upper)
  end

  ls.filetype_extend("javascriptreact", { "javascript", "html", "css" })
  ls.filetype_extend("typescriptreact", { "typescript", "javascriptreact", "html", "css" })
  ls.filetype_extend("typescript", { "javascript" })



  ls.add_snippets("typescript", {
    s("nestcontroller", fmt([[
import {{ Controller, Get }} from "@nestjs/common";
import {{ {}Service }} from "./{}.service";

@Controller("{}")
export class {}Controller {{
  constructor(private readonly {}Service: {}Service) {{}}

  @Get()
  findAll() {{
    return this.{}Service.findAll();
  }}
}}
]], {
      i(1, "Users"),
      i(2, "users"),
      rep(2),
      rep(1),
      i(3, "users"),
      rep(1),
      rep(3),
    })),
    s("nestservice", fmt([[
import {{ Injectable }} from "@nestjs/common";

@Injectable()
export class {}Service {{
  findAll() {{
    return [];
  }}

  findOne(id: string) {{
    return {{ id }};
  }}
}}
]], {
      i(1, "Users"),
    })),
    s("nestmodule", fmt([[
import {{ Module }} from "@nestjs/common";
import {{ {}Controller }} from "./{}.controller";
import {{ {}Service }} from "./{}.service";

@Module({{
  controllers: [{}Controller],
  providers: [{}Service],
  exports: [{}Service],
}})
export class {}Module {{}}
]], {
      i(1, "Users"),
      i(2, "users"),
      rep(1),
      rep(2),
      rep(1),
      rep(1),
      rep(1),
      rep(1),
    })),
    s("dto", fmt([[
import {{ IsString }} from "class-validator";

export class {}Dto {{
  @IsString()
  {}: string;
}}
]], {
      i(1, "CreateUser"),
      i(2, "name"),
    })),
  })

  map({ "i", "s" }, "<Tab>", function()
    if ls.expand_or_jumpable() then
      ls.expand_or_jump()
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
    end
  end, "Expand or jump snippet")

  map({ "i", "s" }, "<S-Tab>", function()
    if ls.jumpable(-1) then
      ls.jump(-1)
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
    end
  end, "Jump backward in snippet")

  map("n", "<leader>sl", "<cmd>LuaSnipListAvailable<cr>", "List available snippets")
end


setup_snippets()
-- require("mini.snippets").setup()
require("blink.cmp").setup({
  keymap = {
    preset = "default",

    ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },

    ["<CR>"] = { "accept", "fallback" },

    ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
  },

  appearance = {
    nerd_font_variant = "mono",
  },

  completion = {
    documentation = {
      auto_show = true,
    },
  },

  sources = {
    default = {
      "lsp",
      "path",
      "buffer",
      "snippets",
    },
  },

  fuzzy = {
    implementation = "prefer_rust_with_warning",
  },
  snippets = {
    preset = "luasnip",
    -- we can have  preset = "mini_snippets" too
  },
})

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
