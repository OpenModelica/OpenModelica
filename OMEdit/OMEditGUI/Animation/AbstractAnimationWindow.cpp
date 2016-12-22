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
 * @author Volker Waurich <volker.waurich@tu-dresden.de>
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

/*!
 * \class AbstractAnimationWindow
 * \brief Abstract animation class defines a QMainWindow for animation.
 */
/*!
 * \brief AbstractAnimationWindow::AbstractAnimationWindow
 * \param pParent
 */
AbstractAnimationWindow::AbstractAnimationWindow(QWidget *pParent)
  : QMainWindow(pParent),
    osgViewer::CompositeViewer(),
    mPathName(""),
    mFileName(""),
    mpSceneView(new osgViewer::View()),
    mpVisualizer(nullptr),
    mpViewerWidget(nullptr),
    mpAnimationToolBar(new QToolBar(QString("Animation Toolbar"),this)),
    mpAnimationChooseFileAction(nullptr),
    mpAnimationInitializeAction(nullptr),
    mpAnimationPlayAction(nullptr),
    mpAnimationPauseAction(nullptr),
    mpAnimationSlider(nullptr),
    mpAnimationTimeLabel(nullptr),
    mpTimeTextBox(nullptr),
    mpAnimationSpeedLabel(nullptr),
    mpSpeedComboBox(nullptr),
    mpPerspectiveDropDownBox(nullptr),
    mpRotateCameraLeftAction(nullptr),
    mpRotateCameraRightAction(nullptr),
    mpFMUSettingsDialog(nullptr)
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
    /* Only use isometric view as default for csv file type.
     * Otherwise use side view as default which suits better for Modelica models.
     */
    if (isCSV(mFileName)) {
      mpPerspectiveDropDownBox->setCurrentIndex(0);
      cameraPositionIsometric();
    } else {
      mpPerspectiveDropDownBox->setCurrentIndex(1);
      cameraPositionSide();
    }
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
  // perspective drop down
  mpPerspectiveDropDownBox = new QComboBox(this);
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective0.svg"), QString("Isometric"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective1.svg"),QString("Side"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective2.svg"),QString("Front"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective3.svg"),QString("Top"));
  connect(mpPerspectiveDropDownBox, SIGNAL(activated(int)), this, SLOT(setPerspective(int)));
  // rotate camera left action
  mpRotateCameraLeftAction = new QAction(QIcon(":/Resources/icons/rotateCameraLeft.svg"), tr("Rotate Left"), this);
  mpRotateCameraLeftAction->setStatusTip(tr("Rotates the camera left"));
  connect(mpRotateCameraLeftAction, SIGNAL(triggered()), this, SLOT(rotateCameraLeft()));
  // rotate camera right action
  mpRotateCameraRightAction = new QAction(QIcon(":/Resources/icons/rotateCameraRight.svg"), tr("Rotate Right"), this);
  mpRotateCameraRightAction->setStatusTip(tr("Rotates the camera right"));
  connect(mpRotateCameraRightAction, SIGNAL(triggered()), this, SLOT(rotateCameraRight()));
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
  cameraPositionIsometric();
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
 * \brief AbstractAnimationWindow::cameraPositionIsometric
 * sets the camera position to isometric view
 */
void AbstractAnimationWindow::cameraPositionIsometric()
{
  double d = computeDistanceToOrigin();
  osg::Matrixd mat = osg::Matrixd(0.7071, 0, -0.7071, 0,
                                  -0.409, 0.816, -0.409, 0,
                                  0.57735,  0.57735, 0.57735, 0,
                                  0.57735*d, 0.57735*d, 0.57735*d, 1);
  mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

/*!
 * \brief AbstractAnimationWindow::cameraPositionSide
 * sets the camera position to Side
 */
void AbstractAnimationWindow::cameraPositionSide()
{
  double d = computeDistanceToOrigin();
  osg::Matrixd mat = osg::Matrixd(1, 0, 0, 0,
                                  0, 1, 0, 0,
                                  0, 0, 1, 0,
                                  0, 0, d, 1);
  mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

/*!
 * \brief AbstractAnimationWindow::cameraPositionFront
 * sets the camera position to Front
 */
void AbstractAnimationWindow::cameraPositionFront()
{
  double d = computeDistanceToOrigin();
  osg::Matrixd mat = osg::Matrixd(0, 0, 1, 0,
                                  1, 0, 0, 0,
                                  0, 1, 0, 0,
                                  0, d, 0, 1);
  mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

/*!
 * \brief AbstractAnimationWindow::cameraPositionTop
 * sets the camera position to Top
 */
void AbstractAnimationWindow::cameraPositionTop()
{
  double d = computeDistanceToOrigin();
  osg::Matrixd mat = osg::Matrixd( 0, 0,-1, 0,
                                   0, 1, 0, 0,
                                   1, 0, 0, 0,
                                   d, 0, 0, 1);
  mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

/*!
 * \brief AbstractAnimationWindow::computeDistanceToOrigin
 * computes distance to origin using pythagoras theorem
 */
double AbstractAnimationWindow::computeDistanceToOrigin()
{
  osg::ref_ptr<osgGA::CameraManipulator> manipulator = mpSceneView->getCameraManipulator();
  osg::Matrixd mat = manipulator->getMatrix();
  //assemble

  //Compute distance to center using pythagoras theorem
  double d = sqrt(abs(mat(3,0))*abs(mat(3,0))+
                  abs(mat(3,1))*abs(mat(3,1))+
                  abs(mat(3,2))*abs(mat(3,2)));

  //If d is very small (~0), set it to 1 as default
  if(d < 1e-10) {
    d=1;
  }

  return d;
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
 * \brief AbstractAnimationWindow::setPerspective
 * gets the identifier for the chosen perspective and calls the functions
 */
void AbstractAnimationWindow::setPerspective(int value)
{
  switch(value) {
    case 0:
      cameraPositionIsometric();
      break;
    case 1:
      cameraPositionSide();
      break;
    case 2:
      cameraPositionTop();
      break;
    case 3:
      cameraPositionFront();
      break;
  }
}

/*!
 * \brief AbstractAnimationWindow::rotateCameraLeft
 * rotates the camera 90 degress left about the line of sight
 */
void AbstractAnimationWindow::rotateCameraLeft()
{
  osg::ref_ptr<osgGA::CameraManipulator> manipulator = mpSceneView->getCameraManipulator();
  osg::Matrixd mat = manipulator->getMatrix();
  osg::Camera *pCamera = mpSceneView->getCamera();

  osg::Vec3d eye, center, up;
  pCamera->getViewMatrixAsLookAt(eye, center, up);
  osg::Vec3d rotationAxis = center-eye;

  osg::Matrixd rotMatrix;
  rotMatrix.makeRotate(3.1415/2.0, rotationAxis);

  mpSceneView->getCameraManipulator()->setByMatrix(mat*rotMatrix);
}

/*!
 * \brief AbstractAnimationWindow::rotateCameraRight
 * rotates the camera 90 degress right about the line of sight
 */
void AbstractAnimationWindow::rotateCameraRight()
{
  osg::ref_ptr<osgGA::CameraManipulator> manipulator = mpSceneView->getCameraManipulator();
  osg::Matrixd mat = manipulator->getMatrix();
  osg::Camera *pCamera = mpSceneView->getCamera();

  osg::Vec3d eye, center, up;
  pCamera->getViewMatrixAsLookAt(eye, center, up);
  osg::Vec3d rotationAxis = center-eye;

  osg::Matrixd rotMatrix;
  rotMatrix.makeRotate(-3.1415/2.0, rotationAxis);

  mpSceneView->getCameraManipulator()->setByMatrix(mat*rotMatrix);
}

/*!
 * \brief AbstractAnimationWindow::saveSimSettings
 */
void AbstractAnimationWindow::saveSimSettings()
{
  std::cout<<"save simulation settings"<<std::endl;
  mpFMUSettingsDialog->close();
}
