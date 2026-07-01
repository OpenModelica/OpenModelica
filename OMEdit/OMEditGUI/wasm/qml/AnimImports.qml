// This file exists only so qmlimportscanner sees the QtQuick / QtQuick3D imports
// and the static QML plugins get linked into the wasm OMEdit. The animation scene
// itself is built from C++ (QQmlComponent::setData), which has no scannable imports.
import QtQuick
import QtQuick3D
import QtQml

Item {}
