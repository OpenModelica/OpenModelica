/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "Modeling/ModelWidgetContainer.h"
#include "MainWindow.h"
#include "LibraryTreeWidget.h"
#include "ItemDelegate.h"
#include "Options/OptionsDialog.h"
#include "MessagesWidget.h"
#include "DocumentationWidget.h"
#include "Annotations/ShapePropertiesDialog.h"
#include "Component/ComponentProperties.h"
#include "Commands.h"
#include "TLM/FetchInterfaceDataDialog.h"
#include "Plotting/VariablesWidget.h"
#include "Options/NotificationsDialog.h"
#include "ModelicaClassDialog.h"
#include "TLM/TLMCoSimulationDialog.h"
#include "Git/GitCommands.h"
#if !defined(WITHOUT_OSG)
#include "Animation/ThreeDViewer.h"
#endif
#include "OMS/OMSProxy.h"
#include "OMS/ModelDialog.h"
#include "OMS/BusDialog.h"
#include "OMS/SystemSimulationInformationDialog.h"

#include <QNetworkReply>

/*!
 * \class GraphicsScene
 * \brief The GraphicsScene class is a container for graphicsl components in a simulationmodel.
 */
/*!
 * \brief GraphicsScene::GraphicsScene
 * \param viewType
 * \param pModelWidget
 */
GraphicsScene::GraphicsScene(StringHandler::ViewType viewType, ModelWidget *pModelWidget)
  : QGraphicsScene(pModelWidget), mViewType(viewType)
{
  mpModelWidget = pModelWidget;
}

/*!
 * \class GraphicsView
 * \brief The GraphicsView class is a class which display the content of a scene of components.
 */
/*!
 * \brief GraphicsView::GraphicsView
 * \param viewType
 * \param parent
 * \param animationView
 */
GraphicsView::GraphicsView(StringHandler::ViewType viewType, ModelWidget *parent, bool visualizationView)
  : QGraphicsView(parent), mViewType(viewType), mVisualizationView(visualizationView), mSkipBackground(false)
{
  /* Ticket #3275
   * Set the scroll bars policy to always on to avoid unnecessary resize events.
   */
  setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  setFrameShape(QFrame::StyledPanel);
  setDragMode(QGraphicsView::RubberBandDrag);
  setAcceptDrops(true);
  setViewportUpdateMode(QGraphicsView::FullViewportUpdate);
  setMouseTracking(true);
  mpModelWidget = parent;
  // set the coOrdinate System
  mCoOrdinateSystem = CoOrdinateSystem();
  GraphicalViewsPage *pGraphicalViewsPage;
  pGraphicalViewsPage = OptionsDialog::instance()->getGraphicalViewsPage();
  QList<QPointF> extent;
  qreal left = (mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewExtentLeft() : pGraphicalViewsPage->getDiagramViewExtentLeft();
  qreal bottom = (mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewExtentBottom() : pGraphicalViewsPage->getDiagramViewExtentBottom();
  qreal right = (mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewExtentRight() : pGraphicalViewsPage->getDiagramViewExtentRight();
  qreal top = (mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewExtentTop() : pGraphicalViewsPage->getDiagramViewExtentTop();
  extent << QPointF(left, bottom) << QPointF(right, top);
  mCoOrdinateSystem.setExtent(extent);
  mCoOrdinateSystem.setPreserveAspectRatio((mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewPreserveAspectRation() : pGraphicalViewsPage->getDiagramViewPreserveAspectRation());
  mCoOrdinateSystem.setInitialScale((mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewScaleFactor() : pGraphicalViewsPage->getDiagramViewScaleFactor());
  qreal horizontal = (mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewGridHorizontal() : pGraphicalViewsPage->getDiagramViewGridHorizontal();
  qreal vertical = (mViewType == StringHandler::Icon) ? pGraphicalViewsPage->getIconViewGridVertical() : pGraphicalViewsPage->getDiagramViewGridVertical();
  mCoOrdinateSystem.setGrid(QPointF(horizontal, vertical));
  setExtentRectangle(left, bottom, right, top);
  scale(1.0, -1.0);     // invert the drawing area.
  setIsCustomScale(false);
  setAddClassAnnotationNeeded(false);
  setIsCreatingConnection(false);
  setIsCreatingTransition(false);
  mIsCreatingLineShape = false;
  mIsCreatingPolygonShape = false;
  mIsCreatingRectangleShape = false;
  mIsCreatingEllipseShape = false;
  mIsCreatingTextShape = false;
  mIsCreatingBitmapShape = false;
  mIsPanning = false;
  mLastMouseEventPos = QPoint(0, 0);
  mpClickedComponent = 0;
  mpClickedState = 0;
  setIsMovingComponentsAndShapes(false);
  setRenderingLibraryPixmap(false);
  mpConnectionLineAnnotation = 0;
  mpTransitionLineAnnotation = 0;
  mpLineShapeAnnotation = 0;
  mpPolygonShapeAnnotation = 0;
  mpRectangleShapeAnnotation = 0;
  mpEllipseShapeAnnotation = 0;
  mpTextShapeAnnotation = 0;
  mpBitmapShapeAnnotation = 0;
  createActions();
}

void GraphicsView::setExtentRectangle(qreal left, qreal bottom, qreal right, qreal top)
{
  mExtentRectangle = QRectF(left, bottom, fabs(left - right), fabs(bottom - top));
  /* Ticket:4340 Extend vertical space
   * Make the drawing area 25% bigger than the actual size. So we can better use the panning feature.
   */
  QRectF sceneRectangle(left * 1.5, bottom * 1.5, fabs(left - right) * 1.5, fabs(bottom - top) * 1.5);
  setSceneRect(sceneRectangle);
  centerOn(sceneRectangle.center());
}

void GraphicsView::setIsCreatingConnection(bool enable)
{
  mIsCreatingConnection = enable;
  setDragModeInternal(enable);
  setItemsFlags(!enable);
}

void GraphicsView::setIsCreatingTransition(bool enable)
{
  mIsCreatingTransition = enable;
  if (enable) {
    setDragMode(QGraphicsView::NoDrag);
  } else {
    setDragMode(QGraphicsView::RubberBandDrag);
  }
  setItemsFlags(!enable);
}

void GraphicsView::setIsCreatingLineShape(bool enable)
{
  mIsCreatingLineShape = enable;
  setDragModeInternal(enable);
  setItemsFlags(!enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingPolygonShape(bool enable)
{
  mIsCreatingPolygonShape = enable;
  setDragModeInternal(enable);
  setItemsFlags(!enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingRectangleShape(bool enable)
{
  mIsCreatingRectangleShape = enable;
  setDragModeInternal(enable);
  setItemsFlags(!enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingEllipseShape(bool enable)
{
  mIsCreatingEllipseShape = enable;
  setDragModeInternal(enable);
  setItemsFlags(!enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingTextShape(bool enable)
{
  mIsCreatingTextShape = enable;
  setDragModeInternal(enable);
  setItemsFlags(!enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingBitmapShape(bool enable)
{
  mIsCreatingBitmapShape = enable;
  setDragModeInternal(enable);
  setItemsFlags(!enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsPanning(bool enable)
{
  mIsPanning = enable;
  setDragModeInternal(enable, true);
  setItemsFlags(!enable);
}

void GraphicsView::setDragModeInternal(bool enable, bool updateCursor)
{
  if (enable) {
    setDragMode(QGraphicsView::NoDrag);
    if (updateCursor) {
      viewport()->setCursor(Qt::ClosedHandCursor);
    }
  } else {
    setDragMode(QGraphicsView::RubberBandDrag);
    if (updateCursor) {
      viewport()->unsetCursor();
    }
  }
}

void GraphicsView::setItemsFlags(bool enable)
{
  // set components, shapes and connection flags accordingly
  foreach(Component *pComponent, mComponentsList) {
    pComponent->setComponentFlags(enable);
  }
  foreach(ShapeAnnotation *pShapeAnnotation, mShapesList){
    pShapeAnnotation->setShapeFlags(enable);
  }
  foreach(LineAnnotation *pLineAnnotation, mConnectionsList) {
    pLineAnnotation->setShapeFlags(enable);
  }
}

/*!
 * \brief GraphicsView::updateUndoRedoActions
 * Updates the Undo Redo actions depending shape(s) creation state.
 * \param enable
 */
void GraphicsView::updateUndoRedoActions(bool enable)
{
  if (enable) {
    MainWindow::instance()->getUndoAction()->setEnabled(!enable);
    MainWindow::instance()->getRedoAction()->setEnabled(!enable);
  } else {
    mpModelWidget->updateUndoRedoActions();
  }
}

bool GraphicsView::addComponent(QString className, QPointF position)
{
  MainWindow *pMainWindow = MainWindow::instance();
  LibraryTreeItem *pLibraryTreeItem = pMainWindow->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(className);
  if (!pLibraryTreeItem) {
    return false;
  }
  mpModelWidget->removeDynamicResults(); // show static values during editing
  // if we are dropping something on meta-model editor then we can skip Modelica stuff.
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    if (!pLibraryTreeItem->isSaved()) {
      QMessageBox::information(pMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::information),
                               tr("The class <b>%1</b> is not saved. You can only drag & drop saved classes.")
                               .arg(pLibraryTreeItem->getNameStructure()), Helper::ok);
      return false;
    } else {
      // item not to be dropped on itself; if dropping an item on itself
      if (isClassDroppedOnItself(pLibraryTreeItem)) {
        return false;
      }
      QString name = getUniqueComponentName(StringHandler::toCamelCase(pLibraryTreeItem->getName()));
      ComponentInfo *pComponentInfo = new ComponentInfo;
      QFileInfo fileInfo(pLibraryTreeItem->getFileName());
      // create StartCommand depending on the external model file extension.
      if (fileInfo.suffix().compare("mo") == 0) {
        pComponentInfo->setStartCommand("StartTLMOpenModelica");
      } else if (fileInfo.suffix().compare("in") == 0) {
        pComponentInfo->setStartCommand("StartTLMBeast");
      } else if (fileInfo.suffix().compare("hmf") == 0) {
        pComponentInfo->setStartCommand("StartTLMHopsan");
      } else if (fileInfo.suffix().compare("fmu") == 0) {
        pComponentInfo->setStartCommand("StartTLMFmiWrapper");
      } else if (fileInfo.suffix().compare("slx") == 0) {
        pComponentInfo->setStartCommand("StartTLMSimulink");
      } else {
        pComponentInfo->setStartCommand("");
      }
      pComponentInfo->setModelFile(fileInfo.fileName());
      addComponentToView(name, pLibraryTreeItem, "", position, pComponentInfo, true, false);
      return true;
    }
  } else {
    // Only allow drag & drop of Modelica LibraryTreeItem on a Modelica LibraryTreeItem
    if (mpModelWidget->getLibraryTreeItem()->getLibraryType() != pLibraryTreeItem->getLibraryType()) {
      QMessageBox::information(pMainWindow, QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                               tr("You can only drag & drop Modelica models."), Helper::ok);
      return false;
    }
    StringHandler::ModelicaClasses type = pLibraryTreeItem->getRestriction();
    OptionsDialog *pOptionsDialog = OptionsDialog::instance();
    // item not to be dropped on itself; if dropping an item on itself
    if (isClassDroppedOnItself(pLibraryTreeItem)) {
      return false;
    } else { // check if the model is partial
      QString name;
      if (pLibraryTreeItem->isPartial()) {
        if (pOptionsDialog->getNotificationsPage()->getReplaceableIfPartialCheckBox()->isChecked()) {
          NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::ReplaceableIfPartial,
                                                                              NotificationsDialog::InformationIcon,
                                                                              MainWindow::instance());
          pNotificationsDialog->setNotificationLabelString(GUIMessages::getMessage(GUIMessages::MAKE_REPLACEABLE_IF_PARTIAL)
                                                           .arg(StringHandler::getModelicaClassType(type).toLower()).arg(name));
          if (!pNotificationsDialog->exec()) {
            return false;
          }
        }
      }
      // get the model defaultComponentPrefixes
      QString defaultPrefix = pMainWindow->getOMCProxy()->getDefaultComponentPrefixes(pLibraryTreeItem->getNameStructure());
      // get the model defaultComponentName
      QString defaultName = pMainWindow->getOMCProxy()->getDefaultComponentName(pLibraryTreeItem->getNameStructure());
      if (defaultName.isEmpty()) {
        name = getUniqueComponentName(StringHandler::toCamelCase(pLibraryTreeItem->getName()));
      } else {
        if (checkComponentName(defaultName)) {
          name = defaultName;
        } else {
          name = getUniqueComponentName(defaultName);
        }
      }
      // Allow user to change the component name if always ask for component name settings is true.
      if (pOptionsDialog->getNotificationsPage()->getAlwaysAskForDraggedComponentName()->isChecked()) {
        ComponentNameDialog *pComponentNameDialog = new ComponentNameDialog(name, this, pMainWindow);
        if (pComponentNameDialog->exec()) {
          name = pComponentNameDialog->getComponentName();
          pComponentNameDialog->deleteLater();
        } else {
          pComponentNameDialog->deleteLater();
          return false;
        }
      }
      // if we or user has changed the default name
      if (!defaultName.isEmpty() && name.compare(defaultName) != 0) {
        // show the information to the user if we have changed the name of some inner component.
        if (defaultPrefix.contains("inner")) {
          if (pOptionsDialog->getNotificationsPage()->getInnerModelNameChangedCheckBox()->isChecked()) {
            NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::InnerModelNameChanged,
                                                                                NotificationsDialog::InformationIcon,
                                                                                MainWindow::instance());
            pNotificationsDialog->setNotificationLabelString(GUIMessages::getMessage(GUIMessages::INNER_MODEL_NAME_CHANGED)
                                                             .arg(defaultName).arg(name));
            if (!pNotificationsDialog->exec()) {
              return false;
            }
          }
        }
      }
      ComponentInfo *pComponentInfo = new ComponentInfo;
      pComponentInfo->applyDefaultPrefixes(defaultPrefix);
      // if dropping an item on the diagram layer
      if (mViewType == StringHandler::Diagram) {
        // if item is a class, model, block, connector or record. then we can drop it to the graphicsview
        if ((type == StringHandler::Class) || (type == StringHandler::Model) || (type == StringHandler::Block) ||
            (type == StringHandler::ExpandableConnector) || (type == StringHandler::Connector) || (type == StringHandler::Record)) {
          addComponentToView(name, pLibraryTreeItem, "", position, pComponentInfo);
          return true;
        } else {
          QMessageBox::information(pMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::information),
                                   GUIMessages::getMessage(GUIMessages::DIAGRAM_VIEW_DROP_MSG).arg(pLibraryTreeItem->getNameStructure())
                                   .arg(StringHandler::getModelicaClassType(type)), Helper::ok);
          return false;
        }
      } else if (mViewType == StringHandler::Icon) { // if dropping an item on the icon layer
        // if item is a connector. then we can drop it to the graphicsview
        if (type == StringHandler::Connector || type == StringHandler::ExpandableConnector) {
          addComponentToView(name, pLibraryTreeItem, "", position, pComponentInfo);
          return true;
        } else {
          QMessageBox::information(pMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::information),
                                   GUIMessages::getMessage(GUIMessages::ICON_VIEW_DROP_MSG).arg(pLibraryTreeItem->getNameStructure())
                                   .arg(StringHandler::getModelicaClassType(type)), Helper::ok);
          return false;
        }
      }
    }
  }
  return false;
}

/*!
 * \brief GraphicsView::addComponentToView
 * Adds the Component to the Graphical Views.
 * \param name
 * \param pLibraryTreeItem
 * \param annotation
 * \param position
 * \param pComponentInfo
 * \param addObject
 * \param openingClass
 */
void GraphicsView::addComponentToView(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, QPointF position,
                                      ComponentInfo *pComponentInfo, bool addObject, bool openingClass)
{
  AddComponentCommand *pAddComponentCommand;
  pAddComponentCommand = new AddComponentCommand(name, pLibraryTreeItem, annotation, position, pComponentInfo, addObject, openingClass, this);
  mpModelWidget->getUndoStack()->push(pAddComponentCommand);
  if (!openingClass) {
    mpModelWidget->getLibraryTreeItem()->emitComponentAdded(pAddComponentCommand->getComponent());
    mpModelWidget->updateModelText();
  }
}

void GraphicsView::addComponentToClass(Component *pComponent)
{
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::Modelica) {
    MainWindow *pMainWindow = MainWindow::instance();
    // Add the component to model in OMC.
    /* Ticket:4132
     * Always send the full path so that addComponent API doesn't fail when it makes a call to getDefaultPrefixes.
     * I updated the addComponent API to make path relative.
     */
    pMainWindow->getOMCProxy()->addComponent(pComponent->getName(), pComponent->getComponentInfo()->getClassName(),
                                             mpModelWidget->getLibraryTreeItem()->getNameStructure(), pComponent->getPlacementAnnotation());
    LibraryTreeModel *pLibraryTreeModel = pMainWindow->getLibraryWidget()->getLibraryTreeModel();
    // get the toplevel class of dragged component
    QString packageName = StringHandler::getFirstWordBeforeDot(pComponent->getLibraryTreeItem()->getNameStructure());
    LibraryTreeItem *pPackageLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(packageName);
    // get the top level class of current class
    QString topLevelClassName = StringHandler::getFirstWordBeforeDot(mpModelWidget->getLibraryTreeItem()->getNameStructure());
    LibraryTreeItem *pTopLevelLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(topLevelClassName);
    if (pPackageLibraryTreeItem && pTopLevelLibraryTreeItem) {
      // get uses annotation of the toplevel class
      QList<QList<QString > > usesAnnotation = pMainWindow->getOMCProxy()->getUses(pTopLevelLibraryTreeItem->getNameStructure());
      QStringList newUsesAnnotation;
      for (int i = 0 ; i < usesAnnotation.size() ; i++) {
        if (usesAnnotation.at(i).at(0).compare(packageName) == 0) {
          return; // if the package is already in uses annotation of class then simply return without doing anything.
        } else {
          newUsesAnnotation.append(QString("%1(version=\"%2\")").arg(usesAnnotation.at(i).at(0)).arg(usesAnnotation.at(i).at(1)));
        }
      }
      // if the package has version only then add the uses annotation
      if (!pPackageLibraryTreeItem->mClassInformation.version.isEmpty() &&
          // Do not add a uses-annotation to itself
          pTopLevelLibraryTreeItem->getNameStructure() != packageName) {
        newUsesAnnotation.append(QString("%1(version=\"%2\")").arg(packageName).arg(pPackageLibraryTreeItem->mClassInformation.version));
        QString usesAnnotationString = QString("annotate=$annotation(uses(%1))").arg(newUsesAnnotation.join(","));
        pMainWindow->getOMCProxy()->addClassAnnotation(pTopLevelLibraryTreeItem->getNameStructure(), usesAnnotationString);
        pLibraryTreeModel->updateLibraryTreeItemClassText(pTopLevelLibraryTreeItem);
      }
    }
  } else if (mpModelWidget->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::CompositeModel) {
    // add SubModel Element
    CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpModelWidget->getEditor());
    pCompositeModelEditor->addSubModel(pComponent);
    /* We need to iterate over Component childrens
     * because if user deletes a submodel for which interfaces are already fetched
     * then undoing the delete operation reaches here and we should add the interfaces back.
     */
    foreach (Component *pInterfaceComponent, pComponent->getComponentsList()) {
      pCompositeModelEditor->addInterface(pInterfaceComponent, pComponent->getName());
    }
  }
}

/*!
 * \brief GraphicsView::deleteComponent
 * Delete the component and its corresponding connectors from the components list and OMC.
 * \param component is the object to be deleted.
 */
void GraphicsView::deleteComponent(Component *pComponent)
{
  // First Remove the Connector associated to this component
  int i = 0;
  while(i != mConnectionsList.size()) {
    QString startComponentName, endComponentName = "";
    if (mConnectionsList[i]->getStartComponent()) {
      startComponentName = mConnectionsList[i]->getStartComponent()->getRootParentComponent()->getName();
    }
    if (mConnectionsList[i]->getEndComponent()) {
      endComponentName = mConnectionsList[i]->getEndComponent()->getRootParentComponent()->getName();
    }
    if (startComponentName == pComponent->getName() || endComponentName == pComponent->getName()) {
      deleteConnection(mConnectionsList[i]);
      i = 0;   //Restart iteration if map has changed
    } else {
      ++i;
    }
  }
  pComponent->setSelected(false);
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    mpModelWidget->getUndoStack()->push(new DeleteSubModelCommand(pComponent, this));
  } else {
    mpModelWidget->getUndoStack()->push(new DeleteComponentCommand(pComponent, this));
  }

}

/*!
 * \brief GraphicsView::deleteComponentObject
 * Deletes the Component.
 * \param pComponent
 */
void GraphicsView::deleteComponentFromClass(Component *pComponent)
{
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    // delete the component from OMC
    pOMCProxy->deleteComponent(pComponent->getName(), mpModelWidget->getLibraryTreeItem()->getNameStructure());
  } else if (mpModelWidget->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::CompositeModel) {
    CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpModelWidget->getEditor());
    pCompositeModelEditor->deleteSubModel(pComponent->getName());
  }
}

/*!
 * \brief GraphicsView::getComponentObject
 * Finds the Component
 * \param componentName
 * \return
 */
Component* GraphicsView::getComponentObject(QString componentName)
{
  // look in inherited components
  foreach (Component *pInheritedComponent, mInheritedComponentsList) {
    if (pInheritedComponent->getName().compare(componentName) == 0) {
      return pInheritedComponent;
    }
  }
  // look in components
  foreach (Component *pComponent, mComponentsList) {
    if (pComponent->getName().compare(componentName) == 0) {
      return pComponent;
    }
  }
  return 0;
}

/*!
 * \brief GraphicsView::getUniqueComponentName
 * Creates a unique component name.
 * \param componentName
 * \param number
 * \return
 */
QString GraphicsView::getUniqueComponentName(QString componentName, int number)
{
  QString name;
  name = QString(componentName).append(QString::number(number));
  foreach (Component *pComponent, mComponentsList) {
    if (pComponent->getName().compare(name, Qt::CaseSensitive) == 0) {
      name = getUniqueComponentName(componentName, ++number);
      break;
    }
  }
  return name;
}

/*!
 * \brief GraphicsView::checkComponentName
 * Checks if the component with the same name already exists or not.
 * \param componentName
 * \return
 */
bool GraphicsView::checkComponentName(QString componentName)
{
  foreach (Component *pComponent, mComponentsList) {
    if (pComponent->getName().compare(componentName, Qt::CaseSensitive) == 0) {
      return false;
    }
  }
  return true;
}

/*!
 * \brief GraphicsView::addConnectionToClass
 * Adds the connection to class.
 * \param pConnectionLineAnnotation - the connection to add.
 * \return
 */
bool GraphicsView::addConnectionToClass(LineAnnotation *pConnectionLineAnnotation)
{
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::CompositeModel) {
    CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpModelWidget->getEditor());
    if (pCompositeModelEditor) {
      pCompositeModelEditor->createConnection(pConnectionLineAnnotation);
    }
  } else if (mpModelWidget->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::OMS) {
    // if TLM connection
    bool connectionSuccessful = false;
    if (pConnectionLineAnnotation->getOMSConnectionType() == oms_connection_tlm) {
      connectionSuccessful = OMSProxy::instance()->addTLMConnection(pConnectionLineAnnotation->getStartComponentName(),
                                                                    pConnectionLineAnnotation->getEndComponentName(),
                                                                    pConnectionLineAnnotation->getDelay().toDouble(),
                                                                    pConnectionLineAnnotation->getAlpha().toDouble(),
                                                                    pConnectionLineAnnotation->getZf().toDouble(),
                                                                    pConnectionLineAnnotation->getZfr().toDouble());
    } else {
      connectionSuccessful = OMSProxy::instance()->addConnection(pConnectionLineAnnotation->getStartComponentName(),
                                                                 pConnectionLineAnnotation->getEndComponentName());
    }
    if (connectionSuccessful) {
      pConnectionLineAnnotation->updateOMSConnection();
      return true;
    } else {
      removeCurrentConnection();
      return false;
    }
  } else {
    MainWindow *pMainWindow = MainWindow::instance();
    if (pMainWindow->getOMCProxy()->addConnection(pConnectionLineAnnotation->getStartComponentName(),
                                                  pConnectionLineAnnotation->getEndComponentName(),
                                                  mpModelWidget->getLibraryTreeItem()->getNameStructure(),
                                                  QString("annotate=").append(pConnectionLineAnnotation->getShapeAnnotation()))) {
      /* Ticket #2450
       * Do not check for the ports compatibility via instantiatemodel. Just let the user create the connection.
       */
      //pMainWindow->getOMCProxy()->instantiateModelSucceeds(mpModelWidget->getNameStructure());
    }
  }
  return true;
}

/*!
 * \brief GraphicsView::deleteConnectionFromClass
 * Deletes the connection from class.
 * \param pConnectionLineAnnotation - the connection to delete.
 */
void GraphicsView::deleteConnectionFromClass(LineAnnotation *pConnectionLineAnnotation)
{
  MainWindow *pMainWindow = MainWindow::instance();
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::CompositeModel) {
    CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpModelWidget->getEditor());
    pCompositeModelEditor->deleteConnection(pConnectionLineAnnotation->getStartComponentName(), pConnectionLineAnnotation->getEndComponentName());
  } else if (mpModelWidget->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::OMS) {
    OMSProxy::instance()->deleteConnection(pConnectionLineAnnotation->getStartComponentName(),
                                           pConnectionLineAnnotation->getEndComponentName());
  } else {
    pMainWindow->getOMCProxy()->deleteConnection(pConnectionLineAnnotation->getStartComponentName(),
                                                 pConnectionLineAnnotation->getEndComponentName(),
                                                 mpModelWidget->getLibraryTreeItem()->getNameStructure());
  }
}

/*!
 * \brief GraphicsView::updateConnectionInClass
 * Updates a connection in a class.
 * \param pConnectonLineAnnotation
 */
void GraphicsView::updateConnectionInClass(LineAnnotation *pConnectionLineAnnotation)
{
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::CompositeModel) {
    CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpModelWidget->getEditor());
    if (pCompositeModelEditor) {
      pCompositeModelEditor->updateConnection(pConnectionLineAnnotation);
    }
  }
}

/*!
 * \brief GraphicsView::removeConnectionsFromView
 * Removes the connections from the view.
 */
void GraphicsView::removeConnectionsFromView()
{
  foreach (LineAnnotation *pConnectionLineAnnotation, mConnectionsList) {
    deleteConnectionFromList(pConnectionLineAnnotation);
    removeItem(pConnectionLineAnnotation);
  }
}

/*!
 * \brief GraphicsView::addTransitionToClass
 * Adds the transition to class.
 * \param pTransitionLineAnnotation - the transition to add.
 */
void GraphicsView::addTransitionToClass(LineAnnotation *pTransitionLineAnnotation)
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  if (pOMCProxy->addTransition(mpModelWidget->getLibraryTreeItem()->getNameStructure(), pTransitionLineAnnotation->getStartComponentName(),
                               pTransitionLineAnnotation->getEndComponentName(), pTransitionLineAnnotation->getCondition(),
                               pTransitionLineAnnotation->getImmediate(), pTransitionLineAnnotation->getReset(),
                               pTransitionLineAnnotation->getSynchronize(), pTransitionLineAnnotation->getPriority(),
                               QString("annotate=$annotation(%1,%2)").arg(pTransitionLineAnnotation->getShapeAnnotation())
                               .arg(pTransitionLineAnnotation->getTextAnnotation()->getShapeAnnotation()))) {
  }
}

/*!
 * \brief GraphicsView::deleteTransitionFromClass
 * Deletes the transition from class.
 * \param pTransitionLineAnnotation - the transition to delete.
 */
void GraphicsView::deleteTransitionFromClass(LineAnnotation *pTransitionLineAnnotation)
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  pOMCProxy->deleteTransition(mpModelWidget->getLibraryTreeItem()->getNameStructure(), pTransitionLineAnnotation->getStartComponentName(),
                              pTransitionLineAnnotation->getEndComponentName(), pTransitionLineAnnotation->getCondition(),
                              pTransitionLineAnnotation->getImmediate(), pTransitionLineAnnotation->getReset(),
                              pTransitionLineAnnotation->getSynchronize(), pTransitionLineAnnotation->getPriority());
}

/*!
 * \brief GraphicsView::removeTransitionsFromView
 * Removes the transitions from the view.
 */
void GraphicsView::removeTransitionsFromView()
{
  foreach (LineAnnotation *pTransitionLineAnnotation, mTransitionsList) {
    deleteTransitionFromList(pTransitionLineAnnotation);
    removeItem(pTransitionLineAnnotation);
  }
}

/*!
 * \brief GraphicsView::addInitialStateToClass
 * Adds the initial state to class.
 * \param pInitialStateLineAnnotation - the initial state to add.
 */
void GraphicsView::addInitialStateToClass(LineAnnotation *pInitialStateLineAnnotation)
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  if (pOMCProxy->addInitialState(mpModelWidget->getLibraryTreeItem()->getNameStructure(),
                                 pInitialStateLineAnnotation->getStartComponentName(),
                                 QString("annotate=").append(pInitialStateLineAnnotation->getShapeAnnotation()))) {
  }
}

/*!
 * \brief GraphicsView::deleteInitialStateFromClass
 * Deletes the initial state from class.
 * \param pInitialStateLineAnnotation - the initial state to delete.
 */
void GraphicsView::deleteInitialStateFromClass(LineAnnotation *pInitialStateLineAnnotation)
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  pOMCProxy->deleteInitialState(mpModelWidget->getLibraryTreeItem()->getNameStructure(), pInitialStateLineAnnotation->getStartComponentName());
}

/*!
 * \brief GraphicsView::removeInitialStatesFromView
 * Removes the initial states from the view.
 */
void GraphicsView::removeInitialStatesFromView()
{
  foreach (LineAnnotation *pInitialStateLineAnnotation, mInitialStatesList) {
    deleteInitialStateFromList(pInitialStateLineAnnotation);
    removeItem(pInitialStateLineAnnotation);
  }
}

/*!
 * \brief GraphicsView::addShapeToList
 * \param pShape
 * \param index
 */
void GraphicsView::addShapeToList(ShapeAnnotation *pShape, int index)
{
  if (index <= -1) {
    mShapesList.append(pShape);
  } else {
    mShapesList.insert(index, pShape);
  }
}

/*!
 * \brief GraphicsView::deleteShape
 * Deletes the shape from the icon/diagram layer.
 * \param pShapeAnnotation
 */
void GraphicsView::deleteShape(ShapeAnnotation *pShapeAnnotation)
{
  pShapeAnnotation->setSelected(false);
  mpModelWidget->getUndoStack()->push(new DeleteShapeCommand(pShapeAnnotation));
}

/*!
 * \brief GraphicsView::deleteShapeFromList
 * \param pShape
 * \return
 */
int GraphicsView::deleteShapeFromList(ShapeAnnotation *pShape)
{
  int index = mShapesList.indexOf(pShape);
  mShapesList.removeOne(pShape);
  return index;
}

/*!
 * \brief GraphicsView::reOrderShapes
 * Reorders the shapes.
 */
void GraphicsView::reOrderShapes()
{
  int zValue = 0;
  // set stacking order for inherited shapes
  foreach (ShapeAnnotation *pShapeAnnotation, mInheritedShapesList) {
    zValue++;
    pShapeAnnotation->setZValue(zValue);
  }
  // set stacking order for shapes.
  foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
    zValue++;
    pShapeAnnotation->setZValue(zValue);
  }
}

/*!
 * \brief GraphicsView::bringToFront
 * \param pShape
 * Brings the shape to front of all other shapes.
 */
void GraphicsView::bringToFront(ShapeAnnotation *pShape)
{
  deleteShapeFromList(pShape);
  int i = 0;
  // update the shapes z index
  for (; i < mShapesList.size() ; i++) {
    mShapesList.at(i)->setZValue(i + 1);
  }
  pShape->setZValue(i + 1);
  mShapesList.append(pShape);
  // update class annotation.
  addClassAnnotation();
}

/*!
 * \brief GraphicsView::bringForward
 * \param pShape
 * Brings the shape one level forward.
 */
void GraphicsView::bringForward(ShapeAnnotation *pShape)
{
  int shapeIndex = mShapesList.indexOf(pShape);
  if (shapeIndex == -1 || shapeIndex == mShapesList.size() - 1) { // if the shape is already at top.
    return;
  }
  // swap the shapes in the list
  mShapesList.swap(shapeIndex, shapeIndex + 1);
  // update the shapes z index
  for (int i = 0 ; i < mShapesList.size() ; i++) {
    mShapesList.at(i)->setZValue(i + 1);
  }
  // update class annotation.
  addClassAnnotation();
}

/*!
 * \brief GraphicsView::sendToBack
 * \param pShape
 * Sends the shape to back of all other shapes.
 */
void GraphicsView::sendToBack(ShapeAnnotation *pShape)
{
  deleteShapeFromList(pShape);
  int i = 0;
  pShape->setZValue(i + 1);
  mShapesList.prepend(pShape);
  // update the shapes z index
  for (i = 1 ; i < mShapesList.size() ; i++) {
    mShapesList.at(i)->setZValue(i + 1);
  }
  // update class annotation.
  addClassAnnotation();
}

/*!
 * \brief GraphicsView::sendBackward
 * \param pShape
 * Sends the shape one level backward.
 */
void GraphicsView::sendBackward(ShapeAnnotation *pShape)
{
  int shapeIndex = mShapesList.indexOf(pShape);
  if (shapeIndex <= 0) { // if the shape is already at bottom.
    return;
  }
  // swap the shapes in the list
  mShapesList.swap(shapeIndex - 1, shapeIndex);
  // update the shapes z index
  for (int i = 0 ; i < mShapesList.size() ; i++) {
    mShapesList.at(i)->setZValue(i + 1);
  }
  // update class annotation.
  addClassAnnotation();
}

void GraphicsView::createLineShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || isVisualizationView()) {
    return;
  }

  if (!isCreatingLineShape()) {
    mpLineShapeAnnotation = new LineAnnotation("", this);
    mpModelWidget->getUndoStack()->push(new AddShapeCommand(mpLineShapeAnnotation));
    setIsCreatingLineShape(true);
    mpLineShapeAnnotation->addPoint(point);
    mpLineShapeAnnotation->addPoint(point);
  } else {  // if we are already creating a line then only add one point.
    mpLineShapeAnnotation->addPoint(point);
  }
}

void GraphicsView::createPolygonShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || isVisualizationView()) {
    return;
  }

  if (!isCreatingPolygonShape()) {
    mpPolygonShapeAnnotation = new PolygonAnnotation("", this);
    mpModelWidget->getUndoStack()->push(new AddShapeCommand(mpPolygonShapeAnnotation));
    setIsCreatingPolygonShape(true);
    mpPolygonShapeAnnotation->addPoint(point);
    mpPolygonShapeAnnotation->addPoint(point);
    mpPolygonShapeAnnotation->addPoint(point);
  } else { // if we are already creating a polygon then only add one point.
    mpPolygonShapeAnnotation->addPoint(point);
  }
}

void GraphicsView::createRectangleShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || isVisualizationView()) {
    return;
  }

  if (!isCreatingRectangleShape()) {
    mpRectangleShapeAnnotation = new RectangleAnnotation("", this);
    mpModelWidget->getUndoStack()->push(new AddShapeCommand(mpRectangleShapeAnnotation));
    setIsCreatingRectangleShape(true);
    mpRectangleShapeAnnotation->replaceExtent(0, point);
    mpRectangleShapeAnnotation->replaceExtent(1, point);
  } else { // if we are already creating a rectangle then finish creating it.
    // finish creating the rectangle
    setIsCreatingRectangleShape(false);
    MainWindow *pMainWindow = MainWindow::instance();
    // set the transformation matrix
    mpRectangleShapeAnnotation->setOrigin(mpRectangleShapeAnnotation->sceneBoundingRect().center());
    mpRectangleShapeAnnotation->adjustExtentsWithOrigin();
    mpRectangleShapeAnnotation->initializeTransformation();
    // draw corner items for the rectangle shape
    mpRectangleShapeAnnotation->drawCornerItems();
    mpRectangleShapeAnnotation->setSelected(true);
    // make the toolbar button of rectangle unchecked
    pMainWindow->getRectangleShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    mpModelWidget->getLibraryTreeItem()->emitShapeAdded(mpRectangleShapeAnnotation, this);
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  }
}

void GraphicsView::createEllipseShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || isVisualizationView()) {
    return;
  }

  if (!isCreatingEllipseShape()) {
    mpEllipseShapeAnnotation = new EllipseAnnotation("", this);
    mpModelWidget->getUndoStack()->push(new AddShapeCommand(mpEllipseShapeAnnotation));
    setIsCreatingEllipseShape(true);
    mpEllipseShapeAnnotation->replaceExtent(0, point);
    mpEllipseShapeAnnotation->replaceExtent(1, point);
  } else { // if we are already creating an ellipse then finish creating it.
    // finish creating the ellipse
    setIsCreatingEllipseShape(false);
    MainWindow *pMainWindow = MainWindow::instance();
    // set the transformation matrix
    mpEllipseShapeAnnotation->setOrigin(mpEllipseShapeAnnotation->sceneBoundingRect().center());
    mpEllipseShapeAnnotation->adjustExtentsWithOrigin();
    mpEllipseShapeAnnotation->initializeTransformation();
    // draw corner items for the ellipse shape
    mpEllipseShapeAnnotation->drawCornerItems();
    mpEllipseShapeAnnotation->setSelected(true);
    // make the toolbar button of ellipse unchecked
    pMainWindow->getEllipseShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    mpModelWidget->getLibraryTreeItem()->emitShapeAdded(mpEllipseShapeAnnotation, this);
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  }
}

void GraphicsView::createTextShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || isVisualizationView()) {
    return;
  }

  if (!isCreatingTextShape()) {
    mpTextShapeAnnotation = new TextAnnotation("", this);
    mpModelWidget->getUndoStack()->push(new AddShapeCommand(mpTextShapeAnnotation));
    setIsCreatingTextShape(true);
    mpTextShapeAnnotation->setTextString("text");
    mpTextShapeAnnotation->replaceExtent(0, point);
    mpTextShapeAnnotation->replaceExtent(1, point);
  } else { // if we are already creating a text then finish creating it.
    // finish creating the text
    setIsCreatingTextShape(false);
    MainWindow *pMainWindow = MainWindow::instance();
    // set the transformation matrix
    mpTextShapeAnnotation->setOrigin(mpTextShapeAnnotation->sceneBoundingRect().center());
    mpTextShapeAnnotation->adjustExtentsWithOrigin();
    mpTextShapeAnnotation->initializeTransformation();
    // draw corner items for the text shape
    mpTextShapeAnnotation->drawCornerItems();
    // make the toolbar button of text unchecked
    pMainWindow->getTextShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    mpModelWidget->getLibraryTreeItem()->emitShapeAdded(mpTextShapeAnnotation, this);
    mpTextShapeAnnotation->showShapeProperties();
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
    mpTextShapeAnnotation->setSelected(true);
  }
}

void GraphicsView::createBitmapShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || isVisualizationView()) {
    return;
  }

  if (!isCreatingBitmapShape()) {
    mpBitmapShapeAnnotation = new BitmapAnnotation(mpModelWidget->getLibraryTreeItem()->getFileName(), "", this);
    mpModelWidget->getUndoStack()->push(new AddShapeCommand(mpBitmapShapeAnnotation));
    setIsCreatingBitmapShape(true);
    mpBitmapShapeAnnotation->replaceExtent(0, point);
    mpBitmapShapeAnnotation->replaceExtent(1, point);
  } else { // if we are already creating a bitmap then finish creating it.
    // finish creating the bitmap
    setIsCreatingBitmapShape(false);
    MainWindow *pMainWindow = MainWindow::instance();
    // set the transformation matrix
    mpBitmapShapeAnnotation->setOrigin(mpBitmapShapeAnnotation->sceneBoundingRect().center());
    mpBitmapShapeAnnotation->adjustExtentsWithOrigin();
    mpBitmapShapeAnnotation->initializeTransformation();
    // draw corner items for the bitmap shape
    mpBitmapShapeAnnotation->drawCornerItems();
    // make the toolbar button of text unchecked
    pMainWindow->getBitmapShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    mpModelWidget->getLibraryTreeItem()->emitShapeAdded(mpBitmapShapeAnnotation, this);
    mpBitmapShapeAnnotation->showShapeProperties();
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
    mpBitmapShapeAnnotation->setSelected(true);
  }
}

/*!
 * \brief GraphicsView::itemsBoundingRect
 * Gets the bounding rectangle of all the items added to the view, excluding background and so on
 * \return
 */
QRectF GraphicsView::itemsBoundingRect()
{
  QRectF rect;
  foreach (Component *pComponent, mComponentsList) {
    rect |= pComponent->itemsBoundingRect();
  }
  foreach (QGraphicsItem *item, mShapesList) {
    if (TextAnnotation *pTextAnnotation = dynamic_cast<TextAnnotation*>(item)) {
      rect |= pTextAnnotation->mExportBoundingRect;
    } else {
      rect |= item->sceneBoundingRect();
    }
  }
  foreach (QGraphicsItem *item, mConnectionsList) {
    rect |= item->sceneBoundingRect();
  }
  foreach (Component *pComponent, mInheritedComponentsList) {
    rect |= pComponent->itemsBoundingRect();
  }
  foreach (QGraphicsItem *item, mInheritedShapesList) {
    rect |= item->sceneBoundingRect();
  }
  foreach (QGraphicsItem *item, mInheritedConnectionsList) {
    rect |= item->sceneBoundingRect();
  }
  qreal x1, y1, x2, y2;
  rect.getCoords(&x1, &y1, &x2, &y2);
  rect.setCoords(x1 -5, y1 -5, x2 + 5, y2 + 5);
  return mapFromScene(rect).boundingRect();
}

QPointF GraphicsView::snapPointToGrid(QPointF point)
{
  qreal stepX = mCoOrdinateSystem.getHorizontalGridStep();
  qreal stepY = mCoOrdinateSystem.getVerticalGridStep();
  point.setX(stepX * qFloor((point.x() / stepX) + 0.5));
  point.setY(stepY * qFloor((point.y() / stepY) + 0.5));
  return point;
}

QPointF GraphicsView::movePointByGrid(QPointF point, QPointF origin, bool useShiftModifier)
{
  qreal stepX = mCoOrdinateSystem.getHorizontalGridStep() * ((useShiftModifier && QApplication::keyboardModifiers().testFlag(Qt::ShiftModifier)) ? 5 : 1);
  qreal stepY = mCoOrdinateSystem.getVerticalGridStep() * ((useShiftModifier && QApplication::keyboardModifiers().testFlag(Qt::ShiftModifier)) ? 5 : 1);
  if (useShiftModifier && QApplication::keyboardModifiers().testFlag(Qt::ShiftModifier)) {
    int modX = (int)fabs(origin.x()) % (int)stepX;
    int modY = (int)fabs(origin.y()) % (int)stepY;
    if (modX != 0) {
      if ((point.x() < 0 && origin.x() > 0) || (point.x() > 0 && origin.x() < 0)) {
        stepX = modX;
      } else if ((point.x() > 0 && origin.x() > 0) || (point.x() < 0 && origin.x() < 0)) {
        stepX = stepX - modX;
      }
    }
    if (modY != 0) {
      if ((point.y() < 0 && origin.y() > 0) || (point.y() > 0 && origin.y() < 0)) {
        stepY = modY;
      } else if ((point.y() > 0 && origin.y() > 0) || (point.y() < 0 && origin.y() < 0)) {
        stepY = stepY - modY;
      }
    }
  }
  point.setX(qRound(point.x() / stepX) * stepX);
  point.setY(qRound(point.y() / stepY) * stepY);
  return point;
}

QPointF GraphicsView::roundPoint(QPointF point)
{
  qreal divisor = 0.5;
  qreal x = (fmod(point.x(), divisor) == 0) ? point.x() : qRound(point.x());
  qreal y = (fmod(point.y(), divisor) == 0) ? point.y() : qRound(point.y());
  return QPointF(x, y);
}

/*!
 * \brief GraphicsView::hasIconAnnotation
 * Checks if class has annotation.
 * \return
 */
bool GraphicsView::hasAnnotation()
{
  // check inherited shapes and components
  if (!mInheritedShapesList.isEmpty()) {
    return true;
  }
  foreach (Component *pInheritedComponent, mInheritedComponentsList) {
    if (pInheritedComponent->hasShapeAnnotation(pInheritedComponent) && pInheritedComponent->isVisible()) {
      return true;
    }
  }
  // check shapes and components
  if (!mShapesList.isEmpty()) {
    return true;
  }
  foreach (Component *pComponent, mComponentsList) {
    if (pComponent->hasShapeAnnotation(pComponent) && pComponent->isVisible()) {
      return true;
    }
  }
  return false;
}

/*!
 * \brief GraphicsView::addItem
 * Adds the QGraphicsItem from GraphicsView
 * \param pGraphicsItem
 */
void GraphicsView::addItem(QGraphicsItem *pGraphicsItem)
{
  if (!scene()->items().contains(pGraphicsItem)) {
    scene()->addItem(pGraphicsItem);
  }
}

/*!
 * \brief GraphicsView::removeItem
 * Removes the QGraphicsItem from GraphicsView
 * \param pGraphicsItem
 */
void GraphicsView::removeItem(QGraphicsItem *pGraphicsItem)
{
  if (scene()->items().contains(pGraphicsItem)) {
    scene()->removeItem(pGraphicsItem);
  }
}

/*!
 * \brief GraphicsView::fitInView
 * Fits the view.
 */
void GraphicsView::fitInViewInternal()
{
  // only resize the view if user has not set any custom scaling like zoom in and zoom out.
  if (!isCustomScale()) {
    // make the fitInView rectangle bigger so that the scene rectangle will show up properly on the screen.
    QRectF extentRectangle = getExtentRectangle();
    qreal x1, y1, x2, y2;
    extentRectangle.getCoords(&x1, &y1, &x2, &y2);
    extentRectangle.setCoords(x1 -5, y1 -5, x2 + 5, y2 + 5);
    fitInView(extentRectangle, Qt::KeepAspectRatio);
  }
}

/*!
 * \brief GraphicsView::createActions
 * Creates the actions for the GraphicsView.
 */
void GraphicsView::createActions()
{
  bool isSystemLibrary = mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || isVisualizationView();
  // Graphics View Properties Action
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    mpPropertiesAction = new QAction(Helper::systemSimulationInformation, this);
  } else {
    mpPropertiesAction = new QAction(Helper::properties, this);
  }
  connect(mpPropertiesAction, SIGNAL(triggered()), SLOT(showGraphicsViewProperties()));
  // rename Action
  mpRenameAction = new QAction(Helper::rename, this);
  mpRenameAction->setStatusTip(Helper::renameTip);
  connect(mpRenameAction, SIGNAL(triggered()), SLOT(showRenameDialog()));
  // Simulation Params Action
  mpSimulationParamsAction = new QAction(QIcon(":/Resources/icons/simulation-parameters.svg"), Helper::simulationParams, this);
  mpSimulationParamsAction->setStatusTip(Helper::simulationParamsTip);
  connect(mpSimulationParamsAction, SIGNAL(triggered()), SLOT(showSimulationParamsDialog()));
  // Actions for shapes and Components
  // Manhattanize Action
  mpManhattanizeAction = new QAction(tr("Manhattanize"), this);
  mpManhattanizeAction->setStatusTip(tr("Manhattanize the lines"));
  mpManhattanizeAction->setDisabled(isSystemLibrary);
  connect(mpManhattanizeAction, SIGNAL(triggered()), SLOT(manhattanizeItems()));
  // Delete Action
  mpDeleteAction = new QAction(QIcon(":/Resources/icons/delete.svg"), Helper::deleteStr, this);
  mpDeleteAction->setStatusTip(tr("Deletes the item"));
  mpDeleteAction->setShortcut(QKeySequence::Delete);
  mpDeleteAction->setDisabled(isSystemLibrary);
  connect(mpDeleteAction, SIGNAL(triggered()), SLOT(deleteItems()));
  // Duplicate Action
  mpDuplicateAction = new QAction(QIcon(":/Resources/icons/duplicate.svg"), Helper::duplicate, this);
  mpDuplicateAction->setStatusTip(Helper::duplicateTip);
  mpDuplicateAction->setShortcut(QKeySequence("Ctrl+d"));
  mpDuplicateAction->setDisabled(isSystemLibrary);
  connect(mpDuplicateAction, SIGNAL(triggered()), SLOT(duplicateItems()));
  // Bring To Front Action
  mpBringToFrontAction = new QAction(QIcon(":/Resources/icons/bring-to-front.svg"), tr("Bring to Front"), this);
  mpBringToFrontAction->setStatusTip(tr("Brings the item to front"));
  mpBringToFrontAction->setDisabled(isSystemLibrary);
  mpBringToFrontAction->setDisabled(true);
  // Bring Forward Action
  mpBringForwardAction = new QAction(QIcon(":/Resources/icons/bring-forward.svg"), tr("Bring Forward"), this);
  mpBringForwardAction->setStatusTip(tr("Brings the item one level forward"));
  mpBringForwardAction->setDisabled(isSystemLibrary);
  mpBringForwardAction->setDisabled(true);
  // Send To Back Action
  mpSendToBackAction = new QAction(QIcon(":/Resources/icons/send-to-back.svg"), tr("Send to Back"), this);
  mpSendToBackAction->setStatusTip(tr("Sends the item to back"));
  mpSendToBackAction->setDisabled(isSystemLibrary);
  mpSendToBackAction->setDisabled(true);
  // Send Backward Action
  mpSendBackwardAction = new QAction(QIcon(":/Resources/icons/send-backward.svg"), tr("Send Backward"), this);
  mpSendBackwardAction->setStatusTip(tr("Sends the item one level backward"));
  mpSendBackwardAction->setDisabled(isSystemLibrary);
  mpSendBackwardAction->setDisabled(true);
  // Rotate ClockWise Action
  mpRotateClockwiseAction = new QAction(QIcon(":/Resources/icons/rotateclockwise.svg"), tr("Rotate Clockwise"), this);
  mpRotateClockwiseAction->setStatusTip(tr("Rotates the item clockwise"));
  mpRotateClockwiseAction->setShortcut(QKeySequence("Ctrl+r"));
  mpRotateClockwiseAction->setDisabled(isSystemLibrary);
  connect(mpRotateClockwiseAction, SIGNAL(triggered()), SLOT(rotateClockwise()));
  // Rotate Anti-ClockWise Action
  mpRotateAntiClockwiseAction = new QAction(QIcon(":/Resources/icons/rotateanticlockwise.svg"), tr("Rotate Anticlockwise"), this);
  mpRotateAntiClockwiseAction->setStatusTip(tr("Rotates the item anticlockwise"));
  mpRotateAntiClockwiseAction->setShortcut(QKeySequence("Ctrl+Shift+r"));
  mpRotateAntiClockwiseAction->setDisabled(isSystemLibrary);
  connect(mpRotateAntiClockwiseAction, SIGNAL(triggered()), SLOT(rotateAntiClockwise()));
  // Flip Horizontal Action
  mpFlipHorizontalAction = new QAction(QIcon(":/Resources/icons/flip-horizontal.svg"), tr("Flip Horizontal"), this);
  mpFlipHorizontalAction->setStatusTip(tr("Flips the item horizontally"));
  mpFlipHorizontalAction->setShortcut(QKeySequence("h"));
  mpFlipHorizontalAction->setDisabled(isSystemLibrary);
  connect(mpFlipHorizontalAction, SIGNAL(triggered()), SLOT(flipHorizontal()));
  // Flip Vertical Action
  mpFlipVerticalAction = new QAction(QIcon(":/Resources/icons/flip-vertical.svg"), tr("Flip Vertical"), this);
  mpFlipVerticalAction->setStatusTip(tr("Flips the item vertically"));
  mpFlipVerticalAction->setShortcut(QKeySequence("v"));
  mpFlipVerticalAction->setDisabled(isSystemLibrary);
  connect(mpFlipVerticalAction, SIGNAL(triggered()), SLOT(flipVertical()));
  // set initial state Action
  mpSetInitialStateAction = new QAction(tr("Set Initial State"), this);
  mpSetInitialStateAction->setStatusTip(tr("Sets the state as initial state"));
  connect(mpSetInitialStateAction, SIGNAL(triggered()), SLOT(setInitialState()));
  // cancel transition Action
  mpCancelTransitionAction = new QAction(tr("Cancel Transition"), this);
  mpCancelTransitionAction->setStatusTip(tr("Cancels the current transition"));
  connect(mpCancelTransitionAction, SIGNAL(triggered()), SLOT(cancelTransition()));
}

/*!
 * \brief GraphicsView::isItemDroppedOnItself
 * Checks if item is dropped on itself.
 * \param pLibraryTreeItem
 * \return
 */
bool GraphicsView::isClassDroppedOnItself(LibraryTreeItem *pLibraryTreeItem)
{
  OptionsDialog *pOptionsDialog = OptionsDialog::instance();
  if (mpModelWidget->getLibraryTreeItem()->getNameStructure().compare(pLibraryTreeItem->getNameStructure()) == 0) {
    if (pOptionsDialog->getNotificationsPage()->getItemDroppedOnItselfCheckBox()->isChecked()) {
      NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::ItemDroppedOnItself,
                                                                          NotificationsDialog::InformationIcon,
                                                                          MainWindow::instance());
      pNotificationsDialog->exec();
    }
    return true;
  }
  return false;
}

/*!
 * \brief GraphicsView::isAnyItemSelectedAndEditable
 * If the class is system library then returns false.
 * Checks all the selected items. If the selected item is not inherited then returns true otherwise false.
 * \param key
 * \return
 */
bool GraphicsView::isAnyItemSelectedAndEditable(int key)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || isVisualizationView()) {
    return false;
  }
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    if (mpModelWidget->getLibraryTreeItem()->isComponentElement()) {
      switch (key) {
        case Qt::Key_Delete:
        case Qt::Key_R: // rotate
        case Qt::Key_H: // horizontal flip
        case Qt::Key_V: // vertical flip
          return false;
        default:
          break;
      }
    }
  }
  bool selectedAndEditable = false;
  QList<QGraphicsItem*> selectedItems = scene()->selectedItems();
  for (int i = 0 ; i < selectedItems.size() ; i++) {
    // check the selected components.
    Component *pComponent = dynamic_cast<Component*>(selectedItems.at(i));
    if (pComponent && !pComponent->isInheritedComponent()) {
      return true;
    }
    // check the selected connections and shapes.
    ShapeAnnotation *pShapeAnnotation = dynamic_cast<ShapeAnnotation*>(selectedItems.at(i));
    if (pShapeAnnotation && !pShapeAnnotation->isInheritedShape()) {
      LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(pShapeAnnotation);
      // if the shape is connection line then we only return true for certain cases.
      if (pLineAnnotation && pLineAnnotation->getLineType() == LineAnnotation::ConnectionType) {
        switch (key) {
          case Qt::Key_Delete:
            selectedAndEditable = true;
            break;
          default:
            selectedAndEditable = false;
            break;
        }
      } else {
        return true;
      }
    }
  }
  return selectedAndEditable;
}

/*!
 * \brief GraphicsView::connectorComponentAtPosition
 * Returns the connector component at the position.
 * \param position
 * \return
 */
Component* GraphicsView::connectorComponentAtPosition(QPoint position)
{
  /* Ticket:4215
   * Allow making connection from the connectors which are under some other shape or component.
   * itemAt() only returns the top level item.
   * Use items() to get all items at position and then return the first connector component from the list.
   */
  QList<QGraphicsItem*> graphicsItems = items(position);
  foreach (QGraphicsItem *pGraphicsItem, graphicsItems) {
    if (pGraphicsItem && pGraphicsItem->parentItem()) {
      Component *pComponent = dynamic_cast<Component*>(pGraphicsItem->parentItem());
      if (pComponent) {
        Component *pRootComponent = pComponent->getRootParentComponent();
        if (pRootComponent && pRootComponent->isSelected()) {
          return 0;
        } else if (pRootComponent && !pRootComponent->isSelected()) {
          if (MainWindow::instance()->getConnectModeAction()->isChecked() && mViewType == StringHandler::Diagram &&
              !(mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || isVisualizationView()) &&
              ((pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->isConnector()) ||
               (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel &&
                pComponent->getComponentType() == Component::Port) ||
               (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS &&
                (pComponent->getLibraryTreeItem()->getOMSConnector() || pComponent->getLibraryTreeItem()->getOMSBusConnector()
                 || pComponent->getLibraryTreeItem()->getOMSTLMBusConnector() || pComponent->getComponentType() == Component::Port)))) {
            return pComponent;
          }
        }
      }
    }
  }
  return 0;
}

/*!
 * \brief GraphicsView::stateComponentAtPosition
 * Returns the state component at the position.
 * \param position
 * \return
 */
Component* GraphicsView::stateComponentAtPosition(QPoint position)
{
  QList<QGraphicsItem*> graphicsItems = items(position);
  foreach (QGraphicsItem *pGraphicsItem, graphicsItems) {
    if (pGraphicsItem && pGraphicsItem->parentItem()) {
      Component *pComponent = dynamic_cast<Component*>(pGraphicsItem->parentItem());
      if (pComponent) {
        Component *pRootComponent = pComponent->getRootParentComponent();
        if (pRootComponent && !pRootComponent->isSelected()) {
          if (MainWindow::instance()->getTransitionModeAction()->isChecked() && mViewType == StringHandler::Diagram &&
              !(mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || isVisualizationView()) &&
              ((pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica &&
                pComponent->getLibraryTreeItem()->isState()))) {
            return pComponent;
          }
        }
      }
    }
  }
  return 0;
}

void GraphicsView::addConnection(Component *pComponent)
{
  // When clicking the start component
  if (!isCreatingConnection()) {
    QPointF startPos;
    if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
      startPos = roundPoint(pComponent->mapToScene(pComponent->boundingRect().center()));
    } else {
      startPos = snapPointToGrid(pComponent->mapToScene(pComponent->boundingRect().center()));
    }
    mpConnectionLineAnnotation = new LineAnnotation(LineAnnotation::ConnectionType, pComponent, this);
    setIsCreatingConnection(true);
    mpConnectionLineAnnotation->addPoint(startPos);
    mpConnectionLineAnnotation->addPoint(startPos);
    mpConnectionLineAnnotation->addPoint(startPos);
    /* Ticket:4196
     * If we are starting connection from expandable connector or array connector
     * then set the line thickness to 0.5
     */
    if ((pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
        (pComponent->getParentComponent() && pComponent->getRootParentComponent()->getComponentInfo()->isArray()) ||
        (!pComponent->getParentComponent() && pComponent->getRootParentComponent()->getLibraryTreeItem() && pComponent->getRootParentComponent()->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
        (pComponent->getParentComponent() && pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
        (pComponent->getComponentInfo() && pComponent->getComponentInfo()->isArray())) {
      mpConnectionLineAnnotation->setLineThickness(0.5);
    }
  } else if (isCreatingConnection()) { // When clicking the end component
    mpConnectionLineAnnotation->setEndComponent(pComponent);
    // update the last point to the center of component
    QPointF newPos;
    if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
      newPos = roundPoint(pComponent->mapToScene(pComponent->boundingRect().center()));
    } else {
      newPos = snapPointToGrid(pComponent->mapToScene(pComponent->boundingRect().center()));
    }
    mpConnectionLineAnnotation->updateEndPoint(newPos);
    mpConnectionLineAnnotation->update();
    // check if connection is valid
    Component *pStartComponent = mpConnectionLineAnnotation->getStartComponent();
    MainWindow *pMainWindow = MainWindow::instance();
    if (pStartComponent == pComponent) {
      QMessageBox::information(pMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::information),
                               GUIMessages::getMessage(GUIMessages::SAME_COMPONENT_CONNECT), Helper::ok);
      removeCurrentConnection();
    } else {
      /* Ticket:4956
       * Only set the connection line thickness to 0.5 when both connectors are either expandable or array.
       * Otherwise set it to 0.25 i.e., default.
       */
      if (((pStartComponent->getLibraryTreeItem() && pStartComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
           (pStartComponent->getParentComponent() && pStartComponent->getRootParentComponent()->getComponentInfo()->isArray()) ||
           (!pStartComponent->getParentComponent() && pStartComponent->getRootParentComponent()->getLibraryTreeItem() && pStartComponent->getRootParentComponent()->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
           (pStartComponent->getParentComponent() && pStartComponent->getLibraryTreeItem() && pStartComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
           (pStartComponent->getComponentInfo() && pStartComponent->getComponentInfo()->isArray())) &&
          ((pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
           (pComponent->getParentComponent() && pComponent->getRootParentComponent()->getComponentInfo()->isArray()) ||
           (!pComponent->getParentComponent() && pComponent->getRootParentComponent()->getLibraryTreeItem() && pComponent->getRootParentComponent()->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
           (pComponent->getParentComponent() && pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
           (pComponent->getComponentInfo() && pComponent->getComponentInfo()->isArray()))) {
        mpConnectionLineAnnotation->setLineThickness(0.5);
      } else {
        /* Ticket:4956
         * If the start connector is either expandable or array and the end connector is not then change the line color to end connector.
         */
        if (((pStartComponent->getLibraryTreeItem() && pStartComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
             (pStartComponent->getParentComponent() && pStartComponent->getRootParentComponent()->getComponentInfo()->isArray()) ||
             (!pStartComponent->getParentComponent() && pStartComponent->getRootParentComponent()->getLibraryTreeItem() && pStartComponent->getRootParentComponent()->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
             (pStartComponent->getParentComponent() && pStartComponent->getLibraryTreeItem() && pStartComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
             (pStartComponent->getComponentInfo() && pStartComponent->getComponentInfo()->isArray())) &&
            (!(pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
             (pComponent->getParentComponent() && pComponent->getRootParentComponent()->getComponentInfo()->isArray()) ||
             (!pComponent->getParentComponent() && pComponent->getRootParentComponent()->getLibraryTreeItem() && pComponent->getRootParentComponent()->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
             (pComponent->getParentComponent() && pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
             (pComponent->getComponentInfo() && pComponent->getComponentInfo()->isArray()))) {
          if (pComponent->getLibraryTreeItem()) {
            if (!pComponent->getLibraryTreeItem()->getModelWidget()) {
              MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pComponent->getLibraryTreeItem(), false);
            }
            ShapeAnnotation *pShapeAnnotation;
            if (pComponent->getLibraryTreeItem()->getModelWidget()->getIconGraphicsView()
                && pComponent->getLibraryTreeItem()->getModelWidget()->getIconGraphicsView()->getShapesList().size() > 0) {
              pShapeAnnotation = pComponent->getLibraryTreeItem()->getModelWidget()->getIconGraphicsView()->getShapesList().at(0);
              mpConnectionLineAnnotation->setLineColor(pShapeAnnotation->getLineColor());
            } else if (pComponent->getShapesList().size() > 0) {
              ShapeAnnotation *pShapeAnnotation = pComponent->getShapesList().at(0);
              mpConnectionLineAnnotation->setLineColor(pShapeAnnotation->getLineColor());
            }
          }
        }
        mpConnectionLineAnnotation->setLineThickness(0.25);
      }
      // check of any of starting or ending components are array
      bool showConnectionArrayDialog = false;
      if ((pStartComponent->getParentComponent() && pStartComponent->getRootParentComponent()->getComponentInfo()->isArray()) ||
          (!pStartComponent->getParentComponent() && pStartComponent->getRootParentComponent()->getLibraryTreeItem() && pStartComponent->getRootParentComponent()->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
          (pStartComponent->getParentComponent() && pStartComponent->getLibraryTreeItem() && pStartComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
          (pStartComponent->getComponentInfo() && pStartComponent->getComponentInfo()->isArray()) ||
          (pComponent->getParentComponent() && pComponent->getRootParentComponent()->getComponentInfo()->isArray()) ||
          (!pComponent->getParentComponent() && pComponent->getRootParentComponent()->getLibraryTreeItem() && pComponent->getRootParentComponent()->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
          (pComponent->getParentComponent() && pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector) ||
          (pComponent->getComponentInfo() && pComponent->getComponentInfo()->isArray())) {
        showConnectionArrayDialog = true;
      }
      // check if any starting or ending components are bus
      bool showBusConnectionDialog = false;
      if ((pStartComponent->getLibraryTreeItem() && pStartComponent->getLibraryTreeItem()->getOMSBusConnector())
        || (pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->getOMSBusConnector())) {
        showBusConnectionDialog = true;
      }
      if (showConnectionArrayDialog) {
        CreateConnectionDialog *pConnectionArray = new CreateConnectionDialog(this, mpConnectionLineAnnotation, MainWindow::instance());
        // if user cancels the array connection
        if (!pConnectionArray->exec()) {
          removeCurrentConnection();
        }
      } else if (showBusConnectionDialog) {
        BusConnectionDialog *pBusConnectionDialog = new BusConnectionDialog(this, mpConnectionLineAnnotation);
        // if user cancels the bus connection
        if (!pBusConnectionDialog->exec()) {
          removeCurrentConnection();
        }
      } else if ((pStartComponent->getLibraryTreeItem() && pStartComponent->getLibraryTreeItem()->getOMSTLMBusConnector())
                 && (pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->getOMSTLMBusConnector())) {
        TLMConnectionDialog *pTLMBusConnectionDialog = new TLMConnectionDialog(this, mpConnectionLineAnnotation);
        // if user cancels the tlm bus connection
        if (!pTLMBusConnectionDialog->exec()) {
          removeCurrentConnection();
        }
      } else {
        QString startComponentName, endComponentName;
        if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
          if (pStartComponent->getLibraryTreeItem()) {
            startComponentName = pStartComponent->getLibraryTreeItem()->getNameStructure();
          }
          if (pComponent->getLibraryTreeItem()) {
            endComponentName = pComponent->getLibraryTreeItem()->getNameStructure();
          }
        } else {
          if (pStartComponent->getParentComponent()) {
            startComponentName = QString("%1.%2").arg(pStartComponent->getRootParentComponent()->getName()).arg(pStartComponent->getName());
          } else {
            startComponentName = pStartComponent->getName();
          }
          if (pComponent->getParentComponent()) {
            endComponentName = QString("%1.%2").arg(pComponent->getRootParentComponent()->getName()).arg(pComponent->getName());
          } else {
            endComponentName = pComponent->getName();
          }
        }
        mpConnectionLineAnnotation->setStartComponentName(startComponentName);
        mpConnectionLineAnnotation->setEndComponentName(endComponentName);
        if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
          CompositeModelEditor* editor = dynamic_cast<CompositeModelEditor*>(mpModelWidget->getEditor());
          if(!editor->okToConnect(mpConnectionLineAnnotation)) {
            removeCurrentConnection();
          }
          else {
            CompositeModelConnectionAttributes *pCompositeModelConnectionAttributes;
            pCompositeModelConnectionAttributes = new CompositeModelConnectionAttributes(this, mpConnectionLineAnnotation, false, MainWindow::instance());
            // if user cancels the array connection
            if (!pCompositeModelConnectionAttributes->exec()) {
              removeCurrentConnection();
            }
          }
        } else {
          mpModelWidget->getUndoStack()->push(new AddConnectionCommand(mpConnectionLineAnnotation, true));
          mpModelWidget->getLibraryTreeItem()->emitConnectionAdded(mpConnectionLineAnnotation);
          mpModelWidget->updateModelText();
        }
      }
      setIsCreatingConnection(false);
    }
  }
}

/*!
 * \brief GraphicsView::removeCurrentConnection
 * Removes the current connecting connector from the model.
 */
void GraphicsView::removeCurrentConnection()
{
  if (isCreatingConnection()) {
    setIsCreatingConnection(false);
    delete mpConnectionLineAnnotation;
    mpConnectionLineAnnotation = 0;
  }
}

void GraphicsView::addTransition(Component *pComponent)
{
  // When clicking the start state
  if (!isCreatingTransition()) {
    QPointF startPos = snapPointToGrid(pComponent->mapToScene(pComponent->boundingRect().center()));
    mpTransitionLineAnnotation = new LineAnnotation(LineAnnotation::TransitionType, pComponent, this);
    mpTransitionLineAnnotation->getTextAnnotation()->setVisible(false);
    setIsCreatingTransition(true);
    mpTransitionLineAnnotation->addPoint(startPos);
    mpTransitionLineAnnotation->addPoint(startPos);
    mpTransitionLineAnnotation->addPoint(startPos);
  } else if (isCreatingTransition()) { // When clicking the end state
    mpTransitionLineAnnotation->setEndComponent(pComponent);
    // Remove reduntant points so that Liang Barsky algorithm can work well.
    mpTransitionLineAnnotation->removeRedundantPointsGeometriesAndCornerItems();
    QList<QPointF> points = mpTransitionLineAnnotation->getPoints();
    // Find the start state intersection point.
    QRectF sceneRectF = mpTransitionLineAnnotation->getStartComponent()->sceneBoundingRect();
    QList<QPointF> newPos = Utilities::liangBarskyClipper(sceneRectF.topLeft().x(), sceneRectF.topLeft().y(),
                                                          sceneRectF.bottomRight().x(), sceneRectF.bottomRight().y(),
                                                          points.at(0).x(), points.at(0).y(),
                                                          points.at(1).x(), points.at(1).y());
    mpTransitionLineAnnotation->updateStartPoint(snapPointToGrid(newPos.at(1)));
    // Find the end state intersection point.
    sceneRectF = pComponent->sceneBoundingRect();
    newPos = Utilities::liangBarskyClipper(sceneRectF.topLeft().x(), sceneRectF.topLeft().y(),
                                           sceneRectF.bottomRight().x(), sceneRectF.bottomRight().y(),
                                           points.at(points.size() - 2).x(), points.at(points.size() - 2).y(),
                                           points.at(points.size() - 1).x(), points.at(points.size() - 1).y());
    mpTransitionLineAnnotation->updateEndPoint(snapPointToGrid(newPos.at(0)));
    mpTransitionLineAnnotation->update();
    // check if connection is valid
    Component *pStartComponent = mpTransitionLineAnnotation->getStartComponent();
    if (pStartComponent == pComponent) {
      QMessageBox::information(MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::information),
                               GUIMessages::getMessage(GUIMessages::SAME_COMPONENT_CONNECT), Helper::ok);
      removeCurrentTransition();
    } else {
      QString startComponentName, endComponentName;
      if (pStartComponent->getParentComponent()) {
        startComponentName = QString(pStartComponent->getRootParentComponent()->getName()).append(".").append(pStartComponent->getName());
      } else {
        startComponentName = pStartComponent->getName();
      }
      if (pComponent->getParentComponent()) {
        endComponentName = QString(pComponent->getRootParentComponent()->getName()).append(".").append(pComponent->getName());
      } else {
        endComponentName = pComponent->getName();
      }
      mpTransitionLineAnnotation->setStartComponentName(startComponentName);
      mpTransitionLineAnnotation->setEndComponentName(endComponentName);
      CreateOrEditTransitionDialog *pCreateOrEditTransitionDialog = new CreateOrEditTransitionDialog(this, mpTransitionLineAnnotation, false,
                                                                                                     MainWindow::instance());
      if (!pCreateOrEditTransitionDialog->exec()) {
        removeCurrentTransition();
      }
    }
    setIsCreatingTransition(false);
  }
}

/*!
 * \brief GraphicsView::removeCurrentTransition
 * Removes the current connecting transition from the model.
 */
void GraphicsView::removeCurrentTransition()
{
  if (isCreatingTransition()) {
    setIsCreatingTransition(false);
    delete mpTransitionLineAnnotation;
    mpTransitionLineAnnotation = 0;
  }
}

/*!
 * \brief GraphicsView::deleteConnection
 * Deletes the connection from the class.
 * \param pConnectionLineAnnotation - is a pointer to the connection to delete.
 */
void GraphicsView::deleteConnection(LineAnnotation *pConnectionLineAnnotation)
{
  pConnectionLineAnnotation->setSelected(false);
  // if deleting a bus connection
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    if (pConnectionLineAnnotation->getStartComponent()->getLibraryTreeItem()
        && pConnectionLineAnnotation->getStartComponent()->getLibraryTreeItem()->getOMSBusConnector()
        && pConnectionLineAnnotation->getEndComponent()->getLibraryTreeItem()
        && pConnectionLineAnnotation->getEndComponent()->getLibraryTreeItem()->getOMSBusConnector()) {
      oms_busconnector_t *pStartBus = pConnectionLineAnnotation->getStartComponent()->getLibraryTreeItem()->getOMSBusConnector();
      oms_busconnector_t *pEndBus = pConnectionLineAnnotation->getEndComponent()->getLibraryTreeItem()->getOMSBusConnector();
      // start bus connectors
      QStringList startBusConnectors;
      if (pStartBus->connectors) {
        for (int i = 0; pStartBus->connectors[i] ; ++i) {
          startBusConnectors.append(QString(pStartBus->connectors[i]));
        }
      }
      // end bus connectors
      QStringList endBusConnectors;
      if (pEndBus->connectors) {
        for (int i = 0; pEndBus->connectors[i] ; ++i) {
          endBusConnectors.append(QString(pEndBus->connectors[i]));
        }
      }
      // Delete the atomic connections before deleting the actual bus connection.
      foreach (LineAnnotation *pAtomicConnectionLineAnnotation, mConnectionsList) {
        if (pAtomicConnectionLineAnnotation->getOMSConnectionType() == oms_connection_single) {
          if (pStartBus->connectors) {
            for (int i = 0; pStartBus->connectors[i] ; ++i) {
              if (startBusConnectors.contains(pAtomicConnectionLineAnnotation->getStartComponent()->getName())
                  && endBusConnectors.contains(pAtomicConnectionLineAnnotation->getEndComponent()->getName())) {
                mpModelWidget->getUndoStack()->push(new DeleteConnectionCommand(pAtomicConnectionLineAnnotation));
                break;
              }
            }
          }
        }
      }
    }
  }
  // Delete the connection
  mpModelWidget->getUndoStack()->push(new DeleteConnectionCommand(pConnectionLineAnnotation));
}

/*!
 * \brief GraphicsView::deleteTransition
 * Deletes the transition from the class.
 * \param pTransitionLineAnnotation - is a pointer to the transition to delete.
 */
void GraphicsView::deleteTransition(LineAnnotation *pTransitionLineAnnotation)
{
  pTransitionLineAnnotation->setSelected(false);
  mpModelWidget->getUndoStack()->push(new DeleteTransitionCommand(pTransitionLineAnnotation));
}

/*!
 * \brief GraphicsView::deleteInitialState
 * Deletes an initial state from the class.
 * \param pInitialLineAnnotation - is a pointer to the initial state to delete.
 */
void GraphicsView::deleteInitialState(LineAnnotation *pInitialLineAnnotation)
{
  pInitialLineAnnotation->setSelected(false);
  mpModelWidget->getUndoStack()->push(new DeleteInitialStateCommand(pInitialLineAnnotation));
}

//! Resets zoom factor to 100%.
//! @see zoomIn()
//! @see zoomOut()
void GraphicsView::resetZoom()
{
  resetMatrix();
  scale(1.0, -1.0);
  setIsCustomScale(false);
  resizeEvent(new QResizeEvent(QSize(0,0), QSize(0,0)));
}

//! Increases zoom factor by 12%.
//! @see resetZoom()
//! @see zoomOut()
void GraphicsView::zoomIn()
{
  // zoom in limitation max: 1000%
  if (matrix().m11() < 34 && matrix().m22() > -34) {
    setIsCustomScale(true);
    scale(1.12, 1.12);
  }
}

//! Decreases zoom factor by 12%.
//! @see resetZoom()
//! @see zoomIn()
void GraphicsView::zoomOut()
{
  // zoom out limitation min: 10%
  if (matrix().m11() > 0.2 && matrix().m22() < -0.2) {
    setIsCustomScale(true);
    scale(1/1.12, 1/1.12);
  }
}

/*!
 * \brief GraphicsView::selectAll
 * Selects all shapes, components and connectors.
 */
void GraphicsView::selectAll()
{
  foreach (QGraphicsItem *pItem, items()) {
    pItem->setSelected(true);
  }
}

/*!
 * \brief GraphicsView::clearSelection
 * Clears the selection of all shapes, components and connectors.
 */
void GraphicsView::clearSelection()
{
  foreach (QGraphicsItem *pItem, items()) {
    pItem->setSelected(false);
  }
}

/*!
 * \brief GraphicsView::addClassAnnotation
 * Adds the annotation string of Icon and Diagram layer to the model. Also creates the model icon in the tree.
 * If some custom models are cross referenced then update them accordingly.
 * \param alwaysAdd - if false then skip the OMCProxy::addClassAnnotation() if annotation is empty.
 */
void GraphicsView::addClassAnnotation(bool alwaysAdd)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || isVisualizationView()) {
    return;
  }
  MainWindow *pMainWindow = MainWindow::instance();
  // coordinate system
  QStringList coOrdinateSystemList;
  QList<QPointF> extent = mCoOrdinateSystem.getExtent();
  qreal x1 = extent.at(0).x();
  qreal y1 = extent.at(0).y();
  qreal x2 = extent.at(1).x();
  qreal y2 = extent.at(1).y();
  if (x1 != -100 || y1 != -100 || x2 != 100 || y2 != 100) {
    coOrdinateSystemList.append(QString("extent={{%1, %2}, {%3, %4}}").arg(x1).arg(y1).arg(x2).arg(y2));
  }
  // add the preserveAspectRatio
  if (!mCoOrdinateSystem.getPreserveAspectRatio()) {
    coOrdinateSystemList.append(QString("preserveAspectRatio=%1").arg(mCoOrdinateSystem.getPreserveAspectRatio() ? "true" : "false"));
  }
  // add the initial scale
  if (mCoOrdinateSystem.getInitialScale() != 0.1) {
    coOrdinateSystemList.append(QString("initialScale=%1").arg(mCoOrdinateSystem.getInitialScale()));
  }
  // add the grid
  QPointF grid = mCoOrdinateSystem.getGrid();
  if (grid.x() != 2 || grid.y() != 2) {
    coOrdinateSystemList.append(QString("grid={%1, %2}").arg(grid.x()).arg(grid.y()));
  }
  // graphics annotations
  QStringList graphicsList;
  if (mShapesList.size() > 0) {
    foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
      /* Don't add the inherited shape to the addClassAnnotation. */
      if (!pShapeAnnotation->isInheritedShape()) {
        graphicsList.append(pShapeAnnotation->getShapeAnnotation());
      }
    }
  }
  // build the annotation string
  QString annotationString;
  QString viewType = (mViewType == StringHandler::Icon) ? "Icon" : "Diagram";
  if (coOrdinateSystemList.size() > 0 && graphicsList.size() > 0) {
    annotationString = QString("annotate=%1(coordinateSystem=CoordinateSystem(%2), graphics={%3})").arg(viewType)
        .arg(coOrdinateSystemList.join(",")).arg(graphicsList.join(","));
  } else if (coOrdinateSystemList.size() > 0) {
    annotationString = QString("annotate=%1(coordinateSystem=CoordinateSystem(%2))").arg(viewType).arg(coOrdinateSystemList.join(","));
  } else if (graphicsList.size() > 0) {
    annotationString = QString("annotate=%1(graphics={%2})").arg(viewType).arg(graphicsList.join(","));
  } else {
    annotationString = QString("annotate=%1()").arg(viewType);
    /* Ticket #3731
     * Return from here since we don't want empty Icon & Diagram annotations.
     */
    if (!alwaysAdd) {
      return;
    }
  }
  // add the class annotation to model through OMC
  if (pMainWindow->getOMCProxy()->addClassAnnotation(mpModelWidget->getLibraryTreeItem()->getNameStructure(), annotationString)) {
    /* When something is added/changed in the icon layer then update the LibraryTreeItem in the Library Browser */
    if (mViewType == StringHandler::Icon) {
      mpModelWidget->getLibraryTreeItem()->handleIconUpdated();
    }
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          tr("Error in class annotation ") + pMainWindow->getOMCProxy()->getResult(),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief GraphicsView::showGraphicsViewProperties
 * Opens the GraphicsViewProperties dialog.
 */
void GraphicsView::showGraphicsViewProperties()
{
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    GraphicsViewProperties *pGraphicsViewProperties = new GraphicsViewProperties(this);
    pGraphicsViewProperties->exec();
  } else if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    ModelWidget *pModelWidget = 0;
    if (mpModelWidget->getLibraryTreeItem()->isTopLevel()) {
      if (mpModelWidget->getLibraryTreeItem()->childrenSize() > 0) {
        LibraryTreeItem *pSystemLibraryTreeItem = mpModelWidget->getLibraryTreeItem()->childAt(0);
        if (pSystemLibraryTreeItem && pSystemLibraryTreeItem->getModelWidget()) {
          pModelWidget = pSystemLibraryTreeItem->getModelWidget();
        }
      }
    } else {
      pModelWidget = mpModelWidget;
    }
    if (pModelWidget) {
      SystemSimulationInformationDialog *pSystemSimulationInformationDialog = new SystemSimulationInformationDialog(pModelWidget);
      pSystemSimulationInformationDialog->exec();
    }
  }
}

/*!
 * \brief GraphicsView::showSimulationParamsDialog
 * Opens the CompositeModelSimulationParamsDialog.
 */
void GraphicsView::showSimulationParamsDialog()
{
  CompositeModelSimulationParamsDialog *pCompositeModelSimulationParamsDialog = new CompositeModelSimulationParamsDialog(this);
  pCompositeModelSimulationParamsDialog->exec();
}

/*!
 * \brief GraphicsView::showRenameDialog
 * Opens the RenameItemDialog.
 */
void GraphicsView::showRenameDialog()
{
  RenameItemDialog *pRenameItemDialog;
  pRenameItemDialog = new RenameItemDialog(mpModelWidget->getLibraryTreeItem(), MainWindow::instance());
  pRenameItemDialog->exec();
}

/*!
 * \brief GraphicsView::manhattanizeItems
 * Manhattanize the selected items by emitting GraphicsView::mouseManhattanize() SIGNAL.
 */
void GraphicsView::manhattanizeItems()
{
  mpModelWidget->beginMacro("Manhattanize by mouse");
  emit mouseManhattanize();
  mpModelWidget->updateClassAnnotationIfNeeded();
  mpModelWidget->updateModelText();
  mpModelWidget->endMacro();
}

/*!
 * \brief GraphicsView::deleteItems
 * Deletes the selected items by emitting GraphicsView::mouseDelete() SIGNAL.
 */
void GraphicsView::deleteItems()
{
  mpModelWidget->beginMacro("Deleting by mouse");
  emit mouseDelete();
  mpModelWidget->updateClassAnnotationIfNeeded();
  mpModelWidget->updateModelText();
  mpModelWidget->endMacro();
}

/*!
 * \brief GraphicsView::duplicateItems
 * Duplicates the selected items by emitting GraphicsView::mouseDuplicate() SIGNAL.
 */
void GraphicsView::duplicateItems()
{
  mpModelWidget->beginMacro("Duplicate by mouse");
  emit mouseDuplicate();
  mpModelWidget->updateClassAnnotationIfNeeded();
  mpModelWidget->updateModelText();
  mpModelWidget->endMacro();
}

/*!
 * \brief GraphicsView::rotateClockwise
 * Rotates the selected items clockwise by emitting GraphicsView::mouseRotateClockwise() SIGNAL.
 */
void GraphicsView::rotateClockwise()
{
  mpModelWidget->beginMacro("Rotate clockwise by mouse");
  emit mouseRotateClockwise();
  mpModelWidget->updateClassAnnotationIfNeeded();
  mpModelWidget->updateModelText();
  mpModelWidget->endMacro();
}

/*!
 * \brief GraphicsView::rotateAntiClockwise
 * Rotates the selected items anti clockwise by emitting GraphicsView::mouseRotateAntiClockwise() SIGNAL.
 */
void GraphicsView::rotateAntiClockwise()
{
  mpModelWidget->beginMacro("Rotate anti clockwise by mouse");
  emit mouseRotateAntiClockwise();
  mpModelWidget->updateClassAnnotationIfNeeded();
  mpModelWidget->updateModelText();
  mpModelWidget->endMacro();
}

/*!
 * \brief GraphicsView::flipHorizontal
 * Flips the selected items horizontally emitting GraphicsView::mouseFlipHorizontal() SIGNAL.
 */
void GraphicsView::flipHorizontal()
{
  mpModelWidget->beginMacro("Flip horizontal by mouse");
  emit mouseFlipHorizontal();
  mpModelWidget->updateClassAnnotationIfNeeded();
  mpModelWidget->updateModelText();
  mpModelWidget->endMacro();
}

/*!
 * \brief GraphicsView::flipVertical
 * Flips the selected items vertically emitting GraphicsView::mouseFlipVertical() SIGNAL.
 */
void GraphicsView::flipVertical()
{
  mpModelWidget->beginMacro("Flip vertical by mouse");
  emit mouseFlipVertical();
  mpModelWidget->updateClassAnnotationIfNeeded();
  mpModelWidget->updateModelText();
  mpModelWidget->endMacro();
}

/*!
 * \brief GraphicsView::setInitialState
 * Sets the state as initial.
 */
void GraphicsView::setInitialState()
{
  if (mpTransitionLineAnnotation) {
    QString startComponentName;
    if (mpTransitionLineAnnotation->getStartComponent()->getParentComponent()) {
      startComponentName = QString(mpTransitionLineAnnotation->getStartComponent()->getRootParentComponent()->getName()).append(".")
          .append(mpTransitionLineAnnotation->getStartComponent()->getName());
    } else {
      startComponentName = mpTransitionLineAnnotation->getStartComponent()->getName();
    }
    mpTransitionLineAnnotation->setStartComponentName(startComponentName);
    mpTransitionLineAnnotation->setEndComponentName("");
    mpTransitionLineAnnotation->setLineType(LineAnnotation::InitialStateType);
    mpModelWidget->getUndoStack()->push(new AddInitialStateCommand(mpTransitionLineAnnotation, true));
    mpModelWidget->updateModelText();
    setIsCreatingTransition(false);
  }
}

/*!
 * \brief GraphicsView::cancelTransition
 * Cancels the current transition.
 */
void GraphicsView::cancelTransition()
{
  if (mpTransitionLineAnnotation) {
    removeCurrentTransition();
  }
}

/*!
 * \brief GraphicsView::dragMoveEvent
 * Defines what happens when dragged and moved an object in a GraphicsView.
 * \param event - contains information of the drag operation.
 */
void GraphicsView::dragMoveEvent(QDragMoveEvent *event)
{
  // check if the class is system library or a package or a OMSimulator model
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || isVisualizationView() ||
      mpModelWidget->getLibraryTreeItem()->getRestriction() == StringHandler::Package ||
      mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    event->ignore();
    return;
  }
  // read the mime data from the event
  if (event->mimeData()->hasFormat(Helper::modelicaComponentFormat) || event->mimeData()->hasFormat(Helper::modelicaFileFormat)) {
    event->setDropAction(Qt::CopyAction);
    event->accept();
  } else {
    event->ignore();
  }
}

/*!
 * \brief GraphicsView::dropEvent
 * Defines what happens when an object is dropped in a GraphicsView.
 * \param event - contains information of the drop operation.
 */
void GraphicsView::dropEvent(QDropEvent *event)
{
  setFocus();
  MainWindow *pMainWindow = MainWindow::instance();
  // check mimeData
  if (!event->mimeData()->hasFormat(Helper::modelicaComponentFormat) && !event->mimeData()->hasFormat(Helper::modelicaFileFormat)) {
    event->ignore();
    return;
  } else if (event->mimeData()->hasFormat(Helper::modelicaFileFormat)) {
    pMainWindow->openDroppedFile(event);
    event->accept();
  } else if (event->mimeData()->hasFormat(Helper::modelicaComponentFormat)) {
    // check if the class is system library
    if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || isVisualizationView()) {
      event->ignore();
      return;
    }
    QByteArray itemData = event->mimeData()->data(Helper::modelicaComponentFormat);
    QDataStream dataStream(&itemData, QIODevice::ReadOnly);
    QString className;
    dataStream >> className;
    if (addComponent(className, mapToScene(event->pos()))) {
      event->accept();
    } else {
      event->ignore();
    }
  } else {
    event->ignore();
  }
}

void GraphicsView::drawBackground(QPainter *painter, const QRectF &rect)
{
  if (mSkipBackground) {
    return;
  }
  QPen grayPen(QBrush(QColor(192, 192, 192)), 0);
  QPen lightGrayPen(QBrush(QColor(229, 229, 229)), 0);
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || isVisualizationView()) {
    painter->setBrush(QBrush(Qt::white, Qt::SolidPattern));
  } else if (mViewType == StringHandler::Icon) {
    painter->setBrush(QBrush(QColor(229, 244, 255), Qt::SolidPattern));
  } else {
    painter->setBrush(QBrush(QColor(242, 242, 242), Qt::SolidPattern));
  }
  // draw scene rectangle white background
  painter->setPen(Qt::NoPen);
  painter->drawRect(rect);
  painter->setBrush(QBrush(Qt::white, Qt::SolidPattern));
  painter->drawRect(getExtentRectangle());
  if (mpModelWidget->getModelWidgetContainer()->isShowGridLines() && !(mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || isVisualizationView())) {
    painter->setBrush(Qt::NoBrush);
    painter->setPen(lightGrayPen);
    /* Draw left half vertical lines */
    int horizontalGridStep = mCoOrdinateSystem.getHorizontalGridStep() * 10;
    qreal xAxisStep = 0;
    qreal yAxisStep = rect.y();
    xAxisStep -= horizontalGridStep;
    while (xAxisStep > rect.left()) {
      painter->drawLine(QPointF(xAxisStep, yAxisStep), QPointF(xAxisStep, rect.bottom()));
      xAxisStep -= horizontalGridStep;
    }
    /* Draw right half vertical lines */
    xAxisStep = 0;
    while (xAxisStep < rect.right()) {
      painter->drawLine(QPointF(xAxisStep, yAxisStep), QPointF(xAxisStep, rect.bottom()));
      xAxisStep += horizontalGridStep;
    }
    /* Draw left half horizontal lines */
    int verticalGridStep = mCoOrdinateSystem.getVerticalGridStep() * 10;
    xAxisStep = rect.x();
    yAxisStep = 0;
    yAxisStep += verticalGridStep;
    while (yAxisStep < rect.bottom()) {
      painter->drawLine(QPointF(xAxisStep, yAxisStep), QPointF(rect.right(), yAxisStep));
      yAxisStep += verticalGridStep;
    }
    /* Draw right half horizontal lines */
    yAxisStep = 0;
    while (yAxisStep > rect.top()) {
      painter->drawLine(QPointF(xAxisStep, yAxisStep), QPointF(rect.right(), yAxisStep));
      yAxisStep -= verticalGridStep;
    }
    /* set the middle horizontal and vertical line gray */
    painter->setPen(grayPen);
    painter->drawLine(QPointF(rect.left(), 0), QPointF(rect.right(), 0));
    painter->drawLine(QPointF(0, rect.top()), QPointF(0, rect.bottom()));
  }
  // draw scene rectangle
  painter->setPen(grayPen);
  painter->drawRect(getExtentRectangle());
}

//! Defines what happens when clicking in a GraphicsView.
//! @param event contains information of the mouse click operation.
void GraphicsView::mousePressEvent(QMouseEvent *event)
{
  if (event->button() == Qt::RightButton) {
    return;
  }
  // if user is starting panning.
  if (QApplication::keyboardModifiers() == Qt::ControlModifier) {
    setIsPanning(true);
    mLastMouseEventPos = event->pos();
    QGraphicsView::mousePressEvent(event);
    return;
  }
  MainWindow *pMainWindow = MainWindow::instance();
  QPointF snappedPoint = snapPointToGrid(mapToScene(event->pos()));
  bool eventConsumed = false;
  // if left button presses and we are creating a connector
  if (isCreatingConnection()) {
    if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
      mpConnectionLineAnnotation->addPoint(roundPoint(mapToScene(event->pos())));
    } else {
      mpConnectionLineAnnotation->addPoint(snappedPoint);
    }
    eventConsumed = true;
  } else if (isCreatingTransition()) {
    mpTransitionLineAnnotation->addPoint(snappedPoint);
    eventConsumed = true;
  } else if (pMainWindow->getLineShapeAction()->isChecked()) {
    /* if line shape tool button is checked then create a line */
    createLineShape(snappedPoint);
  } else if (pMainWindow->getPolygonShapeAction()->isChecked()) {
    /* if polygon shape tool button is checked then create a polygon */
    createPolygonShape(snappedPoint);
  } else if (pMainWindow->getRectangleShapeAction()->isChecked()) {
    /* if rectangle shape tool button is checked then create a rectangle */
    createRectangleShape(snappedPoint);
  } else if (pMainWindow->getEllipseShapeAction()->isChecked()) {
    /* if ellipse shape tool button is checked then create an ellipse */
    createEllipseShape(snappedPoint);
  } else if (pMainWindow->getTextShapeAction()->isChecked()) {
    /* if text shape tool button is checked then create a text */
    createTextShape(snappedPoint);
    eventConsumed = true;
  } else if (pMainWindow->getBitmapShapeAction()->isChecked()) {
    /* if bitmap shape tool button is checked then create a bitmap */
    createBitmapShape(snappedPoint);
    eventConsumed = true;
  } else if (dynamic_cast<ResizerItem*>(itemAt(event->pos()))) {
    // do nothing if resizer item is clicked. It will be handled in its class mousePressEvent();
  } else {
    // this flag is just used to have separate identity for if statement in mouse release event of graphicsview
    setIsMovingComponentsAndShapes(true);
    // save the position of all components
    foreach (Component *pComponent, mComponentsList) {
      pComponent->setOldPosition(pComponent->pos());
      pComponent->setOldScenePosition(pComponent->scenePos());
    }
    // save the position of all shapes
    foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
      pShapeAnnotation->setOldScenePosition(pShapeAnnotation->scenePos());
    }
    // save annotations of all connections
    foreach (LineAnnotation *pConnectionLineAnnotation, mConnectionsList) {
      pConnectionLineAnnotation->setOldAnnotation(pConnectionLineAnnotation->getOMCShapeAnnotation());
    }
    // save annotations of all transitions
    foreach (LineAnnotation *pTransitionLineAnnotation, mTransitionsList) {
      pTransitionLineAnnotation->setOldAnnotation(pTransitionLineAnnotation->getOMCShapeAnnotation());
    }
    // save annotations of all initial states
    foreach (LineAnnotation *pInitialStateLineAnnotation, mInitialStatesList) {
      pInitialStateLineAnnotation->setOldAnnotation(pInitialStateLineAnnotation->getOMCShapeAnnotation());
    }
  }
  // if some item is clicked
  if (Component *pComponent = connectorComponentAtPosition(event->pos())) {
    if (!isCreatingConnection()) {
      mpClickedComponent = pComponent;
    } else if (isCreatingConnection()) {
      addConnection(pComponent);  // end the connection
      eventConsumed = true; // consume the event so that connection line or end component will not become selected
    }
  } else if (Component *pComponent = stateComponentAtPosition(event->pos())) {
    if (!isCreatingTransition()) {
      mpClickedState = pComponent;
    } else if (isCreatingTransition()) {
      addTransition(pComponent);  // end the transition
      eventConsumed = true; // consume the event so that transition line or end component will not become selected
    }
  }
  if (!eventConsumed) {
    /* Ticket:4379 Select multiple objects with [Shift] key (not with [Control] key)
     * To provide multi select we switch the shift key with control.
     */
    if (event->modifiers() & Qt::ShiftModifier) {
      event->setModifiers((event->modifiers() & ~Qt::ShiftModifier) | Qt::ControlModifier);
    }
    QGraphicsView::mousePressEvent(event);
  }
}

/*!
 * \brief GraphicsView::mouseMoveEvent
 * Defines what happens when the mouse is moving in a GraphicsView.
 * \param event contains information of the mouse moving operation.
 */
void GraphicsView::mouseMoveEvent(QMouseEvent *event)
{
  // if we are in panning mode
  if (isPanning()) {
    QScrollBar *pHorizontalScrollBar = horizontalScrollBar();
    QScrollBar *pVerticalScrollBar = verticalScrollBar();
    QPoint delta = event->pos() - mLastMouseEventPos;
    mLastMouseEventPos = event->pos();
    pHorizontalScrollBar->setValue(pHorizontalScrollBar->value() + (isRightToLeft() ? delta.x() : -delta.x()));
    pVerticalScrollBar->setValue(pVerticalScrollBar->value() - delta.y());
    QGraphicsView::mouseMoveEvent(event);
    return;
  }
  // update the position label
  Label *pPositionLabel = MainWindow::instance()->getPositionLabel();
  pPositionLabel->setText(QString("X: %1, Y: %2").arg(QString::number(qRound(mapToScene(event->pos()).x())))
                          .arg(QString::number(qRound(mapToScene(event->pos()).y()))));
  QPointF snappedPoint = snapPointToGrid(mapToScene(event->pos()));
  // if user mouse over connector show Qt::CrossCursor.
  bool setCrossCursor = false;
  if (connectorComponentAtPosition(event->pos()) || stateComponentAtPosition(event->pos())) {
    setCrossCursor = true;
    /* If setOverrideCursor() has been called twice, calling restoreOverrideCursor() will activate the first cursor set.
   * Calling this function a second time restores the original widgets' cursors.
   * So we only set the cursor if it is not already Qt::CrossCursor.
   */
    if (!QApplication::overrideCursor() || QApplication::overrideCursor()->shape() != Qt::CrossCursor) {
      QApplication::setOverrideCursor(Qt::CrossCursor);
    }
  }
  // if user mouse is not on connector then reset the cursor.
  if (!setCrossCursor && QApplication::overrideCursor()) {
    QApplication::restoreOverrideCursor();
  }
  //If creating connector, the end port shall be updated to the mouse position.
  if (isCreatingConnection()) {
    if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
      mpConnectionLineAnnotation->updateEndPoint(roundPoint(mapToScene(event->pos())));
    } else {
      mpConnectionLineAnnotation->updateEndPoint(snappedPoint);
    }
    mpConnectionLineAnnotation->update();
  } else if (isCreatingTransition()) {
    mpTransitionLineAnnotation->updateEndPoint(snappedPoint);
    mpTransitionLineAnnotation->update();
  } else if (isCreatingLineShape()) {
    mpLineShapeAnnotation->updateEndPoint(snappedPoint);
    mpLineShapeAnnotation->update();
  } else if (isCreatingPolygonShape()) {
    mpPolygonShapeAnnotation->updateEndPoint(snappedPoint);
    mpPolygonShapeAnnotation->update();
  } else if (isCreatingRectangleShape()) {
    mpRectangleShapeAnnotation->updateEndExtent(snappedPoint);
    mpRectangleShapeAnnotation->update();
  } else if (isCreatingEllipseShape()) {
    mpEllipseShapeAnnotation->updateEndExtent(snappedPoint);
    mpEllipseShapeAnnotation->update();
  } else if (isCreatingTextShape()) {
    mpTextShapeAnnotation->updateEndExtent(snappedPoint);
    mpTextShapeAnnotation->update();
  } else if (isCreatingBitmapShape()) {
    mpBitmapShapeAnnotation->updateEndExtent(snappedPoint);
    mpBitmapShapeAnnotation->update();
  } else if (mpClickedComponent) {
    addConnection(mpClickedComponent);  // start the connection
    if (mpClickedComponent) { // if we creating a connection then don't select the starting component.
      mpClickedComponent->setSelected(false);
    }
  } else if (mpClickedState) {
    addTransition(mpClickedState);  // start the transition
    if (mpClickedState) { // if we creating a transition then don't select the starting state.
      mpClickedState->setSelected(false);
    }
  }
  QGraphicsView::mouseMoveEvent(event);
}

void GraphicsView::mouseReleaseEvent(QMouseEvent *event)
{
  if (event->button() == Qt::RightButton) {
    return;
  }
  setIsPanning(false);
  mpClickedComponent = 0;
  mpClickedState = 0;
  if (isMovingComponentsAndShapes()) {
    setIsMovingComponentsAndShapes(false);
    bool hasComponentMoved = false;
    bool hasShapeMoved = false;
    bool beginMacro = false;
    // if component position is really changed then update component annotation
    foreach (Component *pComponent, mComponentsList) {
      if (pComponent->getOldPosition() != pComponent->pos()) {
        if (!beginMacro) {
          mpModelWidget->beginMacro("Move items by mouse");
          beginMacro = true;
        }
        Transformation oldTransformation = pComponent->mTransformation;
        QPointF positionDifference = pComponent->scenePos() - pComponent->getOldScenePosition();
        pComponent->mTransformation.adjustPosition(positionDifference.x(), positionDifference.y());
        pComponent->updateComponentTransformations(oldTransformation);
        hasComponentMoved = true;
      }
    }
    // if shape position is changed then update class annotation
    foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
      if (pShapeAnnotation->getOldScenePosition() != pShapeAnnotation->scenePos()) {
        if (!beginMacro) {
          mpModelWidget->beginMacro("Move items by mouse");
          beginMacro = true;
        }
        QString oldAnnotation = pShapeAnnotation->getOMCShapeAnnotation();
        pShapeAnnotation->mTransformation.setOrigin(pShapeAnnotation->scenePos());
        bool state = pShapeAnnotation->flags().testFlag(QGraphicsItem::ItemSendsGeometryChanges);
        pShapeAnnotation->setFlag(QGraphicsItem::ItemSendsGeometryChanges, false);
        pShapeAnnotation->setPos(0, 0);
        pShapeAnnotation->setFlag(QGraphicsItem::ItemSendsGeometryChanges, state);
        pShapeAnnotation->setTransform(pShapeAnnotation->mTransformation.getTransformationMatrix());
        pShapeAnnotation->setOrigin(pShapeAnnotation->mTransformation.getPosition());
        QString newAnnotation = pShapeAnnotation->getOMCShapeAnnotation();
        mpModelWidget->getUndoStack()->push(new UpdateShapeCommand(pShapeAnnotation, oldAnnotation, newAnnotation));
        hasShapeMoved = true;
      }
    }
    if (hasShapeMoved) {
      addClassAnnotation();
    }
    if (hasComponentMoved || hasShapeMoved) {
      mpModelWidget->updateModelText();
    }
    // if we have started he undo stack macro then we should end it.
    if (beginMacro) {
      mpModelWidget->endMacro();
    }
  }
  /* Ticket:4379 Select multiple objects with [Shift] key (not with [Control] key)
   * To provide multi select we switch the shift key with control.
   * Yes we need to do this in both mousePressEvent and mouseReleaseEvent.
   */
  if (event->modifiers() & Qt::ShiftModifier) {
    event->setModifiers((event->modifiers() & ~Qt::ShiftModifier) | Qt::ControlModifier);
  }
  QGraphicsView::mouseReleaseEvent(event);
}

void GraphicsView::mouseDoubleClickEvent(QMouseEvent *event)
{
  MainWindow *pMainWindow = MainWindow::instance();
  if (isCreatingLineShape()) {
    // finish creating the line
    setIsCreatingLineShape(false);
    // set the transformation matrix
    mpLineShapeAnnotation->setOrigin(mpLineShapeAnnotation->sceneBoundingRect().center());
    mpLineShapeAnnotation->adjustPointsWithOrigin();
    mpLineShapeAnnotation->initializeTransformation();
    // draw corner items for the Line shape
    mpLineShapeAnnotation->removePoint(mpLineShapeAnnotation->getPoints().size() - 1);
    mpLineShapeAnnotation->drawCornerItems();
    mpLineShapeAnnotation->setSelected(true);
    // make the toolbar button of line unchecked
    pMainWindow->getLineShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    mpModelWidget->getLibraryTreeItem()->emitShapeAdded(mpLineShapeAnnotation, this);
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
    return;
  } else if (isCreatingPolygonShape()) {
    // finish creating the polygon
    setIsCreatingPolygonShape(false);
    // set the transformation matrix
    mpPolygonShapeAnnotation->setOrigin(roundPoint(mpPolygonShapeAnnotation->sceneBoundingRect().center()));
    mpPolygonShapeAnnotation->adjustPointsWithOrigin();
    mpPolygonShapeAnnotation->initializeTransformation();
    // draw corner items for the polygon shape
    mpPolygonShapeAnnotation->removePoint(mpPolygonShapeAnnotation->getPoints().size() - 1);
    mpPolygonShapeAnnotation->drawCornerItems();
    mpPolygonShapeAnnotation->setSelected(true);
    // make the toolbar button of polygon unchecked
    pMainWindow->getPolygonShapeAction()->setChecked(false);
    pMainWindow->getConnectModeAction()->setChecked(true);
    mpModelWidget->getLibraryTreeItem()->emitShapeAdded(mpPolygonShapeAnnotation, this);
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
    return;
  }
  ShapeAnnotation *pShapeAnnotation = dynamic_cast<ShapeAnnotation*>(itemAt(event->pos()));
  /* Double click on Component also end up here.
   * But we don't have GraphicsView for the shapes inside the Component so we can go out of this block.
   */
  if (!isCreatingConnection() && !isCreatingTransition() && pShapeAnnotation && pShapeAnnotation->getGraphicsView()) {
    if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
      LineAnnotation *pTransitionLineAnnotation = dynamic_cast<LineAnnotation*>(pShapeAnnotation);
      if (pTransitionLineAnnotation && pTransitionLineAnnotation->getLineType() == LineAnnotation::TransitionType) {
        pShapeAnnotation->editTransition();
      } else {
        pShapeAnnotation->showShapeProperties();
      }
      return;
    } else if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
      LineAnnotation *pConnectionLineAnnotation = dynamic_cast<LineAnnotation*>(pShapeAnnotation);
      if (pConnectionLineAnnotation && pConnectionLineAnnotation->getLineType() == LineAnnotation::ConnectionType) {
        pConnectionLineAnnotation->showOMSConnection();
      }
    } else if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
      pShapeAnnotation->showShapeAttributes();
      return;
    }
  }
  // handle double click on the Component.
  QGraphicsItem *pGraphicsItem = itemAt(event->pos());
  if (pGraphicsItem && pGraphicsItem->parentItem()) {
    Component *pComponent = dynamic_cast<Component*>(pGraphicsItem->parentItem());
    if (pComponent) {
      Component *pRootComponent = pComponent->getRootParentComponent();
      if (pRootComponent) {
        if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
          pRootComponent->showSubModelAttributes();
          return;
        } else if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
          removeCurrentConnection();
          pRootComponent->handleOMSComponentDoubleClick();
          return;
        } else {
          removeCurrentConnection();
          removeCurrentTransition();
          /* ticket:4401 Open component class with shift + double click */
          if (QApplication::keyboardModifiers() == Qt::ShiftModifier) {
            pRootComponent->openClass();
            return;
          } else {
            pRootComponent->showParameters();
            return;
          }
        }
      }
    }
  }
  QGraphicsView::mouseDoubleClickEvent(event);
}

/*!
 * \brief GraphicsView::focusOutEvent
 * \param event
 */
void GraphicsView::focusOutEvent(QFocusEvent *event)
{
  // makesure we reset the Qt::CrossCursor
  if (QApplication::overrideCursor() && QApplication::overrideCursor()->shape() == Qt::CrossCursor) {
    QApplication::restoreOverrideCursor();
  }
  QGraphicsView::focusOutEvent(event);
}

void GraphicsView::keyPressEvent(QKeyEvent *event)
{
  // save annotations of all connections
  foreach (LineAnnotation *pConnectionLineAnnotation, mConnectionsList) {
    pConnectionLineAnnotation->setOldAnnotation(pConnectionLineAnnotation->getOMCShapeAnnotation());
  }
  // save annotations of all transitions
  foreach (LineAnnotation *pTransitionLineAnnotation, mTransitionsList) {
    pTransitionLineAnnotation->setOldAnnotation(pTransitionLineAnnotation->getOMCShapeAnnotation());
  }
  // save annotations of all initial states
  foreach (LineAnnotation *pInitialStateLineAnnotation, mInitialStatesList) {
    pInitialStateLineAnnotation->setOldAnnotation(pInitialStateLineAnnotation->getOMCShapeAnnotation());
  }
  bool shiftModifier = event->modifiers().testFlag(Qt::ShiftModifier);
  bool controlModifier = event->modifiers().testFlag(Qt::ControlModifier);
  if (event->key() == Qt::Key_Delete && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Deleting by key press");
    emit keyPressDelete();
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
    mpModelWidget->endMacro();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Up && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Move up by key press");
    emit keyPressUp();
    mpModelWidget->endMacro();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Up && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Move shift up by key press");
    emit keyPressShiftUp();
    mpModelWidget->endMacro();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Up && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Move control up by key press");
    emit keyPressCtrlUp();
    mpModelWidget->endMacro();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Down && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Move down by key press");
    emit keyPressDown();
    mpModelWidget->endMacro();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Down && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Move shift down by key press");
    emit keyPressShiftDown();
    mpModelWidget->endMacro();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Down && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Move control down by key press");
    emit keyPressCtrlDown();
    mpModelWidget->endMacro();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Left && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Move left by key press");
    emit keyPressLeft();
    mpModelWidget->endMacro();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Left && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Move shift left by key press");
    emit keyPressShiftLeft();
    mpModelWidget->endMacro();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Left && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Move control left by key press");
    emit keyPressCtrlLeft();
    mpModelWidget->endMacro();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Right && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Move right by key press");
    emit keyPressRight();
    mpModelWidget->endMacro();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Right && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Move shift right by key press");
    emit keyPressShiftRight();
    mpModelWidget->endMacro();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Right && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Move control right by key press");
    emit keyPressCtrlRight();
    mpModelWidget->endMacro();
  } else if (controlModifier && event->key() == Qt::Key_A) {
    selectAll();
  } else if (controlModifier && event->key() == Qt::Key_D && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Duplicate by key press");
    emit keyPressDuplicate();
    mpModelWidget->endMacro();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_R && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Rotate clockwise by key press");
    emit keyPressRotateClockwise();
    mpModelWidget->endMacro();
  } else if (shiftModifier && controlModifier && event->key() == Qt::Key_R && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Rotate anti clockwise by key press");
    emit keyPressRotateAntiClockwise();
    mpModelWidget->endMacro();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_H && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Flip horizontal by key press");
    emit keyPressFlipHorizontal();
    mpModelWidget->endMacro();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_V && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->beginMacro("Flip vertical by key press");
    emit keyPressFlipVertical();
    mpModelWidget->endMacro();
  } else if (shiftModifier && !controlModifier && (event->key() == Qt::Key_Enter || event->key() == Qt::Key_Return)) {
    /* ticket:4401 Open component class with shift + Enter */
    QList<QGraphicsItem*> selectedItems = scene()->selectedItems();
    if (selectedItems.size() == 1) {
      Component *pComponent = dynamic_cast<Component*>(selectedItems.at(0));
      if (pComponent) {
        Component *pRootComponent = pComponent->getRootParentComponent();
        if (pRootComponent) {
          pRootComponent->openClass();
        }
      }
    }
  } else if (event->key() == Qt::Key_Escape && isCreatingConnection()) {
    removeCurrentConnection();
  } else if (event->key() == Qt::Key_Escape && isCreatingTransition()) {
    removeCurrentTransition();
  } else {
    QGraphicsView::keyPressEvent(event);
  }
}

//! Defines what shall happen when a key is released.
//! @param event contains information about the keypress operation.
void GraphicsView::keyReleaseEvent(QKeyEvent *event)
{
  /* if user has pressed and hold the key. */
  if (event->isAutoRepeat()) {
    return QGraphicsView::keyReleaseEvent(event);
  }
  bool shiftModifier = event->modifiers().testFlag(Qt::ShiftModifier);
  bool controlModifier = event->modifiers().testFlag(Qt::ControlModifier);
  /* handle keys */
  if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Up && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Up && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Up && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Down && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Down && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Down && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Left && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Left && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Left && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Right && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (shiftModifier && !controlModifier && event->key() == Qt::Key_Right && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_Right && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (controlModifier && event->key() == Qt::Key_D && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_R && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (shiftModifier && controlModifier && event->key() == Qt::Key_R && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_H && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_V && isAnyItemSelectedAndEditable(event->key())) {
    mpModelWidget->updateClassAnnotationIfNeeded();
    mpModelWidget->updateModelText();
  } else {
    QGraphicsView::keyReleaseEvent(event);
  }
}

void GraphicsView::contextMenuEvent(QContextMenuEvent *event)
{
  /* If we are creating the connection OR creating any shape then don't show context menu */
  if (isCreatingConnection() ||
      isCreatingLineShape() ||
      isCreatingPolygonShape() ||
      isCreatingRectangleShape() ||
      isCreatingEllipseShape() ||
      isCreatingTextShape()) {
    return;
  }
  // if creating a transition
  if (isCreatingTransition()) {
    QMenu menu(MainWindow::instance());
    menu.addAction(mpSetInitialStateAction);
    menu.addSeparator();
    menu.addAction(mpCancelTransitionAction);
    menu.exec(event->globalPos());
    return;
  }
  // if some item is right clicked then don't show graphics view context menu
  if (!itemAt(event->pos())) {
    QMenu menu(MainWindow::instance());
    menu.addAction(MainWindow::instance()->getExportAsImageAction());
    menu.addAction(MainWindow::instance()->getExportToClipboardAction());
    if (!isVisualizationView()) {
      menu.addSeparator();
      menu.addAction(MainWindow::instance()->getExportToOMNotebookAction());
    }
    menu.addSeparator();
    menu.addAction(MainWindow::instance()->getPrintModelAction());
    if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
      menu.addSeparator();
      menu.addAction(mpPropertiesAction);
    } else if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
      menu.addSeparator();
      menu.addAction(mpRenameAction);
      menu.addSeparator();
      menu.addAction(mpSimulationParamsAction);
    } else if (mpModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
      if (mpModelWidget->getLibraryTreeItem()->isTopLevel() || mpModelWidget->getLibraryTreeItem()->isSystemElement()) {
        menu.addSeparator();
        menu.addAction(MainWindow::instance()->getAddSystemAction());
        if (mpModelWidget->getLibraryTreeItem()->isTopLevel()) {
          menu.addSeparator();
          menu.addAction(mpPropertiesAction);
        }
      }
      if (mpModelWidget->getLibraryTreeItem()->isSystemElement() || mpModelWidget->getLibraryTreeItem()->isComponentElement()) {
        menu.addSeparator();
        menu.addAction(MainWindow::instance()->getAddOrEditIconAction());
        menu.addAction(MainWindow::instance()->getDeleteIconAction());
        menu.addSeparator();
        menu.addAction(MainWindow::instance()->getAddConnectorAction());
        menu.addAction(MainWindow::instance()->getAddBusAction());
        menu.addAction(MainWindow::instance()->getAddTLMBusAction());
        if (mpModelWidget->getLibraryTreeItem()->isSystemElement()) {
          menu.addSeparator();
          menu.addAction(MainWindow::instance()->getAddSubModelAction());
          menu.addSeparator();
          menu.addAction(MainWindow::instance()->getAddSubModelAction());
          menu.addSeparator();
          menu.addAction(mpPropertiesAction);
        }
      }
    }
    menu.exec(event->globalPos());
    return;         // return from it because at a time we only want one context menu.
  }
  QGraphicsView::contextMenuEvent(event);
}

void GraphicsView::resizeEvent(QResizeEvent *event)
{
  fitInViewInternal();
  QGraphicsView::resizeEvent(event);
}

/*!
 * \brief GraphicsView::wheelEvent
 * Reimplementation of QGraphicsView::wheelEvent.
 * Allows zooming with mouse.
 * \param event
 */
void GraphicsView::wheelEvent(QWheelEvent *event)
{
  int numDegrees = event->delta() / 8;
  int numSteps = numDegrees * 3;
  bool controlModifier = event->modifiers().testFlag(Qt::ControlModifier);
  bool shiftModifier = event->modifiers().testFlag(Qt::ShiftModifier);
  // If Ctrl key is pressed and user has scrolled vertically then Zoom In/Out based on the scroll distance.
  if (event->orientation() == Qt::Vertical && controlModifier) {
    if (event->delta() > 0) {
      zoomIn();
    } else {
      zoomOut();
    }
  } else if ((event->orientation() == Qt::Horizontal) || (event->orientation() == Qt::Vertical && shiftModifier)) {
    // If Shift key is pressed and user has scrolled vertically then scroll the horizontal scrollbars.
    // If user has scrolled horizontally then scroll the horizontal scrollbars.
    horizontalScrollBar()->setValue(horizontalScrollBar()->value() - numSteps);
  } else if (event->orientation() == Qt::Vertical) {
    // If user has scrolled vertically then scroll the vertical scrollbars.
    verticalScrollBar()->setValue(verticalScrollBar()->value() - numSteps);
  } else {
    QGraphicsView::wheelEvent(event);
  }
}

/*!
 * \brief GraphicsView::leaveEvent
 * Reimplementation of QGraphicsView::leaveEvent.
 * Clears the position label in the status bar.
 * \param event
 */
void GraphicsView::leaveEvent(QEvent *event)
{
  // clear the position label
  MainWindow::instance()->getPositionLabel()->clear();
  QGraphicsView::leaveEvent(event);
}

WelcomePageWidget::WelcomePageWidget(QWidget *pParent)
  : QWidget(pParent)
{
  // main frame
  mpMainFrame = new QFrame;
  mpMainFrame->setContentsMargins(0, 0, 0, 0);
  mpMainFrame->setStyleSheet("QFrame{color:gray;}");
  // top frame
  mpTopFrame = new QFrame;
  mpTopFrame->setStyleSheet("QFrame{background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #828282, stop: 1 #5e5e5e);}");
  // top frame pixmap
  mpPixmapLabel = new Label;
  QPixmap pixmap(":/Resources/icons/omedit.png");
  mpPixmapLabel->setPixmap(pixmap.scaled(75, 72, Qt::KeepAspectRatio, Qt::SmoothTransformation));
  mpPixmapLabel->setStyleSheet("background-color : transparent;");
  // top frame heading
  mpHeadingLabel = Utilities::getHeadingLabel(QString(Helper::applicationName).append(" - ").append(Helper::applicationIntroText));
  mpHeadingLabel->setStyleSheet("background-color : transparent; color : white;");
#ifndef Q_OS_MAC
  mpHeadingLabel->setGraphicsEffect(new QGraphicsDropShadowEffect);
#endif
  mpHeadingLabel->setElideMode(Qt::ElideMiddle);
  // top frame layout
  QHBoxLayout *topFrameLayout = new QHBoxLayout;
  topFrameLayout->setAlignment(Qt::AlignLeft);
  topFrameLayout->addWidget(mpPixmapLabel);
  topFrameLayout->addWidget(mpHeadingLabel);
  mpTopFrame->setLayout(topFrameLayout);
  // RecentFiles Frame
  mpRecentFilesFrame = new QFrame;
  mpRecentFilesFrame->setFrameShape(QFrame::StyledPanel);
  mpRecentFilesFrame->setStyleSheet("QFrame{background-color: white;}");
  // recent items list
  mpRecentFilesLabel = Utilities::getHeadingLabel(tr("Recent Files"));
  mpNoRecentFileLabel = new Label(tr("No recent files found."));
  mpRecentItemsList = new QListWidget;
  mpRecentItemsList->setObjectName("RecentItemsList");
  mpRecentItemsList->setContentsMargins(0, 0, 0, 0);
  mpRecentItemsList->setSpacing(5);
  mpRecentItemsList->setFrameStyle(QFrame::NoFrame);
  mpRecentItemsList->setViewMode(QListView::ListMode);
  mpRecentItemsList->setMovement(QListView::Static);
  mpRecentItemsList->setIconSize(Helper::iconSize);
  mpRecentItemsList->setCurrentRow(0, QItemSelectionModel::Select);
  connect(mpRecentItemsList, SIGNAL(itemClicked(QListWidgetItem*)), SLOT(openRecentFileItem(QListWidgetItem*)));
  mpClearRecentFilesListButton = new QPushButton(tr("Clear Recent Files"));
  mpClearRecentFilesListButton->setStyleSheet("QPushButton{padding: 5px 15px 5px 15px;}");
  connect(mpClearRecentFilesListButton, SIGNAL(clicked()), MainWindow::instance(), SLOT(clearRecentFilesList()));
  // RecentFiles Frame layout
  QVBoxLayout *recentFilesFrameVBLayout = new QVBoxLayout;
  recentFilesFrameVBLayout->addWidget(mpRecentFilesLabel);
  recentFilesFrameVBLayout->addWidget(mpNoRecentFileLabel);
  recentFilesFrameVBLayout->addWidget(mpRecentItemsList);
  QHBoxLayout *recentFilesHBLayout = new QHBoxLayout;
  recentFilesHBLayout->addWidget(mpClearRecentFilesListButton, 0, Qt::AlignLeft);
  recentFilesFrameVBLayout->addLayout(recentFilesHBLayout);
  mpRecentFilesFrame->setLayout(recentFilesFrameVBLayout);
  // LatestNews Frame
  mpLatestNewsFrame = new QFrame;
  mpLatestNewsFrame->setFrameShape(QFrame::StyledPanel);
  mpLatestNewsFrame->setStyleSheet("QFrame{background-color: white;}");
  /* Read the show latest news settings */
  if (!OptionsDialog::instance()->getGeneralSettingsPage()->getShowLatestNewsCheckBox()->isChecked()) {
    mpLatestNewsFrame->setVisible(false);
  }
  // latest news
  mpLatestNewsLabel = Utilities::getHeadingLabel(tr("Latest News"));
  mpNoLatestNewsLabel = new Label;
  mpLatestNewsListWidget = new QListWidget;
  mpLatestNewsListWidget->setObjectName("LatestNewsList");
  mpLatestNewsListWidget->setContentsMargins(0, 0, 0, 0);
  mpLatestNewsListWidget->setSpacing(5);
  mpLatestNewsListWidget->setFrameStyle(QFrame::NoFrame);
  mpLatestNewsListWidget->setViewMode(QListView::ListMode);
  mpLatestNewsListWidget->setMovement(QListView::Static);
  mpLatestNewsListWidget->setIconSize(Helper::iconSize);
  mpLatestNewsListWidget->setCurrentRow(0, QItemSelectionModel::Select);
  mpReloadLatestNewsButton = new QPushButton(Helper::reload);
  mpReloadLatestNewsButton->setStyleSheet("QPushButton{padding: 5px 15px 5px 15px;}");
  connect(mpReloadLatestNewsButton, SIGNAL(clicked()), SLOT(addLatestNewsListItems()));
  mpVisitWebsiteLabel = new Label(tr("For more details visit our website <u><a href=\"http://www.openmodelica.org\">www.openmodelica.org</a></u>"));
  mpVisitWebsiteLabel->setTextFormat(Qt::RichText);
  mpVisitWebsiteLabel->setTextInteractionFlags(mpVisitWebsiteLabel->textInteractionFlags() | Qt::LinksAccessibleByMouse | Qt::LinksAccessibleByKeyboard);
  mpVisitWebsiteLabel->setOpenExternalLinks(true);
  connect(mpLatestNewsListWidget, SIGNAL(itemClicked(QListWidgetItem*)), SLOT(openLatestNewsItem(QListWidgetItem*)));
  // Latest News Frame layout
  QVBoxLayout *latestNewsFrameVBLayout = new QVBoxLayout;
  latestNewsFrameVBLayout->addWidget(mpLatestNewsLabel);
  latestNewsFrameVBLayout->addWidget(mpNoLatestNewsLabel);
  latestNewsFrameVBLayout->addWidget(mpLatestNewsListWidget);
  QHBoxLayout *latestNewsFrameHBLayout = new QHBoxLayout;
  latestNewsFrameHBLayout->addWidget(mpReloadLatestNewsButton, 0, Qt::AlignLeft);
  latestNewsFrameHBLayout->addWidget(mpVisitWebsiteLabel, 0, Qt::AlignRight);
  latestNewsFrameVBLayout->addLayout(latestNewsFrameHBLayout);
  mpLatestNewsFrame->setLayout(latestNewsFrameVBLayout);
  // create http object for request
  mpLatestNewsNetworkAccessManager = new QNetworkAccessManager;
  connect(mpLatestNewsNetworkAccessManager, SIGNAL(finished(QNetworkReply*)), SLOT(readLatestNewsXML(QNetworkReply*)));
  addLatestNewsListItems();
  // splitter
  mpSplitter = new QSplitter;
  /* Read the welcome page view settings */
  switch (OptionsDialog::instance()->getGeneralSettingsPage()->getWelcomePageView()){
    case 2:
      mpSplitter->setOrientation(Qt::Vertical);
      break;
    case 1:
    default:
      mpSplitter->setOrientation(Qt::Horizontal);
      break;
  }
  mpSplitter->setChildrenCollapsible(false);
  mpSplitter->setHandleWidth(4);
  mpSplitter->setContentsMargins(0, 0, 0, 0);
  mpSplitter->addWidget(mpRecentFilesFrame);
  mpSplitter->addWidget(mpLatestNewsFrame);
  // Read the welcome page splitter state
  QSettings *pSettings = Utilities::getApplicationSettings();
  mpSplitter->restoreState(pSettings->value("welcomePage/splitterState").toByteArray());
  // bottom frame
  mpBottomFrame = new QFrame;
  mpBottomFrame->setStyleSheet("QFrame{background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #828282, stop: 1 #5e5e5e);}");
  // bottom frame create and open buttons buttons
  mpCreateModelButton = new QPushButton(Helper::createNewModelicaClass);
  mpCreateModelButton->setStyleSheet("QPushButton{padding: 5px 15px 5px 15px;}");
  connect(mpCreateModelButton, SIGNAL(clicked()), MainWindow::instance(), SLOT(createNewModelicaClass()));
  mpOpenModelButton = new QPushButton(Helper::openModelicaFiles);
  mpOpenModelButton->setStyleSheet("QPushButton{padding: 5px 15px 5px 15px;}");
  connect(mpOpenModelButton, SIGNAL(clicked()), MainWindow::instance(), SLOT(openModelicaFile()));
  // bottom frame layout
  QHBoxLayout *bottomFrameLayout = new QHBoxLayout;
  bottomFrameLayout->addWidget(mpCreateModelButton, 0, Qt::AlignLeft);
  bottomFrameLayout->addWidget(mpOpenModelButton, 0, Qt::AlignRight);
  mpBottomFrame->setLayout(bottomFrameLayout);
  // vertical layout for frames
  QVBoxLayout *verticalLayout = new QVBoxLayout;
  verticalLayout->setSpacing(4);
  verticalLayout->setContentsMargins(0, 0, 0, 0);
  verticalLayout->addWidget(mpTopFrame, 0, Qt::AlignTop);
  verticalLayout->addWidget(mpSplitter, 1);
  verticalLayout->addWidget(mpBottomFrame, 0, Qt::AlignBottom);
  // main frame layout
  mpMainFrame->setLayout(verticalLayout);
  QHBoxLayout *layout = new QHBoxLayout;
  layout->setContentsMargins(0, 0, 0, 0);
  layout->addWidget(mpMainFrame);
  setLayout(layout);
}

void WelcomePageWidget::addRecentFilesListItems()
{
  // remove list items first
  mpRecentItemsList->clear();
  QSettings *pSettings = Utilities::getApplicationSettings();
  QList<QVariant> files = pSettings->value("recentFilesList/files").toList();
  int numRecentFiles = qMin(files.size(), (int)MainWindow::instance()->MaxRecentFiles);
  for (int i = 0; i < numRecentFiles; ++i)
  {
    RecentFile recentFile = qvariant_cast<RecentFile>(files[i]);
    QListWidgetItem *listItem = new QListWidgetItem(mpRecentItemsList);
    listItem->setIcon(QIcon(":/Resources/icons/next.svg"));
    listItem->setText(recentFile.fileName);
    listItem->setData(Qt::UserRole, recentFile.encoding);
  }
  if (files.size() > 0)
    mpNoRecentFileLabel->setVisible(false);
  else
    mpNoRecentFileLabel->setVisible(true);
}

QFrame* WelcomePageWidget::getLatestNewsFrame()
{
  return mpLatestNewsFrame;
}

QSplitter* WelcomePageWidget::getSplitter()
{
  return mpSplitter;
}

void WelcomePageWidget::addLatestNewsListItems()
{
  mpLatestNewsListWidget->clear();
  /* if show latest news settings is not set then don't fetch the latest news items. */
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getShowLatestNewsCheckBox()->isChecked())
  {
    QUrl newsUrl("https://openmodelica.org/index.php?option=com_content&view=category&id=23&format=feed&amp;type=rss");
    QNetworkReply *pNetworkReply = mpLatestNewsNetworkAccessManager->get(QNetworkRequest(newsUrl));
    pNetworkReply->ignoreSslErrors();
  }
}

void WelcomePageWidget::readLatestNewsXML(QNetworkReply *pNetworkReply)
{
  if (pNetworkReply->error() == QNetworkReply::HostNotFoundError)
  {
    mpNoLatestNewsLabel->setVisible(true);
    mpNoLatestNewsLabel->setText(tr("Sorry, no internet no news items."));
  }
  else if (pNetworkReply->error() == QNetworkReply::NoError)
  {
    QByteArray response(pNetworkReply->readAll());
    QXmlStreamReader xml(response);
    int count = 0;
    QString title, link;
    while (!xml.atEnd())
    {
      mpNoLatestNewsLabel->setVisible(false);
      xml.readNext();
      if (xml.tokenType() == QXmlStreamReader::StartElement)
      {
        if (xml.name() == "item")
        {
          while (!xml.atEnd())
          {
            xml.readNext();
            if (xml.tokenType() == QXmlStreamReader::StartElement)
            {
              if (xml.name() == "title")
                title = xml.readElementText();
              if (xml.name() == "link")
              {
                link = xml.readElementText();
                if (count >= (int)MainWindow::instance()->MaxRecentFiles)
                  break;
                count++;
                QListWidgetItem *listItem = new QListWidgetItem(mpLatestNewsListWidget);
                listItem->setIcon(QIcon(":/Resources/icons/next.svg"));
                listItem->setText(title);
                listItem->setData(Qt::UserRole, link);
                break;
              }
            }
          }
        }
      }
      if (count >= (int)MainWindow::instance()->MaxRecentFiles)
        break;
    }
  }
  else
  {
    mpNoLatestNewsLabel->setVisible(true);
    mpNoLatestNewsLabel->setText(QString(Helper::error).append(" - ").append(pNetworkReply->errorString()));
  }
}

void WelcomePageWidget::openRecentFileItem(QListWidgetItem *pItem)
{
  MainWindow::instance()->getLibraryWidget()->openFile(pItem->text(), pItem->data(Qt::UserRole).toString(), true, true);
}

void WelcomePageWidget::openLatestNewsItem(QListWidgetItem *pItem)
{
  QUrl url(pItem->data(Qt::UserRole).toString());
  QDesktopServices::openUrl(url);
}

/*!
 * \class UndoStack
 * \brief Subclass QUndoStack.\n
 * We need to handle which commands to push to the stack.
 */
/*!
 * \brief UndoStack::UndoStack
 * \param parent
 */
UndoStack::UndoStack(QObject *parent)
  : QUndoStack(parent)
{
  mEnabled = true;
}

/*!
 * \brief UndoStack::push
 * \param cmd
 */
void UndoStack::push(UndoCommand *cmd)
{
  /* We only push the commands to the stack when its enabled.
   * When the stack is not enabled we don't push the command but we do execute the command.
   * Most of such cases are when loading and opening a class. The operations performed at that time are not needed on the stack.
   * This is needed since we don't want to call clear on the stack.
   */
  if (isEnabled()) {
    /* If the stack is enabled then call the command redo function to check if the command fails or not.
     * If the command fails then delete it and don't push to the stack.
     * If the command doesn't fail then disable it and push to the stack. We need to disable it since QUndoStack::push() calls the
     * command redo function and we already called redo once so we don't want to call it here.
     * Enable the command after the push is done.
     */
    cmd->redoInternal();
    if (cmd->isFailed()) {
      delete cmd;
    } else {
      cmd->setEnabled(false);
      QUndoStack::push(cmd);
      cmd->setEnabled(true);
    }
  } else {
    cmd->redo();
  }
}

ModelWidget::ModelWidget(LibraryTreeItem* pLibraryTreeItem, ModelWidgetContainer *pModelWidgetContainer)
  : QWidget(pModelWidgetContainer), mpModelWidgetContainer(pModelWidgetContainer), mpLibraryTreeItem(pLibraryTreeItem),
    mComponentsLoaded(false), mDiagramViewLoaded(false), mConnectionsLoaded(false), mCreateModelWidgetComponents(false),
    mExtendsModifiersLoaded(false)
{
  mExtendsModifiersMap.clear();
  // create widgets based on library type
  if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
    // icon graphics framework
    mpIconGraphicsScene = new GraphicsScene(StringHandler::Icon, this);
    mpIconGraphicsView = new GraphicsView(StringHandler::Icon, this);
    mpIconGraphicsView->setScene(mpIconGraphicsScene);
    mpIconGraphicsView->hide();
    // diagram graphics framework
    mpDiagramGraphicsScene = new GraphicsScene(StringHandler::Diagram, this);
    mpDiagramGraphicsView = new GraphicsView(StringHandler::Diagram, this);
    mpDiagramGraphicsView->setScene(mpDiagramGraphicsScene);
    mpDiagramGraphicsView->hide();
    // Undo stack for model
    mpUndoStack = new UndoStack;
    connect(mpUndoStack, SIGNAL(canUndoChanged(bool)), SLOT(handleCanUndoChanged(bool)));
    connect(mpUndoStack, SIGNAL(canRedoChanged(bool)), SLOT(handleCanRedoChanged(bool)));
    if (MainWindow::instance()->isDebug()) {
      mpUndoView = new QUndoView(mpUndoStack);
    }
    getModelInheritedClasses();
    drawModelInheritedClassShapes(this, StringHandler::Icon);
    getModelIconDiagramShapes(StringHandler::Icon);
    /* Ticket:2960
     * Just a workaround to make browsing faster.
     * We don't get the components here i.e items are shown without connectors in the Libraries Browser.
     * Fetch the components when we really need to draw them.
     */
    /*! @todo Uncomment the following code once we have new faster frontend and remove the flag mComponentsLoaded. */
    //    drawModelInheritedClassComponents(this, StringHandler::Icon);
    //    getModelComponents();
    //    drawModelIconComponents();
    mpEditor = 0;
  } else if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::OMS) {
    // icon graphics framework
    if (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isComponentElement()) {
      mpIconGraphicsScene = new GraphicsScene(StringHandler::Icon, this);
      mpIconGraphicsView = new GraphicsView(StringHandler::Icon, this);
      mpIconGraphicsView->setScene(mpIconGraphicsScene);
      mpIconGraphicsView->hide();
    } else {
      mpIconGraphicsScene = 0;
      mpIconGraphicsView = 0;
    }
    // diagram graphics framework
    mpDiagramGraphicsScene = new GraphicsScene(StringHandler::Diagram, this);
    mpDiagramGraphicsView = new GraphicsView(StringHandler::Diagram, this);
    mpDiagramGraphicsView->setScene(mpDiagramGraphicsScene);
    mpDiagramGraphicsView->hide();
    // Undo stack for model
    mpUndoStack = new UndoStack;
    connect(mpUndoStack, SIGNAL(canUndoChanged(bool)), SLOT(handleCanUndoChanged(bool)));
    connect(mpUndoStack, SIGNAL(canRedoChanged(bool)), SLOT(handleCanRedoChanged(bool)));
    if (MainWindow::instance()->isDebug()) {
      mpUndoView = new QUndoView(mpUndoStack);
    }
    mpEditor = 0;
    mpUndoStack->setEnabled(false);
    drawOMSModelIconElements();
    mpUndoStack->setEnabled(true);
  } else {
    // icon graphics framework
    mpIconGraphicsScene = 0;
    mpIconGraphicsView = 0;
    // diagram graphics framework
    mpDiagramGraphicsScene = 0;
    mpDiagramGraphicsView = 0;
    // undo stack for model
    mpUndoStack = 0;
    if (MainWindow::instance()->isDebug()) {
      mpUndoView = 0;
    }
    mpEditor = 0;
  }
  // Read the file for LibraryTreeItem::Text
  if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Text && !mpLibraryTreeItem->isFilePathValid()) {
    QString contents = "";
    QFile file(mpLibraryTreeItem->getFileName());
    if (!file.open(QIODevice::ReadOnly)) {
      //      QMessageBox::critical(mpLibraryWidget->MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::error),
      //                            GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(pLibraryTreeItem->getFileName())
      //                            .arg(file.errorString()), Helper::ok);
    } else {
      contents = QString(file.readAll());
      file.close();
    }
    mpLibraryTreeItem->setClassText(contents);
  }
  // Clean up model widget if results are removed from variables browser
  connect(MainWindow::instance()->getVariablesWidget()->getVariablesTreeModel(),
          SIGNAL(variableTreeItemRemoved(QString)), this, SLOT(removeDynamicResults(QString)));
}

/*!
 * \brief ModelWidget::getExtendsModifiersMap
 * Returns a extends modifier map for extends class
 * \param extendsClass
 * \return
 */
QMap<QString, QString> ModelWidget::getExtendsModifiersMap(QString extendsClass)
{
  if (!mExtendsModifiersLoaded) {
    foreach (LibraryTreeItem *pLibraryTreeItem, mInheritedClassesList) {
      fetchExtendsModifiers(pLibraryTreeItem->getNameStructure());
    }
    mExtendsModifiersLoaded = true;
  }
  return mExtendsModifiersMap.value(extendsClass);
}

/*!
 * \brief ModelWidget::fetchExtendsModifiers
 * Gets the extends modifiers and their values.
 * \param extendsClass
 */
void ModelWidget::fetchExtendsModifiers(QString extendsClass)
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QStringList extendsModifiersList = pOMCProxy->getExtendsModifierNames(mpLibraryTreeItem->getNameStructure(), extendsClass);
  QMap<QString, QString> extendsModifiersMap;
  foreach (QString extendsModifier, extendsModifiersList) {
    QString extendsModifierValue = pOMCProxy->getExtendsModifierValue(mpLibraryTreeItem->getNameStructure(), extendsClass, extendsModifier);
    extendsModifiersMap.insert(extendsModifier, extendsModifierValue);
  }
  mExtendsModifiersMap.insert(extendsClass, extendsModifiersMap);
}

/*!
 * \brief ModelWidget::reDrawModelWidgetInheritedClasses
 * Redraws the class inherited classes shapes, components and connections.
 */
void ModelWidget::reDrawModelWidgetInheritedClasses()
{
  removeInheritedClassShapes(StringHandler::Icon);
  drawModelInheritedClassShapes(this, StringHandler::Icon);
  mpIconGraphicsView->reOrderShapes();
  if (mComponentsLoaded) {
    removeInheritedClassComponents(StringHandler::Icon);
    drawModelInheritedClassComponents(this, StringHandler::Icon);
  }
  if (mDiagramViewLoaded) {
    removeInheritedClassShapes(StringHandler::Diagram);
    drawModelInheritedClassShapes(this, StringHandler::Diagram);
    mpDiagramGraphicsView->reOrderShapes();
    removeInheritedClassComponents(StringHandler::Diagram);
    drawModelInheritedClassComponents(this, StringHandler::Diagram);
  }
  if (mConnectionsLoaded) {
    removeInheritedClassConnections();
    drawModelInheritedClassConnections(this);
  }
}

/*!
 * \brief ModelWidget::drawBaseCoOrdinateSystem
 * Draws the coordinate system from base class.
 * \param pModelWidget
 * \param pGraphicsView
 */
void ModelWidget::drawBaseCoOrdinateSystem(ModelWidget *pModelWidget, GraphicsView *pGraphicsView)
{
  foreach (LibraryTreeItem *pLibraryTreeItem, pModelWidget->getInheritedClassesList()) {
    if (!pLibraryTreeItem->isNonExisting()) {
      GraphicsView *pInheritedGraphicsView;
      if (pGraphicsView->getViewType() == StringHandler::Icon) {
        pInheritedGraphicsView = pLibraryTreeItem->getModelWidget()->getIconGraphicsView();
      } else {
        pInheritedGraphicsView = pLibraryTreeItem->getModelWidget()->getDiagramGraphicsView();
      }
      if (pInheritedGraphicsView->mCoOrdinateSystem.isValid()) {
        qreal left = pInheritedGraphicsView->mCoOrdinateSystem.getExtent().at(0).x();
        qreal bottom = pInheritedGraphicsView->mCoOrdinateSystem.getExtent().at(0).y();
        qreal right = pInheritedGraphicsView->mCoOrdinateSystem.getExtent().at(1).x();
        qreal top = pInheritedGraphicsView->mCoOrdinateSystem.getExtent().at(1).y();
        pGraphicsView->setExtentRectangle(left, bottom, right, top);
        break;
      } else {
        drawBaseCoOrdinateSystem(pLibraryTreeItem->getModelWidget(), pGraphicsView);
      }
    }
  }
}

/*!
 * \brief ModelWidget::createNonExistingInheritedShape
 * Creates a red cross for non-existing inherited class shape.
 * \param pGraphicsView
 * \return
 */
ShapeAnnotation* ModelWidget::createNonExistingInheritedShape(GraphicsView *pGraphicsView)
{
  LineAnnotation *pLineAnnotation = new LineAnnotation(pGraphicsView);
  pLineAnnotation->initializeTransformation();
  pLineAnnotation->drawCornerItems();
  pLineAnnotation->setCornerItemsActiveOrPassive();
  return pLineAnnotation;
}

/*!
 * \brief ModelWidget::createInheritedShape
 * Creates the inherited class shape.
 * \param pShapeAnnotation
 * \param pGraphicsView
 * \return
 */
ShapeAnnotation* ModelWidget::createInheritedShape(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView)
{
  if (dynamic_cast<LineAnnotation*>(pShapeAnnotation)) {
    LineAnnotation *pLineAnnotation = new LineAnnotation(pShapeAnnotation, pGraphicsView);
    pLineAnnotation->initializeTransformation();
    pLineAnnotation->drawCornerItems();
    pLineAnnotation->setCornerItemsActiveOrPassive();
    return pLineAnnotation;
  } else if (dynamic_cast<PolygonAnnotation*>(pShapeAnnotation)) {
    PolygonAnnotation *pPolygonAnnotation = new PolygonAnnotation(pShapeAnnotation, pGraphicsView);
    pPolygonAnnotation->initializeTransformation();
    pPolygonAnnotation->drawCornerItems();
    pPolygonAnnotation->setCornerItemsActiveOrPassive();
    return pPolygonAnnotation;
  } else if (dynamic_cast<RectangleAnnotation*>(pShapeAnnotation)) {
    RectangleAnnotation *pRectangleAnnotation = new RectangleAnnotation(pShapeAnnotation, pGraphicsView);
    pRectangleAnnotation->initializeTransformation();
    pRectangleAnnotation->drawCornerItems();
    pRectangleAnnotation->setCornerItemsActiveOrPassive();
    return pRectangleAnnotation;
  } else if (dynamic_cast<EllipseAnnotation*>(pShapeAnnotation)) {
    EllipseAnnotation *pEllipseAnnotation = new EllipseAnnotation(pShapeAnnotation, pGraphicsView);
    pEllipseAnnotation->initializeTransformation();
    pEllipseAnnotation->drawCornerItems();
    pEllipseAnnotation->setCornerItemsActiveOrPassive();
    return pEllipseAnnotation;
  } else if (dynamic_cast<TextAnnotation*>(pShapeAnnotation)) {
    TextAnnotation *pTextAnnotation = new TextAnnotation(pShapeAnnotation, pGraphicsView);
    pTextAnnotation->initializeTransformation();
    pTextAnnotation->drawCornerItems();
    pTextAnnotation->setCornerItemsActiveOrPassive();
    return pTextAnnotation;
  } else if (dynamic_cast<BitmapAnnotation*>(pShapeAnnotation)) {
    BitmapAnnotation *pBitmapAnnotation = new BitmapAnnotation(pShapeAnnotation, pGraphicsView);
    pBitmapAnnotation->initializeTransformation();
    pBitmapAnnotation->drawCornerItems();
    pBitmapAnnotation->setCornerItemsActiveOrPassive();
    return pBitmapAnnotation;
  }
  return 0;
}

/*!
 * \brief ModelWidget::createInheritedComponent
 * Creates the inherited component.
 * \param pComponent
 * \param pGraphicsView
 * \return
 */
Component* ModelWidget::createInheritedComponent(Component *pComponent, GraphicsView *pGraphicsView)
{
  return new Component(pComponent, pGraphicsView);
}

/*!
 * \brief ModelWidget::createInheritedConnection
 * Creates the inherited connection.
 * \param pConnectionLineAnnotation
 * \return
 */
LineAnnotation* ModelWidget::createInheritedConnection(LineAnnotation *pConnectionLineAnnotation)
{
  LineAnnotation *pInheritedConnectionLineAnnotation = new LineAnnotation(pConnectionLineAnnotation, mpDiagramGraphicsView);
  pInheritedConnectionLineAnnotation->setToolTip(QString("<b>connect</b>(%1, %2)<br /><br />%3 %4")
                                                 .arg(pInheritedConnectionLineAnnotation->getStartComponentName())
                                                 .arg(pInheritedConnectionLineAnnotation->getEndComponentName())
                                                 .arg(tr("Connection declared in"))
                                                 .arg(pConnectionLineAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure()));
  pInheritedConnectionLineAnnotation->drawCornerItems();
  pInheritedConnectionLineAnnotation->setCornerItemsActiveOrPassive();
  // Add the start component connection details.
  Component *pStartComponent = pInheritedConnectionLineAnnotation->getStartComponent();
  if (pStartComponent->getRootParentComponent()) {
    pStartComponent->getRootParentComponent()->addConnectionDetails(pInheritedConnectionLineAnnotation);
  } else {
    pStartComponent->addConnectionDetails(pInheritedConnectionLineAnnotation);
  }
  // Add the end component connection details.
  Component *pEndComponent = pInheritedConnectionLineAnnotation->getEndComponent();
  if (pEndComponent->getParentComponent()) {
    pEndComponent->getParentComponent()->addConnectionDetails(pInheritedConnectionLineAnnotation);
  } else {
    pEndComponent->addConnectionDetails(pInheritedConnectionLineAnnotation);
  }
  return pInheritedConnectionLineAnnotation;
}

/*!
 * \brief ModelWidget::loadComponents
 * Loads the model components if they are not loaded before.
 */
void ModelWidget::loadComponents()
{
  if (!mComponentsLoaded) {
    drawModelInheritedClassComponents(this, StringHandler::Icon);
    if (mpLibraryTreeItem->getAccess() >= LibraryTreeItem::diagram) {
      getModelComponents();
      drawModelIconComponents();
    }
    mComponentsLoaded = true;
  }
}

/*!
 * \brief ModelWidget::loadDiagramView
 * Loads the diagram view components if they are not loaded before.
 */
void ModelWidget::loadDiagramView()
{
  loadComponents();
  if (!mDiagramViewLoaded) {
    drawModelInheritedClassShapes(this, StringHandler::Diagram);
    getModelIconDiagramShapes(StringHandler::Diagram);
    drawModelInheritedClassComponents(this, StringHandler::Diagram);
    if (mpLibraryTreeItem->getAccess() >= LibraryTreeItem::diagram) {
      drawModelDiagramComponents();
    }
    mDiagramViewLoaded = true;
    /*! @note The following is not needed if we load the connectors alongwith the icon/diagram annotation.
     * We have disabled loading the connectors so user gets fast browsing of libraries.
     */
    mpLibraryTreeItem->handleIconUpdated();
  }
}

/*!
 * \brief ModelWidget::loadConnections
 * Loads the model connections if they are not loaded before.
 */
void ModelWidget::loadConnections()
{
  if (!mConnectionsLoaded) {
    drawModelInheritedClassConnections(this);
    if (mpLibraryTreeItem->getAccess() >= LibraryTreeItem::diagram) {
      getModelConnections();
      getModelTransitions();
      getModelInitialStates();
    }
    mConnectionsLoaded = true;
  }
}

/*!
 * \brief ModelWidget::getModelConnections
 * Gets the connections of the model and place them in the diagram GraphicsView.
 */
void ModelWidget::getModelConnections()
{
  // detect multiple declarations of a component instance
  detectMultipleDeclarations();
  // get the connections
  MainWindow *pMainWindow = MainWindow::instance();
  LibraryTreeModel *pLibraryTreeModel = pMainWindow->getLibraryWidget()->getLibraryTreeModel();
  int connectionCount = pMainWindow->getOMCProxy()->getConnectionCount(mpLibraryTreeItem->getNameStructure());
  for (int i = 1 ; i <= connectionCount ; i++) {
    // get the connection from OMC
    QStringList connectionList = pMainWindow->getOMCProxy()->getNthConnection(mpLibraryTreeItem->getNameStructure(), i);
    QString connectionString = QString("{%1}").arg(connectionList.join(","));
    // if the connectionString only contains two items then continue the loop,
    // because connection is not valid then
    if (connectionList.size() < 3) {
      continue;
    }
    // get start and end components
    QStringList startComponentList = StringHandler::makeVariableParts(connectionList.at(0));
    QStringList endComponentList = StringHandler::makeVariableParts(connectionList.at(1));
    // get start component
    Component *pStartComponent = 0;
    if (startComponentList.size() > 0) {
      QString startComponentName = startComponentList.at(0);
      if (startComponentName.contains("[")) {
        startComponentName = startComponentName.mid(0, startComponentName.indexOf("["));
      }
      pStartComponent = mpDiagramGraphicsView->getComponentObject(startComponentName);
    }
    // get start connector
    Component *pStartConnectorComponent = 0;
    Component *pEndConnectorComponent = 0;
    if (pStartComponent) {
      // if a component type is connector then we only get one item in startComponentList
      // check the startcomponentlist
      if (startComponentList.size() < 2
          || (pStartComponent->getLibraryTreeItem()
              && pStartComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector)) {
        pStartConnectorComponent = pStartComponent;
      } else if (pStartComponent->getLibraryTreeItem()
                 && !pLibraryTreeModel->findLibraryTreeItem(pStartComponent->getLibraryTreeItem()->getNameStructure())) {
        /* if class doesn't exist then connect with the red cross box */
        pStartConnectorComponent = pStartComponent;
      } else {
        // look for port from the parent component
        QString startComponentName = startComponentList.at(1);
        if (startComponentName.contains("[")) {
          startComponentName = startComponentName.mid(0, startComponentName.indexOf("["));
        }
        pStartConnectorComponent = getConnectorComponent(pStartComponent, startComponentName);
      }
    }
    // show error message if start component is not found.
    if (!pStartConnectorComponent) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                            GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION)
                                                            .arg(connectionList.at(0)).arg(connectionString),
                                                            Helper::scriptingKind, Helper::errorLevel));
      continue;
    }
    // get end component
    Component *pEndComponent = 0;
    if (endComponentList.size() > 0) {
      QString endComponentName = endComponentList.at(0);
      if (endComponentName.contains("[")) {
        endComponentName = endComponentName.mid(0, endComponentName.indexOf("["));
      }
      pEndComponent = mpDiagramGraphicsView->getComponentObject(endComponentName);
    }
    // get the end connector
    if (pEndComponent) {
      // if a component type is connector then we only get one item in endComponentList
      // check the endcomponentlist
      if (endComponentList.size() < 2
          || (pEndComponent->getLibraryTreeItem()
              && pEndComponent->getLibraryTreeItem()->getRestriction() == StringHandler::ExpandableConnector)) {
        pEndConnectorComponent = pEndComponent;
      } else if (pEndComponent->getLibraryTreeItem()
                 && !pLibraryTreeModel->findLibraryTreeItem(pEndComponent->getLibraryTreeItem()->getNameStructure())) {
        /* if class doesn't exist then connect with the red cross box */
        pEndConnectorComponent = pEndComponent;
      } else {
        QString endComponentName = endComponentList.at(1);
        if (endComponentName.contains("[")) {
          endComponentName = endComponentName.mid(0, endComponentName.indexOf("["));
        }
        pEndConnectorComponent = getConnectorComponent(pEndComponent, endComponentName);
      }
    }
    // show error message if end component is not found.
    if (!pEndConnectorComponent) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                            GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION)
                                                            .arg(connectionList.at(1)).arg(connectionString),
                                                            Helper::scriptingKind, Helper::errorLevel));
      continue;
    }
    // get the connector annotations from OMC
    QString connectionAnnotationString = pMainWindow->getOMCProxy()->getNthConnectionAnnotation(mpLibraryTreeItem->getNameStructure(), i);
    QStringList shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(connectionAnnotationString), '(', ')');
    // Now parse the shapes available in list
    QString lineShape = "";
    foreach (QString shape, shapesList) {
      if (shape.startsWith("Line")) {
        lineShape = shape.mid(QString("Line").length());
        lineShape = StringHandler::removeFirstLastParentheses(lineShape);
        break;  // break the loop once we have got the line annotation.
      }
    }
    LineAnnotation *pConnectionLineAnnotation;
    pConnectionLineAnnotation = new LineAnnotation(lineShape, pStartConnectorComponent, pEndConnectorComponent, mpDiagramGraphicsView);
    pConnectionLineAnnotation->setStartComponentName(connectionList.at(0));
    pConnectionLineAnnotation->setEndComponentName(connectionList.at(1));
    mpUndoStack->push(new AddConnectionCommand(pConnectionLineAnnotation, false));
  }
}

/*!
 * \brief ModelWidget::loadWidgetComponents
 * Creates the widgets for the ModelWidget.
 */
void ModelWidget::createModelWidgetComponents()
{
  if (!mCreateModelWidgetComponents) {
    // icon view tool button
    mpIconViewToolButton = new QToolButton;
    mpIconViewToolButton->setText(Helper::iconView);
    mpIconViewToolButton->setIcon(QIcon(":/Resources/icons/model.svg"));
    mpIconViewToolButton->setToolTip(Helper::iconView);
    mpIconViewToolButton->setAutoRaise(true);
    mpIconViewToolButton->setCheckable(true);
    // diagram view tool button
    mpDiagramViewToolButton = new QToolButton;
    mpDiagramViewToolButton->setText(Helper::diagramView);
    mpDiagramViewToolButton->setIcon(QIcon(":/Resources/icons/modeling.png"));
    mpDiagramViewToolButton->setToolTip(Helper::diagramView);
    mpDiagramViewToolButton->setAutoRaise(true);
    mpDiagramViewToolButton->setCheckable(true);
    // modelica text view tool button
    mpTextViewToolButton = new QToolButton;
    mpTextViewToolButton->setText(Helper::textView);
    mpTextViewToolButton->setIcon(QIcon(":/Resources/icons/modeltext.svg"));
    mpTextViewToolButton->setToolTip(Helper::textView);
    mpTextViewToolButton->setAutoRaise(true);
    mpTextViewToolButton->setCheckable(true);
    // documentation view tool button
    mpDocumentationViewToolButton = new QToolButton;
    mpDocumentationViewToolButton->setText(Helper::documentationView);
    mpDocumentationViewToolButton->setIcon(QIcon(":/Resources/icons/info-icon.svg"));
    mpDocumentationViewToolButton->setToolTip(Helper::documentationView);
    mpDocumentationViewToolButton->setAutoRaise(true);
    // view buttons box
    mpViewsButtonGroup = new QButtonGroup;
    mpViewsButtonGroup->setExclusive(true);
    mpViewsButtonGroup->addButton(mpDiagramViewToolButton);
    mpViewsButtonGroup->addButton(mpIconViewToolButton);
    mpViewsButtonGroup->addButton(mpTextViewToolButton);
    mpViewsButtonGroup->addButton(mpDocumentationViewToolButton);
    // frame to contain view buttons
    QFrame *pViewButtonsFrame = new QFrame;
    QHBoxLayout *pViewButtonsHorizontalLayout = new QHBoxLayout;
    pViewButtonsHorizontalLayout->setContentsMargins(0, 0, 0, 0);
    pViewButtonsHorizontalLayout->setSpacing(0);
    pViewButtonsFrame->setLayout(pViewButtonsHorizontalLayout);
    // set Project Status Bar lables
    mpReadOnlyLabel = mpLibraryTreeItem->isReadOnly() ? new Label(Helper::readOnly) : new Label(tr("Writable"));
    mpModelicaTypeLabel = new Label;
    mpViewTypeLabel = new Label;
    mpModelClassPathLabel = new Label(mpLibraryTreeItem->getNameStructure());
    mpModelFilePathLabel = new Label(mpLibraryTreeItem->getFileName());
    mpModelFilePathLabel->setElideMode(Qt::ElideMiddle);
    // documentation view tool button
    mpFileLockToolButton = new QToolButton;
    mpFileLockToolButton->setIcon(QIcon(mpLibraryTreeItem->isReadOnly() ? ":/Resources/icons/lock.svg" : ":/Resources/icons/unlock.svg"));
    mpFileLockToolButton->setText(mpLibraryTreeItem->isReadOnly() ? tr("Make writable") : tr("File is writable"));
    mpFileLockToolButton->setToolTip(mpFileLockToolButton->text());
    mpFileLockToolButton->setEnabled(mpLibraryTreeItem->isReadOnly() && !mpLibraryTreeItem->isSystemLibrary());
    mpFileLockToolButton->setAutoRaise(true);
    connect(mpFileLockToolButton, SIGNAL(clicked()), SLOT(makeFileWritAble()));
    // create project status bar
    mpModelStatusBar = new QStatusBar;
    mpModelStatusBar->setObjectName("ModelStatusBar");
    mpModelStatusBar->setSizeGripEnabled(false);
    mpModelStatusBar->addPermanentWidget(pViewButtonsFrame, 0);
    // create the main layout
    QVBoxLayout *pMainLayout = new QVBoxLayout;
    pMainLayout->setContentsMargins(0, 0, 0, 0);
    pMainLayout->setSpacing(4);
    pMainLayout->addWidget(mpModelStatusBar);
    setLayout(pMainLayout);
    MainWindow *pMainWindow = MainWindow::instance();
    // show hide widgets based on library type
    if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
      connect(mpIconViewToolButton, SIGNAL(toggled(bool)), SLOT(showIconView(bool)));
      connect(mpDiagramViewToolButton, SIGNAL(toggled(bool)), SLOT(showDiagramView(bool)));
      connect(mpTextViewToolButton, SIGNAL(toggled(bool)), SLOT(showTextView(bool)));
      connect(mpDocumentationViewToolButton, SIGNAL(clicked()), SLOT(showDocumentationView()));
      pViewButtonsHorizontalLayout->addWidget(mpIconViewToolButton);
      pViewButtonsHorizontalLayout->addWidget(mpDiagramViewToolButton);
      pViewButtonsHorizontalLayout->addWidget(mpTextViewToolButton);
      pViewButtonsHorizontalLayout->addWidget(mpDocumentationViewToolButton);
      mpModelicaTypeLabel->setText(StringHandler::getModelicaClassType(mpLibraryTreeItem->getRestriction()));
      mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::Diagram));
      // modelica text editor
      mpEditor = new ModelicaEditor(this);
      ModelicaHighlighter *pModelicaTextHighlighter = new ModelicaHighlighter(OptionsDialog::instance()->getModelicaEditorPage(),
                                                                              mpEditor->getPlainTextEdit());
      ModelicaEditor *pModelicaEditor = dynamic_cast<ModelicaEditor*>(mpEditor);
      pModelicaEditor->setPlainText(mpLibraryTreeItem->getClassText(pMainWindow->getLibraryWidget()->getLibraryTreeModel()), false);
      mpEditor->hide(); // set it hidden so that Find/Replace action can get correct value.
      connect(OptionsDialog::instance(), SIGNAL(modelicaEditorSettingsChanged()), pModelicaTextHighlighter, SLOT(settingsChanged()));
      mpModelStatusBar->addPermanentWidget(mpReadOnlyLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpModelicaTypeLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpViewTypeLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpModelClassPathLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpModelFilePathLabel, 1);
      mpModelStatusBar->addPermanentWidget(mpFileLockToolButton, 0);
      // set layout
      if (MainWindow::instance()->isDebug()) {
        pMainLayout->addWidget(mpUndoView);
      }
      pMainLayout->addWidget(mpDiagramGraphicsView, 1);
      pMainLayout->addWidget(mpIconGraphicsView, 1);
      mpUndoStack->clear();
    } else if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Text) {
      pViewButtonsHorizontalLayout->addWidget(mpTextViewToolButton);
      QFileInfo fileInfo(mpLibraryTreeItem->getFileName());
      if (Utilities::isCFile(fileInfo.suffix())) {
        mpEditor = new CEditor(this);
        CHighlighter *pCHighlighter = new CHighlighter(OptionsDialog::instance()->getCEditorPage(), mpEditor->getPlainTextEdit());
        CEditor *pCEditor = dynamic_cast<CEditor*>(mpEditor);
        pCEditor->setPlainText(mpLibraryTreeItem->getClassText(pMainWindow->getLibraryWidget()->getLibraryTreeModel()));
        mpEditor->hide();
        connect(OptionsDialog::instance(), SIGNAL(cEditorSettingsChanged()), pCHighlighter, SLOT(settingsChanged()));
      } else if (Utilities::isModelicaFile(fileInfo.suffix())) {
        mpEditor = new MetaModelicaEditor(this);
        MetaModelicaHighlighter *pMetaModelicaHighlighter;
        pMetaModelicaHighlighter = new MetaModelicaHighlighter(OptionsDialog::instance()->getMetaModelicaEditorPage(),
                                                               mpEditor->getPlainTextEdit());
        MetaModelicaEditor *pMetaModelicaEditor = dynamic_cast<MetaModelicaEditor*>(mpEditor);
        pMetaModelicaEditor->setPlainText(mpLibraryTreeItem->getClassText(pMainWindow->getLibraryWidget()->getLibraryTreeModel()));
        mpEditor->hide();
        connect(OptionsDialog::instance(), SIGNAL(metaModelicaEditorSettingsChanged()), pMetaModelicaHighlighter, SLOT(settingsChanged()));
      } else {
        mpEditor = new TextEditor(this);
        TextEditor *pTextEditor = dynamic_cast<TextEditor*>(mpEditor);
        pTextEditor->setPlainText(mpLibraryTreeItem->getClassText(pMainWindow->getLibraryWidget()->getLibraryTreeModel()));
        mpEditor->hide();
      }
      mpModelStatusBar->addPermanentWidget(mpReadOnlyLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpModelFilePathLabel, 1);
      mpModelStatusBar->addPermanentWidget(mpFileLockToolButton, 0);
      // set layout
      pMainLayout->addWidget(mpModelStatusBar);
    } else if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::CompositeModel) {
      connect(mpDiagramViewToolButton, SIGNAL(toggled(bool)), SLOT(showDiagramView(bool)));
      connect(mpTextViewToolButton, SIGNAL(toggled(bool)), SLOT(showTextView(bool)));
      pViewButtonsHorizontalLayout->addWidget(mpDiagramViewToolButton);
      pViewButtonsHorizontalLayout->addWidget(mpTextViewToolButton);
      // diagram graphics framework
      mpDiagramGraphicsScene = new GraphicsScene(StringHandler::Diagram, this);
      mpDiagramGraphicsView = new GraphicsView(StringHandler::Diagram, this);
      mpDiagramGraphicsView->setScene(mpDiagramGraphicsScene);
      mpDiagramGraphicsView->hide();
      // Undo stack for model
      mpUndoStack = new UndoStack;
      connect(mpUndoStack, SIGNAL(canUndoChanged(bool)), SLOT(handleCanUndoChanged(bool)));
      connect(mpUndoStack, SIGNAL(canRedoChanged(bool)), SLOT(handleCanRedoChanged(bool)));
      if (MainWindow::instance()->isDebug()) {
        mpUndoView = new QUndoView(mpUndoStack);
      }
      // create an xml editor for CompositeModel
      mpEditor = new CompositeModelEditor(this);
      CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpEditor);
      if (mpLibraryTreeItem->getFileName().isEmpty()) {
        QString defaultCompositeModelText = QString("<?xml version='1.0' encoding='UTF-8'?>\n"
                                                    "<!-- The root node is the composite-model -->\n"
                                                    "<Model Name=\"%1\">\n"
                                                    "  <!-- List of connected sub-models -->\n"
                                                    "  <SubModels/>\n"
                                                    "  <!-- List of TLM connections -->\n"
                                                    "  <Connections/>\n"
                                                    "  <!-- Parameters for the simulation -->\n"
                                                    "  <SimulationParams StartTime=\"0\" StopTime=\"1\" />\n"
                                                    "</Model>").arg(mpLibraryTreeItem->getName());
        pCompositeModelEditor->setPlainText(defaultCompositeModelText, false);
        mpLibraryTreeItem->setClassText(defaultCompositeModelText);
      } else {
        pCompositeModelEditor->setPlainText(mpLibraryTreeItem->getClassText(pMainWindow->getLibraryWidget()->getLibraryTreeModel()), false);
      }
      CompositeModelHighlighter *pCompositeModelHighlighter = new CompositeModelHighlighter(OptionsDialog::instance()->getCompositeModelEditorPage(),
                                                                                            mpEditor->getPlainTextEdit());
      mpEditor->hide(); // set it hidden so that Find/Replace action can get correct value.
      connect(OptionsDialog::instance(), SIGNAL(compositeModelEditorSettingsChanged()), pCompositeModelHighlighter, SLOT(settingsChanged()));
      // only get the TLM submodels and connectors if the we are not creating a new class.
      if (!mpLibraryTreeItem->getFileName().isEmpty()) {
        getCompositeModelSubModels();
        getCompositeModelConnections();
      }
      mpDiagramGraphicsScene->clearSelection();
      mpModelStatusBar->addPermanentWidget(mpReadOnlyLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpViewTypeLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpModelFilePathLabel, 1);
      mpModelStatusBar->addPermanentWidget(mpFileLockToolButton, 0);
      // set layout
      pMainLayout->addWidget(mpModelStatusBar);
      if (MainWindow::instance()->isDebug()) {
        pMainLayout->addWidget(mpUndoView);
      }
      pMainLayout->addWidget(mpDiagramGraphicsView, 1);
      mpUndoStack->clear();
    } else if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::OMS) {
      if (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isComponentElement()) {
        connect(mpIconViewToolButton, SIGNAL(toggled(bool)), SLOT(showIconView(bool)));
        pViewButtonsHorizontalLayout->addWidget(mpIconViewToolButton);
      }
      connect(mpDiagramViewToolButton, SIGNAL(toggled(bool)), SLOT(showDiagramView(bool)));
      pViewButtonsHorizontalLayout->addWidget(mpDiagramViewToolButton);
      // Only the top level OMSimualtor models or systems or components will have the editor.
      if (mpLibraryTreeItem->isTopLevel() || mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isComponentElement()) {
        connect(mpTextViewToolButton, SIGNAL(toggled(bool)), SLOT(showTextView(bool)));
        pViewButtonsHorizontalLayout->addWidget(mpTextViewToolButton);
        // create an editor
        mpEditor = new OMSimulatorEditor(this);
        mpEditor->getPlainTextEdit()->setReadOnly(true);
        OMSimulatorEditor *pOMSimulatorEditor = dynamic_cast<OMSimulatorEditor*>(mpEditor);
        pOMSimulatorEditor->setPlainText(mpLibraryTreeItem->getClassText(pMainWindow->getLibraryWidget()->getLibraryTreeModel()), false);
        OMSimulatorHighlighter *pOMSimulatorHighlighter = new OMSimulatorHighlighter(OptionsDialog::instance()->getOMSimulatorEditorPage(),
                                                                                     mpEditor->getPlainTextEdit());
        mpEditor->hide(); // set it hidden so that Find/Replace action can get correct value.
        connect(OptionsDialog::instance(), SIGNAL(omsimulatorEditorSettingsChanged()), pOMSimulatorHighlighter, SLOT(settingsChanged()));
      }
      mpUndoStack->setEnabled(false);
      drawOMSModelDiagramElements();
      drawOMSModelConnections();
      mpUndoStack->setEnabled(true);
      mpDiagramGraphicsScene->clearSelection();
      mpModelStatusBar->addPermanentWidget(mpReadOnlyLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpViewTypeLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpModelFilePathLabel, 1);
      mpModelStatusBar->addPermanentWidget(mpFileLockToolButton, 0);
      // set layout
      pMainLayout->addWidget(mpModelStatusBar);
      if (MainWindow::instance()->isDebug()) {
        pMainLayout->addWidget(mpUndoView);
      }
      pMainLayout->addWidget(mpDiagramGraphicsView, 1);
      if (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isComponentElement()) {
        pMainLayout->addWidget(mpIconGraphicsView, 1);
      }
    }
    if (mpEditor) {
      connect(mpEditor->getPlainTextEdit()->document(), SIGNAL(undoAvailable(bool)), SLOT(handleCanUndoChanged(bool)));
      connect(mpEditor->getPlainTextEdit()->document(), SIGNAL(redoAvailable(bool)), SLOT(handleCanRedoChanged(bool)));
      pMainLayout->addWidget(mpEditor, 1);
    }
    mCreateModelWidgetComponents = true;
  }
}

/*!
 * \brief ModelWidget::drawOMSModelElement
 * Draws the OMS model element i.e, system, FMU or table.
 */
ShapeAnnotation* ModelWidget::drawOMSModelElement()
{
  if (mpLibraryTreeItem->getOMSElement()->geometry && mpLibraryTreeItem->getOMSElement()->geometry->iconSource) {
    // Draw bitmap with icon source
    QUrl url(mpLibraryTreeItem->getOMSElement()->geometry->iconSource);
    QFileInfo fileInfo(url.toLocalFile());
    BitmapAnnotation *pBitmapAnnotation = new BitmapAnnotation(fileInfo.absoluteFilePath(), mpIconGraphicsView);
    pBitmapAnnotation->initializeTransformation();
    pBitmapAnnotation->drawCornerItems();
    pBitmapAnnotation->setCornerItemsActiveOrPassive();
    mpIconGraphicsView->addShapeToList(pBitmapAnnotation);
    mpIconGraphicsView->addItem(pBitmapAnnotation);
    return pBitmapAnnotation;
  } else {
    // Rectangle shape as base
    RectangleAnnotation *pRectangleAnnotation = new RectangleAnnotation(mpIconGraphicsView);
    pRectangleAnnotation->initializeTransformation();
    if (mpLibraryTreeItem->isSystemElement()) {
      pRectangleAnnotation->setLineColor(QColor(128, 128, 0));
      pRectangleAnnotation->setFillColor(Qt::white);
    } else if (mpLibraryTreeItem->isFMUComponent()) {
      pRectangleAnnotation->setFillColor(Qt::white);
    } else if (mpLibraryTreeItem->isTableComponent()) {
      pRectangleAnnotation->setLinePattern(StringHandler::LineNone);
      if (mpLibraryTreeItem->getSubModelPath().endsWith(".csv")) {
        pRectangleAnnotation->setFillColor(QColor(0, 148, 21));
      } else {
        pRectangleAnnotation->setFillColor(QColor(3, 75, 220));
      }
    }
    pRectangleAnnotation->drawCornerItems();
    pRectangleAnnotation->setCornerItemsActiveOrPassive();
    mpIconGraphicsView->addShapeToList(pRectangleAnnotation);
    mpIconGraphicsView->addItem(pRectangleAnnotation);
    // Text for name
    TextAnnotation *pTextAnnotation = new TextAnnotation(mpIconGraphicsView);
    pTextAnnotation->initializeTransformation();
    if (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isFMUComponent()) {
      QList<QPointF> extents;
      extents << QPointF(-100, 80) << QPointF(100, 40);
      pTextAnnotation->setExtents(extents);
      if (mpLibraryTreeItem->isSystemElement()) {
        pTextAnnotation->setLineColor(QColor(128, 128, 0));
      }
    } else if (mpLibraryTreeItem->isTableComponent()) {
      pTextAnnotation->setLineColor(Qt::white);
    }
    pTextAnnotation->drawCornerItems();
    pTextAnnotation->setCornerItemsActiveOrPassive();
    mpIconGraphicsView->addShapeToList(pTextAnnotation);
    mpIconGraphicsView->addItem(pTextAnnotation);
    // Text for further information
    if (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isFMUComponent()) {
      TextAnnotation *pInfoTextAnnotation = new TextAnnotation(mpIconGraphicsView);
      pInfoTextAnnotation->initializeTransformation();
      QList<QPointF> extents;
      extents << QPointF(-100, -40) << QPointF(100, -80);
      pInfoTextAnnotation->setExtents(extents);
      if (mpLibraryTreeItem->isSystemElement()) {
        pInfoTextAnnotation->setLineColor(QColor(128, 128, 0));
        pInfoTextAnnotation->setTextString(OMSProxy::getSystemTypeShortString(mpLibraryTreeItem->getSystemType()));
      } else {
        pInfoTextAnnotation->setTextString(QString("%1 %2").arg(OMSProxy::getFMUKindString(mpLibraryTreeItem->getFMUInfo()->fmiKind))
                                           .arg(QString(mpLibraryTreeItem->getFMUInfo()->fmiVersion)));
      }
      pInfoTextAnnotation->drawCornerItems();
      pInfoTextAnnotation->setCornerItemsActiveOrPassive();
      mpIconGraphicsView->addShapeToList(pInfoTextAnnotation);
      mpIconGraphicsView->addItem(pInfoTextAnnotation);
    }
    return pRectangleAnnotation;
  }
}

/*!
 * \brief ModelWidget::getConnectorComponent
 * Finds the Port Component within the Component.
 * \param pConnectorComponent
 * \param connectorName
 * \return
 */
Component* ModelWidget::getConnectorComponent(Component *pConnectorComponent, QString connectorName)
{
  Component *pConnectorComponentFound = 0;
  foreach (Component *pComponent, pConnectorComponent->getComponentsList()) {
    if (pComponent->getName().compare(connectorName) == 0) {
      pConnectorComponentFound = pComponent;
      return pConnectorComponentFound;
    }
    foreach (Component *pInheritedComponent, pComponent->getInheritedComponentsList()) {
      pConnectorComponentFound = getConnectorComponent(pInheritedComponent, connectorName);
      if (pConnectorComponentFound) {
        return pConnectorComponentFound;
      }
    }
  }
  /* if port is not found in components list then look into the inherited components list. */
  foreach (Component *pInheritedComponent, pConnectorComponent->getInheritedComponentsList()) {
    pConnectorComponentFound = getConnectorComponent(pInheritedComponent, connectorName);
    if (pConnectorComponentFound) {
      return pConnectorComponentFound;
    }
  }
  return pConnectorComponentFound;
}

void ModelWidget::clearGraphicsViews()
{
  /* remove everything from the icon view */
  if (mpIconGraphicsView) {
    removeClassComponents(StringHandler::Icon);
    mpIconGraphicsView->removeAllShapes();
    mpIconGraphicsView->removeAllConnections();
    mpIconGraphicsView->removeAllTransitions();
    mpIconGraphicsView->removeAllInitialStates();
    removeInheritedClassShapes(StringHandler::Icon);
    removeInheritedClassComponents(StringHandler::Icon);
    mpIconGraphicsView->scene()->clear();
  }
  /* remove everything from the diagram view */
  if (mpDiagramGraphicsView) {
    removeClassComponents(StringHandler::Diagram);
    mpDiagramGraphicsView->removeAllShapes();
    mpDiagramGraphicsView->removeAllConnections();
    mpDiagramGraphicsView->removeAllTransitions();
    mpDiagramGraphicsView->removeAllInitialStates();
    removeInheritedClassShapes(StringHandler::Diagram);
    removeInheritedClassComponents(StringHandler::Diagram);
    removeInheritedClassConnections();
    mpDiagramGraphicsView->scene()->clear();
  }
}

/*!
 * \brief ModelWidget::reDrawModelWidget
 * Redraws the ModelWidget.
 */
void ModelWidget::reDrawModelWidget()
{
  QApplication::setOverrideCursor(Qt::WaitCursor);
  clearGraphicsViews();
  /* get model components, connection and shapes. */
  if (getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    // read new CompositeModel name
    QString compositeModelName = getCompositeModelName();
    mpLibraryTreeItem->setName(compositeModelName);
    MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->updateLibraryTreeItem(mpLibraryTreeItem);
    setWindowTitle(compositeModelName);
    // get the submodels and connections
    getCompositeModelSubModels();
    getCompositeModelConnections();
    // clear the undo stack
    mpUndoStack->clear();
//    if (mpEditor) {
//      mpEditor->getPlainTextEdit()->document()->clearUndoRedoStacks();
//    }
  } else if (getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->updateLibraryTreeItem(mpLibraryTreeItem);
    // get the submodels and connections
    drawOMSModelIconElements();
    drawOMSModelDiagramElements();
    drawOMSModelConnections();
    // clear the undo stack
    mpUndoStack->clear();
//    if (mpEditor) {
//      mpEditor->getPlainTextEdit()->document()->clearUndoRedoStacks();
//    }
  } else {
    // Draw icon view
    mExtendsModifiersLoaded = false;
    // remove saved inherited classes
    clearInheritedClasses();
    // get inherited classes
    getModelInheritedClasses();
    // Draw Icon shapes and inherited shapes
    drawModelInheritedClassShapes(this, StringHandler::Icon);
    getModelIconDiagramShapes(StringHandler::Icon);
    // clear the components and their annotations
    mComponentsList.clear();
    mComponentsAnnotationsList.clear();
    mComponentsLoaded = false;
    // get the model components
    loadComponents();
    // invalidate the simulation options
    mpLibraryTreeItem->mSimulationOptions.setIsValid(false);
    // update the icon
    mpLibraryTreeItem->handleIconUpdated();
    // Draw diagram view
    if (mDiagramViewLoaded) {
      // reset flags
      mDiagramViewLoaded = false;
      loadDiagramView();
      mConnectionsLoaded = false;
      loadConnections();
    }
    // if documentation view is visible then update it
    if (MainWindow::instance()->getDocumentationDockWidget()->isVisible()) {
      MainWindow::instance()->getDocumentationWidget()->showDocumentation(getLibraryTreeItem());
    }
    // clear the undo stack
    mpUndoStack->clear();
//    if (mpEditor) {
//      mpEditor->getPlainTextEdit()->document()->clearUndoRedoStacks();
//    }
    updateViewButtonsBasedOnAccess();
    // announce the change.
    mpLibraryTreeItem->emitLoaded();
  }
  QApplication::restoreOverrideCursor();
}

/*!
 * \brief ModelWidget::validateText
 * Validates the text of the editor.
 * \param pLibraryTreeItem
 * \return Returns true if validation is successful otherwise return false.
 */
bool ModelWidget::validateText(LibraryTreeItem **pLibraryTreeItem)
{
  if (ModelicaEditor *pModelicaEditor = dynamic_cast<ModelicaEditor*>(mpEditor)) {
    return pModelicaEditor->validateText(pLibraryTreeItem);
  } else if (CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpEditor)) {
    return pCompositeModelEditor->validateText();
  } else if (OMSimulatorEditor *pOMSimulatorEditor = dynamic_cast<OMSimulatorEditor*>(mpEditor)) {
    return pOMSimulatorEditor->validateText();
  } else {
    return true;
  }
}

/*!
 * \brief ModelWidget::modelicaEditorTextChanged
 * Called when Modelica text has been changed by user manually.\n
 * Updates the LibraryTreeItem and ModelWidget with new changes.
 * \param pLibraryTreeItem
 * \return
 * \sa ModelicaEditor::getClassNames()
 */
bool ModelWidget::modelicaEditorTextChanged(LibraryTreeItem **pLibraryTreeItem)
{
  QString errorString;
  ModelicaEditor *pModelicaEditor = dynamic_cast<ModelicaEditor*>(mpEditor);
  QStringList classNames = pModelicaEditor->getClassNames(&errorString);
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QString modelicaText = pModelicaEditor->getPlainText();
  QString stringToLoad;
  LibraryTreeItem *pParentLibraryTreeItem = pLibraryTreeModel->getContainingFileParentLibraryTreeItem(mpLibraryTreeItem);
  removeDynamicResults(); // show static values during editing
  if (pParentLibraryTreeItem != mpLibraryTreeItem) {
    stringToLoad = mpLibraryTreeItem->getClassTextBefore() + StringHandler::trimmedEnd(modelicaText) + "\n" + mpLibraryTreeItem->getClassTextAfter();
  } else {
    stringToLoad = modelicaText;
  }
  if (classNames.size() == 0) {
    /* if the error is occured in P.M and package is saved in one file.
     * then update the package contents with new invalid code because we open P when user clicks on the error message.
     */
    if (mpLibraryTreeItem->isInPackageOneFile()) {
      if (!pParentLibraryTreeItem->getModelWidget()) {
        pLibraryTreeModel->showModelWidget(pParentLibraryTreeItem, false);
      }
      pParentLibraryTreeItem->getModelWidget()->createModelWidgetComponents();
      pParentLibraryTreeItem->setClassText(stringToLoad);
    }
    if (!errorString.isEmpty()) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, errorString, Helper::syntaxKind,
                                                            Helper::errorLevel));
    }
    return false;
  }
  /* if no errors are found with the Modelica Text then load it in OMC */
  QString className = classNames.at(0);
  if (pParentLibraryTreeItem != mpLibraryTreeItem) {
    // only use OMCProxy::loadString merge when LibraryTreeItem::SaveFolderStructure i.e., package.mo
    if (!pOMCProxy->loadString(stringToLoad, pParentLibraryTreeItem->getFileName(), Helper::utf8, pParentLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveFolderStructure)) {
      return false;
    }
  } else {
    // only use OMCProxy::loadString merge when LibraryTreeItem::SaveFolderStructure i.e., package.mo
    if (!pOMCProxy->loadString(stringToLoad, mpLibraryTreeItem->getFileName(), Helper::utf8, mpLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveFolderStructure)) {
      return false;
    }
  }
  /* if user has changed the class contents then refresh it. */
  if (className.compare(mpLibraryTreeItem->getNameStructure()) == 0) {
    mpLibraryTreeItem->setClassInformation(pOMCProxy->getClassInformation(mpLibraryTreeItem->getNameStructure()));
    reDrawModelWidget();
    mpLibraryTreeItem->setClassText(modelicaText);
    if (mpLibraryTreeItem->isInPackageOneFile()) {
      pParentLibraryTreeItem->setClassText(stringToLoad);
      updateModelText();
    }
    // update child classes
    updateChildClasses(mpLibraryTreeItem);
  } else {
    /* if user has changed the class name then delete this class.
     * Update the LibraryTreeItem with new class name and then refresh it.
     */
    int row = mpLibraryTreeItem->row();
    /* if a class inside a package one file is renamed then it is already deleted by calling loadString using the whole package contents
     * so we tell unloadLibraryTreeItem to don't try deleteClass since it will only produce error
     */
    pLibraryTreeModel->unloadLibraryTreeItem(mpLibraryTreeItem, !mpLibraryTreeItem->isInPackageOneFile());
    mpLibraryTreeItem->setModelWidget(0);
    QString name = StringHandler::getLastWordAfterDot(className);
    LibraryTreeItem *pNewLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(name, mpLibraryTreeItem->parent(), false, false, true, row);
    setWindowTitle(pNewLibraryTreeItem->getName() + (pNewLibraryTreeItem->isSaved() ? "" : "*"));
    setModelClassPathLabel(pNewLibraryTreeItem->getNameStructure());
    pNewLibraryTreeItem->setSaveContentsType(mpLibraryTreeItem->getSaveContentsType());
    pLibraryTreeModel->checkIfAnyNonExistingClassLoaded();
    // make the new created LibraryTreeItem selected
    QModelIndex modelIndex = pLibraryTreeModel->libraryTreeItemIndex(pNewLibraryTreeItem);
    LibraryTreeProxyModel *pLibraryTreeProxyModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeProxyModel();
    QModelIndex proxyIndex = pLibraryTreeProxyModel->mapFromSource(modelIndex);
    LibraryTreeView *pLibraryTreeView = MainWindow::instance()->getLibraryWidget()->getLibraryTreeView();
    pLibraryTreeView->selectionModel()->clearSelection();
    pLibraryTreeView->selectionModel()->select(proxyIndex, QItemSelectionModel::Select);
    // update class text
    pNewLibraryTreeItem->setModelWidget(this);
    pNewLibraryTreeItem->setClassText(modelicaText);
    setLibraryTreeItem(pNewLibraryTreeItem);
    setModelFilePathLabel(pNewLibraryTreeItem->getFileName());
    reDrawModelWidget();
    if (pNewLibraryTreeItem->isInPackageOneFile()) {
      pNewLibraryTreeItem->setClassText(stringToLoad);
      updateModelText();
    }
    *pLibraryTreeItem = pNewLibraryTreeItem;
  }
  return true;
}

void ModelWidget::updateChildClasses(LibraryTreeItem *pLibraryTreeItem)
{
  MainWindow *pMainWindow = MainWindow::instance();
  LibraryTreeModel *pLibraryTreeModel = pMainWindow->getLibraryWidget()->getLibraryTreeModel();
  QStringList classNames = pMainWindow->getOMCProxy()->getClassNames(pLibraryTreeItem->getNameStructure());
  // first remove the classes that are removed by the user
  int i = 0;
  while(i != pLibraryTreeItem->childrenSize()) {
    LibraryTreeItem *pChildLibraryTreeItem = pLibraryTreeItem->child(i);
    if (!classNames.contains(pChildLibraryTreeItem->getName())) {
      pLibraryTreeModel->removeLibraryTreeItem(pChildLibraryTreeItem, LibraryTreeItem::Modelica);
      i = 0;  //Restart iteration if list has changed
    } else {
      i++;
    }
  }
  // update and create any new classes
  int index = 0;
  foreach (QString className, classNames) {
    QString classNameStructure = QString("%1.%2").arg(pLibraryTreeItem->getNameStructure()).arg(className);
    LibraryTreeItem *pChildLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(classNameStructure);
    // if the class already exists then we update it if needed.
    if (pChildLibraryTreeItem) {
      if (pChildLibraryTreeItem->isInPackageOneFile()) {
        // update the class information
        pChildLibraryTreeItem->setClassInformation(pMainWindow->getOMCProxy()->getClassInformation(pChildLibraryTreeItem->getNameStructure()));
        if (pLibraryTreeItem->isExpanded()) {
          if (pChildLibraryTreeItem->getModelWidget()) {
            pChildLibraryTreeItem->getModelWidget()->reDrawModelWidget();
            pLibraryTreeModel->readLibraryTreeItemClassText(pChildLibraryTreeItem);
          }
          updateChildClasses(pChildLibraryTreeItem);
        }
      }
    } else if (!pChildLibraryTreeItem) {  // if the class doesn't exists then create one.
      pLibraryTreeModel->createLibraryTreeItem(className, pLibraryTreeItem, false, false, true, index);
      pLibraryTreeModel->checkIfAnyNonExistingClassLoaded();
    }
    index++;
  }
}

/*!
 * \brief ModelWidget::omsimulatorEditorTextChanged
 * Called when OMSimulatorEditor text has been changed by user manually.\n
 * Updates the LibraryTreeItem and ModelWidget with new changes.
 * \return
 */
bool ModelWidget::omsimulatorEditorTextChanged()
{
  OMSimulatorEditor *pOMSimulatorEditor = dynamic_cast<OMSimulatorEditor*>(mpEditor);
  QFileInfo fileInfo(mpLibraryTreeItem->getFileName());
  if (fileInfo.exists()) {
    OMSProxy::instance()->setWorkingDirectory(fileInfo.absoluteDir().absolutePath());
  }
  QString modelName;
  bool success = false;
  if (OMSProxy::instance()->parseString(pOMSimulatorEditor->getPlainTextEdit()->toPlainText(), &modelName)) {
    if (mpLibraryTreeItem->getNameStructure().compare(modelName) != 0
        && MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItemOneLevel(modelName)) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                            GUIMessages::getMessage(GUIMessages::MODEL_ALREADY_EXISTS)
                                                            .arg("Composite model").arg(modelName).arg("scope"),
                                                            Helper::scriptingKind, Helper::errorLevel));
      return false;
    }
    success = OMSProxy::instance()->loadString(pOMSimulatorEditor->getPlainTextEdit()->toPlainText(), &modelName);
  }
  if (fileInfo.exists()) {
    OMSProxy::instance()->setWorkingDirectory(OptionsDialog::instance()->getOMSimulatorPage()->getWorkingDirectory());
  }
  if (success) {
    // model name has changed
    if (mpLibraryTreeItem->getNameStructure().compare(modelName) != 0) {
      // unload the old model from OMSimulator
      OMSProxy::instance()->omsDelete(mpLibraryTreeItem->getNameStructure());
      // Update to the new name
      mpLibraryTreeItem->setName(modelName);
      mpLibraryTreeItem->setNameStructure(modelName);
      setWindowTitle(mpLibraryTreeItem->getName() + (mpLibraryTreeItem->isSaved() ? "" : "*"));
      setModelClassPathLabel(mpLibraryTreeItem->getNameStructure());
    }
    // Update the OMS element
    oms_element_t *pOMSElement = 0;
    OMSProxy::instance()->getElement(mpLibraryTreeItem->getNameStructure(), &pOMSElement);
    mpLibraryTreeItem->setOMSElement(pOMSElement);
    // remove the children
    int i = 0;
    while (i < mpLibraryTreeItem->childrenSize()) {
      MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->removeLibraryTreeItem(mpLibraryTreeItem->child(i), LibraryTreeItem::OMS);
      i = 0;  //Restart iteration
    }
    // create the children
    QModelIndex modelIndex = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->libraryTreeItemIndex(mpLibraryTreeItem);
    QModelIndex proxyIndex = MainWindow::instance()->getLibraryWidget()->getLibraryTreeProxyModel()->mapFromSource(modelIndex);
    MainWindow::instance()->getLibraryWidget()->getLibraryTreeView()->collapse(proxyIndex);
    mpLibraryTreeItem->setExpanded(false);
    MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->createLibraryTreeItems(mpLibraryTreeItem);
    reDrawModelWidget();
    mpLibraryTreeItem->setClassText(pOMSimulatorEditor->getPlainTextEdit()->toPlainText());
    return true;
  } else {
    return false;
  }
}

/*!
 * \brief ModelWidget::clearSelection
 * Clears the selection Icon and Diagram layers.
 */
void ModelWidget::clearSelection()
{
  if (mpIconGraphicsView) {
    mpIconGraphicsView->clearSelection();
  }
  if (mpDiagramGraphicsView) {
    mpDiagramGraphicsView->clearSelection();
  }
}

/*!
 * \brief ModelWidget::updateClassAnnotationIfNeeded
 * Updates the class annotation for both icon and diagram views if needed.
 */
void ModelWidget::updateClassAnnotationIfNeeded()
{
  if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
    if (mpIconGraphicsView && mpIconGraphicsView->isAddClassAnnotationNeeded()) {
      mpIconGraphicsView->addClassAnnotation();
      mpIconGraphicsView->setAddClassAnnotationNeeded(false);
    }
    if (mpDiagramGraphicsView && mpDiagramGraphicsView->isAddClassAnnotationNeeded()) {
      mpDiagramGraphicsView->addClassAnnotation();
      mpDiagramGraphicsView->setAddClassAnnotationNeeded(false);
    }
  }
}

/*!
 * \brief ModelWidget::updateModelText
 * Updates the Text of the class.
 */
void ModelWidget::updateModelText()
{
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  // Don't allow updating the child LibraryTreeItems of OMS model
  if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::OMS && !mpLibraryTreeItem->isTopLevel()) {
    if (mpLibraryTreeItem->parent()->getModelWidget()) {
      mpLibraryTreeItem->parent()->getModelWidget()->updateModelText();
    } else {
      pLibraryTreeModel->updateLibraryTreeItemClassText(mpLibraryTreeItem->parent());
    }
    // set the library node not saved.
    mpLibraryTreeItem->setIsSaved(false);
    pLibraryTreeModel->updateLibraryTreeItem(mpLibraryTreeItem);
    if (mpLibraryTreeItem->isComponentElement()) {
      pLibraryTreeModel->updateOMSChildLibraryTreeItemClassText(mpLibraryTreeItem->parent());
    } else {
      pLibraryTreeModel->updateOMSChildLibraryTreeItemClassText(mpLibraryTreeItem);
    }
    return;
  }
  setWindowTitle(QString(mpLibraryTreeItem->getName()).append("*"));
  pLibraryTreeModel->updateLibraryTreeItemClassText(mpLibraryTreeItem);
#if !defined(WITHOUT_OSG)
  // update the ThreeDViewer Browser
  if (mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::CompositeModel) {
    MainWindow::instance()->getModelWidgetContainer()->updateThreeDViewer(this);
  }
#endif
}

/*!
 * \brief ModelWidget::updateModelicaTextManually
 * Updates the Parent Modelica class text after user has made changes manually in the text view.
 * \param contents
 */
void ModelWidget::updateModelicaTextManually(QString contents)
{
  setWindowTitle(QString(mpLibraryTreeItem->getName()).append("*"));
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  pLibraryTreeModel->updateLibraryTreeItemClassTextManually(mpLibraryTreeItem, contents);
}

/*!
 * \brief ModelWidget::updateUndoRedoActions
 * Enables/disables the Undo/Redo actions based on the stack situation.
 */
void ModelWidget::updateUndoRedoActions()
{
  if (mpIconGraphicsView && mpIconGraphicsView->isVisible()) {
    MainWindow::instance()->getUndoAction()->setEnabled(mpUndoStack->canUndo());
    MainWindow::instance()->getRedoAction()->setEnabled(mpUndoStack->canRedo());
  } else if (mpDiagramGraphicsView && mpDiagramGraphicsView->isVisible()) {
    MainWindow::instance()->getUndoAction()->setEnabled(mpUndoStack->canUndo());
    MainWindow::instance()->getRedoAction()->setEnabled(mpUndoStack->canRedo());
  } else if (mpEditor && mpEditor->isVisible()) {
    MainWindow::instance()->getUndoAction()->setEnabled(mpEditor->getPlainTextEdit()->document()->isUndoAvailable());
    MainWindow::instance()->getRedoAction()->setEnabled(mpEditor->getPlainTextEdit()->document()->isRedoAvailable());
  } else {
    MainWindow::instance()->getUndoAction()->setEnabled(false);
    MainWindow::instance()->getRedoAction()->setEnabled(false);
  }
}

/*!
 * \brief ModelWidget::updateDynamicResults
 * Update the model widget with values from resultFile.
 * Skip update for empty resultFileName -- use removeDynamicResults.
 */
void ModelWidget::updateDynamicResults(QString resultFileName)
{
  mResultFileName = resultFileName;
  if (!resultFileName.isEmpty()) {
    foreach (Component *component, mpDiagramGraphicsView->getInheritedComponentsList()) {
      component->componentParameterHasChanged();
    }
    foreach (Component *component, mpDiagramGraphicsView->getComponentsList()) {
      component->componentParameterHasChanged();
    }
  }
}

/*!
 * \brief ModelWidget::writeCoSimulationResultFile
 * Writes the co-simulation csv result file for 3d viewer.
 * \param fileName
 */
bool ModelWidget::writeCoSimulationResultFile(QString fileName)
{
  // this function is only for meta-models
  if (mpLibraryTreeItem->getLibraryType() != LibraryTreeItem::CompositeModel) {
    return false;
  }
  // first remove the result file.
  if (QFile::exists(fileName)) {
    if (!QFile::remove(fileName)) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                            GUIMessages::getMessage(GUIMessages::UNABLE_TO_DELETE_FILE).arg(fileName),
                                                            Helper::scriptingKind, Helper::errorLevel));
    }
  }
  // write the result file.
  QFile file(fileName);
  if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
    QTextStream resultFile(&file);
    // set to UTF-8
    resultFile.setCodec(Helper::utf8.toStdString().data());
    resultFile.setGenerateByteOrderMark(false);
    // write result file header
    resultFile << "\"" << "time\",";
    int nActiveInterfaces = 0;
    foreach (Component *pSubModelComponent, mpDiagramGraphicsView->getComponentsList()) {
      foreach (Component *pInterfaceComponent, pSubModelComponent->getComponentsList()) {
        QString name = QString("%1.%2").arg(pSubModelComponent->getName()).arg(pInterfaceComponent->getName());
        /*!
         * \note Don't check for connection.
         * If we check for connection then only connected submodels can be seen in the ThreeDViewer Browser.
         */
        //        foreach (LineAnnotation *pConnectionLineAnnotation, mpDiagramGraphicsView->getConnectionsList()) {
        //          if ((pConnectionLineAnnotation->getStartComponentName().compare(name) == 0) ||
        //              (pConnectionLineAnnotation->getEndComponentName().compare(name) == 0)) {
        // Comma between interfaces
        if (nActiveInterfaces > 0) {
          resultFile << ",";
        }
        resultFile << "\"" << name << ".R[cG][cG](1) [m]\",\"" << name << ".R[cG][cG](2) [m]\",\"" << name << ".R[cG][cG](3) [m]\","; // Position vector
        resultFile << "\"" << name << ".A(1,1) [-]\",\"" << name << ".A(1,2) [-]\",\"" << name << ".A(1,3) [-]\",\""
                   << name << ".A(2,1) [-]\",\"" << name << ".A(2,2) [-]\",\"" << name << ".A(2,3) [-]\",\""
                   << name << ".A(3,1) [-]\",\"" << name << ".A(3,2) [-]\",\"" << name << ".A(3,3) [-]\""; // Transformation matrix
        nActiveInterfaces++;
        //          }
        //        }
      }
    }
    // write just single data for result file
    resultFile << "\n" << "0,";
    nActiveInterfaces = 0;
    foreach (Component *pSubModelComponent, mpDiagramGraphicsView->getComponentsList()) {
      foreach (Component *pInterfaceComponent, pSubModelComponent->getComponentsList()) {
        /*!
         * \note Don't check for connection.
         * If we check for connection then only connected submodels can be seen in the ThreeDViewer Browser.
         */
        //        QString name = QString("%1.%2").arg(pSubModelComponent->getName()).arg(pInterfaceComponent->getName());
        //        foreach (LineAnnotation *pConnectionLineAnnotation, mpDiagramGraphicsView->getConnectionsList()) {
        //          if ((pConnectionLineAnnotation->getStartComponentName().compare(name) == 0) ||
        //              (pConnectionLineAnnotation->getEndComponentName().compare(name) == 0)) {
        // Comma between interfaces
        if (nActiveInterfaces > 0) {
          resultFile << ",";
        }

        // get the submodel position
        double values[] = {0.0, 0.0, 0.0};
        QGenericMatrix<3, 1, double> cX_R_cG_cG(values);
        QStringList subModelPositionList = pSubModelComponent->getComponentInfo()->getPosition().split(",", QString::SkipEmptyParts);
        if (subModelPositionList.size() > 2) {
          cX_R_cG_cG(0, 0) = subModelPositionList.at(0).toDouble();
          cX_R_cG_cG(0, 1) = subModelPositionList.at(1).toDouble();
          cX_R_cG_cG(0, 2) = subModelPositionList.at(2).toDouble();
        }
        // get the submodel angle
        double subModelPhi[3] = {0.0, 0.0, 0.0};
        QStringList subModelAngleList = pSubModelComponent->getComponentInfo()->getAngle321().split(",", QString::SkipEmptyParts);
        if (subModelAngleList.size() > 2) {
          subModelPhi[0] = subModelAngleList.at(0).toDouble();
          subModelPhi[1] = subModelAngleList.at(1).toDouble();
          subModelPhi[2] = subModelAngleList.at(2).toDouble();
        }
        QGenericMatrix<3, 3, double> cX_A_cG = Utilities::getRotationMatrix(QGenericMatrix<3, 1, double>(subModelPhi));
        // get the interface position
        QGenericMatrix<3, 1, double> ci_R_cX_cX(values);
        QStringList interfacePositionList = pInterfaceComponent->getComponentInfo()->getPosition().split(",", QString::SkipEmptyParts);
        if (interfacePositionList.size() > 2) {
          ci_R_cX_cX(0, 0) = interfacePositionList.at(0).toDouble();
          ci_R_cX_cX(0, 1) = interfacePositionList.at(1).toDouble();
          ci_R_cX_cX(0, 2) = interfacePositionList.at(2).toDouble();
        }
        // get the interface angle
        double interfacePhi[3] = {0.0, 0.0, 0.0};
        QStringList interfaceAngleList = pInterfaceComponent->getComponentInfo()->getAngle321().split(",", QString::SkipEmptyParts);
        if (interfaceAngleList.size() > 2) {
          interfacePhi[0] = interfaceAngleList.at(0).toDouble();
          interfacePhi[1] = interfaceAngleList.at(1).toDouble();
          interfacePhi[2] = interfaceAngleList.at(2).toDouble();
        }
        QGenericMatrix<3, 3, double> ci_A_cX = Utilities::getRotationMatrix(QGenericMatrix<3, 1, double>(interfacePhi));

        QGenericMatrix<3, 1, double> ci_R_cG_cG = cX_R_cG_cG + ci_R_cX_cX*cX_A_cG;
        QGenericMatrix<3, 3, double> ci_A_cG =  ci_A_cX*cX_A_cG;

        // write data
        resultFile << ci_R_cG_cG(0, 0) << "," << ci_R_cG_cG(0, 1) << "," << ci_R_cG_cG(0, 2) << ","; // Position vector
        resultFile << ci_A_cG(0, 0) << "," << ci_A_cG(0, 1) << "," << ci_A_cG(0, 2) << ","
                   << ci_A_cG(1, 0) << "," << ci_A_cG(1, 1) << "," << ci_A_cG(1, 2) << ","
                   << ci_A_cG(2, 0) << "," << ci_A_cG(2, 1) << "," << ci_A_cG(2, 2); // Transformation matrix
        nActiveInterfaces++;
        //          }
        //        }
      }
    }
    file.close();
    return true;
  } else {
    QString msg = GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).arg(GUIMessages::getMessage(GUIMessages::UNABLE_TO_SAVE_FILE)
                                                                           .arg(fileName).arg(file.errorString()));
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                          Helper::errorLevel));
    return false;
  }
}

/*!
 * \brief ModelWidget::writeVisualXMLFile
 * Writes the visual xml file for 3d visualization.
 * \param fileName
 * \param canWriteVisualXMLFile
 * \return
 */
bool ModelWidget::writeVisualXMLFile(QString fileName, bool canWriteVisualXMLFile)
{
  // this function is only for meta-models
  if (mpLibraryTreeItem->getLibraryType() != LibraryTreeItem::CompositeModel) {
    return false;
  }
  // first remove the visual xml file.
  if (QFile::exists(fileName)) {
    if (!QFile::remove(fileName)) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                            GUIMessages::getMessage(GUIMessages::UNABLE_TO_DELETE_FILE).arg(fileName),
                                                            Helper::scriptingKind, Helper::errorLevel));
    }
  }
  // can we write visual xml file.
  if (!canWriteVisualXMLFile) {
    foreach (Component *pSubModelComponent, mpDiagramGraphicsView->getComponentsList()) {
      if (!pSubModelComponent->getComponentInfo()->getGeometryFile().isEmpty()) {
        canWriteVisualXMLFile = true;
      }
    }
    if (!canWriteVisualXMLFile) {
      return false;
    }
  }
  // write the visual xml file.
  QFile file(fileName);
  if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
    QTextStream visualFile(&file);
    // set to UTF-8
    visualFile.setCodec(Helper::utf8.toStdString().data());
    visualFile.setGenerateByteOrderMark(false);

    visualFile << "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n";
    visualFile << "<visualization>\n";
    visualFile << "  <shape>\n";
    visualFile << "    <ident>x-axis</ident>\n";
    visualFile << "    <type>cylinder</type>\n";
    visualFile << "    <T>\n";
    visualFile << "      <exp>1.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>1.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>1.0</exp>\n";
    visualFile << "    </T>\n";
    visualFile << "    <r>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "    </r>\n";
    visualFile << "    <r_shape>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "    </r_shape>\n";
    visualFile << "    <lengthDir>\n";
    visualFile << "      <exp>1.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "    </lengthDir>\n";
    visualFile << "    <widthDir>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>1.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "    </widthDir>\n";
    visualFile << "    <length><exp>1.0</exp></length>\n";
    visualFile << "    <width><exp>0.0025</exp></width>\n";
    visualFile << "    <height><exp>0.0025</exp></height>\n";
    visualFile << "    <extra><exp>0.0</exp></extra>\n";
    visualFile << "    <color>\n";
    visualFile << "      <exp>255.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "    </color>\n";
    visualFile << "    <specCoeff><exp>0.7</exp></specCoeff>\n";
    visualFile << "  </shape>\n";

    visualFile << "  <shape>\n";
    visualFile << "    <ident>y-axis</ident>\n";
    visualFile << "    <type>cylinder</type>\n";
    visualFile << "    <T>\n";
    visualFile << "      <exp>1.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>1.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>1.0</exp>\n";
    visualFile << "    </T>\n";
    visualFile << "    <r>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "    </r>\n";
    visualFile << "    <r_shape>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "    </r_shape>\n";
    visualFile << "    <lengthDir>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>1.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "    </lengthDir>\n";
    visualFile << "    <widthDir>\n";
    visualFile << "      <exp>1.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "    </widthDir>\n";
    visualFile << "    <length><exp>1.0</exp></length>\n";
    visualFile << "    <width><exp>0.0025</exp></width>\n";
    visualFile << "    <height><exp>0.0025</exp></height>\n";
    visualFile << "    <extra><exp>0.0</exp></extra>\n";
    visualFile << "    <color>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>255.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "    </color>\n";
    visualFile << "    <specCoeff><exp>0.7</exp></specCoeff>\n";
    visualFile << "  </shape>\n";

    visualFile << "  <shape>\n";
    visualFile << "    <ident>z-axis</ident>\n";
    visualFile << "    <type>cylinder</type>\n";
    visualFile << "    <T>\n";
    visualFile << "      <exp>1.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>1.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>1.0</exp>\n";
    visualFile << "    </T>\n";
    visualFile << "    <r>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "    </r>\n";
    visualFile << "    <r_shape>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "    </r_shape>\n";
    visualFile << "    <lengthDir>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>1.0</exp>\n";
    visualFile << "    </lengthDir>\n";
    visualFile << "    <widthDir>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>1.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "    </widthDir>\n";
    visualFile << "    <length><exp>1.0</exp></length>\n";
    visualFile << "    <width><exp>0.0025</exp></width>\n";
    visualFile << "    <height><exp>0.0025</exp></height>\n";
    visualFile << "    <extra><exp>0.0</exp></extra>\n";
    visualFile << "    <color>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>0.0</exp>\n";
    visualFile << "      <exp>255.0</exp>\n";
    visualFile << "    </color>\n";
    visualFile << "    <specCoeff><exp>0.7</exp></specCoeff>\n";
    visualFile << "  </shape>\n";

    QList<QColor> colorsList;
    colorsList.append(QColor(Qt::red));
    colorsList.append(QColor(85,170,0)); // green
    colorsList.append(QColor(Qt::blue));
    colorsList.append(QColor(Qt::lightGray));
    colorsList.append(QColor(Qt::magenta));
    colorsList.append(QColor(Qt::yellow));
    colorsList.append(QColor(Qt::darkRed));
    colorsList.append(QColor(Qt::darkBlue));
    colorsList.append(QColor(Qt::darkGreen));
    colorsList.append(QColor(Qt::darkCyan));
    colorsList.append(QColor(Qt::darkMagenta));
    colorsList.append(QColor(Qt::darkYellow));
    // selected color
    QColor selectedColor(255, 192, 203); // pink
    int i = 0;

    foreach (Component *pSubModelComponent, mpDiagramGraphicsView->getComponentsList()) {
      // if no geometry file then continue.
      if (pSubModelComponent->getComponentInfo()->getGeometryFile().isEmpty()) {
        continue;
      }
      bool visited = false;
      foreach (Component *pInterfaceComponent, pSubModelComponent->getComponentsList()) {
        QString name = QString("%1.%2").arg(pSubModelComponent->getName()).arg(pInterfaceComponent->getName());




        //Draw interface vectors
        bool interfaceSelected=false;
        foreach(LineAnnotation* pConnection, pInterfaceComponent->getGraphicsView()->getConnectionsList()) {
          if(pConnection->isSelected()) {
            if(pConnection->getStartComponent() == pInterfaceComponent ||
             pConnection->getEndComponent() == pInterfaceComponent) {
              interfaceSelected = true;
            }
          }
        }

        //Draw X-axis
        visualFile << "  <shape>\n";
        visualFile << "    <ident>" << name << ".x</ident>\n";
        visualFile << "    <type>cylinder</type>\n";
        visualFile << "    <T>\n";
        visualFile << "      <cref>" << name << ".A(1,1) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(1,2) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(1,3) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(2,1) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(2,2) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(2,3) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(3,1) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(3,2) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(3,3) [-]</cref>\n";
        visualFile << "    </T>\n";
        visualFile << "    <r>\n";
        visualFile << "      <cref>" << name << ".R[cG][cG](1) [m]</cref>\n";
        visualFile << "      <cref>" << name << ".R[cG][cG](2) [m]</cref>\n";
        visualFile << "      <cref>" << name << ".R[cG][cG](3) [m]</cref>\n";
        visualFile << "    </r>\n";
        visualFile << "    <r_shape>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "    </r_shape>\n";
        visualFile << "    <lengthDir>\n";
        visualFile << "      <exp>1</exp>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "    </lengthDir>\n";
        visualFile << "    <widthDir>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "      <exp>1</exp>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "    </widthDir>\n";
        visualFile << "    <length><exp>0.5</exp></length>\n";
        visualFile << "    <width><exp>0.0025</exp></width>\n";
        visualFile << "    <height><exp>0.0025</exp></height>\n";
        visualFile << "    <extra><exp>0.0</exp></extra>\n";
        visualFile << "    <color>\n";
        if(interfaceSelected) {
          visualFile << "      <exp>" << selectedColor.red() << "</exp>\n";
          visualFile << "      <exp>" << selectedColor.green() << "</exp>\n";
          visualFile << "      <exp>" << selectedColor.blue() << "</exp>\n";
        } else {
          visualFile << "      <exp>255</exp>\n";
          visualFile << "      <exp>0</exp>\n";
          visualFile << "      <exp>0</exp>\n";
        }
        visualFile << "    </color>\n";
        visualFile << "    <specCoeff><exp>0.7</exp></specCoeff>\n";
        visualFile << "  </shape>\n";

        //Draw Y-axis
        visualFile << "  <shape>\n";
        visualFile << "    <ident>" << name << ".x</ident>\n";
        visualFile << "    <type>cylinder</type>\n";
        visualFile << "    <T>\n";
        visualFile << "      <cref>" << name << ".A(1,1) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(1,2) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(1,3) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(2,1) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(2,2) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(2,3) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(3,1) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(3,2) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(3,3) [-]</cref>\n";
        visualFile << "    </T>\n";
        visualFile << "    <r>\n";
        visualFile << "      <cref>" << name << ".R[cG][cG](1) [m]</cref>\n";
        visualFile << "      <cref>" << name << ".R[cG][cG](2) [m]</cref>\n";
        visualFile << "      <cref>" << name << ".R[cG][cG](3) [m]</cref>\n";
        visualFile << "    </r>\n";
        visualFile << "    <r_shape>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "    </r_shape>\n";
        visualFile << "    <lengthDir>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "      <exp>1</exp>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "    </lengthDir>\n";
        visualFile << "    <widthDir>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "      <exp>1</exp>\n";
        visualFile << "    </widthDir>\n";
        visualFile << "    <length><exp>0.5</exp></length>\n";
        visualFile << "    <width><exp>0.0025</exp></width>\n";
        visualFile << "    <height><exp>0.0025</exp></height>\n";
        visualFile << "    <extra><exp>0.0</exp></extra>\n";
        visualFile << "    <color>\n";
        if(interfaceSelected) {
          visualFile << "      <exp>" << selectedColor.red() << "</exp>\n";
          visualFile << "      <exp>" << selectedColor.green() << "</exp>\n";
          visualFile << "      <exp>" << selectedColor.blue() << "</exp>\n";
        } else {
          visualFile << "      <exp>0</exp>\n";
          visualFile << "      <exp>255</exp>\n";
          visualFile << "      <exp>0</exp>\n";
        }
        visualFile << "    </color>\n";
        visualFile << "    <specCoeff><exp>0.7</exp></specCoeff>\n";
        visualFile << "  </shape>\n";

        //Draw Z-axis
        visualFile << "  <shape>\n";
        visualFile << "    <ident>" << name << ".x</ident>\n";
        visualFile << "    <type>cylinder</type>\n";
        visualFile << "    <T>\n";
        visualFile << "      <cref>" << name << ".A(1,1) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(1,2) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(1,3) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(2,1) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(2,2) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(2,3) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(3,1) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(3,2) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(3,3) [-]</cref>\n";
        visualFile << "    </T>\n";
        visualFile << "    <r>\n";
        visualFile << "      <cref>" << name << ".R[cG][cG](1) [m]</cref>\n";
        visualFile << "      <cref>" << name << ".R[cG][cG](2) [m]</cref>\n";
        visualFile << "      <cref>" << name << ".R[cG][cG](3) [m]</cref>\n";
        visualFile << "    </r>\n";
        visualFile << "    <r_shape>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "    </r_shape>\n";
        visualFile << "    <lengthDir>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "      <exp>1</exp>\n";
        visualFile << "    </lengthDir>\n";
        visualFile << "    <widthDir>\n";
        visualFile << "      <exp>1</exp>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "      <exp>0</exp>\n";
        visualFile << "    </widthDir>\n";
        visualFile << "    <length><exp>0.5</exp></length>\n";
        visualFile << "    <width><exp>0.0025</exp></width>\n";
        visualFile << "    <height><exp>0.0025</exp></height>\n";
        visualFile << "    <extra><exp>0.0</exp></extra>\n";
        visualFile << "    <color>\n";
        if(interfaceSelected) {
          visualFile << "      <exp>" << selectedColor.red() << "</exp>\n";
          visualFile << "      <exp>" << selectedColor.green() << "</exp>\n";
          visualFile << "      <exp>" << selectedColor.blue() << "</exp>\n";
        } else {
          visualFile << "      <exp>0</exp>\n";
          visualFile << "      <exp>0</exp>\n";
          visualFile << "      <exp>255</exp>\n";
        }
        visualFile << "    </color>\n";
        visualFile << "    <specCoeff><exp>0.7</exp></specCoeff>\n";
        visualFile << "  </shape>\n";
        //End new code

        if (visited) {
          break;
        }
        /*!
         * \note Don't check for connection.
         * If we check for connection then only connected submodels can be seen in the ThreeDViewer Browser.
         */
        //        foreach (LineAnnotation *pConnectionLineAnnotation, mpDiagramGraphicsView->getConnectionsList()) {
        //          if ((pConnectionLineAnnotation->getStartComponentName().compare(name) == 0) ||
        //              (pConnectionLineAnnotation->getEndComponentName().compare(name) == 0)) {
        // get the angle
        double phi[3] = {0.0, 0.0, 0.0};
        QStringList angleList = pInterfaceComponent->getComponentInfo()->getAngle321().split(",", QString::SkipEmptyParts);
        if (angleList.size() > 2) {
          phi[0] = -angleList.at(0).toDouble();
          phi[1] = -angleList.at(1).toDouble();
          phi[2] = -angleList.at(2).toDouble();
        }
        QGenericMatrix<3, 3, double> T = Utilities::getRotationMatrix(QGenericMatrix<3, 1, double>(phi));
        // get the position
        double position[3] = {0.0, 0.0, 0.0};
        QStringList positionList = pInterfaceComponent->getComponentInfo()->getPosition().split(",", QString::SkipEmptyParts);
        if (positionList.size() > 2) {
          position[0] = positionList.at(0).toDouble();
          position[1] = positionList.at(1).toDouble();
          position[2] = positionList.at(2).toDouble();
        }
        QGenericMatrix<3, 1, double> r_shape;
        r_shape(0, 0) = -position[0];
        r_shape(0, 1) = -position[1];
        r_shape(0, 2) = -position[2];
        r_shape = r_shape*(T);
        double lengthDirArr[3] = {1.0, 0.0, 0.0};
        QGenericMatrix<3, 1, double> lengthDir(lengthDirArr);
        lengthDir = lengthDir*(T);
        double widthDirArr[3] = {0.0, 1.0, 0.0};
        QGenericMatrix<3, 1, double> widthDir(widthDirArr);
        widthDir = widthDir*(T);

        visualFile << "  <shape>\n";
        visualFile << "    <ident>" << name << "</ident>\n";
        visualFile << "    <type>file://" << pSubModelComponent->getComponentInfo()->getGeometryFile() << "</type>\n";
        visualFile << "    <T>\n";
        visualFile << "      <cref>" << name << ".A(1,1) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(1,2) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(1,3) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(2,1) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(2,2) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(2,3) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(3,1) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(3,2) [-]</cref>\n";
        visualFile << "      <cref>" << name << ".A(3,3) [-]</cref>\n";
        visualFile << "    </T>\n";
        visualFile << "    <r>\n";
        visualFile << "      <cref>" << name << ".R[cG][cG](1) [m]</cref>\n";
        visualFile << "      <cref>" << name << ".R[cG][cG](2) [m]</cref>\n";
        visualFile << "      <cref>" << name << ".R[cG][cG](3) [m]</cref>\n";
        visualFile << "    </r>\n";
        visualFile << "    <r_shape>\n";
        visualFile << "      <exp>" << r_shape(0, 0) << "</exp>\n";
        visualFile << "      <exp>" << r_shape(0, 1) << "</exp>\n";
        visualFile << "      <exp>" << r_shape(0, 2) << "</exp>\n";
        visualFile << "    </r_shape>\n";
        visualFile << "    <lengthDir>\n";
        visualFile << "      <exp>" << lengthDir(0, 0) << "</exp>\n";
        visualFile << "      <exp>" << lengthDir(0, 1) << "</exp>\n";
        visualFile << "      <exp>" << lengthDir(0, 2) << "</exp>\n";
        visualFile << "    </lengthDir>\n";
        visualFile << "    <widthDir>\n";
        visualFile << "      <exp>" << widthDir(0, 0) << "</exp>\n";
        visualFile << "      <exp>" << widthDir(0, 1) << "</exp>\n";
        visualFile << "      <exp>" << widthDir(0, 2) << "</exp>\n";
        visualFile << "    </widthDir>\n";
        visualFile << "    <length><exp>0.0</exp></length>\n";
        visualFile << "    <width><exp>0.0</exp></width>\n";
        visualFile << "    <height><exp>0.0</exp></height>\n";
        visualFile << "    <extra><exp>0.0</exp></extra>\n";
        visualFile << "    <color>\n";
        if (pSubModelComponent->isSelected()) {
          visualFile << "      <exp>" << selectedColor.red() << "</exp>\n";
          visualFile << "      <exp>" << selectedColor.green() << "</exp>\n";
          visualFile << "      <exp>" << selectedColor.blue() << "</exp>\n";
        } else {
          visualFile << "      <exp>" << colorsList.at(i % colorsList.size()).red() << "</exp>\n";
          visualFile << "      <exp>" << colorsList.at(i % colorsList.size()).green() << "</exp>\n";
          visualFile << "      <exp>" << colorsList.at(i % colorsList.size()).blue() << "</exp>\n";
        }
        visualFile << "    </color>\n";
        visualFile << "    <specCoeff><exp>0.7</exp></specCoeff>\n";
        visualFile << "  </shape>\n";
        // set the visited flag to true.
        visited = true;
        i++;
        break;
        //          }
        //        }
      }
    }

    visualFile << "</visualization>\n";
    file.close();
    return true;
  } else {
    QString msg = GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).arg(GUIMessages::getMessage(GUIMessages::UNABLE_TO_SAVE_FILE)
                                                                           .arg(fileName).arg(file.errorString()));
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                          Helper::errorLevel));
    return false;
  }
}

/*!
 * \brief ModelWidget::beginMacro
 * Tells the undo stack to consider all coming commands as one.\n
 * Also tells the text editor to mark all changes as one.
 * \param text
 */
void ModelWidget::beginMacro(const QString &text)
{
  mpUndoStack->beginMacro(text);
  if (mpEditor) {
    QTextCursor textCursor = mpEditor->getPlainTextEdit()->textCursor();
    textCursor.beginEditBlock();
  }
}

/*!
 * \brief ModelWidget::endMacro
 * Tells the undo stack and text editor that the batch editing is finished.
 */
void ModelWidget::endMacro()
{
  mpUndoStack->endMacro();
  if (mpEditor) {
    mpEditor->setForceSetPlainText(true);
    QTextCursor textCursor = mpEditor->getPlainTextEdit()->textCursor();
    textCursor.endEditBlock();
    mpEditor->setForceSetPlainText(false);
  }
}

/*!
 * \brief ModelWidget::updateViewButtonsBasedOnAccess
 * Update the view buttons i.e., icon, diagram and text based on the Access annotation.
 */
void ModelWidget::updateViewButtonsBasedOnAccess()
{
  if (mCreateModelWidgetComponents) {
    LibraryTreeItem::Access access = mpLibraryTreeItem->getAccess();
    switch (access) {
      case LibraryTreeItem::icon:
        mpIconViewToolButton->setChecked(true);
        mpDiagramViewToolButton->setEnabled(false);
        mpTextViewToolButton->setEnabled(false);
        mpDocumentationViewToolButton->setEnabled(false);
        break;
      case LibraryTreeItem::documentation:
        mpIconViewToolButton->setChecked(true);
        mpDiagramViewToolButton->setEnabled(false);
        mpTextViewToolButton->setEnabled(false);
        mpDocumentationViewToolButton->setEnabled(true);
        break;
      case LibraryTreeItem::diagram:
        if (mpTextViewToolButton->isChecked()) {
          mpDiagramViewToolButton->setChecked(true);
        }
        mpTextViewToolButton->setEnabled(false);
        mpDocumentationViewToolButton->setEnabled(true);
        break;
      case LibraryTreeItem::nonPackageText:
      case LibraryTreeItem::nonPackageDuplicate:
        if (mpLibraryTreeItem->getRestriction() == StringHandler::Package) {
          if (mpTextViewToolButton->isChecked()) {
            mpDiagramViewToolButton->setChecked(true);
          }
          mpTextViewToolButton->setEnabled(false);
        } else {
          mpDiagramViewToolButton->setEnabled(true);
          mpTextViewToolButton->setEnabled(true);
        }
        mpDocumentationViewToolButton->setEnabled(true);
        break;
      default:
        mpDiagramViewToolButton->setEnabled(true);
        mpTextViewToolButton->setEnabled(true);
        mpDocumentationViewToolButton->setEnabled(true);
        break;
    }
  }
}

/*!
 * \brief ModelWidget::associateBusWithConnector
 * Associates the bus component with the connector component.
 * \param busName
 * \param connectorName
 */
void ModelWidget::associateBusWithConnector(QString busName, QString connectorName)
{
  associateBusWithConnector(busName, connectorName, mpIconGraphicsView);
  associateBusWithConnector(busName, connectorName, mpDiagramGraphicsView);
  // get the connector component
  Component *pConnectorComponent = mpIconGraphicsView->getComponentObject(connectorName);
  if (pConnectorComponent) {
    pConnectorComponent->emitDeleted();
  }
}

/*!
 * \brief ModelWidget::dissociateBusWithConnector
 * Dissociate the bus component with the connector component.
 * \param busName
 * \param connectorName
 */
void ModelWidget::dissociateBusWithConnector(QString busName, QString connectorName)
{
  dissociateBusWithConnector(busName, connectorName, mpIconGraphicsView);
  dissociateBusWithConnector(busName, connectorName, mpDiagramGraphicsView);
  // get the connector component
  Component *pConnectorComponent = mpIconGraphicsView->getComponentObject(connectorName);
  if (pConnectorComponent) {
    pConnectorComponent->emitAdded();
  }
}

/*!
 * \brief ModelWidget::associateBusWithConnectors
 * Associates the bus component with each of its connector component.
 * \param busName
 */
void ModelWidget::associateBusWithConnectors(QString busName)
{
  // get the bus component
  Component *pIconBusComponent = mpIconGraphicsView->getComponentObject(busName);
  associateBusWithConnectors(pIconBusComponent, mpIconGraphicsView);
  Component *pDiagramBusComponent = mpDiagramGraphicsView->getComponentObject(busName);
  associateBusWithConnectors(pDiagramBusComponent, mpDiagramGraphicsView);
}

/*!
 * \brief ModelWidget::getModelInheritedClasses
 * Gets the class inherited classes.
 */
void ModelWidget::getModelInheritedClasses()
{
  MainWindow *pMainWindow = MainWindow::instance();
  LibraryTreeModel *pLibraryTreeModel = pMainWindow->getLibraryWidget()->getLibraryTreeModel();
  // get the inherited classes of the class
  QList<QString> inheritedClasses = pMainWindow->getOMCProxy()->getInheritedClasses(mpLibraryTreeItem->getNameStructure());
  foreach (QString inheritedClass, inheritedClasses) {
    /* If the inherited class is one of the builtin type such as Real we can
       * stop here, because the class can not contain any classes, etc.
       * Also check for cyclic loops.
       */
    if (!(pMainWindow->getOMCProxy()->isBuiltinType(inheritedClass) || inheritedClass.compare(mpLibraryTreeItem->getNameStructure()) == 0)) {
      LibraryTreeItem *pInheritedLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(inheritedClass);
      if (!pInheritedLibraryTreeItem) {
        pInheritedLibraryTreeItem = pLibraryTreeModel->createNonExistingLibraryTreeItem(inheritedClass);
      }
      if (!pInheritedLibraryTreeItem->isNonExisting() && !pInheritedLibraryTreeItem->getModelWidget()) {
        pLibraryTreeModel->showModelWidget(pInheritedLibraryTreeItem, false);
      }
      mpLibraryTreeItem->addInheritedClass(pInheritedLibraryTreeItem);
      addInheritedClass(pInheritedLibraryTreeItem);
    }
  }
}

/*!
 * \brief ModelWidget::parseModelInheritedClass
 * Parses the inherited class shape and draws its items on the appropriate view.
 * \param pModelWidget
 * \param viewType
 */
void ModelWidget::drawModelInheritedClassShapes(ModelWidget *pModelWidget, StringHandler::ViewType viewType)
{
  foreach (LibraryTreeItem *pLibraryTreeItem, pModelWidget->getInheritedClassesList()) {
    if (!pLibraryTreeItem->isNonExisting()) {
      if (!pLibraryTreeItem->getModelWidget()) {
        MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem, false);
      }
      drawModelInheritedClassShapes(pLibraryTreeItem->getModelWidget(), viewType);
    }
    GraphicsView *pInheritedGraphicsView, *pGraphicsView;
    if (pLibraryTreeItem->isNonExisting()) {
      if (viewType == StringHandler::Icon) {
        mpIconGraphicsView->addInheritedShapeToList(createNonExistingInheritedShape(mpIconGraphicsView));
      } else {
        mpDiagramGraphicsView->addInheritedShapeToList(createNonExistingInheritedShape(mpDiagramGraphicsView));
      }
    } else {
      if (viewType == StringHandler::Icon) {
        pInheritedGraphicsView = pLibraryTreeItem->getModelWidget()->getIconGraphicsView();
        pGraphicsView = mpIconGraphicsView;
      } else {
        pLibraryTreeItem->getModelWidget()->loadDiagramView();
        pInheritedGraphicsView = pLibraryTreeItem->getModelWidget()->getDiagramGraphicsView();
        pGraphicsView = mpDiagramGraphicsView;
      }
      // loop through the inherited class shapes
      foreach (ShapeAnnotation *pShapeAnnotation, pInheritedGraphicsView->getShapesList()) {
        if (viewType == StringHandler::Icon) {
          pGraphicsView->addInheritedShapeToList(createInheritedShape(pShapeAnnotation, pGraphicsView));
        } else {
          mpDiagramGraphicsView->addInheritedShapeToList(createInheritedShape(pShapeAnnotation, pGraphicsView));
        }
      }
    }
  }
}

/*!
 * \brief ModelWidget::removeInheritedClassShapes
 * Removes all the inherited class shapes.
 * \param viewType
 */
void ModelWidget::removeInheritedClassShapes(StringHandler::ViewType viewType)
{
  GraphicsView *pGraphicsView = 0;
  if (viewType == StringHandler::Icon) {
    pGraphicsView = mpIconGraphicsView;
  } else {
    pGraphicsView = mpDiagramGraphicsView;
  }
  foreach (ShapeAnnotation *pShapeAnnotation, pGraphicsView->getInheritedShapesList()) {
    pGraphicsView->deleteInheritedShapeFromList(pShapeAnnotation);
    pGraphicsView->removeItem(pShapeAnnotation);
    delete pShapeAnnotation;
  }
}

/*!
 * \brief ModelWidget::getModelIconDiagramShapes
 * Gets the Modelica model icon & diagram shapes.
 * Parses the Modelica icon/diagram annotation and creates shapes for it on appropriate GraphicsView.
 * \param viewType
 */
void ModelWidget::getModelIconDiagramShapes(StringHandler::ViewType viewType)
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  GraphicsView *pGraphicsView = 0;
  QString annotationString;
  if (viewType == StringHandler::Icon) {
    pGraphicsView = mpIconGraphicsView;
    if (mpLibraryTreeItem->getAccess() >= LibraryTreeItem::icon) {
      annotationString = pOMCProxy->getIconAnnotation(mpLibraryTreeItem->getNameStructure());
    }
  } else {
    pGraphicsView = mpDiagramGraphicsView;
    if (mpLibraryTreeItem->getAccess() >= LibraryTreeItem::diagram) {
      annotationString = pOMCProxy->getDiagramAnnotation(mpLibraryTreeItem->getNameStructure());
    }
  }
  annotationString = StringHandler::removeFirstLastCurlBrackets(annotationString);
  if (annotationString.isEmpty()) {
    drawBaseCoOrdinateSystem(this, pGraphicsView);
    return;
  }
  QStringList list = StringHandler::getStrings(annotationString);
  // read the coordinate system
  if (list.size() < 8) {
    drawBaseCoOrdinateSystem(this, pGraphicsView);
    return;
  }

  qreal left = qMin(list.at(0).toFloat(), list.at(2).toFloat());
  qreal bottom = qMin(list.at(1).toFloat(), list.at(3).toFloat());
  qreal right = qMax(list.at(0).toFloat(), list.at(2).toFloat());
  qreal top = qMax(list.at(1).toFloat(), list.at(3).toFloat());
  QList<QPointF> extent;
  extent << QPointF(left, bottom) << QPointF(right, top);
  pGraphicsView->mCoOrdinateSystem.setExtent(extent);
  pGraphicsView->mCoOrdinateSystem.setPreserveAspectRatio((list.at(4).compare("true") == 0) ? true : false);
  pGraphicsView->mCoOrdinateSystem.setInitialScale(list.at(5).toFloat());
  qreal horizontal = list.at(6).toFloat();
  qreal vertical = list.at(7).toFloat();
  pGraphicsView->mCoOrdinateSystem.setGrid(QPointF(horizontal, vertical));
  pGraphicsView->mCoOrdinateSystem.setValid(true);
  pGraphicsView->setExtentRectangle(left, bottom, right, top);
  pGraphicsView->resize(pGraphicsView->size());
  // read the shapes
  if (list.size() < 9)
    return;
  QStringList shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(8)), '(', ')');
  // Now parse the shapes available in list
  foreach (QString shape, shapesList) {
    if (shape.startsWith("Line")) {
      shape = shape.mid(QString("Line").length());
      shape = StringHandler::removeFirstLastParentheses(shape);
      LineAnnotation *pLineAnnotation = new LineAnnotation(shape, pGraphicsView);
      pLineAnnotation->initializeTransformation();
      pLineAnnotation->drawCornerItems();
      pLineAnnotation->setCornerItemsActiveOrPassive();
      pGraphicsView->addShapeToList(pLineAnnotation);
      pGraphicsView->addItem(pLineAnnotation);
    } else if (shape.startsWith("Polygon")) {
      shape = shape.mid(QString("Polygon").length());
      shape = StringHandler::removeFirstLastParentheses(shape);
      PolygonAnnotation *pPolygonAnnotation = new PolygonAnnotation(shape, pGraphicsView);
      pPolygonAnnotation->initializeTransformation();
      pPolygonAnnotation->drawCornerItems();
      pPolygonAnnotation->setCornerItemsActiveOrPassive();
      pGraphicsView->addShapeToList(pPolygonAnnotation);
      pGraphicsView->addItem(pPolygonAnnotation);
    } else if (shape.startsWith("Rectangle")) {
      shape = shape.mid(QString("Rectangle").length());
      shape = StringHandler::removeFirstLastParentheses(shape);
      RectangleAnnotation *pRectangleAnnotation = new RectangleAnnotation(shape, pGraphicsView);
      pRectangleAnnotation->initializeTransformation();
      pRectangleAnnotation->drawCornerItems();
      pRectangleAnnotation->setCornerItemsActiveOrPassive();
      pGraphicsView->addShapeToList(pRectangleAnnotation);
      pGraphicsView->addItem(pRectangleAnnotation);
    } else if (shape.startsWith("Ellipse")) {
      shape = shape.mid(QString("Ellipse").length());
      shape = StringHandler::removeFirstLastParentheses(shape);
      EllipseAnnotation *pEllipseAnnotation = new EllipseAnnotation(shape, pGraphicsView);
      pEllipseAnnotation->initializeTransformation();
      pEllipseAnnotation->drawCornerItems();
      pEllipseAnnotation->setCornerItemsActiveOrPassive();
      pGraphicsView->addShapeToList(pEllipseAnnotation);
      pGraphicsView->addItem(pEllipseAnnotation);
    } else if (shape.startsWith("Text")) {
      shape = shape.mid(QString("Text").length());
      shape = StringHandler::removeFirstLastParentheses(shape);
      TextAnnotation *pTextAnnotation = new TextAnnotation(shape, pGraphicsView);
      pTextAnnotation->initializeTransformation();
      pTextAnnotation->drawCornerItems();
      pTextAnnotation->setCornerItemsActiveOrPassive();
      pGraphicsView->addShapeToList(pTextAnnotation);
      pGraphicsView->addItem(pTextAnnotation);
    } else if (shape.startsWith("Bitmap")) {
      /* create the bitmap shape */
      shape = shape.mid(QString("Bitmap").length());
      shape = StringHandler::removeFirstLastParentheses(shape);
      BitmapAnnotation *pBitmapAnnotation = new BitmapAnnotation(mpLibraryTreeItem->mClassInformation.fileName, shape, pGraphicsView);
      pBitmapAnnotation->initializeTransformation();
      pBitmapAnnotation->drawCornerItems();
      pBitmapAnnotation->setCornerItemsActiveOrPassive();
      pGraphicsView->addShapeToList(pBitmapAnnotation);
      pGraphicsView->addItem(pBitmapAnnotation);
    }
  }
}

/*!
 * \brief ModelWidget::drawModelInheritedClassComponents
 * Loops through the class inhertited classes and draws the components for all.
 * \param pModelWidget
 * \param viewType
 */
void ModelWidget::drawModelInheritedClassComponents(ModelWidget *pModelWidget, StringHandler::ViewType viewType)
{
  foreach (LibraryTreeItem *pLibraryTreeItem, pModelWidget->getInheritedClassesList()) {
    if (!pLibraryTreeItem->isNonExisting()) {
      drawModelInheritedClassComponents(pLibraryTreeItem->getModelWidget(), viewType);
      GraphicsView *pInheritedGraphicsView, *pGraphicsView;
      if (viewType == StringHandler::Icon) {
        pLibraryTreeItem->getModelWidget()->loadComponents();
        pInheritedGraphicsView = pLibraryTreeItem->getModelWidget()->getIconGraphicsView();
        pGraphicsView = mpIconGraphicsView;
      } else {
        pLibraryTreeItem->getModelWidget()->loadDiagramView();
        pInheritedGraphicsView = pLibraryTreeItem->getModelWidget()->getDiagramGraphicsView();
        pGraphicsView = mpDiagramGraphicsView;
      }
      foreach (Component *pInheritedComponent, pInheritedGraphicsView->getComponentsList()) {
        pGraphicsView->addInheritedComponentToList(createInheritedComponent(pInheritedComponent, pGraphicsView));
      }
    }
  }
}

/*!
 * \brief ModelWidget::removeInheritedClassComponents
 * Removes all the class inherited components.
 * \param viewType
 */
void ModelWidget::removeInheritedClassComponents(StringHandler::ViewType viewType)
{
  GraphicsView *pGraphicsView = 0;
  if (viewType == StringHandler::Icon) {
    pGraphicsView = mpIconGraphicsView;
  } else {
    pGraphicsView = mpDiagramGraphicsView;
  }
  foreach (Component *pComponent, pGraphicsView->getInheritedComponentsList()) {
    pComponent->removeChildren();
    pGraphicsView->deleteInheritedComponentFromList(pComponent);
    pGraphicsView->removeItem(pComponent->getOriginItem());
    delete pComponent->getOriginItem();
    pGraphicsView->removeItem(pComponent);
    pComponent->emitDeleted();
    delete pComponent;
  }
}

/*!
 * \brief ModelWidget::removeClassComponents
 * Removes all the class components.
 * \param viewType
 */
void ModelWidget::removeClassComponents(StringHandler::ViewType viewType)
{
  GraphicsView *pGraphicsView = 0;
  if (viewType == StringHandler::Icon) {
    pGraphicsView = mpIconGraphicsView;
  } else {
    pGraphicsView = mpDiagramGraphicsView;
  }
  foreach (Component *pComponent, pGraphicsView->getComponentsList()) {
    pComponent->removeChildren();
    pGraphicsView->deleteComponentFromList(pComponent);
    pGraphicsView->removeItem(pComponent->getOriginItem());
    delete pComponent->getOriginItem();
    pGraphicsView->removeItem(pComponent);
    pComponent->emitDeleted();
    delete pComponent;
  }
}

/*!
 * \brief ModelWidget::getModelComponents
 * Gets the components of the model and their annotations.
 */
void ModelWidget::getModelComponents()
{
  MainWindow *pMainWindow = MainWindow::instance();
  // get the components
  mComponentsList = pMainWindow->getOMCProxy()->getComponents(mpLibraryTreeItem->getNameStructure());
  // get the components annotations
  if (!mComponentsList.isEmpty()) {
    mComponentsAnnotationsList = pMainWindow->getOMCProxy()->getComponentAnnotations(mpLibraryTreeItem->getNameStructure());
  }
}

/*!
 * \brief ModelWidget::drawModelIconComponents
 * Draw the components for icon view and place them in the icon GraphicsView.
 */
void ModelWidget::drawModelIconComponents()
{
  MainWindow *pMainWindow = MainWindow::instance();
  int i = 0;
  foreach (ComponentInfo *pComponentInfo, mComponentsList) {
    // if the component type is one of the builtin type then don't try to load it here. we load it when loading diagram view.
    if (pMainWindow->getOMCProxy()->isBuiltinType(pComponentInfo->getClassName())) {
      i++;
      continue;
    }
    LibraryTreeItem *pLibraryTreeItem = 0;
    LibraryTreeModel *pLibraryTreeModel = pMainWindow->getLibraryWidget()->getLibraryTreeModel();
    pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(pComponentInfo->getClassName());
    if (!pLibraryTreeItem) {
      pLibraryTreeItem = pLibraryTreeModel->createNonExistingLibraryTreeItem(pComponentInfo->getClassName());
    }
    // we only load and draw connectors here. Other components are drawn when loading diagram view.
    if (pLibraryTreeItem->isConnector()) {
      if (!pLibraryTreeItem->isNonExisting() && !pLibraryTreeItem->getModelWidget()) {
        pLibraryTreeModel->showModelWidget(pLibraryTreeItem, false);
      }
      QString annotation;
      if (mComponentsAnnotationsList.size() >= i) {
        annotation = mComponentsAnnotationsList.at(i);
        if (StringHandler::getPlacementAnnotation(annotation).isEmpty()) {
          annotation = StringHandler::removeFirstLastCurlBrackets(annotation);
          annotation = QString("{%1, Placement(false,0.0,0.0,-10.0,-10.0,10.0,10.0,0.0,-,-,-,-,-,-,)}").arg(annotation);
        }
      }
      mpIconGraphicsView->addComponentToView(pComponentInfo->getName(), pLibraryTreeItem, annotation, QPointF(0, 0), pComponentInfo,
                                             false, true);
    }
    i++;
  }
}

/*!
 * \brief ModelWidget::drawModelDiagramComponents
 * Draw the components for diagram view and place them in the diagram GraphicsView.
 */
void ModelWidget::drawModelDiagramComponents()
{
  MainWindow *pMainWindow = MainWindow::instance();
  int i = 0;
  foreach (ComponentInfo *pComponentInfo, mComponentsList) {
    LibraryTreeItem *pLibraryTreeItem = 0;
    // if the component type is one of the builtin type then don't try to load it.
    if (!pMainWindow->getOMCProxy()->isBuiltinType(pComponentInfo->getClassName())) {
      LibraryTreeModel *pLibraryTreeModel = pMainWindow->getLibraryWidget()->getLibraryTreeModel();
      pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(pComponentInfo->getClassName());
      if (!pLibraryTreeItem) {
        pLibraryTreeItem = pLibraryTreeModel->createNonExistingLibraryTreeItem(pComponentInfo->getClassName());
      }
      // we only load and draw non-connectors here. Connector components are drawn in drawModelIconComponents().
      if (pLibraryTreeItem->isConnector()) {
        i++;
        continue;
      }
      if (!pLibraryTreeItem->isNonExisting() && !pLibraryTreeItem->getModelWidget()) {
        pLibraryTreeModel->showModelWidget(pLibraryTreeItem, false);
      }
    }
    QString annotation;
    if (mComponentsAnnotationsList.size() >= i) {
      annotation = mComponentsAnnotationsList.at(i);
      if (StringHandler::getPlacementAnnotation(annotation).isEmpty()) {
        annotation = StringHandler::removeFirstLastCurlBrackets(annotation);
        annotation = QString("{%1, Placement(false,0.0,0.0,-10.0,-10.0,10.0,10.0,0.0,-,-,-,-,-,-,)}").arg(annotation);
      }
    }
    mpDiagramGraphicsView->addComponentToView(pComponentInfo->getName(), pLibraryTreeItem, annotation, QPointF(0, 0), pComponentInfo,
                                              false, true);
    i++;
  }
}

/*!
 * \brief ModelWidget::drawModelInheritedClassConnections
 * Loops through the class inhertited classes and draws the connections for all.
 * \param pModelWidget
 */
void ModelWidget::drawModelInheritedClassConnections(ModelWidget *pModelWidget)
{
  foreach (LibraryTreeItem *pLibraryTreeItem, pModelWidget->getInheritedClassesList()) {
    if (!pLibraryTreeItem->isNonExisting()) {
      drawModelInheritedClassConnections(pLibraryTreeItem->getModelWidget());
      pLibraryTreeItem->getModelWidget()->loadConnections();
      foreach (LineAnnotation *pConnectionLineAnnotation, pLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->getConnectionsList()) {
        mpDiagramGraphicsView->addInheritedConnectionToList(createInheritedConnection(pConnectionLineAnnotation));
      }
    }
  }
}

/*!
 * \brief ModelWidget::removeInheritedClassConnections
 * Removes all the class inherited class connections.
 */
void ModelWidget::removeInheritedClassConnections()
{
  foreach (LineAnnotation *pConnectionLineAnnotation, mpDiagramGraphicsView->getInheritedConnectionsList()) {
    mpDiagramGraphicsView->deleteInheritedConnectionFromList(pConnectionLineAnnotation);
    mpDiagramGraphicsView->removeItem(pConnectionLineAnnotation);
    delete pConnectionLineAnnotation;
  }
}

/*!
 * \brief ModelWidget::getModelTransitions
 * Gets the transitions of the model and place them in the diagram GraphicsView.
 */
void ModelWidget::getModelTransitions()
{
  QList<QList<QString>> transitions = MainWindow::instance()->getOMCProxy()->getTransitions(mpLibraryTreeItem->getNameStructure());
  for (int i = 0 ; i < transitions.size() ; i++) {
    QStringList transition = transitions.at(i);
    // get start component
    Component *pStartComponent = mpDiagramGraphicsView->getComponentObject(transition.at(0));
    // show error message if start component is not found.
    if (!pStartComponent) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                            GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_TRANSITION)
                                                            .arg(transition.at(0)).arg(transition.join(",")),
                                                            Helper::scriptingKind, Helper::errorLevel));
      continue;
    }
    // get end component
    Component *pEndComponent = mpDiagramGraphicsView->getComponentObject(transition.at(1));
    // show error message if end component is not found.
    if (!pEndComponent) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                            GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_TRANSITION)
                                                            .arg(transition.at(1)).arg(transition.join(",")),
                                                            Helper::scriptingKind, Helper::errorLevel));
      continue;
    }
    // get the transition annotations
    QStringList shapesList = StringHandler::getStrings(transition.at(7), '(', ')');
    // Now parse the shapes available in list
    QString lineShape, textShape = "";
    foreach (QString shape, shapesList) {
      if (shape.startsWith("Line")) {
        lineShape = shape.mid(QString("Line").length());
        lineShape = StringHandler::removeFirstLastParentheses(lineShape);
      } else if (shape.startsWith("Text")) {
        textShape = shape.mid(QString("Text").length());
        textShape = StringHandler::removeFirstLastParentheses(textShape);
      }
    }
    LineAnnotation *pTransitionLineAnnotation;
    pTransitionLineAnnotation = new LineAnnotation(lineShape, textShape, pStartComponent, pEndComponent, transition.at(2), transition.at(3),
                                                   transition.at(4), transition.at(5), transition.at(6), mpDiagramGraphicsView);
    pTransitionLineAnnotation->setStartComponentName(transition.at(0));
    pTransitionLineAnnotation->setEndComponentName(transition.at(1));
    mpUndoStack->push(new AddTransitionCommand(pTransitionLineAnnotation, false));
  }
}

/*!
 * \brief ModelWidget::getModelInitialStates
 * Gets the initial states of the model and place them in the diagram GraphicsView.
 */
void ModelWidget::getModelInitialStates()
{
  QList<QList<QString>> initialStates = MainWindow::instance()->getOMCProxy()->getInitialStates(mpLibraryTreeItem->getNameStructure());
  for (int i = 0 ; i < initialStates.size() ; i++) {
    QStringList initialState = initialStates.at(i);
    // get initial state component
    Component *pInitialStateComponent = mpDiagramGraphicsView->getComponentObject(initialState.at(0));
    // show error message if initial state component is not found.
    if (!pInitialStateComponent) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                            GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_INITIALSTATE)
                                                            .arg(initialState.at(0)).arg(initialState.join(",")),
                                                            Helper::scriptingKind, Helper::errorLevel));
      continue;
    }
    // get the transition annotations
    QStringList shapesList = StringHandler::getStrings(initialState.at(1), '(', ')');
    // Now parse the shapes available in list
    QString lineShape = "";
    foreach (QString shape, shapesList) {
      if (shape.startsWith("Line")) {
        lineShape = shape.mid(QString("Line").length());
        lineShape = StringHandler::removeFirstLastParentheses(lineShape);
      }
    }
    LineAnnotation *pInitialStateLineAnnotation;
    pInitialStateLineAnnotation = new LineAnnotation(lineShape, pInitialStateComponent, mpDiagramGraphicsView);
    pInitialStateLineAnnotation->setStartComponentName(initialState.at(0));
    pInitialStateLineAnnotation->setEndComponentName("");
    mpUndoStack->push(new AddInitialStateCommand(pInitialStateLineAnnotation, false));
  }
}

/*!
 * \brief ModelWidget::getMetaModelSubModels
 * \brief ModelWidget::detectMultipleDeclarations
 * detect multiple declarations of a component instance
 */
void ModelWidget::detectMultipleDeclarations()
{
  for (int i = 0 ; i < mComponentsList.size() ; i++) {
    for (int j = 0 ; j < mComponentsList.size() ; j++) {
      if (i == j) {
        j++;
        continue;
      }
      if (mComponentsList[i]->getName().compare(mComponentsList[j]->getName()) == 0) {
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                              GUIMessages::getMessage(GUIMessages::MULTIPLE_DECLARATIONS_COMPONENT)
                                                              .arg(mComponentsList[i]->getName()),
                                                              Helper::scriptingKind, Helper::errorLevel));
        return;
      }
    }
  }
}

/*!
 * \brief ModelWidget::getCompositeModelName
 * Gets the CompositeModel name.
 * \return
 */
QString ModelWidget::getCompositeModelName()
{
  CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpEditor);
  return pCompositeModelEditor->getCompositeModelName();
}

/*!
 * \brief ModelWidget::getCompositeModelSubModels
 * Gets the submodels of the TLM and place them in the diagram GraphicsView.
 */
void ModelWidget::getCompositeModelSubModels()
{
  QFileInfo fileInfo(mpLibraryTreeItem->getFileName());
  CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpEditor);
  if (pCompositeModelEditor) {
    QDomNodeList subModels = pCompositeModelEditor->getSubModels();
    for (int i = 0; i < subModels.size(); i++) {
      QString transformation;
      QDomElement subModel = subModels.at(i).toElement();
      QDomNodeList subModelChildren = subModel.childNodes();
      for (int j = 0 ; j < subModelChildren.size() ; j++) {
        QDomElement annotationElement = subModelChildren.at(j).toElement();
        if (annotationElement.tagName().compare("Annotation") == 0) {
          transformation = "Placement(";
          transformation.append(annotationElement.attribute("Visible")).append(",");
          transformation.append(StringHandler::removeFirstLastCurlBrackets(annotationElement.attribute("Origin"))).append(",");
          transformation.append(StringHandler::removeFirstLastCurlBrackets(annotationElement.attribute("Extent"))).append(",");
          transformation.append(StringHandler::removeFirstLastCurlBrackets(annotationElement.attribute("Rotation"))).append(",");
          transformation.append("-,-,-,-,-,-,");
        }
      }
      // add the component to the the diagram view.
      LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
      LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(subModel.attribute("Name"));
      // get the attibutes of the submodel
      ComponentInfo *pComponentInfo = new ComponentInfo;
      pComponentInfo->setName(subModel.attribute("Name"));
      pComponentInfo->setStartCommand(subModel.attribute("StartCommand"));
      bool exactStep;
      if ((subModel.attribute("ExactStep").toLower().compare("1") == 0)
          || (subModel.attribute("ExactStep").toLower().compare("true") == 0)) {
        exactStep = true;
      } else {
        exactStep = false;
      }
      pComponentInfo->setExactStep(exactStep);
      pComponentInfo->setModelFile(subModel.attribute("ModelFile"));
      QString absoluteModelFilePath = QString("%1/%2/%3").arg(fileInfo.absolutePath()).arg(subModel.attribute("Name"))
          .arg(subModel.attribute("ModelFile"));
      // if ModelFile doesn't exist
      if (!QFile::exists(absoluteModelFilePath)) {
        QString msg = tr("Unable to find ModelFile <b>%1</b> for SubModel <b>%2</b>. The file location should be <b>%3</b>.")
            .arg(subModel.attribute("ModelFile")).arg(subModel.attribute("Name")).arg(absoluteModelFilePath);
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                              Helper::errorLevel));
      }
      // Geometry File
      if (!subModel.attribute("GeometryFile").isEmpty()) {
        QString absoluteGeometryFilePath = QString("%1/%2/%3").arg(fileInfo.absolutePath()).arg(subModel.attribute("Name"))
            .arg(subModel.attribute("GeometryFile"));
        pComponentInfo->setGeometryFile(absoluteGeometryFilePath);
        // if GeometryFile doesn't exist
        if (!QFile::exists(absoluteGeometryFilePath)) {
          QString msg = tr("Unable to find GeometryFile <b>%1</b> for SubModel <b>%2</b>. The file location should be <b>%3</b>.")
              .arg(subModel.attribute("GeometryFile")).arg(subModel.attribute("Name")).arg(absoluteGeometryFilePath);
          MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                                Helper::errorLevel));
        }
      }
      pComponentInfo->setPosition(subModel.attribute("Position"));
      pComponentInfo->setAngle321(subModel.attribute("Angle321"));
      // add submodel as component to view.
      mpDiagramGraphicsView->addComponentToView(subModel.attribute("Name"), pLibraryTreeItem, transformation, QPointF(0.0, 0.0),
                                                pComponentInfo, false, true);
    }
  }
}

/*!
 * \brief ModelWidget::getCompositeModelConnections
 * Reads the TLM connections and draws them.
 */
void ModelWidget::getCompositeModelConnections()
{
  MessagesWidget *pMessagesWidget = MessagesWidget::instance();
  CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpEditor);
  QDomNodeList connections = pCompositeModelEditor->getConnections();
  for (int i = 0; i < connections.size(); i++) {
    QDomElement connection = connections.at(i).toElement();
    // get start submodel
    QStringList startConnectionList = connection.attribute("From").split(".");
    if (startConnectionList.size() < 2) {
      continue;
    }
    Component *pStartSubModelComponent = mpDiagramGraphicsView->getComponentObject(startConnectionList.at(0));
    if (!pStartSubModelComponent) {
      pMessagesWidget->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                 GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION).arg(startConnectionList.at(0))
                                                 .arg(connection.attribute("From")), Helper::scriptingKind, Helper::errorLevel));
      continue;
    }
    // get start interface point
    Component *pStartInterfacePointComponent = getConnectorComponent(pStartSubModelComponent, startConnectionList.at(1));
    if (!pStartInterfacePointComponent) {
      pMessagesWidget->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                 GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION).arg(startConnectionList.at(1))
                                                 .arg(connection.attribute("From")), Helper::scriptingKind, Helper::errorLevel));
      continue;
    }
    // get end submodel
    QStringList endConnectionList = connection.attribute("To").split(".");
    if (endConnectionList.size() < 2) {
      continue;
    }
    Component *pEndSubModelComponent = mpDiagramGraphicsView->getComponentObject(endConnectionList.at(0));
    if (!pEndSubModelComponent) {
      pMessagesWidget->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                 GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION).arg(endConnectionList.at(0))
                                                 .arg(connection.attribute("To")), Helper::scriptingKind, Helper::errorLevel));
      continue;
    }
    // get end interface point
    Component *pEndInterfacePointComponent = getConnectorComponent(pEndSubModelComponent, endConnectionList.at(1));
    if (!pEndInterfacePointComponent) {
      pMessagesWidget->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                 GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION).arg(endConnectionList.at(1))
                                                 .arg(connection.attribute("To")), Helper::scriptingKind, Helper::errorLevel));
      continue;
    }
    // default connection annotation
    QString annotation = QString("{Line(true,{0.0,0.0},0,%1,{0,0,0},LinePattern.Solid,0.25,{Arrow.None,Arrow.None},3,Smooth.None)}");
    QStringList shapesList;
    bool annotationFound = false;
    // check if connection has annotaitons defined
    QDomNodeList connectionChildren = connection.childNodes();
    for (int j = 0 ; j < connectionChildren.size() ; j++) {
      QDomElement annotationElement = connectionChildren.at(j).toElement();
      if (annotationElement.tagName().compare("Annotation") == 0) {
        annotationFound = true;
        shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(QString(annotation).arg(annotationElement.attribute("Points"))), '(', ')');
      }
    }
    if (!annotationFound) {
      QString point = QString("{%1,%2}");
      QStringList points;
      QPointF startPoint = pStartInterfacePointComponent->mapToScene(pStartInterfacePointComponent->boundingRect().center());
      points.append(point.arg(startPoint.x()).arg(startPoint.y()));
      QPointF endPoint = pEndInterfacePointComponent->mapToScene(pEndInterfacePointComponent->boundingRect().center());
      points.append(point.arg(endPoint.x()).arg(endPoint.y()));
      QString pointsString = QString("{%1}").arg(points.join(","));
      shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(QString(annotation).arg(pointsString)), '(', ')');
    }
    // Now parse the shapes available in list
    QString lineShape = "";
    foreach (QString shape, shapesList) {
      if (shape.startsWith("Line")) {
        lineShape = shape.mid(QString("Line").length());
        lineShape = StringHandler::removeFirstLastParentheses(lineShape);
        break;  // break the loop once we have got the line annotation.
      }
    }
    LineAnnotation *pConnectionLineAnnotation = new LineAnnotation(lineShape, pStartInterfacePointComponent, pEndInterfacePointComponent,
                                                                   mpDiagramGraphicsView);
    pConnectionLineAnnotation->setStartComponentName(connection.attribute("From"));
    pConnectionLineAnnotation->setEndComponentName(connection.attribute("To"));
    pConnectionLineAnnotation->setDelay(connection.attribute("Delay"));
    pConnectionLineAnnotation->setZf(connection.attribute("Zf"));
    pConnectionLineAnnotation->setZfr(connection.attribute("Zfr"));
    pConnectionLineAnnotation->setAlpha(connection.attribute("alpha"));
    // check if interfaces are aligned
    bool aligned = pCompositeModelEditor->interfacesAligned(pConnectionLineAnnotation->getStartComponentName(),
                                                            pConnectionLineAnnotation->getEndComponentName());
    pConnectionLineAnnotation->setAligned(aligned);

    CompositeModelEditor *pEditor = dynamic_cast<CompositeModelEditor*>(mpEditor);
    if(pEditor->getInterfaceCausality(pConnectionLineAnnotation->getEndComponentName()) ==
       StringHandler::getTLMCausality(StringHandler::TLMInput)) {
      pConnectionLineAnnotation->setLinePattern(StringHandler::LineDash);
      pConnectionLineAnnotation->setEndArrow(StringHandler::ArrowFilled);
      //pConnectionLineAnnotation->update();
      //pConnectionLineAnnotation->handleComponentMoved();
    }
    else if(pEditor->getInterfaceCausality(pConnectionLineAnnotation->getEndComponentName()) ==
            StringHandler::getTLMCausality(StringHandler::TLMOutput)) {
      pConnectionLineAnnotation->setLinePattern(StringHandler::LineDash);
      pConnectionLineAnnotation->setStartArrow(StringHandler::ArrowFilled);
      //pConnectionLineAnnotation->update();
      //pConnectionLineAnnotation->handleComponentMoved();
    }

    mpUndoStack->push(new AddConnectionCommand(pConnectionLineAnnotation, false));
  }
}

void ModelWidget::drawOMSModelIconElements()
{
  if (mpLibraryTreeItem->isTopLevel()) {
    return;
  } else if (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isComponentElement()) {
    drawOMSModelElement();
    // draw connectors
    for (int i = 0 ; i < mpLibraryTreeItem->childrenSize() ; i++) {
      LibraryTreeItem *pChildLibraryTreeItem = mpLibraryTreeItem->childAt(i);
      if (pChildLibraryTreeItem->getOMSConnector()
          && (pChildLibraryTreeItem->getOMSConnector()->causality == oms_causality_input
              || pChildLibraryTreeItem->getOMSConnector()->causality == oms_causality_output)) {
        double x = 0.5;
        double y = 0.5;
        if (pChildLibraryTreeItem->getOMSConnector()->geometry) {
          x = pChildLibraryTreeItem->getOMSConnector()->geometry->x;
          y = pChildLibraryTreeItem->getOMSConnector()->geometry->y;
        }
        QString annotation = QString("Placement(true,%1,%2,-10.0,-10.0,10.0,10.0,0,%1,%2,-10.0,-10.0,10.0,10.0,)")
                             .arg(Utilities::mapToCoOrdinateSystem(x, 0, 1, -100, 100))
                             .arg(Utilities::mapToCoOrdinateSystem(y, 0, 1, -100, 100));
        AddConnectorCommand *pAddConnectorCommand = new AddConnectorCommand(pChildLibraryTreeItem->getName(), pChildLibraryTreeItem,
                                                                            annotation, mpIconGraphicsView, true,
                                                                            pChildLibraryTreeItem->getOMSConnector()->causality,
                                                                            pChildLibraryTreeItem->getOMSConnector()->type);
        mpUndoStack->push(pAddConnectorCommand);
      } else if (pChildLibraryTreeItem->getOMSBusConnector()) {
        double x = 0.5;
        double y = 0.5;
        if (pChildLibraryTreeItem->getOMSBusConnector()->geometry) {
          x = pChildLibraryTreeItem->getOMSBusConnector()->geometry->x;
          y = pChildLibraryTreeItem->getOMSBusConnector()->geometry->y;
        }
        QString annotation = QString("Placement(true,%1,%2,-10.0,-10.0,10.0,10.0,0,%1,%2,-10.0,-10.0,10.0,10.0,)")
                             .arg(Utilities::mapToCoOrdinateSystem(x, 0, 1, -100, 100))
                             .arg(Utilities::mapToCoOrdinateSystem(y, 0, 1, -100, 100));
        AddBusCommand *pAddBusCommand = new AddBusCommand(pChildLibraryTreeItem->getName(), pChildLibraryTreeItem,
                                                          annotation, mpIconGraphicsView, true);
        mpUndoStack->push(pAddBusCommand);
        // assoicated the bus component with each of its connector component
        associateBusWithConnectors(pChildLibraryTreeItem->getName());
      } else if (pChildLibraryTreeItem->getOMSTLMBusConnector()) {
        double x = 0.5;
        double y = 0.5;
        if (pChildLibraryTreeItem->getOMSTLMBusConnector()->geometry) {
          x = pChildLibraryTreeItem->getOMSTLMBusConnector()->geometry->x;
          y = pChildLibraryTreeItem->getOMSTLMBusConnector()->geometry->y;
        }
        QString annotation = QString("Placement(true,%1,%2,-10.0,-10.0,10.0,10.0,0,%1,%2,-10.0,-10.0,10.0,10.0,)")
                             .arg(Utilities::mapToCoOrdinateSystem(x, 0, 1, -100, 100))
                             .arg(Utilities::mapToCoOrdinateSystem(y, 0, 1, -100, 100));
        AddTLMBusCommand *pAddTLMBusCommand = new AddTLMBusCommand(pChildLibraryTreeItem->getName(), pChildLibraryTreeItem,
                                                                   annotation, mpIconGraphicsView, true,
                                                                   pChildLibraryTreeItem->getOMSTLMBusConnector()->domain,
                                                                   pChildLibraryTreeItem->getOMSTLMBusConnector()->dimensions,
                                                                   pChildLibraryTreeItem->getOMSTLMBusConnector()->interpolation);
        mpUndoStack->push(pAddTLMBusCommand);
        // assoicated the bus component with each of its connector component
        associateBusWithConnectors(pChildLibraryTreeItem->getName());
      }
    }
  }
}

void ModelWidget::drawOMSModelDiagramElements()
{
  if (mpLibraryTreeItem->isTopLevel() || mpLibraryTreeItem->isSystemElement()) {
    for (int i = 0 ; i < mpLibraryTreeItem->childrenSize() ; i++) {
      LibraryTreeItem *pChildLibraryTreeItem = mpLibraryTreeItem->childAt(i);
      /* We only draw the elements here
       * Connectors are already drawn as part of ModelWidget::drawOMSModelIconElements();
       */
      if (pChildLibraryTreeItem->getOMSElement() && pChildLibraryTreeItem->getOMSElement()->geometry) {
        // check if we have zero width and height
        double x1, y1, x2, y2;
        x1 = pChildLibraryTreeItem->getOMSElement()->geometry->x1;
        y1 = pChildLibraryTreeItem->getOMSElement()->geometry->y1;
        x2 = pChildLibraryTreeItem->getOMSElement()->geometry->x2;
        y2 = pChildLibraryTreeItem->getOMSElement()->geometry->y2;
        double width = x2 - x1;
        double height = y2 - y1;
        if (width <= 0 && height <= 0) {
          x1 = -10.0;
          y1 = -10.0;
          x2 = 10.0;
          y2 = 10.0;
        }
        // Load the ModelWidget if not loaded already
        if (!pChildLibraryTreeItem->getModelWidget()) {
          MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pChildLibraryTreeItem, false);
        }

        QString annotation = QString("Placement(true,-,-,%1,%2,%3,%4,%5,-,-,-,-,-,-,)")
                             .arg(x1).arg(y1)
                             .arg(x2).arg(y2)
                             .arg(pChildLibraryTreeItem->getOMSElement()->geometry->rotation);

        if (pChildLibraryTreeItem->isSystemElement()) {
          AddSystemCommand *pAddSystemCommand = new AddSystemCommand(pChildLibraryTreeItem->getName(), pChildLibraryTreeItem,
                                                                     annotation, mpDiagramGraphicsView, true,
                                                                     pChildLibraryTreeItem->getSystemType());
          mpUndoStack->push(pAddSystemCommand);
        } else if (pChildLibraryTreeItem->isComponentElement()) {
          AddSubModelCommand *pAddSubModelCommand = new AddSubModelCommand(pChildLibraryTreeItem->getName(), "", pChildLibraryTreeItem,
                                                                           annotation, true, mpDiagramGraphicsView);
          mpUndoStack->push(pAddSubModelCommand);
        }
      }
    }
  }
}

/*!
 * \brief ModelWidget::drawOMSModelConnections
 * Gets the OMSimulator model connections and draws them.
 */
void ModelWidget::drawOMSModelConnections()
{
  if (mpLibraryTreeItem->isSystemElement()) {
    MessagesWidget *pMessagesWidget = MessagesWidget::instance();
    oms_connection_t** pConnections = NULL;
    if (OMSProxy::instance()->getConnections(mpLibraryTreeItem->getNameStructure(), &pConnections)) {
      for (int i = 0 ; pConnections[i] ; i++) {
        // get start component
        QStringList startConnectionList = StringHandler::makeVariableParts(QString(pConnections[i]->conA));
        if (startConnectionList.size() < 1) {
          continue;
        }
        Component *pStartComponent = mpDiagramGraphicsView->getComponentObject(startConnectionList.at(0));
        if (!pStartComponent) {
          pMessagesWidget->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                     GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION)
                                                     .arg(startConnectionList.at(0)).arg(pConnections[i]->conA),
                                                     Helper::scriptingKind, Helper::errorLevel));
          continue;
        }
        Component *pStartConnectorComponent, *pStartBusConnectorComponent;
        if (startConnectionList.size() > 1) {
          // get start connector component
          QString startConnectorName = StringHandler::removeFirstWordAfterDot(QString(pConnections[i]->conA));
          pStartConnectorComponent = getConnectorComponent(pStartComponent, startConnectorName);
          if (!pStartConnectorComponent) {
            pMessagesWidget->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                       GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION)
                                                       .arg(startConnectorName).arg(pConnections[i]->conA),
                                                       Helper::scriptingKind, Helper::errorLevel));
            continue;
          }
          pStartBusConnectorComponent = pStartConnectorComponent;
          // if the connector is part of a bus connector
          if (pStartConnectorComponent->isInBus()) {
            pStartBusConnectorComponent = getConnectorComponent(pStartComponent, pStartConnectorComponent->getBusComponent()->getName());
          }
        } else {
          pStartConnectorComponent = pStartComponent;
          pStartBusConnectorComponent = pStartConnectorComponent;
          // if the connector is part of a bus connector
          if (pStartConnectorComponent->isInBus()) {
            pStartBusConnectorComponent = pStartConnectorComponent->getBusComponent();
          }
        }

        // get end component
        QStringList endConnectionList = StringHandler::makeVariableParts(QString(pConnections[i]->conB));
        if (endConnectionList.size() < 1) {
          continue;
        }
        Component *pEndComponent = mpDiagramGraphicsView->getComponentObject(endConnectionList.at(0));
        if (!pEndComponent) {
          pMessagesWidget->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                     GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION)
                                                     .arg(endConnectionList.at(0)).arg(pConnections[i]->conB),
                                                     Helper::scriptingKind, Helper::errorLevel));
          continue;
        }
        Component *pEndConnectorComponent, *pEndBusConnectorComponent;
        if (endConnectionList.size() > 1) {
          // get end connector component
          QString endConnectorName = StringHandler::removeFirstWordAfterDot(QString(pConnections[i]->conB));
          pEndConnectorComponent = getConnectorComponent(pEndComponent, endConnectorName);
          if (!pEndConnectorComponent) {
            pMessagesWidget->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                       GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION)
                                                       .arg(endConnectorName).arg(pConnections[i]->conB),
                                                       Helper::scriptingKind, Helper::errorLevel));
            continue;
          }
          pEndBusConnectorComponent = pEndConnectorComponent;
          // if the connector is part of a bus connector
          if (pEndConnectorComponent->isInBus()) {
            pEndBusConnectorComponent = getConnectorComponent(pEndComponent, pEndConnectorComponent->getBusComponent()->getName());
          }
        } else {
          pEndConnectorComponent = pEndComponent;
          pEndBusConnectorComponent = pEndConnectorComponent;
          // if the connector is part of a bus connector
          if (pEndConnectorComponent->isInBus()) {
            pEndBusConnectorComponent = pEndConnectorComponent->getBusComponent();
          }
        }

        // default connection annotation
        QString annotation = QString("{Line(true,{0.0,0.0},0,%1,{0,0,0},LinePattern.Solid,0.25,{Arrow.None,Arrow.None},3,Smooth.None)}");
        QStringList shapesList;
        QString point = QString("{%1,%2}");
        QStringList points;
        if (pConnections[i]->geometry && pConnections[i]->geometry->n > 0) {
          for (unsigned int j = 0 ; j < pConnections[i]->geometry->n ; j++) {
            points.append(point.arg(pConnections[i]->geometry->pointsX[j]).arg(pConnections[i]->geometry->pointsY[j]));
          }
        }
        QPointF startPoint = pStartBusConnectorComponent->mapToScene(pStartBusConnectorComponent->boundingRect().center());
        points.prepend(point.arg(startPoint.x()).arg(startPoint.y()));
        QPointF endPoint = pEndBusConnectorComponent->mapToScene(pEndBusConnectorComponent->boundingRect().center());
        points.append(point.arg(endPoint.x()).arg(endPoint.y()));
        QString pointsString = QString("{%1}").arg(points.join(","));
        shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(QString(annotation).arg(pointsString)), '(', ')');
        // Now parse the shapes available in list
        QString lineShape = "";
        foreach (QString shape, shapesList) {
          if (shape.startsWith("Line")) {
            lineShape = shape.mid(QString("Line").length());
            lineShape = StringHandler::removeFirstLastParentheses(lineShape);
            break;  // break the loop once we have got the line annotation.
          }
        }

        LineAnnotation *pConnectionLineAnnotation = new LineAnnotation(lineShape, pStartBusConnectorComponent,
                                                                       pEndBusConnectorComponent, mpDiagramGraphicsView);
        if (pStartConnectorComponent->getLibraryTreeItem()) {
          pConnectionLineAnnotation->setStartComponentName(pStartConnectorComponent->getLibraryTreeItem()->getNameStructure());
        }
        if (pEndConnectorComponent->getLibraryTreeItem()) {
          pConnectionLineAnnotation->setEndComponentName(pEndConnectorComponent->getLibraryTreeItem()->getNameStructure());
        }
        pConnectionLineAnnotation->setOMSConnectionType(pConnections[i]->type);
        mpUndoStack->push(new AddConnectionCommand(pConnectionLineAnnotation, false));
        // Check if the connectors of the connection belongs to a bus
        if (pStartConnectorComponent->isInBus() && pEndConnectorComponent->isInBus()) {
          pConnectionLineAnnotation->setVisible(false);
        }
        // Check if bus connection
        if (pConnections[i]->type == oms_connection_bus || pConnections[i]->type == oms_connection_tlm) {
          pConnectionLineAnnotation->setLineThickness(0.5);
        }
      }
    }
  }
}

/*!
 * \brief ModelWidget::associateBusWithConnector
 * Helper function for ModelWidget::associateBusWithConnector(busName, connectorName)
 * \param busName
 * \param connectorName
 * \param pGraphicsView
 */
void ModelWidget::associateBusWithConnector(QString busName, QString connectorName, GraphicsView *pGraphicsView)
{
  // get the bus component
  Component *pBusComponent = pGraphicsView->getComponentObject(busName);
  // get the connector component
  Component *pConnectorComponent = pGraphicsView->getComponentObject(connectorName);
  if (pBusComponent && pConnectorComponent) {
    pConnectorComponent->setBusComponent(pBusComponent);
  }
}

/*!
 * \brief ModelWidget::dissociateBusWithConnector
 * Helper function for ModelWidget::dissociateBusWithConnector(busName, connectorName)
 * \param busName
 * \param connectorName
 * \param pGraphicsView
 */
void ModelWidget::dissociateBusWithConnector(QString busName, QString connectorName, GraphicsView *pGraphicsView)
{
  // get the bus component
  Component *pBusComponent = pGraphicsView->getComponentObject(busName);
  Component *pConnectorComponent = pGraphicsView->getComponentObject(connectorName);
  if (pBusComponent && pConnectorComponent) {
    pConnectorComponent->setBusComponent(0);
  }
}

/*!
 * \brief ModelWidget::associateBusWithConnectors
 * Helper function for ModelWidget::associateBusWithConnectors(busName)
 * \param pBusComponent
 * \param pGraphicsView
 */
void ModelWidget::associateBusWithConnectors(Component *pBusComponent, GraphicsView *pGraphicsView)
{
  if (pBusComponent && pBusComponent->getLibraryTreeItem() && pBusComponent->getLibraryTreeItem()->getOMSBusConnector()) {
    oms_busconnector_t *pBusConnector = pBusComponent->getLibraryTreeItem()->getOMSBusConnector();
    if (pBusConnector->connectors) {
      for (int i = 0 ; pBusConnector->connectors[i] ; i++) {
        Component *pConnectorComponent = pGraphicsView->getComponentObject(QString(pBusConnector->connectors[i]));
        if (pConnectorComponent) {
          pConnectorComponent->setBusComponent(pBusComponent);
        }
      }
    }
  } else if (pBusComponent && pBusComponent->getLibraryTreeItem() && pBusComponent->getLibraryTreeItem()->getOMSTLMBusConnector()) {
    oms_tlmbusconnector_t *pTLMBusConnector = pBusComponent->getLibraryTreeItem()->getOMSTLMBusConnector();
    if (pTLMBusConnector->connectornames) {
      for (int i = 0 ; pTLMBusConnector->connectornames[i] ; i++) {
        Component *pConnectorComponent = pGraphicsView->getComponentObject(QString(pTLMBusConnector->connectornames[i]));
        if (pConnectorComponent) {
          pConnectorComponent->setBusComponent(pBusComponent);
        }
      }
    }
  }
}

/*!
 * \brief ModelWidget::showIconView
 * \param checked
 * Slot activated when mpIconViewToolButton toggled SIGNAL is raised. Shows the icon view.
 */
void ModelWidget::showIconView(bool checked)
{
  // validate the modelica text before switching to icon view
  if (checked) {
    if (!validateText(&mpLibraryTreeItem)) {
      mpTextViewToolButton->setChecked(true);
      return;
    }
  }
  QMdiSubWindow *pSubWindow = mpModelWidgetContainer->getCurrentMdiSubWindow();
  if (pSubWindow) {
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/model.svg"));
  }
  mpModelWidgetContainer->currentModelWidgetChanged(mpModelWidgetContainer->getCurrentMdiSubWindow());
  mpIconGraphicsView->setFocus(Qt::ActiveWindowFocusReason);
  if (!checked || (checked && mpIconGraphicsView->isVisible())) {
    return;
  }
  mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::Icon));
  mpDiagramGraphicsView->hide();
  if (mpEditor) {
    mpEditor->hide();
  }
  mpIconGraphicsView->show();
  mpIconGraphicsView->setFocus();
  mpModelWidgetContainer->setPreviousViewType(StringHandler::Icon);
  updateUndoRedoActions();
  MainWindow::instance()->getPositionLabel()->clear();
}

/*!
 * \brief ModelWidget::showDiagramView
 * \param checked
 * Slot activated when mpDiagramViewToolButton toggled SIGNAL is raised. Shows the diagram view.
 */
void ModelWidget::showDiagramView(bool checked)
{
  // validate the modelica text before switching to diagram view
  if (checked) {
    if (!validateText(&mpLibraryTreeItem)) {
      mpTextViewToolButton->setChecked(true);
      return;
    }
  }
  QMdiSubWindow *pSubWindow = mpModelWidgetContainer->getCurrentMdiSubWindow();
  if (pSubWindow) {
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/modeling.png"));
  }
  mpModelWidgetContainer->currentModelWidgetChanged(mpModelWidgetContainer->getCurrentMdiSubWindow());
  mpDiagramGraphicsView->setFocus(Qt::ActiveWindowFocusReason);
  if (!checked || (checked && mpDiagramGraphicsView->isVisible())) {
    return;
  }
  mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::Diagram));
  if (mpIconGraphicsView) {
    mpIconGraphicsView->hide();
  }
  if (mpEditor) {
    mpEditor->hide();
  }
  mpDiagramGraphicsView->show();
  mpDiagramGraphicsView->setFocus();
  mpModelWidgetContainer->setPreviousViewType(StringHandler::Diagram);
  updateUndoRedoActions();
  MainWindow::instance()->getPositionLabel()->clear();
}

/*!
 * \brief ModelWidget::showTextView
 * \param checked
 * Slot activated when mpTextViewToolButton toggled SIGNAL is raised. Shows the text view.
 */
void ModelWidget::showTextView(bool checked)
{
  if (!checked || (checked && mpEditor->isVisible())) {
    return;
  }
  if (QMdiSubWindow *pSubWindow = mpModelWidgetContainer->getCurrentMdiSubWindow()) {
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/modeltext.svg"));
  }
  mpModelWidgetContainer->currentModelWidgetChanged(mpModelWidgetContainer->getCurrentMdiSubWindow());
  mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::ModelicaText));
  if (mpIconGraphicsView) {
    mpIconGraphicsView->hide();
  }
  mpDiagramGraphicsView->hide();
  if (mpEditor) {
    mpEditor->show();
    mpEditor->getPlainTextEdit()->setFocus(Qt::ActiveWindowFocusReason);
    mpEditor->getPlainTextEdit()->updateCursorPosition();
  }
  mpModelWidgetContainer->setPreviousViewType(StringHandler::ModelicaText);
  updateUndoRedoActions();
}

/*!
 * \brief ModelWidget::removeDynamicResults
 * Check if resultFileName is empty or equals mResultFileName.
 * Update the model widget with static values from the model
 * and empty mResultFileName.
 */
void ModelWidget::removeDynamicResults(QString resultFileName)
{
  if (mResultFileName.isEmpty()) {
    // nothing to do
    return;
  }
  if (resultFileName.isEmpty() or resultFileName == mResultFileName) {
    mResultFileName = "";
    foreach (Component *component, mpDiagramGraphicsView->getInheritedComponentsList()) {
      component->componentParameterHasChanged();
    }
    foreach (Component *component, mpDiagramGraphicsView->getComponentsList()) {
      component->componentParameterHasChanged();
    }
  }
}

void ModelWidget::makeFileWritAble()
{
  const QString &fileName = mpLibraryTreeItem->getFileName();
  const bool permsOk = QFile::setPermissions(fileName, QFile::permissions(fileName) | QFile::WriteUser);
  if (!permsOk)
    QMessageBox::warning(this, tr("Cannot Set Permissions"),  tr("Cannot set permissions to writable."));
  else
  {
    mpLibraryTreeItem->setReadOnly(false);
    mpFileLockToolButton->setText(tr("File is writable"));
    mpFileLockToolButton->setIcon(QIcon(":/Resources/icons/unlock.svg"));
    mpFileLockToolButton->setEnabled(false);
    mpFileLockToolButton->setToolTip(mpFileLockToolButton->text());
  }
}

void ModelWidget::showDocumentationView()
{
  // validate the modelica text before switching to documentation view
  if (!validateText(&mpLibraryTreeItem)) {
    mpTextViewToolButton->setChecked(true);
    return;
  }
  MainWindow::instance()->getDocumentationWidget()->showDocumentation(getLibraryTreeItem());
  bool state = MainWindow::instance()->getDocumentationDockWidget()->blockSignals(true);
  MainWindow::instance()->getDocumentationDockWidget()->show();
  MainWindow::instance()->getDocumentationDockWidget()->blockSignals(state);
}

/*!
 * \brief ModelWidget::compositeModelEditorTextChanged
 * Called when CompositeModelEditor text has been changed by user manually.\n
 * Updates the LibraryTreeItem and ModelWidget with new changes.
 * \return
 */
bool ModelWidget::compositeModelEditorTextChanged()
{
  MessageHandler *pMessageHandler = new MessageHandler;
  Utilities::parseCompositeModelText(pMessageHandler, mpEditor->getPlainTextEdit()->toPlainText());
  if (pMessageHandler->isFailed()) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::CompositeModel, getLibraryTreeItem()->getName(), false,
                                                          pMessageHandler->line(), pMessageHandler->column(), 0, 0,
                                                          pMessageHandler->statusMessage(), Helper::syntaxKind, Helper::errorLevel));
    delete pMessageHandler;
    return false;
  }
  delete pMessageHandler;
  // update the xml document with new accepted text.
  CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpEditor);
  pCompositeModelEditor->setXmlDocumentContent(mpEditor->getPlainTextEdit()->toPlainText());
  /* get the model components and connectors */
  reDrawModelWidget();
  return true;
}

/*!
 * \brief ModelWidget::handleCanUndoChanged
 * Enables/disables the Edit menu Undo action depending on the stack situation.
 * \param canUndo
 */
void ModelWidget::handleCanUndoChanged(bool canUndo)
{
  Q_UNUSED(canUndo);
  updateUndoRedoActions();
}

/*!
 * \brief ModelWidget::handleCanRedoChanged
 * Enables/disables the Edit menu Redo action depending on the stack situation.
 * \param canRedo
 */
void ModelWidget::handleCanRedoChanged(bool canRedo)
{
  Q_UNUSED(canRedo);
  updateUndoRedoActions();
}

void ModelWidget::closeEvent(QCloseEvent *event)
{
  Q_UNUSED(event);
  mpModelWidgetContainer->removeSubWindow(this);
}

/*!
 * \brief addCloseActionsToSubWindowSystemMenu
 * Adds the "Close All Windows" and "Close All Windows But This" actions to QMdiSubWindow system menu.
 */
void addCloseActionsToSubWindowSystemMenu(QMdiSubWindow *pMdiSubWindow)
{
  /* ticket:3295 Add the "Close All Windows" and "Close All Windows But This" to system menu. */
  QMenu *pMenu = pMdiSubWindow->systemMenu();
  pMenu->addAction(MainWindow::instance()->getCloseAllWindowsAction());
  pMenu->addAction(MainWindow::instance()->getCloseAllWindowsButThisAction());
}

ModelWidgetContainer::ModelWidgetContainer(QWidget *pParent)
  : QMdiArea(pParent), mPreviousViewType(StringHandler::NoView), mShowGridLines(true)
{
  setHorizontalScrollBarPolicy(Qt::ScrollBarAsNeeded);
  setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
  setActivationOrder(QMdiArea::ActivationHistoryOrder);
  setDocumentMode(true);
#if QT_VERSION >= 0x040800
  setTabsClosable(true);
#endif
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getModelingViewMode().compare(Helper::subWindow) == 0) {
    setViewMode(QMdiArea::SubWindowView);
  } else {
    setViewMode(QMdiArea::TabbedView);
  }
  // create a Model Swicther Dialog
  mpModelSwitcherDialog = new QDialog(this, Qt::Popup);
  mpRecentModelsList = new QListWidget(this);
  mpRecentModelsList->setItemDelegate(new ItemDelegate(mpRecentModelsList));
  mpRecentModelsList->setTextElideMode(Qt::ElideMiddle);
  mpRecentModelsList->setViewMode(QListView::ListMode);
  mpRecentModelsList->setMovement(QListView::Static);
  connect(mpRecentModelsList, SIGNAL(itemClicked(QListWidgetItem*)), SLOT(openRecentModelWidget(QListWidgetItem*)));
  QGridLayout *pModelSwitcherLayout = new QGridLayout;
  pModelSwitcherLayout->setContentsMargins(0, 0, 0, 0);
  pModelSwitcherLayout->addWidget(mpRecentModelsList, 0, 0);
  mpModelSwitcherDialog->setLayout(pModelSwitcherLayout);
  // install QApplication event filter to handle the ctrl+tab and ctrl+shift+tab
  QApplication::instance()->installEventFilter(this);
  connect(this, SIGNAL(subWindowActivated(QMdiSubWindow*)), SLOT(currentModelWidgetChanged(QMdiSubWindow*)));
  connect(this, SIGNAL(subWindowActivated(QMdiSubWindow*)), MainWindow::instance(), SLOT(updateModelSwitcherMenu(QMdiSubWindow*)));
  connect(this, SIGNAL(subWindowActivated(QMdiSubWindow*)), SLOT(updateThreeDViewer(QMdiSubWindow*)));
  // add actions
  connect(MainWindow::instance()->getSaveAction(), SIGNAL(triggered()), SLOT(saveModelWidget()));
  connect(MainWindow::instance()->getSaveAsAction(), SIGNAL(triggered()), SLOT(saveAsModelWidget()));
  connect(MainWindow::instance()->getSaveTotalAction(), SIGNAL(triggered()), SLOT(saveTotalModelWidget()));
  connect(MainWindow::instance()->getPrintModelAction(), SIGNAL(triggered()), SLOT(printModel()));
  connect(MainWindow::instance()->getSimulationParamsAction(), SIGNAL(triggered()), SLOT(showSimulationParams()));
  connect(MainWindow::instance()->getAlignInterfacesAction(), SIGNAL(triggered()), SLOT(alignInterfaces()));
  connect(MainWindow::instance()->getAddSystemAction(), SIGNAL(triggered()), SLOT(addSystem()));
  connect(MainWindow::instance()->getAddOrEditIconAction(), SIGNAL(triggered()), SLOT(addOrEditIcon()));
  connect(MainWindow::instance()->getDeleteIconAction(), SIGNAL(triggered()), SLOT(deleteIcon()));
  connect(MainWindow::instance()->getAddConnectorAction(), SIGNAL(triggered()), SLOT(addConnector()));
  connect(MainWindow::instance()->getAddBusAction(), SIGNAL(triggered()), SLOT(addBus()));
  connect(MainWindow::instance()->getAddTLMBusAction(), SIGNAL(triggered()), SLOT(addTLMBus()));
  connect(MainWindow::instance()->getAddSubModelAction(), SIGNAL(triggered()), SLOT(addSubModel()));
}

void ModelWidgetContainer::addModelWidget(ModelWidget *pModelWidget, bool checkPreferedView, StringHandler::ViewType viewType)
{
  if (pModelWidget->isVisible() || pModelWidget->isMinimized()) {
    QList<QMdiSubWindow*> subWindowsList = subWindowList(QMdiArea::ActivationHistoryOrder);
    for (int i = subWindowsList.size() - 1 ; i >= 0 ; i--) {
      ModelWidget *pSubModelWidget = qobject_cast<ModelWidget*>(subWindowsList.at(i)->widget());
      if (pSubModelWidget == pModelWidget) {
        if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
          pModelWidget->loadDiagramView();
          pModelWidget->loadConnections();
        }
        pModelWidget->createModelWidgetComponents();
        pModelWidget->show();
        setActiveSubWindow(subWindowsList.at(i));
        break;
      }
    }
  } else {
    int subWindowsSize = subWindowList(QMdiArea::ActivationHistoryOrder).size();
    QMdiSubWindow *pSubWindow = addSubWindow(pModelWidget);
    addCloseActionsToSubWindowSystemMenu(pSubWindow);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/modeling.png"));
    if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
      pModelWidget->loadDiagramView();
      pModelWidget->loadConnections();
    }
    pModelWidget->createModelWidgetComponents();
    pModelWidget->show();
    if (subWindowsSize == 0) {
      pModelWidget->setWindowState(Qt::WindowMaximized);
    }
    setActiveSubWindow(pSubWindow);
    if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
      pModelWidget->getDiagramViewToolButton()->setChecked(true);
    }
  }
  if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Text) {
    pModelWidget->getTextViewToolButton()->setChecked(true);
    if (!pModelWidget->getEditor()->isVisible()) {
      pModelWidget->getEditor()->show();
    }
    pModelWidget->getEditor()->getPlainTextEdit()->setFocus(Qt::ActiveWindowFocusReason);
  } else if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    if (pModelWidget->getModelWidgetContainer()->getPreviousViewType() != StringHandler::NoView) {
      loadPreviousViewType(pModelWidget);
    } else {
      pModelWidget->getDiagramViewToolButton()->setChecked(true);
    }
  }
  pModelWidget->updateViewButtonsBasedOnAccess();
  if (!checkPreferedView || pModelWidget->getLibraryTreeItem()->getLibraryType() != LibraryTreeItem::Modelica) {
    return;
  }
  // show the view user wants
  if (viewType == StringHandler::Icon) {
    pModelWidget->getIconViewToolButton()->setChecked(true);
  } else if (viewType == StringHandler::Diagram) {
    pModelWidget->getDiagramViewToolButton()->setChecked(true);
  } else if (viewType == StringHandler::ModelicaText) {
    pModelWidget->getTextViewToolButton()->setChecked(true);
  } else {
    // get the preferred view to display
    QString preferredView = pModelWidget->getLibraryTreeItem()->mClassInformation.preferredView;
    if (!preferredView.isEmpty()) {
      if (preferredView.compare("text") == 0) {
        pModelWidget->getTextViewToolButton()->setChecked(true);
      } else {
        pModelWidget->getDiagramViewToolButton()->setChecked(true);
      }
    } else if (pModelWidget->getModelWidgetContainer()->getPreviousViewType() != StringHandler::NoView) {
      loadPreviousViewType(pModelWidget);
    } else {
      QString defaultView = OptionsDialog::instance()->getGeneralSettingsPage()->getDefaultView();
      if (defaultView.compare(Helper::iconView) == 0) {
        pModelWidget->getIconViewToolButton()->setChecked(true);
      } else if (defaultView.compare(Helper::textView) == 0) {
        pModelWidget->getTextViewToolButton()->setChecked(true);
      } else {
        pModelWidget->getDiagramViewToolButton()->setChecked(true);
      }
    }
  }
  pModelWidget->updateViewButtonsBasedOnAccess();
}

/*!
 * \brief ModelWidgetContainer::getCurrentModelWidget
 * Returns the current ModelWidget.
 * \return
 */
ModelWidget* ModelWidgetContainer::getCurrentModelWidget()
{
  if (subWindowList(QMdiArea::ActivationHistoryOrder).size() == 0) {
    return 0;
  } else {
    return qobject_cast<ModelWidget*>(subWindowList(QMdiArea::ActivationHistoryOrder).last()->widget());
  }
}

/*!
 * \brief ModelWidgetContainer::getModelWidget
 * Returns the ModelWidget for className or NULL if not found.
 */
ModelWidget* ModelWidgetContainer::getModelWidget(const QString& className)
{
  foreach (QMdiSubWindow *pSubWindow, subWindowList()) {
    ModelWidget *pModelWidget = qobject_cast<ModelWidget*>(pSubWindow->widget());
    if (className == pModelWidget->getLibraryTreeItem()->getNameStructure())
      return pModelWidget;
  }
  return NULL;
}

/*!
 * \brief ModelWidgetContainer::getCurrentMdiSubWindow
 * Returns the current QMdiSubWindow.
 * \return
 */
QMdiSubWindow* ModelWidgetContainer::getCurrentMdiSubWindow()
{
  if (subWindowList(QMdiArea::ActivationHistoryOrder).size() == 0) {
    return 0;
  } else {
    return subWindowList(QMdiArea::ActivationHistoryOrder).last();
  }
}

/*!
 * \brief ModelWidgetContainer::getMdiSubWindow
 * Returns the QMdiSubWindow for a specific ModelWidget.
 * \param pModelWidget
 * \return
 */
QMdiSubWindow* ModelWidgetContainer::getMdiSubWindow(ModelWidget *pModelWidget)
{
  if (subWindowList(QMdiArea::ActivationHistoryOrder).size() == 0) {
    return 0;
  }
  QList<QMdiSubWindow*> mdiSubWindowsList = subWindowList(QMdiArea::ActivationHistoryOrder);
  foreach (QMdiSubWindow *pMdiSubWindow, mdiSubWindowsList) {
    if (pMdiSubWindow->widget() == pModelWidget) {
      return pMdiSubWindow;
    }
  }
  return 0;
}

bool ModelWidgetContainer::eventFilter(QObject *object, QEvent *event)
{
  /* Ticket:4164
   * Open the file passed as an argument to OSX.
   * QFileOpenEvent is only available in OSX.
   */
  if (event->type() == QEvent::FileOpen && qobject_cast<QApplication*>(object)) {
    QFileOpenEvent *pFileOpenEvent = static_cast<QFileOpenEvent*>(event);
    if (!pFileOpenEvent->file().isEmpty()) {
      // if path is relative make it absolute
      QFileInfo fileInfo (pFileOpenEvent->file());
      QString fileName = pFileOpenEvent->file();
      if (fileInfo.isRelative()) {
        fileName = QString("%1/%2").arg(QDir::currentPath()).arg(fileName);
      }
      fileName = fileName.replace("\\", "/");
      if (QFile::exists(fileName)) {
        MainWindow::instance()->getLibraryWidget()->openFile(fileName);
      }
    }
  }
  if (!object || isHidden() || qApp->activeWindow() != MainWindow::instance()) {
    return QMdiArea::eventFilter(object, event);
  }
  /* If focus is set to LibraryTreeView, DocumentationViewer, QMenuBar etc. then try to validate the text because user might have
   * updated the text manually.
   */
  if ((event->type() == QEvent::MouseButtonPress && qobject_cast<QMenuBar*>(object)) ||
      (event->type() == QEvent::FocusIn && (qobject_cast<LibraryTreeView*>(object) || qobject_cast<DocumentationViewer*>(object)))) {
    ModelWidget *pModelWidget = getCurrentModelWidget();
    if (pModelWidget && pModelWidget->getLibraryTreeItem()) {
      LibraryTreeItem *pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
      /* if Model text is changed manually by user then validate it. */
      if (!pModelWidget->validateText(&pLibraryTreeItem)) {
        return true;
      }
    }
  }
  // Global key events with Ctrl modifier.
  if (event->type() == QEvent::KeyPress || event->type() == QEvent::KeyRelease) {
    if (subWindowList(QMdiArea::ActivationHistoryOrder).size() > 0) {
      QKeyEvent *keyEvent = static_cast<QKeyEvent*>(event);
      // Ingore key events without a Ctrl modifier (except for press/release on the modifier itself).
#ifdef Q_OS_MAC
      if (!(keyEvent->modifiers() & Qt::AltModifier) && keyEvent->key() != Qt::Key_Alt) {
#else
      if (!(keyEvent->modifiers() & Qt::ControlModifier) && keyEvent->key() != Qt::Key_Control) {
#endif
        return QMdiArea::eventFilter(object, event);
      }
      // check key press
      const bool keyPress = (event->type() == QEvent::KeyPress) ? true : false;
      ModelWidget *pCurrentModelWidget = getCurrentModelWidget();
      switch (keyEvent->key()) {
#ifdef Q_OS_MAC
        case Qt::Key_Alt:
#else
        case Qt::Key_Control:
#endif
          if (keyPress) {
            // add items to mpRecentModelsList to show in mpModelSwitcherDialog
            mpRecentModelsList->clear();
            QList<QMdiSubWindow*> subWindowsList = subWindowList(QMdiArea::ActivationHistoryOrder);
            for (int i = subWindowsList.size() - 1 ; i >= 0 ; i--) {
              ModelWidget *pModelWidget = qobject_cast<ModelWidget*>(subWindowsList.at(i)->widget());
              QListWidgetItem *listItem = new QListWidgetItem(mpRecentModelsList);
              if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
                listItem->setText(pModelWidget->getLibraryTreeItem()->getNameStructure());
              } else {
                listItem->setText(pModelWidget->getLibraryTreeItem()->getName());
              }
              listItem->setData(Qt::UserRole, pModelWidget->getLibraryTreeItem()->getNameStructure());
            }
          } else {
            if (!mpRecentModelsList->selectedItems().isEmpty()) {
              if (!openRecentModelWidget(mpRecentModelsList->selectedItems().at(0))) {
                return true;
              }
            }
            mpModelSwitcherDialog->hide();
          }
          break;
        case Qt::Key_1: // Ctrl+1 switches to icon view
          if (pCurrentModelWidget && pCurrentModelWidget->getIconGraphicsView()) {
            pCurrentModelWidget->getIconViewToolButton()->setChecked(true);
          }
          return true;
        case Qt::Key_2: // Ctrl+2 switches to diagram view
          if (pCurrentModelWidget && pCurrentModelWidget->getDiagramGraphicsView()) {
            pCurrentModelWidget->getDiagramViewToolButton()->setChecked(true);
          }
          return true;
        case Qt::Key_3: // Ctrl+3 switches to text view
          if (pCurrentModelWidget && pCurrentModelWidget->getEditor()) {
            pCurrentModelWidget->getTextViewToolButton()->setChecked(true);
          }
          return true;
        case Qt::Key_4: // Ctrl+4 shows the documentation view
          if (pCurrentModelWidget && pCurrentModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
            pCurrentModelWidget->showDocumentationView();
          }
          return true;
        case Qt::Key_Tab:
        case Qt::Key_Backtab:
          if (keyPress) {
            if (keyEvent->key() == Qt::Key_Tab) {
              changeRecentModelsListSelection(true);
            } else {
              changeRecentModelsListSelection(false);
            }
          }
          return true;
#ifndef QT_NO_RUBBERBAND
        case Qt::Key_Escape:
          mpModelSwitcherDialog->hide();
          break;
#endif
        default:
          break;
      }
      return QMdiArea::eventFilter(object, event);
    }
  }
  return QMdiArea::eventFilter(object, event);
}

void ModelWidgetContainer::changeRecentModelsListSelection(bool moveDown)
{
  mpModelSwitcherDialog->show();
  mpRecentModelsList->setFocus();
  int count = mpRecentModelsList->count();
  if (count < 1) {
    return;
  }
  int currentRow = mpRecentModelsList->currentRow();
  if (moveDown) {
    if (currentRow < count - 1) {
      mpRecentModelsList->setCurrentRow(currentRow + 1);
    } else {
      mpRecentModelsList->setCurrentRow(0);
    }
  } else if (!moveDown) {
    if (currentRow == 0) {
      mpRecentModelsList->setCurrentRow(count - 1);
    } else {
      mpRecentModelsList->setCurrentRow(currentRow - 1);
    }
  }
}

#if !defined(WITHOUT_OSG)
/*!
 * \brief ModelWidgetContainer::updateThreeDViewer
 * Updates the ThreeDViewer with the visualization of the current ModelWidget.
 * \param pModelWidget
 */
void ModelWidgetContainer::updateThreeDViewer(ModelWidget *pModelWidget)
{
  if (pModelWidget->getLibraryTreeItem() && pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    // write dummy csv file for 3d view
    QString fileName;
    if (pModelWidget->getLibraryTreeItem()->getFileName().isEmpty()) {
      fileName = pModelWidget->getLibraryTreeItem()->getName();
    } else {
      QFileInfo fileInfo(pModelWidget->getLibraryTreeItem()->getFileName());
      fileName = fileInfo.baseName();
    }
    QString resultFileName = QString("%1/%2.csv").arg(Utilities::tempDirectory()).arg(fileName);
    QString visualXMLFileName = QString("%1/%2_visual.xml").arg(Utilities::tempDirectory()).arg(fileName);
    // write dummy csv file and visualization file
    if (pModelWidget->writeCoSimulationResultFile(resultFileName) && pModelWidget->writeVisualXMLFile(visualXMLFileName, true)) {
      MainWindow::instance()->getThreeDViewer()->stashView();
      bool state = MainWindow::instance()->getThreeDViewerDockWidget()->blockSignals(true);
      MainWindow::instance()->getThreeDViewerDockWidget()->show();
      MainWindow::instance()->getThreeDViewerDockWidget()->blockSignals(state);
      MainWindow::instance()->getThreeDViewer()->clearView();
      MainWindow::instance()->getThreeDViewer()->openAnimationFile(resultFileName,true);
      MainWindow::instance()->getThreeDViewer()->popView();
    } else {
      MainWindow::instance()->getThreeDViewer()->clearView();
    }
  } else {
    if (MainWindow::instance()->isThreeDViewerInitialized()) {
      MainWindow::instance()->getThreeDViewer()->clearView();
    }
  }
}
#endif

/*!
 * \brief ModelWidgetContainer::loadPreviousViewType
 * Opens the ModelWidget using the previous view type used by user.
 * \param pModelWidget
 */
void ModelWidgetContainer::loadPreviousViewType(ModelWidget *pModelWidget)
{
  if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    switch (pModelWidget->getModelWidgetContainer()->getPreviousViewType()) {
      case StringHandler::Icon:
        pModelWidget->getIconViewToolButton()->setChecked(true);
        break;
      case StringHandler::ModelicaText:
        pModelWidget->getTextViewToolButton()->setChecked(true);
        break;
      case StringHandler::Diagram:
      default:
        pModelWidget->getDiagramViewToolButton()->setChecked(true);
        break;
    }
  } else if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    switch (pModelWidget->getModelWidgetContainer()->getPreviousViewType()) {
      case StringHandler::ModelicaText:
        pModelWidget->getTextViewToolButton()->setChecked(true);
        break;
      case StringHandler::Icon:
      case StringHandler::Diagram:
      default:
        pModelWidget->getDiagramViewToolButton()->setChecked(true);
        break;
    }
  } else if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Text) {
    pModelWidget->getTextViewToolButton()->setChecked(true);
  }
}

/*!
 * \brief ModelWidgetContainer::openRecentModelWidget
 * Slot activated when mpRecentModelsList itemClicked SIGNAL is raised.\n
 * Before switching to new ModelWidget try to update the class contents if user has changed anything.
 * \param pListWidgetItem
 */
bool ModelWidgetContainer::openRecentModelWidget(QListWidgetItem *pListWidgetItem)
{
  /* if Model text is changed manually by user then validate it before opening recent ModelWidget. */
  ModelWidget *pModelWidget = getCurrentModelWidget();
  if (pModelWidget && pModelWidget->getLibraryTreeItem()) {
    LibraryTreeItem *pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
    if (!pModelWidget->validateText(&pLibraryTreeItem)) {
      return false;
    }
  }
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(pListWidgetItem->data(Qt::UserRole).toString());
  addModelWidget(pLibraryTreeItem->getModelWidget(), false);
  return true;
}

/*!
 * \brief ModelWidgetContainer::currentModelWidgetChanged
 * Updates the toolbar and menus items depending on what kind of ModelWidget is activated.
 * \param pSubWindow
 */
void ModelWidgetContainer::currentModelWidgetChanged(QMdiSubWindow *pSubWindow)
{
  bool enabled = false;
  bool modelica = false;
  bool compositeModel = false;
  bool oms = false;
  bool omsModel = false;
  bool omsSystem = false;
  bool omsSubmodel = false;
  bool omsConnector = false;
  bool gitWorkingDirectory = false;
  bool iconGraphicsView = false;
  bool diagramGraphicsView = false;
  bool textView = false;
  ModelWidget *pModelWidget = 0;
  LibraryTreeItem *pLibraryTreeItem = 0;
  if (pSubWindow) {
    enabled = true;
    pModelWidget = qobject_cast<ModelWidget*>(pSubWindow->widget());
    pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
    iconGraphicsView = pModelWidget->getIconViewToolButton()->isChecked();
    diagramGraphicsView = pModelWidget->getDiagramViewToolButton()->isChecked();
    textView = pModelWidget->getTextViewToolButton()->isChecked();
    // check for git working directory
    gitWorkingDirectory = !pLibraryTreeItem->getFileName().isEmpty() && GitCommands::instance()->isSavedUnderGitRepository(pLibraryTreeItem->getFileName());
    if (pLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica) {
      modelica = true;
    } else if (pLibraryTreeItem->getLibraryType() == LibraryTreeItem::CompositeModel) {
      compositeModel = true;
    } else if (pLibraryTreeItem->getLibraryType() == LibraryTreeItem::OMS) {
      oms = true;
      omsModel = pLibraryTreeItem->isTopLevel() ? true : false;
      omsSystem = false;
      omsSubmodel = false;
      omsConnector = false;
      if (pLibraryTreeItem->isSystemElement()) {
        omsSystem = true;
      } else if (pLibraryTreeItem->isComponentElement()) {
        omsSubmodel = true;
      }
      if (pLibraryTreeItem->getOMSConnector()) {
        omsConnector = true;
      }
    }
  }
  // update the actions of the menu and toolbars
  MainWindow::instance()->getSaveAction()->setEnabled(enabled);
  MainWindow::instance()->getSaveAsAction()->setEnabled(enabled);
  //  MainWindow::instance()->getSaveAllAction()->setEnabled(enabled);
  MainWindow::instance()->getSaveTotalAction()->setEnabled(enabled && modelica);
  MainWindow::instance()->getShowGridLinesAction()->setEnabled(enabled && (modelica || compositeModel || oms) && !textView && !pModelWidget->getLibraryTreeItem()->isSystemLibrary());
  MainWindow::instance()->getResetZoomAction()->setEnabled(enabled && (modelica || compositeModel || oms));
  MainWindow::instance()->getZoomInAction()->setEnabled(enabled && (modelica || compositeModel || oms));
  MainWindow::instance()->getZoomOutAction()->setEnabled(enabled && (modelica || compositeModel || oms));
  MainWindow::instance()->getLineShapeAction()->setEnabled(enabled && modelica && !textView);
  MainWindow::instance()->getPolygonShapeAction()->setEnabled(enabled && modelica && !textView);
  MainWindow::instance()->getRectangleShapeAction()->setEnabled(enabled && modelica && !textView);
  MainWindow::instance()->getEllipseShapeAction()->setEnabled(enabled && modelica && !textView);
  MainWindow::instance()->getTextShapeAction()->setEnabled(enabled && modelica && !textView);
  MainWindow::instance()->getBitmapShapeAction()->setEnabled(enabled && modelica && !textView);
  MainWindow::instance()->getConnectModeAction()->setEnabled(enabled && (modelica || compositeModel || (oms && !(omsSubmodel || omsConnector))) && !textView);
  MainWindow::instance()->getTransitionModeAction()->setEnabled(enabled && (modelica) && !textView);
  MainWindow::instance()->getSimulateModelAction()->setEnabled(enabled && modelica && pLibraryTreeItem->isSimulationAllowed());
  MainWindow::instance()->getSimulateWithTransformationalDebuggerAction()->setEnabled(enabled && modelica && pLibraryTreeItem->isSimulationAllowed());
  MainWindow::instance()->getSimulateWithAlgorithmicDebuggerAction()->setEnabled(enabled && modelica && pLibraryTreeItem->isSimulationAllowed());
#if !defined(WITHOUT_OSG)
  MainWindow::instance()->getSimulateWithAnimationAction()->setEnabled(enabled && modelica && pLibraryTreeItem->isSimulationAllowed());
#endif
  MainWindow::instance()->getSimulationSetupAction()->setEnabled(enabled && modelica && pLibraryTreeItem->isSimulationAllowed());
  bool accessAnnotation = false;
  if (pLibraryTreeItem && (pLibraryTreeItem->getAccess() >= LibraryTreeItem::packageText
                           || ((pLibraryTreeItem->getAccess() == LibraryTreeItem::nonPackageText
                                || pLibraryTreeItem->getAccess() == LibraryTreeItem::nonPackageDuplicate)
                               && pLibraryTreeItem->getRestriction() != StringHandler::Package))) {
    accessAnnotation = true;
  }
  MainWindow::instance()->getInstantiateModelAction()->setEnabled(enabled && modelica && accessAnnotation);
  MainWindow::instance()->getCheckModelAction()->setEnabled(enabled && modelica);
  MainWindow::instance()->getCheckAllModelsAction()->setEnabled(enabled && modelica);
  MainWindow::instance()->getExportToClipboardAction()->setEnabled(enabled && modelica);
  MainWindow::instance()->getExportAsImageAction()->setEnabled(enabled && modelica);
  MainWindow::instance()->getExportFMUAction()->setEnabled(enabled && modelica);
  bool packageSaveAsFolder = (enabled && pLibraryTreeItem && pLibraryTreeItem->isTopLevel()
                              && pLibraryTreeItem->getRestriction() == StringHandler::Package
                              && pLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveFolderStructure);
  MainWindow::instance()->getExportEncryptedPackageAction()->setEnabled(packageSaveAsFolder && enabled && modelica);
  MainWindow::instance()->getExportRealonlyPackageAction()->setEnabled(packageSaveAsFolder && enabled && modelica);
  MainWindow::instance()->getExportXMLAction()->setEnabled(enabled && modelica);
  MainWindow::instance()->getExportFigaroAction()->setEnabled(enabled && modelica);
  MainWindow::instance()->getExportToOMNotebookAction()->setEnabled(enabled && modelica);
  MainWindow::instance()->getSimulationParamsAction()->setEnabled(enabled && compositeModel);
  MainWindow::instance()->getFetchInterfaceDataAction()->setEnabled(enabled && compositeModel);
  MainWindow::instance()->getAlignInterfacesAction()->setEnabled(enabled && compositeModel);
  MainWindow::instance()->getTLMSimulationAction()->setEnabled(enabled && compositeModel);
  MainWindow::instance()->getAddSystemAction()->setEnabled(enabled && !iconGraphicsView && !textView && (omsModel || (omsSystem && (!pLibraryTreeItem->isSCSystem()))));
  MainWindow::instance()->getAddOrEditIconAction()->setEnabled(enabled && !diagramGraphicsView && !textView && (omsSystem || omsSubmodel));
  MainWindow::instance()->getDeleteIconAction()->setEnabled(enabled && !diagramGraphicsView && !textView && (omsSystem || omsSubmodel));
  MainWindow::instance()->getAddConnectorAction()->setEnabled(enabled && !textView && (omsSystem && (!pLibraryTreeItem->isTLMSystem())));
  MainWindow::instance()->getAddBusAction()->setEnabled(enabled && !textView && ((omsSystem || omsSubmodel)  && (!pLibraryTreeItem->isTLMSystem())));
  MainWindow::instance()->getAddTLMBusAction()->setEnabled(enabled && !textView && ((omsSystem || omsSubmodel)  && (!pLibraryTreeItem->isTLMSystem())));
  MainWindow::instance()->getAddSubModelAction()->setEnabled(enabled && !iconGraphicsView && !textView && omsSystem);
  MainWindow::instance()->getOMSInstantiateModelAction()->setEnabled(enabled && (omsModel || omsSystem || omsSubmodel));
  if (pLibraryTreeItem) {
    LibraryTreeItem *pTopLevelLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(StringHandler::getFirstWordBeforeDot(pLibraryTreeItem->getNameStructure()));
    MainWindow::instance()->getOMSInstantiateModelAction()->setChecked(pTopLevelLibraryTreeItem && pTopLevelLibraryTreeItem->isInstantiated());
  }
  MainWindow::instance()->getOMSSimulationSetupAction()->setEnabled(enabled && (omsModel || omsSystem || omsSubmodel) && MainWindow::instance()->getOMSInstantiateModelAction()->isChecked());
  MainWindow::instance()->getLogCurrentFileAction()->setEnabled(enabled && gitWorkingDirectory);
  MainWindow::instance()->getStageCurrentFileForCommitAction()->setEnabled(enabled && gitWorkingDirectory);
  MainWindow::instance()->getUnstageCurrentFileFromCommitAction()->setEnabled(enabled && gitWorkingDirectory);
  MainWindow::instance()->getCommitFilesAction()->setEnabled(enabled && gitWorkingDirectory);
  MainWindow::instance()->getRevertCommitAction()->setEnabled(enabled && gitWorkingDirectory);
  MainWindow::instance()->getCleanWorkingDirectoryAction()->setEnabled(enabled && gitWorkingDirectory);
  /* disable the save actions if class is a system library class. */
  if (pModelWidget) {
    if (pModelWidget->getLibraryTreeItem()->isSystemLibrary()) {
      MainWindow::instance()->getSaveAction()->setEnabled(false);
      MainWindow::instance()->getSaveAsAction()->setEnabled(false);
      MainWindow::instance()->getSaveAllAction()->setEnabled(false);
      // Disable also Git actions
      MainWindow::instance()->getLogCurrentFileAction()->setEnabled(false);
      MainWindow::instance()->getStageCurrentFileForCommitAction()->setEnabled(false);
      MainWindow::instance()->getUnstageCurrentFileFromCommitAction()->setEnabled(false);
      MainWindow::instance()->getCommitFilesAction()->setEnabled(false);
      MainWindow::instance()->getRevertCommitAction()->setEnabled(false);
      MainWindow::instance()->getCleanWorkingDirectoryAction()->setEnabled(false);
    }
    // update the Undo/Redo actions
    pModelWidget->updateUndoRedoActions();
  } else {
    MainWindow::instance()->getUndoAction()->setEnabled(false);
    MainWindow::instance()->getRedoAction()->setEnabled(false);
  }
  /* ticket:4983 Update the documentation browser when a new ModelWidget is selected.
   * Provided that the Documentation Browser is already visible.
   */
  if (pModelWidget && pModelWidget->getLibraryTreeItem() && MainWindow::instance()->getDocumentationDockWidget()->isVisible()) {
    MainWindow::instance()->getDocumentationWidget()->showDocumentation(pModelWidget->getLibraryTreeItem());
  }
}

/*!
 * \brief ModelWidgetContainer::updateThreeDViewer
 * Updates the ThreeDViewer when subWindowActivated(QMdiSubWindow*) signal of ModelWidgetContainer is raised.
 * \param pSubWindow
 */
void ModelWidgetContainer::updateThreeDViewer(QMdiSubWindow *pSubWindow)
{
#if !defined(WITHOUT_OSG)
  if (!pSubWindow) {
    if (MainWindow::instance()->isThreeDViewerInitialized()) {
      MainWindow::instance()->getThreeDViewer()->clearView();
    }
    return;
  }
  ModelWidget *pModelWidget = qobject_cast<ModelWidget*>(pSubWindow->widget());
  updateThreeDViewer(pModelWidget);
#else
  Q_UNUSED(pSubWindow);
#endif
}

/*!
 * \brief ModelWidgetContainer::saveModelWidget
 * Saves a model.
 */
void ModelWidgetContainer::saveModelWidget()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  // if pModelWidget = 0
  if (!pModelWidget) {
    QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                             GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN).arg(tr("saving")), Helper::ok);
    return;
  }
  LibraryTreeItem *pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
  MainWindow::instance()->getLibraryWidget()->saveLibraryTreeItem(pLibraryTreeItem);
}

/*!
 * \brief ModelWidgetContainer::saveAsModelWidget
 * Save a copy of the model in a new file.
 */
void ModelWidgetContainer::saveAsModelWidget()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  // if pModelWidget = 0
  if (!pModelWidget) {
    QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                             GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN).arg(tr("save as")), Helper::ok);
    return;
  }
  LibraryTreeItem *pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
  MainWindow::instance()->getLibraryWidget()->saveAsLibraryTreeItem(pLibraryTreeItem);
}

/*!
 * \brief ModelWidgetContainer::saveTotalModelWidget
 * Saves a model as total file.
 */
void ModelWidgetContainer::saveTotalModelWidget()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  // if pModelWidget = 0
  if (!pModelWidget) {
    QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                             GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN).arg(tr("saving")), Helper::ok);
    return;
  }
  LibraryTreeItem *pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
  MainWindow::instance()->getLibraryWidget()->saveTotalLibraryTreeItem(pLibraryTreeItem);
}

/*!
 * \brief ModelWidgetContainer::printModel
 * Slot activated when MainWindow::mpPrintModelAction triggered SIGNAL is raised.
 * Prints the model Icon/Diagram/Text depending on which one is visible.
 */
void ModelWidgetContainer::printModel()
{
#ifndef QT_NO_PRINTER
  if (ModelWidget *pModelWidget = getCurrentModelWidget()) {
    QPrinter printer(QPrinter::ScreenResolution);
    QPrintDialog *pPrintDialog = new QPrintDialog(&printer);

    // print the text of the model if it is visible
    if (pModelWidget->getEditor()->isVisible()) {
      ModelicaEditor *pModelicaEditor = dynamic_cast<ModelicaEditor*>(pModelWidget->getEditor());
      // set print options if text is selected
      if (pModelicaEditor->getPlainTextEdit()->textCursor().hasSelection()) {
        pPrintDialog->addEnabledOption(QAbstractPrintDialog::PrintSelection);
      }
      // open print dialog
      if (pPrintDialog->exec() == QDialog::Accepted) {
        pModelicaEditor->getPlainTextEdit()->print(&printer);
      }
    } else {
      // print the model Diagram/Icon
      GraphicsView *pGraphicsView = 0;
      if (pModelWidget->getIconGraphicsView()->isVisible()) {
        pGraphicsView = pModelWidget->getIconGraphicsView();
      } else {
        pGraphicsView = pModelWidget->getDiagramGraphicsView();
      }
      // hide the background of the view for printing
      bool oldSkipDrawBackground = pGraphicsView->mSkipBackground;
      pGraphicsView->mSkipBackground = true;
      // open print dialog
      if (pPrintDialog->exec() == QDialog::Accepted) {
        QPainter painter(&printer);
        painter.setRenderHints(QPainter::Antialiasing);
        pGraphicsView->render(&painter);
        painter.end();
      }
      pGraphicsView->mSkipBackground = oldSkipDrawBackground;
    }
    delete pPrintDialog;
  }
#endif
}

/*!
 * \brief ModelWidgetContainer::showSimulationParams
 * Slot activated when MainWindow::mpSimulationParamsAction triggered SIGNAL is raised.
 * Shows the CompositeModelSimulationParamsDialog
 */
void ModelWidgetContainer::showSimulationParams()
{
  if (ModelWidget *pModelWidget = getCurrentModelWidget()) {
    pModelWidget->getDiagramGraphicsView()->showSimulationParamsDialog();
  }
}

/*!
 * \brief ModelWidgetContainer::alignInterfaces
 * Slot activated when MainWindow::mpAlignInterfacesAction triggered SIGNAL is raised.
 * Shows the AlignInterfacesDialog
 */
void ModelWidgetContainer::alignInterfaces()
{
  if (ModelWidget *pModelWidget = getCurrentModelWidget()) {
    AlignInterfacesDialog *pAlignInterfacesDialog = new AlignInterfacesDialog(pModelWidget);
    pAlignInterfacesDialog->exec();
  }
}

/*!
 * \brief ModelWidgetContainer::addSystem
 * Opens the AddSystemDialog
 */
void ModelWidgetContainer::addSystem()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  if (pModelWidget && pModelWidget->getDiagramGraphicsView()) {
    AddSystemDialog *pAddSystemDialog = new AddSystemDialog(pModelWidget->getDiagramGraphicsView());
    pAddSystemDialog->exec();
  }
}

/*!
 * \brief ModelWidgetContainer::addOrEditIcon
 * Opens the AddOrEditSubModelIconDialog.
 */
void ModelWidgetContainer::addOrEditIcon()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  if (pModelWidget && pModelWidget->getIconGraphicsView()) {
    if (pModelWidget->getIconGraphicsView()->getShapesList().size() > 0) {
      ShapeAnnotation *pShapeAnnotation = pModelWidget->getIconGraphicsView()->getShapesList().at(0);
      if (dynamic_cast<BitmapAnnotation*>(pShapeAnnotation)) { // edit case
        AddOrEditIconDialog *pAddOrEditSubModelIconDialog = new AddOrEditIconDialog(pShapeAnnotation,
                                                                                                    pModelWidget->getIconGraphicsView());
        pAddOrEditSubModelIconDialog->exec();
      } else { // add case
        AddOrEditIconDialog *pAddOrEditSubModelIconDialog = new AddOrEditIconDialog(0, pModelWidget->getIconGraphicsView());
        pAddOrEditSubModelIconDialog->exec();
      }
    }
  }
}

/*!
 * \brief ModelWidgetContainer::deleteIcon
 * Deletes the icon from OMSimulator system or component.
 */
void ModelWidgetContainer::deleteIcon()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  if (pModelWidget && pModelWidget->getIconGraphicsView()) {
    if (pModelWidget->getIconGraphicsView()->getShapesList().size() > 0) {
      ShapeAnnotation *pShapeAnnotation = pModelWidget->getIconGraphicsView()->getShapesList().at(0);
      if (dynamic_cast<BitmapAnnotation*>(pShapeAnnotation)) {
        pModelWidget->getUndoStack()->push(new DeleteIconCommand(pShapeAnnotation->getFileName(), pModelWidget->getIconGraphicsView()));
      }
    }
  }
}

/*!
 * \brief ModelWidgetContainer::addConnector
 * Opens the AddConnectorDialog.
 */
void ModelWidgetContainer::addConnector()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  if (pModelWidget) {
    GraphicsView *pGraphicsView = 0;
    if (pModelWidget->getIconGraphicsView() && pModelWidget->getIconGraphicsView()->isVisible()) {
      pGraphicsView = pModelWidget->getIconGraphicsView();
    } else if (pModelWidget->getDiagramGraphicsView() && pModelWidget->getDiagramGraphicsView()->isVisible()) {
      pGraphicsView = pModelWidget->getDiagramGraphicsView();
    }
    AddConnectorDialog *pAddConnectorDialog = new AddConnectorDialog(pGraphicsView);
    pAddConnectorDialog->exec();
  }
}

/*!
 * \brief ModelWidgetContainer::addBus
 * Opens the AddBusDialog.
 */
void ModelWidgetContainer::addBus()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  if (pModelWidget) {
    GraphicsView *pGraphicsView = 0;
    if (pModelWidget->getIconGraphicsView() && pModelWidget->getIconGraphicsView()->isVisible()) {
      pGraphicsView = pModelWidget->getIconGraphicsView();
    } else if (pModelWidget->getDiagramGraphicsView() && pModelWidget->getDiagramGraphicsView()->isVisible()) {
      pGraphicsView = pModelWidget->getDiagramGraphicsView();
    }
    QList<Component*> components;
    QList<QGraphicsItem*> selectedItems = pGraphicsView->scene()->selectedItems();
    for (int i = 0 ; i < selectedItems.size() ; i++) {
      // check the selected components.
      Component *pComponent = dynamic_cast<Component*>(selectedItems.at(i));
      if (pComponent && pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->getOMSConnector()) {
        components.append(pComponent);
      }
    }
    AddBusDialog *pAddBusDialog = new AddBusDialog(components, 0, pGraphicsView);
    pAddBusDialog->exec();
  }
}

/*!
 * \brief ModelWidgetContainer::addTLMBus
 * Opens the AddTLMBusDialog.
 */
void ModelWidgetContainer::addTLMBus()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  if (pModelWidget) {
    GraphicsView *pGraphicsView = 0;
    if (pModelWidget->getIconGraphicsView() && pModelWidget->getIconGraphicsView()->isVisible()) {
      pGraphicsView = pModelWidget->getIconGraphicsView();
    } else if (pModelWidget->getDiagramGraphicsView() && pModelWidget->getDiagramGraphicsView()->isVisible()) {
      pGraphicsView = pModelWidget->getDiagramGraphicsView();
    }
    QList<Component*> components;
    QList<QGraphicsItem*> selectedItems = pGraphicsView->scene()->selectedItems();
    for (int i = 0 ; i < selectedItems.size() ; i++) {
      // check the selected components.
      Component *pComponent = dynamic_cast<Component*>(selectedItems.at(i));
      if (pComponent && pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->getOMSConnector()) {
        components.append(pComponent);
      }
    }
    AddTLMBusDialog *pAddTLMBusDialog = new AddTLMBusDialog(components, 0, pGraphicsView);
    pAddTLMBusDialog->exec();
  }
}

/*!
 * \brief ModelWidgetContainer::addSubModel
 * Opens the AddFMUDialog.
 */
void ModelWidgetContainer::addSubModel()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  if (pModelWidget && pModelWidget->getDiagramGraphicsView()) {
    AddSubModelDialog *pAddFMUDialog = new AddSubModelDialog(pModelWidget->getDiagramGraphicsView());
    pAddFMUDialog->exec();
  }
}
