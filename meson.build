project(
  'chess3d', 
  'vala', 'c',
  version: '0.0.1'
)

add_project_arguments(['--enable-experimental'], language: 'vala')
valac = meson.get_compiler('vala')
cc = meson.get_compiler('c')

subdir('src')
