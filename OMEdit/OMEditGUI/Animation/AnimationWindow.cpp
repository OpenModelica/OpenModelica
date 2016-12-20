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

#include "AnimationWindow.h"
#include "Modeling/MessagesWidget.h"
#include "Options/OptionsDialog.h"
#include "Modeling/MessagesWidget.h"
#include "Plotting/PlotWindowContainer.h"
#include "Visualizer.h"
#include "VisualizerMAT.h"
#include "VisualizerCSV.h"
#include "VisualizerFMU.h"

/*!
 * \class AnimationWindow
 * \brief A QMainWindow for animation.
 */
/*!
 * \brief AnimationWindow::AnimationWindow
 * \param pPlotWindowContainer
 */
AnimationWindow::AnimationWindow(PlotWindowContainer *pPlotWindowContainer)
  : QMainWindow(pPlotWindowContainer),
    osgViewer::CompositeViewer(),
    mpPlotWindowContainer(pPlotWindowContainer),
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
  // actions and widgets for the toolbar
  int toolbarIconSize = OptionsDialog::instance()->getGeneralSettingsPage()->getToolbarIconSizeSpinBox()->value();
  mpAnimationChooseFileAction = new QAction(QIcon(":/Resources/icons/open.svg"), Helper::animationChooseFile, this);
  mpAnimationChooseFileAction->setStatusTip(Helper::animationChooseFileTip);
  mpAnimationInitializeAction = new QAction(QIcon(":/Resources/icons/initialize.svg"), Helper::animationInitialize, this);
  mpAnimationInitializeAction->setStatusTip(Helper::animationInitializeTip);
  mpAnimationInitializeAction->setEnabled(false);
  mpAnimationPlayAction = new QAction(QIcon(":/Resources/icons/play_animation.svg"), Helper::animationPlay, this);
  mpAnimationPlayAction->setStatusTip(Helper::animationPlayTip);
  mpAnimationPlayAction->setEnabled(false);
  mpAnimationPauseAction = new QAction(QIcon(":/Resources/icons/pause.svg"), Helper::animationPause, this);
  mpAnimationPauseAction->setStatusTip(Helper::animationPauseTip);
  mpAnimationPauseAction->setEnabled(false);
  mpAnimationSlider = new QSlider(Qt::Horizontal);
  mpAnimationSlider->setMinimum(0);
  mpAnimationSlider->setMaximum(100);
  mpAnimationSlider->setSliderPosition(0);
  mpAnimationSlider->setEnabled(false);
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
  pDoubleValidator->setBottom(0);
  mpAnimationTimeLabel = new Label;
  mpAnimationTimeLabel->setText(tr("Time [s]:"));
  mpTimeTextBox = new QLineEdit("0.0", this);
  mpTimeTextBox->setMaximumSize(QSize(toolbarIconSize*2, toolbarIconSize));
  mpTimeTextBox->setEnabled(false);
  mpTimeTextBox->setValidator(pDoubleValidator);
  mpAnimationSpeedLabel = new Label;
  mpAnimationSpeedLabel->setText(tr("Speed:"));
  mpSpeedComboBox = new QComboBox(this);
  mpSpeedComboBox->setEditable(true);
  mpSpeedComboBox->addItems(QStringList() << "10" << "5" << "2" << "1" << "0.5" << "0.2" << "0.1");
  mpSpeedComboBox->setCurrentIndex(3);
  mpSpeedComboBox->setMaximumSize(QSize(toolbarIconSize*2, toolbarIconSize));
  mpSpeedComboBox->setEnabled(false);
  mpSpeedComboBox->setValidator(pDoubleValidator);
  mpSpeedComboBox->setCompleter(0);
  mpPerspectiveDropDownBox = new QComboBox(this);
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective0.svg"), QString("Isometric"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective1.svg"),QString("Left 1"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective2.svg"),QString("Left 2"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective3.svg"),QString("Right 1"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective4.svg"),QString("Right 2"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective5.svg"),QString("Front 1"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective6.svg"),QString("Front 2"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective7.svg"),QString("Front 3"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective8.svg"),QString("Back 1"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective9.svg"),QString("Back 2"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective10.svg"),QString("Back 3"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective11.svg"),QString("Top 1"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective12.svg"),QString("Top 2"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective13.svg"),QString("Top 3"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective14.svg"),QString("Bottom 1"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective15.svg"),QString("Bottom 2"));
  mpPerspectiveDropDownBox->addItem(QIcon(":/Resources/icons/perspective16.svg"),QString("Bottom 3"));
  //assemble the animation toolbar
  mpAnimationToolBar->addAction(mpAnimationChooseFileAction);
  mpAnimationToolBar->addSeparator();
  mpAnimationToolBar->addAction(mpAnimationInitializeAction);
  mpAnimationToolBar->addSeparator();
  mpAnimationToolBar->addAction(mpAnimationPlayAction);
  mpAnimationToolBar->addSeparator();
  mpAnimationToolBar->addAction(mpAnimationPauseAction);
  mpAnimationToolBar->addSeparator();
  mpAnimationToolBar->addWidget(mpAnimationSlider);
  mpAnimationToolBar->addSeparator();
  mpAnimationToolBar->addWidget(mpAnimationTimeLabel);
  mpAnimationToolBar->addWidget(mpTimeTextBox);
  mpAnimationToolBar->addSeparator();
  mpAnimationToolBar->addWidget(mpAnimationSpeedLabel);
  mpAnimationToolBar->addWidget(mpSpeedComboBox);
  mpAnimationToolBar->addSeparator();
  mpAnimationToolBar->addWidget(mpPerspectiveDropDownBox);
  mpAnimationToolBar->setIconSize(QSize(toolbarIconSize, toolbarIconSize));
  addToolBar(Qt::TopToolBarArea,mpAnimationToolBar);
  // Viewer layout
  QGridLayout *pGridLayout = new QGridLayout;
  pGridLayout->setContentsMargins(0, 0, 0, 0);
  pGridLayout->addWidget(mpViewerWidget);
  // add the viewer to the frame for boxed rectangle around it.
  QFrame *pCentralWidgetFrame = new QFrame;
  pCentralWidgetFrame->setFrameStyle(QFrame::StyledPanel);
  pCentralWidgetFrame->setLayout(pGridLayout);
  setCentralWidget(pCentralWidgetFrame);
  //connections
  connect(mpAnimationChooseFileAction, SIGNAL(triggered()),this, SLOT(chooseAnimationFileSlotFunction()));
  connect(mpAnimationInitializeAction, SIGNAL(triggered()),this, SLOT(initSlotFunction()));
  connect(mpAnimationPlayAction, SIGNAL(triggered()),this, SLOT(playSlotFunction()));
  connect(mpAnimationPauseAction, SIGNAL(triggered()),this, SLOT(pauseSlotFunction()));
  connect(mpPerspectiveDropDownBox, SIGNAL(activated(int)), this, SLOT(setPerspective(int)));
  connect(mpAnimationSlider, SIGNAL(valueChanged(int)),this, SLOT(sliderSetTimeSlotFunction(int)));
  connect(mpSpeedComboBox, SIGNAL(currentIndexChanged(int)),this, SLOT(setSpeedSlotFunction()));
  connect(mpSpeedComboBox->lineEdit(), SIGNAL(textChanged(QString)),this, SLOT(setSpeedSlotFunction()));
  connect(mpTimeTextBox, SIGNAL(returnPressed()),this, SLOT(jumpToTimeSlotFunction()));
}

/*!
 * \brief AnimationWindow::jumpToTimeSlotFunction
 * slot function to jump to the user input point of time
 */
void AnimationWindow::jumpToTimeSlotFunction()
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
 * \brief AnimationWindow::setSpeedUpSlotFunction
 * slot function to set the user input speed up
 */
void AnimationWindow::setSpeedSlotFunction()
{
  QString str = mpSpeedComboBox->lineEdit()->text();
  bool isFloat = true;
  double value = str.toFloat(&isFloat);
  if (isFloat && value > 0.0) {
    mpVisualizer->getTimeManager()->setSpeedUp(value);
  }
}

AnimationWindow::~AnimationWindow()
{
  if (mpVisualizer) {
    delete mpVisualizer;
  }
}

/*!
 * \brief AnimationWindow::setupViewWidget
 * creates the widget for the osg viewer
 * \return the widget
 */
QWidget* AnimationWindow::setupViewWidget()
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
 * \brief AnimationWindow::loadVisualization
 * loads the data and the xml scene description
 */
void AnimationWindow::loadVisualization()
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
 * \brief AnimationWindow::animationFileSlotFunction
 * opens a file dialog to chooes an animation
 */
void AnimationWindow::chooseAnimationFileSlotFunction()
{
  QString fileName = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseFile),
                                                       NULL, Helper::visualizationFileTypes, NULL);
  if (fileName.isEmpty()) {
    return;
  }
  openAnimationFile(fileName);
}

/*!
 * \brief AnimationWindow::getTimeFraction
 * gets the fraction of the complete simulation time to move the slider
 */
double AnimationWindow::getTimeFraction()
{
  if (mpVisualizer==NULL) {
    return 0.0;
  } else {
    return mpVisualizer->getTimeManager()->getTimeFraction();
  }
}

/*!
 * \brief AnimationWindow::sliderSetTimeSlotFunction
 * slot function for the time slider to jump to the adjusted point of time
 */
void AnimationWindow::sliderSetTimeSlotFunction(int value)
{
  float time = (mpVisualizer->getTimeManager()->getEndTime()
                - mpVisualizer->getTimeManager()->getStartTime())
                * (float) (value / 100.0);
  mpVisualizer->getTimeManager()->setVisTime(time);
  mpTimeTextBox->setText(QString::number(mpVisualizer->getTimeManager()->getVisTime()));
  mpVisualizer->updateScene(time);
}

/*!
 * \brief AnimationWindow::playSlotFunction
 * slot function for the play button
 */
void AnimationWindow::playSlotFunction()
{
  mpVisualizer->getTimeManager()->setPause(false);
}

/*!
 * \brief AnimationWindow::pauseSlotFunction
 * slot function for the pause button
 */
void AnimationWindow::pauseSlotFunction()
{
  mpVisualizer->getTimeManager()->setPause(true);
}

/*!
 * \brief AnimationWindow::initSlotFunction
 * slot function for the init button
 */
void AnimationWindow::initSlotFunction()
{
  mpVisualizer->initVisualization();
  bool state = mpAnimationSlider->blockSignals(true);
  mpAnimationSlider->setValue(0);
  mpAnimationSlider->blockSignals(state);
  mpTimeTextBox->setText(QString::number(mpVisualizer->getTimeManager()->getVisTime()));
}

/*!
 * \brief AnimationWindow::updateSceneFunction
 * updates the visualization objects
 */
void AnimationWindow::updateScene()
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
 * \brief AnimationWindow::renderFrame
 * renders the osg viewer
 */
void AnimationWindow::renderFrame()
{
  frame();
}

/*!
 * \brief AnimationWindow::getVisTime
 * returns the current visualization time
 */
double AnimationWindow::getVisTime()
{
  if (mpVisualizer==NULL) {
    return -1.0;
  } else {
    return mpVisualizer->getTimeManager()->getVisTime();
  }
}

/*!
 * \brief AnimationWindow::setPathName
 * sets mpPathName
 */
void AnimationWindow::setPathName(std::string pathName)
{
  mPathName = pathName;
}

/*!
 * \brief AnimationWindow::setFileName
 * sets mpFileName
 */
void AnimationWindow::setFileName(std::string fileName)
{
  mFileName = fileName;
}

/*!
 * \brief AnimationWindow::openAnimationFile
 * \param fileName
 */
void AnimationWindow::openAnimationFile(QString fileName)
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
 * \brief AnimationWindow::cameraPositionIsometric
 * sets the camera position to isometric view
 */
void AnimationWindow::cameraPositionIsometric()
{
    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd(0, -0.7071, 0.7071, 0,
                       0.816, -0.409, -0.409, 0,
                       0.57735, 0.57735, 0.57735, 0,
                       0.57735*d, 0.57735*d, 0.57735*d, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

void AnimationWindow::cameraPositionLeft1()
{
    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd(0, 1, 0, 0,
                                    1, 0, 0, 0,
                                    0, 0,-1, 0,
                                    0, 0,-d, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

/*!
 * \brief AnimationWindow::cameraPositionXY
 * sets the camera position to XY
 */
void AnimationWindow::cameraPositionLeft2()
{
    //the new orientation
    //osg::Matrix3 newOrient = osg::Matrix3(1, 0, 0, 0, 0, 1, 0, -1, 0);
    osg::ref_ptr<osgGA::CameraManipulator> manipulator = mpSceneView->getCameraManipulator();
    osg::Matrixd mat2 = manipulator->getMatrix();

    std::stringstream ss;
    ss << "Matrix:\n" << mat2(0,0) << ", " << mat2(0,1) << ", " << mat2(0,2) << ", " << mat2(0,3) << "\n"
                      << mat2(1,0) << ", " << mat2(1,1) << ", " << mat2(1,2) << ", " << mat2(1,3) << "\n"
                      << mat2(2,0) << ", " << mat2(2,1) << ", " << mat2(2,2) << ", " << mat2(2,3) << "\n"
                      << mat2(3,0) << ", " << mat2(3,1) << ", " << mat2(3,2) << ", " << mat2(3,3) << "\n\n";
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::MetaModel, "", false, 0, 0, 0, 0, QString(ss.str().c_str()),
                                                          Helper::scriptingKind, Helper::errorLevel));



    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd(-1, 0, 0, 0,
                       0, 1, 0, 0,
                       0, 0,-1, 0,
                       0, 0,-d, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

void AnimationWindow::cameraPositionRight1()
{
    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd(0,-1, 0, 0,
                                    1, 0, 0, 0,
                                    0, 0, 1, 0,
                                    0, 0, d, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

/*!
 * \brief AnimationWindow::cameraPositionXY
 * sets the camera position to XY
 */
void AnimationWindow::cameraPositionRight2()
{
  double d = computeDistanceToOrigin();
  osg::Matrixd mat = osg::Matrixd(1, 0, 0, 0,
                                  0, 1, 0, 0,
                                  0, 0, 1, 0,
                                  0, 0, d, 1);
  mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

void AnimationWindow::cameraPositionFront1()
{
    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd(0, 0, 1, 0,
                                    1, 0, 0, 0,
                                    0, 1, 0, 0,
                                    0, d, 0, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

void AnimationWindow::cameraPositionFront2()
{
    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd(-1, 0, 0, 0,
                                    0, 0, 1, 0,
                                    0, 1, 0, 0,
                                    0, d, 0, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

void AnimationWindow::cameraPositionFront3()
{
    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd(1, 0, 0, 0,
                                    0, 0,-1, 0,
                                    0, 1, 0, 0,
                                    0, d, 0, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

void AnimationWindow::cameraPositionBack1()
{
    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd(0, 0,-1, 0,
                                    1, 0, 0, 0,
                                    0,-1, 0, 0,
                                    0,-d, 0, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

/*!
 * \brief AnimationWindow::cameraPositionXZ
 * sets the camera position to XZ
 */
void AnimationWindow::cameraPositionBack2()
{
    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd(1, 0, 0, 0,
                                    0, 0, 1, 0,
                                    0,-1, 0, 0,
                                    0,-d, 0, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

void AnimationWindow::cameraPositionBack3()
{
    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd(-1, 0, 0, 0,
                                     0, 0,-1, 0,
                                     0,-1, 0, 0,
                                     0,-d, 0, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

void AnimationWindow::cameraPositionTop1()
{
    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd( 0, 0,-1, 0,
                                     0, 1, 0, 0,
                                     1, 0, 0, 0,
                                     d, 0, 0, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

/*!
 * \brief AnimationWindow::cameraPositionYZ
 * sets the camera position to YZ
 */
void AnimationWindow::cameraPositionTop2()
{
    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd(0, 1, 0, 0,
                                    0, 0, 1, 0,
                                    1, 0, 0, 0,
                                    d, 0, 0, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

void AnimationWindow::cameraPositionTop3()
{
    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd(0,-1, 0, 0,
                                    0, 0,-1, 0,
                                    1, 0, 0, 0,
                                    d, 0, 0, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

void AnimationWindow::cameraPositionBottom1()
{
    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd( 0, 0, 1, 0,
                                     0, 1, 0, 0,
                                    -1, 0, 0, 0,
                                    -d, 0, 0, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

void AnimationWindow::cameraPositionBottom2()
{
    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd(0,-1, 0, 0,
                                    0, 0, 1, 0,
                                    -1,0, 0, 0,
                                    -d,0, 0, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}

void AnimationWindow::cameraPositionBottom3()
{
    double d = computeDistanceToOrigin();
    osg::Matrixd mat = osg::Matrixd(0, 1, 0, 0,
                                    0, 0,-1, 0,
                                    -1,0, 0, 0,
                                    -d,0, 0, 1);
    mpSceneView->getCameraManipulator()->setByMatrix(mat);
}




/*!
 * \brief AnimationWindow::computeDistanceToOrigin
 * computes distance to origin using pythagoras theorem
 */
//
double AnimationWindow::computeDistanceToOrigin()
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
 * \brief AnimationWindow::resetCamera
 * resets the camera position
 */
void AnimationWindow::resetCamera()
{
  mpSceneView->home();
}

/*!
 * \brief AnimationWindow::setPerspective
 * gets the identifier for the chosen perspective and calls the functions
 */
void AnimationWindow::setPerspective(int value)
{
  switch(value) {
    case 0:
      cameraPositionIsometric();
      break;
    case 1:
      cameraPositionLeft1();
      break;
    case 2:
      cameraPositionLeft2();
      break;
    case 3:
      cameraPositionRight1();
      break;
    case 4:
      cameraPositionRight2();
      break;
    case 5:
      cameraPositionFront1();
      break;
    case 6:
      cameraPositionFront2();
      break;
    case 7:
      cameraPositionFront3();
      break;
    case 8:
      cameraPositionBack1();
      break;
    case 9:
      cameraPositionBack2();
      break;
    case 10:
      cameraPositionBack3();
      break;
    case 11:
      cameraPositionTop1();
      break;
    case 12:
      cameraPositionTop2();
      break;
    case 13:
      cameraPositionTop3();
      break;
    case 14:
      cameraPositionBottom1();
      break;
    case 15:
      cameraPositionBottom2();
      break;
    case 16:
      cameraPositionBottom3();
      break;
  }
}

/*!
 * \brief AnimationWindow::openmpFMUSettingsDialog
 * opens a dialog to set the settings for the FMU visualization
 */
void AnimationWindow::openFMUSettingsDialog()
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

void AnimationWindow::saveSimSettings()
{
  std::cout<<"save simulation settings"<<std::endl;
  mpFMUSettingsDialog->close();
}
