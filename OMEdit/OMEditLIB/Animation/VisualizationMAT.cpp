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

#include "VisualizationMAT.h"

VisualizationMAT::VisualizationMAT(const std::string& modelFile, const std::string& path)
  : VisualizationAbstract(modelFile, path, VisType::MAT),
    _matReader()
{

}

/*!
 * \brief VisualizationMAT::~VisualizationMAT
 * Free the ModelicaMatReader
 */
VisualizationMAT::~VisualizationMAT()
{
  if (_matReader.file) {
    omc_free_matlab4_reader(&_matReader);
  }
}

void VisualizationMAT::initData()
{
  VisualizationAbstract::initData();
  readMat(mpOMVisualBase->getModelFile(), mpOMVisualBase->getPath());
  mpTimeManager->setStartTime(omc_matlab4_startTime(&_matReader));
  mpTimeManager->setEndTime(omc_matlab4_stopTime(&_matReader));
}

void VisualizationMAT::initializeVisAttributes(const double time)
{
  if (0.0 > time) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                          QObject::tr("Cannot load visualization attributes for time point < 0.0."),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
  updateVisAttributes(time);
}

void VisualizationMAT::readMat(const std::string& modelFile, const std::string& path)
{
  std::string resFileName = path + modelFile;     // + "_res.mat";

  // Check if the MAT file exists.
  if (!fileExists(resFileName))
  {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, QString(QObject::tr("Could not find MAT file %1."))
                                                          .arg(resFileName.c_str()),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
  else
  {
    // Read mat file.
    omc_new_matlab4_reader(resFileName.c_str(), &_matReader);
    //auto ret = omc_new_matlab4_reader(resFileName.c_str(), &_matReader);
    // Check return value.
//    if (0 != ret)
//    {
//      std::string msg(ret);
//      std::cout<<msg<<std::endl;
//    }
  }

  /*
     FILE * fileA = omc_fopen("allVArs.txt", "w+");
     omc_matlab4_print_all_vars(fileA, &matReader);
     fclose(fileA);
     */
}

void VisualizationMAT::setSimulationSettings(const UserSimSettingsMAT& simSetMAT)
{
  auto newVal = simSetMAT.speedup * mpTimeManager->getHVisual();
  mpTimeManager->setHVisual(newVal);
}

void VisualizationMAT::updateVisAttributes(const double time)
{
  // Update all visualizers
  //std::cout<<"updateVisAttributes at "<<time <<std::endl;

  try
  {
    for (ShapeObject& shape : mpOMVisualBase->_shapes)
    {
      // Get the values for the scene graph objects
      //std::cout<<"shape "<<shape._id <<std::endl;

      updateVisualizerAttributeMAT(shape._T[0], time);
      updateVisualizerAttributeMAT(shape._T[1], time);
      updateVisualizerAttributeMAT(shape._T[2], time);
      updateVisualizerAttributeMAT(shape._T[3], time);
      updateVisualizerAttributeMAT(shape._T[4], time);
      updateVisualizerAttributeMAT(shape._T[5], time);
      updateVisualizerAttributeMAT(shape._T[6], time);
      updateVisualizerAttributeMAT(shape._T[7], time);
      updateVisualizerAttributeMAT(shape._T[8], time);

      updateVisualizerAttributeMAT(shape._r[0], time);
      updateVisualizerAttributeMAT(shape._r[1], time);
      updateVisualizerAttributeMAT(shape._r[2], time);

      updateVisualizerAttributeMAT(shape._color[0], time);
      updateVisualizerAttributeMAT(shape._color[1], time);
      updateVisualizerAttributeMAT(shape._color[2], time);

      updateVisualizerAttributeMAT(shape._specCoeff, time);

      updateVisualizerAttributeMAT(shape._rShape[0], time);
      updateVisualizerAttributeMAT(shape._rShape[1], time);
      updateVisualizerAttributeMAT(shape._rShape[2], time);

      updateVisualizerAttributeMAT(shape._lDir[0], time);
      updateVisualizerAttributeMAT(shape._lDir[1], time);
      updateVisualizerAttributeMAT(shape._lDir[2], time);

      updateVisualizerAttributeMAT(shape._wDir[0], time);
      updateVisualizerAttributeMAT(shape._wDir[1], time);
      updateVisualizerAttributeMAT(shape._wDir[2], time);

      updateVisualizerAttributeMAT(shape._length, time);
      updateVisualizerAttributeMAT(shape._width, time);
      updateVisualizerAttributeMAT(shape._height, time);

      updateVisualizerAttributeMAT(shape._extra, time);

      rAndT rT = rotateModelica2OSG(
          osg::Matrix3(shape._T[0].exp, shape._T[1].exp, shape._T[2].exp,
                       shape._T[3].exp, shape._T[4].exp, shape._T[5].exp,
                       shape._T[6].exp, shape._T[7].exp, shape._T[8].exp),
          osg::Vec3f(shape._r[0].exp, shape._r[1].exp, shape._r[2].exp),
          osg::Vec3f(shape._rShape[0].exp, shape._rShape[1].exp, shape._rShape[2].exp),
          osg::Vec3f(shape._lDir[0].exp, shape._lDir[1].exp, shape._lDir[2].exp),
          osg::Vec3f(shape._wDir[0].exp, shape._wDir[1].exp, shape._wDir[2].exp),
          shape._type);
      assemblePokeMatrix(shape._mat, rT._T, rT._r);

      // Update the shapes
      updateVisualizer(shape);
      //shape.dumpVisualizerAttributes();
      //mpOMVisScene->dumpOSGTreeDebug();
    }

    for (VectorObject& vector : mpOMVisualBase->_vectors)
    {
      // Get the values for the scene graph objects
      //std::cout<<"vector "<<vector._id <<std::endl;

      updateVisualizerAttributeMAT(vector._T[0], time);
      updateVisualizerAttributeMAT(vector._T[1], time);
      updateVisualizerAttributeMAT(vector._T[2], time);
      updateVisualizerAttributeMAT(vector._T[3], time);
      updateVisualizerAttributeMAT(vector._T[4], time);
      updateVisualizerAttributeMAT(vector._T[5], time);
      updateVisualizerAttributeMAT(vector._T[6], time);
      updateVisualizerAttributeMAT(vector._T[7], time);
      updateVisualizerAttributeMAT(vector._T[8], time);

      updateVisualizerAttributeMAT(vector._r[0], time);
      updateVisualizerAttributeMAT(vector._r[1], time);
      updateVisualizerAttributeMAT(vector._r[2], time);

      updateVisualizerAttributeMAT(vector._color[0], time);
      updateVisualizerAttributeMAT(vector._color[1], time);
      updateVisualizerAttributeMAT(vector._color[2], time);

      updateVisualizerAttributeMAT(vector._specCoeff, time);

      updateVisualizerAttributeMAT(vector._coords[0], time);
      updateVisualizerAttributeMAT(vector._coords[1], time);
      updateVisualizerAttributeMAT(vector._coords[2], time);

      updateVisualizerAttributeMAT(vector._quantity, time);

      updateVisualizerAttributeMAT(vector._headAtOrigin, time);

      updateVisualizerAttributeMAT(vector._twoHeadedArrow, time);

      rAndT rT = rotateModelica2OSG(
          osg::Matrix3(vector._T[0].exp, vector._T[1].exp, vector._T[2].exp,
                       vector._T[3].exp, vector._T[4].exp, vector._T[5].exp,
                       vector._T[6].exp, vector._T[7].exp, vector._T[8].exp),
          osg::Vec3f(vector._r[0].exp, vector._r[1].exp, vector._r[2].exp),
          osg::Vec3f(vector._coords[0].exp, vector._coords[1].exp, vector._coords[2].exp));
      assemblePokeMatrix(vector._mat, rT._T, rT._r);

      // Update the vectors
      updateVisualizer(vector);
      //vector.dumpVisualizerAttributes();
      //mpOMVisScene->dumpOSGTreeDebug();
    }
  }
  catch (std::exception& ex)
  {
    QString msg = QString(QObject::tr("Error in VisualizationMAT::updateVisAttributes at time point %1\n%2."))
                  .arg(QString::number(time), ex.what());
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, msg, Helper::scriptingKind, Helper::errorLevel));
    throw(msg.toStdString());
  }
}

void VisualizationMAT::updateScene(const double time)
{
  mpTimeManager->updateTick();  //for real-time measurement
  double visTime = mpTimeManager->getRealTime();
  updateVisAttributes(time);
  mpTimeManager->updateTick();  //for real-time measurement
  visTime = mpTimeManager->getRealTime() - visTime;
  mpTimeManager->setRealTimeFactor(mpTimeManager->getHVisual() / visTime);
}

void VisualizationMAT::updateVisualizerAttributeMAT(VisualizerAttribute& attr, double time)
{
  if (!attr.isConst) {
    attr.exp = omcGetVarValue(&_matReader, attr.cref.c_str(), time);
  }
}

double VisualizationMAT::omcGetVarValue(ModelicaMatReader* reader, const char* varName, double time)
{
  double val = 0.0;
  ModelicaMatVariable_t* var = nullptr;
  var = omc_matlab4_find_var(reader, varName);
  if (var == nullptr) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                          QString(QObject::tr("Did not get variable from result file. Variable name is %1."))
                                                          .arg(varName), Helper::scriptingKind, Helper::errorLevel));
  } else {
    omc_matlab4_val(&val, reader, var, time);
  }

  return val;
}
