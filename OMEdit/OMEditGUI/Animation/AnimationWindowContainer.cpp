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
  : MdiArea(pParent),
	osgViewer::CompositeViewer(),
	_sceneView(new osgViewer::View()),
	viewerWidget(nullptr),
    topWidget(nullptr),
    _playButton(nullptr),
    _pauseButton(nullptr),
    _initButton(nullptr),
    _timeSlider(nullptr),
	_timeDisplay(nullptr),
	_RTFactorDisplay(nullptr)
{
  if (mpMainWindow->getOptionsDialog()->getAnimationPage()->getAnimationViewMode().compare(Helper::subWindow) == 0) {
    setViewMode(QMdiArea::SubWindowView);
  } else {
    setViewMode(QMdiArea::TabbedView);
  }

  //the viewer widget
  osg::ref_ptr<osg::Node> rootNode = osgDB::readNodeFile("D:/Programming/OPENMODELICA_GIT/OpenModelica/build/bin/dumptruck.osg");
  setupViewWidget(rootNode);
  topWidget = AnimationWindowContainer::setupAnimationWidgets();

  // dont show this widget at startup
  setVisible(true);
}

/*!
 * \brief AnimationWindowContainer::setupViewWidget
 * creates the widget for the osg viewer
 * \return the widget
 */
void AnimationWindowContainer::setupViewWidget(osg::ref_ptr<osg::Node> rootNode)
{
	//get context
    osg::ref_ptr<osg::DisplaySettings> ds = osg::DisplaySettings::instance().get();
    osg::ref_ptr<osg::GraphicsContext::Traits> traits = new osg::GraphicsContext::Traits();
    traits->windowName = "";
    traits->windowDecoration = false;
    traits->x = 100;
    traits->y = 100;
    traits->width = 300;
    traits->height = 500;
    traits->doubleBuffer = true;
    traits->alpha = ds->getMinimumNumAlphaBits();
    traits->stencil = ds->getMinimumNumStencilBits();
    traits->sampleBuffers = ds->getMultiSamples();
    traits->samples = ds->getNumMultiSamples();
    osg::ref_ptr<osgQt::GraphicsWindowQt> gw = new osgQt::GraphicsWindowQt(traits.get(),this);

	//add a scene to viewer
    osgViewer::CompositeViewer::addView(_sceneView);

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
    viewerWidget = gw->getGLWidget();
}


/*!
 * \brief AnimationWindowContainer::setupAnimationWidgets
 * creates the widgets for the animation
 * \return void
 */
QWidget* AnimationWindowContainer::setupAnimationWidgets()
{
    _timeSlider = new QSlider(Qt::Horizontal,this);
    _timeSlider->setFixedHeight(30);
    _timeSlider->setMinimum(0);
    _timeSlider->setMaximum(100);
    _timeSlider->setSliderPosition(50);
    _playButton = new QPushButton("Play",this);
    _pauseButton = new QPushButton("Pause",this);
    _initButton = new QPushButton("Initialize",this);
    _timeDisplay = new QLabel(this);
    _timeDisplay->setText(QString("Time [s]: ").append(QString::fromStdString("0.000")));
    _RTFactorDisplay = new QLabel(this);
    _RTFactorDisplay->setText(QString("RT-Factor: ").append(QString::fromStdString("0.000")));

    //make a row layout
    QHBoxLayout* rowLayOut = new QHBoxLayout();
    rowLayOut->addWidget(_initButton);
    rowLayOut->addWidget(_playButton);
    rowLayOut->addWidget(_pauseButton);
    rowLayOut->addWidget(_timeSlider);
    rowLayOut->addWidget(_RTFactorDisplay);
    rowLayOut->addWidget(_timeDisplay);
    QGroupBox* widgetRowBox = new QGroupBox(this);
    widgetRowBox->setLayout(rowLayOut);
    widgetRowBox->setFixedHeight(40);

    topWidget = new QWidget(this);
    QVBoxLayout* mainRowLayout = new QVBoxLayout(this);
    //mainRowLayout->addWidget(viewerWidget);
    mainRowLayout->addWidget(widgetRowBox);
    topWidget->setLayout(mainRowLayout);

    // Connect the buttons to the corresponding slot functions.
    //QObject::connect(playButton, SIGNAL(clicked()), this, SLOT(playSlotFunction()));
    //QObject::connect(pauseButton, SIGNAL(clicked()), this, SLOT(pauseSlotFunction()));
    //QObject::connect(initButton, SIGNAL(clicked()), this, SLOT(initSlotFunction()));
    return topWidget;
}


/*!
 * \brief AnimationWindowContainer::getUniqueName
 * Returns a unique name for new animation window.
 * \param name
 * \param number
 * \return
 */
QString AnimationWindowContainer::getUniqueName(QString name, int number)
{
  QString newName;
  newName = name + QString::number(number);

  foreach (QMdiSubWindow *pWindow, subWindowList()) {
    if (pWindow->widget()->windowTitle().compare(newName) == 0) {
      newName = getUniqueName(name, ++number);
      break;
    }
  }
  return newName;
}




