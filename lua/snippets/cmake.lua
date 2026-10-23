-- CMake snippets (LuaSnip).
local ls = require('luasnip')
local s, t, i, c = ls.snippet, ls.text_node, ls.insert_node, ls.choice_node
local fmt = require('luasnip.extras.fmt').fmt
local rep = require('luasnip.extras').rep

return {
  s({ trig = 'cmproj', dscr = 'Minimal CMake project' }, fmt([[
cmake_minimum_required(VERSION 3.20)
project({} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD {})
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable({} src/main.cpp)
target_compile_options({} PRIVATE -Wall -Wextra -Wpedantic)
]], { i(1, 'app'), c(2, { t('20'), t('23'), t('17'), t('14') }), rep(1), rep(1) })),

  s({ trig = 'cmlib', dscr = 'Library target' }, fmt([[
add_library({} {}
    {}
)
target_include_directories({} PUBLIC include)
]], { i(1, 'mylib'), c(2, { t('STATIC'), t('SHARED'), t('INTERFACE') }), i(3, 'src/lib.cpp'), rep(1) })),

  s({ trig = 'cmfetch', dscr = 'FetchContent dependency' }, fmt([[
include(FetchContent)
FetchContent_Declare({}
    GIT_REPOSITORY {}
    GIT_TAG {}
)
FetchContent_MakeAvailable({})
]], { i(1, 'dep'), i(2, 'https://github.com/org/repo.git'), i(3, 'v1.0.0'), rep(1) })),

  s({ trig = 'cmgtest', dscr = 'GoogleTest via FetchContent' }, fmt([[
include(FetchContent)
FetchContent_Declare(googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG v1.15.2
)
FetchContent_MakeAvailable(googletest)

enable_testing()
add_executable({} test/{}.cpp)
target_link_libraries({} PRIVATE GTest::gtest_main)
include(GoogleTest)
gtest_discover_tests({})
]], { i(1, 'tests'), rep(1), rep(1), rep(1) })),

  s({ trig = 'cmpkg', dscr = 'find_package + link' }, fmt([[
find_package({} REQUIRED)
target_link_libraries({} PRIVATE {}::{})
]], { i(1, 'fmt'), i(2, 'app'), rep(1), rep(1) })),
}
