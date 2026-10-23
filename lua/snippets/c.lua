-- C snippets (LuaSnip).
local ls = require('luasnip')
local s, t, i, f = ls.snippet, ls.text_node, ls.insert_node, ls.function_node
local fmt = require('luasnip.extras.fmt').fmt
local rep = require('luasnip.extras').rep

local function guard()
  local name = vim.fn.expand('%:t'):upper():gsub('[^%w]', '_')
  return name ~= '' and name or 'HEADER_H'
end

return {
  s({ trig = 'main', dscr = 'int main' }, fmt([[
int main(int argc, char** argv) {{
    {}
    return 0;
}}
]], { i(0) })),
  s({ trig = 'inc', dscr = '#include <...>' }, fmt('#include <{}>', { i(1, 'stdio.h') })),
  s({ trig = 'incl', dscr = '#include "..."' }, fmt('#include "{}"', { i(1) })),
  s({ trig = 'once', dscr = '#pragma once' }, t('#pragma once')),
  s({ trig = 'guard', dscr = 'Include guard' }, fmt([[
#ifndef {}
#define {}

{}

#endif /* {} */
]], { f(guard), f(guard), i(0), f(guard) })),
  s({ trig = 'fori', dscr = 'indexed for' }, fmt([[
for (size_t {} = 0; {} < {}; ++{}) {{
    {}
}}
]], { i(1, 'i'), rep(1), i(2, 'n'), rep(1), i(0) })),
  s({ trig = 'td', dscr = 'typedef struct' }, fmt([[
typedef struct {} {{
    {}
}} {};
]], { i(1, 'name'), i(0), rep(1) })),
  s({ trig = 'malloc', dscr = 'checked malloc' }, fmt([[
{}* {} = malloc({} * sizeof(*{}));
if (!{}) {{
    {}
}}
]], { i(1, 'int'), i(2, 'p'), i(3, 'n'), rep(2), rep(2), i(0, 'return -1;') })),
  s({ trig = 'printf', dscr = 'printf' }, fmt('printf("{}\\n"{});', { i(1), i(0) })),
}
