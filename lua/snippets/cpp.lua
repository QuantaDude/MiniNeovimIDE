-- C++ snippets (LuaSnip, loaded from lua/snippets by ide.completion).
local ls = require('luasnip')
local s, t, i, c, f = ls.snippet, ls.text_node, ls.insert_node, ls.choice_node, ls.function_node
local fmt = require('luasnip.extras.fmt').fmt
local rep = require('luasnip.extras').rep

local function filename_guard()
  local name = vim.fn.expand('%:t'):upper():gsub('[^%w]', '_')
  return name ~= '' and name or 'HEADER_H'
end

local function basename()
  local n = vim.fn.expand('%:t:r')
  return n ~= '' and n or 'name'
end

return {
  s({ trig = 'main', dscr = 'int main' }, fmt([[
int main(int argc, char** argv) {{
    {}
    return 0;
}}
]], { i(0) })),

  s({ trig = 'inc', dscr = '#include <...>' }, fmt('#include <{}>', { i(1, 'vector') })),
  s({ trig = 'incl', dscr = '#include "..."' }, fmt('#include "{}"', { i(1, basename() .. '.hpp') })),
  s({ trig = 'once', dscr = '#pragma once' }, t('#pragma once')),

  s({ trig = 'guard', dscr = 'Include guard' }, fmt([[
#ifndef {}
#define {}

{}

#endif // {}
]], { f(filename_guard), f(filename_guard), i(0), f(filename_guard) })),

  s({ trig = 'region', dscr = '#pragma region (folded by ide.regions)' }, fmt([[
#pragma region {}
{}
#pragma endregion
]], { i(1, 'name'), i(0) })),

  s({ trig = 'ns', dscr = 'namespace' }, fmt([[
namespace {} {{

{}

}} // namespace {}
]], { i(1, 'name'), i(0), rep(1) })),

  s({ trig = 'cls', dscr = 'class' }, fmt([[
class {} {{
public:
    {}();
    ~{}();

private:
    {}
}};
]], { i(1, 'Name'), rep(1), rep(1), i(0) })),

  s({ trig = 'rule5', dscr = 'class with rule of five' }, fmt([[
class {} {{
public:
    {}() = default;
    ~{}() = default;

    {}(const {}&) = default;
    {}& operator=(const {}&) = default;
    {}({}&&) noexcept = default;
    {}& operator=({}&&) noexcept = default;

private:
    {}
}};
]], { i(1, 'Name'), rep(1), rep(1), rep(1), rep(1), rep(1), rep(1), rep(1), rep(1), rep(1), rep(1), i(0) })),

  s({ trig = 'struct', dscr = 'struct' }, fmt([[
struct {} {{
    {}
}};
]], { i(1, 'Name'), i(0) })),

  s({ trig = 'enumc', dscr = 'enum class' }, fmt([[
enum class {} : {} {{
    {},
}};
]], { i(1, 'Name'), i(2, 'std::uint8_t'), i(0, 'A') })),

  s({ trig = 'tmpl', dscr = 'template function' }, fmt([[
template <typename {}>
{} {}({}) {{
    {}
}}
]], { i(1, 'T'), i(2, 'void'), i(3, 'name'), i(4), i(0) })),

  s({ trig = 'tmplc', dscr = 'template class' }, fmt([[
template <typename {}>
class {} {{
public:
    {}
}};
]], { i(1, 'T'), i(2, 'Name'), i(0) })),

  s({ trig = 'concept', dscr = 'C++20 concept' }, fmt([[
template <typename {}>
concept {} = requires({} {}) {{
    {}
}};
]], { i(1, 'T'), i(2, 'Name'), rep(1), i(3, 'x'), i(0, '{ x + x } -> std::same_as<T>;') })),

  s({ trig = 'forr', dscr = 'range-based for' }, fmt([[
for ({} {} : {}) {{
    {}
}}
]], { c(1, { t('const auto&'), t('auto&'), t('auto'), t('auto&&') }), i(2, 'x'), i(3, 'container'), i(0) })),

  s({ trig = 'fori', dscr = 'indexed for' }, fmt([[
for (std::size_t {} = 0; {} < {}; ++{}) {{
    {}
}}
]], { i(1, 'i'), rep(1), i(2, 'n'), rep(1), i(0) })),

  s({ trig = 'lam', dscr = 'lambda' }, fmt('[{}]({}) {{ {} }}', { i(1, '&'), i(2), i(0) })),

  s({ trig = 'mu', dscr = 'unique_ptr via make_unique' }, fmt(
    'auto {} = std::make_unique<{}>({});', { i(1, 'p'), i(2, 'T'), i(0) })),
  s({ trig = 'ms', dscr = 'shared_ptr via make_shared' }, fmt(
    'auto {} = std::make_shared<{}>({});', { i(1, 'p'), i(2, 'T'), i(0) })),

  s({ trig = 'cexpr', dscr = 'constexpr function' }, fmt([[
constexpr {} {}({}) {{
    {}
}}
]], { i(1, 'int'), i(2, 'name'), i(3), i(0) })),

  s({ trig = 'ifc', dscr = 'if constexpr' }, fmt([[
if constexpr ({}) {{
    {}
}}
]], { i(1), i(0) })),

  s({ trig = 'try', dscr = 'try / catch' }, fmt([[
try {{
    {}
}} catch (const {}& e) {{
    {}
}}
]], { i(1), i(2, 'std::exception'), i(0, 'std::cerr << e.what() << \'\\n\';') })),

  s({ trig = 'sw', dscr = 'switch' }, fmt([[
switch ({}) {{
case {}:
    {}
    break;
default:
    break;
}}
]], { i(1), i(2), i(0) })),

  s({ trig = 'opeq', dscr = 'operator==' }, fmt(
    'bool operator==(const {}& other) const {{ return {}; }}', { i(1, 'T'), i(0, 'true') })),
  s({ trig = 'spaceship', dscr = 'defaulted <=>' }, fmt(
    'auto operator<=>(const {}&) const = default;', { i(1, 'T') })),

  s({ trig = 'cout', dscr = 'std::cout' }, fmt("std::cout << {} << '\\n';", { i(0) })),
  s({ trig = 'cerr', dscr = 'std::cerr' }, fmt("std::cerr << {} << '\\n';", { i(0) })),
  s({ trig = 'println', dscr = 'std::println (C++23)' }, fmt('std::println("{}", {});', { i(1, '{}'), i(0) })),
  s({ trig = 'fmt', dscr = 'std::format' }, fmt('std::format("{}", {})', { i(1, '{}'), i(0) })),
  s({ trig = 'sassert', dscr = 'static_assert' }, fmt('static_assert({}, "{}");', { i(1), i(2) })),

  -- tests
  s({ trig = 'gtest', dscr = 'GoogleTest TEST' }, fmt([[
TEST({}, {}) {{
    {}
}}
]], { i(1, 'Suite'), i(2, 'Name'), i(0, 'EXPECT_EQ(1, 1);') })),
  s({ trig = 'gtestf', dscr = 'GoogleTest TEST_F' }, fmt([[
TEST_F({}, {}) {{
    {}
}}
]], { i(1, 'Fixture'), i(2, 'Name'), i(0) })),
  s({ trig = 'catch', dscr = 'Catch2 / doctest TEST_CASE' }, fmt([[
TEST_CASE("{}") {{
    {}
}}
]], { i(1, 'name'), i(0, 'REQUIRE(true);') })),
  s({ trig = 'bench', dscr = 'Google Benchmark' }, fmt([[
static void BM_{}(benchmark::State& state) {{
    for (auto _ : state) {{
        {}
    }}
}}
BENCHMARK(BM_{});
]], { i(1, 'Name'), i(0), rep(1) })),
}
