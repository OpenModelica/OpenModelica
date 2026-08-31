/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * @author Volker Waurich <volker.waurich@tu-dresden.de>
 */

#ifndef ABSTRACTANIMATIONWINDOW_H
#define ABSTRACTANIMATIONWINDOW_H

#include <QMainWindow>
#include <QToolBar>
#include <QSlider>
#include <QLineEdit>
#include <QComboBox>
#include <QTimer>
#include <QDoubleSpinBox>
#include <QLabel>

// FMUSettingsDialog pulls in VisualizationFMU (fmilib), unavailable on wasm.
#if !defined(__EMSCRIPTEN__)
#include "FMUSettingsDialog.h"
#endif

class VisualizationAbstract;
#if defined(OMEDIT_ANIMATION_QUICK3D)
class Quick3DViewerWidget;
#else
class ViewerWidget;
#endif
class Label;

class DoubleSpinBoxIndexed : public QDoubleSpinBox
{
  Q_OBJECT

public:
  explicit DoubleSpinBoxIndexed(QWidget *pParent, int idx);
  int mStateIdx;
signals:
  void valueChangedFrom(double val, int idx);
private slots:
   void slotForwardValueChanged(double val);
private slots:

};

class AbstractAnimationWindow : public QMainWindow
{
  Q_OBJECT
public:
  AbstractAnimationWindow(QWidget *pParent);
#if !defined(OMEDIT_ANIMATION_QUICK3D)
  ViewerWidget* getViewerWidget() {return mpViewerWidget;}
#endif
  VisualizationAbstract* getVisualization() {return mpVisualization;}
  void openAnimationFile(QString fileName, bool stashCamera=false);
  virtual void createActions();
  void clearView();
  void stashView();
  void popView();
private:
  bool loadVisualization();
protected:
  //to be animated
  std::string mPathName;
  std::string mFileName;
  //stores the data for the visualizers, time management, functionality for updating the values(mat/fmu) etc.
  VisualizationAbstract* mpVisualization;
  //widgets
#if defined(OMEDIT_ANIMATION_QUICK3D)
  Quick3DViewerWidget *mpViewerWidget;
#else
  ViewerWidget *mpViewerWidget;
#endif
  QToolBar* mpAnimationToolBar;
  QDockWidget* mpAnimationParameterDockerWidget;
  QAction *mpAnimationChooseFileAction;
  QAction *mpAnimationInitializeAction;
  QAction *mpAnimationPlayAction;
  QAction *mpAnimationPauseAction;
  QAction *mpInteractiveControlAction;
  QAction *mpAnimationRepeatAction;
  QSlider* mpAnimationSlider;
  Label *mpAnimationTimeLabel;
  QLineEdit *mpTimeTextBox;
  Label *mpAnimationSpeedLabel;
  QComboBox *mpSpeedComboBox;
  QComboBox *mpPerspectiveDropDownBox;
  QAction *mpRotateCameraLeftAction;
  QAction *mpRotateCameraRightAction;
  QVector<DoubleSpinBoxIndexed*> mSpinBoxVector;
  QVector<QLabel*> mStateLabels;
#if !defined(OMEDIT_ANIMATION_QUICK3D)
  osg::Matrixd mStashedViewMatrix;
#endif
  bool mCameraInitialized;
  int mSliderRange;

  void resetCamera();
  void cameraPositionIsometric();
  void cameraPositionSide();
  void cameraPositionFront();
  void cameraPositionTop();
  double computeDistanceToOrigin();
#if !defined(__EMSCRIPTEN__)
  void openFMUSettingsDialog(VisualizationFMU *pVisualizationFMU);
#endif
  void updateControlPanelValues();
  void updateSceneTime(double time);

public slots:
  void updateScene();
  void chooseAnimationFileSlotFunction();
  void initSlotFunction();
  void playSlotFunction();
  void pauseSlotFunction();
  void repeatSlotFunciton(bool checked);
  void sliderSetTimeSlotFunction(int value);
  void jumpToTimeSlotFunction();
  void setSpeedSlotFunction();
  void setPerspective(int value);
  void rotateCameraLeft();
  void rotateCameraRight();
  void initInteractiveControlPanel();
  void setStateSolveSystem(double val, int idx);
};

#endif // ABSTRACTANIMATIONWINDOW_H
