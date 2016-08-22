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
	osgViewer::CompositeViewer()
{
  if (mpMainWindow->getOptionsDialog()->getAnimationPage()->getAnimationViewMode().compare(Helper::subWindow) == 0) {
    setViewMode(QMdiArea::SubWindowView);
  } else {
    setViewMode(QMdiArea::TabbedView);
  }

  //time slider
  _timeSlider = new QSlider(Qt::Horizontal, this);
  _timeSlider->setFixedHeight(30);
  _timeSlider->setMinimum(0);
  _timeSlider->setMaximum(100);
  _timeSlider->setSliderPosition(50);

  //osg::ref_ptr<osgQt::GraphicsWindowQt> window = createGraphicsWindow(0, 0, 100, 100);
  _sceneView = new osgViewer::View();
  osgViewer::CompositeViewer::addView(_sceneView);
  osg::ref_ptr<osg::Camera> camera = _sceneView->getCamera();

  osg::ref_ptr<osg::GraphicsContext::Traits> traits = new osg::GraphicsContext::Traits();



  // dont show this widget at startup
  setVisible(false);
}

/*
osg::ref_ptr<osgQt::GraphicsWindowQt> AnimationWindowContainer::createGraphicsWindow(int x, int y, int w, int h,
                                                                        const std::string& name, bool windowDecoration)
{
    osg::ref_ptr<osg::DisplaySettings> ds = osg::DisplaySettings::instance().get();
    osg::ref_ptr<osg::GraphicsContext::Traits> traits = new osg::GraphicsContext::Traits();
    traits->windowName = name;
    traits->windowDecoration = windowDecoration;
    traits->x = x;
    traits->y = y;
    traits->width = w;
    traits->height = h;
    traits->doubleBuffer = true;
    traits->alpha = ds->getMinimumNumAlphaBits();
    traits->stencil = ds->getMinimumNumStencilBits();
    traits->sampleBuffers = ds->getMultiSamples();
    traits->samples = ds->getNumMultiSamples();

    return new osgQt::GraphicsWindowQt(traits.get());
}
*/

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




