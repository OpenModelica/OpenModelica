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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
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

#include <osgGA/MultiTouchTrackballManipulator>
#include <osgViewer/ViewerEventHandlers>

#include <QPainter>
#include <QColorDialog>
#include <QKeyEvent>
#include <cassert>

#include "ViewerWidget.h"
#include "Modeling/MessagesWidget.h"

/*!
 * \brief Viewer::setUpThreading
 */
void Viewer::setUpThreading()
{
  if (_threadingModel == SingleThreaded) {
    if (_threadsRunning) {
      stopThreading();
    }
  } else {
    if (!_threadsRunning) {
      startThreading();
    }
  }
}

/*!
 * \class ViewerWidget
 * \brief Viewer widget for OpenSceneGraph animations.
 */
/*!
 * \brief ViewerWidget::ViewerWidget
 * \param parent
 * \param flags
 */
ViewerWidget::ViewerWidget(QWidget* parent, Qt::WindowFlags flags)
  : GLWidget(parent, flags)

{
  // Set the number of samples used for multisampling
#if (QT_VERSION >= QT_VERSION_CHECK(5, 4, 0))
  QSurfaceFormat format;
  format.setSamples(4);
  setFormat(format);
#else
  QGLFormat format;
  format.setSamples(4);
  setFormat(format);
#endif
  mpGraphicsWindow = new osgViewer::GraphicsWindowEmbedded(x(), y(), width(), height());
  mpViewer = new Viewer;
  mpSceneView = new osgViewer::View();
  mpAnimationWidget = qobject_cast<AbstractAnimationWindow*>(parent);
  // widget resolution
  int height = rect().height();
  int width = rect().width();
  // add a scene to viewer
  mpViewer->addView(mpSceneView);
  // get the viewer widget
  osg::ref_ptr<osg::Camera> camera = mpSceneView->getCamera();
  camera->setGraphicsContext(mpGraphicsWindow);
  camera->setClearColor(osg::Vec4(0.95, 0.95, 0.95, 1.0));
  camera->setViewport(new osg::Viewport(0, 0, width, height));
  camera->setProjectionMatrixAsPerspective(30.0f, static_cast<double>(width/2) / static_cast<double>(height/2), 1.0f, 10000.0f);
  mpSceneView->addEventHandler(new osgViewer::StatsHandler());
  // reverse the mouse wheel zooming
  osgGA::MultiTouchTrackballManipulator *pMultiTouchTrackballManipulator = new osgGA::MultiTouchTrackballManipulator();
  pMultiTouchTrackballManipulator->setWheelZoomFactor(-pMultiTouchTrackballManipulator->getWheelZoomFactor());
  mpSceneView->setCameraManipulator(pMultiTouchTrackballManipulator);
  // the osg threading model
  mpViewer->setThreadingModel(osgViewer::CompositeViewer::SingleThreaded);
  // disable the default setting of viewer.done() by pressing Escape.
  mpViewer->setKeyEventSetsDone(0);
  mpViewer->realize();
  // This ensures that the widget will receive keyboard events. This focus
  // policy is not set by default. The default, Qt::NoFocus, will result in
  // keyboard events that are ignored.
  setFocusPolicy(Qt::StrongFocus);
  setMinimumSize(100, 100);
  // Ensures that the widget receives mouse move events even though no
  // mouse button has been pressed. We require this in order to let the
  // graphics window switch viewports properly.
  setMouseTracking(true);
}

/*!
 * \brief ViewerWidget::paintEvent
 * Reimplementation of the paintEvent.\n
 * \sa ViewerWidget::paintGL()
 */
void ViewerWidget::paintEvent(QPaintEvent* /* paintEvent */)
{
  makeCurrent();
  QPainter painter(this);
  painter.setRenderHint(QPainter::Antialiasing);
  paintGL();
  painter.end();
  doneCurrent();
}

/*!
 * \brief ViewerWidget::paintGL
 * Renders the animation frame.
 * \sa ViewerWidget::paintEvent()
 */
void ViewerWidget::paintGL()
{
  mpViewer->frame();
}

/*!
 * \brief ViewerWidget::resizeGL
 * Resizes the graphics window.
 * \param width
 * \param height
 */
void ViewerWidget::resizeGL(int width, int height)
{
  getEventQueue()->windowResize(x(), y(), width, height);
  mpGraphicsWindow->resized(x(), y(), width, height);
}

/*!
 * \brief ViewerWidget::keyPressEvent
 * Passes the QWidget::keyPressEvent() to Graphics Window.
 * \param event
 */
void ViewerWidget::keyPressEvent(QKeyEvent *event)
{
  QString keyString = event->text();
  const char* keyData = keyString.toLocal8Bit().data();
  getEventQueue()->keyPress(osgGA::GUIEventAdapter::KeySymbol(*keyData));
}

/*!
 * \brief ViewerWidget::keyReleaseEvent
 * Passes the QWidget::keyReleaseEvent() to Graphics Window.
 * \param event
 */
void ViewerWidget::keyReleaseEvent(QKeyEvent *event)
{
  QString keyString = event->text();
  const char* keyData = keyString.toLocal8Bit().data();
  getEventQueue()->keyRelease(osgGA::GUIEventAdapter::KeySymbol(*keyData));
}

/*!
 * \brief ViewerWidget::mouseMoveEvent
 * Passes the QWidget::mouseMoveEvent() to Graphics Window.
 * \param event
 */
void ViewerWidget::mouseMoveEvent(QMouseEvent *event)
{
  getEventQueue()->mouseMotion(static_cast<float>(event->x()), static_cast<float>(event->y()));
}

/*!
 * \brief ViewerWidget::mousePressEvent
 * Passes the QWidget::mousePressEvent() to Graphics Window.
 * \param event
 */
void ViewerWidget::mousePressEvent(QMouseEvent *event)
{
  // 1 = left mouse button
  // 2 = middle mouse button
  // 3 = right mouse button
  unsigned int button = 0;
  switch (event->button()) {
    case Qt::LeftButton:
      button = 1;
      break;
    case Qt::MiddleButton:
      button = 2;
      break;
    case Qt::RightButton:
      button = 3;
      if (event->modifiers() == Qt::ShiftModifier) {
        //qt counts pixels from upper left corner and osg from bottom left corner
        pickShape(event->x(), this->height() - event->y());
        showShapePickContextMenu(event->pos());
        return;
      }
      break;
    default:
      break;
  }
  getEventQueue()->mouseButtonPress(static_cast<float>(event->x()), static_cast<float>(event->y()), button);
}

/*!
 * \brief ViewerWidget::pickShape
 * Picks the name of the selected shape in the osg view
 * \param x - mouse position pixel in x direction in osg system
 * \param y - mouse position pixel in y direction in osg system
 */
void ViewerWidget::pickShape(int x, int y)
{
  //std::cout<<"pickShape "<<x<<" and "<<y<<std::endl;
  osgUtil::LineSegmentIntersector::Intersections intersections;
  if (mpSceneView->computeIntersections(mpSceneView->getCamera(),osgUtil::Intersector::WINDOW , x, y, intersections)) {
    //take the first intersection with a facette only
    osgUtil::LineSegmentIntersector::Intersections::iterator hitr = intersections.begin();

    if (!hitr->nodePath.empty() && !(hitr->nodePath.back()->getName().empty())) {
      mSelectedShape = hitr->nodePath.back()->getName();
      //std::cout<<"Object identified by name "<<mSelectedShape<<std::endl;
    } else if (hitr->drawable.valid()) {
      mSelectedShape = hitr->drawable->className();
      //std::cout<<"Object identified by its drawable "<<mSelectedShape<<std::endl;
    }
  }
}

/*!
 * \brief ViewerWidget::showShapePickContextMenu
 * \param pos
 */
void ViewerWidget::showShapePickContextMenu(const QPoint& pos)
{
  QString name = QString::fromStdString(mSelectedShape);
  //std::cout<<"SHOW CONTEXT "<<name.toStdString()<<" compare "<<QString::compare(name,QString(""))<< std::endl;
  //the context widget
  QMenu contextMenu(tr("Context menu"), this);
  QMenu shapeMenu(name, this);
  shapeMenu.setIcon(QIcon(":/Resources/icons/animation.svg"));
  QAction action0(QIcon(":/Resources/icons/undo.svg"), tr("Reset Transparency and Texture"), this);
  QAction action1(QIcon(":/Resources/icons/transparency.svg"), tr("Change Transparency"), this);
  QAction action2(QIcon(":/Resources/icons/invisible.svg"), tr("Make Shape Invisible"), this);
  QAction action3(QIcon(":/Resources/icons/changeColor.svg"), tr("Change Color"), this);
  QAction action4(QIcon(":/Resources/icons/checkered.svg"), tr("Apply Check Texture"), this);
  QAction action5(QIcon(":/Resources/icons/texture.svg"), tr("Apply Custom Texture"), this);
  QAction action6(QIcon(":/Resources/icons/undo.svg"), tr("Remove Texture"), this);

  //if a shape is picked, we can set it transparent
  if (0 != QString::compare(name,QString(""))) {
    contextMenu.addMenu(&shapeMenu);
    shapeMenu.addAction( &action1);
    shapeMenu.addAction( &action2);
    shapeMenu.addSeparator();
    shapeMenu.addAction( &action3);
    shapeMenu.addSeparator();
    shapeMenu.addAction( &action4);
    shapeMenu.addAction( &action5);
    shapeMenu.addAction( &action6);
    shapeMenu.addSeparator();
    connect(&action1, SIGNAL(triggered()), this, SLOT(changeShapeTransparency()));
    connect(&action2, SIGNAL(triggered()), this, SLOT(makeShapeInvisible()));
    connect(&action3, SIGNAL(triggered()), this, SLOT(changeShapeColor()));
    connect(&action4, SIGNAL(triggered()), this, SLOT(applyCheckTexture()));
    connect(&action5, SIGNAL(triggered()), this, SLOT(applyCustomTexture()));
    connect(&action6, SIGNAL(triggered()), this, SLOT(removeTexture()));
  }
  contextMenu.addAction(&action0);
  connect(&action0, SIGNAL(triggered()), this, SLOT(removeTransparencyForAllShapes()));
  contextMenu.exec(this->mapToGlobal(pos));
}

/*!
 * \brief ViewerWidget::applyCheckTexture
 * adds a checkered texture to the shape
 */
void ViewerWidget::applyCheckTexture()
{
    ShapeObject* shape = nullptr;
    if ((shape = mpAnimationWidget->getVisualizer()->getBaseData()->getShapeObjectByID(mSelectedShape)))
    {
      if (shape->_type.compare("dxf") == 0 or shape->_type.compare("stl") == 0)
      {
        QString msg = tr("Texture feature for CAD-Files is not applicable.");
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                                    Helper::notificationLevel));
      }
      else
      {
        shape->setTextureImagePath(":/Resources/bitmaps/check.png");
        mpAnimationWidget->getVisualizer()->modifyShape(mSelectedShape);
        mSelectedShape = "";
      }
    }
}

/*!
 * \brief ViewerWidget::removeTexture
 * removes the texture of the shape
 */
void ViewerWidget::removeTexture()
{
    ShapeObject* shape = nullptr;
    if ((shape = mpAnimationWidget->getVisualizer()->getBaseData()->getShapeObjectByID(mSelectedShape)))
    {
      if (shape->_type.compare("dxf") == 0 or shape->_type.compare("stl") == 0)
      {
        QString msg = tr("Texture feature for CAD-Files is not applicable.");
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                                    Helper::notificationLevel));
      }
      else
      {
        shape->setTextureImagePath("");
        mpAnimationWidget->getVisualizer()->modifyShape(mSelectedShape);
        mSelectedShape = "";
      }
    }
}


/*!
 * \brief ViewerWidget::applyCustomTexture
 * adds a user-defiend texture to the shape
 */
void ViewerWidget::applyCustomTexture()
{
    ShapeObject* shape = nullptr;
    if ((shape = mpAnimationWidget->getVisualizer()->getBaseData()->getShapeObjectByID(mSelectedShape)))
    {
      if (shape->_type.compare("dxf") == 0 or shape->_type.compare("stl") == 0)
      {
        QString msg = tr("Texture feature for CAD-Files is not applicable.");
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                                    Helper::notificationLevel));
      }
      else
      {
        QString fileName = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseFile),
                                                              NULL, Helper::bitmapFileTypes, NULL);
        if(fileName.compare(""))
        {
          shape->setTextureImagePath(fileName.toStdString());
          mpAnimationWidget->getVisualizer()->modifyShape(mSelectedShape);
          mSelectedShape = "";
        }
      }
    }
}

/*!
 * \brief ViewerWidget::changeShapeTransparency
 * changes the transparency selection of a shape
 */
void ViewerWidget::changeShapeTransparency()
{
  ShapeObject* shape = nullptr;
  if ((shape = mpAnimationWidget->getVisualizer()->getBaseData()->getShapeObjectByID(mSelectedShape))) {
    if (shape->_type.compare("dxf") == 0) {
      QString msg = tr("Transparency is not applicable for DXF-Files.");
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                            Helper::notificationLevel));
      mSelectedShape = "";
    } else {
      if (shape->getTransparency() == 0) {
        shape->setTransparency(0.5);
      } else {
        shape->setTransparency(0.0);
      }
      mpAnimationWidget->getVisualizer()->modifyShape(mSelectedShape);
      mSelectedShape = "";
    }
  }
}

/*!
 * \brief ViewerWidget::makeShapeInvisible
 * suppresses the visualization of this shape
 */
void ViewerWidget::makeShapeInvisible()
{
  ShapeObject* shape = nullptr;
  if ((shape = mpAnimationWidget->getVisualizer()->getBaseData()->getShapeObjectByID(mSelectedShape))) {
    if (shape->_type.compare("dxf") == 0) {
      QString msg = tr("Invisibility is not applicable for DXF-Files.");
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                            Helper::notificationLevel));
      mSelectedShape = "";
    } else {
      shape->setTransparency(1.0);
      mpAnimationWidget->getVisualizer()->modifyShape(mSelectedShape);
      mSelectedShape = "";
    }
  }
}

/*!
 * \brief ViewerWidget::changeShapeColor
 * opens a color dialog and selects a new color for the shape
 */
void ViewerWidget::changeShapeColor()
{
  ShapeObject* shape = nullptr;
  if ((shape = mpAnimationWidget->getVisualizer()->getBaseData()->getShapeObjectByID(mSelectedShape))) {
    if (shape->_type.compare("dxf") == 0)
    {
      QString msg = tr("Changing the color is not applicable for DXF-Files.");
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                            Helper::notificationLevel));
      mSelectedShape = "";
    }
    else
    {
      QColor currentColor = shape->getColor();
      QColor color = QColorDialog::getColor(currentColor, this,"Shape Color");
      if(color.isValid())
      {
        shape->setColor(color);
      }
      else
      {
          QString msg = tr("The selected color is not valid.");
          MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                                Helper::notificationLevel));
      }
      mpAnimationWidget->getVisualizer()->modifyShape(mSelectedShape);
      mSelectedShape = "";
    }
  }
}

/*!
 * \brief ViewerWidget::removeTransparancyForAllShapes
 * sets all transparency settings back to default (nothing is transparent)
 *
 */
void ViewerWidget::removeTransparencyForAllShapes()
{
  if (mpAnimationWidget->getVisualizer() != NULL) {
    std::vector<ShapeObject>* shapes = nullptr;
    shapes = &mpAnimationWidget->getVisualizer()->getBaseData()->_shapes;
    for (std::vector<ShapeObject>::iterator shape = shapes->begin() ; shape < shapes->end(); ++shape) {
      shape->setTransparency(0.0);
      shape->setTextureImagePath("");
      mpAnimationWidget->getVisualizer()->modifyShape(shape->_id);
    }
  }
}

/*!
 * \brief ViewerWidget::mouseReleaseEvent
 * Passes the QWidget::mouseReleaseEvent() to Graphics Window.
 * \param event
 */
void ViewerWidget::mouseReleaseEvent(QMouseEvent *event)
{
  // 1 = left mouse button
  // 2 = middle mouse button
  // 3 = right mouse button
  unsigned int button = 0;
  switch (event->button()) {
    case Qt::LeftButton:
      button = 1;
      break;
    case Qt::MiddleButton:
      button = 2;
      break;
    case Qt::RightButton:
      button = 3;
      mSelectedShape = "";
      break;
    default:
      break;
  }
  getEventQueue()->mouseButtonRelease(static_cast<float>(event->x()), static_cast<float>(event->y()), button);
}

/*!
 * \brief ViewerWidget::wheelEvent
 * Passes the QWidget::wheelEvent() to Graphics Window.
 * \param event
 */
void ViewerWidget::wheelEvent(QWheelEvent *event)
{
  event->accept();
  int delta = event->delta();
  osgGA::GUIEventAdapter::ScrollingMotion motion = delta > 0 ? osgGA::GUIEventAdapter::SCROLL_UP : osgGA::GUIEventAdapter::SCROLL_DOWN;
  getEventQueue()->mouseScroll(motion);
}

/*!
 * \brief ViewerWidget::event
 * Repaint the Graphics window on each user interaction.
 * \param event
 * \return
 */
bool ViewerWidget::event(QEvent *event)
{
  bool handled = GLWidget::event(event);
  // This ensures that the OSG widget is always going to be repainted after the
  // user performed some interaction. Doing this in the event handler ensures
  // that we don't forget about some event and prevents duplicate code.
  switch(event->type()) {
    case QEvent::KeyPress:
    case QEvent::KeyRelease:
    case QEvent::MouseButtonDblClick:
    case QEvent::MouseButtonPress:
    case QEvent::MouseButtonRelease:
    case QEvent::MouseMove:
    case QEvent::Wheel:
      update();
      break;
    default:
      break;
  }
  return handled;
}

/*!
 * \brief ViewerWidget::getEventQueue
 * \return
 */
osgGA::EventQueue* ViewerWidget::getEventQueue() const
{
  osgGA::EventQueue* eventQueue = mpGraphicsWindow->getEventQueue();
  assert (eventQueue != 0);
  return eventQueue;
}
