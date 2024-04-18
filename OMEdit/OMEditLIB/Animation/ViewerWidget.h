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

#ifndef VIEWERWIDGET_H
#define VIEWERWIDGET_H

#include <QOpenGLContext> // must be included before OSG headers

#include <osg/ref_ptr>
#include <osgViewer/GraphicsWindow>
#include <osgViewer/CompositeViewer>

#include <OpenThreads/Mutex>

#include <iostream>

#include <QMenu>

#include "AbstractAnimationWindow.h"
#include "AnimationUtil.h"
#include "Util/Helper.h"

/*!
 * \note We need to create two files with same class name since Qt meta object compiler doesn't handle ifdef.
 * OpenGLWidget.h uses QOpenGLWidget and GLWidget.h uses QGLWidget
 */
#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 4, 0))
#include "OpenGLWidget.h"
#else
#include "GLWidget.h"
#endif

/*!
 * This subclassing allows us to remove the annoying automatic
 * setting of the CPU affinity to core 0 by osgViewer::ViewerBase,
 * osgViewer::CompositeViewer's base class.
 */
class Viewer : public osgViewer::CompositeViewer
{
public:
  virtual void setUpThreading();
};

class ViewerWidget : public GLWidget
{
  Q_OBJECT
public:
  ViewerWidget(QWidget *pParent = 0, Qt::WindowFlags flags = Qt::WindowFlags());
  osgViewer::View* getSceneView() {return mpSceneView;}
  OpenThreads::Mutex* getFrameMutex() {return mpFrameMutex;}
  AbstractVisualizerObject* getSelectedVisualizer() {return mpSelectedVisualizer;}
  void setSelectedVisualizer(AbstractVisualizerObject* visualizer) {mpSelectedVisualizer = visualizer;}
  void pickVisualizer(int x, int y);
  void frame();
protected:
  virtual void paintEvent(QPaintEvent *paintEvent) override;
  virtual void paintGL() override;
  virtual void resizeGL(int width, int height) override;
  virtual void keyPressEvent(QKeyEvent *event) override;
  virtual void keyReleaseEvent(QKeyEvent *event) override;
  virtual void mouseMoveEvent(QMouseEvent *event) override;
  virtual void mousePressEvent(QMouseEvent *event) override;
  virtual void mouseReleaseEvent(QMouseEvent *event) override;
  virtual void wheelEvent(QWheelEvent *event) override;
  virtual bool event(QEvent* event) override;
  void showVisualizerPickContextMenu(const QPoint& pos);
private:
  osgGA::EventQueue* getEventQueue() const;
  osg::ref_ptr<osgViewer::GraphicsWindowEmbedded> mpGraphicsWindow;
  osg::ref_ptr<Viewer> mpViewer;
  osgViewer::View* mpSceneView;
  OpenThreads::Mutex* mpFrameMutex;
  AbstractAnimationWindow* mpAnimationWidget;
  AbstractVisualizerObject* mpSelectedVisualizer;
  unsigned int mMouseButton = 0;
public slots:
  void changeVisualizerTransparency();
  void makeVisualizerInvisible();
  void changeVisualizerColor();
  void changeVisualizerSpec();
  void applyCheckerTexture();
  void applyCustomTexture();
  void removeTexture();
  void resetVisualPropertiesForAllVisualizers();
};

#endif
