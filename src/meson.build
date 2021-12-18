gnome = import('gnome')

resources = gnome.compile_resources('com.github.prince781.Ch3', files('chess3d.gresource.xml'),
  c_name: 'resources')

sources = [
  resources,
  'animation.vala',
  'main.vala',
  'mainwindow.vala',
  'mat4x4.vala',
  'material.vala',
  'mesh.vala',
  'model.vala',
  'renderer.vala',
  'texture2d.vala',
  'utf8inputstream.vala',
  'vec2.vala',
  'vec3.vala'
]

dependencies = [
  dependency('glib-2.0', version: '>= 2.50'),
  dependency('gobject-2.0', version: '>= 2.50'),
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gdk-pixbuf-2.0', version: '>= 2.42'),
  dependency('gtk4', version: '>= 4.2'),
  cc.find_library('epoxy'),
  valac.find_library('gl', dirs: meson.source_root() / 'vapi'),
  cc.find_library('m', required: false)   # optional on Windows
]

executable(
  'chess3d',
  sources,
  dependencies: dependencies,
  install: true
)
