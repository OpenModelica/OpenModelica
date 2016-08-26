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
 * @author Volker Waurich <volker.waurich@tu-dresden.de>
 */

#ifndef ANIMATIONWINDOWCONTAINER_H
#define ANIMATIONWINDOWCONTAINER_H

#include "AnimationUtil.h"
#include "MainWindow.h"
#include "Visualizer.h"

#include <iostream>
#include <string>

#include <osg/GraphicsContext>
#include <osg/io_utils>
#include <osg/MatrixTransform>
#include <osg/Vec3>
#include <osgDB/ReadFile>
#include <osgGA/MultiTouchTrackballManipulator>
#include <osgQt/GraphicsWindowQt>
#include <osgViewer/CompositeViewer>
#include <osgViewer/View>
#include <osgViewer/ViewerEventHandlers>



class MainWindow;

class AnimationWindowContainer : public QWidget, public osgViewer::CompositeViewer
{
  Q_OBJECT
  public:
    AnimationWindowContainer(MainWindow *pParent);
    QWidget* setupAnimationWidgets();
    QWidget* setupViewWidget(osg::ref_ptr<osg::Node> rootNode);
    void showWidgets();
    void loadVisualization();
  public slots:
    void sliderSetTimeSlotFunction(int value);
    void moveTimeSliderSlotFunction();
    void playSlotFunction();
    void pauseSlotFunction();
    void initSlotFunction();
    void renderSlotFunction();
    void chooseAnimationFileSlotFunction();
    void updateSceneFunction();
  private:
    //to be animated
    std::string _pathName;
    std::string _fileName;
    //osg viewer scene
    osgViewer::View* _sceneView;
    //stores the data for the shapes, time management, functionality for updating the values(mat/fmu) etc.
    VisualizerAbstract* _visualizer;
    //widgets
    QWidget* _viewerWidget;
    QWidget* _topWidget;
    QPushButton* _visFileButton;
    QPushButton* _playButton;
    QPushButton* _pauseButton;
    QPushButton* _initButton;
    QSlider* _timeSlider;
    QLabel* _timeDisplay;
    QLabel* _RTFactorDisplay;
    QTimer* _updateTimer;
};

#endif // ANIMATIONWINDOWCONTAINER_H
