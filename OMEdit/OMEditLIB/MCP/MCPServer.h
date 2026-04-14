#pragma once
#include "OMC/OMCProxy.h"
#include <QObject>
#include <QtGlobal>

#if QT_VERSION >= QT_VERSION_CHECK(6, 4, 0) && __has_include(<QtHttpServer>)
#include <QtHttpServer/QHttpServer>
#include <QTcpServer>
#include <QJsonValue>
#include <QJsonObject>
#include <QJsonArray>
#include <QImage>
#endif

class MCPServer : public QObject
{
    Q_OBJECT
public:
    explicit MCPServer(OMCProxy *proxy, int port, bool enableAdminTools, QObject *parent = nullptr);

#if QT_VERSION >= QT_VERSION_CHECK(6, 4, 0) && __has_include(<QtHttpServer>)
private:
    QHttpServer m_server;
    QTcpServer m_tcpServer;
    OMCProxy *m_proxy;
    QJsonArray m_toolsArray;
    QJsonArray m_toolsArrayNoVision;
    QJsonObject m_toolsObject;
    QJsonArray m_adminToolsArray;
    QJsonObject m_adminToolsObject;

    QJsonObject makeRPCError(QJsonValue id, int code, QString message);
    QJsonObject makeRPCResponse(QJsonValue id, QJsonObject result);
    QJsonObject makeMCPToolResponse(QJsonValue id, QJsonArray contents);
    QJsonObject makeMCPToolResponse(QJsonValue id, QJsonObject contents);
    QJsonObject makeMCPResourceResponse(QJsonValue id, QString uri, QImage image);
    QJsonObject makeMCPError(QJsonValue id, QString message);
    QHttpServerResponse handleMCPRequest(const QHttpServerRequest &request, bool vision, bool admin = false);
    QHttpServerResponse handleSimulationTool(const QString &toolName, QJsonValue id, QJsonObject arguments, bool vision);
    QHttpServerResponse handleDiagramTool(const QString &toolName, QJsonValue id, QJsonObject arguments);
    QHttpServerResponse applyShapeAnnotation(QJsonValue id, const QString &className, const QString &view, const QString &shapeStr);
#endif
};
