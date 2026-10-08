// This file exists only so qmlimportscanner sees the QtQuick / QtQuick3D imports:
// the static QML plugins get linked into the wasm OMEdit, and the Windows cross
// deploy (OMEdit/OMEditGUI/CMakeLists.txt) installs the modules the scan names.
// The animation scene itself is built from C++ (QQmlComponent::setData), which
// has no scannable imports.
import QtQuick
import QtQuick3D
import QtQml

Item {}
