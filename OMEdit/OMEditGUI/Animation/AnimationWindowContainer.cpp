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


const double HEIGHT_CONTROLWIDGETS = 40;

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
	_visualizer(nullptr),
	_viewerWidget(nullptr),
	_updateTimer(nullptr)
{
  setThreadingModel(osgViewer::CompositeViewer::SingleThreaded);
  //the viewer widget
  osg::ref_ptr<osg::Node> rootNode = osgDB::readRefNodeFile("D:/Programming/OPENMODELICA_GIT/OpenModelica/build/bin/dumptruck.osg");
  _viewerWidget = setupViewWidget(rootNode);
  _viewerWidget->setParent(this);
  _viewerWidget->setWindowFlags(Qt::SubWindow);
  //_viewerWidget->setWindowState(Qt::WindowMaximized);
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
    addView(_sceneView);

    //get the viewer widget
    osg::ref_ptr<osg::Camera> camera = _sceneView->getCamera();
    camera->setGraphicsContext(gw);
    camera->setClearColor(osg::Vec4(0.2, 0.2, 0.6, 1.0));
    camera->setViewport(new osg::Viewport(0, 0, traits->width, traits->height));
    camera->setProjectionMatrixAsPerspective(30.0f, static_cast<double>(traits->width) / static_cast<double>(traits->height), 1.0f, 10000.0f);
    _sceneView->setSceneData(rootNode);
    _sceneView->addEventHandler(new osgViewer::StatsHandler());
    _sceneView->setCameraManipulator(new osgGA::MultiTouchTrackballManipulator());
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

    //add scene for the chosen visualization
    _sceneView->setSceneData(_visualizer->getOMVisScene()->getScene().getRootNode());
    _updateTimer = new QTimer();
    // do a scene update at every tick
    QObject::connect(_updateTimer, SIGNAL(timeout()), this, SLOT(updateSceneFunction()));
    QObject::connect(_updateTimer, SIGNAL(timeout()), parentWidget(), SLOT(doSomething()));

    _updateTimer->start(100);
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
    _pathName = file.substr(0, pos + 1);
    _fileName = file.substr(pos + 1, file.length());
	//std::cout<<"file "<<_fileName<<"   path "<<_pathName<<std::endl;
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
	_viewerWidget->show();
	show();
}

double AnimationWindowContainer::getTimeFraction(){
	if (_visualizer==NULL)
		return 0.0;
	else
		return _visualizer->getTimeManager()->getTimeFraction();
}

/*!
 * \brief AnimationWindowContainer::sliderSetTimeSlotFunction
 * slot function for the time slider
 */
void AnimationWindowContainer::sliderSetTimeSlotFunction(int value){
	int time = (_visualizer->getTimeManager()->getEndTime()
            - _visualizer->getTimeManager()->getStartTime())
            * (float) (value / 100.0);
	_visualizer->getTimeManager()->setVisTime(time);
	_visualizer->sceneUpdate();
}


/*!
 * \brief AnimationWindowContainer::playSlotFunction
 * slot function for the play button
 */
void AnimationWindowContainer::playSlotFunction(){
	_visualizer->getTimeManager()->setPause(false);
}

/*!
 * \brief AnimationWindowContainer::pauseSlotFunction
 * slot function for the pause button
 */
void AnimationWindowContainer::pauseSlotFunction(){
	_visualizer->getTimeManager()->setPause(true);
}

/*!
 * \brief AnimationWindowContainer::initSlotFunction
 * slot function for the init button
 */
void AnimationWindowContainer::initSlotFunction(){
    _visualizer->initVisualization();

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

/*!
 * \brief AnimationWindowContainer::getVisTime
 * returns the current visualization time
 */
double AnimationWindowContainer::getVisTime(){
	if (_visualizer==NULL)
		return -1.0;
	else
		return _visualizer->getTimeManager()->getVisTime();
}




