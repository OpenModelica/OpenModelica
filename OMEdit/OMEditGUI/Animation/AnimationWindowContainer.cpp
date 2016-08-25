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

#include "AnimationWindowContainer.h"


/*!
  \class AnimationWindowContainer
  \brief A MDI area for animation windows.
  */
/*!
 * \brief AnimationWindowContainer::AnimationWindowContainer
 * \param pParent
 */
AnimationWindowContainer::AnimationWindowContainer(MainWindow *pParent)
  : QWidget(pParent),
	osgViewer::CompositeViewer(),
	_pathName(""),
	_fileName(""),
	_sceneView(new osgViewer::View()),
	_visualizer(),
	_viewerWidget(nullptr),
    _topWidget(nullptr),
	_visFileButton(nullptr),
    _playButton(nullptr),
    _pauseButton(nullptr),
    _initButton(nullptr),
    _timeSlider(nullptr),
	_timeDisplay(nullptr),
	_RTFactorDisplay(nullptr),
	_updateTimer(nullptr)
{
  setThreadingModel(osgViewer::CompositeViewer::SingleThreaded);
  //the viewer widget
  osg::ref_ptr<osg::Node> rootNode = osgDB::readRefNodeFile("D:/Programming/OPENMODELICA_GIT/OpenModelica/build/bin/dumptruck.osg");
  _viewerWidget = setupViewWidget(rootNode);
  //the control widgets
  _topWidget = AnimationWindowContainer::setupAnimationWidgets();
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
    traits->x = 100;
    traits->y = 100;
    traits->width = 300;
    traits->height = 300;
    traits->doubleBuffer = true;
    traits->alpha = ds->getMinimumNumAlphaBits();
    traits->stencil = ds->getMinimumNumStencilBits();
    traits->sampleBuffers = ds->getMultiSamples();
    traits->samples = ds->getNumMultiSamples();
    osg::ref_ptr<osgQt::GraphicsWindowQt> gw = new osgQt::GraphicsWindowQt(traits.get(),this);

	//add a scene to viewer
    addView(_sceneView);

    //get the viewer widget
    osg::ref_ptr<osg::Camera> camera = _sceneView->getCamera();
    camera->setGraphicsContext(gw);
    const osg::GraphicsContext::Traits* traits2 = gw->getTraits();
    camera->setClearColor(osg::Vec4(0.2, 0.2, 0.6, 1.0));
    camera->setViewport(new osg::Viewport(0, 0, traits2->width, traits2->height));
    camera->setProjectionMatrixAsPerspective(30.0f, static_cast<double>(traits2->width) / static_cast<double>(traits2->height), 1.0f, 10000.0f);
    _sceneView->setSceneData(rootNode);
    _sceneView->addEventHandler(new osgViewer::StatsHandler());
    _sceneView->setCameraManipulator(new osgGA::MultiTouchTrackballManipulator());
    gw->setTouchEventsEnabled(true);
    return gw->getGLWidget();
}


/*!
 * \brief AnimationWindowContainer::setupAnimationWidgets
 * creates the widgets for the animation
 */
QWidget* AnimationWindowContainer::setupAnimationWidgets()
{
	// control widgets
    _timeSlider = new QSlider(Qt::Horizontal,this);
    _timeSlider->setFixedHeight(30);
    _timeSlider->setMinimum(0);
    _timeSlider->setMaximum(100);
    _timeSlider->setSliderPosition(50);
    _visFileButton = new QPushButton("Choose File",this);
    _playButton = new QPushButton("Play",this);
    _pauseButton = new QPushButton("Pause",this);
    _initButton = new QPushButton("Initialize",this);
    _timeDisplay = new QLabel(this);
    _timeDisplay->setText(QString("Time [s]: ").append(QString::fromStdString("0.000")));
    _RTFactorDisplay = new QLabel(this);
    _RTFactorDisplay->setText(QString("RT-Factor: ").append(QString::fromStdString("0.000")));

    //layout for all control widgets
    QHBoxLayout* rowLayOut = new QHBoxLayout();
    rowLayOut->addWidget(_visFileButton);
    rowLayOut->addWidget(_initButton);
    rowLayOut->addWidget(_playButton);
    rowLayOut->addWidget(_pauseButton);
    rowLayOut->addWidget(_timeSlider);
    rowLayOut->addWidget(_RTFactorDisplay);
    rowLayOut->addWidget(_timeDisplay);
    QGroupBox* widgetRowBox = new QGroupBox(this);
    widgetRowBox->setLayout(rowLayOut);
    widgetRowBox->setFixedHeight(40);

    _topWidget = new QWidget(this);
    QVBoxLayout* mainVLayout = new QVBoxLayout(this);
    //mainVLayout->addWidget(viewerWidget);
    mainVLayout->addWidget(widgetRowBox);
    _topWidget->setLayout(mainVLayout);

    // Connect the buttons to the corresponding slot functions.
    QObject::connect(_visFileButton, SIGNAL(clicked()), this, SLOT(chooseAnimationFileSlotFunction()));
    QObject::connect(_playButton, SIGNAL(clicked()), this, SLOT(playSlotFunction()));
    QObject::connect(_pauseButton, SIGNAL(clicked()), this, SLOT(pauseSlotFunction()));
    QObject::connect(_initButton, SIGNAL(clicked()), this, SLOT(initSlotFunction()));
    return _topWidget;
}


/*!
 * \brief AnimationWindowContainer::loadVisualization
 * loads the data and the xml scene description
 */
void AnimationWindowContainer::loadVisualization(){
	VisType visType = VisType::NONE;

    // Get visualization type.
    if (isFMU(_fileName))
        visType = VisType::FMU;
    else if (isMAT(_fileName))
        visType = VisType::MAT;
    else
    	std::cout<<"unknown visualization type. "<<std::endl;

    //init visualizer
    if (visType == VisType::MAT){
		_visualizer = new VisualizerMAT(_fileName, _pathName);
	}
	else{
		std::cout<<"could not init "<<_pathName<<_fileName<<std::endl;
	}

    //load the XML File, build osgTree, get initial values for the shapes
    bool xmlExists = checkForXMLFile(_fileName, _pathName);
    if (!xmlExists){
        std::cout<<"Could not find the visual XML file "<<assembleXMLFileName(_fileName, _pathName)<<std::endl;
    }
    _visualizer->initData();
    _visualizer->setUpScene();
    _visualizer->initVisualization();

    //add
    _sceneView->setSceneData(_visualizer->getOMVisScene()->getScene().getRootNode());

    std::cout<<"start timer"<<std::endl;
    _updateTimer = new QTimer();
    QObject::connect(_updateTimer, SIGNAL(timeout()), this, SLOT(updateSceneFunction()));
    _updateTimer->start(100);
}


/*!
 * \brief AnimationWindowContainer::animationFileSlotFunction
 * opens a file dialog to chooes an animation
 */
void AnimationWindowContainer::chooseAnimationFileSlotFunction(){
	std::cout<<"animationFileSlotFunction "<<std::endl;
	QFileDialog dialog(this);
	std::string file = dialog.getOpenFileName(this,tr("Open Visualiation File"), "./", tr("Visualization FMU(*.fmu);; Visualization MAT(*.mat)")).toStdString();;
    std::size_t pos = file.find_last_of("/\\");
    _pathName = file.substr(0, pos + 1);
    _fileName = file.substr(pos + 1, file.length());
	std::cout<<"file "<<_fileName<<"   path "<<_pathName<<std::endl;
	loadVisualization();

}

/*!
 * \brief AnimationWindowContainer::showWidgets
 * overwrite show method to explicitly show the viewer as well
 */
void AnimationWindowContainer::showWidgets(){
	_viewerWidget->show();
	show();
}

/*!
 * \brief AnimationWindowContainer::playSlotFunction
 * slot function for the play button
 */
void AnimationWindowContainer::playSlotFunction(){
	std::cout<<"playSlotFunction "<<std::endl;
	_visualizer->getTimeManager()->setPause(false);
}

/*!
 * \brief AnimationWindowContainer::pauseSlotFunction
 * slot function for the pause button
 */
void AnimationWindowContainer::pauseSlotFunction(){
	std::cout<<"pauseSlotFunction "<<std::endl;
	_visualizer->getTimeManager()->setPause(true);
}

/*!
 * \brief AnimationWindowContainer::initSlotFunction
 * slot function for the init button
 */
void AnimationWindowContainer::initSlotFunction(){
	std::cout<<"initSlotFunction "<<std::endl;
}

/*!
 * \brief AnimationWindowContainer::updateSceneFunction
 * updates the visualization objects
 */
void AnimationWindowContainer::updateSceneFunction(){
	_visualizer->sceneUpdate();
}

/*!
 * \brief AnimationWindowContainer::renderSlotFunction
 * renders the osg viewer
 */
void AnimationWindowContainer::renderSlotFunction()
{
  frame();
}





