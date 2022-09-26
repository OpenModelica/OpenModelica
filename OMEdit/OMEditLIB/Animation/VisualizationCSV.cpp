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

#include "VisualizationCSV.h"

VisualizationCSV::VisualizationCSV(const std::string& modelFile, const std::string& path)
  : VisualizationAbstract(modelFile, path, VisType::CSV), mpCSVData(0)
{

}

VisualizationCSV::~VisualizationCSV()
{
  if (mpCSVData) {
    omc_free_csv_reader(mpCSVData);
  }
}

void VisualizationCSV::initData()
{
  VisualizationAbstract::initData();
  readCSV(mpOMVisualBase->getModelFile(), mpOMVisualBase->getPath());
  double *time = read_csv_dataset(mpCSVData, "time");
  if (time) {
    mpTimeManager->setStartTime(time[0]);
    mpTimeManager->setEndTime(time[mpCSVData->numsteps - 1]);
  }
}

void VisualizationCSV::initializeVisAttributes(const double time)
{
  if (0.0 > time) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                          QObject::tr("Cannot load visualization attributes for time point < 0.0."),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
  updateVisAttributes(time);
}

void VisualizationCSV::readCSV(const std::string& modelFile, const std::string& path)
{
  std::string resFileName = path + modelFile;     // + "_res.csv";

  // Check if the file exists.
  if (!fileExists(resFileName)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, QString(QObject::tr("Could not find CSV file %1."))
                                                          .arg(resFileName.c_str()), Helper::scriptingKind, Helper::errorLevel));
  } else {
    // Read mat file.
    mpCSVData = read_csv(resFileName.c_str());
    // Check return value.
    if (!mpCSVData) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, QString(QObject::tr("Could not read CSV file %1."))
                                                            .arg(resFileName.c_str()), Helper::scriptingKind, Helper::errorLevel));
    }
  }
}

void VisualizationCSV::updateVisAttributes(const double time)
{
  // Update all visualizers
  //std::cout<<"updateVisAttributes at "<<time <<std::endl;

  try
  {
    for (ShapeObject& shape : mpOMVisualBase->_shapes)
    {
      // Get the values for the scene graph objects
      //std::cout<<"shape "<<shape._id <<std::endl;

      updateVisualizerAttributeCSV(shape._T[0], time);
      updateVisualizerAttributeCSV(shape._T[1], time);
      updateVisualizerAttributeCSV(shape._T[2], time);
      updateVisualizerAttributeCSV(shape._T[3], time);
      updateVisualizerAttributeCSV(shape._T[4], time);
      updateVisualizerAttributeCSV(shape._T[5], time);
      updateVisualizerAttributeCSV(shape._T[6], time);
      updateVisualizerAttributeCSV(shape._T[7], time);
      updateVisualizerAttributeCSV(shape._T[8], time);

      updateVisualizerAttributeCSV(shape._r[0], time);
      updateVisualizerAttributeCSV(shape._r[1], time);
      updateVisualizerAttributeCSV(shape._r[2], time);

      updateVisualizerAttributeCSV(shape._color[0], time);
      updateVisualizerAttributeCSV(shape._color[1], time);
      updateVisualizerAttributeCSV(shape._color[2], time);

      updateVisualizerAttributeCSV(shape._specCoeff, time);

      updateVisualizerAttributeCSV(shape._rShape[0], time);
      updateVisualizerAttributeCSV(shape._rShape[1], time);
      updateVisualizerAttributeCSV(shape._rShape[2], time);

      updateVisualizerAttributeCSV(shape._lDir[0], time);
      updateVisualizerAttributeCSV(shape._lDir[1], time);
      updateVisualizerAttributeCSV(shape._lDir[2], time);

      updateVisualizerAttributeCSV(shape._wDir[0], time);
      updateVisualizerAttributeCSV(shape._wDir[1], time);
      updateVisualizerAttributeCSV(shape._wDir[2], time);

      updateVisualizerAttributeCSV(shape._length, time);
      updateVisualizerAttributeCSV(shape._width, time);
      updateVisualizerAttributeCSV(shape._height, time);

      updateVisualizerAttributeCSV(shape._extra, time);

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

      updateVisualizerAttributeCSV(vector._T[0], time);
      updateVisualizerAttributeCSV(vector._T[1], time);
      updateVisualizerAttributeCSV(vector._T[2], time);
      updateVisualizerAttributeCSV(vector._T[3], time);
      updateVisualizerAttributeCSV(vector._T[4], time);
      updateVisualizerAttributeCSV(vector._T[5], time);
      updateVisualizerAttributeCSV(vector._T[6], time);
      updateVisualizerAttributeCSV(vector._T[7], time);
      updateVisualizerAttributeCSV(vector._T[8], time);

      updateVisualizerAttributeCSV(vector._r[0], time);
      updateVisualizerAttributeCSV(vector._r[1], time);
      updateVisualizerAttributeCSV(vector._r[2], time);

      updateVisualizerAttributeCSV(vector._color[0], time);
      updateVisualizerAttributeCSV(vector._color[1], time);
      updateVisualizerAttributeCSV(vector._color[2], time);

      updateVisualizerAttributeCSV(vector._specCoeff, time);

      updateVisualizerAttributeCSV(vector._coords[0], time);
      updateVisualizerAttributeCSV(vector._coords[1], time);
      updateVisualizerAttributeCSV(vector._coords[2], time);

      updateVisualizerAttributeCSV(vector._quantity, time);

      updateVisualizerAttributeCSV(vector._headAtOrigin, time);

      updateVisualizerAttributeCSV(vector._twoHeadedArrow, time);

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
    QString msg = QString(QObject::tr("Error in VisualizationCSV::updateVisAttributes at time point %1\n%2."))
                  .arg(QString::number(time), ex.what());
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, msg, Helper::scriptingKind, Helper::errorLevel));
    throw(msg.toStdString());
  }
}

void VisualizationCSV::updateScene(const double time)
{
  mpTimeManager->updateTick();  //for real-time measurement
  double visTime = mpTimeManager->getRealTime();
  updateVisAttributes(time);
  mpTimeManager->updateTick();  //for real-time measurement
  visTime = mpTimeManager->getRealTime() - visTime;
  mpTimeManager->setRealTimeFactor(mpTimeManager->getHVisual() / visTime);
}

void VisualizationCSV::updateVisualizerAttributeCSV(VisualizerAttribute& attr, double time)
{
  if (!attr.isConst) {
    attr.exp = omcGetVarValue(attr.cref.c_str(), time);
  }
}

double VisualizationCSV::omcGetVarValue(const char* varName, double time)
{
  double *timeDataSet = read_csv_dataset(mpCSVData, "time");
  for (int i = 0 ; i < mpCSVData->numsteps ; i++) {
    if (timeDataSet[i] == time) {
      double *varDataSet = read_csv_dataset(mpCSVData, varName);
      if (varDataSet) {
        return varDataSet[i];
      } else {
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                              QString(QObject::tr("Did not get variable from result file. Variable name is %1."))
                                                              .arg(varName), Helper::scriptingKind, Helper::errorLevel));
      }
    } else if ((time > timeDataSet[i]) && (i + 1 < mpCSVData->numsteps) && (time < timeDataSet[i + 1])) { // interpolate
      double *varDataSet = read_csv_dataset(mpCSVData, varName);
      if (varDataSet) {
        return (varDataSet[i] + varDataSet[i + 1]) / 2;
      } else {
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                              QString(QObject::tr("Did not get variable from result file. Variable name is %1."))
                                                              .arg(varName), Helper::scriptingKind, Helper::errorLevel));
      }
    }
  }
  return 0.0;
}
