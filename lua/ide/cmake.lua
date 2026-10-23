require('cmake-tools').setup({
  cmake_build_directory = 'build/${variant:buildType}',
  cmake_dap_configuration = {
    name = 'cmake: launch',
    type = 'lldb',
    request = 'launch',
    stopOnEntry = false,
  },
})
