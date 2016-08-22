/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

#ifndef ANIMATIONWINDOWCONTAINER_H
#define ANIMATIONWINDOWCONTAINER_H

#include "MainWindow.h"

#include <osgViewer/CompositeViewer>
#include <osgViewer/View>
#include <osgDB/ReadFile>
#include <osgGA/MultiTouchTrackballManipulator>
#include <osgViewer/ViewerEventHandlers>
#include <osg/Vec3>
#include <osg/io_utils>
#include <osg/MatrixTransform>
#include <osg/GraphicsContext>

#include <QtOpenGL/QGLWidget>
//#include <osgQt/GraphicsWindowQt>



class MainWindow;

class AnimationWindowContainer : public MdiArea, public osgViewer::CompositeViewer
{
  Q_OBJECT
public:
  AnimationWindowContainer(MainWindow *pParent);
  QString getUniqueName(QString name = QString("Animation"), int number = 4);
  QSlider* _timeSlider;
  //osg::ref_ptr<osgQt::GraphicsWindowQt> createGraphicsWindow(int x, int y, int w, int h, const std::string& name, bool windowDecoration)

  osgViewer::View* _sceneView;
  osg::ref_ptr<osg::GraphicsContext::Traits> traits;
};

#endif // ANIMATIONWINDOWCONTAINER_H
