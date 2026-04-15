#include <QtGlobal>
#include "MCPServer.h"

#if QT_VERSION >= QT_VERSION_CHECK(6, 4, 0) && __has_include(<QtHttpServer>)

#include "MCPServerPrivate.h"
#include "MainWindow.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Modeling/Commands.h"
#include "Util/Utilities.h"

// ──────────────────────────────────────────────────────────────
// File-local annotation helpers
// ──────────────────────────────────────────────────────────────

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
* Collects the optional filled-shape annotation arguments present in \a arguments and
* returns them as Modelica keyword-argument strings ready to be joined into an annotation.
* Recognised keys: \c lineColor, \c fillColor, \c fillPattern, \c lineThickness.
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

// ──────────────────────────────────────────────────────────────
// MCPServer member implementations
// ──────────────────────────────────────────────────────────────

/*!
* \brief MCPServer::applyShapeAnnotation
* Appends a pre-built Modelica shape string to the graphics annotation of the
* named view of \a className, then redraws the model widget.
*
* The function reads the current coordinate system and graphics list from the
* view, appends \a shapeStr, and writes the combined annotation back via
* \c addClassAnnotation.  The model widget is redrawn and, for icon-view changes,
* the library icon is refreshed.
* \param id        JSON-RPC request id echoed back on error.
* \param className Fully-qualified Modelica class name.
* \param view      Target view: \c "icon" or \c "diagram".
* \param shapeStr  Modelica shape annotation string (e.g. \c "Rectangle(...)").
* \return MCP tool success response, or an error response on failure.
*/
QHttpServerResponse MCPServer::applyShapeAnnotation(QJsonValue id, const QString &className, const QString &view, const QString &shapeStr) {
  if (view != "icon" && view != "diagram")
  return makeMCPError(id, QString("Invalid view: %1. Must be \"icon\" or \"diagram\".").arg(view));
  MainWindow *mainWindow = MainWindow::instance();
  LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
  if (!pLibraryTreeItem)
  return makeMCPError(id, QString("Class not found: %1").arg(className));
  if (isClassReadOnly(className, pLibraryTreeModel))
  return makeMCPError(id, QString("Cannot modify class in a system library or read-only package: %1").arg(className));
  if (!pLibraryTreeItem->getModelWidget())
  pLibraryTreeModel->showModelWidget(pLibraryTreeItem, false);
  ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
  GraphicsView *pGraphicsView = (view == "icon") ? pModelWidget->getIconGraphicsView() : pModelWidget->getDiagramGraphicsView();
  if (view == "diagram" && !pModelWidget->isDiagramViewLoaded())
  pModelWidget->loadDiagramViewNAPI();
  // Read all existing shapes so we append rather than replace the graphics list
  QStringList coordinateSystemList;
  QStringList graphicsList;
  pGraphicsView->getCoordinateSystemAndGraphics(coordinateSystemList, graphicsList);
  graphicsList.append(shapeStr);
  QString viewName = (view == "icon") ? "Icon" : "Diagram";
  QString annotationString;
  if (!coordinateSystemList.isEmpty())
  annotationString = QString("annotate=%1(coordinateSystem=CoordinateSystem(%2), graphics={%3})").arg(viewName, coordinateSystemList.join(","), graphicsList.join(","));
  else
  annotationString = QString("annotate=%1(graphics={%2})").arg(viewName, graphicsList.join(","));
  if (!m_proxy->addClassAnnotation(className, annotationString))
  return makeMCPError(id, QString("Failed to add shape to %1 of class %2").arg(view, className));
  pModelWidget->reDrawModelWidget();
  if (view == "icon")
  pLibraryTreeItem->handleIconUpdated();
  pLibraryTreeModel->updateLibraryTreeItemClassText(pLibraryTreeItem);
  QCoreApplication::processEvents();
  return makeMCPToolResponse(id, makeContent(QString("Shape added to %1 view of class %2").arg(view, className)));
}

/*!
* \brief MCPServer::handleDiagramTool
* Dispatches MCP tool calls related to graphical diagram editing and component introspection.
*
* Handled tools:
* \list
*   \li \c classDiagram / \c iconDiagram – exports the diagram or icon view as a PNG image.
*   \li \c addComponent – instantiates a component class inside a model at a given position.
*   \li \c setComponentPlacement – moves, resizes, rotates, or hides a component.
*   \li \c addConnection – creates a connection between two connectors with auto-routed lines.
*   \li \c removeConnection – deletes an existing connection.
*   \li \c listConnections – returns all connections in a model.
*   \li \c listConnectors – returns all connector instances reachable from the diagram view.
*   \li \c setConnectionPlacement – replaces the waypoints of an existing connection.
*   \li \c setElementModifierValue – sets a modifier on a component instance.
*   \li \c listComponents – lists all directly-owned component instances.
*   \li \c getComponentPlacement – returns position, size and rotation of a component.
*   \li \c deleteComponent – removes a component and all its connections.
*   \li \c listComponentParameters – returns the parameters of a component's class,
*       with instance-level modifiers applied.
*   \li \c addRectangle / \c addEllipse / \c addLine / \c addPolygon / \c addText –
*       add graphical shape annotations to a class view.
*   \li \c listShapes – returns the raw Modelica graphics strings for a view.
*   \li \c removeShape – removes a specific shape from a view by its Modelica string.
* \endlist
* \param toolName  Name of the MCP tool to execute.
* \param id        JSON-RPC request id echoed back in the response.
* \param arguments Tool arguments as a JSON object.
* \return A QHttpServerResponse containing the MCP tool result or error.
*/
QHttpServerResponse MCPServer::handleDiagramTool(const QString &toolName, QJsonValue id, QJsonObject arguments)
{
  if (toolName == "classDiagram" || toolName == "iconDiagram") {
    bool isIcon = (toolName == "iconDiagram");
    MainWindow *mainWindow = MainWindow::instance();
    QString className = arguments.contains("className") ? arguments.value("className").toString() : ""; // optional
    ModelWidget *pModelWidget = nullptr;
    if (className.isEmpty()) {
      pModelWidget = mainWindow->getModelWidgetContainer()->getCurrentModelWidget();
      if (!pModelWidget) {
        return makeMCPError(id, QString("No active model"));
      }
      className = pModelWidget->getModelInstance()->getName();
    } else {
      if (!m_proxy->existClass(className)) {
        return makeMCPError(id, QString("Class not found: %1").arg(className));
      }
      LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
      LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
      if (pLibraryTreeItem == nullptr) {
        return makeMCPError(id, QString("Class not found: %1").arg(className));
      }
      pModelWidget = pLibraryTreeItem->getModelWidget();
      if (!pModelWidget) {
        pLibraryTreeModel->showModelWidget(pLibraryTreeItem, false);
        pModelWidget = pLibraryTreeItem->getModelWidget();
        pModelWidget->loadDiagramViewNAPI();
        if (!pModelWidget) {
          return makeMCPError(id, QString("Model could not opened: %1").arg(className));
        }
      }
    }
    GraphicsView *pGraphicsView = isIcon ? pModelWidget->getIconGraphicsView() : pModelWidget->getDiagramGraphicsView();
    pGraphicsView->clearSelection();
    MainWindow::ViewSelection viewSelection = isIcon ? MainWindow::ViewSelection::Icon : MainWindow::ViewSelection::Class;
    QImage modelImage = mainWindow->exportModelAsImage(".png", true, viewSelection, pModelWidget, QSize(1024, 1024));
    QRectF extent = pGraphicsView->mMergedCoordinateSystem.getExtentRectangle();
    QString extentStr = QString("(%1,%2), (%3,%4)").arg(extent.topLeft().x()).arg(extent.topLeft().y()).arg(extent.bottomRight().x()).arg(extent.bottomRight().y());
    QString label = isIcon ? "Icon diagram for " : "Model diagram for ";
    QString extentNote = isIcon ? ". The diagram has the extent: " : ". The diagram has the extent (marked by a rectangle with a thin gray border): ";
    QJsonArray contents = QJsonArray{{makeContent(label + className + extentNote + extentStr + " image size: " + QString::number(modelImage.width()) + "x" + QString::number(modelImage.height()))}, makeContent(modelImage)};
    return makeMCPToolResponse(id, contents);
  }
  if (toolName == "addComponent") {
    QString className = arguments.value("className").toString(); // required
    QString componentClassName = arguments.value("componentClassName").toString(); // required
    QString componentName = arguments.value("componentName").toString(); // required
    double x = arguments.value("x").toDouble();
    double y = arguments.value("y").toDouble();
    MainWindow *mainWindow = MainWindow::instance();
    LibraryWidget *pLibraryWidget = mainWindow->getLibraryWidget();
    LibraryTreeModel *pLibraryTreeModel = pLibraryWidget->getLibraryTreeModel();
    LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
    if (pLibraryTreeItem == nullptr) {
      return makeMCPError(id, QString("Class not found: %1").arg(className));
    }
    if (isClassReadOnly(className, pLibraryTreeModel)) {
      return makeMCPError(id, QString("Cannot modify class in a system library or read-only package: %1").arg(className));
    }
    if (pLibraryTreeModel->findLibraryTreeItem(componentClassName) == nullptr) {
      return makeMCPError(id, QString("Component class not found: %1").arg(componentClassName));
    }
    pLibraryTreeModel->showModelWidget(pLibraryTreeItem, true);
    QCoreApplication::processEvents();
    ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
    GraphicsView *pGraphicsView = pModelWidget->getDiagramGraphicsView();
    if (pGraphicsView->getElementObject(componentName)) {
      return makeMCPError(id, QString("Component already exists: %1 in model %2").arg(componentName, className));
    }
    ModelInfo oldModelInfo = pModelWidget->createModelInfo();
    ModelInstance::Component *pComponent = GraphicsView::createModelInstanceComponent(pModelWidget->getModelInstance(), componentName, componentClassName);
    if (!pComponent) {
      return makeMCPError(id, QString("Failed to add component %1 to model %2").arg(componentClassName, className));
    }
    pGraphicsView->addElementToView(pComponent, false, true, true, QPointF(x, y), "", true);
    ModelInfo newModelInfo = pModelWidget->createModelInfo();
    pModelWidget->getUndoStack()->push(new OMCUndoCommand(pLibraryTreeItem, oldModelInfo, newModelInfo, "Add Element", true));
    pModelWidget->updateModelText();
    if (arguments.contains("rotation") || arguments.contains("width") || arguments.contains("height")) {
      Element *pElement = pGraphicsView->getElementObject(componentName);
      if (pElement) {
        if (arguments.contains("rotation")) {
          pElement->mTransformation.setRotateAngle(arguments.value("rotation").toDouble());
        }
        if (arguments.contains("width") || arguments.contains("height")) {
          ExtentAnnotation extent = pElement->mTransformation.getExtent();
          QPointF p1 = extent.size() > 0 ? extent.at(0) : QPointF(-10, -10);
          QPointF p2 = extent.size() > 1 ? extent.at(1) : QPointF(10, 10);
          double halfW = arguments.contains("width")  ? arguments.value("width").toDouble()  / 2.0 : (p2.x() - p1.x()) / 2.0;
          double halfH = arguments.contains("height") ? arguments.value("height").toDouble() / 2.0 : (p2.y() - p1.y()) / 2.0;
          pElement->mTransformation.setExtent(QVector<QPointF>{QPointF(-halfW, -halfH), QPointF(halfW, halfH)});
        }
        pElement->setTransform(pElement->mTransformation.getTransformationMatrix());
        pElement->emitTransformHasChanged();
        pModelWidget->updateModelText();
      }
    }
    QCoreApplication::processEvents();
    return makeMCPToolResponse(id, makeContent(QString("Component %1 of class %2 added to model %3").arg(componentName, componentClassName, className)));
  }
  if (toolName == "setComponentPlacement") {
    QString className = arguments.value("className").toString(); // required
    QString componentName = arguments.value("componentName").toString(); // required
    QString view = arguments.contains("view") ? arguments.value("view").toString() : "diagram";
    if (view != "diagram" && view != "icon") {
      return makeMCPError(id, QString("Invalid view: %1. Must be \"diagram\" or \"icon\".").arg(view));
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
    pLibraryTreeModel->showModelWidget(pLibraryTreeItem, true);
    QCoreApplication::processEvents();
    ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
    GraphicsView *pGraphicsView = (view == "icon") ? pModelWidget->getIconGraphicsView() : pModelWidget->getDiagramGraphicsView();
    Element *pElement = pGraphicsView->getElementObject(componentName);
    if (!pElement) {
      return makeMCPError(id, QString("Component not found: %1 in model %2 (%3 view)").arg(componentName, className, view));
    }
    Transformation oldTransformation = pElement->mTransformation;
    if (arguments.contains("visible")) {
      pElement->mTransformation.setVisible(arguments.value("visible").toBool());
    }
    if (arguments.contains("x") || arguments.contains("y")) {
      QPointF origin = pElement->mTransformation.getOrigin();
      double x = arguments.contains("x") ? arguments.value("x").toDouble() : origin.x();
      double y = arguments.contains("y") ? arguments.value("y").toDouble() : origin.y();
      pElement->mTransformation.setOrigin(QPointF(x, y));
    }
    if (arguments.contains("rotation")) {
      pElement->mTransformation.setRotateAngle(arguments.value("rotation").toDouble());
    }
    if (arguments.contains("width") || arguments.contains("height")) {
      ExtentAnnotation extent = pElement->mTransformation.getExtent();
      QPointF p1 = extent.size() > 0 ? extent.at(0) : QPointF(-10, -10);
      QPointF p2 = extent.size() > 1 ? extent.at(1) : QPointF(10, 10);
      double halfW = arguments.contains("width")  ? arguments.value("width").toDouble()  / 2.0 : (p2.x() - p1.x()) / 2.0;
      double halfH = arguments.contains("height") ? arguments.value("height").toDouble() / 2.0 : (p2.y() - p1.y()) / 2.0;
      pElement->mTransformation.setExtent(QVector<QPointF>{QPointF(-halfW, -halfH), QPointF(halfW, halfH)});
    }
    pElement->setTransform(pElement->mTransformation.getTransformationMatrix());
    // updateElementTransformations pushes the undo command and emits transformChanging(),
    // which moves all connected connection lines along with the component.
    pElement->updateElementTransformations(oldTransformation, arguments.contains("x") || arguments.contains("y"));
    pModelWidget->updateModelText();
    // reDrawModelWidget re-fetches from OMC and redraws both icon and diagram views,
    // which is necessary for visibility changes to take effect.
    pModelWidget->reDrawModelWidget();
    QCoreApplication::processEvents();
    return makeMCPToolResponse(id, makeContent(QString("Placement of component %1 updated in model %2").arg(componentName).arg(className)));
  }
  if (toolName == "addConnection") {
    QString className = arguments.value("className").toString(); // required
    QString firstComponent = arguments.value("first").toString(); // required
    QString secondComponent = arguments.value("second").toString(); // required
    MainWindow *mainWindow = MainWindow::instance();
    LibraryWidget *pLibraryWidget = mainWindow->getLibraryWidget();
    LibraryTreeModel *pLibraryTreeModel = pLibraryWidget->getLibraryTreeModel();
    LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
    if (pLibraryTreeItem == nullptr) {
      return makeMCPError(id, QString("Class not found: %1").arg(className));
    }
    if (isClassReadOnly(className, pLibraryTreeModel)) {
      return makeMCPError(id, QString("Cannot modify class in a system library or read-only package: %1").arg(className));
    }
    ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
    pLibraryTreeModel->showModelWidget(pLibraryTreeItem, true);
    QCoreApplication::processEvents();
    ModelInstance::Model *pModel = pModelWidget->getModelInstance();
    GraphicsView *pGraphicsView = pModelWidget->getDiagramGraphicsView();
    QStringList firstElementParts = StringHandler::splitPath(firstComponent);
    QString firstElementName = firstElementParts.takeLast();
    QStringList secondElementParts = StringHandler::splitPath(secondComponent);
    QString secondElementName = secondElementParts.takeLast();
    Element *firstElementFirstPart = pGraphicsView->getElementObject(firstElementParts.join("."));
    if (!firstElementFirstPart) {
      return makeMCPError(id, QString("Could not find element %1 in model %2").arg(firstComponent).arg(className));
    }
    Element *secondElementFirstPart = pGraphicsView->getElementObject(secondElementParts.join("."));
    if (!secondElementFirstPart) {
      return makeMCPError(id, QString("Could not find element %1 in model %2").arg(secondComponent).arg(className));
    }
    Element *pFirstElement = pModelWidget->getConnectorElement(firstElementFirstPart, firstElementName);
    Element *pSecondElement = pModelWidget->getConnectorElement(secondElementFirstPart, secondElementName);
    if (!pFirstElement) {
      return makeMCPError(id, QString("Could not find element %1 in model %2").arg(firstComponent).arg(className));
    }
    if (!pSecondElement) {
      return makeMCPError(id, QString("Could not find element %1 in model %2").arg(secondComponent).arg(className));
    }
    if (!pModel->isValidConnection(firstComponent, secondComponent)) {
      return makeMCPError(id, QString("Invalid connection between %1 and %2 in model %3").arg(firstComponent).arg(secondComponent).arg(className));
    }
    ModelInfo modelInfo = pModelWidget->createModelInfo();
    if (modelInfo.getConnection(firstComponent, secondComponent)) {
      return makeMCPError(id, QString("Connection already exists between %1 and %2 in model %3").arg(firstComponent).arg(secondComponent).arg(className));
    }
    LineAnnotation *pLineAnnotation = new LineAnnotation(LineAnnotation::ConnectionType, pFirstElement, pGraphicsView);
    pLineAnnotation->setEndElement(pSecondElement);
    pLineAnnotation->addPoint(pGraphicsView->snapPointToGrid(pFirstElement->mapToScene(pFirstElement->boundingRect().center())));
    pLineAnnotation->addPoint(pGraphicsView->snapPointToGrid(pSecondElement->mapToScene(pSecondElement->boundingRect().center())));
    pLineAnnotation->manhattanizeShape();
    pLineAnnotation->setStartElementName(firstComponent);
    pLineAnnotation->setEndElementName(secondComponent);
    ModelInstance::Connection *pConnection = pGraphicsView->createModelInstanceConnection(pModel, pLineAnnotation);
    pGraphicsView->addConnectionToView(pLineAnnotation, false);
    pGraphicsView->addConnectionToClass(pLineAnnotation);
    pModelWidget->updateModelText();
    QCoreApplication::processEvents();
    pGraphicsView->handleCollidingConnections();
    pLineAnnotation->update();
    QCoreApplication::processEvents();
    return makeMCPToolResponse(id, makeContent("Connection added between " + firstComponent + " and " + secondComponent + " in model " + className));
  }
  if (toolName == "removeConnection") {
    QString className = arguments.value("className").toString(); // required
    QString firstComponent = arguments.value("first").toString(); // required
    QString secondComponent = arguments.value("second").toString(); // required
    MainWindow *mainWindow = MainWindow::instance();
    LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
    LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
    if (pLibraryTreeItem == nullptr) {
      return makeMCPError(id, QString("Class not found: %1").arg(className));
    }
    if (isClassReadOnly(className, pLibraryTreeModel)) {
      return makeMCPError(id, QString("Cannot modify class in a system library or read-only package: %1").arg(className));
    }
    pLibraryTreeModel->showModelWidget(pLibraryTreeItem, true);
    QCoreApplication::processEvents();
    ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
    GraphicsView *pGraphicsView = pModelWidget->getDiagramGraphicsView();
    LineAnnotation *pConnectionLineAnnotation = nullptr;
    for (LineAnnotation *pLine : pGraphicsView->getConnectionsList()) {
      if (pLine->getStartElementName() == firstComponent && pLine->getEndElementName() == secondComponent) {
        pConnectionLineAnnotation = pLine;
        break;
      }
    }
    if (!pConnectionLineAnnotation) {
      return makeMCPError(id, QString("Connection not found between %1 and %2 in model %3").arg(firstComponent).arg(secondComponent).arg(className));
    }
    ModelInfo oldModelInfo = pModelWidget->createModelInfo();
    pGraphicsView->deleteConnectionFromClass(pConnectionLineAnnotation);
    pModelWidget->updateModelText();
    ModelInfo newModelInfo = pModelWidget->createModelInfo();
    pModelWidget->getUndoStack()->push(new OMCUndoCommand(pLibraryTreeItem, oldModelInfo, newModelInfo, "Remove Connection", true));
    QCoreApplication::processEvents();
    return makeMCPToolResponse(id, makeContent("Connection removed between " + firstComponent + " and " + secondComponent + " in model " + className));
  }
  if (toolName == "listConnections") {
    QString className = arguments.value("className").toString(); // required
    MainWindow *mainWindow = MainWindow::instance();
    LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
    LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
    if (pLibraryTreeItem == nullptr) {
      return makeMCPError(id, QString("Class not found: %1").arg(className));
    }
    if (!pLibraryTreeItem->getModelWidget()) {
      pLibraryTreeModel->showModelWidget(pLibraryTreeItem, false);
    }
    ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
    if (!pModelWidget->isDiagramViewLoaded()) {
      pModelWidget->loadDiagramViewNAPI();
    }
    QCoreApplication::processEvents();
    GraphicsView *pGraphicsView = pModelWidget->getDiagramGraphicsView();
    QJsonArray connections;
    for (LineAnnotation *pLine : pGraphicsView->getConnectionsList()) {
      QJsonArray points;
      for (const QPointF &pt : pLine->getPoints()) {
        points.append(QJsonArray{pt.x(), pt.y()});
      }
      connections.append(QJsonObject{
        {"first", pLine->getStartElementName()},
        {"second", pLine->getEndElementName()},
        {"points", points}
      });
    }
    return makeMCPToolResponse(id, makeContent(connections));
  }
  if (toolName == "listConnectors") {
    QString className = arguments.value("className").toString(); // required
    MainWindow *mainWindow = MainWindow::instance();
    LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
    LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
    if (pLibraryTreeItem == nullptr) {
      return makeMCPError(id, QString("Class not found: %1").arg(className));
    }
    if (!pLibraryTreeItem->getModelWidget()) {
      pLibraryTreeModel->showModelWidget(pLibraryTreeItem, false);
    }
    ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
    if (!pModelWidget->isDiagramViewLoaded()) {
      pModelWidget->loadDiagramViewNAPI();
    }
    QCoreApplication::processEvents();
    GraphicsView *pGraphicsView = pModelWidget->getDiagramGraphicsView();
    QJsonArray connectors;
    std::function<void(Element*, const QString&)> collectConnectors = [&](Element *pEl, const QString &prefix) {
      if (pEl->isExtend()) {
        // Extend elements represent base classes, not instances — pass through without adding a name segment
        for (Element *pChild : pEl->getElementsList() + pEl->getInheritedElementsList()) {
          collectConnectors(pChild, prefix);
        }
        return;
      }
      QString fullName = prefix.isEmpty() ? pEl->getName() : prefix + "." + pEl->getName();
      if (pEl->isConnector()) {
        QPointF pos = pEl->mapToScene(pEl->boundingRect().center());
        connectors.append(QJsonObject{
          {"name", fullName},
          {"className", pEl->getClassName()},
          {"x", pos.x()},
          {"y", pos.y()}
        });
      } else {
        for (Element *pChild : pEl->getElementsList() + pEl->getInheritedElementsList()) {
          collectConnectors(pChild, fullName);
        }
      }
    };
    for (Element *pElement : pGraphicsView->getElementsList() + pGraphicsView->getInheritedElementsList()) {
      collectConnectors(pElement, "");
    }
    return makeMCPToolResponse(id, makeContent(connectors));
  }
  if (toolName == "setConnectionPlacement") {
    QString className = arguments.value("className").toString(); // required
    QString firstComponent = arguments.value("first").toString(); // required
    QString secondComponent = arguments.value("second").toString(); // required
    QJsonArray points = arguments.contains("points") ? arguments.value("points").toArray() : QJsonArray{};
    MainWindow *mainWindow = MainWindow::instance();
    LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
    LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
    if (pLibraryTreeItem == nullptr) {
      return makeMCPError(id, QString("Class not found: %1").arg(className));
    }
    if (isClassReadOnly(className, pLibraryTreeModel)) {
      return makeMCPError(id, QString("Cannot modify class in a system library or read-only package: %1").arg(className));
    }
    pLibraryTreeModel->showModelWidget(pLibraryTreeItem, true);
    QCoreApplication::processEvents();
    ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
    GraphicsView *pGraphicsView = pModelWidget->getDiagramGraphicsView();
    LineAnnotation *pConnectionLineAnnotation = nullptr;
    for (LineAnnotation *pLine : pGraphicsView->getConnectionsList()) {
      if (pLine->getStartElementName() == firstComponent && pLine->getEndElementName() == secondComponent) {
        pConnectionLineAnnotation = pLine;
        break;
      }
    }
    if (!pConnectionLineAnnotation) {
      return makeMCPError(id, QString("Connection not found between %1 and %2 in model %3").arg(firstComponent).arg(secondComponent).arg(className));
    }
    Element *pStartElement = pConnectionLineAnnotation->getStartElement();
    Element *pEndElement = pConnectionLineAnnotation->getEndElement();
    pConnectionLineAnnotation->clearPoints();
    pConnectionLineAnnotation->addPoint(pGraphicsView->snapPointToGrid(pStartElement->mapToScene(pStartElement->boundingRect().center())));
    for (const QJsonValue &pt : points) {
      pConnectionLineAnnotation->addPoint(QPointF(pt.toObject().value("x").toDouble(), pt.toObject().value("y").toDouble()));
    }
    pConnectionLineAnnotation->addPoint(pGraphicsView->snapPointToGrid(pEndElement->mapToScene(pEndElement->boundingRect().center())));
    pGraphicsView->handleCollidingConnections();
    pConnectionLineAnnotation->update();
    pConnectionLineAnnotation->updateConnectionAnnotation();
    pModelWidget->updateModelText();
    QCoreApplication::processEvents();
    return makeMCPToolResponse(id, makeContent(QString("Connection placement updated between %1 and %2 in model %3").arg(firstComponent).arg(secondComponent).arg(className)));
  }
  if (toolName == "setElementModifierValue") {
    QString className = arguments.value("className").toString(); // required
    QString component = arguments.value("component").toString(); // required
    QString modifier = arguments.value("modifier").toString(); // required
    QString value = arguments.value("value").toString(); // required
    MainWindow *mainWindow = MainWindow::instance();
    LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
    LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
    if (pLibraryTreeItem == nullptr) {
      return makeMCPError(id, QString("Class not found: %1").arg(className));
    }
    if (isClassReadOnly(className, pLibraryTreeModel)) {
      return makeMCPError(id, QString("Cannot modify class in a system library or read-only package: %1").arg(className));
    }
    pLibraryTreeModel->showModelWidget(pLibraryTreeItem, true);
    QCoreApplication::processEvents();
    ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
    ModelInfo oldModelInfo = pModelWidget->createModelInfo();
    // setElementModifierValue expects the component name and value as "(modifier = value)"
    QString modifierExpr = "(" + modifier + " = " + value + ")";
    bool ok = mainWindow->getOMCProxy()->setElementModifierValue(className, component, modifierExpr);
    if (!ok) {
      return makeMCPError(id, QString("Failed to set modifier %1 on %2 in model %3").arg(modifier).arg(component).arg(className));
    }
    ModelInfo newModelInfo = pModelWidget->createModelInfo();
    pModelWidget->getUndoStack()->push(new OMCUndoCommand(pLibraryTreeItem, oldModelInfo, newModelInfo,
      QString("Set %1.%2 = %3").arg(component).arg(modifier).arg(value)));
      pModelWidget->updateModelText();
      return makeMCPToolResponse(id, makeContent(QString("Set %1.%2 = %3 in model %4").arg(component).arg(modifier).arg(value).arg(className)));
    }
    if (toolName == "listComponents") {
      QString className = arguments.value("className").toString(); // required
      MainWindow *mainWindow = MainWindow::instance();
      LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
      LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
      if (pLibraryTreeItem == nullptr) {
        return makeMCPError(id, QString("Class not found: %1").arg(className));
      }
      if (!pLibraryTreeItem->getModelWidget()) {
        pLibraryTreeModel->showModelWidget(pLibraryTreeItem, false);
      }
      ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
      if (!pModelWidget->isDiagramViewLoaded()) {
        pModelWidget->loadDiagramViewNAPI();
      }
      QCoreApplication::processEvents();
      GraphicsView *pGraphicsView = pModelWidget->getDiagramGraphicsView();
      QJsonArray components;
      for (Element *pElement : pGraphicsView->getElementsList()) {
        components.append(QJsonObject{
          {"name", pElement->getName()},
          {"className", pElement->getClassName()}
        });
      }
      return makeMCPToolResponse(id, makeContent(components));
    }
    if (toolName == "getComponentPlacement") {
      QString className = arguments.value("className").toString(); // required
      QString componentName = arguments.value("component").toString(); // required
      MainWindow *mainWindow = MainWindow::instance();
      LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
      LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
      if (pLibraryTreeItem == nullptr) {
        return makeMCPError(id, QString("Class not found: %1").arg(className));
      }
      if (!pLibraryTreeItem->getModelWidget()) {
        pLibraryTreeModel->showModelWidget(pLibraryTreeItem, false);
      }
      ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
      if (!pModelWidget->isDiagramViewLoaded()) {
        pModelWidget->loadDiagramViewNAPI();
      }
      QCoreApplication::processEvents();
      auto elementPlacement = [](Element *pElement) -> QJsonObject {
        if (!pElement) return QJsonObject{};
        QPointF origin = pElement->mTransformation.getOrigin();
        ExtentAnnotation extent = pElement->mTransformation.getExtent();
        QPointF p1 = extent.size() > 0 ? extent.at(0) : QPointF(-10, -10);
        QPointF p2 = extent.size() > 1 ? extent.at(1) : QPointF(10, 10);
        return QJsonObject{
          {"x", origin.x()},
          {"y", origin.y()},
          {"width",  p2.x() - p1.x()},
          {"height", p2.y() - p1.y()},
          {"rotation", (double)pElement->mTransformation.getRotateAngle()}
        };
      };
      Element *pDiagramElement = pModelWidget->getDiagramGraphicsView()->getElementObject(componentName);
      if (!pDiagramElement) {
        return makeMCPError(id, QString("Component not found: %1 in model %2").arg(componentName).arg(className));
      }
      QJsonObject result = elementPlacement(pDiagramElement);
      result.insert("visible", (bool)pDiagramElement->mTransformation.getVisible());
      Element *pIconElement = pModelWidget->getIconGraphicsView()->getElementObject(componentName);
      if (pIconElement) {
        result.insert("icon", elementPlacement(pIconElement));
      }
      return makeMCPToolResponse(id, makeContent(result));
    }
    if (toolName == "deleteComponent") {
      QString className = arguments.value("className").toString(); // required
      QString componentName = arguments.value("component").toString(); // required
      MainWindow *mainWindow = MainWindow::instance();
      LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
      LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
      if (pLibraryTreeItem == nullptr) {
        return makeMCPError(id, QString("Class not found: %1").arg(className));
      }
      if (isClassReadOnly(className, pLibraryTreeModel)) {
        return makeMCPError(id, QString("Cannot modify class in a system library or read-only package: %1").arg(className));
      }
      pLibraryTreeModel->showModelWidget(pLibraryTreeItem, true);
      QCoreApplication::processEvents();
      ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
      GraphicsView *pGraphicsView = pModelWidget->getDiagramGraphicsView();
      Element *pElement = pGraphicsView->getElementObject(componentName);
      if (!pElement) {
        return makeMCPError(id, QString("Component not found: %1 in model %2").arg(componentName).arg(className));
      }
      ModelInfo oldModelInfo = pModelWidget->createModelInfo();
      pGraphicsView->deleteElement(pElement);
      pModelWidget->updateModelText();
      ModelInfo newModelInfo = pModelWidget->createModelInfo();
      pModelWidget->getUndoStack()->push(new OMCUndoCommand(pLibraryTreeItem, oldModelInfo, newModelInfo,
        QString("Delete Component %1").arg(componentName), true));
        QCoreApplication::processEvents();
        return makeMCPToolResponse(id, makeContent(QString("Component %1 deleted from model %2").arg(componentName).arg(className)));
      }
      if (toolName == "listComponentParameters") {
        QString className = arguments.value("className").toString(); // required
        QString component = arguments.value("component").toString(); // required
        MainWindow *mainWindow = MainWindow::instance();
        LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
        LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
        if (pLibraryTreeItem == nullptr) {
          return makeMCPError(id, QString("Class not found: %1").arg(className));
        }
        if (!pLibraryTreeItem->getModelWidget()) {
          pLibraryTreeModel->showModelWidget(pLibraryTreeItem, false);
        }
        ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
        if (!pModelWidget->isDiagramViewLoaded()) {
          pModelWidget->loadDiagramViewNAPI();
        }
        QCoreApplication::processEvents();
        GraphicsView *pGraphicsView = pModelWidget->getDiagramGraphicsView();
        Element *pElement = nullptr;
        for (Element *pEl : pGraphicsView->getElementsList() + pGraphicsView->getInheritedElementsList()) {
          if (pEl->getName() == component) {
            pElement = pEl;
            break;
          }
        }
        if (!pElement) {
          return makeMCPError(id, QString("Component %1 not found in model %2").arg(component).arg(className));
        }
        ModelInstance::Model *pComponentModel = pElement->getModel();
        // Recursively collect parameters
        QJsonArray parameters;
        QSet<QString> seen;
        std::function<void(ModelInstance::Model*)> collectParameters = [&](ModelInstance::Model *pModel) {
          for (auto pElem : pModel->getElements()) {
            if ((pElem->isComponent() || pElem->isShortClassDefinition()) && pElem->isPublic() && !pElem->isFinal()) {
              if (seen.contains(pElem->getName())) continue;
              seen.insert(pElem->getName());
              if (!pElem->isParameter() && !pElem->isInput()) continue;
              QJsonObject param;
              param["name"] = pElem->getName();
              param["type"] = pElem->getType();
              param["comment"] = pElem->getComment();
              const FlatModelica::Expression &binding = static_cast<const ModelInstance::Element*>(pElem)->getBinding();
              if (!binding.isNull()) {
                param["value"] = QString::fromStdString(binding.toString());
              } else if (pElem->getModifier()) {
                param["value"] = pElem->getModifier()->getValue();
              }
              parameters.append(param);
            } else if (pElem->isExtend() && pElem->getModel()) {
              collectParameters(pElem->getModel());
            }
          }
        };
        collectParameters(pComponentModel);
        return makeMCPToolResponse(id, makeContent(parameters));
      }
      if (toolName == "addRectangle") {
        QString className = arguments.value("className").toString();
        QString view = arguments.value("view").toString();
        double x1 = arguments.value("x1").toDouble();
        double y1 = arguments.value("y1").toDouble();
        double x2 = arguments.value("x2").toDouble();
        double y2 = arguments.value("y2").toDouble();
        QStringList args;
        args.append(extentToModelica(x1, y1, x2, y2));
        args.append(filledShapeArgs(arguments));
        if (arguments.contains("borderPattern"))
        args.append(QString("borderPattern=BorderPattern.%1").arg(arguments.value("borderPattern").toString()));
        if (arguments.contains("radius"))
        args.append(QString("radius=%1").arg(arguments.value("radius").toDouble()));
        return applyShapeAnnotation(id, className, view, QString("Rectangle(%1)").arg(args.join(",")));
      }
      if (toolName == "addEllipse") {
        QString className = arguments.value("className").toString();
        QString view = arguments.value("view").toString();
        double x1 = arguments.value("x1").toDouble();
        double y1 = arguments.value("y1").toDouble();
        double x2 = arguments.value("x2").toDouble();
        double y2 = arguments.value("y2").toDouble();
        QStringList args;
        args.append(extentToModelica(x1, y1, x2, y2));
        args.append(filledShapeArgs(arguments));
        if (arguments.contains("startAngle"))
        args.append(QString("startAngle=%1").arg(arguments.value("startAngle").toDouble()));
        if (arguments.contains("endAngle"))
        args.append(QString("endAngle=%1").arg(arguments.value("endAngle").toDouble()));
        if (arguments.contains("closure"))
        args.append(QString("closure=EllipseClosure.%1").arg(arguments.value("closure").toString()));
        return applyShapeAnnotation(id, className, view, QString("Ellipse(%1)").arg(args.join(",")));
      }
      if (toolName == "addLine") {
        QString className = arguments.value("className").toString();
        QString view = arguments.value("view").toString();
        QJsonArray points = arguments.value("points").toArray();
        QStringList args;
        args.append(QString("points=%1").arg(pointsToModelica(points)));
        if (arguments.contains("color"))
        args.append("color=" + colorToModelica(arguments.value("color").toObject()));
        if (arguments.contains("pattern"))
        args.append(QString("pattern=LinePattern.%1").arg(arguments.value("pattern").toString()));
        if (arguments.contains("thickness"))
        args.append(QString("thickness=%1").arg(arguments.value("thickness").toDouble()));
        if (arguments.contains("startArrow") || arguments.contains("endArrow")) {
          QString start = arguments.contains("startArrow") ? "Arrow." + arguments.value("startArrow").toString() : "Arrow.None";
          QString end   = arguments.contains("endArrow")   ? "Arrow." + arguments.value("endArrow").toString()   : "Arrow.None";
          args.append(QString("arrow={%1,%2}").arg(start, end));
        }
        if (arguments.contains("arrowSize"))
        args.append(QString("arrowSize=%1").arg(arguments.value("arrowSize").toDouble()));
        if (arguments.contains("smooth"))
        args.append(QString("smooth=Smooth.%1").arg(arguments.value("smooth").toString()));
        return applyShapeAnnotation(id, className, view, QString("Line(%1)").arg(args.join(",")));
      }
      if (toolName == "addPolygon") {
        QString className = arguments.value("className").toString();
        QString view = arguments.value("view").toString();
        QJsonArray points = arguments.value("points").toArray();
        QStringList args;
        args.append(QString("points=%1").arg(pointsToModelica(points)));
        args.append(filledShapeArgs(arguments));
        if (arguments.contains("smooth"))
        args.append(QString("smooth=Smooth.%1").arg(arguments.value("smooth").toString()));
        return applyShapeAnnotation(id, className, view, QString("Polygon(%1)").arg(args.join(",")));
      }
      if (toolName == "addText") {
        QString className = arguments.value("className").toString();
        QString view = arguments.value("view").toString();
        double x1 = arguments.value("x1").toDouble();
        double y1 = arguments.value("y1").toDouble();
        double x2 = arguments.value("x2").toDouble();
        double y2 = arguments.value("y2").toDouble();
        QString textString = arguments.value("textString").toString();
        // Escape backslashes and double quotes for Modelica string literal
        textString.replace("\\", "\\\\").replace("\"", "\\\"");
        QStringList args;
        args.append(extentToModelica(x1, y1, x2, y2));
        args.append(QString("textString=\"%1\"").arg(textString));
        if (arguments.contains("textColor"))
        args.append("textColor=" + colorToModelica(arguments.value("textColor").toObject()));
        if (arguments.contains("fontSize"))
        args.append(QString("fontSize=%1").arg(arguments.value("fontSize").toDouble()));
        if (arguments.contains("fontName"))
        args.append(QString("fontName=\"%1\"").arg(arguments.value("fontName").toString()));
        if (arguments.contains("textStyle")) {
          QStringList styles;
          for (const auto &s : arguments.value("textStyle").toArray())
          styles.append("TextStyle." + s.toString());
          args.append(QString("textStyle={%1}").arg(styles.join(",")));
        }
        if (arguments.contains("horizontalAlignment"))
        args.append(QString("horizontalAlignment=TextAlignment.%1").arg(arguments.value("horizontalAlignment").toString()));
        return applyShapeAnnotation(id, className, view, QString("Text(%1)").arg(args.join(",")));
      }
      if (toolName == "listShapes") {
        QString className = arguments.value("className").toString(); // required
        QString view = arguments.value("view").toString(); // required
        if (view != "icon" && view != "diagram")
        return makeMCPError(id, QString("Invalid view: %1. Must be \"icon\" or \"diagram\".").arg(view));
        MainWindow *mainWindow = MainWindow::instance();
        LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
        LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
        if (!pLibraryTreeItem)
        return makeMCPError(id, QString("Class not found: %1").arg(className));
        if (!pLibraryTreeItem->getModelWidget())
        pLibraryTreeModel->showModelWidget(pLibraryTreeItem, false);
        ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
        GraphicsView *pGraphicsView = (view == "icon") ? pModelWidget->getIconGraphicsView() : pModelWidget->getDiagramGraphicsView();
        if (view == "diagram" && !pModelWidget->isDiagramViewLoaded())
        pModelWidget->loadDiagramViewNAPI();
        QStringList coordinateSystemList, graphicsList;
        pGraphicsView->getCoordinateSystemAndGraphics(coordinateSystemList, graphicsList);
        return makeMCPToolResponse(id, makeContent(QJsonArray::fromStringList(graphicsList)));
      }
      if (toolName == "removeShape") {
        QString className = arguments.value("className").toString(); // required
        QString view = arguments.value("view").toString(); // required
        QString shapeStr = arguments.value("shape").toString(); // required
        if (view != "icon" && view != "diagram")
        return makeMCPError(id, QString("Invalid view: %1. Must be \"icon\" or \"diagram\".").arg(view));
        MainWindow *mainWindow = MainWindow::instance();
        LibraryTreeModel *pLibraryTreeModel = mainWindow->getLibraryWidget()->getLibraryTreeModel();
        LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
        if (!pLibraryTreeItem)
        return makeMCPError(id, QString("Class not found: %1").arg(className));
        if (isClassReadOnly(className, pLibraryTreeModel))
        return makeMCPError(id, QString("Cannot modify class in a system library or read-only package: %1").arg(className));
        if (!pLibraryTreeItem->getModelWidget())
        pLibraryTreeModel->showModelWidget(pLibraryTreeItem, false);
        ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
        GraphicsView *pGraphicsView = (view == "icon") ? pModelWidget->getIconGraphicsView() : pModelWidget->getDiagramGraphicsView();
        if (view == "diagram" && !pModelWidget->isDiagramViewLoaded())
        pModelWidget->loadDiagramViewNAPI();
        QStringList coordinateSystemList, graphicsList;
        pGraphicsView->getCoordinateSystemAndGraphics(coordinateSystemList, graphicsList);
        int idx = graphicsList.indexOf(shapeStr);
        if (idx < 0)
        return makeMCPError(id, QString("Shape not found in %1 view of class %2").arg(view, className));
        graphicsList.removeAt(idx);
        QString viewName = (view == "icon") ? "Icon" : "Diagram";
        QString annotationString;
        if (!coordinateSystemList.isEmpty())
        annotationString = QString("annotate=%1(coordinateSystem=CoordinateSystem(%2), graphics={%3})").arg(viewName, coordinateSystemList.join(","), graphicsList.join(","));
        else
        annotationString = QString("annotate=%1(graphics={%2})").arg(viewName, graphicsList.join(","));
        if (!m_proxy->addClassAnnotation(className, annotationString))
        return makeMCPError(id, QString("Failed to update shapes in %1 of class %2").arg(view, className));
        pModelWidget->reDrawModelWidget();
        if (view == "icon")
        pLibraryTreeItem->handleIconUpdated();
        pLibraryTreeModel->updateLibraryTreeItemClassText(pLibraryTreeItem);
        QCoreApplication::processEvents();
        return makeMCPToolResponse(id, makeContent(QString("Shape removed from %1 view of class %2").arg(view, className)));
      }
      return makeMCPError(id, QString("Tool not found: %1").arg(toolName));
    }

    #endif
