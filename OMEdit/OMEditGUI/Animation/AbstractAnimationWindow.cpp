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

#include <osg/GraphicsContext>
#include <osg/io_utils>
#include <osg/MatrixTransform>
#include <osg/Vec3>
#include <osgDB/ReadFile>
#include <osgGA/MultiTouchTrackballManipulator>
#include <osg/Version>
#include <osgViewer/View>
#include <osgViewer/ViewerEventHandlers>
#include <../../osgQt/OMEdit_GraphicsWindowQt.h>

#include "AbstractAnimationWindow.h"
#include "Modeling/MessagesWidget.h"
#include "Options/OptionsDialog.h"
#include "Modeling/MessagesWidget.h"
#include "Plotting/PlotWindowContainer.h"
#include "Visualizer.h"
#include "VisualizerMAT.h"
#include "VisualizerCSV.h"
#include "VisualizerFMU.h"

AbstractAnimationWindow::AbstractAnimationWindow(QWidget *pParent)
  : QMainWindow(pParent),
    osgViewer::CompositeViewer(),
    mPathName(""),
    mFileName(""),
    mpSceneView(new osgViewer::View()),
    mpVisualizer(nullptr),
    mpViewerWidget(nullptr),
    mpAnimationToolBar(new QToolBar(QString("Animation Toolbar"),this)),
    mpFMUSettingsDialog(nullptr),
    mpAnimationChooseFileAction(nullptr),
    mpAnimationInitializeAction(nullptr),
    mpAnimationPlayAction(nullptr),
    mpAnimationPauseAction(nullptr)
{
  // to distinguish this widget as a subwindow among the plotwindows
  this->setObjectName(QString("animationWidget"));
  // the osg threading model
  setThreadingModel(osgViewer::CompositeViewer::SingleThreaded);
  // disable the default setting of viewer.done() by pressing Escape.
  setKeyEventSetsDone(0);
  //the viewer widget
  mpViewerWidget = setupViewWidget();
  // we need to set the minimum height so that visualization window is still shown when we cascade windows.
  mpViewerWidget->setMinimumHeight(100);
  // let render timer do a render frame at every tick
  mRenderFrameTimer.setInterval(100);
  QObject::connect(&mRenderFrameTimer, SIGNAL(timeout()), this, SLOT(renderFrame()));
  mRenderFrameTimer.start();
  // toolbar icon size
  int toolbarIconSize = OptionsDialog::instance()->getGeneralSettingsPage()->getToolbarIconSizeSpinBox()->value();
  mpAnimationToolBar->setIconSize(QSize(toolbarIconSize, toolbarIconSize));
  addToolBar(Qt::TopToolBarArea, mpAnimationToolBar);
  // Viewer layout
  QGridLayout *pGridLayout = new QGridLayout;
  pGridLayout->setContentsMargins(0, 0, 0, 0);
  pGridLayout->addWidget(mpViewerWidget);
  // add the viewer to the frame for boxed rectangle around it.
  QFrame *pCentralWidgetFrame = new QFrame;
  pCentralWidgetFrame->setFrameStyle(QFrame::StyledPanel);
  pCentralWidgetFrame->setLayout(pGridLayout);
  setCentralWidget(pCentralWidgetFrame);
}

/*!
 * \brief AbstractAnimationWindow::openAnimationFile
 * \param fileName
 */
void AbstractAnimationWindow::openAnimationFile(QString fileName)
{
  std::string file = fileName.toStdString();
  if (file.compare("")) {
    std::size_t pos = file.find_last_of("/\\");
    mPathName = file.substr(0, pos + 1);
    mFileName = file.substr(pos + 1, file.length());
    //std::cout<<"file "<<mFileName<<"   path "<<mPathName<<std::endl;
    loadVisualization();
    // start the widgets
    mpAnimationInitializeAction->setEnabled(true);
    mpAnimationPlayAction->setEnabled(true);
    mpAnimationPauseAction->setEnabled(true);
    mpAnimationSlider->setEnabled(true);
    bool state = mpAnimationSlider->blockSignals(true);
    mpAnimationSlider->setValue(0);
    mpAnimationSlider->blockSignals(state);
    mpSpeedComboBox->setEnabled(true);
    mpTimeTextBox->setEnabled(true);
    mpTimeTextBox->setText(QString::number(mpVisualizer->getTimeManager()->getStartTime()));
    state = mpPerspectiveDropDownBox->blockSignals(true);
    mpPerspectiveDropDownBox->setCurrentIndex(0);
    mpPerspectiveDropDownBox->blockSignals(state);
  }
}

/*!
 * \brief AbstractAnimationWindow::openmpFMUSettingsDialog
 * opens a dialog to set the settings for the FMU visualization
 */
void AbstractAnimationWindow::openFMUSettingsDialog()
{
  //create dialog
  mpFMUSettingsDialog = new QDialog(this);
  mpFMUSettingsDialog->setWindowTitle("FMU settings");
  mpFMUSettingsDialog->setWindowIcon(QIcon(":/Resources/icons/animation.svg"));
  //the layouts
  QVBoxLayout *mainLayout = new QVBoxLayout;
  QHBoxLayout *simulationLayout = new QHBoxLayout;
  QVBoxLayout *leftSimLayout = new QVBoxLayout;
  QVBoxLayout *rightSimLayout = new QVBoxLayout;
  //the widgets
  QLabel *simulationLabel = new QLabel(tr("Simulation settings"));
  QPushButton *okButton = new QPushButton(tr("OK"));
  //solver settings
  QLabel *solverLabel = new QLabel(tr("solver"));
  QComboBox *solverComboBox = new QComboBox(mpFMUSettingsDialog);
  solverComboBox->addItem(QString("euler forward"));
  //assemble
  mainLayout->addWidget(simulationLabel);
  mainLayout->addLayout(simulationLayout);
  simulationLayout->addLayout(leftSimLayout);
  simulationLayout->addLayout(rightSimLayout);
  leftSimLayout->addWidget(solverLabel);
  rightSimLayout->addWidget(solverComboBox);
  mainLayout->addWidget(okButton);
  mpFMUSettingsDialog->setLayout(mainLayout);
  //connections
  connect(okButton, SIGNAL(clicked()),this, SLOT(saveSimSettings()));
  mpFMUSettingsDialog->show();
}

void AbstractAnimationWindow::createActions()
{
  mpPerspectiveDropDownBox = new QComboBox(this);
  //mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective0.svg"), QString("to home position"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective2.svg"),QString("normal to x-y plane"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective1.svg"),QString("normal to y-z plane"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective3.svg"),QString("normal to x-z plane"));
  connect(mpPerspectiveDropDownBox, SIGNAL(activated(int)), this, SLOT(setPerspective(int)));
}

/*!
 * \brief AbstractAnimationWindow::setupViewWidget
 * creates the widget for the osg viewer
 * \return the widget
 */
QWidget* AbstractAnimationWindow::setupViewWidget()
{
  //desktop resolution
  QRect rec = QApplication::desktop()->screenGeometry();
  int height = rec.height();
  int width = rec.width();
  //int height = 1000;
  //int width = 2000;
  //get context
  osg::ref_ptr<osg::DisplaySettings> ds = osg::DisplaySettings::instance().get();
  osg::ref_ptr<osg::GraphicsContext::Traits> traits = new osg::GraphicsContext::Traits();
  traits->windowName = "";
  traits->windowDecoration = false;
  traits->x = 0;
  traits->y = 0;
  traits->width = width;
  traits->height = height;
  traits->doubleBuffer = true;
  traits->alpha = ds->getMinimumNumAlphaBits();
  traits->stencil = ds->getMinimumNumStencilBits();
  traits->sampleBuffers = ds->getMultiSamples();
  traits->samples = ds->getNumMultiSamples();
  osg::ref_ptr<osgQt::GraphicsWindowQt> gw = new osgQt::GraphicsWindowQt(traits.get());
  //add a scene to viewer
  addView(mpSceneView);
  //get the viewer widget
  osg::ref_ptr<osg::Camera> camera = mpSceneView->getCamera();
  camera->setGraphicsContext(gw);
  camera->setClearColor(osg::Vec4(0.95, 0.95, 0.95, 1.0));
  //camera->setViewport(new osg::Viewport(0, 0, traits->width, traits->height));
  camera->setViewport(new osg::Viewport(0, 0, width, height));
  camera->setProjectionMatrixAsPerspective(30.0f, static_cast<double>(traits->width/2) / static_cast<double>(traits->height/2), 1.0f, 10000.0f);
  mpSceneView->addEventHandler(new osgViewer::StatsHandler());
  // reverse the mouse wheel zooming
  osgGA::MultiTouchTrackballManipulator *pMultiTouchTrackballManipulator = new osgGA::MultiTouchTrackballManipulator();
  pMultiTouchTrackballManipulator->setWheelZoomFactor(-pMultiTouchTrackballManipulator->getWheelZoomFactor());
  mpSceneView->setCameraManipulator(pMultiTouchTrackballManipulator);
#if OSG_VERSION_GREATER_OR_EQUAL(3,4,0)
  gw->setTouchEventsEnabled(true);
#endif
  return gw->getGLWidget();
}

/*!
 * \brief AbstractAnimationWindow::loadVisualization
 * loads the data and the xml scene description
 */
void AbstractAnimationWindow::loadVisualization()
{
  VisType visType = VisType::NONE;
  // Get visualization type.
  if (isFMU(mFileName)) {
    visType = VisType::FMU;
  } else if (isMAT(mFileName)) {
    visType = VisType::MAT;
  } else if (isCSV(mFileName)) {
    visType = VisType::CSV;
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, tr("Unknown visualization type."),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
  //init visualizer
  if (visType == VisType::MAT) {
    mpVisualizer = new VisualizerMAT(mFileName, mPathName);
  } else if (visType == VisType::CSV) {
    mpVisualizer = new VisualizerCSV(mFileName, mPathName);
  } else if (visType == VisType::FMU) {
    mpVisualizer = new VisualizerFMU(mFileName, mPathName);
  } else {
    QString msg = tr("Could not init %1 %2.").arg(QString(mPathName.c_str())).arg(QString(mFileName.c_str()));
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                          Helper::errorLevel));
  }
  //load the XML File, build osgTree, get initial values for the shapes
  bool xmlExists = checkForXMLFile(mFileName, mPathName);
  if (!xmlExists) {
    QString msg = tr("Could not find the visual XML file %1.").arg(QString(assembleXMLFileName(mFileName, mPathName).c_str()));
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                          Helper::errorLevel));
  } else {
    connect(mpVisualizer->getTimeManager()->getUpdateSceneTimer(), SIGNAL(timeout()), SLOT(updateScene()));
    mpVisualizer->initData();
    mpVisualizer->setUpScene();
    mpVisualizer->initVisualization();
    //add scene for the chosen visualization
    mpSceneView->setSceneData(mpVisualizer->getOMVisScene()->getScene().getRootNode());
  }
  //FMU settings dialog
  if (visType == VisType::FMU) {
    //openFMUSettingsDialog();
  }
  //add window title
  this->setWindowTitle(QString::fromStdString(mFileName));
  //jump to xy-view
  cameraPositionXY();
}

/*!
 * \brief AbstractAnimationWindow::sliderSetTimeSlotFunction
 * slot function for the time slider to jump to the adjusted point of time
 */
void AbstractAnimationWindow::sliderSetTimeSlotFunction(int value)
{
  float time = (mpVisualizer->getTimeManager()->getEndTime()
                - mpVisualizer->getTimeManager()->getStartTime())
                * (float) (value / 100.0);
  mpVisualizer->getTimeManager()->setVisTime(time);
  mpTimeTextBox->setText(QString::number(mpVisualizer->getTimeManager()->getVisTime()));
  mpVisualizer->updateScene(time);
}

/*!
 * \brief AbstractAnimationWindow::playSlotFunction
 * slot function for the play button
 */
void AbstractAnimationWindow::playSlotFunction()
{
  mpVisualizer->getTimeManager()->setPause(false);
}

/*!
 * \brief AbstractAnimationWindow::pauseSlotFunction
 * slot function for the pause button
 */
void AbstractAnimationWindow::pauseSlotFunction()
{
  mpVisualizer->getTimeManager()->setPause(true);
}

/*!
 * \brief AbstractAnimationWindow::initSlotFunction
 * slot function for the init button
 */
void AbstractAnimationWindow::initSlotFunction()
{
  mpVisualizer->initVisualization();
  bool state = mpAnimationSlider->blockSignals(true);
  mpAnimationSlider->setValue(0);
  mpAnimationSlider->blockSignals(state);
  mpTimeTextBox->setText(QString::number(mpVisualizer->getTimeManager()->getVisTime()));
}

/*!
 * \brief AbstractAnimationWindow::updateSceneFunction
 * updates the visualization objects
 */
void AbstractAnimationWindow::updateScene()
{
  if (!(mpVisualizer == NULL)) {
    //set time label
    if (!mpVisualizer->getTimeManager()->isPaused()) {
      mpTimeTextBox->setText(QString::number(mpVisualizer->getTimeManager()->getVisTime()));
      // set time slider
      if (mpVisualizer->getVisType() != VisType::FMU) {
        int time = mpVisualizer->getTimeManager()->getTimeFraction();
        bool state = mpAnimationSlider->blockSignals(true);
        mpAnimationSlider->setValue(time);
        mpAnimationSlider->blockSignals(state);
      }
    }
    //update the scene
    mpVisualizer->sceneUpdate();
  }
}

/*!
 * \brief AbstractAnimationWindow::renderFrame
 * renders the osg viewer
 */
void AbstractAnimationWindow::renderFrame()
{
  frame();
}

/*!
 * \brief AbstractAnimationWindow::animationFileSlotFunction
 * opens a file dialog to chooes an animation
 */
void AbstractAnimationWindow::chooseAnimationFileSlotFunction()
{
  QString fileName = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseFile),
                                                       NULL, Helper::visualizationFileTypes, NULL);
  if (fileName.isEmpty()) {
    return;
  }
  openAnimationFile(fileName);
}

/*!
 * \brief AbstractAnimationWindow::setSpeedUpSlotFunction
 * slot function to set the user input speed up
 */
void AbstractAnimationWindow::setSpeedSlotFunction()
{
  QString str = mpSpeedComboBox->lineEdit()->text();
  bool isFloat = true;
  double value = str.toFloat(&isFloat);
  if (isFloat && value > 0.0) {
    mpVisualizer->getTimeManager()->setSpeedUp(value);
  }
}

/*!
 * \brief AbstractAnimationWindow::jumpToTimeSlotFunction
 * slot function to jump to the user input point of time
 */
void AbstractAnimationWindow::jumpToTimeSlotFunction()
{
  QString str = mpTimeTextBox->text();
  bool isFloat = true;
  double start = mpVisualizer->getTimeManager()->getStartTime();
  double end = mpVisualizer->getTimeManager()->getEndTime();
  double value = str.toFloat(&isFloat);
  if (isFloat && value >= 0.0) {
    if (value < start) {
      value = start;
    } else if (value > end) {
      value = end;
    }
    mpVisualizer->getTimeManager()->setVisTime(value);
    bool state = mpAnimationSlider->blockSignals(true);
    mpAnimationSlider->setValue(mpVisualizer->getTimeManager()->getTimeFraction());
    mpAnimationSlider->blockSignals(state);
    mpVisualizer->updateScene(value);
  }
}

/*!
 * \brief AbstractAnimationWindow::resetCamera
 * resets the camera position
 */
void AbstractAnimationWindow::resetCamera()
{
  mpSceneView->home();
}

/*!
 * \brief AbstractAnimationWindow::cameraPositionXY
 * sets the camera position to XY
 */
void AbstractAnimationWindow::cameraPositionXY()
{
  resetCamera();
  //the new orientation
  osg::Matrix3 newOrient = osg::Matrix3(1, 0, 0, 0, 1, 0, 0, 0, 1);
  osg::ref_ptr<osgGA::CameraManipulator> manipulator = mpSceneView->getCameraManipulator();
  osg::Matrixd mat = manipulator->getMatrix();
  //assemble
  mat = osg::Matrixd(newOrient(0, 0), newOrient(0, 1), newOrient(0, 2), 0,
                     newOrient(1, 0), newOrient(1, 1), newOrient(1, 2), 0,
                     newOrient(2, 0), newOrient(2, 1), newOrient(2, 2), 0,
                     abs(mat(3, 0)), abs(mat(3, 2)), abs(mat(3, 1)), 1);
  manipulator->setByMatrix(mat);
}

/*!
 * \brief AbstractAnimationWindow::cameraPositionXZ
 * sets the camera position to XZ
 */
void AbstractAnimationWindow::cameraPositionXZ()
{
  //to get the correct distance of the bodies, reset to home position and use the values of this camera position
  resetCamera();
  //the new orientation
  osg::Matrix3 newOrient = osg::Matrix3(1, 0, 0, 0, 0, 1, 0, -1, 0);
  osg::ref_ptr<osgGA::CameraManipulator> manipulator = mpSceneView->getCameraManipulator();
  osg::Matrixd mat = manipulator->getMatrix();
  //assemble
  mat = osg::Matrixd(newOrient(0, 0), newOrient(0, 1), newOrient(0, 2), 0,
                     newOrient(1, 0), newOrient(1, 1), newOrient(1, 2), 0,
                     newOrient(2, 0), newOrient(2, 1), newOrient(2, 2), 0,
                     abs(mat(3, 0)), -abs(mat(3, 1)), abs(mat(3, 2)), 1);
  manipulator->setByMatrix(mat);
}

/*!
 * \brief AbstractAnimationWindow::cameraPositionYZ
 * sets the camera position to YZ
 */
void AbstractAnimationWindow::cameraPositionYZ()
{
  //to get the correct distance of the bodies, reset to home position and use the values of this camera position
  resetCamera();
  //the new orientation
  osg::Matrix3 newOrient = osg::Matrix3(0, 1, 0, 0, 0, 1, 1, 0, 0);
  osg::ref_ptr<osgGA::CameraManipulator> manipulator = mpSceneView->getCameraManipulator();
  osg::Matrixd mat = manipulator->getMatrix();
  //assemble
  mat = osg::Matrixd(newOrient(0, 0), newOrient(0, 1), newOrient(0, 2), 0,
                     newOrient(1, 0), newOrient(1, 1), newOrient(1, 2), 0,
                     newOrient(2, 0), newOrient(2, 1), newOrient(2, 2), 0,
                     abs(mat(3, 1)), abs(mat(3, 2)), abs(mat(3, 0)), 1);
  manipulator->setByMatrix(mat);
}

/*!
 * \brief AbstractAnimationWindow::setPerspective
 * gets the identifier for the chosen perspective and calls the functions
 */
void AbstractAnimationWindow::setPerspective(int value)
{
  switch(value) {
    case 0:
      cameraPositionXY();
      break;
    case 1:
      cameraPositionYZ();
      break;
    case 2:
      cameraPositionXZ();
      break;
  }
}

/*!
 * \brief AbstractAnimationWindow::saveSimSettings
 */
void AbstractAnimationWindow::saveSimSettings()
{
  std::cout<<"save simulation settings"<<std::endl;
  mpFMUSettingsDialog->close();
}
