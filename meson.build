# openos-files — 独立文件管理器 App
project('openos-files', 'cpp',
  version: 'DEV2026.1',
  default_options: ['cpp_std=c++17'])
qt6 = import('qt6')
qt6_dep = dependency('qt6', modules: ['Core', 'Gui', 'Qml', 'Quick', 'Svg'])
qt6_res = qt6.preprocess(qresources: 'qml.qrc')
executable('openos-files',
  sources: ['main.cpp', 'iconloader.cpp', 'iconloader.h', 'iconprovider.cpp', 'iconprovider.h', qt6_res],
  dependencies: [qt6_dep],
  install: true)