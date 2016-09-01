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

#include "AnimationWindowContainer.h"


const double HEIGHT_CONTROLWIDGETS = 40;

/*!
  \class AnimationWindowContainer
  \brief A MDI area for animation windows.
  */
/*!
 * \brief AnimationWindowContainer::AnimationWindowContainer
 * \param pParent
 */
AnimationWindowContainer::AnimationWindowContainer(QWidget *pParent)
  : QMainWindow(pParent),
	osgViewer::CompositeViewer(),
	mPathName(""),
	mFileName(""),
	mpSceneView(new osgViewer::View()),
	mpVisualizer(nullptr),
	mpViewerWidget(nullptr),
	mpUpdateTimer(new QTimer()),
	mpAnimationToolBar(new QToolBar(QString("Animation Toolbar"),this)),
    mpAnimationChooseFileAction(nullptr),
    mpAnimationInitializeAction(nullptr),
    mpAnimationPlayAction(nullptr),
    mpAnimationPauseAction(nullptr)
{
  setThreadingModel(osgViewer::CompositeViewer::SingleThreaded);
  //the viewer widget
  osg::ref_ptr<osg::Node> rootNode = osgDB::readRefNodeFile("D:/Programming/OPENMODELICA_GIT/OpenModelica/build/bin/dumptruck.osg");
  mpViewerWidget = setupViewWidget(rootNode);

  //mpViewerWidget->setParent(this);
  //mpViewerWidget->setWindowFlags(Qt::SubWindow);
  //mpViewerWidget->setWindowState(Qt::WindowMaximized);
  mpViewerWidget->setBaseSize(QSize(2000,1000));
  //mpViewerWidget->move(100,100);
  // do a scene update at every tick
  QObject::connect(mpUpdateTimer, SIGNAL(timeout()), this, SLOT(updateSceneFunction()));
  QObject::connect(mpUpdateTimer, SIGNAL(timeout()), this, SLOT(renderSlotFunction()));
  mpUpdateTimer->start(100);

   // animation action
   mpAnimationChooseFileAction = new QAction(QIcon(":/Resources/icons/openFile.png"), Helper::animationChooseFile, this);
   mpAnimationChooseFileAction->setStatusTip(Helper::animationChooseFileTip);
   mpAnimationChooseFileAction->setEnabled(true);
   mpAnimationInitializeAction = new QAction(QIcon(":/Resources/icons/initialize.png"), Helper::animationInitialize, this);
   mpAnimationInitializeAction->setStatusTip(Helper::animationInitializeTip);
   mpAnimationInitializeAction->setEnabled(true);
   mpAnimationPlayAction = new QAction(QIcon(":/Resources/icons/play.png"), Helper::animationPlay, this);
   mpAnimationPlayAction->setStatusTip(Helper::animationPlayTip);
   mpAnimationPlayAction->setEnabled(true);
   mpAnimationPauseAction = new QAction(QIcon(":/Resources/icons/pause.png"), Helper::animationPause, this);
   mpAnimationPauseAction->setStatusTip(Helper::animationPauseTip);
   mpAnimationPauseAction->setEnabled(true);

   mpAnimationSlider = new QSlider(Qt::Horizontal);
   //mpAnimationSlider->setFixedWidth(200);
   mpAnimationSlider->setMinimum(0);
   mpAnimationSlider->setMaximum(100);
   mpAnimationSlider->setSliderPosition(50);
   mpAnimationTimeLabel = new QLabel();
   mpAnimationTimeLabel->setText(QString(" Time [s]: ").append(QString::fromStdString("0.000")));

   mpAnimationToolBar->addAction(mpAnimationChooseFileAction);
   mpAnimationToolBar->addSeparator();
 	mpAnimationToolBar->addAction(mpAnimationInitializeAction);
 	mpAnimationToolBar->addSeparator();
 	mpAnimationToolBar->addAction(mpAnimationPlayAction);
 	mpAnimationToolBar->addSeparator();
 	mpAnimationToolBar->addAction(mpAnimationPauseAction);
 	mpAnimationToolBar->addSeparator();
 	mpAnimationToolBar->addWidget(mpAnimationSlider);
 	mpAnimationToolBar->addWidget(mpAnimationTimeLabel);
 	//connect(mpAnimationSlider, SIGNAL(sliderMoved(int)),mpAnimationWindowContainer, SLOT(sliderSetTimeSlotFunction(int)));
    addToolBar(Qt::TopToolBarArea,mpAnimationToolBar);



    //QVBoxLayout* mainLayout = new QVBoxLayout();
    //mainLayout->addWidget(mpViewerWidget);
    //QWidget* topWidget = new QWidget();
    //topWidget->setLayout(mainLayout);
    mpViewerWidget->setParent(this);//important!!

    //mpViewerWidget->setParent(topWidget);//kein Einfluss

      //setCentralWidget(topWidget); //kein Einfluss

    connect(mpAnimationChooseFileAction, SIGNAL(triggered()),this, SLOT(chooseAnimationFileSlotFunction()));
    connect(mpAnimationInitializeAction, SIGNAL(triggered()),this, SLOT(initSlotFunction()));
    connect(mpAnimationPlayAction, SIGNAL(triggered()),this, SLOT(playSlotFunction()));
    connect(mpAnimationPauseAction, SIGNAL(triggered()),this, SLOT(pauseSlotFunction()));



}
/*!
 * \brief AnimationWindowContainer::setupViewWidget
 * creates the widget for the osg viewer
 * \return the widget
 */
QWidget* AnimationWindowContainer::setupViewWidget(osg::ref_ptr<osg::Node> rootNode)
{
	//get context
    osg::ref_ptr<osg::DisplaySettings> ds = osg::DisplaySettings::instance().get();
    osg::ref_ptr<osg::GraphicsContext::Traits> traits = new osg::GraphicsContext::Traits();
    traits->windowName = "";
    traits->windowDecoration = false;
    traits->x = 0;
    traits->y = 0;

    traits->width = 2000;
    traits->height = 1000;
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
    camera->setClearColor(osg::Vec4(0.2, 0.2, 0.6, 1.0));
    camera->setViewport(new osg::Viewport(0, 0, traits->width, traits->height));
    camera->setProjectionMatrixAsPerspective(30.0f, static_cast<double>(traits->width/2) / static_cast<double>(traits->height/2), 1.0f, 10000.0f);
    mpSceneView->setSceneData(rootNode);
    mpSceneView->addEventHandler(new osgViewer::StatsHandler());
    mpSceneView->setCameraManipulator(new osgGA::MultiTouchTrackballManipulator());
    gw->setTouchEventsEnabled(true);
    return gw->getGLWidget();
}

/*!
 * \brief AnimationWindowContainer::loadVisualization
 * loads the data and the xml scene description
 */
void AnimationWindowContainer::loadVisualization(){
	VisType visType = VisType::NONE;

    // Get visualization type.
    if (isFMU(mFileName))
        visType = VisType::FMU;
    else if (isMAT(mFileName))
        visType = VisType::MAT;
    else
    	std::cout<<"unknown visualization type. "<<std::endl;

    //init visualizer
    if (visType == VisType::MAT){
		mpVisualizer = new VisualizerMAT(mFileName, mPathName);
	}
	else{
		std::cout<<"could not init "<<mPathName<<mFileName<<std::endl;
	}

    //load the XML File, build osgTree, get initial values for the shapes
    bool xmlExists = checkForXMLFile(mFileName, mPathName);
    if (!xmlExists){
        std::cout<<"Could not find the visual XML file "<<assembleXMLFileName(mFileName, mPathName)<<std::endl;
    }
    mpVisualizer->initData();
    mpVisualizer->setUpScene();
    mpVisualizer->initVisualization();

    //add scene for the chosen visualization
    mpSceneView->setSceneData(mpVisualizer->getOMVisScene()->getScene().getRootNode());
}


/*!
 * \brief AnimationWindowContainer::animationFileSlotFunction
 * opens a file dialog to chooes an animation
 */
void AnimationWindowContainer::chooseAnimationFileSlotFunction(){
	QFileDialog dialog(this);
	std::string file = dialog.getOpenFileName(this,tr("Open Visualiation File"), "./", tr("Visualization MAT(*.mat)")).toStdString();
	if (file.compare("")){
    std::size_t pos = file.find_last_of("/\\");
    mPathName = file.substr(0, pos + 1);
    mFileName = file.substr(pos + 1, file.length());
	//std::cout<<"file "<<mFileName<<"   path "<<mPathName<<std::endl;
	loadVisualization();
	}
	else
		std::cout<<"No Visualization selected!"<<std::endl;

}

/*!
 * \brief AnimationWindowContainer::showWidgets
 * overwrite show method to explicitly show the viewer as well
 */
void AnimationWindowContainer::showWidgets(){
	mpViewerWidget->show();
	show();
}

double AnimationWindowContainer::getTimeFraction(){
	if (mpVisualizer==NULL)
		return 0.0;
	else
		return mpVisualizer->getTimeManager()->getTimeFraction();
}

/*!
 * \brief AnimationWindowContainer::sliderSetTimeSlotFunction
 * slot function for the time slider
 */
void AnimationWindowContainer::sliderSetTimeSlotFunction(int value){
	int time = (mpVisualizer->getTimeManager()->getEndTime()
            - mpVisualizer->getTimeManager()->getStartTime())
            * (float) (value / 100.0);
	mpVisualizer->getTimeManager()->setVisTime(time);
	mpVisualizer->sceneUpdate();
}


/*!
 * \brief AnimationWindowContainer::playSlotFunction
 * slot function for the play button
 */
void AnimationWindowContainer::playSlotFunction(){
	mpVisualizer->getTimeManager()->setPause(false);
}

/*!
 * \brief AnimationWindowContainer::pauseSlotFunction
 * slot function for the pause button
 */
void AnimationWindowContainer::pauseSlotFunction(){
	mpVisualizer->getTimeManager()->setPause(true);
}

/*!
 * \brief AnimationWindowContainer::initSlotFunction
 * slot function for the init button
 */
void AnimationWindowContainer::initSlotFunction(){
    mpVisualizer->initVisualization();

}

/*!
 * \brief AnimationWindowContainer::updateSceneFunction
 * updates the visualization objects
 */
void AnimationWindowContainer::updateSceneFunction(){
	if (!(mpVisualizer==NULL))
		mpVisualizer->sceneUpdate();
}

/*!
 * \brief AnimationWindowContainer::renderSlotFunction
 * renders the osg viewer
 */
void AnimationWindowContainer::renderSlotFunction()
{
	std::cout<<"render"<<std::endl;
  frame();
}

/*!
 * \brief AnimationWindowContainer::getVisTime
 * returns the current visualization time
 */
double AnimationWindowContainer::getVisTime(){
	if (mpVisualizer==NULL)
		return -1.0;
	else
		return mpVisualizer->getTimeManager()->getVisTime();
}

