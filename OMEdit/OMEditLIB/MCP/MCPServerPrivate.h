#pragma once
// Shared free-function helpers used across MCPServer.cpp,
// MCPToolsSimulation.cpp and MCPToolsDiagram.cpp.
// All functions are defined in MCPServer.cpp.

#include <QtGlobal>
#if QT_VERSION >= QT_VERSION_CHECK(6, 4, 0) && __has_include(<QtHttpServer>)

#include <QJsonObject>
#include <QJsonValue>
#include <QImage>
#include <QString>

class LibraryTreeModel;

QJsonObject makeContent(QJsonValue content);
QJsonObject makeContent(QImage image);
bool isClassReadOnly(const QString &className, LibraryTreeModel *pModel);

#endif
