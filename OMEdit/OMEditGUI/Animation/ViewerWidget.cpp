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
#include <QKeyEvent>
#include <cassert>

#include "ViewerWidget.h"

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

#if (QT_VERSION >= QT_VERSION_CHECK(5, 4, 0))
ViewerWidget::ViewerWidget(QWidget* parent, Qt::WindowFlags flags)
  : QOpenGLWidget(parent, flags)
{
#else
ViewerWidget::ViewerWidget(QWidget* parent, Qt::WindowFlags flags)
  : QGLWidget(parent, nullptr, flags)
{
#endif
  mpGraphicsWindow = new osgViewer::GraphicsWindowEmbedded(x(), y(), width(), height());
  mpViewer = new Viewer;
  mpSceneView = new osgViewer::View();
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

void ViewerWidget::paintEvent(QPaintEvent* /* paintEvent */)
{
  makeCurrent();
  QPainter painter(this);
  painter.setRenderHint(QPainter::Antialiasing);
  paintGL();
  painter.end();
  doneCurrent();
}

void ViewerWidget::paintGL()
{
  mpViewer->frame();
}

void ViewerWidget::resizeGL(int width, int height)
{
  getEventQueue()->windowResize(x(), y(), width, height);
  mpGraphicsWindow->resized(x(), y(), width, height);
  onResize(width, height);
}

void ViewerWidget::keyPressEvent(QKeyEvent *event)
{
  QString keyString = event->text();
  const char* keyData = keyString.toLocal8Bit().data();
  getEventQueue()->keyPress(osgGA::GUIEventAdapter::KeySymbol(*keyData));
}

void ViewerWidget::keyReleaseEvent(QKeyEvent *event)
{
  QString keyString = event->text();
  const char* keyData = keyString.toLocal8Bit().data();
  getEventQueue()->keyRelease(osgGA::GUIEventAdapter::KeySymbol(*keyData));
}

void ViewerWidget::mouseMoveEvent(QMouseEvent *event)
{
  getEventQueue()->mouseMotion(static_cast<float>(event->x()), static_cast<float>(event->y()));
}

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
      break;
    default:
      break;
  }
  getEventQueue()->mouseButtonPress(static_cast<float>(event->x()), static_cast<float>(event->y()), button);
}

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
      break;
    default:
      break;
  }
  getEventQueue()->mouseButtonRelease(static_cast<float>(event->x()), static_cast<float>(event->y()), button);
}

void ViewerWidget::wheelEvent(QWheelEvent *event)
{
  event->accept();
  int delta = event->delta();
  osgGA::GUIEventAdapter::ScrollingMotion motion = delta > 0 ? osgGA::GUIEventAdapter::SCROLL_UP : osgGA::GUIEventAdapter::SCROLL_DOWN;
  getEventQueue()->mouseScroll(motion);
}

bool ViewerWidget::event(QEvent *event)
{
#if (QT_VERSION >= QT_VERSION_CHECK(5, 4, 0))
  bool handled = QOpenGLWidget::event(event);
#else
  bool handled = QGLWidget::event(event);
#endif
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

void ViewerWidget::onResize(int width, int height)
{
  std::vector<osg::Camera*> cameras;
  mpViewer->getCameras(cameras);

  /*! @todo Handle the resize case */
}

osgGA::EventQueue* ViewerWidget::getEventQueue() const
{
  osgGA::EventQueue* eventQueue = mpGraphicsWindow->getEventQueue();
  assert (eventQueue != 0);
  return eventQueue;
}
