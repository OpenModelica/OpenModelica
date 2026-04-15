#include "Simulation/SimulationOutputWidget.h"
#include "MCPServer.h"
#include <QtGlobal>
#include "Modeling/MessagesWidget.h"

#if QT_VERSION < QT_VERSION_CHECK(6, 4, 0) || !__has_include(<QtHttpServer>)

MCPServer::MCPServer(OMCProxy *proxy, int port, bool enableAdminTools, QObject *parent) : QObject(parent) {
  Q_UNUSED(proxy) Q_UNUSED(port) Q_UNUSED(enableAdminTools)
  MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "The MCP server required Qt 6.4.0 (or ideally Qt 6.8.0)", Helper::scriptingKind, Helper::warningLevel));
}

#else

#include "MCPServerPrivate.h"
#include "MainWindow.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Modeling/Commands.h"
#include <QtHttpServer/QHttpServer>
#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
#include <QHttpHeaders>
#endif
#include <QTcpServer>
#include "Plotting/PlotWindowContainer.h"
#include "Plotting/VariablesWidget.h"
#include <QFileInfo>
#include <QDateTime>
#include "Util/Utilities.h"

/*!
* \brief MCPServer::makeRPCError
* Builds a JSON-RPC 2.0 protocol-level error response (sets the \c error key,
* leaves \c result absent).  Used for failures that occur \e before any tool
* logic runs: malformed JSON, wrong protocol version, unknown method, etc.
* Compare with makeMCPError(), which is the \e tool-level error path where the
* request was valid but the tool itself failed.
* \param id      Request id to echo back.
* \param code    JSON-RPC error code (currently always 0; reserved for future use).
* \param message Human-readable error description.
* \return JSON object with an \c error field conforming to the JSON-RPC 2.0 format.
*/
QJsonObject MCPServer::makeRPCError(QJsonValue id, int code, QString message) {
  QJsonObject err;
  err.insert("jsonrpc", "2.0");
  err.insert("id", id);
  QJsonObject error;
  error.insert("code", 0);
  error.insert("message", message);
  err.insert("error", error);
  return err;
}

/*!
* \brief MCPServer::makeRPCResponse
* Builds a JSON-RPC 2.0 success response object (sets the \c result key).
* Used for non-tool methods: \c initialize, \c tools/list, \c resources/list.
* Tool calls use makeMCPToolResponse() / makeMCPError() instead, because the
* MCP specification requires tool outcomes to be expressed via \c result.isError
* so the LLM client can read and potentially recover from errors.
* \param id     Request id to echo back.
* \param result The \c result payload to include in the response.
* \return JSON object with a \c result field conforming to the JSON-RPC 2.0 format.
*/
QJsonObject MCPServer::makeRPCResponse(QJsonValue id, QJsonObject result) {
  QJsonObject response;
  response.insert("jsonrpc", "2.0");
  response.insert("id", id);
  response.insert("result", result);
  return response;
}

/*!
* \brief appendMCPResponseWithMessages
* Drains the pending MCP message queue from MessagesWidget and appends each
* non-empty message as a text content entry to \a content.  File name and
* line number are prepended when available.
* \param content Content array to which the message entries are appended.
*/
static void appendMCPResponseWithMessages(QJsonArray &content) {
  for (MessageItem item : MessagesWidget::instance()->takeMCPMessages()) {
    if (item.getMessage().isEmpty()) continue;
    QString text = item.getMessage();
    if (!item.getFileName().isEmpty()) {
      text = item.getFileName() + ":" + item.getLineStart() + ": " + text;
    }
    content.append(QJsonObject{{"type", "text"}, {"text", text}});
  }
}

/*!
* \brief MCPServer::makeMCPToolResponse
* Builds an MCP \c tools/call success response wrapping \a contents, appending
* any pending OMEdit diagnostic messages collected during the tool execution.
*
* Per the MCP specification a tool call \e always returns a JSON-RPC \c result
* (never a JSON-RPC \c error), so the LLM client can read the content.
* Success vs. failure is signalled by \c result.isError, not by the JSON-RPC
* layer.  This function sets \c isError to \c false; use makeMCPError() when
* the tool itself fails.
* \param id       Request id to echo back.
* \param contents Array of MCP content objects (text or image).
* \return JSON-RPC response object with \c result.isError set to \c false.
*/
QJsonObject MCPServer::makeMCPToolResponse(QJsonValue id, QJsonArray contents) {
  QJsonArray content = contents;
  appendMCPResponseWithMessages(content);
  QJsonObject response;
  response.insert("jsonrpc", "2.0");
  response.insert("id", id);
  QJsonObject result;
  result.insert("isError", false);
  result.insert("content", content);
  response.insert("result", result);
  return response;
}

/*!
* \brief MCPServer::makeMCPToolResponse
* Convenience overload that accepts a single MCP content object, wrapping it in
* a one-element content array before forwarding to the array overload.
* \param id       Request id to echo back.
* \param contents Single MCP content object (text or image).
* \return JSON-RPC response object with \c result.isError set to \c false.
*/
QJsonObject MCPServer::makeMCPToolResponse(QJsonValue id, QJsonObject contents) {
  QJsonArray content = {contents};
  appendMCPResponseWithMessages(content);
  QJsonObject response;
  response.insert("jsonrpc", "2.0");
  response.insert("id", id);
  QJsonObject result;
  result.insert("isError", false);
  result.insert("content", content);
  response.insert("result", result);
  return response;
}

/*!
* \brief MCPServer::makeMCPResourceResponse
* Builds an MCP \c resources/read response that returns \a image as a
* base64-encoded PNG blob associated with \a uri.
* \param id    Request id to echo back.
* \param uri   Resource URI echoed back in the response.
* \param image Image to encode and embed.
* \return JSON-RPC response object in the MCP resource-read format.
*/
QJsonObject MCPServer::makeMCPResourceResponse(QJsonValue id, QString uri, QImage image) {
  QJsonObject response;
  response.insert("jsonrpc", "2.0");
  response.insert("id", id);
  QJsonObject result;
  response.insert("result", QJsonObject{
    {"contents", QJsonArray{QJsonObject{
      {"uri", uri},
      {"mimeType", "image/png"},
      {"blob", QString::fromStdString(QByteArray::fromRawData((const char*)image.bits(), image.sizeInBytes()).toBase64().toStdString())}
    }}}
  });
  return response;
}

/*!
* \brief MCPServer::makeMCPError
* Builds an MCP \c tools/call error response with \c result.isError set to
* \c true.  Any pending OMEdit diagnostic messages are appended to the content
* array alongside the error text.
*
* Even though this represents an error, it is still a JSON-RPC \e success
* (the \c result key is set, not \c error), because the MCP specification
* requires tool outcomes to travel through \c result so that the LLM client
* can read and act on the error message.  Use makeRPCError() only for
* protocol-level failures that occur before a tool is dispatched.
* \param id      Request id to echo back.
* \param message Error description shown to the MCP client.
* \return JSON-RPC response object with \c result.isError set to \c true.
*/
QJsonObject MCPServer::makeMCPError(QJsonValue id, QString message) {
  QJsonArray content;
  content.append(QJsonObject{{"type", "text"}, {"text", "Error: " + message}});
  appendMCPResponseWithMessages(content);
  QJsonObject response;
  response.insert("jsonrpc", "2.0");
  response.insert("id", id);
  response.insert("result", QJsonObject{{"content", content}, {"isError", true}});
  return response;
}

const QJsonArray resourcesArray = QJsonArray{
  QJsonObject{
    {"name", "classDiagram"},
    {"description", "A class diagram for the model currently active in the OMEdit GUI. The class diagram is returned as a PNG image."},
    {"uri", "omedit://classDiagram"},
    {"annotations", QJsonObject{
      {"readOnlyHint", true},
      {"destructiveHint", false}
    }}
  }
};

#if QT_VERSION < QT_VERSION_CHECK(6, 9, 0)
/*!
* \brief toJson
* Converts the \c QJsonValue to a \c QByteArray when \c QJsonValue::toJson is
* not available.
* \param value JSON value to convert to QByteArray
* \return QByteArray representing \c value
*/
static QByteArray toJson(const QJsonValue &value) {
    // Wrap any value in a temporary array
    QJsonArray wrapper;
    wrapper.append(value);

    QJsonDocument doc(wrapper);
    QByteArray json = doc.toJson(QJsonDocument::Compact);

    // Remove the leading '[' and trailing ']' added by the array wrapper
    return json.mid(1, json.size() - 2);
}
#endif

/*!
* \brief makeContent
* Creates an MCP text content object from \a content.
* String values are stored verbatim; all other JSON types are serialised to
* compact JSON first.
* \param content JSON value to present as text.
* \return MCP content object with \c type set to \c "text".
*/
QJsonObject makeContent(QJsonValue content) {
  QJsonObject result;
  result.insert("type", "text");
  if (content.isString()) {
    result.insert("text", content.toString());
  } else {
    #if QT_VERSION >= QT_VERSION_CHECK(6, 9, 0)
    result.insert("text", QString(content.toJson(QJsonDocument::Compact)));
    #else
    result.insert("text", QString(toJson(content)));
    #endif
  }
  return result;
}

/*!
* \brief makeContent
* Creates an MCP image content object from \a image, encoding it as a
* base64-encoded PNG.
* \param image Image to encode.
* \return MCP content object with \c type set to \c "image" and
*         \c mimeType set to \c "image/png".
*/
QJsonObject makeContent(QImage image) {
  QJsonObject result;
  result.insert("type", "image");
  result.insert("mimeType", "image/png");
  // Convert QImage to base64 encoded string
  QByteArray byteArray;
  QBuffer buffer(&byteArray);
  buffer.open(QIODevice::WriteOnly);
  image.save(&buffer, "PNG");
  result.insert("data", QString::fromStdString(byteArray.toBase64().toStdString()));
  return result;
}

static const QJsonObject notifyToolsImageWasReturned = makeContent("Returned the image. If you cannot see it, use a different tool as you do not have vision capabilities.");

/*!
* \brief colorToModelica
* Converts a JSON RGB color object to a Modelica color literal of the form \c {r,g,b}.
* \param c JSON object with integer fields \c r, \c g and \c b (range 0–255).
* \return Modelica color string, e.g. \c {255,0,0}.
*/
static QString colorToModelica(const QJsonObject &c) {
  return QString("{%1,%2,%3}").arg(c.value("r").toInt()).arg(c.value("g").toInt()).arg(c.value("b").toInt());
}

/*!
* \brief filledShapeArgs
* Collects the optional filled-shape annotation arguments present in \a arguments
* and returns them as Modelica keyword-argument strings ready to be joined into
* an annotation.  Recognised keys: \c lineColor, \c fillColor, \c fillPattern,
* \c lineThickness.
* \param arguments Tool arguments JSON object.
* \return List of Modelica annotation argument strings for the present options.
*/
static QStringList filledShapeArgs(const QJsonObject &arguments) {
  QStringList args;
  if (arguments.contains("lineColor"))
  args.append("lineColor=" + colorToModelica(arguments.value("lineColor").toObject()));
  if (arguments.contains("fillColor"))
  args.append("fillColor=" + colorToModelica(arguments.value("fillColor").toObject()));
  if (arguments.contains("fillPattern"))
  args.append(QString("fillPattern=FillPattern.%1").arg(arguments.value("fillPattern").toString()));
  if (arguments.contains("lineThickness"))
  args.append(QString("lineThickness=%1").arg(arguments.value("lineThickness").toDouble()));
  return args;
}

/*!
* \brief pointsToModelica
* Converts a JSON array of \c {x,y} point objects to a Modelica points literal,
* e.g. \c {{0,0},{10,10}}.
* \param points JSON array of objects each having \c x and \c y numeric fields.
* \return Modelica points literal string.
*/
static QString pointsToModelica(const QJsonArray &points) {
  QStringList pts;
  for (const auto &p : points) {
    QJsonObject pt = p.toObject();
    pts.append(QString("{%1,%2}").arg(pt.value("x").toDouble()).arg(pt.value("y").toDouble()));
  }
  return "{" + pts.join(",") + "}";
}

/*!
* \brief extentToModelica
* Formats four coordinates as a Modelica \c extent annotation attribute,
* e.g. \c extent={{x1,y1},{x2,y2}}.
* \param x1 Left x coordinate.
* \param y1 Bottom y coordinate.
* \param x2 Right x coordinate.
* \param y2 Top y coordinate.
* \return Modelica extent attribute string.
*/
static QString extentToModelica(double x1, double y1, double x2, double y2) {
  return QString("extent={{%1,%2},{%3,%4}}").arg(x1).arg(y1).arg(x2).arg(y2);
}

/*!
* \brief isClassReadOnly
* Returns \c true if the top-level class of \a className is a system library or
* marked read-only, preventing any modification via the MCP interface.
* \param className   Fully-qualified Modelica class name.
* \param pModel      Library tree model used to look up the top-level item.
* \return \c true when the class must not be modified; \c false otherwise.
*/
bool isClassReadOnly(const QString &className, LibraryTreeModel *pModel)
{
  QString topLevel = StringHandler::getFirstWordBeforeDot(className);
  LibraryTreeItem *pTopLevel = pModel->findLibraryTreeItem(topLevel);
  return pTopLevel && (pTopLevel->isSystemLibrary() || pTopLevel->isReadOnly());
}

/*!
* \brief typeCheck
* Validates \a argument against a JSON Schema-style type descriptor \a argType.
* Supports primitive types (\c string, \c number, \c boolean), \c array (with
* per-element type checking via \c items), and \c object (with required-property
* enforcement and \c patternProperties support).
* \param argType  JSON Schema object describing the expected type.
* \param argument JSON value to validate.
* \return An empty string on success, or a human-readable error message on failure.
*/
QString typeCheck(QJsonObject argType, QJsonValue argument) {
  QString argTypeName = argType.value("type").toString();
  if (argTypeName == "string" && argument.isString()) {
    return "";
  }
  if (argTypeName == "number" && argument.isDouble()) {
    return "";
  }
  if (argTypeName == "boolean" && argument.isBool()) {
    return "";
  }
  if (argTypeName == "array" && argument.isArray()) {
    QJsonObject itemsType = argType.value("items").toObject();
    for (const auto &item : argument.toArray()) {
      QString error = typeCheck(itemsType, item);
      if (!error.isEmpty()) {
        return error;
      }
    }
    return "";
  }
  if (argTypeName == "object" && argument.isObject()) {
    QJsonObject props = argType.value("properties").toObject();
    QJsonArray required = argType.value("required").toArray();
    for (const auto &req : required) {
      if (!argument.toObject().contains(req.toString())) {
        return QString("Missing required property: %1").arg(req.toString());
      }
    }
    for (const auto &key : argument.toObject().keys()) {
      QJsonObject propType;
      if (!props.contains(key)) {
        for (const auto &pattern : argType.value("patternProperties").toObject().keys()) {
          QRegularExpression re(pattern);
          if (re.match(key).hasMatch()) {
            propType = argType.value("patternProperties").toObject().value(pattern).toObject();
            break;
          }
        }
        if (propType.isEmpty()) {
          return QString("Unknown property: %1").arg(key);
        }
      } else {
        propType = props.value(key).toObject();
      }
      QString error = typeCheck(propType, argument.toObject().value(key));
      if (!error.isEmpty()) {
        return error;
      }
    }
    return "";
  }
  #if QT_VERSION >= QT_VERSION_CHECK(6, 9, 0)
  return QString("Wrong type for argument, got %1 expected type %2").arg(argument.toJson(QJsonDocument::Compact)).arg(QJsonDocument(argType).toJson(QJsonDocument::Compact));
  #else
  return QString("Wrong type for argument, got %1 expected type %2").arg(toJson(argument)).arg(QJsonDocument(argType).toJson(QJsonDocument::Compact));
  #endif
}


/*!
* \brief MCPServer::handleMCPRequest
* Main JSON-RPC 2.0 request dispatcher for the MCP HTTP endpoint.
*
* Supported JSON-RPC methods:
* \list
*   \li \c initialize – returns server info, capabilities and tool instructions.
*   \li \c notifications/initialized – acknowledged silently (no response body).
*   \li \c tools/list – returns the appropriate tool list for the endpoint
*       (vision / no-vision / admin).
*   \li \c tools/call – validates arguments via typeCheck, then dispatches to the
*       inline handlers for simple tools or to handleSimulationTool /
*       handleDiagramTool for thematic groups.
*   \li \c resources/list – returns the static list of available MCP resources.
*   \li \c resources/read – (partially implemented) reads a named resource.
* \endlist
* \param request HTTP request; the body must contain a JSON-RPC 2.0 object.
* \param vision  Whether the client supports receiving image content.
* \param admin   Whether admin-only tools should be exposed and honoured.
* \return HTTP response whose body contains the JSON-RPC reply object.
*/
QHttpServerResponse MCPServer::handleMCPRequest(const QHttpServerRequest &request, bool vision, bool admin) {
  const auto doc = QJsonDocument::fromJson(request.body());
  if (doc.isNull() || !doc.isObject()) {
    return makeRPCError(0, 0, "Invalid JSON");
  }
  QJsonObject body = doc.object();
  QJsonValue id = body.value("id");
  if (body.value("jsonrpc").toString() != "2.0") {
    return makeRPCError(id, 0, "Invalid JSON-RPC version");
  }
  if (!(body.value("id").isString() || body.value("id").isDouble())) {
    return makeRPCError(id, 0, "Invalid request ID");
  }
  QString method = body.value("method").toString();
  if (method == "initialize") {
    // Handle initialization
    QJsonObject result = {
      {"protocolVersion", "2025-11-25"},
      {"serverInfo", QJsonObject{
        {"name", "OMEdit" + QString(admin ? "-admin" : (vision ? "" : "-noVL"))},
        {"title", "OMEdit MCP Server" + QString(admin ? " (admin)" : (vision ? "" : " without vision capabilities"))},
        {"version", "1.0.0"},
        {"icons", QJsonArray{QJsonObject{
          {"src", request.url().toString(QUrl::RemovePath) + "/icon.png"},
          {"mimeType", "image/png"},
          {"sizes", QJsonArray{"any"}}
        }}},
        {"description", "OMEdit is a Modelica development environment that is part of the OpenModelica project."},
        {"websiteUrl", "https://openmodelica.org"}
      }
    },
    {"instructions", "Use the tools provided by this server to interact with the Modelica classes loaded in OMEdit. You can query information as well as perform actions on the classes."},
    {"capabilities", QJsonObject{
      {"tools", QJsonObject{}},
      // {"resources", QJsonObject{}}
    }
  }
};
return makeRPCResponse(id, result);
}
if (method == "notifications/initialized") {
  return QHttpServerResponse("");  // No response for notifications
}
if (method == "tools/list") {
  QJsonArray tools = vision ? m_toolsArray : m_toolsArrayNoVision;
  if (admin) {
    for (const auto &tool : m_adminToolsArray)
    tools.append(tool);
  }
  return makeRPCResponse(id, QJsonObject{{"tools", tools}});
}
if (method == "tools/call") {
  if (!body.contains("params") || !body.value("params").isObject()) {
    return makeRPCError(id, 0, "Missing or invalid params");
  }
  QJsonObject params = body.value("params").toObject();
  if (!params.contains("name") || !params.value("name").isString() || !params.contains("arguments") || !params.value("arguments").isObject()) {
    return makeRPCError(id, 0, "Missing or invalid tool name");
  }
  QString toolName = params.value("name").toString();
  QJsonObject arguments = params.value("arguments").toObject();
  QJsonObject schema = m_toolsObject.value(toolName).toObject().value("inputSchema").toObject();
  if (schema.isEmpty() && admin)
  schema = m_adminToolsObject.value(toolName).toObject().value("inputSchema").toObject();
  QString error = typeCheck(schema, arguments);
  if (!error.isEmpty()) {
    return makeMCPError(id, error);
  }

  MessagesWidget::instance()->startMCPMessageCollection();

  if (toolName == "getClassNames") {
    QString className = arguments.contains("className") ? arguments.value("className").toString() : "AllLoadedClasses";
    if (className != "AllLoadedClasses" && !m_proxy->existClass(className)) {
      return makeMCPError(id, QString("Class not found: %1").arg(className));
    }
    QStringList classNames = m_proxy->getClassNames(className);
    return makeMCPToolResponse(id, makeContent(QJsonArray::fromStringList(classNames)));
  }
  if (toolName == "getSourceCode") {
    QString className = arguments.value("className").toString(); // required
    if (!m_proxy->existClass(className)) {
      return makeMCPError(id, QString("Class not found: %1").arg(className));
    }
    QString code = m_proxy->listFile(className);
    return makeMCPToolResponse(id, makeContent(code));
  }
  if (toolName == "setSourceCode") {
    QString className = arguments.value("className").toString(); // required
    QStringList parts = StringHandler::splitPath(className);
    parts.removeLast();
    QString code = arguments.value("code").toString(); // required
    if (!m_proxy->existClass(className)) {
      return makeMCPError(id, QString("Class not found: %1").arg(className));
    }
    MainWindow *mainWindow = MainWindow::instance();
    LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
    LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
    if (pLibraryTreeItem == nullptr) {
      return makeMCPError(id, QString("Class not found: %1").arg(className));
    }
    if (isClassReadOnly(className, pLibraryTreeModel)) {
      return makeMCPError(id, QString("Cannot modify class in a system library or read-only package: %1").arg(className));
    }
    QString within = "";
    if (!parts.isEmpty() && !code.startsWith("within ")) {
      within = "within " + QStringList(parts).join('.') + ";\n";
    }
    LibraryTreeItem *pParentLibraryTreeItem = pLibraryTreeItem->isInPackageOneFile() ? pLibraryTreeItem->parent() : pLibraryTreeItem;
    if (!m_proxy->loadString(within + code, pParentLibraryTreeItem->getFileName(), Helper::utf8, pParentLibraryTreeItem->isSaveFolderStructure())) {
      return makeMCPError(id, QString("Failed to load source code for class: %1").arg(className));
    }
    // pLibraryTreeItem->updateClassInformation();
    ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
    if (pModelWidget) {
      pModelWidget->reDrawModelWidget();
    }
    pLibraryTreeModel->updateLibraryTreeItemClassText(pLibraryTreeItem);
    return makeMCPToolResponse(id, makeContent(QString("Source code updated for class: %1").arg(className)));
  }
  if (toolName == "createClass") {
    QString className = arguments.value("className").toString(); // required
    QStringList parts = StringHandler::splitPath(className);
    QString name = parts.last();
    QString parentClassName = QStringList(parts.mid(0, parts.size() - 1)).join('.');
    QString specialization = arguments.contains("specialization") ? arguments.value("specialization").toString().toLower() : "model";
    QString extendsClassName = arguments.contains("extendsClass") ? arguments.value("extendsClass").toString() : "";
    bool partial = arguments.contains("partial") && arguments.value("partial").toBool();
    bool encapsulated = arguments.contains("encapsulated") && arguments.value("encapsulated").toBool();
    MainWindow *mainWindow = MainWindow::instance();
    LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
    LibraryTreeItem *pExtendsLibraryTreeItem = nullptr;
    if (!extendsClassName.isEmpty()) {
      if (!m_proxy->existClass(extendsClassName)) {
        return makeMCPError(id, QString("Extends class not found: %1").arg(extendsClassName));
      }
      pExtendsLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(extendsClassName);
      if (!pExtendsLibraryTreeItem) {
        return makeMCPError(id, QString("Extends class not found: %1").arg(extendsClassName));
      }
    }
    LibraryTreeItem *pParentLibraryTreeItem = pLibraryTreeModel->getRootLibraryTreeItem();
    if (!parentClassName.isEmpty()) {
      pParentLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(parentClassName);
      if (!pParentLibraryTreeItem) {
        return makeMCPError(id, QString("Parent class not found: %1").arg(parentClassName));
      }
      if (isClassReadOnly(parentClassName, pLibraryTreeModel)) {
        return makeMCPError(id, QString("Cannot modify class in a system library or read-only package: %1").arg(parentClassName));
      }
    }
    if (m_proxy->existClass(className) || pLibraryTreeModel->findLibraryTreeItemOneLevel(className)) {
      return makeMCPError(id, QString("Class already exists: %1").arg(className));
    }
    QString modelicaClass;
    if (encapsulated) modelicaClass += "encapsulated ";
    if (partial) modelicaClass += "partial ";
    modelicaClass += specialization;
    bool ok;
    if (parentClassName.isEmpty()) {
      ok = m_proxy->createClass(modelicaClass, name, pExtendsLibraryTreeItem);
    } else {
      ok = m_proxy->createSubClass(modelicaClass, name, pParentLibraryTreeItem, pExtendsLibraryTreeItem);
    }
    if (!ok) {
      return makeMCPError(id, QString("Failed to create class %1: %2").arg(className).arg(m_proxy->getErrorString()));
    }
    LibraryTreeItem *pNewLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(name, pParentLibraryTreeItem, false, false, true);
    if (pParentLibraryTreeItem != pLibraryTreeModel->getRootLibraryTreeItem() && pParentLibraryTreeItem->isSaveInOneFile()) {
      pNewLibraryTreeItem->setSaveContentsType(LibraryTreeItem::SaveInOneFile);
    }
    pLibraryTreeModel->showModelWidget(pNewLibraryTreeItem, true);
    if (pNewLibraryTreeItem->getModelWidget()) {
      pNewLibraryTreeItem->getModelWidget()->updateModelText();
    }
    return makeMCPToolResponse(id, makeContent(QString("Class %1 created successfully").arg(className)));
  }
  if (toolName == "activeModel") {
    MainWindow *mainWindow = MainWindow::instance();
    ModelWidget *pModelWidget = mainWindow->getModelWidgetContainer()->getCurrentModelWidget();
    if (!pModelWidget) {
      return makeMCPError(id, QString("No active model"));
    }
    return makeMCPToolResponse(id, makeContent(pModelWidget->getModelInstance()->getName()));
  }
  // ── Simulation and plotting ─────────────────────────────────────────
  if (toolName == "getSimulationResultVariables" || toolName == "resimulate" ||
    toolName == "simulate" || toolName == "plot" || toolName == "showPlot") {
      return handleSimulationTool(toolName, id, arguments, vision);
    }

    // ── Graphical modeling ────────────────────────────────────────────────
    if (toolName == "classDiagram" || toolName == "iconDiagram" ||
      toolName == "addComponent" || toolName == "setComponentPlacement" ||
      toolName == "addConnection" || toolName == "removeConnection" ||
      toolName == "listConnections" || toolName == "listConnectors" ||
      toolName == "setConnectionPlacement" || toolName == "setElementModifierValue" ||
      toolName == "listComponents" || toolName == "getComponentPlacement" ||
      toolName == "deleteComponent" || toolName == "listComponentParameters" ||
      toolName == "addRectangle" || toolName == "addEllipse" || toolName == "addLine" ||
      toolName == "addPolygon" || toolName == "addText" ||
      toolName == "listShapes" || toolName == "removeShape") {
        return handleDiagramTool(toolName, id, arguments);
      }
      if (toolName == "checkModel") {
        QString className = arguments.value("className").toString(); // required
        if (!m_proxy->existClass(className)) {
          return makeMCPError(id, QString("Class not found: %1").arg(className));
        }
        QString result = m_proxy->checkModel(className);
        return makeMCPToolResponse(id, makeContent(result));
      }
      if (admin) {
        if (toolName == "getSimulationResultPath") {
          QString className = arguments.value("className").toString();
          VariablesWidget *pVariablesWidget = MainWindow::instance()->getVariablesWidget();
          VariablesTreeItem *foundResultFile = pVariablesWidget->getVariablesTreeModel()->findVariablesTreeItemFromClassNameTopLevel(className);
          if (!foundResultFile) {
            return makeMCPError(id, QString("No simulation results found for model: %1").arg(className));
          }
          SimulationOptions simOptions = foundResultFile->getSimulationOptions();
          QString resultFilePath = simOptions.getWorkingDirectory() + "/" + simOptions.getFullResultFileName();
          return makeMCPToolResponse(id, makeContent(resultFilePath));
        }
        if (toolName == "loadFile") {
          QString fileName = arguments.value("fileName").toString();
          LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
          QStringList classesBefore = m_proxy->getClassNames();
          if (!m_proxy->loadFile(fileName, Helper::utf8, true, true, false, false, false))
          return makeMCPError(id, QString("Failed to load file: %1").arg(fileName));
          QStringList classesAfter = m_proxy->getClassNames();
          QStringList newClasses;
          for (const QString &cls : classesAfter)
          if (!classesBefore.contains(cls))
          newClasses.append(cls);
          for (const QString &cls : newClasses)
          pLibraryTreeModel->createLibraryTreeItem(cls, pLibraryTreeModel->getRootLibraryTreeItem(), true, false, true);
          return makeMCPToolResponse(id, makeContent(QString("Loaded %1. New classes: %2").arg(fileName, newClasses.isEmpty() ? "(none)" : newClasses.join(", "))));
        }
        if (toolName == "loadModel") {
          QString library = arguments.value("library").toString();
          QString version = arguments.contains("version") ? arguments.value("version").toString() : "default";
          LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
          if (pLibraryTreeModel->findLibraryTreeItem(library))
          return makeMCPError(id, QString("Library already loaded: %1").arg(library));
          if (!m_proxy->loadModel(library, version, true, "", true))
          return makeMCPError(id, QString("Failed to load library: %1 %2").arg(library, version));
          pLibraryTreeModel->createLibraryTreeItem(library, pLibraryTreeModel->getRootLibraryTreeItem(), true, true, true);
          return makeMCPToolResponse(id, makeContent(QString("Loaded library: %1 %2").arg(library, version)));
        }
        if (toolName == "resetEnvironment") {
          MainWindow *mainWindow = MainWindow::instance();

          // Unload all top-level Modelica classes (user and system) from the library.
          // Skip non-Modelica items like OMEditInternal (Text-type, no backing OMC class).
          LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
          const QList<LibraryTreeItem*> topLevelItems = pLibraryTreeModel->getRootLibraryTreeItem()->childrenItems();
          for (LibraryTreeItem *pItem : topLevelItems) {
            if (pItem->isModelica())
            pLibraryTreeModel->unloadClass(pItem, false, true);
          }

          // Remove all open simulation result files
          VariablesWidget *pVariablesWidget = mainWindow->getVariablesWidget();
          VariablesTreeModel *pVariablesTreeModel = pVariablesWidget->getVariablesTreeModel();
          VariablesTreeItem *pRootVarItem = pVariablesTreeModel->getRootVariablesTreeItem();
          while (!pRootVarItem->mChildren.isEmpty())
          pVariablesTreeModel->removeVariableTreeItem(pRootVarItem->mChildren.first());

          // Close all plot windows
          PlotWindowContainer *pPlotWindowContainer = mainWindow->getPlotWindowContainer();
          for (QMdiSubWindow *pSubWindow : pPlotWindowContainer->subWindowList()) {
            if (pPlotWindowContainer->isPlotWindow(pSubWindow->widget()))
            pSubWindow->close();
          }

          // Remove all compilation/simulation output tabs
          QTabWidget *pTabWidget = MessagesWidget::instance()->getMessagesTabWidget();
          for (int i = pTabWidget->count() - 1; i >= 0; --i) {
            if (qobject_cast<SimulationOutputWidget*>(pTabWidget->widget(i)))
            pTabWidget->removeTab(i);
          }

          // Clear the messages browser
          MessagesWidget::instance()->clearMessages();

          return makeMCPToolResponse(id, makeContent("Environment reset: all classes unloaded, simulation results removed, plot windows closed, logs cleared."));
        }
      }
      return makeMCPError(id, QString("Tool not found: %1").arg(toolName));
    }
    if (method == "resources/list") {
      /*QJsonArray resourcesArrayFixed;
      // replace the URI with the correct one based on the request URL
      for (auto resource : resourcesArray) {
      QJsonObject resourceObj = resource.toObject();
      QString uri = resourceObj.value("uri").toString();
      if (uri.startsWith("omedit://")) {
      resourceObj.insert("uri", request.url().toString(QUrl::RemovePath) + "/" + uri.mid(QString("omedit://").length()));
      }
      resourcesArrayFixed.append(resourceObj);
      }*/
      return makeRPCResponse(id, QJsonObject{{"resources", resourcesArray}});
    }
    if (method == "resources/read") {
      if (!body.contains("params") || !body.value("params").isObject()) {
        return makeRPCError(id, 0, "Missing or invalid params");
      }
      QJsonObject params = body.value("params").toObject();
      if (!params.contains("uri") || !params.value("uri").isString()) {
        return makeRPCError(id, 0, "Missing or invalid URI");
      }
      QString uri = params.value("uri").toString();
      /*if (uri == "omedit://classDiagram") {
      MainWindow *mainWindow = MainWindow::instance();
      ModelWidget *pModelWidget = mainWindow->getModelWidgetContainer()->getCurrentModelWidget();
      if (!pModelWidget) {
      return makeRPCError(id, -32002, QString("No active model"));
      }
      QImage modelImage = mainWindow->exportModelAsImage(".png", true);
      return makeMCPResourceResponse(id, uri, modelImage);
      }*/
    }
    return makeRPCError(id, 0, "Method not found");
  }

  /*!
  * \class MCPServer
  * \brief HTTP server exposing an MCP (Model Context Protocol) interface to OMEdit.
  *
  * The server listens on localhost at the configured port and exposes three endpoints:
  * \list
  *   \li \c /mcp – full tool set with vision (image) support.
  *   \li \c /mcp/novision – tool set with image-returning tools omitted.
  *   \li \c /mcp/admin – full vision tool set plus administrative tools
  *       (loadFile, loadModel, getSimulationResultPath, resetEnvironment).
  * \endlist
  * Tool definitions are loaded from Qt resource files \c Resources/json/MCPTools.json
  * and \c Resources/json/MCPAdminTools.json during construction.
  * On Qt < 6.8.0 CORS headers cannot be set and a warning is logged.
  */
  /*!
  * \brief MCPServer::MCPServer
  * Loads tool definitions from JSON resources, registers all HTTP routes, and
  * starts listening on \a port.
  * \param proxy  OMC proxy used for Modelica queries and modifications.
  * \param port   TCP port the server will listen on (localhost only).
  * \param parent Optional QObject parent.
  */
  MCPServer::MCPServer(OMCProxy *proxy, int port, bool enableAdminTools, QObject *parent) : QObject(parent), m_proxy(proxy) {
    {
      QFile file(":Resources/json/MCPTools.json");
      file.open(QIODevice::ReadOnly);
      m_toolsArray = QJsonDocument::fromJson(file.readAll()).array();
    }
    for (const auto &tool : m_toolsArray) {
      QString name = tool.toObject().value("name").toString();
      // "plot" is actually fine - we can return the data like a plot, but showPlot could have trajectories from other models
      if (name != "classDiagram" && name != "iconDiagram" && name != "showPlot")
      m_toolsArrayNoVision.append(tool);
      m_toolsObject.insert(name, tool);
    }
    {
      QFile file(":Resources/json/MCPAdminTools.json");
      file.open(QIODevice::ReadOnly);
      m_adminToolsArray = QJsonDocument::fromJson(file.readAll()).array();
    }
    for (const auto &tool : m_adminToolsArray) {
      QString name = tool.toObject().value("name").toString();
      m_adminToolsObject.insert(name, tool);
    }

    m_server.route("/mcp", QHttpServerRequest::Method::Options, [](const QHttpServerRequest &request) {Q_UNUSED(request) return "";});
    m_server.route("/mcp", QHttpServerRequest::Method::Post, [this](const QHttpServerRequest &request) {return handleMCPRequest(request, true);});
    m_server.route("/mcp/novision", QHttpServerRequest::Method::Options, [](const QHttpServerRequest &request) {Q_UNUSED(request) return "";});
    m_server.route("/mcp/novision", QHttpServerRequest::Method::Post, [this](const QHttpServerRequest &request) {return handleMCPRequest(request, false);});
    if (enableAdminTools) {
      m_server.route("/mcp/admin", QHttpServerRequest::Method::Options, [](const QHttpServerRequest &request) {Q_UNUSED(request) return "";});
      m_server.route("/mcp/admin", QHttpServerRequest::Method::Post, [this](const QHttpServerRequest &request) {return handleMCPRequest(request, true, true);});
    }

    m_server.route("/", [] () {
      return "";
    });

    m_server.route("/health", [] () {
      return "OK";
    });

    m_server.route("/icon.png", [] () {
      QFile image = QFile(":Resources/icons/modeling.png");
      if (image.exists()) {
        if (image.open(QIODevice::ReadOnly)) {
          return QHttpServerResponse(image.readAll());
        }
      }
      return QHttpServerResponse(QHttpServerResponse::StatusCode::InternalServerError);
    });

    m_server.route("/classDiagram", [] () {
      MainWindow *mainWindow = MainWindow::instance();
      ModelWidget *pModelWidget = mainWindow->getModelWidgetContainer()->getCurrentModelWidget();
      if (!pModelWidget) {
        return QHttpServerResponse("No active model", QHttpServerResponse::StatusCode::NotFound);
      }
      QImage modelImage = mainWindow->exportModelAsImage(".png", true, MainWindow::ViewSelection::Class);
      QByteArray ba;
      QBuffer buffer(&ba);
      buffer.open(QIODevice::WriteOnly);
      modelImage.save(&buffer, "PNG");
      return QHttpServerResponse(ba);
    });

    #if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
    m_server.addAfterRequestHandler(&m_server, [] (const QHttpServerRequest &req, QHttpServerResponse &resp) {
      auto h = resp.headers();
      h.append(QHttpHeaders::WellKnownHeader::AccessControlAllowOrigin, "*");
      h.append(QHttpHeaders::WellKnownHeader::AccessControlAllowHeaders, "Content-Type, Authorization, mcp-protocol-version");
      resp.setHeaders(std::move(h));
    });
    #endif

    if (!m_tcpServer.listen(QHostAddress::LocalHost, port)) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "Failed to start MCP server", Helper::scriptingKind, Helper::errorLevel));
      return;
    }
    m_server.bind(&m_tcpServer);
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "Started MCP server as http://localhost:" + QString::number(port), Helper::scriptingKind, Helper::notificationLevel));
    #if QT_VERSION < QT_VERSION_CHECK(6, 8, 0)
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "MCP server does not have support for headers (Qt < 6.8.0). AccessControlAllowOrigin can not be set, which means CORS will not work properly (no webbrowser-based MCP clients).", Helper::scriptingKind, Helper::warningLevel));
    #endif
  }

  #endif
