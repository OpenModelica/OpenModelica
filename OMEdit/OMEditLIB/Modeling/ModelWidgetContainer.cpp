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
#include "ElementTreeWidget.h"
#include "ItemDelegate.h"
#include "Options/OptionsDialog.h"
#include "MessagesWidget.h"
#include "DocumentationWidget.h"
#include "Annotations/ShapePropertiesDialog.h"
#include "Element/ElementProperties.h"
#include "Commands.h"
#include "Options/NotificationsDialog.h"
#include "ModelicaClassDialog.h"
#include "Git/GitCommands.h"
#include "OMS/OMSProxy.h"
#include "OMS/ModelDialog.h"
#include "OMS/BusDialog.h"
#include "OMS/SystemSimulationInformationDialog.h"
#include "Util/ResourceCache.h"
#include "Plotting/PlotWindowContainer.h"
#include "Util/NetworkAccessManager.h"

#include <QNetworkReply>
#include <QMessageBox>
#include <QMenu>
#include <QMenuBar>
#include <QGraphicsDropShadowEffect>
#include <QButtonGroup>
#include <QDockWidget>
#include <QPrinter>
#include <QPrintDialog>
#include <QDesktopServices>
#include <QClipboard>
#include <QStringBuilder>

const QString cutCopyPasteComponentsConnectionsFormat("application/OMEdit.cut-copy-paste-components-connections");
const QString cutCopyPasteComponentsFormat("application/OMEdit.cut-copy-paste-components");
const QString cutCopyPasteConnectionsFormat("application/OMEdit.cut-copy-paste-connections");
const QString cutCopyPasteShapesFormat("application/OMEdit.cut-copy-paste-shapes");
const QString cutCopyPasteShapesOMCFormat("application/OMEdit.cut-copy-paste-shapes-omc");

ModelInfo::ModelInfo()
{
  mName = "";
  mIconElementsList.clear();
  mDiagramElementsList.clear();
  mConnectionsList.clear();
  mTransitionsList.clear();
  mInitialStatesList.clear();
}

Element* ModelInfo::getIconElement(const QString &name) const
{
  foreach (Element *pElement, mIconElementsList) {
    if (pElement->getName().compare(name) == 0) {
      return pElement;
    }
  }
  return 0;
}

Element* ModelInfo::getDiagramElement(const QString &name) const
{
  foreach (Element *pElement, mDiagramElementsList) {
    if (pElement->getName().compare(name) == 0) {
      return pElement;
    }
  }
  return 0;
}

LineAnnotation* ModelInfo::getConnection(const QString &startElementName, const QString &endElementName) const
{
  foreach (LineAnnotation *pConnectionLineAnnotation, mConnectionsList) {
    if ((pConnectionLineAnnotation->getStartElementName().compare(startElementName) == 0) && (pConnectionLineAnnotation->getEndElementName().compare(endElementName) == 0)) {
      return pConnectionLineAnnotation;
    }
  }
  return 0;
}

/*!
 * \class GraphicsScene
 * \brief The GraphicsScene class is a container for graphical components in a simulationmodel.
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
 * \param pModelWidget
 * \param visualizationView
 */
GraphicsView::GraphicsView(StringHandler::ViewType viewType, ModelWidget *pModelWidget)
  : QGraphicsView(pModelWidget), mViewType(viewType), mSkipBackground(false), mContextMenuStartPosition(QPointF(0, 0)),
    mContextMenuStartPositionValid(false)
{
  setIsVisualizationView(false);
  /* Ticket #3275
   * Set the scroll bars policy to always on to avoid unnecessary resize events.
   */
  setRenderHint(QPainter::SmoothPixmapTransform);
  setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  setFrameShape(QFrame::StyledPanel);
  setDragMode(QGraphicsView::RubberBandDrag);
  setAcceptDrops(true);
  setViewportUpdateMode(QGraphicsView::FullViewportUpdate);
  setMouseTracking(true);
  mpModelWidget = pModelWidget;
  setExtentRectangle(mCoordinateSystem.getExtentRectangle(), true);
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
  mElementsList.clear();
  mOutOfSceneElementsList.clear();
  mConnectionsList.clear();
  mOutOfSceneConnectionsList.clear();
  mTransitionsList.clear();
  mOutOfSceneTransitionsList.clear();
  mInitialStatesList.clear();
  mOutOfSceneInitialStatesList.clear();
  mShapesList.clear();
  mOutOfSceneShapesList.clear();
  mInheritedElementsList.clear();
  mInheritedConnectionsList.clear();
  mInheritedTransitionsList.clear();
  mInheritedInitialStatesList.clear();
  mInheritedShapesList.clear();
  mpConnectionLineAnnotation = 0;
  mpTransitionLineAnnotation = 0;
  mpLineShapeAnnotation = 0;
  mpPolygonShapeAnnotation = 0;
  mpRectangleShapeAnnotation = 0;
  mpEllipseShapeAnnotation = 0;
  mpTextShapeAnnotation = 0;
  mpErrorTextShapeAnnotation = 0;
  mpBitmapShapeAnnotation = 0;
  createActions();
  mAllItems.clear();
}

GraphicsView::~GraphicsView()
{
  /* When the scene is deleted it will delete all the items inside it.
   * We need to delete the items that are not part of the scene.
   */
  foreach (Element *pElement, mOutOfSceneElementsList) {
    delete pElement->getOriginItem();
    delete pElement->getBottomLeftResizerItem();
    delete pElement->getTopLeftResizerItem();
    delete pElement->getTopRightResizerItem();
    delete pElement->getBottomRightResizerItem();
    delete pElement;
  }

  foreach (LineAnnotation *pConnectionLineAnnotation, mOutOfSceneConnectionsList) {
    delete pConnectionLineAnnotation;
  }

  foreach (LineAnnotation *pTransitionLineAnnotation, mOutOfSceneTransitionsList) {
    delete pTransitionLineAnnotation;
  }

  foreach (LineAnnotation *pInitialStateLineAnnotation, mOutOfSceneInitialStatesList) {
    delete pInitialStateLineAnnotation;
  }

  foreach (ShapeAnnotation *pShapeAnnotation, mOutOfSceneShapesList) {
    delete pShapeAnnotation;
  }
}

/*!
 * \brief GraphicsView::resetCoordinateSystem
 * Resets the coordinate system
 */
void GraphicsView::resetCoordinateSystem()
{
  mCoordinateSystem = ModelInstance::CoordinateSystem();
  mMergedCoordinateSystem = mCoordinateSystem;
}

void GraphicsView::setIsVisualizationView(bool visualizationView)
{
  setItemsFlags(!visualizationView);
  mVisualizationView = visualizationView;
}

/*!
 * \brief GraphicsView::drawCoordinateSystem
 * Draws the coordinate system.
 */
void GraphicsView::drawCoordinateSystem()
{
  if (isIconView() && mpModelWidget->getLibraryTreeItem()->getAccess() >= LibraryTreeItem::icon) {
    mCoordinateSystem = mpModelWidget->getModelInstance()->getAnnotation()->getIconAnnotation()->mCoordinateSystem;
    mMergedCoordinateSystem = mpModelWidget->getModelInstance()->getAnnotation()->getIconAnnotation()->mMergedCoordinateSystem;
    setExtentRectangle(mMergedCoordinateSystem.getExtentRectangle(), false);
  } else if (isDiagramView() && mpModelWidget->getLibraryTreeItem()->getAccess() >= LibraryTreeItem::diagram) {
    mCoordinateSystem = mpModelWidget->getModelInstance()->getAnnotation()->getDiagramAnnotation()->mCoordinateSystem;
    mMergedCoordinateSystem = mpModelWidget->getModelInstance()->getAnnotation()->getDiagramAnnotation()->mMergedCoordinateSystem;
    setExtentRectangle(mMergedCoordinateSystem.getExtentRectangle(), false);
  }
  resize(size());
}

/*!
 * \brief GraphicsView::drawShapes
 * Draws the shapes of the model.
 * \param pModelInstance
 * \param inhertied
 * \param openingModel
 */
void GraphicsView::drawShapes(ModelInstance::Model *pModelInstance, bool inhertied, bool openingModel)
{
  QList<ModelInstance::Shape*> shapes;
  ModelInstance::Extend *pExtendModel = 0;
  if (inhertied) {
    pExtendModel = pModelInstance->getParentExtend();
  }
  if (isIconView() && mpModelWidget->getLibraryTreeItem()->getAccess() >= LibraryTreeItem::icon) {
    if (!(pExtendModel && !pExtendModel->getIconDiagramMapPrimitivesVisible(true))) {
      shapes = pModelInstance->getAnnotation()->getIconAnnotation()->getGraphics();
    }
  } else if (isDiagramView() && mpModelWidget->getLibraryTreeItem()->getAccess() >= LibraryTreeItem::diagram) {
    if (!(pExtendModel && !pExtendModel->getIconDiagramMapPrimitivesVisible(false))) {
      shapes = pModelInstance->getAnnotation()->getDiagramAnnotation()->getGraphics();
    }
  }

  // if inherited or openingModel then simply draw new shapes.
  if (inhertied || openingModel) {
    foreach (auto shape, shapes) {
      ShapeAnnotation *pShapeAnnotation = 0;
      if (ModelInstance::Line *pLine = dynamic_cast<ModelInstance::Line*>(shape)) {
        pShapeAnnotation = new LineAnnotation(pLine, inhertied, this);
      } else if (ModelInstance::Polygon *pPolygon = dynamic_cast<ModelInstance::Polygon*>(shape)) {
        pShapeAnnotation = new PolygonAnnotation(pPolygon, inhertied, this);
      } else if (ModelInstance::Rectangle *pRectangle = dynamic_cast<ModelInstance::Rectangle*>(shape)) {
        pShapeAnnotation = new RectangleAnnotation(pRectangle, inhertied, this);
      } else if (ModelInstance::Ellipse *pEllipse = dynamic_cast<ModelInstance::Ellipse*>(shape)) {
        pShapeAnnotation = new EllipseAnnotation(pEllipse, inhertied, this);
      } else if (ModelInstance::Text *pText = dynamic_cast<ModelInstance::Text*>(shape)) {
        pShapeAnnotation = new TextAnnotation(pText, inhertied, this);
      } else if (ModelInstance::Bitmap *pBitmap = dynamic_cast<ModelInstance::Bitmap*>(shape)) {
        pShapeAnnotation = new BitmapAnnotation(pBitmap, mpModelWidget->getLibraryTreeItem()->mClassInformation.fileName, inhertied, this);
      }

      if (pShapeAnnotation) {
        pShapeAnnotation->drawCornerItems();
        pShapeAnnotation->setCornerItemsActiveOrPassive();
        pShapeAnnotation->applyTransformation();
        if (pShapeAnnotation->isInheritedShape()) {
          addInheritedShapeToList(pShapeAnnotation);
        } else {
          addShapeToList(pShapeAnnotation, -1);
        }
        addItem(pShapeAnnotation);
        addItem(pShapeAnnotation->getOriginItem());
      }
    }
  } else { // if we are updating the model then update the existing shapes.
    if (mShapesList.size() == shapes.size()) {
      for (int i = 0; i < mShapesList.size(); ++i) {
        if (LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(mShapesList.at(i))) {
          pLineAnnotation->setLine(dynamic_cast<ModelInstance::Line*>(shapes.at(i)));
        } else if (PolygonAnnotation *pPolygonAnnotation = dynamic_cast<PolygonAnnotation*>(mShapesList.at(i))) {
          pPolygonAnnotation->setPolygon(dynamic_cast<ModelInstance::Polygon*>(shapes.at(i)));
        } else if (RectangleAnnotation *pRectangleAnnotation = dynamic_cast<RectangleAnnotation*>(mShapesList.at(i))) {
          pRectangleAnnotation->setRectangle(dynamic_cast<ModelInstance::Rectangle*>(shapes.at(i)));
        } else if (EllipseAnnotation *pEllipseAnnotation = dynamic_cast<EllipseAnnotation*>(mShapesList.at(i))) {
          pEllipseAnnotation->setEllipse(dynamic_cast<ModelInstance::Ellipse*>(shapes.at(i)));
        } else if (TextAnnotation *pTextAnnotation = dynamic_cast<TextAnnotation*>(mShapesList.at(i))) {
          pTextAnnotation->setText(dynamic_cast<ModelInstance::Text*>(shapes.at(i)));
        } else if (BitmapAnnotation *pBitmapAnnotation = dynamic_cast<BitmapAnnotation*>(mShapesList.at(i))) {
          pBitmapAnnotation->setBitmap(dynamic_cast<ModelInstance::Bitmap*>(shapes.at(i)));
        }
        // remove and add the shape to keep the correct order of shapes.
        removeItem(mShapesList.at(i));
        removeItem(mShapesList.at(i)->getOriginItem());
        addItem(mShapesList.at(i));
        addItem(mShapesList.at(i)->getOriginItem());
      }
    }
  }
}

/*!
 * \brief GraphicsView::drawElements
 * This function is only called for Diagram layer.
 * Draws the elements. If element is a connector then it is also drawn on the icon layer.
 * \param pModelInstance
 * \param inherited
 * \param modelInfo
 */
void GraphicsView::drawElements(ModelInstance::Model *pModelInstance, bool inherited, const ModelInfo &modelInfo)
{
  // We use access.icon so we can draw public components so that we can see and set the parameters in the parameters window.
  if (mpModelWidget->getLibraryTreeItem()->getAccess() >= LibraryTreeItem::icon && isDiagramView()) {
    QList<ModelInstance::Element*> elements = pModelInstance->getElements();
    int elementIndex = -1, connectorIndex = -1;
    for (int i = 0; i < elements.size(); ++i) {
      auto pModelInstanceElement = elements.at(i);
      if (pModelInstanceElement->isComponent() && pModelInstanceElement->getModel()) {
        auto pModelInstanceComponent = dynamic_cast<ModelInstance::Component*>(pModelInstanceElement);
        elementIndex++;
        if (pModelInstanceComponent->getModel()->isConnector()) {
          connectorIndex++;
        }
        if (modelInfo.mDiagramElementsList.isEmpty() || inherited) {
          addElementToView(pModelInstanceComponent, inherited, false, false, QPointF(0, 0), "", false);
        } else { // update case
          GraphicsView *pIconGraphicsView = mpModelWidget->getIconGraphicsView();
          GraphicsView *pDiagramGraphicsView = mpModelWidget->getDiagramGraphicsView();
          if (elementIndex < modelInfo.mDiagramElementsList.size()) {
            Element *pDiagramElement = modelInfo.mDiagramElementsList.at(elementIndex);
            if (pDiagramElement) {
              pDiagramElement->setModelComponent(pModelInstanceComponent);
              pDiagramElement->reDrawElement();
              pDiagramGraphicsView->addElementItem(pDiagramElement);
              pDiagramGraphicsView->addElementToList(pDiagramElement);
              pDiagramGraphicsView->deleteElementFromOutOfSceneList(pDiagramElement);
              if (pModelInstanceComponent->getModel()->isConnector() && connectorIndex < modelInfo.mIconElementsList.size()) {
                Element *pIconElement = modelInfo.mIconElementsList.at(connectorIndex);
                if (pIconElement) {
                  pIconElement->setModelComponent(pModelInstanceComponent);
                  pIconElement->reDrawElement();
                  pIconGraphicsView->addElementItem(pIconElement);
                  pIconGraphicsView->addElementToList(pIconElement);
                  pIconGraphicsView->deleteElementFromOutOfSceneList(pIconElement);
                  pIconElement->setVisible(pModelInstanceComponent->isPublic());
                }
              }
            }
          } else {
            qDebug() << "Got an element from getModelInstance that is not handled." << pModelInstanceElement->toString();
          }
        }
      }
    }
  }
}

/*!
 * \brief GraphicsView::drawConnections
 * Draws the connections.
 * \param pModelInstance
 * \param inherited
 * \param modelInfo
 */
void GraphicsView::drawConnections(ModelInstance::Model *pModelInstance, bool inherited, const ModelInfo &modelInfo)
{
  mpModelWidget->detectMultipleDeclarations();
  // We use access.diagram so we can draw connections.
  if (mpModelWidget->getLibraryTreeItem()->getAccess() >= LibraryTreeItem::diagram && isDiagramView()) {
    int modelInfoIndex = -1;
    QList<ModelInstance::Connection*> connections = pModelInstance->getConnections();
    for (int i = 0; i < connections.size(); ++i) {
      auto pConnection = connections.at(i);
      // if connection is valid and has line annotation
      if (pConnection->getStartConnector() && pConnection->getEndConnector() && pConnection->getAnnotation()->getLine()
          && !connectionExists(pConnection->getStartConnector()->getName(), pConnection->getEndConnector()->getName(), inherited)) {
        // get start and end elements
        auto pStartConnectorElement = getConnectorElement(pConnection->getStartConnector());
        // show error message if start element is not found.
        if (!pStartConnectorElement) {
          MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
            GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION_NEW)
              .arg(pConnection->getStartConnector()->getName()).arg(pConnection->toString())
              .arg(mpModelWidget->getLibraryTreeItem()->getNameStructure()), Helper::scriptingKind, Helper::errorLevel));
          continue;
        }

        auto pEndConnectorElement = getConnectorElement(pConnection->getEndConnector());
        // show error message if end element is not found.
        if (!pEndConnectorElement) {
          MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
            GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION_NEW)
              .arg(pConnection->getEndConnector()->getName()).arg(pConnection->toString())
              .arg(mpModelWidget->getLibraryTreeItem()->getNameStructure()), Helper::scriptingKind, Helper::errorLevel));
          continue;
        }

        modelInfoIndex++;
        if (modelInfo.mConnectionsList.isEmpty() || inherited) {
          LineAnnotation *pConnectionLineAnnotation = new LineAnnotation(pConnection, pStartConnectorElement, pEndConnectorElement, inherited, this);
          pConnectionLineAnnotation->drawCornerItems();
          pConnectionLineAnnotation->setCornerItemsActiveOrPassive();
          addConnectionToView(pConnectionLineAnnotation, inherited);
        } else { // update case
          if (modelInfoIndex < modelInfo.mConnectionsList.size()) {
            LineAnnotation *pConnectionLineAnnotation = modelInfo.mConnectionsList.at(modelInfoIndex);
            if (pConnectionLineAnnotation) {
              pConnectionLineAnnotation->setStartElement(pStartConnectorElement);
              pConnectionLineAnnotation->setStartElementName(pConnection->getStartConnector()->getName());
              pConnectionLineAnnotation->setEndElement(pEndConnectorElement);
              pConnectionLineAnnotation->setEndElementName(pConnection->getEndConnector()->getName());
              pConnectionLineAnnotation->setLine(pConnection->getAnnotation()->getLine());
              addConnectionDetails(pConnectionLineAnnotation);
              addItem(pConnectionLineAnnotation);
              addConnectionToList(pConnectionLineAnnotation);
              deleteConnectionFromOutOfSceneList(pConnectionLineAnnotation);
            }
          } else {
            qDebug() << "Got a connection from getModelInstance that is not handled." << pConnection->toString();
          }
        }
      }
    }
  }
}

/*!
 * \brief GraphicsView::drawTransitions
 * Draws the transitions.
 * \param pModelInstance
 * \param inherited
 * \param modelInfo
 */
void GraphicsView::drawTransitions(ModelInstance::Model *pModelInstance, bool inherited, const ModelInfo &modelInfo)
{
  // We use access.diagram so we can draw transitions.
  if (mpModelWidget->getLibraryTreeItem()->getAccess() >= LibraryTreeItem::diagram && isDiagramView()) {
    int modelInfoIndex = -1;
    QList<ModelInstance::Transition*> transitions = pModelInstance->getTransitions();
    for (int i = 0; i < transitions.size(); ++i) {
      auto pTransition = transitions.at(i);
      // if transition is valid and has line annotation
      if (pTransition->getStartConnector() && pTransition->getEndConnector() && pTransition->getAnnotation()->getLine()) {
        // get start element
        Element *pStartElement = getElementObject(pTransition->getStartConnector()->getName());
        // show error message if start element is not found.
        if (!pStartElement) {
          MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                                GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_TRANSITION_NEW)
                                                                .arg(pTransition->getStartConnector()->getName()).arg(pTransition->toString())
                                                                .arg(mpModelWidget->getLibraryTreeItem()->getNameStructure()),
                                                                Helper::scriptingKind, Helper::errorLevel));
          continue;
        }
        // get end element
        Element *pEndElement = getElementObject(pTransition->getEndConnector()->getName());
        // show error message if end element is not found.

        if (!pEndElement) {
          MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                                GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_TRANSITION_NEW)
                                                                .arg(pTransition->getEndConnector()->getName()).arg(pTransition->toString())
                                                                .arg(mpModelWidget->getLibraryTreeItem()->getNameStructure()),
                                                                Helper::scriptingKind, Helper::errorLevel));
          continue;
        }

        modelInfoIndex++;
        if (modelInfo.mTransitionsList.isEmpty() || inherited) {
          LineAnnotation *pTransitionLineAnnotation = new LineAnnotation(pTransition, pStartElement, pEndElement, inherited, this);
          pTransitionLineAnnotation->drawCornerItems();
          pTransitionLineAnnotation->setCornerItemsActiveOrPassive();
          addTransitionToView(pTransitionLineAnnotation, inherited);
        } else { // update case
          if (modelInfoIndex < modelInfo.mTransitionsList.size()) {
            LineAnnotation *pTransitionLineAnnotation = modelInfo.mTransitionsList.at(modelInfoIndex);
            if (pTransitionLineAnnotation) {
              pTransitionLineAnnotation->setStartElement(pStartElement);
              pTransitionLineAnnotation->setStartElementName(pTransition->getStartConnector()->getName());
              pTransitionLineAnnotation->setEndElement(pEndElement);
              pTransitionLineAnnotation->setEndElementName(pTransition->getEndConnector()->getName());
              pTransitionLineAnnotation->setLine(pTransition->getAnnotation()->getLine());
              addConnectionDetails(pTransitionLineAnnotation);
              addItem(pTransitionLineAnnotation);
              addTransitionToList(pTransitionLineAnnotation);
              deleteTransitionFromOutOfSceneList(pTransitionLineAnnotation);
            }
          }
        }
      }
    }
  }
}

/*!
 * \brief GraphicsView::drawInitialStates
 * Draws the initial states.
 * \param pModelInstance
 * \param inherited
 * \param modelInfo
 */
void GraphicsView::drawInitialStates(ModelInstance::Model *pModelInstance, bool inherited, const ModelInfo &modelInfo)
{
  // We use access.diagram so we can draw initial states.
  if (mpModelWidget->getLibraryTreeItem()->getAccess() >= LibraryTreeItem::diagram && isDiagramView()) {
    int modelInfoIndex = -1;
    QList<ModelInstance::InitialState*> initialStates = pModelInstance->getInitialStates();
    for (int i = 0; i < initialStates.size(); ++i) {
      auto pInitialState = initialStates.at(i);
      // if initialState is valid and has line annotation
      if (pInitialState->getStartConnector() && pInitialState->getAnnotation()->getLine()) {
        // get start element
        Element *pStartElement = getElementObject(pInitialState->getStartConnector()->getName());
        // show error message if start element is not found.
        if (!pStartElement) {
          MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                                GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_INITIALSTATE_NEW)
                                                                .arg(pInitialState->getStartConnector()->getName()).arg(pInitialState->toString())
                                                                .arg(mpModelWidget->getLibraryTreeItem()->getNameStructure()),
                                                                Helper::scriptingKind, Helper::errorLevel));
          continue;
        }

        modelInfoIndex++;
        if (modelInfo.mInitialStatesList.isEmpty() || inherited) {
          LineAnnotation *pInitialStateLineAnnotation = new LineAnnotation(pInitialState, pStartElement, inherited, this);
          pInitialStateLineAnnotation->drawCornerItems();
          pInitialStateLineAnnotation->setCornerItemsActiveOrPassive();
          addInitialStateToView(pInitialStateLineAnnotation, inherited);
        } else { // update case
          if (modelInfoIndex < modelInfo.mInitialStatesList.size()) {
            LineAnnotation *pInitialStateLineAnnotation = modelInfo.mInitialStatesList.at(modelInfoIndex);
            if (pInitialStateLineAnnotation) {
              pInitialStateLineAnnotation->setStartElement(pStartElement);
              pInitialStateLineAnnotation->setStartElementName(pInitialState->getStartConnector()->getName());
              pInitialStateLineAnnotation->setLine(pInitialState->getAnnotation()->getLine());
              addConnectionDetails(pInitialStateLineAnnotation);
              addItem(pInitialStateLineAnnotation);
              addInitialStateToList(pInitialStateLineAnnotation);
              deleteInitialStateFromOutOfSceneList(pInitialStateLineAnnotation);
            }
          }
        }
      }
    }
  }
}

/*!
 * \brief GraphicsView::handleCollidingConnections
 * Detect the colliding connections for the diagram view.
 */
void GraphicsView::handleCollidingConnections()
{
  // First clear the colliding connector elements and connections.
  QList<LineAnnotation*> connections = mInheritedConnectionsList;
  connections.append(mConnectionsList);
  foreach (LineAnnotation *pConnectionLineAnnotation, connections) {
    pConnectionLineAnnotation->clearCollidingConnections();
  }

  foreach (LineAnnotation *pConnectionLineAnnotation, connections) {
    pConnectionLineAnnotation->handleCollidingConnections();
  }
}

bool GraphicsView::isCreatingShape()
{
  return isCreatingLineShape() ||
      isCreatingPolygonShape() ||
      isCreatingRectangleShape() ||
      isCreatingEllipseShape() ||
      isCreatingBitmapShape() ||
      isCreatingTextShape();
}

/*!
 * \brief GraphicsView::setExtentRectangle
 * Increases the size of the extent rectangle by 25%.
 * \param rectangle
 * \param moveToCenter
 */
void GraphicsView::setExtentRectangle(const QRectF rectangle, bool moveToCenter)
{
  QRectF sceneRectangle = Utilities::adjustSceneRectangle(rectangle, 0.25);
  setSceneRect(sceneRectangle);
  if (moveToCenter) {
    centerOn(sceneRectangle.center());
  }
}

void GraphicsView::setIsCreatingConnection(const bool enable)
{
  mIsCreatingConnection = enable;
  setIsCreatingPrologue(enable);
}

void GraphicsView::setIsCreatingTransition(const bool enable)
{
  mIsCreatingTransition = enable;
  setIsCreatingPrologue(enable);
}

void GraphicsView::setIsCreatingLineShape(const bool enable)
{
  mIsCreatingLineShape = enable;
  setIsCreatingPrologue(enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingPolygonShape(const bool enable)
{
  mIsCreatingPolygonShape = enable;
  setIsCreatingPrologue(enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingRectangleShape(const bool enable)
{
  mIsCreatingRectangleShape = enable;
  setIsCreatingPrologue(enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingEllipseShape(const bool enable)
{
  mIsCreatingEllipseShape = enable;
  setIsCreatingPrologue(enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingTextShape(const bool enable)
{
  mIsCreatingTextShape = enable;
  setIsCreatingPrologue(enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingBitmapShape(const bool enable)
{
  mIsCreatingBitmapShape = enable;
  setIsCreatingPrologue(enable);
  updateUndoRedoActions(enable);
}

void GraphicsView::setIsCreatingPrologue(const bool enable)
{
  setDragModeInternal(enable);
  setItemsFlags(!enable);
}

void GraphicsView::setIsPanning(const bool enable)
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
  foreach (Element *pElement, mElementsList) {
    pElement->setElementFlags(enable);
  }
  foreach (ShapeAnnotation *pShapeAnnotation, mShapesList){
    pShapeAnnotation->setShapeFlags(enable);
  }
  foreach (LineAnnotation *pConnectionLineAnnotation, mConnectionsList) {
    pConnectionLineAnnotation->setShapeFlags(enable);
  }
  foreach (LineAnnotation *pTransitionLineAnnotation, mTransitionsList) {
    pTransitionLineAnnotation->setShapeFlags(enable);
  }
  foreach (LineAnnotation *pInitialStateLineAnnotation, mInitialStatesList) {
    pInitialStateLineAnnotation->setShapeFlags(enable);
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

/*!
 * \brief GraphicsView::performElementCreationChecks
 * Performs the checks like partial model, default name, inner component etc.
 * \param nameStructure
 * \param partial
 * \param name
 * \param defaultPrefix
 * \return
 */
bool GraphicsView::performElementCreationChecks(const QString &nameStructure, bool partial, QString *name, QString *defaultPrefix)
{
  MainWindow *pMainWindow = MainWindow::instance();
  OptionsDialog *pOptionsDialog = OptionsDialog::instance();
  // check if the model is partial
  if (partial) {
    if (pOptionsDialog->getNotificationsPage()->getReplaceableIfPartialCheckBox()->isChecked()) {
      NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::ReplaceableIfPartial, NotificationsDialog::InformationIcon, MainWindow::instance());
      pNotificationsDialog->setNotificationLabelString(GUIMessages::getMessage(GUIMessages::MAKE_REPLACEABLE_IF_PARTIAL).arg(nameStructure));
      if (!pNotificationsDialog->exec()) {
        return false;
      }
    }
  }
  // get the model defaultComponentPrefixes
  *defaultPrefix = pMainWindow->getOMCProxy()->getDefaultComponentPrefixes(nameStructure);
  QString defaultName;
  *name = getUniqueElementName(nameStructure, *name, &defaultName);
  // Allow user to change the component name if always ask for component name settings is true.
  if (pOptionsDialog->getNotificationsPage()->getAlwaysAskForDraggedComponentName()->isChecked()) {
    ComponentNameDialog *pComponentNameDialog = new ComponentNameDialog(nameStructure, *name, this, pMainWindow);
    if (pComponentNameDialog->exec()) {
      *name = pComponentNameDialog->getComponentName();
      pComponentNameDialog->deleteLater();
    } else {
      pComponentNameDialog->deleteLater();
      return false;
    }
  }
  // if we or user has changed the default name
  if (!defaultName.isEmpty() && name->compare(defaultName) != 0) {
    // show the information to the user if we have changed the name of some inner component.
    if (defaultPrefix->contains("inner")) {
      if (pOptionsDialog->getNotificationsPage()->getInnerModelNameChangedCheckBox()->isChecked()) {
        NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::InnerModelNameChanged, NotificationsDialog::InformationIcon, MainWindow::instance());
        pNotificationsDialog->setNotificationLabelString(GUIMessages::getMessage(GUIMessages::INNER_MODEL_NAME_CHANGED).arg(defaultName).arg(*name));
        if (!pNotificationsDialog->exec()) {
          return false;
        }
      }
    }
  }
  return true;
}

/*!
 * \brief GraphicsView::createModelInstanceComponent
 * Creates a Component and returns it.
 * \param pModelInstance
 * \param name
 * \param className
 * \return
 */
ModelInstance::Component *GraphicsView::createModelInstanceComponent(ModelInstance::Model *pModelInstance, const QString &name, const QString &className)
{
  /* Create a dummyOMEditClass
   * Add the component to it
   * Call getModelInstance on it
   * Use the JSON of the component and add the component to current model.
   */
  const QString dummyClass("dummyOMEditClass");
  MainWindow::instance()->getOMCProxy()->loadString("model " % dummyClass % " end " % dummyClass % ";", "<interactive>");
  MainWindow::instance()->getOMCProxy()->addComponent(name, className, dummyClass, "annotate=Placement()");
  const QJsonObject modelJSON = MainWindow::instance()->getOMCProxy()->getModelInstance(dummyClass);
  MainWindow::instance()->getOMCProxy()->deleteClass(dummyClass);
  const QJsonArray elementsArray = modelJSON.value("elements").toArray();
  if (!elementsArray.isEmpty()) {
    pModelInstance->deserializeElements(modelJSON.value("elements").toArray());
    QList<ModelInstance::Element*> elements = pModelInstance->getElements();
    if (!elements.isEmpty()) {
      return dynamic_cast<ModelInstance::Component*>(elements.last());
    }
  }
  return 0;
}

/*!
 * \brief GraphicsView::createModelInstanceComponent
 * Creates a Component and returns it.
 * \param pModelInstance
 * \param name
 * \param className
 * \param isConnector
 * \return
 */
ModelInstance::Component *GraphicsView::createModelInstanceComponent(ModelInstance::Model *pModelInstance, const QString &name, const QString &className, bool isConnector)
{
  ModelInstance::Component *pComponent = new ModelInstance::Component(pModelInstance);
  pComponent->setName(name);
  pComponent->setType(className);
  /* We use getModelInstance with icon flag for bettter performance
   * This model will be updated right after this so it doesn't matter if the Component has complete model or not.
   */
  ModelInstance::Model *pModel = new ModelInstance::Model(MainWindow::instance()->getOMCProxy()->getModelInstance(className, "", false, true));
  pModel->setRestriction(isConnector ? "connector" : "model");
  pComponent->setModel(pModel);
  pModelInstance->addElement(pComponent);
  return pComponent;
}

bool GraphicsView::addComponent(QString className, QPointF position)
{
  MainWindow *pMainWindow = MainWindow::instance();
  LibraryTreeItem *pLibraryTreeItem = pMainWindow->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(className);
  if (!pLibraryTreeItem) {
    return false;
  }
  // Only allow drag & drop of Modelica LibraryTreeItem on a Modelica LibraryTreeItem
  if (mpModelWidget->getLibraryTreeItem()->getLibraryType() != pLibraryTreeItem->getLibraryType()) {
    QMessageBox::information(pMainWindow, QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                             tr("You can only drag & drop Modelica models."), QMessageBox::Ok);
    return false;
  }
  StringHandler::ModelicaClasses type = pLibraryTreeItem->getRestriction();
  // item not to be dropped on itself; if dropping an item on itself
  if (isClassDroppedOnItself(pLibraryTreeItem)) {
    return false;
  } else {
    QString name = pLibraryTreeItem->getName();
    QString defaultPrefix = "";
    if (!performElementCreationChecks(pLibraryTreeItem->getNameStructure(), pLibraryTreeItem->isPartial(), &name, &defaultPrefix)) {
      return false;
    }
    // If dropping an item on the diagram layer. If item is a class, model, block, connector or record. then we can drop it to the graphicsview
    // If dropping an item on the icon layer. If item is a connector. then we can drop it to the graphicsview
    if ((isDiagramView() && ((type == StringHandler::Class) || (type == StringHandler::Model) || (type == StringHandler::Block) ||
                             (type == StringHandler::ExpandableConnector) || (type == StringHandler::Connector) || (type == StringHandler::Record)))
        || (isIconView() && (type == StringHandler::Connector || type == StringHandler::ExpandableConnector))) {
      ModelInfo oldModelInfo = mpModelWidget->createModelInfo();
      ModelInstance::Component *pComponent = GraphicsView::createModelInstanceComponent(mpModelWidget->getModelInstance(), name, pLibraryTreeItem->getNameStructure());
      if (pComponent) {
        addElementToView(pComponent, false, true, true, position, "", true);
        ModelInfo newModelInfo = mpModelWidget->createModelInfo();
        mpModelWidget->getUndoStack()->push(new OMCUndoCommand(mpModelWidget->getLibraryTreeItem(), oldModelInfo, newModelInfo, "Add Element", true));
        mpModelWidget->updateModelText();
      } else {
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, tr("Failed to add component <b>%1</b>.").arg(name),
                                                              Helper::scriptingKind, Helper::errorLevel));
      }
      return true;
    } else {
      if (isDiagramView()) {
        QMessageBox::information(pMainWindow, QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                                 GUIMessages::getMessage(GUIMessages::DIAGRAM_VIEW_DROP_MSG).arg(pLibraryTreeItem->getNameStructure())
                                 .arg(StringHandler::getModelicaClassType(type)), QMessageBox::Ok);
      } else {
        QMessageBox::information(pMainWindow, QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                                 GUIMessages::getMessage(GUIMessages::ICON_VIEW_DROP_MSG).arg(pLibraryTreeItem->getNameStructure())
                                 .arg(StringHandler::getModelicaClassType(type)), QMessageBox::Ok);
      }
      return false;
    }
  }
}

/*!
 * \brief GraphicsView::addElementToView
 * Adds the Element to the view and also to OMC.
 * \param pComponent
 * \param inherited
 * \param addElementToOMC
 * \param createTransformation
 * \param position
 * \param placementAnnotation
 * \param clearSelection
 */
void GraphicsView::addElementToView(ModelInstance::Component *pComponent, bool inherited, bool addElementToOMC, bool createTransformation, QPointF position,
                                    const QString &placementAnnotation, bool clearSelection)
{
  Element *pIconElement = 0;
  Element *pDiagramElement = 0;
  GraphicsView *pIconGraphicsView = mpModelWidget->getIconGraphicsView();
  GraphicsView *pDiagramGraphicsView = mpModelWidget->getDiagramGraphicsView();

  // if element is of connector type.
  if (pComponent && pComponent->getModel()->isConnector()) {
    // Connector type elements exists on icon view as well
    pIconElement = new Element(pComponent, inherited, pIconGraphicsView, createTransformation, position, placementAnnotation);
  }
  pDiagramElement = new Element(pComponent, inherited, pDiagramGraphicsView, createTransformation, position, placementAnnotation);

  // if element is of connector type && containing class is Modelica type.
  if (pIconElement && pComponent->getModel()->isConnector()) {
    // Connector type elements exists on icon view as well
    if (pIconElement->mTransformation.isValid() && pIconElement->mTransformation.getVisible()) {
      pIconGraphicsView->addElementItem(pIconElement);
    }
    if (pIconElement->isInheritedElement()) {
      pIconGraphicsView->addInheritedElementToList(pIconElement);
    } else {
      pIconGraphicsView->addElementToList(pIconElement);
    }
    // hide the element if it is connector and is protected
    pIconElement->setVisible(pComponent->isPublic());
  }

  if (pDiagramElement->mTransformation.isValid() && pDiagramElement->mTransformation.getVisible()) {
    pDiagramGraphicsView->addElementItem(pDiagramElement);
  }
  if (pDiagramElement->isInheritedElement()) {
    pDiagramGraphicsView->addInheritedElementToList(pDiagramElement);
  } else {
    pDiagramGraphicsView->addElementToList(pDiagramElement);
    if (addElementToOMC) {
      pDiagramGraphicsView->addElementToClass(pDiagramElement);
    }
    if (clearSelection) {
      if (isDiagramView()) {
        pDiagramGraphicsView->clearSelection(pDiagramElement);
      } else {
        pIconGraphicsView->clearSelection(pIconElement);
      }
    }
  }
}

void GraphicsView::addElementToClass(Element *pElement)
{
  if (mpModelWidget->getLibraryTreeItem()->isModelica()) {
    // Add the component to model in OMC.
    /* Ticket:4132
     * Always send the full path so that addComponent API doesn't fail when it makes a call to getDefaultPrefixes.
     * I updated the addComponent API to make path relative.
     */
    const QString className = pElement->getClassName();
    MainWindow::instance()->getOMCProxy()->addComponent(pElement->getName(), className, mpModelWidget->getLibraryTreeItem()->getNameStructure(), pElement->getPlacementAnnotation());
    // add uses annotation
    addUsesAnnotation(className, mpModelWidget->getLibraryTreeItem()->getNameStructure(), false);
  }
}

/*!
 * \brief GraphicsView::addUsesAnnotation
 * \param insertedClassName - the name of the class that is dragged or duplicated.
 * \param containingClassName - the name of the containing class where the component is dropped or duplicated model is added.
 * \param updateParentText - update the text of the parent.
 */
void GraphicsView::addUsesAnnotation(const QString &insertedClassName, const QString &containingClassName, bool updateParentText)
{
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  // get the toplevel class of dragged component or duplicated model
  QString packageName = StringHandler::getFirstWordBeforeDot(insertedClassName);
  LibraryTreeItem *pPackageLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(packageName);
  // get the top level class of containing class
  QString topLevelClassName = StringHandler::getFirstWordBeforeDot(containingClassName);
  LibraryTreeItem *pTopLevelLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(topLevelClassName);
  if (pPackageLibraryTreeItem && pTopLevelLibraryTreeItem) {
    // get uses annotation of the toplevel class
    QList<QList<QString > > usesAnnotation = MainWindow::instance()->getOMCProxy()->getUses(pTopLevelLibraryTreeItem->getNameStructure());
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
      MainWindow::instance()->getOMCProxy()->addClassAnnotation(pTopLevelLibraryTreeItem->getNameStructure(), usesAnnotationString);
      // if save folder structure then update the parent package
      if (pTopLevelLibraryTreeItem->isSaveFolderStructure() || updateParentText) {
        pLibraryTreeModel->updateLibraryTreeItemClassText(pTopLevelLibraryTreeItem);
      }
    }
  }
}

/*!
 * \brief GraphicsView::addElementItem
 * Adds the Element and its origin and resizer items to the GraphicsView.
 * \param pElement
 */
void GraphicsView::addElementItem(Element *pElement)
{
  addItem(pElement);
  addItem(pElement->getOriginItem());
  addItem(pElement->getBottomLeftResizerItem());
  addItem(pElement->getTopLeftResizerItem());
  addItem(pElement->getTopRightResizerItem());
  addItem(pElement->getBottomRightResizerItem());
}

/*!
 * \brief GraphicsView::removeElementItem
 * Removes the Element and its origin and resizer items from the GraphicsView.
 * \param pElement
 */
void GraphicsView::removeElementItem(Element *pElement)
{
  removeItem(pElement);
  removeItem(pElement->getOriginItem());
  removeItem(pElement->getBottomLeftResizerItem());
  removeItem(pElement->getTopLeftResizerItem());
  removeItem(pElement->getTopRightResizerItem());
  removeItem(pElement->getBottomRightResizerItem());
}

QString getComponentName(const QString &qualifiedComponentName)
{
  QString componentName = StringHandler::getFirstWordBeforeDot(qualifiedComponentName);
  if (componentName.contains("[")) {
    componentName = componentName.mid(0, componentName.indexOf("["));
  }
  return componentName;
}

/*!
 * \brief GraphicsView::deleteComponent
 * Delete the component and its corresponding connections from the components list and OMC.
 * \param component is the object to be deleted.
 */
void GraphicsView::deleteElement(Element *pElement)
{
  // First remove the connections associated to this element
  int i = 0;
  while(i != mConnectionsList.size()) {
    QString startComponentName = getComponentName(mConnectionsList[i]->getStartElementName());
    QString endComponentName = getComponentName(mConnectionsList[i]->getEndElementName());
    if ((startComponentName.compare(pElement->getName()) == 0) || (endComponentName.compare(pElement->getName()) == 0)) {
      deleteConnection(mConnectionsList[i]);
      i = 0;   //Restart iteration if map has changed
    } else {
      ++i;
    }
  }
  // First remove the transitions associated to this element
  i = 0;
  while(i != mTransitionsList.size()) {
    QString startComponentName = getComponentName(mTransitionsList[i]->getStartElementName());
    QString endComponentName = getComponentName(mTransitionsList[i]->getEndElementName());
    if ((startComponentName.compare(pElement->getName()) == 0) || (endComponentName.compare(pElement->getName()) == 0)) {
      deleteTransition(mTransitionsList[i]);
      i = 0;   //Restart iteration if map has changed
    } else {
      ++i;
    }
  }
  // First remove the initial state associated to this element
  i = 0;
  while(i != mInitialStatesList.size()) {
    QString startComponentName = getComponentName(mInitialStatesList[i]->getStartElementName());
    if ((startComponentName.compare(pElement->getName()) == 0)) {
      deleteInitialState(mInitialStatesList[i]);
      i = 0;   //Restart iteration if map has changed
    } else {
      ++i;
    }
  }
  pElement->setSelected(false);
  if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
    OMSProxy::instance()->omsDelete(pElement->getLibraryTreeItem()->getNameStructure());
  } else {
    if (pElement->getModel() && pElement->getModel()->isConnector()) {
      GraphicsView *pGraphicsView;
      if (isIconView()) {
        pGraphicsView = mpModelWidget->getDiagramGraphicsView();
      } else {
        pGraphicsView = mpModelWidget->getIconGraphicsView();
      }
      Element *pConnectorElement = pGraphicsView->getElementObject(pElement->getName());
      if (pConnectorElement) {
        pGraphicsView->removeElementItem(pConnectorElement);
        pGraphicsView->deleteElementFromList(pConnectorElement);
        pGraphicsView->addElementToOutOfSceneList(pConnectorElement);
        pConnectorElement->removeChildrenNew();
        pConnectorElement->setModelComponent(nullptr);
        pConnectorElement->setModel(nullptr);
      }
    }
    removeElementItem(pElement);
    deleteElementFromList(pElement);
    addElementToOutOfSceneList(pElement);
    deleteElementFromClass(pElement);
    pElement->removeChildrenNew();
    pElement->setModelComponent(nullptr);
    pElement->setModel(nullptr);
  }
}

/*!
 * \brief GraphicsView::deleteElementFromClass
 * Deletes the Element from class.
 * \param pElement
 */
void GraphicsView::deleteElementFromClass(Element *pElement)
{
  if (mpModelWidget && mpModelWidget->getLibraryTreeItem() && mpModelWidget->getLibraryTreeItem()->isModelica()) {
    // delete the component from OMC
    MainWindow::instance()->getOMCProxy()->deleteComponent(pElement->getName(), mpModelWidget->getLibraryTreeItem()->getNameStructure());
    /* Since we don't call getModelInstance on deleting a component so we need to update instance JSON manually by removing the component from it.
     * This is needed so the Element Browser shows the correct list of components.
     */
    if (mpModelWidget->getModelInstance()) {
      mpModelWidget->getModelInstance()->removeElement(pElement->getName());
    }
  }
}

/*!
 * \brief GraphicsView::getElementObject
 * Finds the Element
 * \param componentName
 * \return
 */
Element* GraphicsView::getElementObject(QString elementName)
{
  // look in inherited elements
  foreach (Element *pInheritedElement, mInheritedElementsList) {
    if (pInheritedElement->getName().compare(elementName) == 0) {
      return pInheritedElement;
    }
  }
  // look in elements
  foreach (Element *pElement, mElementsList) {
    if (pElement->getName().compare(elementName) == 0) {
      return pElement;
    }
  }
  return 0;
}

/*!
 * \brief GraphicsView::getElementObjectFromQualifiedName
 * Finds the Element using the qualified name.
 * \param elementQualifiedName
 * \return
 */
Element* GraphicsView::getElementObjectFromQualifiedName(QString elementQualifiedName)
{
  // look in inherited elements
  foreach (Element *pInheritedElement, mInheritedElementsList) {
    if (pInheritedElement->getModelComponent() && pInheritedElement->getModelComponent()->getQualifiedName(true).compare(elementQualifiedName) == 0) {
      return pInheritedElement;
    }
  }
  // look in elements
  foreach (Element *pElement, mElementsList) {
    if (pElement->getModelComponent() && pElement->getModelComponent()->getQualifiedName(true).compare(elementQualifiedName) == 0) {
      return pElement;
    }
  }
  return 0;
}

/*!
 * \brief GraphicsView::getUniqueElementName
 * Checks the Element default name and returns a unique name for the element.
 * \param nameStructure
 * \param name
 * \param defaultName
 * \return
 */
QString GraphicsView::getUniqueElementName(const QString &nameStructure, const QString &name, QString *defaultName)
{
  // get the model defaultComponentName
  *defaultName = MainWindow::instance()->getOMCProxy()->getDefaultComponentName(nameStructure);
  QString newName;
  if (!defaultName->isEmpty()) {
    newName = getUniqueElementName(nameStructure, *defaultName);
  } else {
    newName = getUniqueElementName(nameStructure, StringHandler::toCamelCase(name));
  }
  return newName;
}

/*!
 * \brief GraphicsView::getUniqueElementName
 * Creates a unique element name.
 * \param nameStructure
 * \param elementName
 * \param number
 * \return
 */
QString GraphicsView::getUniqueElementName(const QString &nameStructure, QString elementName, int number)
{
  QString name = elementName;
  if (number > 0) {
    if (!name.isEmpty()) {
      bool ok;
      int endNumber = name.right(1).toInt(&ok);
      if (ok) {
        number = endNumber + 1;
        elementName.chop(1);
      }
    }
    name = QString("%1%2").arg(elementName).arg(number);
  }

  if (!checkElementName(nameStructure, name)) {
    name = getUniqueElementName(nameStructure, elementName, ++number);
  }
  return name;
}

/*!
 * \brief GraphicsView::checkElementName
 * Checks the element name against the Modelica keywords as well.
 * Checks if the element name is same as class name.
 * Checks if the element with the same name already exists or not.
 * \param nameStructure
 * \param elementName
 * \return
 */
bool GraphicsView::checkElementName(const QString &nameStructure, QString elementName)
{
  // if element name is any keyword of Modelica
  if (mpModelWidget->getLibraryTreeItem()->isModelica()) {
    if (ModelicaHighlighter::getKeywords().contains(elementName)) {
      return false;
    }
  }
  // if element name is same as class name
  QString className = nameStructure;
  if (mpModelWidget->getLibraryTreeItem()->isInPackageOneFile()) {
    className = StringHandler::getLastWordAfterDot(className);
  }
  if (className.compare(elementName) == 0) {
    return false;
  }
  // if element with same name exists
  foreach (Element *pElement, mElementsList) {
    if (pElement->getName().compare(elementName, Qt::CaseSensitive) == 0) {
      return false;
    }
  }
  return true;
}

/*!
 * \brief GraphicsView::connectionExists
 * Checks if the connection already exists.
 * \param startElementName
 * \param endElementName
 * \param inherited
 * \return
 */
bool GraphicsView::connectionExists(const QString &startElementName, const QString &endElementName, bool inherited)
{
  QList<LineAnnotation*> connections;
  if (!inherited) {
    connections = mConnectionsList;
  } else {
    connections = mInheritedConnectionsList;
  }
  foreach (LineAnnotation *pConnectionLineAnnotation, connections) {
    if (pConnectionLineAnnotation->getStartElementName().compare(startElementName) == 0 && pConnectionLineAnnotation->getEndElementName().compare(endElementName) == 0) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, tr("Connection connect(%1, %2) already exists.").arg(startElementName, endElementName),
                                                            Helper::scriptingKind, Helper::errorLevel));
      return true;
    }
  }
  return false;
}

/*!
 * \brief updateConnectionIndexes
 * Updates the connection indexes in the connection name with the passed index.
 * \param connectionComponentName
 * \param componentConnectionIndex
 * \return
 */
QString updateConnectionIndexes(const QString &connectionComponentName, int &componentConnectionIndex) {
  QString newConnectionComponentName = "";
  int endIndex = connectionComponentName.lastIndexOf(']');
  int startIndex = connectionComponentName.lastIndexOf('[', endIndex);
  if (startIndex > -1 && endIndex > -1) {
    newConnectionComponentName = connectionComponentName.left(startIndex);
    newConnectionComponentName += "[";
    QStringList range = connectionComponentName.mid(startIndex + 1, endIndex - startIndex - 1).split(':');
    if (range.size() > 1) {
      newConnectionComponentName += QString("%1:%2").arg(componentConnectionIndex).arg(componentConnectionIndex + (range.at(1).toInt() - range.at(0).toInt()));
      componentConnectionIndex = componentConnectionIndex + (range.at(1).toInt() - range.at(0).toInt());
    } else {
      newConnectionComponentName += QString("%1").arg(componentConnectionIndex);
    }
    newConnectionComponentName += "]";
  }
  return newConnectionComponentName;
}

/*!
 * \brief GraphicsView::addConnectionDetails
 * Adds connection details by linking with start and end connector.
 * \param pConnectionLineAnnotation
 */
void GraphicsView::addConnectionDetails(LineAnnotation *pConnectionLineAnnotation)
{
  // Add the start element connection details.
  Element *pStartElement = pConnectionLineAnnotation->getStartElement();
  if (pStartElement) {
    if (pStartElement->getRootParentElement()) {
      pStartElement->getRootParentElement()->addConnectionDetails(pConnectionLineAnnotation);
      if (pConnectionLineAnnotation->isTransition()) {
        pStartElement->getRootParentElement()->setHasTransition(true);
      } else if (pConnectionLineAnnotation->isInitialState()) {
        pStartElement->getRootParentElement()->setIsInitialState(true);
      }
    } else {
      pStartElement->addConnectionDetails(pConnectionLineAnnotation);
      if (pConnectionLineAnnotation->isTransition()) {
        pStartElement->setHasTransition(true);
      } else if (pConnectionLineAnnotation->isInitialState()) {
        pStartElement->setIsInitialState(false);
      }
    }
  }
  // Add the end element connection details.
  Element *pEndElement = pConnectionLineAnnotation->getEndElement();
  if (pEndElement) {
    if (pEndElement->getRootParentElement()) {
      pEndElement->getRootParentElement()->addConnectionDetails(pConnectionLineAnnotation);
      if (pConnectionLineAnnotation->isTransition()) {
        pEndElement->getRootParentElement()->setHasTransition(true);
      }
    } else {
      pEndElement->addConnectionDetails(pConnectionLineAnnotation);
      if (pConnectionLineAnnotation->isTransition()) {
        pEndElement->setHasTransition(true);
      }
    }
  }
  pConnectionLineAnnotation->updateToolTip();
}

/*!
 * \brief GraphicsView::addConnectionToView
 * Adds the connection to the view.
 * \param pConnectionLineAnnotation
 * \param inherited
 */
void GraphicsView::addConnectionToView(LineAnnotation *pConnectionLineAnnotation, bool inherited)
{
  addConnectionDetails(pConnectionLineAnnotation);
  if (inherited) {
    addInheritedConnectionToList(pConnectionLineAnnotation);
  } else {
    addConnectionToList(pConnectionLineAnnotation);
  }
  addItem(pConnectionLineAnnotation);
  deleteConnectionFromOutOfSceneList(pConnectionLineAnnotation);
}

/*!
 * \brief GraphicsView::addConnectionToClass
 * Adds the connection to class.
 * \param pConnectionLineAnnotation - the connection to add.
 * \param deleteUndo - True when undo of a delete connection is called.
 * \return
 */
bool GraphicsView::addConnectionToClass(LineAnnotation *pConnectionLineAnnotation, bool deleteUndo)
{
  if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
    // if TLM connection
    bool connectionSuccessful = false;
    if (pConnectionLineAnnotation->getOMSConnectionType() == oms_connection_tlm) {
      connectionSuccessful = OMSProxy::instance()->addTLMConnection(pConnectionLineAnnotation->getStartElement()->getLibraryTreeItem()->getNameStructure(),
                                                                    pConnectionLineAnnotation->getEndElement()->getLibraryTreeItem()->getNameStructure(),
                                                                    pConnectionLineAnnotation->getDelay().toDouble(), pConnectionLineAnnotation->getAlpha().toDouble(),
                                                                    pConnectionLineAnnotation->getZf().toDouble(), pConnectionLineAnnotation->getZfr().toDouble());
    } else {
      connectionSuccessful = OMSProxy::instance()->addConnection(pConnectionLineAnnotation->getStartElement()->getLibraryTreeItem()->getNameStructure(),
                                                                 pConnectionLineAnnotation->getEndElement()->getLibraryTreeItem()->getNameStructure());
    }
    if (connectionSuccessful) {
      pConnectionLineAnnotation->updateOMSConnection();
      return true;
    } else {
      return false;
    }
  } else {
    MainWindow *pMainWindow = MainWindow::instance();
    // update connectorSizing on start component if exists
    bool isStartComponentConnectorSizing = GraphicsView::updateElementConnectorSizingParameter(this, mpModelWidget->getLibraryTreeItem()->getNameStructure(), pConnectionLineAnnotation->getStartElement());
    // update connectorSizing on end component if exists
    bool isEndComponentConnectorSizing = GraphicsView::updateElementConnectorSizingParameter(this, mpModelWidget->getLibraryTreeItem()->getNameStructure(), pConnectionLineAnnotation->getEndElement());
    if (deleteUndo) {
      if (isStartComponentConnectorSizing) {
        int connectionIndex = numberOfElementConnections(pConnectionLineAnnotation->getStartElement(), pConnectionLineAnnotation) + 1;
        QString newStartComponentName = updateConnectionIndexes(pConnectionLineAnnotation->getStartElementName(), connectionIndex);
        if (!newStartComponentName.isEmpty()) {
          pConnectionLineAnnotation->setStartElementName(newStartComponentName);
          pConnectionLineAnnotation->updateToolTip();
        }
      }
      if (isEndComponentConnectorSizing) {
        int connectionIndex = numberOfElementConnections(pConnectionLineAnnotation->getEndElement(), pConnectionLineAnnotation) + 1;
        QString newEndComponentName = updateConnectionIndexes(pConnectionLineAnnotation->getEndElementName(), connectionIndex);
        if (!newEndComponentName.isEmpty()) {
          pConnectionLineAnnotation->setEndElementName(newEndComponentName);
          pConnectionLineAnnotation->updateToolTip();
        }
      }
    }
    // add connection
    pMainWindow->getOMCProxy()->addConnection(pConnectionLineAnnotation->getStartElementName(), pConnectionLineAnnotation->getEndElementName(),
                                              mpModelWidget->getLibraryTreeItem()->getNameStructure(),
                                              QString("annotate=").append(pConnectionLineAnnotation->getShapeAnnotation()));
  }
  return true;
}

/*!
 * \brief elementIndexesRangeInConnection
 * Returns the element array index in connection.
 * It could be just index or range e.g., 1:3
 * \param connectionElementName
 * \return
 */
QStringList elementIndexesRangeInConnection(const QString &connectionElementName)
{
  int endIndex = connectionElementName.lastIndexOf(']');
  int startIndex = connectionElementName.lastIndexOf('[', endIndex);
  if (startIndex > -1 && endIndex > -1) {
    return connectionElementName.mid(startIndex + 1, endIndex - startIndex - 1).split(':');
  }
  return QStringList();
}

/*!
 * \brief elementIndexInConnection
 * Return the element array index used in connection.
 * If the index is range then the start of range is returned e.g., 1:3 returns 1 and 2:4 returns 2.
 * \param connectionElementName
 * \return
 */
int elementIndexInConnection(const QString &connectionElementName)
{
  QStringList range = elementIndexesRangeInConnection(connectionElementName);
  return range.value(0, "0").toInt();
}

/*!
 * \brief GraphicsView::deleteConnectionFromClass
 * Deletes the connection from class.
 * \param pConnectionLineAnnotation - the connection to delete.
 */
void GraphicsView::deleteConnectionFromClass(LineAnnotation *pConnectionLineAnnotation)
{
  MainWindow *pMainWindow = MainWindow::instance();
  if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
    OMSProxy::instance()->deleteConnection(pConnectionLineAnnotation->getStartElementName(), pConnectionLineAnnotation->getEndElementName());
  } else {
    // delete the connection
    if (pMainWindow->getOMCProxy()->deleteConnection(pConnectionLineAnnotation->getStartElementName(), pConnectionLineAnnotation->getEndElementName(), mpModelWidget->getLibraryTreeItem()->getNameStructure())) {
      // update connectorSizing on start element if exists
      bool isStartComponentConnectorSizing = GraphicsView::updateElementConnectorSizingParameter(this, mpModelWidget->getLibraryTreeItem()->getNameStructure(), pConnectionLineAnnotation->getStartElement());
      // update connectorSizing on end element if exists
      bool isEndComponentConnectorSizing = GraphicsView::updateElementConnectorSizingParameter(this, mpModelWidget->getLibraryTreeItem()->getNameStructure(), pConnectionLineAnnotation->getEndElement());
      // if the element is connectorSizing then get the index used in deleted connection
      int startConnectionIndex = 0;
      if (isStartComponentConnectorSizing) {
        startConnectionIndex = elementIndexInConnection(pConnectionLineAnnotation->getStartElementName());
      }
      int endConnectionIndex = 0;
      if (isEndComponentConnectorSizing) {
        endConnectionIndex = elementIndexInConnection(pConnectionLineAnnotation->getEndElementName());
      }
      if (isStartComponentConnectorSizing || isEndComponentConnectorSizing) {
        // update the connections if some middle connectorSizing connection is removed
        foreach (LineAnnotation *pOtherConnectionLineAnnotation, mConnectionsList) {
          // if deleted connection then continue
          if (pOtherConnectionLineAnnotation == pConnectionLineAnnotation) {
            continue;
          }
          bool updateConnection = false;
          // start component matches
          QString startComponentName = pOtherConnectionLineAnnotation->getStartElementName();
          if (pOtherConnectionLineAnnotation->getStartElement() == pConnectionLineAnnotation->getStartElement()) {
            if (elementIndexInConnection(startComponentName) > startConnectionIndex) {
              pOtherConnectionLineAnnotation->setStartElementName(updateConnectionIndexes(startComponentName, startConnectionIndex));
              startConnectionIndex++;
              updateConnection = true;
            }
          }
          if (pOtherConnectionLineAnnotation->getStartElement() == pConnectionLineAnnotation->getEndElement()) {
            if (elementIndexInConnection(startComponentName) > endConnectionIndex) {
              pOtherConnectionLineAnnotation->setStartElementName(updateConnectionIndexes(startComponentName, endConnectionIndex));
              endConnectionIndex++;
              updateConnection = true;
            }
          }
          // end component matches
          QString endComponentName = pOtherConnectionLineAnnotation->getEndElementName();
          if (pOtherConnectionLineAnnotation->getEndElement() == pConnectionLineAnnotation->getEndElement()) {
            if (elementIndexInConnection(endComponentName) > endConnectionIndex) {
              pOtherConnectionLineAnnotation->setEndElementName(updateConnectionIndexes(endComponentName, endConnectionIndex));
              endConnectionIndex++;
              updateConnection = true;
            }
          }
          if (pOtherConnectionLineAnnotation->getEndElement() == pConnectionLineAnnotation->getStartElement()) {
            if (elementIndexInConnection(endComponentName) > startConnectionIndex) {
              pOtherConnectionLineAnnotation->setEndElementName(updateConnectionIndexes(endComponentName, startConnectionIndex));
              startConnectionIndex++;
              updateConnection = true;
            }
          }
          // update the connection with updated connectorSizing indexes.
          if (updateConnection) {
            pMainWindow->getOMCProxy()->updateConnectionNames(mpModelWidget->getLibraryTreeItem()->getNameStructure(), startComponentName, endComponentName,
                                                              pOtherConnectionLineAnnotation->getStartElementName(), pOtherConnectionLineAnnotation->getEndElementName());
            pOtherConnectionLineAnnotation->updateToolTip();
          }
        }
      }
    }
  }
}

/*!
 * \brief GraphicsView::removeConnectionDetails
 * Removes connection details that are linked with start and end connector.
 * \param pConnectionLineAnnotation
 */
void GraphicsView::removeConnectionDetails(LineAnnotation *pConnectionLineAnnotation)
{
  // Remove the start element connection details.
  Element *pStartElement = pConnectionLineAnnotation->getStartElement();
  if (pStartElement) {
    if (pStartElement->getRootParentElement()) {
      pStartElement->getRootParentElement()->removeConnectionDetails(pConnectionLineAnnotation);
      if (pConnectionLineAnnotation->isTransition()) {
        pStartElement->getRootParentElement()->setHasTransition(false);
      } else if (pConnectionLineAnnotation->isInitialState()) {
        pStartElement->getRootParentElement()->setIsInitialState(false);
      }
    } else {
      pStartElement->removeConnectionDetails(pConnectionLineAnnotation);
      if (pConnectionLineAnnotation->isTransition()) {
        pStartElement->setHasTransition(false);
      } else if (pConnectionLineAnnotation->isInitialState()) {
        pStartElement->setIsInitialState(false);
      }
    }
  }
  pConnectionLineAnnotation->setStartElement(0);
  // Remove the end element connection details.
  Element *pEndElement = pConnectionLineAnnotation->getEndElement();
  if (pEndElement) {
    if (pEndElement->getRootParentElement()) {
      pEndElement->getRootParentElement()->removeConnectionDetails(pConnectionLineAnnotation);
      if (pConnectionLineAnnotation->isTransition()) {
        pEndElement->getRootParentElement()->setHasTransition(false);
      }
    } else {
      pEndElement->removeConnectionDetails(pConnectionLineAnnotation);
      if (pConnectionLineAnnotation->isTransition()) {
        pEndElement->setHasTransition(false);
      }
    }
  }
  pConnectionLineAnnotation->setEndElement(0);
}

/*!
 * \brief GraphicsView::removeConnectionFromView
 * Removes the connection from the view.
 * \param pConnectionLineAnnotation
 */
void GraphicsView::removeConnectionFromView(LineAnnotation *pConnectionLineAnnotation)
{
  // unselect the connection so it will not receive further signals
  pConnectionLineAnnotation->setSelected(false);
  pConnectionLineAnnotation->clearCollidingConnections();
  removeConnectionDetails(pConnectionLineAnnotation);
  deleteConnectionFromList(pConnectionLineAnnotation);
  addConnectionToOutOfSceneList(pConnectionLineAnnotation);
  removeItem(pConnectionLineAnnotation);
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
 * \brief GraphicsView::numberOfElementConnections
 * Counts the number of connections of the element.
 * \param pElement
 * \param pExcludeConnectionLineAnnotation
 * \return
 */
int GraphicsView::numberOfElementConnections(Element *pElement, LineAnnotation *pExcludeConnectionLineAnnotation)
{
  int connections = 0;
  foreach (LineAnnotation *pConnectionLineAnnotation, mConnectionsList) {
    if (pExcludeConnectionLineAnnotation && pExcludeConnectionLineAnnotation == pConnectionLineAnnotation) {
      continue;
    }
    if (pConnectionLineAnnotation->getStartElement() == pElement || pConnectionLineAnnotation->getEndElement() == pElement) {
      // always count one connection if we are in here. Then look for array connections.
      connections++;
      QString connectionElementName;
      if (pConnectionLineAnnotation->getStartElement() == pElement) {
        connectionElementName = pConnectionLineAnnotation->getStartElementName();
      } else {
        connectionElementName = pConnectionLineAnnotation->getEndElementName();
      }
      QStringList range = elementIndexesRangeInConnection(connectionElementName);
      if (range.size() > 1) {
        connections += (range.at(1).toInt() - range.at(0).toInt());
      }
    }
  }
  return connections;
}

/*!  * \brief GraphicsView::getConnectorName
 * Returns the name of the connector element as a string.
 * \param pConnector
 */
QString GraphicsView::getConnectorName(Element *pConnector)
{
  QString name;
  if (!pConnector) return name;

  if (pConnector->getParentElement()) {
    name = QString("%1.%2").arg(pConnector->getRootParentElement()->getName()).arg(pConnector->getName());
  } else {
    name = pConnector->getName();
  }

  if (!mpModelWidget->getLibraryTreeItem()->isSSP() && pConnector->isConnectorSizing()) {
    name = QString("%1[%2]").arg(name).arg(numberOfElementConnections(pConnector) + 1);
  }

  return name;
}

/*!
 * \brief GraphicsView::addTransitionToView
 * Adds the transition to the view.
 * \param pTransitionLineAnnotation
 * \param inherited
 */
void GraphicsView::addTransitionToView(LineAnnotation *pTransitionLineAnnotation, bool inherited)
{
  addConnectionDetails(pTransitionLineAnnotation);
  if (inherited) {
    addInheritedTransitionToList(pTransitionLineAnnotation);
  } else {
    addTransitionToList(pTransitionLineAnnotation);
  }

  if (pTransitionLineAnnotation->getTextAnnotation()) {
    pTransitionLineAnnotation->getTextAnnotation()->setTextString("%condition");
    pTransitionLineAnnotation->getTextAnnotation()->updateTextString();
    pTransitionLineAnnotation->updateTransitionTextPosition();
  }

  addItem(pTransitionLineAnnotation);
}

/*!
 * \brief GraphicsView::addTransitionToClass
 * Adds the transition to class.
 * \param pTransitionLineAnnotation - the transition to add.
 */
void GraphicsView::addTransitionToClass(LineAnnotation *pTransitionLineAnnotation)
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  if (pOMCProxy->addTransition(mpModelWidget->getLibraryTreeItem()->getNameStructure(), pTransitionLineAnnotation->getStartElementName(),
                               pTransitionLineAnnotation->getEndElementName(), pTransitionLineAnnotation->getCondition(),
                               pTransitionLineAnnotation->getImmediate(), pTransitionLineAnnotation->getReset(),
                               pTransitionLineAnnotation->getSynchronize(), pTransitionLineAnnotation->getPriority(),
                               QString("annotate=$annotation(%1,%2)").arg(pTransitionLineAnnotation->getShapeAnnotation())
                               .arg(pTransitionLineAnnotation->getTextAnnotation()->getShapeAnnotation()))) {
  }
}

/*!
 * \brief GraphicsView::removeTransitionFromView
 * Removes the transition from the view.
 * \param pTransitionLineAnnotation
 */
void GraphicsView::removeTransitionFromView(LineAnnotation *pTransitionLineAnnotation)
{
  removeConnectionDetails(pTransitionLineAnnotation);
  deleteTransitionFromList(pTransitionLineAnnotation);
  addTransitionToOutOfSceneList(pTransitionLineAnnotation);
  if (pTransitionLineAnnotation->getTextAnnotation()) {
    pTransitionLineAnnotation->getTextAnnotation()->setTextString("%condition");
    pTransitionLineAnnotation->getTextAnnotation()->updateTextString();
    pTransitionLineAnnotation->updateTransitionTextPosition();
  }
  removeItem(pTransitionLineAnnotation);
}

/*!
 * \brief GraphicsView::deleteTransitionFromClass
 * Deletes the transition from class.
 * \param pTransitionLineAnnotation - the transition to delete.
 */
void GraphicsView::deleteTransitionFromClass(LineAnnotation *pTransitionLineAnnotation)
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  pOMCProxy->deleteTransition(mpModelWidget->getLibraryTreeItem()->getNameStructure(), pTransitionLineAnnotation->getStartElementName(),
                              pTransitionLineAnnotation->getEndElementName(), pTransitionLineAnnotation->getCondition(),
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
 * \brief GraphicsView::addInitialStateToView
 * Adds the initial state to the view.
 * \param pInitialStateLineAnnotation
 * \param inherited
 */
void GraphicsView::addInitialStateToView(LineAnnotation *pInitialStateLineAnnotation, bool inherited)
{
  addConnectionDetails(pInitialStateLineAnnotation);
  if (inherited) {
    addInheritedInitialStateToList(pInitialStateLineAnnotation);
  } else {
    addInitialStateToList(pInitialStateLineAnnotation);
  }

  addItem(pInitialStateLineAnnotation);
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
                                 pInitialStateLineAnnotation->getStartElementName(),
                                 QString("annotate=").append(pInitialStateLineAnnotation->getShapeAnnotation()))) {
  }
}

/*!
 * \brief GraphicsView::removeInitialStateFromView
 * Removes the initial state from the view.
 * \param pInitialStateLineAnnotation
 */
void GraphicsView::removeInitialStateFromView(LineAnnotation *pInitialStateLineAnnotation)
{
  removeConnectionDetails(pInitialStateLineAnnotation);
  deleteInitialStateFromList(pInitialStateLineAnnotation);
  addInitialStateToOutOfSceneList(pInitialStateLineAnnotation);
  removeItem(pInitialStateLineAnnotation);
}

/*!
 * \brief GraphicsView::deleteInitialStateFromClass
 * Deletes the initial state from class.
 * \param pInitialStateLineAnnotation - the initial state to delete.
 */
void GraphicsView::deleteInitialStateFromClass(LineAnnotation *pInitialStateLineAnnotation)
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  pOMCProxy->deleteInitialState(mpModelWidget->getLibraryTreeItem()->getNameStructure(), pInitialStateLineAnnotation->getStartElementName());
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
#if QT_VERSION >= QT_VERSION_CHECK(5, 13, 0)
  mShapesList.swapItemsAt(shapeIndex, shapeIndex + 1);
#else // QT_VERSION_CHECK
  mShapesList.swap(shapeIndex, shapeIndex + 1);
#endif // QT_VERSION_CHECK
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
#if QT_VERSION >= QT_VERSION_CHECK(5, 13, 0)
  mShapesList.swapItemsAt(shapeIndex - 1, shapeIndex);
#else // QT_VERSION_CHECK
  mShapesList.swap(shapeIndex - 1, shapeIndex);
#endif // QT_VERSION_CHECK
  // update the shapes z index
  for (int i = 0 ; i < mShapesList.size() ; i++) {
    mShapesList.at(i)->setZValue(i + 1);
  }
  // update class annotation.
  addClassAnnotation();
}

/*!
 * \brief GraphicsView::clearGraphicsView
 * Clears everything from the GraphicsView.
 */
void GraphicsView::clearGraphicsView()
{
  removeAllShapes();
  removeOutOfSceneShapes();
  removeAllConnections();
  removeOutOfSceneConnections();
  removeAllTransitions();
  removeOutOfSceneTransitions();
  removeAllInitialStates();
  removeOutOfSceneInitialStates();
  removeClassComponents();
  removeOutOfSceneClassComponents();
  removeInheritedClassShapes();
  removeInheritedClassConnections();
  removeInheritedClassTransitions();
  removeInheritedClassInitialStates();
  removeInheritedClassElements();
  removeErrorTextShape();
  scene()->clear();
  mAllItems.clear();
}

/*!
 * \brief GraphicsView::clearGraphicsViewsExceptOutOfSceneItems
 * Clears everything from the GraphicsView except for out of scene items.
 */
void GraphicsView::clearGraphicsViewsExceptOutOfSceneItems()
{
  removeAllShapes();
  removeAllConnections();
  removeAllTransitions();
  removeAllInitialStates();
  removeClassComponents();
  removeInheritedClassShapes();
  removeInheritedClassConnections();
  removeInheritedClassTransitions();
  removeInheritedClassInitialStates();
  removeInheritedClassElements();
  removeErrorTextShape();
  scene()->clear();
  mAllItems.clear();
}

/*!
 * \brief GraphicsView::removeClassComponents
 * Removes all the class components.
 */
void GraphicsView::removeClassComponents()
{
  foreach (Element *pElement, mElementsList) {
    pElement->removeChildren();
    deleteElementFromList(pElement);
    removeElementItem(pElement);
    delete pElement->getOriginItem();
    delete pElement->getBottomLeftResizerItem();
    delete pElement->getTopLeftResizerItem();
    delete pElement->getTopRightResizerItem();
    delete pElement->getBottomRightResizerItem();
    delete pElement;
  }
}

/*!
 * \brief GraphicsView::removeShapesFromScene
 * Removes the shapes from the scene.
 */
void GraphicsView::removeShapesFromScene()
{
  foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
    removeItem(pShapeAnnotation);
    removeItem(pShapeAnnotation->getOriginItem());
    deleteShapeFromList(pShapeAnnotation);
  }
}

/*!
 * \brief GraphicsView::removeElementsFromView
 * Removes all the elements from the scene and add them to mOutOfSceneElementsList.
 */
void GraphicsView::removeElementsFromScene()
{
  foreach (Element *pElement, mElementsList) {
    removeElementItem(pElement);
    addElementToOutOfSceneList(pElement);
    deleteElementFromList(pElement);
  }
}

/*!
 * \brief GraphicsView::removeOutOfSceneClassComponents
 * Removes all the class components that are not deleted but are removed from scene.
 */
void GraphicsView::removeOutOfSceneClassComponents()
{
  foreach (Element *pComponent, mOutOfSceneElementsList) {
    pComponent->removeChildren();
    deleteElementFromOutOfSceneList(pComponent);
    delete pComponent->getOriginItem();
    delete pComponent->getBottomLeftResizerItem();
    delete pComponent->getTopLeftResizerItem();
    delete pComponent->getTopRightResizerItem();
    delete pComponent->getBottomRightResizerItem();
    delete pComponent;
  }
}

/*!
 * \brief GraphicsView::removeInheritedClassShapes
 * Removes all the inherited class shapes.
 */
void GraphicsView::removeInheritedClassShapes()
{
  foreach (ShapeAnnotation *pShapeAnnotation, mInheritedShapesList) {
    deleteInheritedShapeFromList(pShapeAnnotation);
    removeItem(pShapeAnnotation);
    removeItem(pShapeAnnotation->getOriginItem());
    delete pShapeAnnotation;
  }
}

/*!
 * \brief GraphicsView::removeInheritedClassElements
 * Removes all the class inherited elements.
 */
void GraphicsView::removeInheritedClassElements()
{
  foreach (Element *pElement, mInheritedElementsList) {
    pElement->removeChildren();
    deleteInheritedElementFromList(pElement);
    removeElementItem(pElement);
    delete pElement->getOriginItem();
    delete pElement->getBottomLeftResizerItem();
    delete pElement->getTopLeftResizerItem();
    delete pElement->getTopRightResizerItem();
    delete pElement->getBottomRightResizerItem();
    delete pElement;
  }
}

/*!
 * \brief GraphicsView::removeInheritedClassConnections
 * Removes all the class inherited connections.
 */
void GraphicsView::removeInheritedClassConnections()
{
  foreach (LineAnnotation *pConnectionLineAnnotation, mInheritedConnectionsList) {
    pConnectionLineAnnotation->clearCollidingConnections();
    deleteInheritedConnectionFromList(pConnectionLineAnnotation);
    removeItem(pConnectionLineAnnotation);
    delete pConnectionLineAnnotation;
  }
}

/*!
 * \brief GraphicsView::removeInheritedClassTransitions
 * Removes all the class inherited transitions.
 */
void GraphicsView::removeInheritedClassTransitions()
{
  foreach (LineAnnotation *pTransitionLineAnnotation, mInheritedTransitionsList) {
    removeConnectionDetails(pTransitionLineAnnotation);
    deleteInheritedTransitionFromList(pTransitionLineAnnotation);
    removeItem(pTransitionLineAnnotation);
    delete pTransitionLineAnnotation;
  }
}

/*!
 * \brief GraphicsView::removeInheritedClassInitialStates
 * Removes all the class inherited initial states.
 */
void GraphicsView::removeInheritedClassInitialStates()
{
  foreach (LineAnnotation *pInitialStateLineAnnotation, mInheritedInitialStatesList) {
    deleteInheritedInitialStateFromList(pInitialStateLineAnnotation);
    removeItem(pInitialStateLineAnnotation);
    delete pInitialStateLineAnnotation;
  }
}

/*!
 * \brief GraphicsView::removeOutOfSceneShapes
 * Removes all the shapes that are not deleted but are removed from scene.
 */
void GraphicsView::removeOutOfSceneShapes()
{
  foreach (ShapeAnnotation *pShapeAnnotation, mOutOfSceneShapesList) {
    deleteShapeFromOutOfSceneList(pShapeAnnotation);
    delete pShapeAnnotation;
  }
}

/*!
 * \brief GraphicsView::removeConnectionsFromScene
 * Removes all the connections from the scene and add them to mOutOfSceneConnectionsList.
 */
void GraphicsView::removeConnectionsFromScene()
{
  foreach (LineAnnotation *pConnectionLineAnnotation, mConnectionsList) {
    pConnectionLineAnnotation->clearCollidingConnections();
    removeConnectionDetails(pConnectionLineAnnotation);
    removeItem(pConnectionLineAnnotation);
    addConnectionToOutOfSceneList(pConnectionLineAnnotation);
    deleteConnectionFromList(pConnectionLineAnnotation);
  }
}

/*!
 * \brief GraphicsView::removeOutOfSceneConnections
 * Removes all the connections that are not deleted but are removed from scene.
 */
void GraphicsView::removeOutOfSceneConnections()
{
  foreach (LineAnnotation *pLineAnnotation, mOutOfSceneConnectionsList) {
    deleteConnectionFromOutOfSceneList(pLineAnnotation);
    delete pLineAnnotation;
  }
}

/*!
 * \brief GraphicsView::removeTransitionsFromScene
 * Removes all the transitons from the scene and add them to mOutOfSceneTransitionsList.
 */
void GraphicsView::removeTransitionsFromScene()
{
  foreach (LineAnnotation *pTransitionLineAnnotation, mTransitionsList) {
    removeConnectionDetails(pTransitionLineAnnotation);
    removeItem(pTransitionLineAnnotation);
    addTransitionToOutOfSceneList(pTransitionLineAnnotation);
    deleteTransitionFromList(pTransitionLineAnnotation);
  }
}

/*!
 * \brief GraphicsView::removeOutOfSceneTransitions
 * Removes all the class transitions that are not deleted but are removed from scene.
 */
void GraphicsView::removeOutOfSceneTransitions()
{
  foreach (LineAnnotation *pLineAnnotation, mOutOfSceneTransitionsList) {
    deleteTransitionFromOutOfSceneList(pLineAnnotation);
    delete pLineAnnotation;
  }
}

/*!
 * \brief GraphicsView::removeInitialStatesFromScene
 * Removes all the initial states from the scene and add them to mOutOfSceneInitialStatesList.
 */
void GraphicsView::removeInitialStatesFromScene()
{
  foreach (LineAnnotation *pInitialStateLineAnnotation, mInitialStatesList) {
    removeConnectionDetails(pInitialStateLineAnnotation);
    removeItem(pInitialStateLineAnnotation);
    addInitialStateToOutOfSceneList(pInitialStateLineAnnotation);
    deleteInitialStateFromList(pInitialStateLineAnnotation);
  }
}

/*!
 * \brief GraphicsView::removeOutOfSceneInitialStates
 * Removes all the initial states that are not deleted but are removed from scene.
 */
void GraphicsView::removeOutOfSceneInitialStates()
{
  foreach (LineAnnotation *pLineAnnotation, mOutOfSceneInitialStatesList) {
    deleteInitialStateFromOutOfSceneList(pLineAnnotation);
    delete pLineAnnotation;
  }
}

void GraphicsView::createLineShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView()) {
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
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView()) {
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
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView()) {
    return;
  }

  if (!isCreatingRectangleShape()) {
    mpRectangleShapeAnnotation = new RectangleAnnotation("", this);
    mpModelWidget->getUndoStack()->push(new AddShapeCommand(mpRectangleShapeAnnotation));
    setIsCreatingRectangleShape(true);
    mpRectangleShapeAnnotation->replaceExtent(0, point);
    mpRectangleShapeAnnotation->replaceExtent(1, point);
  } else { // if we are already creating a rectangle then finish creating it.
    finishDrawingRectangleShape();
  }
}

void GraphicsView::createEllipseShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView()) {
    return;
  }

  if (!isCreatingEllipseShape()) {
    mpEllipseShapeAnnotation = new EllipseAnnotation("", this);
    mpModelWidget->getUndoStack()->push(new AddShapeCommand(mpEllipseShapeAnnotation));
    setIsCreatingEllipseShape(true);
    mpEllipseShapeAnnotation->replaceExtent(0, point);
    mpEllipseShapeAnnotation->replaceExtent(1, point);
  } else { // if we are already creating an ellipse then finish creating it.
    finishDrawingEllipseShape();
  }
}

void GraphicsView::createTextShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView()) {
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
    finishDrawingTextShape();
  }
}

void GraphicsView::createBitmapShape(QPointF point)
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView()) {
    return;
  }

  if (!isCreatingBitmapShape()) {
    mpBitmapShapeAnnotation = new BitmapAnnotation(mpModelWidget->getLibraryTreeItem()->getFileName(), "", this);
    mpModelWidget->getUndoStack()->push(new AddShapeCommand(mpBitmapShapeAnnotation));
    setIsCreatingBitmapShape(true);
    mpBitmapShapeAnnotation->replaceExtent(0, point);
    mpBitmapShapeAnnotation->replaceExtent(1, point);
  } else { // if we are already creating a bitmap then finish creating it.
    finishDrawingBitmapShape();
  }
}

/*!
 * \brief GraphicsView::finishDrawingGenericShape
 * This function is called when shape creation operation is cancelled.
 * So we want to unselect the shapes in this case except for Text and Bitmap
 * since they have their respective pop-up dialogs which doesn't lead to selection and focus issue.
 */
void GraphicsView::finishDrawingGenericShape()
{
  if (mIsCreatingLineShape){
    finishDrawingLineShape();
    mpLineShapeAnnotation->setSelected(false);
  } else if (mIsCreatingPolygonShape)  {
    finishDrawingPolygonShape();
    mpPolygonShapeAnnotation->setSelected(false);
  } else if (mIsCreatingRectangleShape) {
    finishDrawingRectangleShape();
    mpRectangleShapeAnnotation->setSelected(false);
  } else if (mIsCreatingEllipseShape) {
    finishDrawingEllipseShape();
    mpEllipseShapeAnnotation->setSelected(false);
  } else if (mIsCreatingTextShape) {
    finishDrawingTextShape();
  } else /*Otherwise we have a bitmap*/{
    finishDrawingBitmapShape();
  }
}

void GraphicsView::finishDrawingLineShape(bool removeLastAddedPoint)
{
  setIsCreatingLineShape(false);
  if (removeLastAddedPoint) {
    mpLineShapeAnnotation->removePoint(mpLineShapeAnnotation->getPoints().size() - 1);
  }
  setOriginAdjustAndInitialize(mpLineShapeAnnotation);
  mpLineShapeAnnotation->setSelected(true);
  uncheckAllShapeDrawingActions();
  checkEmitUpdateSelect(false, mpLineShapeAnnotation);
}

void GraphicsView::finishDrawingPolygonShape(bool removeLastAddedPoint)
{
  setIsCreatingPolygonShape(false);
  if (removeLastAddedPoint) {
    mpPolygonShapeAnnotation->removePoint(mpPolygonShapeAnnotation->getPoints().size() - 1);
  }
  setOriginAdjustAndInitialize(mpPolygonShapeAnnotation);
  mpPolygonShapeAnnotation->setSelected(true);
  uncheckAllShapeDrawingActions();
  checkEmitUpdateSelect(false, mpPolygonShapeAnnotation);
}

void GraphicsView::finishDrawingRectangleShape()
{
  setIsCreatingRectangleShape(false);
  setOriginAdjustAndInitialize(mpRectangleShapeAnnotation);
  mpRectangleShapeAnnotation->setSelected(true);
  uncheckAllShapeDrawingActions();
  checkEmitUpdateSelect(false, mpRectangleShapeAnnotation);
}

void GraphicsView::finishDrawingEllipseShape()
{
  setIsCreatingEllipseShape(false);
  setOriginAdjustAndInitialize(mpEllipseShapeAnnotation);
  mpEllipseShapeAnnotation->setSelected(true);
  uncheckAllShapeDrawingActions();
  checkEmitUpdateSelect(false, mpEllipseShapeAnnotation);
}

void GraphicsView::finishDrawingTextShape()
{
  setIsCreatingTextShape(false);
  setOriginAdjustAndInitialize(mpTextShapeAnnotation);
  uncheckAllShapeDrawingActions();
  checkEmitUpdateSelect(true, mpTextShapeAnnotation);
}

void GraphicsView::finishDrawingBitmapShape() {
  setIsCreatingBitmapShape(false);
  setOriginAdjustAndInitialize(mpBitmapShapeAnnotation);
  uncheckAllShapeDrawingActions();
  checkEmitUpdateSelect(true, mpBitmapShapeAnnotation);
}

void GraphicsView::checkEmitUpdateSelect(const bool showPropertiesAndSelect, ShapeAnnotation* shapeAnnotation)
{
  MainWindow *pMainWindow = MainWindow::instance();
  pMainWindow->getConnectModeAction()->setChecked(true);
  if (showPropertiesAndSelect) {
    shapeAnnotation->showShapeProperties();
    // set the focus back on GraphicsView once the shape properties dialog is closed.
    setFocus(Qt::ActiveWindowFocusReason);
  }
  mpModelWidget->updateClassAnnotationIfNeeded();
  mpModelWidget->updateModelText();
  if (showPropertiesAndSelect) {
    shapeAnnotation->setSelected(true);
  }
}

void GraphicsView::setOriginAdjustAndInitialize(ShapeAnnotation* shapeAnnotation)
{
  shapeAnnotation->setOrigin(shapeAnnotation->sceneBoundingRect().center());
  adjustInitializeDraw(shapeAnnotation);
}

void GraphicsView::setOriginAdjustAndInitialize(PolygonAnnotation* shapeAnnotation)
{
  shapeAnnotation->setOrigin(roundPoint(shapeAnnotation->sceneBoundingRect().center()));
  adjustInitializeDraw(shapeAnnotation);
}

void GraphicsView::adjustInitializeDraw(ShapeAnnotation* shapeAnnotation)
{
  if (dynamic_cast<LineAnnotation*>(shapeAnnotation) || dynamic_cast<PolygonAnnotation*>(shapeAnnotation)) {
    shapeAnnotation->adjustPointsWithOrigin();
  } else {
    shapeAnnotation->adjustExtentsWithOrigin();
  }
  shapeAnnotation->drawCornerItems();
  shapeAnnotation->applyTransformation();
}

/*!
 * \brief GraphicsView::itemsBoundingRect
 * Gets the bounding rectangle of all the items added to the view, excluding background and so on
 * \return
 */
QRectF GraphicsView::itemsBoundingRect()
{
  QRectF rect;
  foreach (Element *pElement, mElementsList) {
    rect |= pElement->itemsBoundingRect();
  }
  foreach (QGraphicsItem *item, mShapesList) {
    rect |= item->sceneBoundingRect();
  }
  foreach (QGraphicsItem *item, mConnectionsList) {
    rect |= item->sceneBoundingRect();
  }
  foreach (QGraphicsItem *item, mTransitionsList) {
    rect |= item->sceneBoundingRect();
  }
  foreach (QGraphicsItem *item, mInitialStatesList) {
    rect |= item->sceneBoundingRect();
  }
  foreach (Element *pElement, mInheritedElementsList) {
    rect |= pElement->itemsBoundingRect();
  }
  foreach (QGraphicsItem *item, mInheritedShapesList) {
    rect |= item->sceneBoundingRect();
  }
  foreach (QGraphicsItem *item, mInheritedConnectionsList) {
    rect |= item->sceneBoundingRect();
  }
  foreach (QGraphicsItem *item, mInheritedTransitionsList) {
    rect |= item->sceneBoundingRect();
  }
  foreach (QGraphicsItem *item, mInheritedInitialStatesList) {
    rect |= item->sceneBoundingRect();
  }
  qreal x1, y1, x2, y2;
  rect.getCoords(&x1, &y1, &x2, &y2);
  rect.setCoords(x1 -5, y1 -5, x2 + 5, y2 + 5);
  return mapFromScene(rect).boundingRect();
}

QPointF GraphicsView::snapPointToGrid(QPointF point)
{
  qreal stepX = mMergedCoordinateSystem.getHorizontalGridStep();
  qreal stepY = mMergedCoordinateSystem.getVerticalGridStep();
  point.setX(stepX * qFloor((point.x() / stepX) + 0.5));
  point.setY(stepY * qFloor((point.y() / stepY) + 0.5));
  return point;
}

QPointF GraphicsView::movePointByGrid(QPointF point, QPointF origin, bool useShiftModifier)
{
  qreal stepX = mMergedCoordinateSystem.getHorizontalGridStep() * ((useShiftModifier && QApplication::keyboardModifiers().testFlag(Qt::ShiftModifier)) ? 5 : 1);
  qreal stepY = mMergedCoordinateSystem.getVerticalGridStep() * ((useShiftModifier && QApplication::keyboardModifiers().testFlag(Qt::ShiftModifier)) ? 5 : 1);
  if (useShiftModifier && QApplication::keyboardModifiers().testFlag(Qt::ShiftModifier)) {
    int modX = (int)qFabs(origin.x()) % (int)stepX;
    int modY = (int)qFabs(origin.y()) % (int)stepY;
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
  foreach (Element *pInheritedElement, mInheritedElementsList) {
    if (pInheritedElement->hasShapeAnnotation() && pInheritedElement->isVisible()) {
      return true;
    }
  }
  // check shapes and components
  if (!mShapesList.isEmpty()) {
    return true;
  }
  foreach (Element *pElement, mElementsList) {
    if (pElement->hasShapeAnnotation() && pElement->isVisible()) {
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
  if (!mAllItems.contains(pGraphicsItem)) {
    mAllItems.insert(pGraphicsItem);
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
  if (mAllItems.contains(pGraphicsItem)) {
    mAllItems.remove(pGraphicsItem);
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
    QRectF extentRectangle = mMergedCoordinateSystem.getExtentRectangle();
    qreal x1, y1, x2, y2;
    extentRectangle.getCoords(&x1, &y1, &x2, &y2);
    extentRectangle.setCoords(x1 -5, y1 -5, x2 + 5, y2 + 5);
    fitInView(extentRectangle, Qt::KeepAspectRatio);
  }
}

/*!
 * \brief GraphicsView::emitResetDynamicSelect
 * Emits the reset dynamic select signal.
 */
void GraphicsView::emitResetDynamicSelect()
{
  emit resetDynamicSelect();
}

/*!
 * \brief GraphicsView::createActions
 * Creates the actions for the GraphicsView.
 */
void GraphicsView::createActions()
{
  bool isSystemLibrary = mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView();
  // parameters Action
  mpParametersAction = new QAction(Helper::parameters, this);
  mpParametersAction->setStatusTip(tr("Shows the class parameters"));
  connect(mpParametersAction, SIGNAL(triggered()), SLOT(showParameters()));
  // Graphics View Properties Action
  if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
    mpPropertiesAction = new QAction(Helper::systemSimulationInformation, this);
  } else {
    mpPropertiesAction = new QAction(Helper::properties, this);
  }
  connect(mpPropertiesAction, SIGNAL(triggered()), SLOT(showGraphicsViewProperties()));
  // rename Action
  mpRenameAction = new QAction(Helper::rename, this);
  mpRenameAction->setStatusTip(Helper::renameTip);
  connect(mpRenameAction, SIGNAL(triggered()), SLOT(showRenameDialog()));
  // Actions for shapes and Components
  // Manhattanize Action
  mpManhattanizeAction = new QAction(tr("Manhattanize"), this);
  mpManhattanizeAction->setStatusTip(tr("Manhattanize the lines"));
  mpManhattanizeAction->setDisabled(isSystemLibrary);
  connect(mpManhattanizeAction, SIGNAL(triggered()), SLOT(manhattanizeItems()));
  // Delete Action
  mpDeleteAction = new QAction(ResourceCache::getIcon(":/Resources/icons/delete.svg"), Helper::deleteStr, this);
  mpDeleteAction->setStatusTip(tr("Deletes the item"));
  mpDeleteAction->setShortcut(QKeySequence::Delete);
  mpDeleteAction->setDisabled(isSystemLibrary);
  connect(mpDeleteAction, SIGNAL(triggered()), SLOT(deleteItems()));
  // cut action
  mpCutAction = new QAction(ResourceCache::getIcon(":/Resources/icons/cut.svg"), tr("Cut"), this);
  mpCutAction->setShortcut(QKeySequence("Ctrl+x"));
  mpCutAction->setDisabled(isSystemLibrary);
  connect(mpCutAction, SIGNAL(triggered()), SLOT(cutItems()));
  // copy action
  mpCopyAction = new QAction(ResourceCache::getIcon(":/Resources/icons/copy.svg"), Helper::copy, this);
  mpCopyAction->setShortcut(QKeySequence("Ctrl+c"));
  connect(mpCopyAction, SIGNAL(triggered()), SLOT(copyItems()));
  // paste action
  mpPasteAction = new QAction(ResourceCache::getIcon(":/Resources/icons/paste.svg"), tr("Paste"), this);
  mpPasteAction->setShortcut(QKeySequence("Ctrl+v"));
  mpPasteAction->setDisabled(isSystemLibrary);
  connect(mpPasteAction, SIGNAL(triggered()), SLOT(pasteItems()));
  // Duplicate Action
  mpDuplicateAction = new QAction(ResourceCache::getIcon(":/Resources/icons/duplicate.svg"), Helper::duplicate, this);
  mpDuplicateAction->setStatusTip(Helper::duplicateTip);
  mpDuplicateAction->setShortcut(QKeySequence("Ctrl+d"));
  mpDuplicateAction->setDisabled(isSystemLibrary);
  connect(mpDuplicateAction, SIGNAL(triggered()), SLOT(duplicateItems()));
  // Bring To Front Action
  mpBringToFrontAction = new QAction(ResourceCache::getIcon(":/Resources/icons/bring-to-front.svg"), tr("Bring to Front"), this);
  mpBringToFrontAction->setStatusTip(tr("Brings the item to front"));
  mpBringToFrontAction->setDisabled(isSystemLibrary);
  mpBringToFrontAction->setDisabled(true);
  // Bring Forward Action
  mpBringForwardAction = new QAction(ResourceCache::getIcon(":/Resources/icons/bring-forward.svg"), tr("Bring Forward"), this);
  mpBringForwardAction->setStatusTip(tr("Brings the item one level forward"));
  mpBringForwardAction->setDisabled(isSystemLibrary);
  mpBringForwardAction->setDisabled(true);
  // Send To Back Action
  mpSendToBackAction = new QAction(ResourceCache::getIcon(":/Resources/icons/send-to-back.svg"), tr("Send to Back"), this);
  mpSendToBackAction->setStatusTip(tr("Sends the item to back"));
  mpSendToBackAction->setDisabled(isSystemLibrary);
  mpSendToBackAction->setDisabled(true);
  // Send Backward Action
  mpSendBackwardAction = new QAction(ResourceCache::getIcon(":/Resources/icons/send-backward.svg"), tr("Send Backward"), this);
  mpSendBackwardAction->setStatusTip(tr("Sends the item one level backward"));
  mpSendBackwardAction->setDisabled(isSystemLibrary);
  mpSendBackwardAction->setDisabled(true);
  // Rotate ClockWise Action
  mpRotateClockwiseAction = new QAction(ResourceCache::getIcon(":/Resources/icons/rotateclockwise.svg"), tr("Rotate Clockwise"), this);
  mpRotateClockwiseAction->setStatusTip(tr("Rotates the item clockwise"));
  mpRotateClockwiseAction->setShortcut(QKeySequence("Ctrl+r"));
  mpRotateClockwiseAction->setDisabled(isSystemLibrary);
  connect(mpRotateClockwiseAction, SIGNAL(triggered()), SLOT(rotateClockwise()));
  // Rotate Anti-ClockWise Action
  mpRotateAntiClockwiseAction = new QAction(ResourceCache::getIcon(":/Resources/icons/rotateanticlockwise.svg"), tr("Rotate Anticlockwise"), this);
  mpRotateAntiClockwiseAction->setStatusTip(tr("Rotates the item anticlockwise"));
  mpRotateAntiClockwiseAction->setShortcut(QKeySequence("Ctrl+Shift+r"));
  mpRotateAntiClockwiseAction->setDisabled(isSystemLibrary);
  connect(mpRotateAntiClockwiseAction, SIGNAL(triggered()), SLOT(rotateAntiClockwise()));
  // Flip Horizontal Action
  mpFlipHorizontalAction = new QAction(ResourceCache::getIcon(":/Resources/icons/flip-horizontal.svg"), tr("Flip Horizontal"), this);
  mpFlipHorizontalAction->setStatusTip(tr("Flips the item horizontally"));
  mpFlipHorizontalAction->setShortcut(QKeySequence("h"));
  mpFlipHorizontalAction->setDisabled(isSystemLibrary);
  connect(mpFlipHorizontalAction, SIGNAL(triggered()), SLOT(flipHorizontal()));
  // Flip Vertical Action
  mpFlipVerticalAction = new QAction(ResourceCache::getIcon(":/Resources/icons/flip-vertical.svg"), tr("Flip Vertical"), this);
  mpFlipVerticalAction->setStatusTip(tr("Flips the item vertically"));
  mpFlipVerticalAction->setShortcut(QKeySequence("v"));
  mpFlipVerticalAction->setDisabled(isSystemLibrary);
  connect(mpFlipVerticalAction, SIGNAL(triggered()), SLOT(flipVertical()));
  // create connector Action
  mpCreateConnectorAction = new QAction(tr("Create Connector"), this);
  mpCreateConnectorAction->setStatusTip(tr("Creates a connector"));
  connect(mpCreateConnectorAction, SIGNAL(triggered()), SLOT(createConnector()));
  // cancel connection Action
  mpCancelConnectionAction = new QAction(tr("Cancel Connection"), this);
  mpCancelConnectionAction->setStatusTip(tr("Cancels the current connection"));
  connect(mpCancelConnectionAction, SIGNAL(triggered()), SLOT(cancelConnection()));
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
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView()) {
    return false;
  }
  if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
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
    Element *pComponent = dynamic_cast<Element*>(selectedItems.at(i));
    if (pComponent && !pComponent->isInheritedElement()) {
      return true;
    }
    // check the selected connections and shapes.
    ShapeAnnotation *pShapeAnnotation = dynamic_cast<ShapeAnnotation*>(selectedItems.at(i));
    if (pShapeAnnotation && !pShapeAnnotation->isInheritedShape()) {
      LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(pShapeAnnotation);
      // if the shape is connection line then we only return true for certain cases.
      if (pLineAnnotation && pLineAnnotation->isConnection()) {
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
 * \brief GraphicsView::duplicateItems
 * Duplicates the selected items by emitting GraphicsView::duplicate() SIGNAL.
 * \param action
 */
void GraphicsView::duplicateItems(const QString &action)
{
  mpModelWidget->beginMacro(action);
  ModelInfo oldModelInfo = mpModelWidget->createModelInfo();
  emit duplicate();
  ModelInfo newModelInfo = mpModelWidget->createModelInfo();
  mpModelWidget->getUndoStack()->push(new OMCUndoCommand(mpModelWidget->getLibraryTreeItem(), oldModelInfo, newModelInfo, action));
  mpModelWidget->updateClassAnnotationIfNeeded();
  mpModelWidget->updateModelText();
  mpModelWidget->endMacro();
}

/*!
 * \brief GraphicsView::getComponentFromQGraphicsItem
 * \param pGraphicsItem
 * A QGraphicsItem can be a Element or a ShapeAnnotation inside a Element.
 * \return
 */
Element* GraphicsView::getElementFromQGraphicsItem(QGraphicsItem *pGraphicsItem)
{
  if (pGraphicsItem) {
    Element *pElement = dynamic_cast<Element*>(pGraphicsItem);
    if (!pElement && pGraphicsItem->parentItem()) {
      pElement = dynamic_cast<Element*>(pGraphicsItem->parentItem());
    }
    if (!pElement) {
      OriginItem *pOriginItem = dynamic_cast<OriginItem*>(pGraphicsItem);
      if (pOriginItem) {
        pElement = pOriginItem->getElement();
      }
    }
    return pElement;
  }
  return 0;
}

/*!
 * \brief GraphicsView::elementAtPosition
 * Returns the first Element at the position.
 * \param position
 * \return
 */
Element* GraphicsView::elementAtPosition(QPoint position)
{
  QList<QGraphicsItem*> graphicsItems = items(position);
  foreach (QGraphicsItem *pGraphicsItem, graphicsItems) {
    Element *pElement = getElementFromQGraphicsItem(pGraphicsItem);
    if (pElement) {
      return pElement->getRootParentElement();
    }
  }
  return 0;
}

/*!
 * \brief GraphicsView::connectorElementAtPosition
 * Returns the connector element at the position.
 * \param position
 * \return
 */
Element* GraphicsView::connectorElementAtPosition(QPoint position)
{
  /* Ticket:4215
   * Allow making connection from the connectors which are under some other shape or element.
   * itemAt() only returns the top level item.
   * Use items() to get all items at position and then return the first connector element from the list.
   */
  QList<QGraphicsItem*> graphicsItems = items(position);
  foreach (QGraphicsItem *pGraphicsItem, graphicsItems) {
    Element *pElement = getElementFromQGraphicsItem(pGraphicsItem);
    if (pElement) {
      Element *pRootElement = pElement->getRootParentElement();
      if (pRootElement && pRootElement->isSelected()) {
        return 0;
      } else if (pRootElement && !pRootElement->isSelected()) {
        // Issue #11310. If both root and element are connectors then use the root.
        if ((pRootElement->getModel() && pRootElement->getModel()->isConnector() && pElement && pElement->getModel() && pElement->getModel()->isConnector())
            || (pRootElement->getLibraryTreeItem() && pRootElement->getLibraryTreeItem()->isConnector() && pElement->getLibraryTreeItem() && pElement->getLibraryTreeItem()->isConnector())) {
          pElement = pRootElement;
        }
        if (MainWindow::instance()->getConnectModeAction()->isChecked() && isDiagramView() &&
            !(mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView()) &&
            ((pElement->getModel() && pElement->getModel()->isConnector()) ||
             (pElement->getLibraryTreeItem() && pElement->getLibraryTreeItem()->isConnector()) ||
             (mpModelWidget->getLibraryTreeItem()->isSSP() &&
              (pElement->getLibraryTreeItem()->getOMSConnector() || pElement->getLibraryTreeItem()->getOMSBusConnector()
               || pElement->getLibraryTreeItem()->getOMSTLMBusConnector() || pElement->isPort())))) {
          return pElement;
        }
      }
    }
  }
  return 0;
}

/*!
 * \brief GraphicsView::stateElementAtPosition
 * Returns the state element at the position.
 * \param position
 * \return
 */
Element* GraphicsView::stateElementAtPosition(QPoint position)
{
  QList<QGraphicsItem*> graphicsItems = items(position);
  foreach (QGraphicsItem *pGraphicsItem, graphicsItems) {
    Element *pElement = getElementFromQGraphicsItem(pGraphicsItem);
    if (pElement) {
      Element *pRootElement = pElement->getRootParentElement();
      if (pRootElement && !pRootElement->isSelected()) {
        // Issue #11310. If both root and element are connectors then use the root.
        if ((pRootElement->getModel() && pRootElement->getModel()->getAnnotation()->isState() && pElement && pElement->getModel() && pElement->getModel()->getAnnotation()->isState())
            || (pRootElement->getLibraryTreeItem() && pRootElement->getLibraryTreeItem()->isState() && pElement->getLibraryTreeItem() && pElement->getLibraryTreeItem()->isState())) {
          pElement = pRootElement;
        }
        if (MainWindow::instance()->getTransitionModeAction()->isChecked() && isDiagramView() &&
            !(mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView()) &&
            ((pElement->getModel() && pElement->getModel()->getAnnotation()->isState()) ||
             (pElement->getLibraryTreeItem() && pElement->getLibraryTreeItem()->isModelica() && pElement->getLibraryTreeItem()->isState()))) {
          return pElement;
        }
      }
    }
  }
  return 0;
}

/*!
 * \brief GraphicsView::updateElementConnectorSizingParameter
 * Updates the Element's connectorSizing parameter via the modifier.
 * \param pGraphicsView
 * \param className
 * \param pElement
 * \return
 */
bool GraphicsView::updateElementConnectorSizingParameter(GraphicsView *pGraphicsView, QString className, Element *pElement)
{
  // if connectorSizing then set a new value for the connectorSizing parameter.
  if (pElement && pElement->isConnectorSizing()) {
    QStringList parameters = pElement->getAbsynArrayIndexes();
    if (!parameters.isEmpty()) {
      QString parameter = parameters.at(0);
      int numberOfElementConnections = pGraphicsView->numberOfElementConnections(pElement);
      // if the connectorSizing parameter is in this class
      if (pGraphicsView->getModelWidget()->getModelInstance()->isParameterConnectorSizing(parameter)) {
        MainWindow::instance()->getOMCProxy()->setParameterValue(className, parameter, QString::number(numberOfElementConnections));
        return true;
      } else {
        QString modifierKey = QString("%1.%2").arg(pElement->getRootParentElement()->getName()).arg(parameter);
        MainWindow::instance()->getOMCProxy()->setElementModifierValueOld(className, modifierKey, QString::number(numberOfElementConnections));
        return true;
      }
    }
  }
  return false;
}

/*!  * \brief GraphicsView::getConnectorElement
 * Returns the element associated with a Connector.
 * \param pConnector
 */
Element* GraphicsView::getConnectorElement(ModelInstance::Connector *pConnector)
{
  QStringList elementList = pConnector->getNameParts();
  Element *element = nullptr;

  // Get element.
  if (elementList.size() > 0) {
    if (mpModelWidget->isElementMode() && mpModelWidget->getModelInstance()->getParentElement()) {
      QString relativeName = StringHandler::makeClassNameRelative(elementList.join('.'), mpModelWidget->getModelInstance()->getParentElement()->getQualifiedName());
      elementList = StringHandler::makeVariableParts(relativeName);
    }
    QString elementName = elementList.front();
    elementName = elementName.left(elementName.indexOf('['));
    element = getElementObject(elementName);
  }

  // Get connector element.
  Element *connectorElement = nullptr;
  if (element) {
    // If an element type is connector then we only get one item in elementList
    // Check the elementList
    // If conditional connector or condition is false or if type is missing then connect with the red cross box
    if (elementList.size() < 2 || element->isExpandableConnector() || !element->isCondition() || (element->getModel() && element->getModel()->isMissing())) {
      connectorElement = element;
    } else {
      // Look for port from the parent element
      QString elementName = elementList.at(1);
      elementName = elementName.left(elementName.indexOf('['));
      connectorElement = mpModelWidget->getConnectorElement(element, elementName);
    }
  }

  return connectorElement;
}

/*!
 * \brief GraphicsView::addConnection
 * Adds the connection to GraphicsView.
 * \param pElement
 * \param createConnector true when function is called from GraphicsView::createConnector
 */
void GraphicsView::addConnection(Element *pElement, bool createConnector)
{
  // When clicking the start element
  if (!isCreatingConnection()) {
    QPointF startPos;
    if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
      startPos = roundPoint(pElement->mapToScene(pElement->boundingRect().center()));
    } else {
      startPos = snapPointToGrid(pElement->mapToScene(pElement->boundingRect().center()));
    }
    mpConnectionLineAnnotation = new LineAnnotation(LineAnnotation::ConnectionType, pElement, this);
    setIsCreatingConnection(true);
    mpConnectionLineAnnotation->addPoint(startPos);
    mpConnectionLineAnnotation->addPoint(startPos);
    mpConnectionLineAnnotation->addPoint(startPos);
    /* Ticket:4196
     * If we are starting connection from expandable connector or (array && !connectorSizing) connector
     * then set the line thickness to 0.5
     */
    Element *pRootParentElement = pElement->getParentElement() ? pElement->getRootParentElement() : 0;
    if (pElement->isExpandableConnector()
        || (pElement->isArray() && !pElement->isConnectorSizing())
        || (pRootParentElement && (pRootParentElement->isExpandableConnector() || (pRootParentElement->isArray() && !pRootParentElement->isConnectorSizing())))) {
      mpConnectionLineAnnotation->setLineThickness(0.5);
    }
  } else { // When clicking the end element
    setIsCreatingConnection(false);
    mpConnectionLineAnnotation->setEndElement(pElement);
    // update the last point to the center of element
    QPointF newPos;
    if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
      newPos = roundPoint(pElement->mapToScene(pElement->boundingRect().center()));
    } else {
      newPos = snapPointToGrid(pElement->mapToScene(pElement->boundingRect().center()));
    }
    mpConnectionLineAnnotation->updateEndPoint(newPos);
    // check if connection is valid
    Element *pStartElement = mpConnectionLineAnnotation->getStartElement();
    MainWindow *pMainWindow = MainWindow::instance();
    if (pStartElement == pElement) {
      QMessageBox::information(pMainWindow, QString("%1 - %2").arg(Helper::applicationName, Helper::information), GUIMessages::getMessage(GUIMessages::SAME_COMPONENT_CONNECT), QMessageBox::Ok);
      removeCurrentConnection();
    } else {
      /* Ticket:4956
       * Only set the connection line thickness to 0.5 when both connectors are either expandable or (array && !connectorSizing).
       * Otherwise set it to 0.25 i.e., default.
       */
      Element *pStartRootParentElement = pStartElement->getParentElement() ? pStartElement->getRootParentElement() : 0;
      Element *pRootParentElement = pElement->getParentElement() ? pElement->getRootParentElement() : 0;

      if ((pStartElement->isExpandableConnector() || (pStartElement->isArray() && !pStartElement->isConnectorSizing())
           || (pStartRootParentElement && (pStartRootParentElement->isExpandableConnector() || (pStartRootParentElement->isArray() && !pStartRootParentElement->isConnectorSizing()))))
          && (pElement->isExpandableConnector() || (pElement->isArray() && !pElement->isConnectorSizing())
              || (pRootParentElement && (pRootParentElement->isExpandableConnector() || (pRootParentElement->isArray() && !pRootParentElement->isConnectorSizing()))))) {
        mpConnectionLineAnnotation->setLineThickness(0.5);
      } else {
        /* Ticket:4956
         * If the start connector is either expandable or array and the end connector is not then change the line color to end connector.
         */
        if ((pStartElement->isExpandableConnector() || pStartElement->isArray()
             || (pStartRootParentElement && (pStartRootParentElement->isExpandableConnector() || pStartRootParentElement->isArray())))
            && (!(pElement->isExpandableConnector() || pElement->isArray()
                || (pRootParentElement && (pRootParentElement->isExpandableConnector() || pRootParentElement->isArray()))))) {
          if (pElement->getModel()) {
            QList<ModelInstance::Shape*> shapes = pElement->getModel()->getAnnotation()->getIconAnnotation()->getGraphics();
            if (!shapes.isEmpty()) {
              mpConnectionLineAnnotation->setLineColor(shapes.at(0)->getLineColor());
            } else if (pElement->getShapesList().size() > 0) {
              ShapeAnnotation *pShapeAnnotation = pElement->getShapesList().at(0);
              mpConnectionLineAnnotation->setLineColor(pShapeAnnotation->getLineColor());
            }
          }
        }
        mpConnectionLineAnnotation->setLineThickness(0.25);
      }
      // check if any of starting or ending elements are array
      bool showConnectionArrayDialog = false;
      if ((pStartElement->isExpandableConnector() || (pStartElement->isArray() && !pStartElement->isConnectorSizing())
           || (pStartRootParentElement && (pStartRootParentElement->isExpandableConnector() || (pStartRootParentElement->isArray() && !pStartRootParentElement->isConnectorSizing()))))
          || (pElement->isExpandableConnector() || (pElement->isArray() && !pElement->isConnectorSizing())
              || (pRootParentElement && (pRootParentElement->isExpandableConnector() || (pRootParentElement->isArray() && !pRootParentElement->isConnectorSizing()))))) {
        showConnectionArrayDialog = true;
      }
      // check if any starting or ending elements are bus
      bool showBusConnectionDialog = false;
      if ((pStartElement->getLibraryTreeItem() && pStartElement->getLibraryTreeItem()->getOMSBusConnector())
        || (pElement->getLibraryTreeItem() && pElement->getLibraryTreeItem()->getOMSBusConnector())) {
        showBusConnectionDialog = true;
      }
      // if connectorSizing annotation is set then don't show the CreateConnectionDialog
      if (showConnectionArrayDialog) {
        CreateConnectionDialog *pConnectionArray = new CreateConnectionDialog(this, mpConnectionLineAnnotation, createConnector, MainWindow::instance());
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
      } else if ((pStartElement->getLibraryTreeItem() && pStartElement->getLibraryTreeItem()->getOMSTLMBusConnector())
                 && (pElement->getLibraryTreeItem() && pElement->getLibraryTreeItem()->getOMSTLMBusConnector())) {
        TLMConnectionDialog *pTLMBusConnectionDialog = new TLMConnectionDialog(this, mpConnectionLineAnnotation);
        // if user cancels the tlm bus connection
        if (!pTLMBusConnectionDialog->exec()) {
          removeCurrentConnection();
        }
      } else {
        QString startElementName = getConnectorName(pStartElement);
        QString endElementName = getConnectorName(pElement);
        mpConnectionLineAnnotation->setStartElementName(startElementName);
        mpConnectionLineAnnotation->setEndElementName(endElementName);
        if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
          mpConnectionLineAnnotation->drawCornerItems();
          mpConnectionLineAnnotation->setCornerItemsActiveOrPassive();
          addConnectionToView(mpConnectionLineAnnotation, false);
          if (addConnectionToClass(mpConnectionLineAnnotation)) {
            mpModelWidget->createOMSimulatorUndoCommand(QString("Add OMS Connection connect(%1, %2)").arg(mpConnectionLineAnnotation->getStartElementName(),
                                                                                                          mpConnectionLineAnnotation->getEndElementName()));
            mpModelWidget->updateModelText();
          } else {
            removeCurrentConnection();
          }
        } else {
          if (!connectionExists(startElementName, endElementName, false)) {
            /* Issue #12163. Do not check connection validity when called from GraphicsView::createConnector
             * GraphicsView::createConnector creates an incomplete connector. We do this for performance reasons. Avoid calling getModelInstance API.
             * We know for sure that both connectors are compatible in this case so its okay not to check for validity.
             */
            if (createConnector) {
              mpConnectionLineAnnotation->drawCornerItems();
              mpConnectionLineAnnotation->setCornerItemsActiveOrPassive();
              addConnectionToView(mpConnectionLineAnnotation, false);
              addConnectionToClass(mpConnectionLineAnnotation);
            } else if (mpModelWidget->getModelInstance()->isValidConnection(startElementName, endElementName)) {
              mpModelWidget->getUndoStack()->push(new AddConnectionCommand(mpConnectionLineAnnotation, true));
              mpModelWidget->updateModelText();
            } else {
              QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                                    GUIMessages::getMessage(GUIMessages::MISMATCHED_CONNECTORS_IN_CONNECT).arg(startElementName, endElementName), QMessageBox::Ok);
              removeCurrentConnection();
            }
          } else {
            removeCurrentConnection();
          }
        }
      }
    }
    // Once we are done creating the connection then we should set mpConnectionLineAnnotation to 0.
    mpConnectionLineAnnotation = 0;
  }
}

/*!
 * \brief GraphicsView::removeCurrentConnection
 * Removes the current connecting connector from the model.
 */
void GraphicsView::removeCurrentConnection()
{
  setIsCreatingConnection(false);
  deleteConnectionFromList(mpConnectionLineAnnotation);
  removeItem(mpConnectionLineAnnotation);
  if (mpConnectionLineAnnotation) {
    mpConnectionLineAnnotation->deleteLater();
    mpConnectionLineAnnotation = 0;
  }
}

void GraphicsView::addTransition(Element *pComponent)
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
    setIsCreatingTransition(false);
    mpTransitionLineAnnotation->setEndElement(pComponent);
    // Remove reduntant points so that Liang Barsky algorithm can work well.
    mpTransitionLineAnnotation->removeRedundantPointsGeometriesAndCornerItems();
    QVector<QPointF> points = mpTransitionLineAnnotation->getPoints();
    // Find the start state intersection point.
    QRectF sceneRectF = mpTransitionLineAnnotation->getStartElement()->sceneBoundingRect();
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
    Element *pStartComponent = mpTransitionLineAnnotation->getStartElement();
    if (pStartComponent == pComponent) {
      QMessageBox::information(MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::information),
                               GUIMessages::getMessage(GUIMessages::SAME_COMPONENT_CONNECT), QMessageBox::Ok);
      removeCurrentTransition();
    } else {
      QString startComponentName, endComponentName;
      if (pStartComponent->getParentElement()) {
        startComponentName = QString(pStartComponent->getRootParentElement()->getName()).append(".").append(pStartComponent->getName());
      } else {
        startComponentName = pStartComponent->getName();
      }
      if (pComponent->getParentElement()) {
        endComponentName = QString(pComponent->getRootParentElement()->getName()).append(".").append(pComponent->getName());
      } else {
        endComponentName = pComponent->getName();
      }
      mpTransitionLineAnnotation->setStartElementName(startComponentName);
      mpTransitionLineAnnotation->setEndElementName(endComponentName);
      CreateOrEditTransitionDialog *pCreateOrEditTransitionDialog = new CreateOrEditTransitionDialog(this, mpTransitionLineAnnotation, false, MainWindow::instance());
      if (!pCreateOrEditTransitionDialog->exec()) {
        removeCurrentTransition();
      }
    }
    // Once we are done creating the transition then we should set mpTransitionLineAnnotation to 0.
    mpTransitionLineAnnotation = 0;
  }
}

/*!
 * \brief GraphicsView::removeCurrentTransition
 * Removes the current connecting transition from the model.
 */
void GraphicsView::removeCurrentTransition()
{
  setIsCreatingTransition(false);
  deleteTransitionFromList(mpTransitionLineAnnotation);
  removeItem(mpTransitionLineAnnotation);
  if (mpTransitionLineAnnotation) {
    mpTransitionLineAnnotation->deleteLater();
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
  // if deleting a bus connection
  if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
    if (pConnectionLineAnnotation->getStartElement()->getLibraryTreeItem()
        && pConnectionLineAnnotation->getStartElement()->getLibraryTreeItem()->getOMSBusConnector()
        && pConnectionLineAnnotation->getEndElement()->getLibraryTreeItem()
        && pConnectionLineAnnotation->getEndElement()->getLibraryTreeItem()->getOMSBusConnector()) {
      oms_busconnector_t *pStartBus = pConnectionLineAnnotation->getStartElement()->getLibraryTreeItem()->getOMSBusConnector();
      oms_busconnector_t *pEndBus = pConnectionLineAnnotation->getEndElement()->getLibraryTreeItem()->getOMSBusConnector();
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
              if (startBusConnectors.contains(pAtomicConnectionLineAnnotation->getStartElement()->getName())
                  && endBusConnectors.contains(pAtomicConnectionLineAnnotation->getEndElement()->getName())) {
                removeConnectionFromView(pAtomicConnectionLineAnnotation);
                deleteConnectionFromClass(pAtomicConnectionLineAnnotation);
                break;
              }
            }
          }
        }
      }
    }
    removeConnectionFromView(pConnectionLineAnnotation);
    deleteConnectionFromClass(pConnectionLineAnnotation);
  } else {
    removeConnectionFromView(pConnectionLineAnnotation);
    deleteConnectionFromClass(pConnectionLineAnnotation);
  }
}

/*!
 * \brief GraphicsView::deleteTransition
 * Deletes the transition from the class.
 * \param pTransitionLineAnnotation - is a pointer to the transition to delete.
 */
void GraphicsView::deleteTransition(LineAnnotation *pTransitionLineAnnotation)
{
  pTransitionLineAnnotation->setSelected(false);
  removeTransitionFromView(pTransitionLineAnnotation);
  deleteTransitionFromClass(pTransitionLineAnnotation);
}

/*!
 * \brief GraphicsView::deleteInitialState
 * Deletes an initial state from the class.
 * \param pInitialLineAnnotation - is a pointer to the initial state to delete.
 */
void GraphicsView::deleteInitialState(LineAnnotation *pInitialLineAnnotation)
{
  pInitialLineAnnotation->setSelected(false);
  removeInitialStateFromView(pInitialLineAnnotation);
  deleteInitialStateFromClass(pInitialLineAnnotation);
}

//! Resets zoom factor to 100%.
//! @see zoomIn()
//! @see zoomOut()
void GraphicsView::resetZoom()
{
  resetTransform();
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
  if (transform().m11() < 34 && transform().m22() > -34) {
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
  if (transform().m11() > 0.2 && transform().m22() < -0.2) {
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
  foreach (QGraphicsItem *pGraphicsItem, items()) {
    pGraphicsItem->setSelected(true);
  }
}

/*!
 * \brief GraphicsView::cutItems
 * Slot activated when mpCutAction triggered SIGNAL is raised.
 */
void GraphicsView::cutItems()
{
  copyItems(true);
}

/*!
 * \brief GraphicsView::copyItems
 * Slot activated when mpCopyAction triggered SIGNAL is raised.
 */
void GraphicsView::copyItems()
{
  copyItems(false);
}

/*!
 * \brief GraphicsView::copyItems
 * Copies the selected items to the clipboard.
 * \param cut - flag to know if we should cut the items or not.
 */
void GraphicsView::copyItems(bool cut)
{
  /* Issue #9515
   * scene()->selectedItems() returns a list of all currently selected items. The items are returned in no particular order.
   * So use items() instead and then check which items are selected.
   */
  QList<QGraphicsItem*> selectedItems = scene()->selectedItems();
  QList<QGraphicsItem*> itemsList = items();
  if (!selectedItems.isEmpty()) {
    QStringList components, connections, shapes, shapesOMC, allItems;
    QJsonArray componentsJsonArray, connectionsJsonArray;
    for (int i = itemsList.size() - 1 ; i >= 0 ; i--) {
      if (itemsList.at(i)->isSelected()) {
        if (Element *pElement = dynamic_cast<Element*>(itemsList.at(i))) {
          components << pElement->getModelComponent()->toString(false, true) % " " % "annotation(" % pElement->getPlacementAnnotation(true) % ");";
          // component JSON
          QJsonObject componentJsonObject;
          componentJsonObject.insert(QLatin1String("classname"), pElement->getClassName());
          componentJsonObject.insert(QLatin1String("name"), pElement->getName());
          componentJsonObject.insert(QLatin1String("connector"), pElement->getModel() ? pElement->getModel()->isConnector() : false);
          componentJsonObject.insert(QLatin1String("placement"), pElement->getOMCPlacementAnnotation(QPointF(0, 0)));
          componentsJsonArray.append(componentJsonObject);
        } else if (ShapeAnnotation *pShapeAnnotation = dynamic_cast<ShapeAnnotation*>(itemsList.at(i))) {
          LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(itemsList.at(i));
          if (pLineAnnotation && pLineAnnotation->isConnection()) {
            // Only consider the connection for copying if both the start and the end components are selected.
            if (pLineAnnotation->getStartElement()->getRootParentElement()->isSelected() && pLineAnnotation->getEndElement()->getRootParentElement()->isSelected()) {
              connections << "connect(" % pLineAnnotation->getStartElementName() % ", " % pLineAnnotation->getEndElementName() % ") annotation ("
                             % pLineAnnotation->getShapeAnnotation() % ");";
              // connection JSON
              QJsonObject connectionJsonObject;
              connectionJsonObject.insert(QLatin1String("from"), pLineAnnotation->getStartElementName());
              connectionJsonObject.insert(QLatin1String("to"), pLineAnnotation->getEndElementName());
              connectionJsonObject.insert(QLatin1String("annotation"), pLineAnnotation->getOMCShapeAnnotationWithShapeName());
              connectionsJsonArray.append(connectionJsonObject);
            }
          } else {
            shapes << pShapeAnnotation->getShapeAnnotation();
            shapesOMC << pShapeAnnotation->getOMCShapeAnnotationWithShapeName();
          }
        }
      }
    }

    QJsonObject jsonObject;
    jsonObject.insert(QLatin1String("components"), componentsJsonArray);
    jsonObject.insert(QLatin1String("connections"), connectionsJsonArray);
    QJsonDocument jsonDocument(jsonObject);
    QByteArray json = jsonDocument.toJson(QJsonDocument::Compact);

    const QString view = isIconView() ? "Icon" : "Diagram";
    QString annotation;
    if (!shapes.isEmpty()) {
      annotation = "annotation (" % view % "(graphics={" % shapes.join(", ") % "}));";
    }

    if (!connections.isEmpty()) {
      connections.prepend("equation");
    }

    allItems << components << connections << annotation;
    QString allItemsStr = allItems.join("\n");
    if (!allItemsStr.isEmpty() && QApplication::clipboard()) { // do not push empty strings to the clipboard.
      QMimeData *pMimeData = new QMimeData;
      pMimeData->setText(allItemsStr);
      pMimeData->setData(Helper::cutCopyPasteFormat, allItemsStr.toUtf8());

      if (!json.isEmpty()) {
        pMimeData->setData(cutCopyPasteComponentsConnectionsFormat, json);
      }
      if (!components.isEmpty()) {
        const QString componentsStr = components.join("\n");
        pMimeData->setData(cutCopyPasteComponentsFormat, componentsStr.toUtf8());
      }
      if (!connections.isEmpty()) {
        const QString connectionsStr = connections.join("\n");
        pMimeData->setData(cutCopyPasteConnectionsFormat, connectionsStr.toUtf8());
      }
      if (!shapes.isEmpty()) {
        const QString shapesStr = shapes.join(", ");
        pMimeData->setData(cutCopyPasteShapesFormat, shapesStr.toUtf8());
      }
      if (!shapesOMC.isEmpty()) {
        const QString shapesStr = shapesOMC.join(", ");
        pMimeData->setData(cutCopyPasteShapesOMCFormat, shapesStr.toUtf8());
      }
      QApplication::clipboard()->setMimeData(pMimeData);
      // if cut flag is set
      if (cut) {
        deleteItems();
      }
    }
  }
}

/*!
 * \brief GraphicsView::modelicaGraphicsViewContextMenu
 * Creates a context menu for Modelica class.
 * \param pMenu
 */
void GraphicsView::modelicaGraphicsViewContextMenu(QMenu *pMenu)
{
  if (!isVisualizationView()) {
    QMenu *pExportMenu = pMenu->addMenu(Helper::exportt);
    pExportMenu->addAction(MainWindow::instance()->getExportToClipboardAction());
    pExportMenu->addAction(MainWindow::instance()->getExportAsImageAction());
    pExportMenu->addAction(MainWindow::instance()->getExportToOMNotebookAction());
    pMenu->addSeparator();
    bool isSystemLibrary = mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView();
    mpPasteAction->setEnabled(!isSystemLibrary
                              && QApplication::clipboard()->mimeData()
                              && QApplication::clipboard()->mimeData()->hasFormat(Helper::cutCopyPasteFormat));
    pMenu->addAction(mpPasteAction);
    pMenu->addSeparator();
    pMenu->addAction(MainWindow::instance()->getPrintModelAction());
    pMenu->addSeparator();
  }
  pMenu->addAction(mpParametersAction);
  pMenu->addSeparator();
  pMenu->addAction(mpPropertiesAction);
}

/*!
 * \brief GraphicsView::modelicaOneShapeContextMenu
 * Creates a context menu for Modelica class when one shape is right clicked.
 * \param pShapeAnnotation
 * \param pMenu
 */
void GraphicsView::modelicaOneShapeContextMenu(ShapeAnnotation *pShapeAnnotation, QMenu *pMenu)
{
  LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(pShapeAnnotation);
  pMenu->addAction(pShapeAnnotation->getShapePropertiesAction());
  pMenu->addSeparator();
  pMenu->addAction(mpDeleteAction);
  pMenu->addSeparator();
  pMenu->addAction(mpCutAction);
  pMenu->addAction(mpCopyAction);
  if (pLineAnnotation && pLineAnnotation->isTransition()) {
    pMenu->addSeparator();
    pMenu->addAction(pShapeAnnotation->getEditTransitionAction());
  }
  if (pLineAnnotation && pLineAnnotation->isLineShape()) {
    pMenu->addSeparator();
    pMenu->addAction(mpManhattanizeAction);
  }
  if (!pLineAnnotation || pLineAnnotation->isLineShape()) {
    pMenu->addAction(mpDuplicateAction);
    pMenu->addSeparator();
    pMenu->addAction(mpRotateClockwiseAction);
    pMenu->addAction(mpRotateAntiClockwiseAction);
    pMenu->addSeparator();
    pMenu->addAction(mpBringToFrontAction);
    pMenu->addAction(mpBringForwardAction);
    pMenu->addAction(mpSendToBackAction);
    pMenu->addAction(mpSendBackwardAction);
  }
}

/*!
 * \brief GraphicsView::modelicaOneComponentContextMenu
 * Creates a context menu for Modelica class when one component is right clicked.
 * \param pComponent
 * \param pMenu
 */
void GraphicsView::modelicaOneComponentContextMenu(Element *pComponent, QMenu *pMenu)
{
  pMenu->addAction(pComponent->getParametersAction());
  pMenu->addAction(pComponent->getAttributesAction());
  pMenu->addSeparator();
  pMenu->addAction(pComponent->getShowElementAction());
  pMenu->addSeparator();
  pMenu->addAction(pComponent->getOpenClassAction());
  pMenu->addSeparator();
  pMenu->addAction(mpDeleteAction);
  pMenu->addSeparator();
  pMenu->addAction(mpCutAction);
  pMenu->addAction(mpCopyAction);
  pMenu->addAction(mpDuplicateAction);
  pMenu->addSeparator();
  pMenu->addAction(mpRotateClockwiseAction);
  pMenu->addAction(mpRotateAntiClockwiseAction);
  pMenu->addAction(mpFlipHorizontalAction);
  pMenu->addAction(mpFlipVerticalAction);
}

/*!
 * \brief GraphicsView::modelicaMultipleItemsContextMenu
 * Creates a context menu for Modelica class when multiple items are right clicked.
 * \param pMenu
 */
void GraphicsView::modelicaMultipleItemsContextMenu(QMenu *pMenu)
{
  pMenu->addAction(mpDeleteAction);
  pMenu->addSeparator();
  pMenu->addAction(mpCutAction);
  pMenu->addAction(mpCopyAction);
  pMenu->addAction(mpDuplicateAction);
  pMenu->addSeparator();
  pMenu->addAction(mpRotateClockwiseAction);
  pMenu->addAction(mpRotateAntiClockwiseAction);
}

/*!
 * \brief GraphicsView::omsGraphicsViewContextMenu
 * Creates a context menu for OMSimulator model.
 * \param pMenu
 */
void GraphicsView::omsGraphicsViewContextMenu(QMenu *pMenu)
{
  mpPropertiesAction->setEnabled(!mpModelWidget->getLibraryTreeItem()->isSystemLibrary());
  QMenu *pExportMenu = pMenu->addMenu(Helper::exportt);
  pExportMenu->addAction(MainWindow::instance()->getExportToClipboardAction());
  pExportMenu->addAction(MainWindow::instance()->getExportAsImageAction());
  pMenu->addSeparator();
  pMenu->addAction(MainWindow::instance()->getPrintModelAction());
  pMenu->addSeparator();
  if (mpModelWidget->getLibraryTreeItem()->isTopLevel() || mpModelWidget->getLibraryTreeItem()->isSystemElement()) {
    pMenu->addSeparator();
    pMenu->addAction(MainWindow::instance()->getAddSystemAction());
    if (mpModelWidget->getLibraryTreeItem()->isTopLevel()) {
      pMenu->addSeparator();
      pMenu->addAction(mpPropertiesAction);
    }
  }
  if (mpModelWidget->getLibraryTreeItem()->isSystemElement() || mpModelWidget->getLibraryTreeItem()->isComponentElement()) {
    pMenu->addSeparator();
    pMenu->addAction(MainWindow::instance()->getAddOrEditIconAction());
    pMenu->addAction(MainWindow::instance()->getDeleteIconAction());
    pMenu->addSeparator();
    pMenu->addAction(MainWindow::instance()->getAddConnectorAction());
    pMenu->addAction(MainWindow::instance()->getAddBusAction());
    pMenu->addAction(MainWindow::instance()->getAddTLMBusAction());
    if (mpModelWidget->getLibraryTreeItem()->isSystemElement()) {
      pMenu->addSeparator();
      pMenu->addAction(MainWindow::instance()->getAddSubModelAction());
      pMenu->addSeparator();
      pMenu->addAction(mpPropertiesAction);
    }
  }
}

/*!
 * \brief GraphicsView::omsOneShapeContextMenu
 * Creates a context menu for OMSimulator model when one shape is right clicked.
 * \param pShapeAnnotation
 * \param pMenu
 */
void GraphicsView::omsOneShapeContextMenu(ShapeAnnotation *pShapeAnnotation, QMenu *pMenu)
{
  BitmapAnnotation *pBitmapAnnotation = dynamic_cast<BitmapAnnotation*>(pShapeAnnotation);
  if (pBitmapAnnotation && mpModelWidget->getLibraryTreeItem()->getOMSElement()) {
    pMenu->addAction(MainWindow::instance()->getAddOrEditIconAction());
    pMenu->addAction(MainWindow::instance()->getDeleteIconAction());
  }
}

/*!
 * \brief GraphicsView::omsOneComponentContextMenu
 * Creates a context menu for OMSimulator model when one component is right clicked.
 * \param pComponent
 * \param pMenu
 */
void GraphicsView::omsOneComponentContextMenu(Element *pComponent, QMenu *pMenu)
{
  if (pComponent->getLibraryTreeItem() && (pComponent->getLibraryTreeItem()->isSystemElement() || pComponent->getLibraryTreeItem()->isComponentElement())) {
    pMenu->addAction(pComponent->getElementPropertiesAction());
  }
  pMenu->addSeparator();
  pMenu->addAction(mpDeleteAction);
  pMenu->addSeparator();
  pMenu->addAction(mpRotateClockwiseAction);
  pMenu->addAction(mpRotateAntiClockwiseAction);
  pMenu->addAction(mpFlipHorizontalAction);
  pMenu->addAction(mpFlipVerticalAction);
  if (pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->isComponentElement()) {
    pMenu->addSeparator();
    pMenu->addAction(pComponent->getReplaceSubModelAction());
  }
}

/*!
 * \brief GraphicsView::omsMultipleItemsContextMenu
 * Creates a context menu for OMSimulator model when multiple items are right clicked.
 * \param pMenu
 */
void GraphicsView::omsMultipleItemsContextMenu(QMenu *pMenu)
{
  pMenu->addAction(mpDeleteAction);
  pMenu->addSeparator();
  pMenu->addAction(mpRotateClockwiseAction);
  pMenu->addAction(mpRotateAntiClockwiseAction);
  pMenu->addAction(mpFlipHorizontalAction);
  pMenu->addAction(mpFlipVerticalAction);
}

/*!
 * \brief GraphicsView::getCoordinateSystemAndGraphics
 * Makes a list of coordinateSystem values and a list of graphical shapes.
 * \param coOrdinateSystemList
 * \param graphicsList
 */
void GraphicsView::getCoordinateSystemAndGraphics(QStringList &coOrdinateSystemList, QStringList &graphicsList)
{
  // coordinate system
  if (mCoordinateSystem.hasExtent()) {
    ExtentAnnotation extent = mCoordinateSystem.getExtent();
    qreal x1 = extent.at(0).x();
    qreal y1 = extent.at(0).y();
    qreal x2 = extent.at(1).x();
    qreal y2 = extent.at(1).y();
    coOrdinateSystemList.append(QString("extent={{%1, %2}, {%3, %4}}").arg(x1).arg(y1).arg(x2).arg(y2));
  }
  // add the preserveAspectRatio
  if (mCoordinateSystem.hasPreserveAspectRatio()) {
    coOrdinateSystemList.append(QString("preserveAspectRatio=%1").arg(mCoordinateSystem.getPreserveAspectRatio() ? "true" : "false"));
  }
  // add the initial scale
  if (mCoordinateSystem.hasInitialScale()) {
    coOrdinateSystemList.append(QString("initialScale=%1").arg(mCoordinateSystem.getInitialScale()));
  }
  // add the grid
  if (mCoordinateSystem.hasGrid()) {
    PointAnnotation grid = mCoordinateSystem.getGrid();
    coOrdinateSystemList.append(QString("grid={%1, %2}").arg(grid.x()).arg(grid.y()));
  }
  // graphics annotations
  if (mShapesList.size() > 0) {
    foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
      /* Don't add the inherited shape to the addClassAnnotation. */
      if (!pShapeAnnotation->isInheritedShape()) {
        graphicsList.append(pShapeAnnotation->getShapeAnnotation());
      }
    }
  }
}

/*!
 * \brief GraphicsView::pasteItems
 * Slot activated when mpPasteAction triggered SIGNAL is raised.
 * Reads the items from the clipboard and adds them to the view.
 */
void GraphicsView::pasteItems()
{
  QClipboard *pClipboard = QApplication::clipboard();
  if (pClipboard && pClipboard->mimeData() && pClipboard->mimeData()->hasFormat(Helper::cutCopyPasteFormat)) {
    ModelInfo oldModelInfo = mpModelWidget->createModelInfo();

    QJsonObject jsonObject;
    if (pClipboard->mimeData()->hasFormat(cutCopyPasteComponentsConnectionsFormat)) {
      const QByteArray json = pClipboard->mimeData()->data(cutCopyPasteComponentsConnectionsFormat);
      QJsonParseError jsonParserError;
      QJsonDocument jsonDocument = QJsonDocument::fromJson(json, &jsonParserError);
      if (jsonDocument.isNull()) {
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                              QString("Failed to parse json %1 for pasting with error %2.")
                                                              .arg(json, jsonParserError.errorString()), Helper::scriptingKind, Helper::errorLevel));
      } else {
        jsonObject = jsonDocument.object();
      }
    }

    QStringList allItems;
    if (pClipboard->mimeData()->hasFormat(cutCopyPasteComponentsFormat)) {
      allItems << pClipboard->mimeData()->data(cutCopyPasteComponentsFormat);
    }

    if (pClipboard->mimeData()->hasFormat(cutCopyPasteConnectionsFormat)) {
      allItems << pClipboard->mimeData()->data(cutCopyPasteConnectionsFormat);
    }

    QString shapes;
    if (pClipboard->mimeData()->hasFormat(cutCopyPasteShapesFormat)) {
      shapes = pClipboard->mimeData()->data(cutCopyPasteShapesFormat);
    }

    QString shapesOMC;
    if (pClipboard->mimeData()->hasFormat(cutCopyPasteShapesOMCFormat)) {
      shapesOMC = pClipboard->mimeData()->data(cutCopyPasteShapesOMCFormat);
    }

    const QString view = isIconView() ? "Icon" : "Diagram";
    QString annotation;
    if (!shapes.isEmpty()) {
      QStringList coOrdinateSystemList;
      QStringList graphicsList;
      getCoordinateSystemAndGraphics(coOrdinateSystemList, graphicsList);
      graphicsList.append(shapes);

      if (coOrdinateSystemList.size() > 0) {
        annotation = "annotation (" % view % "(coordinateSystem(" % coOrdinateSystemList.join(",") % "), graphics={" % graphicsList.join(",") % "}));";
      } else {
        annotation = "annotation (" % view % "(graphics={" % graphicsList.join(",") % "}));";
      }
    }

    allItems << annotation;
    allItems.removeAll(QString(""));
    const QString allItemsStr = allItems.join("\n");
    // Load the text in the model.
    if (!allItemsStr.isEmpty() && MainWindow::instance()->getOMCProxy()->loadClassContentString(allItemsStr, mpModelWidget->getLibraryTreeItem()->getNameStructure())) {
      const QString action = "Paste items from clipboard";
      mpModelWidget->beginMacro(action);
      // add components
      if (jsonObject.contains("components")) {
        QJsonArray componentsArray = jsonObject.value("components").toArray();
        for (int i = 0; i < componentsArray.size(); ++i) {
          QJsonObject componentObject = componentsArray.at(i).toObject();
          const QString className = componentObject.value("classname").toString();
          const QString name = componentObject.value("name").toString();
          const bool connector = componentObject.value("connector").toBool();
          const QString placement = componentObject.value("placement").toString();
          const int numberOfElements = mElementsList.size();
          addElementToView(GraphicsView::createModelInstanceComponent(mpModelWidget->getModelInstance(), name, className, connector), false, false, false, QPointF(0, 0), placement, false);
          assert(mElementsList.size() > numberOfElements);
          mElementsList.last()->setSelected(true);
        }
      }
      // add connections
      if (jsonObject.contains("connections")) {
        QJsonArray connectionsArray = jsonObject.value("connections").toArray();
        for (int i = 0; i < connectionsArray.size(); ++i) {
          QJsonObject connectionObject = connectionsArray.at(i).toObject();
          // connection annotation
          QStringList shapesList = StringHandler::getStrings(connectionObject.value("annotation").toString());
          // Now parse the shapes available in list
          QString lineShape = "";
          foreach (QString shape, shapesList) {
            if (shape.startsWith("Line")) {
              lineShape = shape.mid(QString("Line").length());
              lineShape = StringHandler::removeFirstLastParentheses(lineShape);
              break;  // break the loop once we have got the line annotation.
            }
          }
          LineAnnotation *pConnectionLineAnnotation = new LineAnnotation(lineShape, 0, 0, this);
          // the start and end element of connection is added in ModelWidget::drawConnections() when the connection is updated
          pConnectionLineAnnotation->setStartElementName(connectionObject.value("from").toString());
          pConnectionLineAnnotation->setEndElementName(connectionObject.value("to").toString());
          pConnectionLineAnnotation->drawCornerItems();
          pConnectionLineAnnotation->setCornerItemsActiveOrPassive();
          // always add the connections to diagram layer.
          GraphicsView *pDiagramGraphicsView = mpModelWidget->getDiagramGraphicsView();
          pDiagramGraphicsView->addConnectionToView(pConnectionLineAnnotation, false);
          if (isDiagramView()) {
            mConnectionsList.last()->setSelected(true);
          }
        }
      }
      // add shapes
      QStringList shapesList = StringHandler::getStrings(shapesOMC);
      bool state = isAddClassAnnotationNeeded();
      mpModelWidget->drawModelIconDiagramShapes(shapesList, this, true);
      setAddClassAnnotationNeeded(state);
      ModelInfo newModelInfo = mpModelWidget->createModelInfo();
      mpModelWidget->getUndoStack()->push(new OMCUndoCommand(mpModelWidget->getLibraryTreeItem(), oldModelInfo, newModelInfo, action));
      // update the model text
      mpModelWidget->updateModelText();
      mpModelWidget->endMacro();
    }
  }
}

/*!
 * \brief GraphicsView::clearSelection
 * Clears the selection of all shapes, components and connectors.
 * Selects the passed item if its valid.
 * \param pSelectGraphicsItem
 */
void GraphicsView::clearSelection(QGraphicsItem *pSelectGraphicsItem)
{
  foreach (QGraphicsItem *pGraphicsItem, items()) {
    pGraphicsItem->setSelected(false);
  }
  // only select the item if it is valid
  if (pSelectGraphicsItem) {
    pSelectGraphicsItem->setSelected(true);
  }
}

/*!
 * \brief GraphicsView::addClassAnnotation
 * Adds the annotation string of Icon and Diagram layer to the model. Also creates the model icon in the tree.
 * If some custom models are cross referenced then update them accordingly.
 */
void GraphicsView::addClassAnnotation()
{
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView()) {
    return;
  }
  QStringList coordinateSystemList;
  QStringList graphicsList;
  getCoordinateSystemAndGraphics(coordinateSystemList, graphicsList);
  // build the annotation string
  QString annotationString;
  QString viewType = isIconView() ? "Icon" : "Diagram";
  if (coordinateSystemList.size() > 0 && graphicsList.size() > 0) {
    annotationString = QString("annotate=%1(coordinateSystem=CoordinateSystem(%2), graphics={%3})").arg(viewType)
                       .arg(coordinateSystemList.join(",")).arg(graphicsList.join(","));
  } else if (coordinateSystemList.size() > 0) {
    annotationString = QString("annotate=%1(coordinateSystem=CoordinateSystem(%2))").arg(viewType).arg(coordinateSystemList.join(","));
  } else if (graphicsList.size() > 0) {
    annotationString = QString("annotate=%1(graphics={%2})").arg(viewType).arg(graphicsList.join(","));
  } else {
    annotationString = QString("annotate=%1()").arg(viewType);
  }
  // add the class annotation to model through OMC
  if (MainWindow::instance()->getOMCProxy()->addClassAnnotation(mpModelWidget->getLibraryTreeItem()->getNameStructure(), annotationString)) {
    /* When something is added/changed in the icon layer then update the LibraryTreeItem in the Library Browser */
    if (isIconView()) {
      mpModelWidget->getLibraryTreeItem()->handleIconUpdated();
    }
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, tr("Error in class annotation %1").arg(MainWindow::instance()->getOMCProxy()->getResult()),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief GraphicsView::showParameters
 * Opens the ElementParameters dialog for a class.
 *
 */
void GraphicsView::showParameters()
{
  if (mpModelWidget->getLibraryTreeItem()->isModelica()) {
    MainWindow::instance()->getStatusBar()->showMessage(tr("Opening %1 parameters window").arg(mpModelWidget->getModelInstance()->getName()));
    MainWindow::instance()->getProgressBar()->setRange(0, 0);
    MainWindow::instance()->showProgressBar();
    ElementParameters *pElementParameters;
    if (mpModelWidget->isElementMode()) {
      bool inherited = false;
      if (mpModelWidget->getModelInstance()->getRootParentElement()) {
        inherited = mpModelWidget->getModelInstance()->getRootParentElement()->isExtend();
      }
      pElementParameters = new ElementParameters(mpModelWidget->getModelInstance()->getParentElement(), this, inherited, false, 0, 0, 0, MainWindow::instance());
    } else {
      pElementParameters = new ElementParameters(0, this, false, false, 0, 0, 0, MainWindow::instance());
    }
    MainWindow::instance()->hideProgressBar();
    MainWindow::instance()->getStatusBar()->clearMessage();
    pElementParameters->exec();
    pElementParameters->deleteLater();
  }
}

/*!
 * \brief GraphicsView::showGraphicsViewProperties
 * Opens the GraphicsViewProperties dialog.
 */
void GraphicsView::showGraphicsViewProperties()
{
  if (mpModelWidget->getLibraryTreeItem()->isModelica()) {
    GraphicsViewProperties *pGraphicsViewProperties = new GraphicsViewProperties(this);
    pGraphicsViewProperties->exec();
  } else if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
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
 * Manhattanize the selected items by emitting GraphicsView::manhattanize() SIGNAL.
 */
void GraphicsView::manhattanizeItems()
{
  mpModelWidget->beginMacro("Manhattanize");
  emit manhattanize();
  mpModelWidget->updateClassAnnotationIfNeeded();
  mpModelWidget->updateModelText();
  mpModelWidget->endMacro();
}

/*!
 * \brief GraphicsView::deleteItems
 * Deletes the selected items by emitting GraphicsView::deleteSignal() SIGNAL.
 */
void GraphicsView::deleteItems()
{
  mpModelWidget->beginMacro("Delete items");
  ModelInfo oldModelInfo = mpModelWidget->createModelInfo();
  emit deleteSignal();
  ModelInfo newModelInfo = mpModelWidget->createModelInfo();
  mpModelWidget->getUndoStack()->push(new OMCUndoCommand(mpModelWidget->getLibraryTreeItem(), oldModelInfo, newModelInfo, QString("Delete items"), true));
  mpModelWidget->updateClassAnnotationIfNeeded();
  mpModelWidget->updateModelText();
  mpModelWidget->endMacro();
}

/*!
 * \brief GraphicsView::duplicateItems
 * Slot activated when mpDuplicateAction triggered SIGNAL is raised.
 */
void GraphicsView::duplicateItems()
{
  duplicateItems("Duplicate by mouse");
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
 * \brief GraphicsView::showReplaceSubModelDialog
 * function that opens up the ReplaceSubModelDialog Dialog.
 */
void GraphicsView::showReplaceSubModelDialog(QString name)
{
  ReplaceSubModelDialog *pReplaceFMUDialog = new ReplaceSubModelDialog(this, name);
  pReplaceFMUDialog->exec();
}

/*!
 * \brief GraphicsView::addErrorTextShape
 * Creates and adds the error text shape to view when getModelInstance fails.
 */
void GraphicsView::addErrorTextShape()
{
  if (!mpErrorTextShapeAnnotation) {
    mpErrorTextShapeAnnotation = new TextAnnotation("", this);
    mpErrorTextShapeAnnotation->setOrigin(QPointF(0, 50));
    mpErrorTextShapeAnnotation->replaceExtent(0, QPointF(-100, 30));
    mpErrorTextShapeAnnotation->replaceExtent(1, QPointF(100, -30));
    mpErrorTextShapeAnnotation->setLineColor(Qt::red);
    mpErrorTextShapeAnnotation->setTextString(tr("The Modelica code of this model is invalid, so the graphics cannot be displayed."
                                                 "\nPlease check the Messages browser for error messages and possibly undo the latest changes with ctrl-z."));
    mpErrorTextShapeAnnotation->setShapeFlags(false);
    mpErrorTextShapeAnnotation->applyTransformation();
    addItem(mpErrorTextShapeAnnotation);
  }
}

/*!
 * \brief GraphicsView::removeErrorTextShape
 * Removes the error text shape from the view.
 */
void GraphicsView::removeErrorTextShape()
{
  if (mpErrorTextShapeAnnotation) {
    removeItem(mpErrorTextShapeAnnotation);
    delete mpErrorTextShapeAnnotation;
    mpErrorTextShapeAnnotation = 0;
  }
}

/*!
 * \brief GraphicsView::createConnector
 * Creates a connector while making a connection.\n
 * Ends the connection on the newly created connector.
 */
void GraphicsView::createConnector()
{
  if (mpConnectionLineAnnotation && mpConnectionLineAnnotation->getStartElement()) {
    Element *pConnectorElement = mpConnectionLineAnnotation->getStartElement();
    QString defaultName;
    QString name = getUniqueElementName(pConnectorElement->getClassName(), pConnectorElement->getName(), &defaultName);
    ModelInfo oldModelInfo = mpModelWidget->createModelInfo();
    ModelInstance::Component *pComponent = GraphicsView::createModelInstanceComponent(mpModelWidget->getModelInstance(), name, pConnectorElement->getClassName());
    addElementToView(pComponent, false, true, true, mapToScene(mapFromGlobal(QCursor::pos())), "", true);
    addConnection(mElementsList.last(), true);
    ModelInfo newModelInfo = mpModelWidget->createModelInfo();
    mpModelWidget->getUndoStack()->push(new OMCUndoCommand(mpModelWidget->getLibraryTreeItem(), oldModelInfo, newModelInfo, "Add connector"));
    mpModelWidget->updateModelText();
  }
}

/*!
 * \brief GraphicsView::cancelConnection
 * Cancels the current connecton.
 */
void GraphicsView::cancelConnection()
{
  if (mpConnectionLineAnnotation) {
    removeCurrentConnection();
  }
}

/*!
 * \brief GraphicsView::setInitialState
 * Sets the state as initial.
 */
void GraphicsView::setInitialState()
{
  if (mpTransitionLineAnnotation) {
    QString startComponentName;
    if (mpTransitionLineAnnotation->getStartElement()->getParentElement()) {
      startComponentName = QString("%1.%2").arg(mpTransitionLineAnnotation->getStartElement()->getRootParentElement()->getName())
                           .arg(mpTransitionLineAnnotation->getStartElement()->getName());
    } else {
      startComponentName = mpTransitionLineAnnotation->getStartElement()->getName();
    }
    mpTransitionLineAnnotation->setStartElementName(startComponentName);
    mpTransitionLineAnnotation->setEndElementName("");
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
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView() ||
      mpModelWidget->getLibraryTreeItem()->getRestriction() == StringHandler::Package ||
      mpModelWidget->getLibraryTreeItem()->isSSP()) {
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
    pMainWindow->openDroppedFile(event->mimeData());
    event->accept();
  } else if (event->mimeData()->hasFormat(Helper::modelicaComponentFormat)) {
    // check if the class is system library
    if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView()) {
      event->ignore();
      return;
    }
    QByteArray itemData = event->mimeData()->data(Helper::modelicaComponentFormat);
    QDataStream dataStream(&itemData, QIODevice::ReadOnly);
    QString className;
    dataStream >> className;
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    if (addComponent(className, mapToScene(event->position().toPoint()))) {
#else
    if (addComponent(className, mapToScene(event->pos()))) {
#endif
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
  if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView()) {
    painter->setBrush(QBrush(Qt::white, Qt::SolidPattern));
  } else if (isIconView()) {
    painter->setBrush(QBrush(QColor(229, 244, 255), Qt::SolidPattern));
  } else {
    painter->setBrush(QBrush(QColor(242, 242, 242), Qt::SolidPattern));
  }
  // draw scene rectangle white background
  painter->setPen(Qt::NoPen);
  painter->drawRect(rect);
  painter->setBrush(QBrush(Qt::white, Qt::SolidPattern));
  QRectF extentRectangle = mMergedCoordinateSystem.getExtentRectangle();
  painter->drawRect(extentRectangle);
  if (mpModelWidget->getModelWidgetContainer()->isShowGridLines()
      && !(mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView())) {
    painter->setBrush(Qt::NoBrush);
    painter->setPen(lightGrayPen);
    /* Draw left half vertical lines */
    int horizontalGridStep = mMergedCoordinateSystem.getHorizontalGridStep() * 10;
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
    int verticalGridStep = mMergedCoordinateSystem.getVerticalGridStep() * 10;
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
    /* Draw horizontal and vertical gray line from 0,0 */
    painter->setPen(grayPen);
    painter->drawLine(QPointF(rect.left(), 0), QPointF(rect.right(), 0));
    painter->drawLine(QPointF(0, rect.top()), QPointF(0, rect.bottom()));
  }
  // draw scene rectangle
  painter->setPen(grayPen);
  painter->drawRect(extentRectangle);
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
  QPointF scenePos = mapToScene(event->pos());
  QPointF snappedPoint = snapPointToGrid(scenePos);
  bool eventConsumed = false;
  // if left button presses and we are creating a connector
  if (isCreatingConnection()) {
    if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
      mpConnectionLineAnnotation->addPoint(roundPoint(scenePos));
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
    eventConsumed = true;
  } else if (pMainWindow->getPolygonShapeAction()->isChecked()) {
    /* if polygon shape tool button is checked then create a polygon */
    createPolygonShape(snappedPoint);
    eventConsumed = true;
  } else if (pMainWindow->getRectangleShapeAction()->isChecked()) {
    /* if rectangle shape tool button is checked then create a rectangle */
    createRectangleShape(snappedPoint);
    eventConsumed = true;
  } else if (pMainWindow->getEllipseShapeAction()->isChecked()) {
    /* if ellipse shape tool button is checked then create an ellipse */
    createEllipseShape(snappedPoint);
    eventConsumed = true;
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
  } else if (dynamic_cast<CornerItem*>(itemAt(event->pos()))) {
    // do nothing if corner item is clicked. It will be handled in its class mousePressEvent();
  } else {
    // this flag is just used to have separate identity for if statement in mouse release event of graphicsview
    setIsMovingComponentsAndShapes(true);
    // save the position of all components
    foreach (Element *pElement, mElementsList) {
      pElement->setOldPosition(pElement->pos());
      pElement->setOldScenePosition(pElement->scenePos());
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
  // if connector is clicked
  if (Element *pComponent = connectorElementAtPosition(event->pos())) {
    if (!isCreatingConnection()) {
      mpClickedComponent = pComponent;
    } else if (isCreatingConnection()) {
      addConnection(pComponent);  // end the connection
      eventConsumed = true; // consume the event so that connection line or end component will not become selected
    }
  } else if (Element *pComponent = stateElementAtPosition(event->pos())) { // if state is clicked
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
  setFocus(Qt::ActiveWindowFocusReason);
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
  if (connectorElementAtPosition(event->pos()) || stateElementAtPosition(event->pos())) {
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
    if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
      mpConnectionLineAnnotation->updateEndPoint(roundPoint(mapToScene(event->pos())));
    } else {
      mpConnectionLineAnnotation->updateEndPoint(snappedPoint);
    }
  } else if (isCreatingTransition()) {
    mpTransitionLineAnnotation->updateEndPoint(snappedPoint);
  } else if (isCreatingLineShape()) {
    mpLineShapeAnnotation->updateEndPoint(snappedPoint);
  } else if (isCreatingPolygonShape()) {
    mpPolygonShapeAnnotation->updateEndPoint(snappedPoint);
  } else if (isCreatingRectangleShape()) {
    mpRectangleShapeAnnotation->updateExtent(1, snappedPoint);
  } else if (isCreatingEllipseShape()) {
    mpEllipseShapeAnnotation->updateExtent(1, snappedPoint);
  } else if (isCreatingTextShape()) {
    mpTextShapeAnnotation->updateExtent(1, snappedPoint);
  } else if (isCreatingBitmapShape()) {
    mpBitmapShapeAnnotation->updateExtent(1, snappedPoint);
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
    // if component position is really changed then update element annotation
    foreach (Element *pElement, mElementsList) {
      if (pElement->getOldPosition() != pElement->pos()) {
        if (!beginMacro) {
          mpModelWidget->beginMacro("Move items by mouse");
          beginMacro = true;
        }
        Transformation oldTransformation = pElement->mTransformation;
        QPointF positionDifference = pElement->scenePos() - pElement->getOldScenePosition();
        pElement->mTransformation.adjustPosition(positionDifference.x(), positionDifference.y());
        pElement->updateElementTransformations(oldTransformation, true);
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
        QPointF positionDifference = pShapeAnnotation->scenePos() - pShapeAnnotation->getOldScenePosition();
        pShapeAnnotation->moveShape(positionDifference.x(), positionDifference.y());
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

bool GraphicsView::handleDoubleClickOnComponent(QMouseEvent *event)
{
  bool shouldEnactQTDoubleClick = true;
  Element *pComponent = elementAtPosition(event->pos());
  if (pComponent) {
    shouldEnactQTDoubleClick = false;
    Element *pRootComponent = pComponent->getRootParentElement();
    if (pRootComponent) {
      removeCurrentConnection();
      if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
        pRootComponent->handleOMSElementDoubleClick();
      } else {
        removeCurrentTransition();
        bool shiftModifier = QApplication::keyboardModifiers().testFlag(Qt::ShiftModifier);
        bool controlModifier = QApplication::keyboardModifiers().testFlag(Qt::ControlModifier);
        /* ticket:4401 Open component class with shift + double click */
        if (!controlModifier && shiftModifier) {
          pRootComponent->openClass();
        } else if (controlModifier && !shiftModifier) {
          pRootComponent->showElement();
        } else {
          pRootComponent->showParameters();
        }
      }
    }
  }
  return shouldEnactQTDoubleClick;
}

/*!
 * \brief GraphicsView::mouseDoubleClickEvent
 * Defines what happens when double clicking in a GraphicsView.
 * \param event
 */
void GraphicsView::mouseDoubleClickEvent(QMouseEvent *event)
{
  /* If is visualization view.
   * Issue #12049. Stop double click event when the getModelInstance API fails.
   */
  if (isVisualizationView() || (mpModelWidget->getLibraryTreeItem()->isModelica() && mpModelWidget->getModelInstance()->isModelJsonEmpty())) {
    return;
  }
  const bool removeLastAddedPoint = true;
  if (isCreatingLineShape()) {
    finishDrawingLineShape(removeLastAddedPoint);
    setFocus(Qt::ActiveWindowFocusReason);
    return;
  } else if (isCreatingPolygonShape()) {
    finishDrawingPolygonShape(removeLastAddedPoint);
    setFocus(Qt::ActiveWindowFocusReason);
    return;
  }
  ShapeAnnotation *pShapeAnnotation = dynamic_cast<ShapeAnnotation*>(itemAt(event->pos()));
  /* Double click on Component also end up here.
   * But we don't have GraphicsView for the shapes inside the Component so we can go out of this block.
   */
  if (!isCreatingConnection() && !isCreatingTransition() && pShapeAnnotation && pShapeAnnotation->getGraphicsView()) {
    if (mpModelWidget->getLibraryTreeItem()->isModelica()) {
      LineAnnotation *pTransitionLineAnnotation = dynamic_cast<LineAnnotation*>(pShapeAnnotation);
      if (pTransitionLineAnnotation && pTransitionLineAnnotation->isTransition()) {
        pShapeAnnotation->editTransition();
      } else {
        pShapeAnnotation->showShapeProperties();
      }
      return;
    } else if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
      LineAnnotation *pConnectionLineAnnotation = dynamic_cast<LineAnnotation*>(pShapeAnnotation);
      if (pConnectionLineAnnotation && pConnectionLineAnnotation->isConnection()) {
        pConnectionLineAnnotation->showOMSConnection();
      }
    }
  }
  if (!handleDoubleClickOnComponent(event)) {
    return;
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
  /*If we get a focus out event while drawing. Stop drawing.*/
  if (isCreatingShape()) {
    finishDrawingGenericShape();
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
    deleteItems();
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
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_A) {
    selectAll();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_X && isAnyItemSelectedAndEditable(event->key()) && mpModelWidget->getLibraryTreeItem()->isModelica()) {
    cutItems();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_C && mpModelWidget->getLibraryTreeItem()->isModelica()) {
    copyItems();
  } else if (!shiftModifier && controlModifier && event->key() == Qt::Key_V && mpModelWidget->getLibraryTreeItem()->isModelica()) {
    bool isSystemLibrary = mpModelWidget->getLibraryTreeItem()->isSystemLibrary() || mpModelWidget->isElementMode() || isVisualizationView();
    if (!isSystemLibrary) {
      pasteItems();
    }
  } else if (controlModifier && event->key() == Qt::Key_D && isAnyItemSelectedAndEditable(event->key())) {
    duplicateItems("Duplicate by key press");
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
      Element *pComponent = dynamic_cast<Element*>(selectedItems.at(0));
      if (pComponent) {
        Element *pRootComponent = pComponent->getRootParentElement();
        if (pRootComponent) {
          pRootComponent->openClass();
        }
      }
    }
  } else if (event->key() == Qt::Key_Escape && isCreatingConnection()) {
    removeCurrentConnection();
  } else if (event->key() == Qt::Key_Escape && isCreatingTransition()) {
    removeCurrentTransition();
  } else if (event->key() == Qt::Key_Escape && isCreatingShape()) {
    finishDrawingGenericShape();
  } else {
    QGraphicsView::keyPressEvent(event);
  }
}

void GraphicsView::uncheckAllShapeDrawingActions()
{
  MainWindow *pMainWindow = MainWindow::instance();
  pMainWindow->toggleShapesButton();
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

/*!
 * \brief GraphicsView::contextMenuEvent
 * Shows the context menu.
 * \param event
 */
void GraphicsView::contextMenuEvent(QContextMenuEvent *event)
{
  /* If we are creating the connection OR creating any shape OR is visualization view then don't show context menu
   * Issue #12049. Stop context menu event when the getModelInstance API fails.
   */
  if (isCreatingShape() || isVisualizationView() || (mpModelWidget->getLibraryTreeItem()->isModelica() && mpModelWidget->getModelInstance()->isModelJsonEmpty())) {
    return;
  }
  // if creating a connection
  if (isCreatingConnection()) {
    if (mpModelWidget->getLibraryTreeItem()->isModelica()) {
      QMenu menu(MainWindow::instance());
      menu.addAction(mpCreateConnectorAction);
      menu.addSeparator();
      menu.addAction(mpCancelConnectionAction);
      menu.exec(event->globalPos());
    }
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
    QMenu menu;
    mContextMenuStartPosition = mapToScene(mapFromGlobal(QCursor::pos()));
    mContextMenuStartPositionValid = true;
    if (mpModelWidget->getLibraryTreeItem()->isModelica()) {
      modelicaGraphicsViewContextMenu(&menu);
    } else if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
      omsGraphicsViewContextMenu(&menu);
    }
    menu.exec(event->globalPos());
    mContextMenuStartPosition = QPointF(0, 0);
    mContextMenuStartPositionValid = false;
    return; // return from it because at a time we only want one context menu.
  } else {  // if we click on some item.
    bool oneShapeSelected = false;
    bool oneComponentSelected = false;
    // if a shape is right clicked
    ShapeAnnotation *pShapeAnnotation = dynamic_cast<ShapeAnnotation*>(itemAt(event->pos()));
    Element *pComponent = 0;
    if (pShapeAnnotation && pShapeAnnotation->getGraphicsView()) {
      if (!pShapeAnnotation->isSelected()) {
        clearSelection(pShapeAnnotation);
      }
      oneShapeSelected = scene()->selectedItems().size() == 1;
    } else {
      // if a component is right clicked
      pComponent = elementAtPosition(event->pos());
      if (pComponent) {
        if (!pComponent->isSelected()) {
          clearSelection(pComponent);
        }
        oneComponentSelected = scene()->selectedItems().size() == 1;
      }
    }
    // construct context menu now
    QMenu menu;
    if (oneShapeSelected) {
      if (mpModelWidget->getLibraryTreeItem()->isModelica()) {
        modelicaOneShapeContextMenu(pShapeAnnotation, &menu);
      } else if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
        omsOneShapeContextMenu(pShapeAnnotation, &menu);
      }
    } else if (oneComponentSelected) {
      if (mpModelWidget->getLibraryTreeItem()->isModelica()) {
        modelicaOneComponentContextMenu(pComponent, &menu);
      } else if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
        // No context menu for component of type OMS connector i.e., input/output signal or OMS bus connector.
        if (pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->isSSP()
            && (pComponent->getLibraryTreeItem()->getOMSConnector()
                || pComponent->getLibraryTreeItem()->getOMSBusConnector()
                || pComponent->getLibraryTreeItem()->getOMSTLMBusConnector())) {
          return;
        }
        omsOneComponentContextMenu(pComponent, &menu);
      }
    } else {
      if (mpModelWidget->getLibraryTreeItem()->isModelica()) {
        modelicaMultipleItemsContextMenu(&menu);
      } else if (mpModelWidget->getLibraryTreeItem()->isSSP()) {
        omsMultipleItemsContextMenu(&menu);
      }
    }
    // enable/disable common actions based on if any inherited item is selected
    bool noInheritedItemSelected = true;
    QList<QGraphicsItem*> graphicsItems = scene()->selectedItems();
    foreach (QGraphicsItem *pGraphicsItem, graphicsItems) {
      Element *pComponent = getElementFromQGraphicsItem(pGraphicsItem);
      if (pComponent) {
        Element *pRootComponent = pComponent->getRootParentElement();
        if (pRootComponent && pRootComponent->isInheritedElement() && pRootComponent->isSelected()) {
          noInheritedItemSelected = false;
        }
      } else if (ShapeAnnotation *pShapeAnnotation = dynamic_cast<ShapeAnnotation*>(pGraphicsItem)) {
        if (pShapeAnnotation->isInheritedShape() && pShapeAnnotation->isSelected()) {
          noInheritedItemSelected = false;
        }
      }
    }
    bool isSystemLibrary = mpModelWidget->getLibraryTreeItem()->isSystemLibrary();
    bool isElementMode = mpModelWidget->isElementMode();
    mpManhattanizeAction->setEnabled(noInheritedItemSelected && !isSystemLibrary && !isElementMode);
    mpDeleteAction->setEnabled(noInheritedItemSelected && !isSystemLibrary && !isElementMode);
    mpCutAction->setEnabled(noInheritedItemSelected && !isSystemLibrary && !isElementMode);
    mpDuplicateAction->setEnabled(noInheritedItemSelected && !isSystemLibrary && !isElementMode);
    mpRotateClockwiseAction->setEnabled(noInheritedItemSelected && !isSystemLibrary && !isElementMode);
    mpRotateAntiClockwiseAction->setEnabled(noInheritedItemSelected && !isSystemLibrary && !isElementMode);
    mpFlipHorizontalAction->setEnabled(noInheritedItemSelected && !isSystemLibrary && !isElementMode);
    mpFlipVerticalAction->setEnabled(noInheritedItemSelected && !isSystemLibrary && !isElementMode);
    menu.exec(event->globalPos());
    return; // return from it because at a time we only want one context menu.
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
#if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0)
  static QPoint angleDelta = QPoint(0, 0);
  angleDelta += event->angleDelta();
  QPoint numDegrees = angleDelta / 8;
  QPoint numSteps = numDegrees / 15; // see QWheelEvent documentation
  if (numSteps.x() != 0 || numSteps.y() != 0) {
    angleDelta = QPoint(0, 0);
    const bool horizontal = qAbs(event->angleDelta().x()) > qAbs(event->angleDelta().y());
    bool controlModifier = event->modifiers().testFlag(Qt::ControlModifier);
    bool shiftModifier = event->modifiers().testFlag(Qt::ShiftModifier);
    // If Ctrl key is pressed and user has scrolled vertically then Zoom In/Out based on the scroll distance.
    if (!horizontal && numSteps.y() != 0 && controlModifier) {
      if (numSteps.y() > 0) {
        zoomIn();
      } else {
        zoomOut();
      }
    } else if (horizontal) { // If user has scrolled horizontally then scroll the horizontal scrollbars.
      horizontalScrollBar()->setValue(horizontalScrollBar()->value() - event->angleDelta().x());
    } else if (!horizontal && shiftModifier) { // If Shift key is pressed and user has scrolled vertically then scroll the horizontal scrollbars.
      horizontalScrollBar()->setValue(horizontalScrollBar()->value() - event->angleDelta().y());
    } else if (!horizontal) { // If user has scrolled vertically then scroll the vertical scrollbars.
      verticalScrollBar()->setValue(verticalScrollBar()->value() - event->angleDelta().y());
    } else {
      QGraphicsView::wheelEvent(event);
    }
  }
#else // QT_VERSION_CHECK
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
#endif // QT_VERSION_CHECK
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
  topFrameLayout->addWidget(mpHeadingLabel, 1);
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
  mpLatestNewsLabel = Utilities::getHeadingLabel(tr("Latest News & Events"));
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
  mpLatestNewsNetworkAccessManager = new NetworkAccessManager;
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
  const QString buttonStyleSheet = "QPushButton{padding: 5px 15px 5px 15px;}";
  mpCreateModelButton = new QPushButton(Helper::createNewModelicaClass);
  mpCreateModelButton->setStyleSheet(buttonStyleSheet);
  connect(mpCreateModelButton, SIGNAL(clicked()), MainWindow::instance(), SLOT(createNewModelicaClass()));
  mpOpenModelButton = new QPushButton(Helper::openModelicaFiles);
  mpOpenModelButton->setStyleSheet(buttonStyleSheet);
  connect(mpOpenModelButton, SIGNAL(clicked()), MainWindow::instance(), SLOT(openModelicaFile()));
  mpSystemLibrariesButton = new QPushButton(tr("System Libraries"));
  mpSystemLibrariesButton->setStyleSheet(buttonStyleSheet);
  mpSystemLibrariesButton->setMenu(MainWindow::instance()->getLibrariesMenu());
  mpInstallLibraryButton = new QPushButton(Helper::installLibrary);
  mpInstallLibraryButton->setStyleSheet(buttonStyleSheet);
  connect(mpInstallLibraryButton, SIGNAL(clicked()), MainWindow::instance(), SLOT(openInstallLibraryDialog()));
  // bottom frame layout
  QHBoxLayout *pBottomFrameLayout = new QHBoxLayout;
  pBottomFrameLayout->setAlignment(Qt::AlignLeft);
  pBottomFrameLayout->addWidget(mpCreateModelButton);
  pBottomFrameLayout->addWidget(mpOpenModelButton);
  pBottomFrameLayout->addWidget(mpSystemLibrariesButton);
  pBottomFrameLayout->addWidget(mpInstallLibraryButton);
  mpBottomFrame->setLayout(pBottomFrameLayout);
  // vertical layout for frames
  QVBoxLayout *verticalLayout = new QVBoxLayout;
  verticalLayout->setSpacing(4);
  verticalLayout->setContentsMargins(0, 0, 0, 0);
  verticalLayout->addWidget(mpTopFrame, 0, Qt::AlignTop);
  verticalLayout->addWidget(mpSplitter, 1);
  // Issue #10235. Use QScrollArea so we can resize.
  QScrollArea *pBottomScrollArea = new QScrollArea;
  pBottomScrollArea->setFrameShape(QFrame::NoFrame);
  pBottomScrollArea->setBackgroundRole(QPalette::Base);
  pBottomScrollArea->setWidgetResizable(true);
  pBottomScrollArea->setWidget(mpBottomFrame);
  verticalLayout->addWidget(pBottomScrollArea, 0, Qt::AlignBottom);
  // main frame layout
  mpMainFrame->setLayout(verticalLayout);
  QHBoxLayout *layout = new QHBoxLayout;
  layout->setContentsMargins(0, 0, 0, 0);
  layout->addWidget(mpMainFrame);
  setLayout(layout);
}

/*!
 * \brief WelcomePageWidget::addRecentFilesListItems
 * Adds the recent file list items to list view.
 */
void WelcomePageWidget::addRecentFilesListItems()
{
  // remove list items first
  mpRecentItemsList->clear();
  QSettings *pSettings = Utilities::getApplicationSettings();
  QList<QVariant> files = pSettings->value("recentFilesList/files").toList();
  int recentFilesSize = OptionsDialog::instance()->getGeneralSettingsPage()->getRecentFilesAndLatestNewsSizeSpinBox()->value();
  int numRecentFiles = qMin(files.size(), recentFilesSize);
  for (int i = 0; i < numRecentFiles; ++i) {
    RecentFile recentFile = qvariant_cast<RecentFile>(files[i]);
    QListWidgetItem *listItem = new QListWidgetItem(mpRecentItemsList);
    listItem->setIcon(ResourceCache::getIcon(":/Resources/icons/next.svg"));
    listItem->setText(recentFile.fileName);
    listItem->setData(Qt::UserRole, recentFile.encoding);
  }
  if (numRecentFiles > 0) {
    mpNoRecentFileLabel->setVisible(false);
  } else {
    mpNoRecentFileLabel->setVisible(true);
  }
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
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getShowLatestNewsCheckBox()->isChecked()) {
    QUrl newsUrl("https://openmodelica.org/tags/news/index.xml");
    mpLatestNewsNetworkAccessManager->get(QNetworkRequest(newsUrl));
  }
}

void WelcomePageWidget::readLatestNewsXML(QNetworkReply *pNetworkReply)
{
  int maxNewsSize = OptionsDialog::instance()->getGeneralSettingsPage()->getRecentFilesAndLatestNewsSizeSpinBox()->value();
  if (pNetworkReply->error() == QNetworkReply::HostNotFoundError) {
    mpNoLatestNewsLabel->setVisible(true);
    mpNoLatestNewsLabel->setText(tr("Sorry, no internet no news items."));
  } else if (pNetworkReply->error() == QNetworkReply::NoError) {
    QByteArray response(pNetworkReply->readAll());
    QXmlStreamReader xml(response);
    int count = 0;
    QString title, link;
    QDateTime pubDateTime, endDateTime;
    while (!xml.atEnd()) {
      mpNoLatestNewsLabel->setVisible(false);
      xml.readNext();
      if (xml.tokenType() == QXmlStreamReader::StartElement) {
        if (xml.name() == QString("item")) {
          title = "";
          link = "";
          pubDateTime = QDateTime();
          endDateTime = QDateTime();
          // read everything inside item
          xml.readNext();
          if (xml.name() == QString("title")) {
            title = xml.readElementText();
          }
          xml.readNext();
          if (xml.name() == QString("link")) {
            link = xml.readElementText();
          }
          xml.readNext();
          if (xml.name() == QString("pubDate")) {
            pubDateTime = QDateTime::fromString(xml.readElementText(), Qt::RFC2822Date);
          }
          xml.readNext();
          if (xml.name() == QString("endDate")) {
            endDateTime = QDateTime::fromString(xml.readElementText(), Qt::RFC2822Date);
          }
        }
      } else if (xml.tokenType() == QXmlStreamReader::EndElement) {
        if (xml.name() == QString("item")) {
          // add the item to the list view
          QListWidgetItem *listItem = new QListWidgetItem(mpLatestNewsListWidget);
          listItem->setIcon(ResourceCache::getIcon(":/Resources/icons/next.svg"));
          QString itemTitle;
          if (pubDateTime.isValid() && endDateTime.isValid()) {
            itemTitle = QLocale::c().toString(pubDateTime, "yyyy-MM-dd") % " - " % QLocale::c().toString(endDateTime, "yyyy-MM-dd") % " " % title;
          } else if (pubDateTime.isValid()) {
            itemTitle = QLocale::c().toString(pubDateTime, "yyyy-MM-dd") % " " % title;
          } else {
            itemTitle = title;
          }
          listItem->setText(itemTitle);
          listItem->setData(Qt::UserRole, link);
          count++;
          // if reached max news size
          if (count >= maxNewsSize) {
            break;
          }
        }
      }
    }
  } else {
    mpNoLatestNewsLabel->setVisible(true);
    mpNoLatestNewsLabel->setText(QString(Helper::error).append(" - ").append(pNetworkReply->errorString()));
  }
  pNetworkReply->deleteLater();
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
  : QWidget(pModelWidgetContainer), mpModelWidgetContainer(pModelWidgetContainer), mpModelInstance(0), mpLibraryTreeItem(pLibraryTreeItem),
    mpUndoStack(0), mpUndoView(0), mpEditor(0), mDiagramViewLoaded(false), mCreateModelWidgetComponents(false)
{
  // create widgets based on library type
  if (mpLibraryTreeItem->isModelica()) {
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
    createUndoStack();
    loadModelInstance(true, ModelInfo());
    /* Ticket:5620
     * Hack to make the operations like moving objects with keys faster.
     * We don't update the model directly instead we start a timer.
     * Update the model on the timer timeout function. The timer is singleshot and ensures atleast one time run of updateModel().
     * Bundles the several operations together by calling timer start function before the timer is timed out.
     */
    mUpdateModelTimer.setSingleShot(true);
    mUpdateModelTimer.setInterval(500);
    connect(&mUpdateModelTimer, SIGNAL(timeout()), SLOT(updateModel()));
  } else if (mpLibraryTreeItem->isSSP()) {
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
    mpLibraryTreeItem->getClassText(MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel());
    createUndoStack();
    drawOMSModelIconElements();
  } else {
    // icon graphics framework
    mpIconGraphicsScene = 0;
    mpIconGraphicsView = 0;
    // diagram graphics framework
    mpDiagramGraphicsScene = 0;
    mpDiagramGraphicsView = 0;
  }
  // Read the file for LibraryTreeItem::Text
  if (mpLibraryTreeItem->isText() && !mpLibraryTreeItem->isFilePathValid()) {
    QString contents = "";
    QFile file(mpLibraryTreeItem->getFileName());
    if (!file.open(QIODevice::ReadOnly)) {
      //      QMessageBox::critical(mpLibraryWidget->MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::error),
      //                            GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(pLibraryTreeItem->getFileName())
      //                            .arg(file.errorString()), QMessageBox::Ok);
    } else {
      contents = QString(file.readAll());
      file.close();
    }
    mpLibraryTreeItem->setClassText(contents);
  }
}

ModelWidget::~ModelWidget()
{
  if (mpModelInstance) {
    delete mpModelInstance;
  }
}

void ModelWidget::addDependsOnModel(const QString &dependsOnModel)
{
  if (!mDependsOnModelsList.contains(dependsOnModel)) {
    mDependsOnModelsList.append(dependsOnModel);
    connect(MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel(), SIGNAL(modelStateChanged(QString)), SLOT(updateModelIfDependsOn(QString)), Qt::UniqueConnection);
  }
}

/*!
 * \brief ModelWidget::drawModelIconDiagramShapes
 * Draws the model shapes.
 * \param shapes
 * \param pGraphicsView
 */
void ModelWidget::drawModelIconDiagramShapes(QStringList shapes, GraphicsView *pGraphicsView, bool select)
{
  foreach (QString shape, shapes) {
    ShapeAnnotation *pShapeAnnotation = 0;
    if (shape.startsWith("Line")) {
      shape = shape.mid(QString("Line").length());
      shape = StringHandler::removeFirstLastParentheses(shape);
      pShapeAnnotation = new LineAnnotation(shape, pGraphicsView);
    } else if (shape.startsWith("Polygon")) {
      shape = shape.mid(QString("Polygon").length());
      shape = StringHandler::removeFirstLastParentheses(shape);
      pShapeAnnotation = new PolygonAnnotation(shape, pGraphicsView);
    } else if (shape.startsWith("Rectangle")) {
      shape = shape.mid(QString("Rectangle").length());
      shape = StringHandler::removeFirstLastParentheses(shape);
      pShapeAnnotation = new RectangleAnnotation(shape, pGraphicsView);
    } else if (shape.startsWith("Ellipse")) {
      shape = shape.mid(QString("Ellipse").length());
      shape = StringHandler::removeFirstLastParentheses(shape);
      pShapeAnnotation = new EllipseAnnotation(shape, pGraphicsView);
    } else if (shape.startsWith("Text")) {
      shape = shape.mid(QString("Text").length());
      shape = StringHandler::removeFirstLastParentheses(shape);
      pShapeAnnotation = new TextAnnotation(shape, pGraphicsView);
    } else if (shape.startsWith("Bitmap")) {
      /* create the bitmap shape */
      shape = shape.mid(QString("Bitmap").length());
      shape = StringHandler::removeFirstLastParentheses(shape);
      pShapeAnnotation = new BitmapAnnotation(mpLibraryTreeItem->mClassInformation.fileName, shape, pGraphicsView);
    }
    if (pShapeAnnotation) {
      pShapeAnnotation->drawCornerItems();
      pShapeAnnotation->setCornerItemsActiveOrPassive();
      pShapeAnnotation->applyTransformation();
      mpUndoStack->push(new AddShapeCommand(pShapeAnnotation));
      if (select) {
        pShapeAnnotation->setSelected(true);
      }
    }
  }
}

void ModelWidget::drawModel(const ModelInfo &modelInfo)
{
  mpIconGraphicsView->drawCoordinateSystem();
  mpDiagramGraphicsView->drawCoordinateSystem();
  clearDependsOnModels();
  disconnect(MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel(), SIGNAL(modelStateChanged(QString)), this, SLOT(updateModelIfDependsOn(QString)));
  // if we are drawing the model inside the element mode and the parent element is extends so draw the element as inherited.
  ModelInstance::Element *pElement = mpModelInstance->getRootParentElement();
  if (pElement && pElement->isExtend()) {
    drawModelIconDiagram(mpModelInstance, true, modelInfo);
  } else {
    drawModelIconDiagram(mpModelInstance, false, modelInfo);
  }
  mpDiagramGraphicsView->handleCollidingConnections();
  /* Issue #12049
   * Show the error message when the getModelInstance returns empty JSON.
   */
  mpIconGraphicsView->removeErrorTextShape();
  mpDiagramGraphicsView->removeErrorTextShape();
  if (mpModelInstance->isModelJsonEmpty()) {
    mpIconGraphicsView->addErrorTextShape();
    mpDiagramGraphicsView->addErrorTextShape();
  }
}

void ModelWidget::drawModelIconDiagram(ModelInstance::Model *pModelInstance, bool inherited, const ModelInfo &modelInfo)
{
  QList<ModelInstance::Element*> elements = pModelInstance->getElements();
  foreach (auto pElement, elements) {
    if (pElement->isExtend() && pElement->getModel()) {
      auto pExtend = dynamic_cast<ModelInstance::Extend*>(pElement);
      addDependsOnModel(pExtend->getModel()->getName());
      drawModelIconDiagram(pExtend->getModel(), true, modelInfo);
    }
  }

  mpIconGraphicsView->drawShapes(pModelInstance, inherited, modelInfo.mName.isEmpty());
  mpDiagramGraphicsView->drawShapes(pModelInstance, inherited, modelInfo.mName.isEmpty());
  mpDiagramGraphicsView->drawElements(pModelInstance, inherited, modelInfo);
  mpDiagramGraphicsView->drawConnections(pModelInstance, inherited, modelInfo);
  mpDiagramGraphicsView->drawTransitions(pModelInstance, inherited, modelInfo);
  mpDiagramGraphicsView->drawInitialStates(pModelInstance, inherited, modelInfo);
}

/*!
 * \brief ModelWidget::loadModelInstance
 * Calls getModelInstance and draws the model.
 * \param icon
 * \param modelInfo
 */
void ModelWidget::loadModelInstance(bool icon, const ModelInfo &modelInfo)
{
  // save the current ModelInstance pointer so we can delete it later.
  ModelInstance::Model *pOldModelInstance = mpModelInstance;
  QElapsedTimer timer;
  timer.start();
  // call getModelInstance
  const QJsonObject jsonObject = MainWindow::instance()->getOMCProxy()->getModelInstance(mpLibraryTreeItem->getNameStructure(), "", false, icon);
  // set the new ModelInstance
  mpModelInstance = new ModelInstance::Model(jsonObject);
  if (MainWindow::instance()->isNewApiProfiling()) {
    double elapsed = (double)timer.elapsed() / 1000.0;
    MainWindow::instance()->writeNewApiProfiling(QString("Time for parsing JSON %1 secs").arg(QString::number(elapsed, 'f', 6)));
  }
  timer.restart();
  // drawing
  drawModel(modelInfo);
  if (MainWindow::instance()->isNewApiProfiling()) {
    double elapsed = (double)timer.elapsed() / 1000.0;
    MainWindow::instance()->writeNewApiProfiling(QString("Time for drawing graphical objects %1 secs").arg(QString::number(elapsed, 'f', 6)));
    MainWindow::instance()->writeNewApiProfiling("\n");
  }

  // delete the old ModelInstance
  if (pOldModelInstance) {
    delete pOldModelInstance;
  }
}

/*!
 * \brief ModelWidget::loadDiagramViewNAPI
 * Loads the diagram view if its not loaded before.
 */
void ModelWidget::loadDiagramViewNAPI()
{
  if (!mDiagramViewLoaded) {
    mDiagramViewLoaded = true;
    // clear graphical views
    clearGraphicsViews();
    // reset the CoordinateSystem
    if (mpIconGraphicsView) {
      mpIconGraphicsView->resetCoordinateSystem();
    }
    if (mpDiagramGraphicsView) {
      mpDiagramGraphicsView->resetCoordinateSystem();
    }
    loadModelInstance(false, ModelInfo());
    mpLibraryTreeItem->handleIconUpdated();
  }
}

/*!
 * \brief ModelWidget::detectMultipleDeclarations
 * detect multiple declarations of a element instance
 */
void ModelWidget::detectMultipleDeclarations()
{
  QList<ModelInstance::Element*> elements = mpModelInstance->getElements();
  for (int i = 0 ; i < elements.size() ; i++) {
    for (int j = 0 ; j < elements.size() ; j++) {
      if (i == j) {
        j++;
        continue;
      }
      if (elements[i]->isComponent() && elements[j]->isComponent()) {
        auto pComponent1 = dynamic_cast<ModelInstance::Component*>(elements[i]);
        auto pComponent2 = dynamic_cast<ModelInstance::Component*>(elements[j]);
        if (pComponent1->getName().compare(pComponent2->getName()) == 0) {
          MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                                GUIMessages::getMessage(GUIMessages::MULTIPLE_DECLARATIONS_COMPONENT).arg(pComponent1->getName()),
                                                                Helper::scriptingKind, Helper::errorLevel));
          return;
        }
      }
    }
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
    mpIconViewToolButton->setIcon(ResourceCache::getIcon(":/Resources/icons/model.svg"));
    mpIconViewToolButton->setToolTip(Helper::iconView);
    mpIconViewToolButton->setAutoRaise(true);
    mpIconViewToolButton->setCheckable(true);
    // diagram view tool button
    mpDiagramViewToolButton = new QToolButton;
    mpDiagramViewToolButton->setText(Helper::diagramView);
    mpDiagramViewToolButton->setIcon(ResourceCache::getIcon(":/Resources/icons/modeling.png"));
    mpDiagramViewToolButton->setToolTip(Helper::diagramView);
    mpDiagramViewToolButton->setAutoRaise(true);
    mpDiagramViewToolButton->setCheckable(true);
    // modelica text view tool button
    mpTextViewToolButton = new QToolButton;
    mpTextViewToolButton->setText(Helper::textView);
    mpTextViewToolButton->setIcon(ResourceCache::getIcon(":/Resources/icons/modeltext.svg"));
    mpTextViewToolButton->setToolTip(Helper::textView);
    mpTextViewToolButton->setAutoRaise(true);
    mpTextViewToolButton->setCheckable(true);
    // documentation view tool button
    mpDocumentationViewToolButton = new QToolButton;
    mpDocumentationViewToolButton->setText(Helper::documentationView);
    mpDocumentationViewToolButton->setIcon(ResourceCache::getIcon(":/Resources/icons/info-icon.svg"));
    mpDocumentationViewToolButton->setToolTip(Helper::documentationView);
    mpDocumentationViewToolButton->setAutoRaise(true);
    // view buttons box
    mpViewsButtonGroup = new QButtonGroup(this);
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
    // back tool button
    mpBackToolButton = new QToolButton;
    mpBackToolButton->setText(tr("Back"));
    mpBackToolButton->setIcon(ResourceCache::getIcon(":/Resources/icons/previous.svg"));
    mpBackToolButton->setToolTip(tr("Back"));
    mpBackToolButton->setAutoRaise(true);
    mpBackToolButton->setEnabled(false);
    connect(mpBackToolButton, SIGNAL(clicked()), SLOT(backElement()));
    // forward tool button
    mpForwardToolButton = new QToolButton;
    mpForwardToolButton->setText(tr("Forward"));
    mpForwardToolButton->setIcon(ResourceCache::getIcon(":/Resources/icons/next.svg"));
    mpForwardToolButton->setToolTip(tr("Forward"));
    mpForwardToolButton->setAutoRaise(true);
    mpForwardToolButton->setEnabled(false);
    connect(mpForwardToolButton, SIGNAL(clicked()), SLOT(forwardElement()));
    // exit tool button
    mpExitToolButton = new QToolButton;
    mpExitToolButton->setText(tr("Exit"));
    mpExitToolButton->setIcon(ResourceCache::getIcon(":/Resources/icons/delete.svg"));
    mpExitToolButton->setToolTip(tr("Exit Element"));
    mpExitToolButton->setAutoRaise(true);
    mpExitToolButton->setEnabled(false);
    connect(mpExitToolButton, SIGNAL(clicked()), SLOT(exitElement()));
    // description label for element mode
    mpElementModeLabel = new Label;
    // frame to contain element mode buttons
    QHBoxLayout *pElementModeButtonsHorizontalLayout = new QHBoxLayout;
    pElementModeButtonsHorizontalLayout->setContentsMargins(0, 0, 0, 0);
    pElementModeButtonsHorizontalLayout->setSpacing(0);
    pElementModeButtonsHorizontalLayout->addWidget(mpBackToolButton);
    pElementModeButtonsHorizontalLayout->addWidget(mpForwardToolButton);
    pElementModeButtonsHorizontalLayout->addWidget(mpExitToolButton);
    pElementModeButtonsHorizontalLayout->addWidget(mpElementModeLabel);
    QFrame *pElementModeButtonsFrame = new QFrame;
    pElementModeButtonsFrame->setLayout(pElementModeButtonsHorizontalLayout);
    // set Project Status Bar lables
    mpReadOnlyLabel = mpLibraryTreeItem->isReadOnly() ? new Label(Helper::readOnly) : new Label(tr("Writable"));
    mpModelicaTypeLabel = new Label;
    mpViewTypeLabel = new Label;
    mpModelClassPathLabel = new Label(mpLibraryTreeItem->getNameStructure());
    mpModelFilePathLabel = new Label(mpLibraryTreeItem->getFileName());
    mpModelFilePathLabel->setElideMode(Qt::ElideMiddle);
    // documentation view tool button
    mpFileLockToolButton = new QToolButton;
    mpFileLockToolButton->setIcon(ResourceCache::getIcon(mpLibraryTreeItem->isReadOnly() ? ":/Resources/icons/lock.svg" : ":/Resources/icons/unlock.svg"));
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
    mpMainLayout = new QVBoxLayout;
    mpMainLayout->setContentsMargins(0, 0, 0, 0);
    mpMainLayout->setSpacing(4);
    mpMainLayout->addWidget(mpModelStatusBar);
    setLayout(mpMainLayout);
    MainWindow *pMainWindow = MainWindow::instance();
    // show hide widgets based on library type
    if (mpLibraryTreeItem->isModelica()) {
      connect(mpIconViewToolButton, SIGNAL(toggled(bool)), SLOT(showIconView(bool)));
      connect(mpDiagramViewToolButton, SIGNAL(toggled(bool)), SLOT(showDiagramView(bool)));
      connect(mpTextViewToolButton, SIGNAL(toggled(bool)), SLOT(showTextView(bool)));
      connect(mpDocumentationViewToolButton, SIGNAL(clicked()), SLOT(showDocumentationView()));
      pViewButtonsHorizontalLayout->addWidget(mpIconViewToolButton);
      pViewButtonsHorizontalLayout->addWidget(mpDiagramViewToolButton);
      pViewButtonsHorizontalLayout->addWidget(mpTextViewToolButton);
      pViewButtonsHorizontalLayout->addWidget(mpDocumentationViewToolButton);
      mpModelStatusBar->addPermanentWidget(pElementModeButtonsFrame);
      mpModelicaTypeLabel->setText(StringHandler::getModelicaClassType(mpLibraryTreeItem->getRestriction()));
      mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::Diagram));
      // modelica text editor
      mpEditor = new ModelicaEditor(this);
      ModelicaHighlighter *pModelicaTextHighlighter = new ModelicaHighlighter(OptionsDialog::instance()->getModelicaEditorPage(), mpEditor->getPlainTextEdit());
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
        mpMainLayout->addWidget(mpUndoView);
      }
      mpMainLayout->addWidget(mpDiagramGraphicsView, 1);
      mpMainLayout->addWidget(mpIconGraphicsView, 1);
      mpUndoStack->clear();
    } else if (mpLibraryTreeItem->isText()) {
      pViewButtonsHorizontalLayout->addWidget(mpTextViewToolButton);
      QFileInfo fileInfo(mpLibraryTreeItem->getFileName());
      if (Utilities::isCFile(fileInfo.suffix())) {
        mpEditor = new CEditor(this);
        CHighlighter *pCHighlighter = new CHighlighter(OptionsDialog::instance()->getCEditorPage(), mpEditor->getPlainTextEdit());
        CEditor *pCEditor = dynamic_cast<CEditor*>(mpEditor);
        pCEditor->setPlainText(mpLibraryTreeItem->getClassText(pMainWindow->getLibraryWidget()->getLibraryTreeModel()));
        mpEditor->hide();
        connect(OptionsDialog::instance(), SIGNAL(cEditorSettingsChanged()), pCHighlighter, SLOT(settingsChanged()));
      } else if (mpLibraryTreeItem->isCRMLFile()) {
        mpEditor = new CRMLEditor(this);
        CRMLHighlighter *pCRMLHighlighter;
        pCRMLHighlighter = new CRMLHighlighter(OptionsDialog::instance()->getCRMLEditorPage(), mpEditor->getPlainTextEdit());
        CRMLEditor *pCRMLEditor = dynamic_cast<CRMLEditor*>(mpEditor);
        pCRMLEditor->setPlainText(mpLibraryTreeItem->getClassText(pMainWindow->getLibraryWidget()->getLibraryTreeModel()));
        mpEditor->hide();
        connect(OptionsDialog::instance(), SIGNAL(crmlEditorSettingsChanged()), pCRMLHighlighter, SLOT(settingsChanged()));
      } else if (mpLibraryTreeItem->isMOSFile()) {
        mpEditor = new MOSEditor(this);
        MOSHighlighter *pMOSHighlighter;
        pMOSHighlighter = new MOSHighlighter(OptionsDialog::instance()->getMOSEditorPage(), mpEditor->getPlainTextEdit());
        MOSEditor *pMOSEditor = dynamic_cast<MOSEditor*>(mpEditor);
        pMOSEditor->setPlainText(mpLibraryTreeItem->getClassText(pMainWindow->getLibraryWidget()->getLibraryTreeModel()));
        mpEditor->hide();
        connect(OptionsDialog::instance(), SIGNAL(mosEditorSettingsChanged()), pMOSHighlighter, SLOT(settingsChanged()));
      } else if (Utilities::isModelicaFile(fileInfo.suffix())) {
        mpEditor = new MetaModelicaEditor(this);
        MetaModelicaHighlighter *pMetaModelicaHighlighter;
        pMetaModelicaHighlighter = new MetaModelicaHighlighter(OptionsDialog::instance()->getMetaModelicaEditorPage(), mpEditor->getPlainTextEdit());
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
      mpMainLayout->addWidget(mpModelStatusBar);
    } else if (mpLibraryTreeItem->isSSP()) {
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
        OMSimulatorEditor *pOMSimulatorEditor = dynamic_cast<OMSimulatorEditor*>(mpEditor);
        pOMSimulatorEditor->setPlainText(mpLibraryTreeItem->getClassText(pMainWindow->getLibraryWidget()->getLibraryTreeModel()), false);
        OMSimulatorHighlighter *pOMSimulatorHighlighter = new OMSimulatorHighlighter(OptionsDialog::instance()->getOMSimulatorEditorPage(), mpEditor->getPlainTextEdit());
        mpEditor->hide(); // set it hidden so that Find/Replace action can get correct value.
        connect(OptionsDialog::instance(), SIGNAL(omsimulatorEditorSettingsChanged()), pOMSimulatorHighlighter, SLOT(settingsChanged()));
      }
      drawOMSModelDiagramElements();
      drawOMSModelConnections();
      mpDiagramGraphicsScene->clearSelection();
      mpModelStatusBar->addPermanentWidget(mpReadOnlyLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpViewTypeLabel, 0);
      mpModelStatusBar->addPermanentWidget(mpModelFilePathLabel, 1);
      mpModelStatusBar->addPermanentWidget(mpFileLockToolButton, 0);
      // set layout
      mpMainLayout->addWidget(mpModelStatusBar);
      if (MainWindow::instance()->isDebug() && mpUndoView) {
        mpMainLayout->addWidget(mpUndoView);
      }
      mpMainLayout->addWidget(mpDiagramGraphicsView, 1);
      if (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isComponentElement()) {
        mpMainLayout->addWidget(mpIconGraphicsView, 1);
      }
    }
    if (mpEditor) {
      connect(mpEditor->getPlainTextEdit()->document(), SIGNAL(undoAvailable(bool)), SLOT(handleCanUndoChanged(bool)));
      connect(mpEditor->getPlainTextEdit()->document(), SIGNAL(redoAvailable(bool)), SLOT(handleCanRedoChanged(bool)));
      mpMainLayout->addWidget(mpEditor, 1);
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
    pBitmapAnnotation->drawCornerItems();
    pBitmapAnnotation->setCornerItemsActiveOrPassive();
    pBitmapAnnotation->applyTransformation();
    mpIconGraphicsView->addShapeToList(pBitmapAnnotation);
    mpIconGraphicsView->addItem(pBitmapAnnotation);
    return pBitmapAnnotation;
  } else {
    // Rectangle shape as base
    RectangleAnnotation *pRectangleAnnotation = new RectangleAnnotation(mpIconGraphicsView);
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
    pRectangleAnnotation->applyTransformation();
    mpIconGraphicsView->addShapeToList(pRectangleAnnotation);
    mpIconGraphicsView->addItem(pRectangleAnnotation);
    // Text for name
    TextAnnotation *pTextAnnotation = new TextAnnotation(mpIconGraphicsView);
    if (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isFMUComponent()) {
      QVector<QPointF> extents;
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
    pTextAnnotation->applyTransformation();
    mpIconGraphicsView->addShapeToList(pTextAnnotation);
    mpIconGraphicsView->addItem(pTextAnnotation);
    // Text for further information
    if (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isFMUComponent()) {
      TextAnnotation *pInfoTextAnnotation = new TextAnnotation(mpIconGraphicsView);
      QVector<QPointF> extents;
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
      pInfoTextAnnotation->applyTransformation();
      mpIconGraphicsView->addShapeToList(pInfoTextAnnotation);
      mpIconGraphicsView->addItem(pInfoTextAnnotation);
    }
    return pRectangleAnnotation;
  }
}

/*!
 * \brief ModelWidget::addUpdateDeleteOMSSystemIcon
 * Adds, update or delete the OMSimulator element icon.
 * \param iconPath
 */
void ModelWidget::addUpdateDeleteOMSElementIcon(const QString &iconPath)
{
  // update element ssd_element_geometry_t
  if (mpLibraryTreeItem && mpLibraryTreeItem->getOMSElement() && mpLibraryTreeItem->getOMSElement()->geometry) {
    ssd_element_geometry_t elementGeometry = mpLibraryTreeItem->getOMSElementGeometry();
    QString fileURI = "file:///" + iconPath;
    QString commandText = "Add";
    if (elementGeometry.iconSource) {
      commandText = "Update";
      delete[] elementGeometry.iconSource;
    }
    if (iconPath.isEmpty()) {
      commandText = "Delete";
      elementGeometry.iconSource = NULL;
    } else {
      size_t size = fileURI.toStdString().size() + 1;
      elementGeometry.iconSource = new char[size];
      memcpy(elementGeometry.iconSource, fileURI.toStdString().c_str(), size*sizeof(char));
    }
    if (OMSProxy::instance()->setElementGeometry(mpLibraryTreeItem->getNameStructure(), &elementGeometry)) {
      createOMSimulatorUndoCommand(QString("%1 Icon %2").arg(commandText, iconPath));
      updateModelText();
    }
  }
}

/*!
 * \brief ModelWidget::getConnectorElement
 * Finds the Port Element within the Element.
 * \param pConnectorElement
 * \param connectorName
 * \return
 */
Element* ModelWidget::getConnectorElement(Element *pConnectorElement, QString connectorName)
{
  Element *pConnectorElementFound = 0;
  foreach (Element *pElement, pConnectorElement->getElementsList()) {
    if (pElement->getName().compare(connectorName) == 0) {
      pConnectorElementFound = pElement;
      return pConnectorElementFound;
    }
    foreach (Element *pInheritedElement, pElement->getInheritedElementsList()) {
      pConnectorElementFound = getConnectorElement(pInheritedElement, connectorName);
      if (pConnectorElementFound) {
        return pConnectorElementFound;
      }
    }
  }
  /* if port is not found in elements list then look into the inherited elements list. */
  foreach (Element *pInheritedElement, pConnectorElement->getInheritedElementsList()) {
    pConnectorElementFound = getConnectorElement(pInheritedElement, connectorName);
    if (pConnectorElementFound) {
      return pConnectorElementFound;
    }
  }
  return pConnectorElementFound;
}

/*!
 * \brief ModelWidget::clearGraphicsViews
 * Removes everything from GraphicsViews.
 */
void ModelWidget::clearGraphicsViews()
{
  /* remove everything from the icon view */
  if (mpIconGraphicsView) {
    mpIconGraphicsView->clearGraphicsView();
  }
  /* remove everything from the diagram view */
  if (mpDiagramGraphicsView) {
    mpDiagramGraphicsView->clearGraphicsView();
  }
}

/*!
 * \brief ModelWidget::clearGraphicsViewsExceptOutOfSceneItems
 * Removes everything from GrphicsViews except for out of scene items.
 */
void ModelWidget::clearGraphicsViewsExceptOutOfSceneItems()
{
  /* remove everything from the icon view */
  if (mpIconGraphicsView) {
    mpIconGraphicsView->clearGraphicsViewsExceptOutOfSceneItems();
  }
  /* remove everything from the diagram view */
  if (mpDiagramGraphicsView) {
    mpDiagramGraphicsView->clearGraphicsViewsExceptOutOfSceneItems();
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
  if (getLibraryTreeItem()->isSSP()) {
    MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->updateLibraryTreeItem(mpLibraryTreeItem);
    // get the submodels and connections
    drawOMSModelIconElements();
    drawOMSModelDiagramElements();
    drawOMSModelConnections();
  } else {
    // reset the CoordinateSystem
    if (mpIconGraphicsView) {
      mpIconGraphicsView->resetCoordinateSystem();
    }
    if (mpDiagramGraphicsView) {
      mpDiagramGraphicsView->resetCoordinateSystem();
    }
    if (mDiagramViewLoaded) {
      loadModelInstance(false, ModelInfo());
    } else {
      loadModelInstance(true, ModelInfo());
    }
    // invalidate the simulation options
    mpLibraryTreeItem->mSimulationOptions.setIsValid(false);
    mpLibraryTreeItem->mSimulationOptions.setDataReconciliationInitialized(false);
    // update the icon
    mpLibraryTreeItem->handleIconUpdated();
    // if documentation view is visible and this model is the current active model then update it
    ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
    if (pModelWidget && pModelWidget == this && MainWindow::instance()->getDocumentationDockWidget()->isVisible()) {
      MainWindow::instance()->getDocumentationWidget()->showDocumentation(getLibraryTreeItem());
    }
    // Update Element Browser
    if (pModelWidget && pModelWidget->getLibraryTreeItem()) {
      MainWindow::instance()->getElementWidget()->getElementTreeModel()->addElements(pModelWidget->getModelInstance());
      MainWindow::instance()->getElementWidget()->selectDeselectElementItem("", false);
    }
    // clear the undo stack
    mpUndoStack->clear();
//    if (mpEditor) {
//      mpEditor->getPlainTextEdit()->document()->clearUndoRedoStacks();
//    }
    updateViewButtonsBasedOnAccess();
  }
  QApplication::restoreOverrideCursor();
}

void ModelWidget::reDrawModelWidget(const ModelInfo &modelInfo)
{
  QApplication::setOverrideCursor(Qt::WaitCursor);
  // Remove all elements from the scene
  mpIconGraphicsView->removeElementsFromScene();
  mpDiagramGraphicsView->removeElementsFromScene();
  mpDiagramGraphicsView->removeConnectionsFromScene();
  mpDiagramGraphicsView->removeTransitionsFromScene();
  mpDiagramGraphicsView->removeInitialStatesFromScene();
  // We only remove the inherited stuff and redraw it. The class shapes, connections and elements are updated.
  mpIconGraphicsView->removeInheritedClassShapes();
  mpIconGraphicsView->removeInheritedClassConnections();
  mpIconGraphicsView->removeInheritedClassTransitions();
  mpIconGraphicsView->removeInheritedClassInitialStates();
  mpIconGraphicsView->removeInheritedClassElements();
  mpDiagramGraphicsView->removeInheritedClassShapes();
  mpDiagramGraphicsView->removeInheritedClassConnections();
  mpDiagramGraphicsView->removeInheritedClassTransitions();
  mpDiagramGraphicsView->removeInheritedClassInitialStates();
  mpDiagramGraphicsView->removeInheritedClassElements();
  /* get model components, connection and shapes. */
  // Draw icon view
  // reset the CoordinateSystem
  if (mpIconGraphicsView) {
    mpIconGraphicsView->resetCoordinateSystem();
  }
  if (mpDiagramGraphicsView) {
    mpDiagramGraphicsView->resetCoordinateSystem();
  }
  loadModelInstance(false, modelInfo);
  // update the icon
  mpLibraryTreeItem->handleIconUpdated();
  updateViewButtonsBasedOnAccess();
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
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, errorString, Helper::syntaxKind,
                                                            Helper::errorLevel));
    }
    return false;
  }
  /* if no errors are found with the Modelica Text then load it in OMC */
  QString className = classNames.at(0);
  if (pParentLibraryTreeItem != mpLibraryTreeItem) {
    // only use OMCProxy::loadString merge when LibraryTreeItem::SaveFolderStructure i.e., package.mo
    if (!pOMCProxy->loadString(stringToLoad, pParentLibraryTreeItem->getFileName(), Helper::utf8, pParentLibraryTreeItem->isSaveFolderStructure())) {
      return false;
    }
  } else {
    // only use OMCProxy::loadString merge when LibraryTreeItem::SaveFolderStructure i.e., package.mo
    if (!pOMCProxy->loadString(stringToLoad, mpLibraryTreeItem->getFileName(), Helper::utf8, mpLibraryTreeItem->isSaveFolderStructure())) {
      return false;
    }
  }
  /* if user has changed the class contents then refresh it. */
  if (className.compare(mpLibraryTreeItem->getNameStructure()) == 0) {
    mpLibraryTreeItem->updateClassInformation();
    reDrawModelWidget();
    mpLibraryTreeItem->setClassText(modelicaText);
    if (mpLibraryTreeItem->isInPackageOneFile()) {
      pParentLibraryTreeItem->setClassText(stringToLoad);
      updateModelText();
    } else {
      MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->emitModelStateChanged(mpLibraryTreeItem->getNameStructure());
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
    MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->emitModelStateChanged(mpLibraryTreeItem->getNameStructure());
    disconnect(MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel(), SIGNAL(modelStateChanged(QString)), this, SLOT(updateModelIfDependsOn(QString)));
    mpLibraryTreeItem->setModelWidget(0);
    QString name = StringHandler::getLastWordAfterDot(className);
    LibraryTreeItem *pNewLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(name, mpLibraryTreeItem->parent(), false, false, true, row);
    setWindowTitle(pNewLibraryTreeItem->getName() + (pNewLibraryTreeItem->isSaved() ? "" : "*"));
    setModelClassPathLabel(pNewLibraryTreeItem->getNameStructure());
    pNewLibraryTreeItem->setSaveContentsType(mpLibraryTreeItem->getSaveContentsType());
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
    mpLibraryTreeItem->deleteLater();
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
      pLibraryTreeModel->removeLibraryTreeItem(pChildLibraryTreeItem);
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
        pChildLibraryTreeItem->updateClassInformation();
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
  QString newCref;
  if (mpLibraryTreeItem->isTopLevel()) {
    if (OMSProxy::instance()->importSnapshot(mpLibraryTreeItem->getNameStructure(), mpEditor->getPlainTextEdit()->toPlainText(), &newCref)) {
      createOMSimulatorUndoCommand("Text edited", true, false, mpLibraryTreeItem->getNameStructure(), newCref);
      return true;
    }
  } else {
    LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
    LibraryTreeItem *pModelLibraryTreeItem = pLibraryTreeModel->getTopLevelLibraryTreeItem(mpLibraryTreeItem);
    if (pModelLibraryTreeItem && OMSProxy::instance()->importSnapshot(pModelLibraryTreeItem->getNameStructure(), mpEditor->getPlainTextEdit()->toPlainText(), &newCref)) {
      QString newEditedCref = QString("%1.%2").arg(mpLibraryTreeItem->parent()->getNameStructure(), newCref);
      createOMSimulatorUndoCommand("Text edited", true, false, mpLibraryTreeItem->getNameStructure(), newEditedCref);
      return true;
    }
  }
  return false;
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
  if (mpLibraryTreeItem->isModelica()) {
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
  if (mpLibraryTreeItem->isSSP()) {
    LibraryTreeItem *pModelLibraryTreeItem = pLibraryTreeModel->getTopLevelLibraryTreeItem(mpLibraryTreeItem);
    if (pModelLibraryTreeItem->getModelWidget()) {
      pModelLibraryTreeItem->getModelWidget()->setWindowTitle(QString("%1*").arg(pModelLibraryTreeItem->getName()));
      if (pModelLibraryTreeItem->getModelWidget()->isLoadedWidgetComponents()) {
        pModelLibraryTreeItem->getModelWidget()->setModelFilePathLabel(pModelLibraryTreeItem->getFileName());
      }
    }
    if (pModelLibraryTreeItem != mpLibraryTreeItem) {
      setWindowTitle(QString("%1*").arg(mpLibraryTreeItem->getName()));
      setModelFilePathLabel(mpLibraryTreeItem->getFileName());
    }
  } else {
    setWindowTitle(QString("%1*").arg(mpLibraryTreeItem->getName()));
    mUpdateModelTimer.start();
    callHandleCollidingConnectionsIfNeeded();
    // announce the change.
    MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->emitModelStateChanged(mpLibraryTreeItem->getNameStructure());
    // Update Element Browser
    MainWindow::instance()->getElementWidget()->getElementTreeModel()->addElements(mpModelInstance);
    MainWindow::instance()->getElementWidget()->selectDeselectElementItem("", false);
  }
}

/*!
 * \brief ModelWidget::callHandleCollidingConnectionsIfNeeded
 * Calls GraphicsView::handleCollidingConnections if needed.
 */
void ModelWidget::callHandleCollidingConnectionsIfNeeded()
{
  if (mpLibraryTreeItem->isModelica() && mpDiagramGraphicsView && isHandleCollidingConnectionsNeeded()) {
    mpDiagramGraphicsView->handleCollidingConnections();
    setHandleCollidingConnectionsNeeded(false);
  }
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
  if (mpLibraryTreeItem->isSSP()) {
    createOMSimulatorUndoCommand("");
  }
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
 * \brief ModelWidget::associateBusWithConnectors
 * Associates the bus component with each of its connector component.
 * \param busName
 */
void ModelWidget::associateBusWithConnectors(QString busName)
{
  // get the bus component
  Element *pIconBusComponent = mpIconGraphicsView->getElementObject(busName);
  associateBusWithConnectors(pIconBusComponent, mpIconGraphicsView);
  Element *pDiagramBusComponent = mpDiagramGraphicsView->getElementObject(busName);
  associateBusWithConnectors(pDiagramBusComponent, mpDiagramGraphicsView);
}

const QString modelicaBlocksInterfacesRealInput = "Modelica.Blocks.Interfaces.RealInput";
const QString modelicaBlocksInterfacesRealOutput = "Modelica.Blocks.Interfaces.RealOutput";

void walkMe(ModelInstance::Model *model, QStringList &inputVariables, QStringList &outputVariables, QStringList &parameters, QStringList &auxVariables)
{
  if (model == NULL) return;

  for (ModelInstance::Element *element : model->getElements())
    if (element->isComponent()) {
      QString causality = element->getDirectionPrefix();
      QString variability = element->getVariability();
      const bool classNameIsReal = element->getType().compare(QStringLiteral("Real")) == 0;
      QString ty = element->getType();
      QString qn = element->getQualifiedName();
      // printf("C: %s %s %s %s\n", causality.toUtf8().constData(), variability.toUtf8().constData(), ty.toUtf8().constData(), qn.toUtf8().constData());
      if (causality.compare(QStringLiteral("input")) == 0) {
        if (classNameIsReal || ty.compare(modelicaBlocksInterfacesRealInput) == 0) {
          inputVariables.append(qn);
        }
      } else if (causality.compare(QStringLiteral("output")) == 0) {
        if (classNameIsReal || ty.compare(modelicaBlocksInterfacesRealOutput) == 0) {
          outputVariables.append(qn);
        }
      } else if(classNameIsReal && variability.compare(QStringLiteral("parameter")) == 0) {
        parameters.append(element->getQualifiedName());
      } else if (classNameIsReal) { /* Otherwise we are dealing with an auxiliarly variable */
        auxVariables.append(qn);
      }
      walkMe(element->getModel(), inputVariables, outputVariables, parameters, auxVariables);
    } else if (element->isExtend()) {
      walkMe(element->getModel(), inputVariables, outputVariables, parameters, auxVariables);
    }
}

/*!
 * \brief ModelWidget::toOMSensData
 * Creates a list of QVariant containing the model information needed by OMSens.
 * Currently only works for REAL types (OMSens currently have similar limitations)
 * \return
 */
QList<QVariant> ModelWidget::toOMSensData()
{
  QList<QVariant> omSensData;
  if (!mpDiagramGraphicsView) {
    return omSensData;
  }

  QStringList inputVariables;
  QStringList outputVariables;
  QStringList parameters;
  QStringList auxVariables;

  walkMe(getModelInstance(), inputVariables, outputVariables, parameters, auxVariables);
  omSensData << inputVariables << outputVariables << auxVariables << parameters << mpLibraryTreeItem->getFileName() << mpLibraryTreeItem->getNameStructure();
  return omSensData;
}

/*!
 * \brief ModelWidget::createOMSimulatorUndoCommand
 * Creates OMSimulatorUndoCommand and pushes it to the undo stack.
 * \param commandText
 * \param doSnapShot
 * \param switchToEdited
 */
void ModelWidget::createOMSimulatorUndoCommand(const QString &commandText, const bool doSnapShot, const bool switchToEdited, const QString oldEditedCref, const QString newEditedCref)
{
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pModelLibraryTreeItem = pLibraryTreeModel->getTopLevelLibraryTreeItem(mpLibraryTreeItem);
  if (!pModelLibraryTreeItem->getModelWidget()) {
    pLibraryTreeModel->showModelWidget(pModelLibraryTreeItem, false);
  }
  QString oldSnapshot = pModelLibraryTreeItem->getClassText(pLibraryTreeModel);
  QString newSnapshot;
  OMSProxy::instance()->exportSnapshot(pModelLibraryTreeItem->getNameStructure(), &newSnapshot);
  mpUndoStack->push(new OMSimulatorUndoCommand(pModelLibraryTreeItem->getNameStructure(), oldSnapshot, newSnapshot, mpLibraryTreeItem->getNameStructure(),
                                               doSnapShot, switchToEdited, oldEditedCref, newEditedCref, "OMSimulator " + commandText));
}

/*!
 * \brief ModelWidget::createOMSimulatorRenameModelUndoCommand
 * Creates OMSimulatorUndoCommand and pushes it to the undo stack.
 * Used only for renaming of models.
 * \param commandText
 * \param cref
 * \param newCref
 */
void ModelWidget::createOMSimulatorRenameModelUndoCommand(const QString &commandText, const QString &cref, const QString &newCref)
{
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pModelLibraryTreeItem = pLibraryTreeModel->getTopLevelLibraryTreeItem(mpLibraryTreeItem);
  if (!pModelLibraryTreeItem->getModelWidget()) {
    pLibraryTreeModel->showModelWidget(pModelLibraryTreeItem, false);
  }
  QString oldSnapshot = pModelLibraryTreeItem->getClassText(pLibraryTreeModel);
  if (OMSProxy::instance()->rename(cref, newCref)) {
    pModelLibraryTreeItem->setName(newCref);
    pModelLibraryTreeItem->setNameStructure(newCref);
    QString newSnapshot;
    OMSProxy::instance()->exportSnapshot(newCref, &newSnapshot);
    mpUndoStack->push(new OMSimulatorUndoCommand(newCref, oldSnapshot, newSnapshot, mpLibraryTreeItem->getNameStructure(), true, true, "", "", "OMSimulator " + commandText));
  }
}

/*!
 * \brief ModelWidget::processPendingModelUpdate
 * Updates the model immediately if the update model timer is running.
 * Useful in cases like save and when switching to text view.
 */
void ModelWidget::processPendingModelUpdate()
{
  if (mUpdateModelTimer.isActive()) {
    mUpdateModelTimer.stop();
    updateModel();
  }
}

/*!
 * \brief ModelWidget::updateModelIfDependsOn
 * Updates the model if it depends on modelName.\n
 * Slot activated when modelStateChanged SIGNAL of LibraryTreeModel is raised.
 * \param modelName
 */
void ModelWidget::updateModelIfDependsOn(const QString &modelName)
{
  if (mDiagramViewLoaded && dependsOnModel(modelName)) {
    // if this is the current ModelWidget then update it directly otherwise mark it for update
    if (this == mpModelWidgetContainer->getCurrentModelWidget()) {
      setRequiresUpdate(false);
      reDrawModelWidget(createModelInfo());
    } else {
      setRequiresUpdate(true);
    }
  }
}

/*!
 * \brief ModelWidget::createModelInfo
 * Creates the ModelInfo object.
 * \return
 */
ModelInfo ModelWidget::createModelInfo() const
{
  ModelInfo modelInfo;
  modelInfo.mName = mpLibraryTreeItem->getNameStructure();
  if (mpIconGraphicsView) {
    modelInfo.mIconElementsList = mpIconGraphicsView->getElementsList();
  }
  if (mpDiagramGraphicsView) {
    modelInfo.mDiagramElementsList = mpDiagramGraphicsView->getElementsList();
    modelInfo.mConnectionsList = mpDiagramGraphicsView->getConnectionsList();
    modelInfo.mTransitionsList = mpDiagramGraphicsView->getTransitionsList();
    modelInfo.mInitialStatesList = mpDiagramGraphicsView->getInitialStatesList();
  }

  return modelInfo;
}

/*!
 * \brief ModelWidget::showElement
 * Opens the element represented by passed ModelInstance in editing mode.
 * \param pModelInstance
 * \param addToList
 */
void ModelWidget::showElement(ModelInstance::Model *pModelInstance, bool addToList)
{
  QApplication::setOverrideCursor(Qt::WaitCursor);
  if (mModelInstancesPos < 0) {
    mpRootModelInstance = mpModelInstance;
    mPreservedIconShapesList = mpIconGraphicsView->getShapesList();
    mPreservedDiagramShapesList = mpDiagramGraphicsView->getShapesList();
    mModelInfo = createModelInfo();
  }

  // Remove all elements from the scene
  mpIconGraphicsView->removeShapesFromScene();
  mpIconGraphicsView->removeElementsFromScene();
  mpDiagramGraphicsView->removeShapesFromScene();
  mpDiagramGraphicsView->removeElementsFromScene();
  mpDiagramGraphicsView->removeConnectionsFromScene();
  mpDiagramGraphicsView->removeTransitionsFromScene();
  mpDiagramGraphicsView->removeInitialStatesFromScene();
  // We only remove the inherited stuff and redraw it. The class shapes, connections and elements are updated.
  mpIconGraphicsView->removeInheritedClassShapes();
  mpIconGraphicsView->removeInheritedClassElements();
  mpIconGraphicsView->removeInheritedClassConnections();
  mpIconGraphicsView->removeInheritedClassTransitions();
  mpIconGraphicsView->removeInheritedClassInitialStates();
  mpDiagramGraphicsView->removeInheritedClassShapes();
  mpDiagramGraphicsView->removeInheritedClassConnections();
  mpDiagramGraphicsView->removeInheritedClassTransitions();
  mpDiagramGraphicsView->removeInheritedClassInitialStates();
  mpDiagramGraphicsView->removeInheritedClassElements();
  // reset the CoordinateSystem
  mpIconGraphicsView->resetCoordinateSystem();
  mpDiagramGraphicsView->resetCoordinateSystem();

  if (addToList) {
    while (mModelInstanceList.count() > (mModelInstancesPos+1)) {
      mModelInstanceList.removeLast();
    }
    mModelInstanceList.append(pModelInstance);
    mModelInstancesPos++;
  }
  mpModelInstance = pModelInstance;
  mpElementModeLabel->setText(tr("Showing element <b>%1</b> in <b>%2</b>").arg(mpModelInstance->getParentElement()->getQualifiedName(), mpRootModelInstance->getName()));
  drawModel(ModelInfo());
  updateElementModeButtons();
  // update the coordinate system according to new values
  mpIconGraphicsView->resetZoom();
  mpDiagramGraphicsView->resetZoom();
  QApplication::restoreOverrideCursor();
}

/*!
 * \brief ModelWidget::selectDeselectElement
 * Select/Deselect the element in the GraphicsView.
 * \param name
 * \param selected
 */
void ModelWidget::selectDeselectElement(const QString &name, bool selected)
{
  if (mpDiagramGraphicsView) {
    Element *pDiagramElement = mpDiagramGraphicsView->getElementObjectFromQualifiedName(name);
    if (pDiagramElement) {
      pDiagramElement->setIgnoreSelection(true);
      pDiagramElement->setSelected(selected);
      pDiagramElement->setIgnoreSelection(false);
      if (mpIconGraphicsView && pDiagramElement->getModel() && pDiagramElement->getModel()->isConnector()) {
        Element *pIconElement = mpIconGraphicsView->getElementObjectFromQualifiedName(name);
        pIconElement->setIgnoreSelection(true);
        pIconElement->setSelected(selected);
        pIconElement->setIgnoreSelection(false);
      }
    }
  }
}

/*!
 * \brief ModelWidget::navigateToClass
 * Lookup the class and open it.
 * \param className
 */
void ModelWidget::navigateToClass(const QString &className)
{
  LibraryWidget *pLibraryWidget = MainWindow::instance()->getLibraryWidget();
  LibraryTreeItem *pLibraryTreeItem = nullptr;
  // first see if we find any relative class
  const QString parentClassName = StringHandler::removeLastWordAfterDot(mpLibraryTreeItem->getNameStructure());
  pLibraryTreeItem = pLibraryWidget->getLibraryTreeModel()->findLibraryTreeItem(parentClassName % "." % className);
  if (pLibraryTreeItem) {
    pLibraryWidget->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
  } else {
    // relative class not found.
    bool classFound = false;
    if (mpModelInstance) {
      auto imports = mpModelInstance->getImports();
      foreach (auto import, imports) {
        if (className.compare(import.getShortName()) == 0) {
          pLibraryTreeItem = pLibraryWidget->getLibraryTreeModel()->findLibraryTreeItem(import.getPath());
        } else {
          const QString importPath = StringHandler::removeLastWordAfterDot(import.getPath());
          pLibraryTreeItem = pLibraryWidget->getLibraryTreeModel()->findLibraryTreeItem(importPath % "." % className);
        }
        // check if we found the class in imports
        if (pLibraryTreeItem) {
          classFound = true;
          break;
        }
      }
    }
    // if class is not found in imports then see if the class is fully qualified path.
    if (!classFound) {
      pLibraryTreeItem = pLibraryWidget->getLibraryTreeModel()->findLibraryTreeItem(className);
    }
    // if class is found then open it.
    if (pLibraryTreeItem) {
      pLibraryWidget->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
    }
  }
}

/*!
 * \brief ModelWidget::createUndoStack
 * Creates the undo stack.
 */
void ModelWidget::createUndoStack()
{
  /* Undo stack for model
   * For OMSimulator models only the top level model has the undo stack.
   * Nested systems and components use the same undo stack.
   */
  if (mpLibraryTreeItem && !mpLibraryTreeItem->isTopLevel() && mpLibraryTreeItem->isSSP()) {
    LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
    LibraryTreeItem *pModelLibraryTreeItem = pLibraryTreeModel->getTopLevelLibraryTreeItem(mpLibraryTreeItem);
    if (pModelLibraryTreeItem) {
      if (pModelLibraryTreeItem->getModelWidget()) {
        mpUndoStack = pModelLibraryTreeItem->getModelWidget()->getUndoStack();
      } else {
        pLibraryTreeModel->showModelWidget(pModelLibraryTreeItem, false);
        mpUndoStack = pModelLibraryTreeItem->getModelWidget()->getUndoStack();
      }
    } else {
      assert(mpUndoStack);
    }
  } else {
    mpUndoStack = new UndoStack(this);
    connect(mpUndoStack, SIGNAL(canUndoChanged(bool)), SLOT(handleCanUndoChanged(bool)));
    connect(mpUndoStack, SIGNAL(canRedoChanged(bool)), SLOT(handleCanRedoChanged(bool)));
  }
  if (MainWindow::instance()->isDebug()) {
    mpUndoView = new QUndoView(mpUndoStack);
  }
}

/*!
 * \brief ModelWidget::handleCanUndoRedoChanged
 * Enables/disables the Edit menu Undo/Redo action depending on the stack situation.
 */
void ModelWidget::handleCanUndoRedoChanged()
{
  if (mpLibraryTreeItem->isSSP()) {
    ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
    if (pModelWidget) {
      pModelWidget->updateUndoRedoActions();
    }
  } else {
    updateUndoRedoActions();
  }
}

/*!
 * \brief ModelWidget::drawOMSModelIconElements
 * Draws the OMSimulator elements for icon view.
 */
void ModelWidget::drawOMSModelIconElements()
{
  if (mpLibraryTreeItem->isTopLevel()) {
    return;
  } else if (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isComponentElement()) {
    drawOMSModelElement();
    // draw connectors
    for (int i = 0 ; i < mpLibraryTreeItem->childrenSize() ; i++) {
      LibraryTreeItem *pChildLibraryTreeItem = mpLibraryTreeItem->childAt(i);
      if ((pChildLibraryTreeItem->getOMSConnector()
          && (pChildLibraryTreeItem->getOMSConnector()->causality == oms_causality_input
              || pChildLibraryTreeItem->getOMSConnector()->causality == oms_causality_output))
          || (pChildLibraryTreeItem->getOMSBusConnector())
          || (pChildLibraryTreeItem->getOMSTLMBusConnector())) {
        double x = 0.5;
        double y = 0.5;
        if (pChildLibraryTreeItem->getOMSConnector() && pChildLibraryTreeItem->getOMSConnector()->geometry) {
          x = pChildLibraryTreeItem->getOMSConnector()->geometry->x;
          y = pChildLibraryTreeItem->getOMSConnector()->geometry->y;
        } else if (pChildLibraryTreeItem->getOMSBusConnector() && pChildLibraryTreeItem->getOMSBusConnector()->geometry) {
          x = pChildLibraryTreeItem->getOMSBusConnector()->geometry->x;
          y = pChildLibraryTreeItem->getOMSBusConnector()->geometry->y;
        } else if (pChildLibraryTreeItem->getOMSTLMBusConnector() && pChildLibraryTreeItem->getOMSTLMBusConnector()->geometry) {
          x = pChildLibraryTreeItem->getOMSTLMBusConnector()->geometry->x;
          y = pChildLibraryTreeItem->getOMSTLMBusConnector()->geometry->y;
        }
        QString annotation = QString("Placement(true,%1,%2,-10.0,-10.0,10.0,10.0,0,%1,%2,-10.0,-10.0,10.0,10.0,)")
                             .arg(Utilities::mapToCoordinateSystem(x, 0, 1, -100, 100))
                             .arg(Utilities::mapToCoordinateSystem(y, 0, 1, -100, 100));
        drawOMSElement(pChildLibraryTreeItem, annotation);
        // assoicated the bus component with each of its connector component
        if ((pChildLibraryTreeItem->getOMSBusConnector()) || (pChildLibraryTreeItem->getOMSTLMBusConnector())) {
          associateBusWithConnectors(pChildLibraryTreeItem->getName());
        }
      }
    }
  }
}

/*!
 * \brief ModelWidget::drawOMSModelDiagramElements
 * Draws the OMSimulator elements for diagram view.
 */
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
        // check zero width
        if (qFuzzyCompare(width, 0.0)) {
          x1 = -10.0;
          x2 = 10.0;
        }
        // check zero height
        if (qFuzzyCompare(height, 0.0)) {
          y1 = -10.0;
          y2 = 10.0;
        }
        // origin
        double origX = (x1 + x2) / 2;
        double origY = (y1 + y2) / 2;
        // horizontal position
        x1 = x1 - origX;
        x2 = x2 - origX;
        // vertical position
        y1 = y1 - origY;
        y2 = y2 - origY;
        // Load the ModelWidget if not loaded already
        if (!pChildLibraryTreeItem->getModelWidget()) {
          MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pChildLibraryTreeItem, false);
        }

        QString annotation = QString("Placement(true,%1,%2,%3,%4,%5,%6,%7,-,-,-,-,-,-,)")
                             .arg(origX).arg(origY)
                             .arg(x1).arg(y1)
                             .arg(x2).arg(y2)
                             .arg(pChildLibraryTreeItem->getOMSElement()->geometry->rotation);

        if (pChildLibraryTreeItem->isSystemElement() || pChildLibraryTreeItem->isComponentElement()) {
          drawOMSElement(pChildLibraryTreeItem, annotation);
        }
      }
    }
  }
}

/*!
 * \brief ModelWidget::drawOMSElement
 * Draws the OMSimulator element.
 * \param pLibraryTreeItem
 * \param annotation
 */
void ModelWidget::drawOMSElement(LibraryTreeItem *pLibraryTreeItem, const QString &annotation)
{
  // add the connector element to icon view
  if ((pLibraryTreeItem->getOMSConnector()
      && (pLibraryTreeItem->getOMSConnector()->causality == oms_causality_input
          || pLibraryTreeItem->getOMSConnector()->causality == oms_causality_output))
      || (pLibraryTreeItem->getOMSBusConnector())
      || (pLibraryTreeItem->getOMSTLMBusConnector())) {
    Element *pIconComponent = new Element(pLibraryTreeItem->getName(), pLibraryTreeItem, annotation, QPointF(0, 0), mpIconGraphicsView);
    mpIconGraphicsView->addElementItem(pIconComponent);
    mpIconGraphicsView->addElementToList(pIconComponent);
  }
  // add the element to diagram view
  Element *pDiagramComponent = new Element(pLibraryTreeItem->getName(), pLibraryTreeItem, annotation, QPointF(0, 0), mpDiagramGraphicsView);
  mpDiagramGraphicsView->addElementItem(pDiagramComponent);
  mpDiagramGraphicsView->addElementToList(pDiagramComponent);
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
        Element *pStartComponent = mpDiagramGraphicsView->getElementObject(startConnectionList.at(0));
        if (!pStartComponent) {
          pMessagesWidget->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION)
                                                     .arg(startConnectionList.at(0), pConnections[i]->conA), Helper::scriptingKind, Helper::errorLevel));
          continue;
        }
        Element *pStartConnectorComponent = 0;
        if (startConnectionList.size() > 1) {
          // get start connector component
          QString startConnectorName = StringHandler::removeFirstWordAfterDot(QString(pConnections[i]->conA));
          pStartConnectorComponent = getConnectorElement(pStartComponent, startConnectorName);
          if (!pStartConnectorComponent) {
            pMessagesWidget->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION)
                                                       .arg(startConnectorName, pConnections[i]->conA), Helper::scriptingKind, Helper::errorLevel));
            continue;
          }
        } else {
          pStartConnectorComponent = pStartComponent;
        }

        // get end component
        QStringList endConnectionList = StringHandler::makeVariableParts(QString(pConnections[i]->conB));
        if (endConnectionList.size() < 1) {
          continue;
        }
        Element *pEndComponent = mpDiagramGraphicsView->getElementObject(endConnectionList.at(0));
        if (!pEndComponent) {
          pMessagesWidget->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION)
                                                     .arg(endConnectionList.at(0), pConnections[i]->conB), Helper::scriptingKind, Helper::errorLevel));
          continue;
        }
        Element *pEndConnectorComponent = 0;
        if (endConnectionList.size() > 1) {
          // get end connector component
          QString endConnectorName = StringHandler::removeFirstWordAfterDot(QString(pConnections[i]->conB));
          pEndConnectorComponent = getConnectorElement(pEndComponent, endConnectorName);
          if (!pEndConnectorComponent) {
            pMessagesWidget->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::UNABLE_FIND_COMPONENT_IN_CONNECTION)
                                                       .arg(endConnectorName, pConnections[i]->conB), Helper::scriptingKind, Helper::errorLevel));
            continue;
          }
        } else {
          pEndConnectorComponent = pEndComponent;
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
        QPointF startPoint = mpDiagramGraphicsView->roundPoint(pStartConnectorComponent->mapToScene(pStartConnectorComponent->boundingRect().center()));
        points.prepend(point.arg(startPoint.x()).arg(startPoint.y()));
        QPointF endPoint = mpDiagramGraphicsView->roundPoint(pEndConnectorComponent->mapToScene(pEndConnectorComponent->boundingRect().center()));
        points.append(point.arg(endPoint.x()).arg(endPoint.y()));
        QString pointsString = QString("{%1}").arg(points.join(","));
        shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(QString(annotation).arg(pointsString)));
        // Now parse the shapes available in list
        QString lineShape = "";
        foreach (QString shape, shapesList) {
          if (shape.startsWith("Line")) {
            lineShape = shape.mid(QString("Line").length());
            lineShape = StringHandler::removeFirstLastParentheses(lineShape);
            break;  // break the loop once we have got the line annotation.
          }
        }

        LineAnnotation *pConnectionLineAnnotation = new LineAnnotation(lineShape, pStartConnectorComponent, pEndConnectorComponent, mpDiagramGraphicsView);
        pConnectionLineAnnotation->setStartElementName(pStartConnectorComponent->getLibraryTreeItem() ? pStartConnectorComponent->getLibraryTreeItem()->getNameStructure() : "");
        pConnectionLineAnnotation->setEndElementName(pEndConnectorComponent->getLibraryTreeItem() ? pEndConnectorComponent->getLibraryTreeItem()->getNameStructure() : "");
        pConnectionLineAnnotation->setOMSConnectionType(pConnections[i]->type);
        pConnectionLineAnnotation->drawCornerItems();
        pConnectionLineAnnotation->setCornerItemsActiveOrPassive();
        mpDiagramGraphicsView->addConnectionToView(pConnectionLineAnnotation, false);
        // Check if the connectors of the connection belongs to a bus
        if (pStartConnectorComponent->isInBus() && pEndConnectorComponent->isInBus()) {
          pConnectionLineAnnotation->setVisible(false);
        }
        // Check if bus connection
        if (pConnections[i]->type == oms_connection_bus || pConnections[i]->type == oms_connection_tlm) {
          pConnectionLineAnnotation->setLineThickness(0.5);
          if (pConnections[i]->type == oms_connection_tlm) {
            pConnectionLineAnnotation->setDelay(QString::number(pConnections[i]->tlmparameters->delay));
            pConnectionLineAnnotation->setAlpha(QString::number(pConnections[i]->tlmparameters->alpha));
            pConnectionLineAnnotation->setZf(QString::number(pConnections[i]->tlmparameters->linearimpedance));
            pConnectionLineAnnotation->setZfr(QString::number(pConnections[i]->tlmparameters->angularimpedance));
          }
        }
      }
    }
  }
}

/*!
 * \brief ModelWidget::associateBusWithConnectors
 * Helper function for ModelWidget::associateBusWithConnectors(busName)
 * \param pBusComponent
 * \param pGraphicsView
 */
void ModelWidget::associateBusWithConnectors(Element *pBusComponent, GraphicsView *pGraphicsView)
{
  if (pBusComponent && pBusComponent->getLibraryTreeItem() && pBusComponent->getLibraryTreeItem()->getOMSBusConnector()) {
    oms_busconnector_t *pBusConnector = pBusComponent->getLibraryTreeItem()->getOMSBusConnector();
    if (pBusConnector->connectors) {
      for (int i = 0 ; pBusConnector->connectors[i] ; i++) {
        Element *pConnectorComponent = pGraphicsView->getElementObject(QString(pBusConnector->connectors[i]));
        if (pConnectorComponent) {
          pConnectorComponent->setBusComponent(pBusComponent);
        }
      }
    }
  } else if (pBusComponent && pBusComponent->getLibraryTreeItem() && pBusComponent->getLibraryTreeItem()->getOMSTLMBusConnector()) {
    oms_tlmbusconnector_t *pTLMBusConnector = pBusComponent->getLibraryTreeItem()->getOMSTLMBusConnector();
    if (pTLMBusConnector->connectornames) {
      for (int i = 0 ; pTLMBusConnector->connectornames[i] ; i++) {
        Element *pConnectorComponent = pGraphicsView->getElementObject(QString(pTLMBusConnector->connectornames[i]));
        if (pConnectorComponent) {
          pConnectorComponent->setBusComponent(pBusComponent);
        }
      }
    }
  }
}

/*!
 * \brief ModelWidget::dependsOnModel
 * Checks if modelName exists in dependsOnModel list
 * \param modelName
 * \return
 */
bool ModelWidget::dependsOnModel(const QString &modelName)
{
  foreach (QString model, mDependsOnModelsList) {
    if ((model.compare(modelName) == 0)) {
      return true;
    }
  }
  return false;
}

/*!
 * \brief ModelWidget::updateElementModeButtons
 * Enables/disables the back, forward and exit buttons.
 */
void ModelWidget::updateElementModeButtons()
{
  // back button
  if (mModelInstancesPos > 0) {
    mpBackToolButton->setDisabled(false);
  } else {
    mpBackToolButton->setDisabled(true);
  }
  // forward button
  if (mModelInstanceList.count() == (mModelInstancesPos + 1)) {
    mpForwardToolButton->setDisabled(true);
  } else {
    mpForwardToolButton->setDisabled(false);
  }
  // exit button
  if (mModelInstancesPos > -1) {
    mpExitToolButton->setDisabled(false);
  } else {
    mpExitToolButton->setDisabled(true);
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
    pSubWindow->setWindowIcon(ResourceCache::getIcon(":/Resources/icons/model.svg"));
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
    pSubWindow->setWindowIcon(ResourceCache::getIcon(":/Resources/icons/modeling.png"));
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
  processPendingModelUpdate();
  if (QMdiSubWindow *pSubWindow = mpModelWidgetContainer->getCurrentMdiSubWindow()) {
    pSubWindow->setWindowIcon(ResourceCache::getIcon(":/Resources/icons/modeltext.svg"));
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
 * \brief ModelWidget::backElement
 * Slot activated when mpBackToolButton clicked SIGNAL is raised.
 * Moves back in element mode.
 */
void ModelWidget::backElement()
{
  if (mModelInstancesPos > 0) {
    mModelInstancesPos--;
    showElement(mModelInstanceList.at(mModelInstancesPos), false);
  }
  updateElementModeButtons();
}

/*!
 * \brief ModelWidget::forwardElement
 * Slot activated when mpForwardToolButton clicked SIGNAL is raised.
 * Moves forward in element mode.
 */
void ModelWidget::forwardElement()
{
  if ((mModelInstancesPos + 1) < mModelInstanceList.count()) {
    mModelInstancesPos++;
    showElement(mModelInstanceList.at(mModelInstancesPos), false);
  }
  updateElementModeButtons();
}

/*!
 * \brief ModelWidget::exitElement
 * Slot activated when mpExitToolButton clicked SIGNAL is raised.
 * Exits the element mode.
 */
void ModelWidget::exitElement()
{
  /* Clear GraphicsViews except out of scene items
   * The out of scene items are the original model elements that will be restored.
   */
  clearGraphicsViewsExceptOutOfSceneItems();
  // call clearGraphicsViewsExceptOutOfSceneItems before resetting the model instances list so the icon update signal can be ignored.
  mModelInstanceList.clear();
  mModelInstancesPos = -1;
  mpElementModeLabel->setText("");
  // reset the CoordinateSystem
  mpIconGraphicsView->resetCoordinateSystem();
  mpDiagramGraphicsView->resetCoordinateSystem();
  mpModelInstance = mpRootModelInstance;
  mpIconGraphicsView->setShapesList(mPreservedIconShapesList);
  mPreservedIconShapesList.clear();
  mpDiagramGraphicsView->setShapesList(mPreservedDiagramShapesList);
  mPreservedDiagramShapesList.clear();
  if (isComponentModified()) {
    /* We use the same model info as it doesn't matter in case of element mode.
     * The element mode only allows changing the parameters.
     */
    mpUndoStack->push(new OMCUndoCommand(mpLibraryTreeItem, mModelInfo, mModelInfo, QString("Model modified in element mode")));
    updateModelText();
  } else {
    setRestoringModel(true);
    drawModel(mModelInfo);
    setRestoringModel(false);
  }
  setComponentModified(false);
  updateElementModeButtons();
  // update the coordinate system according to new values
  mpIconGraphicsView->resetZoom();
  mpDiagramGraphicsView->resetZoom();
}

/*!
 * \brief ModelWidget::updateModel
 * Slot activated when mUpdateModelTimer timeout SIGNAL is raised.
 */
void ModelWidget::updateModel()
{
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  pLibraryTreeModel->updateLibraryTreeItemClassText(mpLibraryTreeItem);
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
    mpFileLockToolButton->setIcon(ResourceCache::getIcon(":/Resources/icons/unlock.svg"));
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
 * \brief ModelWidget::handleCanUndoChanged
 * Enables/disables the Edit menu Undo action depending on the stack situation.
 * \param canUndo
 */
void ModelWidget::handleCanUndoChanged(bool canUndo)
{
  Q_UNUSED(canUndo);
  handleCanUndoRedoChanged();
}

/*!
 * \brief ModelWidget::handleCanRedoChanged
 * Enables/disables the Edit menu Redo action depending on the stack situation.
 * \param canRedo
 */
void ModelWidget::handleCanRedoChanged(bool canRedo)
{
  Q_UNUSED(canRedo);
  handleCanUndoRedoChanged();
}

void ModelWidget::closeEvent(QCloseEvent *event)
{
  Q_UNUSED(event);
  QMdiSubWindow *pMdiSubWindow = mpModelWidgetContainer->getMdiSubWindow(this);
  if (pMdiSubWindow) {
    mpModelWidgetContainer->removeSubWindow(this);
  }
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
  setTabsClosable(true);
  setTabsMovable(true);
  if (OptionsDialog::instance()->getGraphicalViewsPage()->getModelingViewMode().compare(Helper::subWindow) == 0) {
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
  mpLastActiveSubWindow = 0;
  // install QApplication event filter to handle the ctrl+tab and ctrl+shift+tab
  QApplication::instance()->installEventFilter(this);
  connect(this, SIGNAL(subWindowActivated(QMdiSubWindow*)), SLOT(currentModelWidgetChanged(QMdiSubWindow*)));
  connect(this, SIGNAL(subWindowActivated(QMdiSubWindow*)), MainWindow::instance(), SLOT(updateModelSwitcherMenu(QMdiSubWindow*)));
  // add actions
  connect(MainWindow::instance()->getSaveAction(), SIGNAL(triggered()), SLOT(saveModelWidget()));
  connect(MainWindow::instance()->getSaveAsAction(), SIGNAL(triggered()), SLOT(saveAsModelWidget()));
  connect(MainWindow::instance()->getSaveTotalAction(), SIGNAL(triggered()), SLOT(saveTotalModelWidget()));
  connect(MainWindow::instance()->getPrintModelAction(), SIGNAL(triggered()), SLOT(printModel()));
  connect(MainWindow::instance()->getFitToDiagramAction(), SIGNAL(triggered()), SLOT(fitToDiagram()));
  connect(MainWindow::instance()->getAddSystemAction(), SIGNAL(triggered()), SLOT(addSystem()));
  connect(MainWindow::instance()->getAddOrEditIconAction(), SIGNAL(triggered()), SLOT(addOrEditIcon()));
  connect(MainWindow::instance()->getDeleteIconAction(), SIGNAL(triggered()), SLOT(deleteIcon()));
  connect(MainWindow::instance()->getAddConnectorAction(), SIGNAL(triggered()), SLOT(addConnector()));
  connect(MainWindow::instance()->getAddBusAction(), SIGNAL(triggered()), SLOT(addBus()));
  connect(MainWindow::instance()->getAddTLMBusAction(), SIGNAL(triggered()), SLOT(addTLMBus()));
  connect(MainWindow::instance()->getAddSubModelAction(), SIGNAL(triggered()), SLOT(addSubModel()));
}

void ModelWidgetContainer::addModelWidget(ModelWidget *pModelWidget, bool checkPreferedView)
{
  bool hasModelWidget = false;
  QList<QMdiSubWindow*> subWindowsList = subWindowList(QMdiArea::ActivationHistoryOrder);
  for (int i = subWindowsList.size() - 1 ; i >= 0 ; i--) {
    ModelWidget *pSubModelWidget = qobject_cast<ModelWidget*>(subWindowsList.at(i)->widget());
    if (pSubModelWidget == pModelWidget) {
      if (pModelWidget->getLibraryTreeItem()->isModelica()) {
        pModelWidget->loadDiagramViewNAPI();
      }
      pModelWidget->createModelWidgetComponents();
      pModelWidget->show();
      setActiveSubWindow(subWindowsList.at(i));
      hasModelWidget = true;
      break;
    }
  }
  if (!hasModelWidget) {
    int subWindowsSize = subWindowList(QMdiArea::ActivationHistoryOrder).size();
    QMdiSubWindow *pSubWindow = addSubWindow(pModelWidget);
    addCloseActionsToSubWindowSystemMenu(pSubWindow);
    pSubWindow->setWindowIcon(ResourceCache::getIcon(":/Resources/icons/modeling.png"));
    if (pModelWidget->getLibraryTreeItem()->isModelica()) {
      pModelWidget->loadDiagramViewNAPI();
    }
    pModelWidget->createModelWidgetComponents();
    pModelWidget->show();
    if (subWindowsSize == 0 || MainWindow::instance()->isPlottingPerspectiveActive()) {
      pModelWidget->setWindowState(Qt::WindowMaximized);
    }
    setActiveSubWindow(pSubWindow);
    if (pModelWidget->getLibraryTreeItem()->isSSP()) {
      pModelWidget->getDiagramViewToolButton()->setChecked(true);
    }
  }
  if (pModelWidget->getLibraryTreeItem()->isText()) {
    pModelWidget->getTextViewToolButton()->setChecked(true);
    if (!pModelWidget->getEditor()->isVisible()) {
      pModelWidget->getEditor()->show();
    }
    pModelWidget->getEditor()->getPlainTextEdit()->setFocus(Qt::ActiveWindowFocusReason);
  }
  pModelWidget->updateViewButtonsBasedOnAccess();
  if (!checkPreferedView || !pModelWidget->getLibraryTreeItem()->isModelica()) {
    return;
  }
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
    QString defaultView = OptionsDialog::instance()->getGraphicalViewsPage()->getDefaultView();
    if (defaultView.compare(Helper::iconViewForSettings) == 0) {
      pModelWidget->getIconViewToolButton()->setChecked(true);
    } else if (defaultView.compare(Helper::textViewForSettings) == 0) {
      pModelWidget->getTextViewToolButton()->setChecked(true);
    } else {
      pModelWidget->getDiagramViewToolButton()->setChecked(true);
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
    if (className == pModelWidget->getLibraryTreeItem()->getNameStructure()) {
      return pModelWidget;
    }
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
  /* See ticket #6162 and #6248
   * We can have syntactically incorrect code in the current model so following actions should validate the text,
   * If MainWindow shortcut for menu actions are used then we should try to validate text since we can create a new model from there.
   * If context menu is used on LibraryTreeView to save a model other than the current model.
   * If QMenuBar is used with mouse or keyboard/shortcut
   * If QToolBar QToolButton is used with mouse. See issue #7389.
   * If users switches between model using the tab bar.
   * If focus in called for DocumentationViewer
   */
  /* Don't check LibraryTreeView focus since now OMEdit supports drag and drop of classnames on text view See ticket:5128
   * The user is expected to click on LibraryTreeView and drag items on the working text view which might be invalid.
   * So we don't want to validate text in that case. For OMSimualtor models we allow LibraryTreeView focus in.
   */
  bool shouldValidateText = false;
  if (event->type() == QEvent::Shortcut && qobject_cast<QAction*>(object) && object->parent() && qobject_cast<MainWindow*>(object->parent())) {
    QAction *pAction = qobject_cast<QAction*>(object);
    if (pAction->shortcut() != QKeySequence("Ctrl+q")) {
      shouldValidateText = true;
    }
  } else if (event->type() == QEvent::ContextMenu && object->parent() && qobject_cast<LibraryTreeView*>(object->parent())) {
    shouldValidateText = true;
  } else if ((event->type() == QEvent::MouseButtonPress && qobject_cast<QMenuBar*>(object)) ||
             (event->type() == QEvent::MouseButtonPress && qobject_cast<QToolButton*>(object)) ||
             (event->type() == QEvent::Shortcut && qobject_cast<QMenuBar*>(object)) ||
             (event->type() == QEvent::MouseButtonPress && qobject_cast<QTabBar*>(object)) ||
             (event->type() == QEvent::FocusIn && qobject_cast<DocumentationViewer*>(object))
             ) {
    shouldValidateText = true;
  } else if (event->type() == QEvent::FocusIn && qobject_cast<LibraryTreeView*>(object)) {
    ModelWidget *pCurrentModelWidget = getCurrentModelWidget();
    if (pCurrentModelWidget && pCurrentModelWidget->getLibraryTreeItem() && pCurrentModelWidget->getLibraryTreeItem()->isSSP()) {
      shouldValidateText = true;
    }
  }

  if (shouldValidateText) {
    /* if Model text is changed manually by user then validate it. */
    if (!validateText()) {
      return true;
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
              if (pModelWidget && pModelWidget->getLibraryTreeItem()) {
                QListWidgetItem *listItem = new QListWidgetItem(mpRecentModelsList);
                if (pModelWidget->getLibraryTreeItem()->isModelica()) {
                  listItem->setText(pModelWidget->getLibraryTreeItem()->getNameStructure());
                } else {
                  listItem->setText(pModelWidget->getLibraryTreeItem()->getName());
                }
                listItem->setData(Qt::UserRole, pModelWidget->getLibraryTreeItem()->getNameStructure());
              }
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
          if (pCurrentModelWidget && pCurrentModelWidget->getLibraryTreeItem()->isModelica()) {
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

/*!
 * \brief ModelWidgetContainer::validateText
 * Validates the text of the current ModelWidget editor.
 * \return Returns true if validation is successful otherwise return false.
 */
bool ModelWidgetContainer::validateText()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  if (pModelWidget && pModelWidget->getLibraryTreeItem()) {
    LibraryTreeItem *pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
    return pModelWidget->validateText(&pLibraryTreeItem);
  }
  return true;
}

/*!
 * \brief collectSelectedElements
 * Collect the selected elements.
 * \param pGraphicsView
 * \param pSelectedItemsList
 */
void collectSelectedElements(GraphicsView *pGraphicsView, QStringList *pSelectedItemsList)
{
  QList<QGraphicsItem*> selectedItems = pGraphicsView->scene()->selectedItems();
  for (int i = 0 ; i < selectedItems.size() ; i++) {
    Element *pElement = dynamic_cast<Element*>(selectedItems.at(i));
    if (pElement && pElement->isSelected()) {
      pSelectedItemsList->append(pElement->getName());
    }
  }
}

/*!
 * \brief ModelWidgetContainer::getOpenedModelWidgetsAndSelectedElementsOfClass
 * Creates the list of opened ModelWidgets and its selected icon and diagram view elements.
 * \param modelName
 * \param pOpenedModelWidgetsAndSelectedElements
 * \param pIconSelectedItemsList
 * \param pDiagramSelectedItemsList
 */
void ModelWidgetContainer::getOpenedModelWidgetsAndSelectedElementsOfClass(const QString &modelName,
                                                                           QHash<QString, QPair<QStringList, QStringList> > *pOpenedModelWidgetsAndSelectedElements)
{
  QList<QMdiSubWindow*> subWindowsList = subWindowList(QMdiArea::StackingOrder);
  foreach (QMdiSubWindow *pSubWindow, subWindowsList) {
    ModelWidget *pModelWidget = qobject_cast<ModelWidget*>(pSubWindow->widget());
    if (pModelWidget && pModelWidget->getLibraryTreeItem()
        && StringHandler::getFirstWordBeforeDot(pModelWidget->getLibraryTreeItem()->getNameStructure()).compare(modelName) == 0) {
      QStringList iconSelectedItemsList, diagramSelectedItemsList;
      // icon view selected elements
      if (pModelWidget->getIconGraphicsView()) {
        collectSelectedElements(pModelWidget->getIconGraphicsView(), &iconSelectedItemsList);
      }
      // diagram view selected elements
      if (pModelWidget && pModelWidget->getDiagramGraphicsView()) {
        collectSelectedElements(pModelWidget->getDiagramGraphicsView(), &diagramSelectedItemsList);
      }
      pOpenedModelWidgetsAndSelectedElements->insert(pModelWidget->getLibraryTreeItem()->getNameStructure(), qMakePair(iconSelectedItemsList, diagramSelectedItemsList));
    }
  }
}

/*!
 * \brief selectElements
 * Selects the elements.
 * \param pGraphicsView
 * \param selectedItemsList
 */
void selectElements(GraphicsView *pGraphicsView, QStringList selectedItemsList)
{
  foreach (QString selectedItem, selectedItemsList) {
    Element *pElement = pGraphicsView->getElementObject(selectedItem);
    if (pElement) {
      pElement->setSelected(true);
    }
  }
}

/*!
 * \brief ModelWidgetContainer::openModelWidgetsAndSelectElement
 * Opens the ModelWidgets and select elements in icon and diagram view.
 * \param closedModelWidgetsAndSelectedElements
 */
void ModelWidgetContainer::openModelWidgetsAndSelectElement(QHash<QString, QPair<QStringList, QStringList> > closedModelWidgetsAndSelectedElements, bool skipSelection)
{
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  QHash<QString, QPair<QStringList, QStringList> >::const_iterator iterator = closedModelWidgetsAndSelectedElements.constBegin();
  while (iterator != closedModelWidgetsAndSelectedElements.constEnd()) {
    LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(iterator.key());
    if (pLibraryTreeItem) {
      pLibraryTreeModel->showModelWidget(pLibraryTreeItem);
      if (pLibraryTreeItem->getModelWidget() && !skipSelection) {
        // select icon view Elements
        if (pLibraryTreeItem->getModelWidget()->getIconGraphicsView()) {
          selectElements(pLibraryTreeItem->getModelWidget()->getIconGraphicsView(), iterator.value().first);
        }
        // select diagram view Elements
        if (pLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()) {
          selectElements(pLibraryTreeItem->getModelWidget()->getDiagramGraphicsView(), iterator.value().second);
        }
      }
    }
    ++iterator;
  }
}

/*!
 * \brief ModelWidgetContainer::loadPreviousViewType
 * Opens the ModelWidget using the previous view type used by user.
 * \param pModelWidget
 */
void ModelWidgetContainer::loadPreviousViewType(ModelWidget *pModelWidget)
{
  if (pModelWidget->getLibraryTreeItem()->isModelica()) {
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
  } else if (pModelWidget->getLibraryTreeItem()->isText()) {
    pModelWidget->getTextViewToolButton()->setChecked(true);
  } else {
    qDebug() << "ModelWidgetContainer::loadPreviousViewType() should never be reached.";
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
  if (!validateText()) {
    return false;
  }
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(pListWidgetItem->data(Qt::UserRole).toString());
  if (!pLibraryTreeItem) {
    return false;
  }
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
  bool zoomEnabled = false;
  bool modelica = false;
  bool oms = false;
  bool plottingDiagram = false;
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
    zoomEnabled = true;
    pModelWidget = qobject_cast<ModelWidget*>(pSubWindow->widget());
    pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
    iconGraphicsView = pModelWidget->getIconViewToolButton()->isChecked();
    diagramGraphicsView = pModelWidget->getDiagramViewToolButton()->isChecked();
    textView = pModelWidget->getTextViewToolButton()->isChecked();
    // check for git working directory
    /* ticket:5646 Crash when importing SSP files with TLM systems
     * Disable the Git features until we have them implemented properly.
     * GitCommands::getGitStdout causes crash in Linux.
     */
    //gitWorkingDirectory = !pLibraryTreeItem->getFileName().isEmpty() && GitCommands::instance()->isSavedUnderGitRepository(pLibraryTreeItem->getFileName());
    if (pLibraryTreeItem->isModelica()) {
      modelica = true;
    } else if (pLibraryTreeItem->isSSP()) {
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
  } else if (MainWindow::instance()->isPlottingPerspectiveActive() && MainWindow::instance()->getPlotWindowContainer()->currentSubWindow()
             && MainWindow::instance()->getPlotWindowContainer()->isDiagramWindow(MainWindow::instance()->getPlotWindowContainer()->currentSubWindow()->widget())) {
    zoomEnabled = true;
    plottingDiagram = true;
  }
  // update the actions of the menu and toolbars
  MainWindow::instance()->getSaveAction()->setEnabled(enabled);
  MainWindow::instance()->getSaveAsAction()->setEnabled(enabled && pLibraryTreeItem && pLibraryTreeItem->isTopLevel());
  //  MainWindow::instance()->getSaveAllAction()->setEnabled(enabled);
  MainWindow::instance()->getSaveTotalAction()->setEnabled(enabled && modelica);
  MainWindow::instance()->getShowGridLinesAction()->setEnabled(enabled && (modelica || oms) && !textView && !pModelWidget->getLibraryTreeItem()->isSystemLibrary() && !pModelWidget->isElementMode());
  MainWindow::instance()->getResetZoomAction()->setEnabled(zoomEnabled && (modelica || oms || plottingDiagram));
  MainWindow::instance()->getZoomInAction()->setEnabled(zoomEnabled && (modelica || oms || plottingDiagram));
  MainWindow::instance()->getZoomOutAction()->setEnabled(zoomEnabled && (modelica || oms || plottingDiagram));
  MainWindow::instance()->getFitToDiagramAction()->setEnabled(zoomEnabled && (modelica));
  MainWindow::instance()->getLineShapeAction()->setEnabled(enabled && modelica && !textView);
  MainWindow::instance()->getPolygonShapeAction()->setEnabled(enabled && modelica && !textView);
  MainWindow::instance()->getRectangleShapeAction()->setEnabled(enabled && modelica && !textView);
  MainWindow::instance()->getEllipseShapeAction()->setEnabled(enabled && modelica && !textView);
  MainWindow::instance()->getTextShapeAction()->setEnabled(enabled && modelica && !textView);
  MainWindow::instance()->getBitmapShapeAction()->setEnabled(enabled && modelica && !textView);
  MainWindow::instance()->getConnectModeAction()->setEnabled(enabled && (modelica || (oms && !(omsSubmodel || omsConnector))) && !textView);
  MainWindow::instance()->getTransitionModeAction()->setEnabled(enabled && (modelica) && !textView);
  MainWindow::instance()->getSimulateModelAction()->setEnabled(enabled && ((modelica && pLibraryTreeItem->isSimulationAllowed()) || (oms)));
  MainWindow::instance()->getSimulateWithTransformationalDebuggerAction()->setEnabled(enabled && modelica && pLibraryTreeItem->isSimulationAllowed());
  MainWindow::instance()->getSimulateWithAlgorithmicDebuggerAction()->setEnabled(enabled && modelica && pLibraryTreeItem->isSimulationAllowed());
#if !defined(WITHOUT_OSG)
  MainWindow::instance()->getSimulateWithAnimationAction()->setEnabled(enabled && modelica && pLibraryTreeItem->isSimulationAllowed());
#endif
  MainWindow::instance()->getSimulateModelInteractiveAction()->setEnabled(enabled && oms);
  MainWindow::instance()->getSimulationSetupAction()->setEnabled(enabled && ((modelica && pLibraryTreeItem->isSimulationAllowed()) || (oms)));
  MainWindow::instance()->getCalculateDataReconciliationAction()->setEnabled(enabled && modelica && pLibraryTreeItem->isSimulationAllowed());
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
  MainWindow::instance()->getExportToClipboardAction()->setEnabled(enabled && (modelica || oms));
  MainWindow::instance()->getExportAsImageAction()->setEnabled(enabled && (modelica || oms));
  MainWindow::instance()->getExportFMUAction()->setEnabled(enabled && modelica);
  bool packageSaveAsFolder = (enabled && pLibraryTreeItem && pLibraryTreeItem->isTopLevel()
                              && pLibraryTreeItem->getRestriction() == StringHandler::Package
                              && pLibraryTreeItem->isSaveFolderStructure());
  MainWindow::instance()->getExportReadonlyPackageAction()->setEnabled(packageSaveAsFolder && enabled && modelica);
  MainWindow::instance()->getExportEncryptedPackageAction()->setEnabled(packageSaveAsFolder && enabled && modelica);
  MainWindow::instance()->getExportXMLAction()->setEnabled(enabled && modelica);
  MainWindow::instance()->getExportFigaroAction()->setEnabled(enabled && modelica);
  MainWindow::instance()->getExportToOMNotebookAction()->setEnabled(enabled && modelica);
  MainWindow::instance()->getAddSystemAction()->setEnabled(enabled && !iconGraphicsView && !textView && (omsModel || (omsSystem && (!pLibraryTreeItem->isSCSystem()))));
  MainWindow::instance()->getAddOrEditIconAction()->setEnabled(enabled && !diagramGraphicsView && !textView && (omsSystem || omsSubmodel));
  MainWindow::instance()->getDeleteIconAction()->setEnabled(enabled && !diagramGraphicsView && !textView && (omsSystem || omsSubmodel));
  MainWindow::instance()->getAddConnectorAction()->setEnabled(enabled && !textView && (omsSystem && (!pLibraryTreeItem->isTLMSystem())));
  MainWindow::instance()->getAddBusAction()->setEnabled(enabled && !textView && ((omsSystem || omsSubmodel)  && (!pLibraryTreeItem->isTLMSystem())));
  MainWindow::instance()->getAddTLMBusAction()->setEnabled(enabled && !textView && ((omsSystem || omsSubmodel)  && (!pLibraryTreeItem->isTLMSystem())));
  MainWindow::instance()->getAddSubModelAction()->setEnabled(enabled && !iconGraphicsView && !textView && omsSystem);
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
    // set the focus when ModelWidget is changed so that the keyboard shortcuts can work e.g., ctrl+v
    if (pModelWidget->getIconGraphicsView() && pModelWidget->getIconGraphicsView()->isVisible()) {
      pModelWidget->getIconGraphicsView()->setFocus(Qt::ActiveWindowFocusReason);
    } else if (pModelWidget->getDiagramGraphicsView() && pModelWidget->getDiagramGraphicsView()->isVisible()) {
      pModelWidget->getDiagramGraphicsView()->setFocus(Qt::ActiveWindowFocusReason);
    } else if (pModelWidget->getEditor() && pModelWidget->getEditor()) {
      pModelWidget->getEditor()->getPlainTextEdit()->setFocus(Qt::ActiveWindowFocusReason);
    }
  } else {
    MainWindow::instance()->getUndoAction()->setEnabled(false);
    MainWindow::instance()->getRedoAction()->setEnabled(false);
  }
  /* ticket:5441 OMEdit toolbars
   * Show the relevant toolbars if we are in a Modeling perspective
   */
  if (MainWindow::instance()->isModelingPerspectiveActive()) {
    MainWindow::instance()->showModelingPerspectiveToolBars(pModelWidget);
  } else if (MainWindow::instance()->isDebuggingPerspectiveActive()) {
    MainWindow::instance()->showDebuggingPerspectiveToolBars(pModelWidget);
  }
  if (!pSubWindow || mpLastActiveSubWindow == pSubWindow) {
    return;
  }
  mpLastActiveSubWindow = pSubWindow;
  // update the model if its require update flag is set.
  if (pModelWidget && pModelWidget->requiresUpdate()) {
    pModelWidget->setRequiresUpdate(false);
    pModelWidget->reDrawModelWidget(pModelWidget->createModelInfo());
  }
  /* ticket:4983 Update the documentation browser when a new ModelWidget is selected.
   * Provided that the Documentation Browser is already visible.
   */
  if (pModelWidget && pModelWidget->getLibraryTreeItem() && MainWindow::instance()->getDocumentationDockWidget()->isVisible()) {
    MainWindow::instance()->getDocumentationWidget()->showDocumentation(pModelWidget->getLibraryTreeItem());
  }
  // Update the LibraryTreeView to mark the active model
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeView()->viewport()->update();
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getSynchronizeWithModelWidgetCheckBox()->isChecked()) {
    MainWindow::instance()->getLibraryWidget()->scrollToActiveLibraryTreeItem();
  }
  // Update Element Browser
  if (pModelWidget && pModelWidget->getLibraryTreeItem()) {
    MainWindow::instance()->getElementWidget()->getElementTreeModel()->addElements(pModelWidget->getModelInstance());
    MainWindow::instance()->getElementWidget()->selectDeselectElementItem("", false);
  }
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
    QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                             GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN).arg(tr("saving")), QMessageBox::Ok);
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
    QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                             GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN).arg(tr("save as")), QMessageBox::Ok);
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
                             GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN).arg(tr("saving")), QMessageBox::Ok);
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
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
        pPrintDialog->setOption(QAbstractPrintDialog::PrintSelection);
#else
        pPrintDialog->addEnabledOption(QAbstractPrintDialog::PrintSelection);
#endif
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
        painter.setRenderHints(QPainter::Antialiasing | QPainter::SmoothPixmapTransform);
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
 * \brief ModelWidgetContainer::fitToDiagram
 * Fits the active ModelWidget to its diagram.
 */
void ModelWidgetContainer::fitToDiagram()
{
  ModelWidget *pModelWidget = getCurrentModelWidget();
  if (pModelWidget) {
    // show the progressbar and set the message in status bar
    MainWindow::instance()->getProgressBar()->setRange(0, 0);
    MainWindow::instance()->showProgressBar();
    MainWindow::instance()->getStatusBar()->showMessage(tr("Adapting extent to diagram"));
    GraphicsView *pGraphicsView;
    if (pModelWidget->getIconGraphicsView()->isVisible()) {
      pGraphicsView = pModelWidget->getIconGraphicsView();
    } else {
      pGraphicsView = pModelWidget->getDiagramGraphicsView();
    }
    QRect diagramRect = pGraphicsView->itemsBoundingRect().toAlignedRect();
    diagramRect = pGraphicsView->mapToScene(diagramRect).boundingRect().toRect();
    // invert the rectangle as the drawing area has scale(1.0, -1.0);
    const int top = diagramRect.top();
    diagramRect.setTop(diagramRect.bottom());
    diagramRect.setBottom(top);
    // Make the extent values interval of 10 based on grid size
    const int xInterval = qRound(pGraphicsView->mMergedCoordinateSystem.getHorizontalGridStep()) * 10;
    const int yInterval = qRound(pGraphicsView->mMergedCoordinateSystem.getVerticalGridStep()) * 10;
    const int left = qRound((double)diagramRect.left() / xInterval) * xInterval;
    const int bottom = qRound((double)diagramRect.bottom() / yInterval) * yInterval;
    const int right = qRound((double)diagramRect.right() / xInterval) * xInterval;
    const int top_ = qRound((double)diagramRect.top() / yInterval) * yInterval;
    QRectF adaptedRect(left, bottom, qAbs(left - right), qAbs(bottom - top_));
    // For read-only system libraries we just set the zoom and for writeable models we modify the extent.
    if (pModelWidget->getLibraryTreeItem()->isSystemLibrary() || pModelWidget->isElementMode()) {
      pGraphicsView->setIsCustomScale(true);
      pGraphicsView->fitInView(diagramRect, Qt::KeepAspectRatio);
    } else {
      // avoid putting unnecessary commands on the stack
      if (adaptedRect.width() != 0 && adaptedRect.height() != 0 && adaptedRect != pGraphicsView->mMergedCoordinateSystem.getExtentRectangle()) {
        // CoordinateSystem
        ModelInstance::CoordinateSystem oldCoordinateSystem = pGraphicsView->mCoordinateSystem;
        // version
        QString oldVersion = pModelWidget->getLibraryTreeItem()->mClassInformation.version;
        // uses annotation
        OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
        QList<QList<QString> > usesAnnotation = pOMCProxy->getUses(pModelWidget->getLibraryTreeItem()->getNameStructure());
        QStringList oldUsesAnnotation;
        for (int i = 0 ; i < usesAnnotation.size() ; i++) {
          oldUsesAnnotation.append(QString("%1(version=\"%2\")").arg(usesAnnotation.at(i).at(0)).arg(usesAnnotation.at(i).at(1)));
        }
        QString oldUsesAnnotationString = QString("annotate=$annotation(uses(%1))").arg(oldUsesAnnotation.join(","));
        // construct a new CoordinateSystem
        ModelInstance::CoordinateSystem newCoordinateSystem = oldCoordinateSystem;
        QVector<QPointF> extent;
        extent.append(QPointF(adaptedRect.left(), adaptedRect.bottom()));
        extent.append(QPointF(adaptedRect.right(), adaptedRect.top()));
        newCoordinateSystem.setExtent(extent);
        // push the CoordinateSystem change to undo stack
        UpdateCoordinateSystemCommand *pUpdateCoordinateSystemCommand = new UpdateCoordinateSystemCommand(pGraphicsView, oldCoordinateSystem, newCoordinateSystem, false,
                                                                                                          oldVersion, oldVersion, oldUsesAnnotationString,
                                                                                                          oldUsesAnnotationString);
        pModelWidget->getUndoStack()->push(pUpdateCoordinateSystemCommand);
        pModelWidget->updateModelText();
      }
    }
    // hide the progressbar and clear the message in status bar
    MainWindow::instance()->getStatusBar()->clearMessage();
    MainWindow::instance()->hideProgressBar();
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                          .arg(tr("adapting extent to diagram")), Helper::scriptingKind, Helper::notificationLevel));
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
        AddOrEditIconDialog *pAddOrEditSubModelIconDialog = new AddOrEditIconDialog(pShapeAnnotation, pModelWidget->getIconGraphicsView());
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
        pModelWidget->addUpdateDeleteOMSElementIcon("");
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
    QList<Element*> components;
    QList<QGraphicsItem*> selectedItems = pGraphicsView->scene()->selectedItems();
    for (int i = 0 ; i < selectedItems.size() ; i++) {
      // check the selected components.
      Element *pComponent = dynamic_cast<Element*>(selectedItems.at(i));
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
    QList<Element*> components;
    QList<QGraphicsItem*> selectedItems = pGraphicsView->scene()->selectedItems();
    for (int i = 0 ; i < selectedItems.size() ; i++) {
      // check the selected components.
      Element *pComponent = dynamic_cast<Element*>(selectedItems.at(i));
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
    QString name = "";
    QString path = AddSubModelDialog::browseSubModelPath(pModelWidget->getDiagramGraphicsView(), &name);
    if (!path.isEmpty()) {
      AddSubModelDialog *pAddFMUDialog = new AddSubModelDialog(pModelWidget->getDiagramGraphicsView(), path, name);
      pAddFMUDialog->exec();
    }
  }
}
