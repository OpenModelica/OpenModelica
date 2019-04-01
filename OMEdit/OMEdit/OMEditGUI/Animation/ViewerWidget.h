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

#include <osg/ref_ptr>
#include <osgViewer/GraphicsWindow>
#include <osgViewer/CompositeViewer>

#include<iostream>

#include<QMenu>

#include "AbstractAnimationWindow.h"
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
  ViewerWidget(QWidget *pParent = 0, Qt::WindowFlags flags = 0);
  osgViewer::View* getSceneView() {return mpSceneView;}
  std::string getSelectedShape() {return mSelectedShape;}
  void setSelectedShape(std::string shape) {mSelectedShape = shape;}
  void pickShape(int x, int y);
protected:
  virtual void paintEvent(QPaintEvent *paintEvent);
  virtual void paintGL();
  virtual void resizeGL(int width, int height);
  virtual void keyPressEvent(QKeyEvent *event);
  virtual void keyReleaseEvent(QKeyEvent *event);
  virtual void mouseMoveEvent(QMouseEvent *event);
  virtual void mousePressEvent(QMouseEvent *event);
  virtual void mouseReleaseEvent(QMouseEvent *event);
  virtual void wheelEvent(QWheelEvent *event);
  virtual bool event(QEvent* event);
  void showShapePickContextMenu(const QPoint& pos);
private:
  osgGA::EventQueue* getEventQueue() const;
  osg::ref_ptr<osgViewer::GraphicsWindowEmbedded> mpGraphicsWindow;
  osg::ref_ptr<Viewer> mpViewer;
  osgViewer::View* mpSceneView;
  std::string mSelectedShape;
  AbstractAnimationWindow *mpAnimationWidget;
public slots:
  void changeShapeTransparency();
  void removeTransparencyForAllShapes();
  void makeShapeInvisible();
  void applyCheckTexture();
  void applyCustomTexture();
  void removeTexture();
  void changeShapeColor();

};

#endif // VIEWERWIDGET_H
