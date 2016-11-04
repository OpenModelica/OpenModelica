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

#ifndef ANIMATIONWINDOW_H
#define ANIMATIONWINDOW_H

#include <iostream>
#include <string>

#include <osg/GraphicsContext>
#include <osg/io_utils>
#include <osg/MatrixTransform>
#include <osg/Vec3>
#include <osgDB/ReadFile>
#include <osgGA/MultiTouchTrackballManipulator>
#include <../../osgQt/OMEdit_GraphicsWindowQt.h>
#include <osg/Version>
#include <osgViewer/CompositeViewer>
#include <osgViewer/View>
#include <osgViewer/ViewerEventHandlers>

#include "AnimationUtil.h"
#include "MainWindow.h"
#include "OMPlot.h"
#include "Visualizer.h"
#include "VisualizerMAT.h"
#include "VisualizerCSV.h"

class MainWindow;
class PlotWindowContainer;

class AnimationWindow : public QMainWindow, public osgViewer::CompositeViewer
{
  Q_OBJECT
public:
  AnimationWindow(PlotWindowContainer *pPlotWindowContainer);
  QWidget* setupViewWidget();
  void loadVisualization();
  double getTimeFraction();
  double getVisTime();
  void setPathName(std::string name);
  void setFileName(std::string name);
  void openAnimationFile(QString fileName);
public slots:
  void sliderSetTimeSlotFunction(int value);
  void playSlotFunction();
  void pauseSlotFunction();
  void initSlotFunction();
  void renderSlotFunction();
  void chooseAnimationFileSlotFunction();
  void setSpeedUpSlotFunction();
  void jumpToTimeSlotFunction();
  void updateSceneFunction();
  void resetCamera();
  void cameraPositionXY();
  void cameraPositionXZ();
  void cameraPositionYZ();
  void setPerspective(int value);
private:
  PlotWindowContainer *mpPlotWindowContainer;
  //to be animated
  std::string mPathName;
  std::string mFileName;
  //osg viewer scene
  osgViewer::View* mpSceneView;
  //stores the data for the shapes, time management, functionality for updating the values(mat/fmu) etc.
  VisualizerAbstract* mpVisualizer;
  //widgets
  QWidget* mpViewerWidget;
  QTimer* mpUpdateTimer;
  QToolBar* mpAnimationToolBar;
  QSlider* mpAnimationSlider;
  QLabel *mpAnimationTimeLabel;
  QLineEdit *mpTimeTextBox;
  Label *mpAnimationSpeedLabel;
  QLineEdit *mpSpeedTextBox;
  QComboBox *mpPerspectiveDropDownBox;
  //actions
  QAction *mpAnimationChooseFileAction;
  QAction *mpAnimationInitializeAction;
  QAction *mpAnimationPlayAction;
  QAction *mpAnimationPauseAction;
};

#endif // ANIMATIONWINDOW_H
