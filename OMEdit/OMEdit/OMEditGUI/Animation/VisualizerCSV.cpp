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

#include "VisualizerCSV.h"

VisualizerCSV::VisualizerCSV(const std::string& modelFile, const std::string& path)
  : VisualizerAbstract(modelFile, path, VisType::CSV), mpCSVData(0)
{

}

VisualizerCSV::~VisualizerCSV()
{
  if (mpCSVData) {
    omc_free_csv_reader(mpCSVData);
  }
}

void VisualizerCSV::initData()
{
  VisualizerAbstract::initData();
  readCSV(mpOMVisualBase->getModelFile(), mpOMVisualBase->getPath());
  double *time = read_csv_dataset(mpCSVData, "time");
  if (time) {
    mpTimeManager->setStartTime(time[0]);
    mpTimeManager->setEndTime(time[mpCSVData->numsteps - 1]);
  }
}

void VisualizerCSV::initializeVisAttributes(const double time)
{
  if (0.0 > time) {
    std::cout<<"Cannot load visualization attributes for time point < 0.0."<<std::endl;
  }
  updateVisAttributes(time);
}

void VisualizerCSV::readCSV(const std::string& modelFile, const std::string& path)
{
  std::string resFileName = path + modelFile;     // + "_res.csv";

  // Check if the file exists.
  if (!fileExists(resFileName)) {
    std::string msg = "Could not find CSV file" + resFileName + ".";
    std::cout<<msg<<std::endl;
  } else {
    // Read mat file.
    mpCSVData = read_csv(resFileName.c_str());
    // Check return value.
    if (!mpCSVData) {
      std::string msg = "Could not read CSV file" + resFileName + ".";
      std::cout<<msg<<std::endl;
    }
  }
}

void VisualizerCSV::updateVisAttributes(const double time)
{
  //std::cout<<"updateVisAttributes at "<<time <<std::endl;
  // Update all shapes.
  unsigned int shapeIdx = 0;
  rAndT rT;
  osg::ref_ptr<osg::Node> child = nullptr;
  try {
    for (ShapeObject &shape : mpOMVisualBase->_shapes) {
      //std::cout<<"shape "<<shape._id <<std::endl;

      // Get the values for the scene graph objects
      updateObjectAttributeCSV(&shape._length, time);
      updateObjectAttributeCSV(&shape._width, time);
      updateObjectAttributeCSV(&shape._height, time);

      updateObjectAttributeCSV(&shape._lDir[0], time);
      updateObjectAttributeCSV(&shape._lDir[1], time);
      updateObjectAttributeCSV(&shape._lDir[2], time);

      updateObjectAttributeCSV(&shape._wDir[0], time);
      updateObjectAttributeCSV(&shape._wDir[1], time);
      updateObjectAttributeCSV(&shape._wDir[2], time);

      updateObjectAttributeCSV(&shape._r[0], time);
      updateObjectAttributeCSV(&shape._r[1], time);
      updateObjectAttributeCSV(&shape._r[2], time);

      updateObjectAttributeCSV(&shape._rShape[0], time);
      updateObjectAttributeCSV(&shape._rShape[1], time);
      updateObjectAttributeCSV(&shape._rShape[2], time);

      updateObjectAttributeCSV(&shape._T[0], time);
      updateObjectAttributeCSV(&shape._T[1], time);
      updateObjectAttributeCSV(&shape._T[2], time);
      updateObjectAttributeCSV(&shape._T[3], time);
      updateObjectAttributeCSV(&shape._T[4], time);
      updateObjectAttributeCSV(&shape._T[5], time);
      updateObjectAttributeCSV(&shape._T[6], time);
      updateObjectAttributeCSV(&shape._T[7], time);
      updateObjectAttributeCSV(&shape._T[8], time);

      updateObjectAttributeCSV(&shape._color[0], time);
      updateObjectAttributeCSV(&shape._color[1], time);
      updateObjectAttributeCSV(&shape._color[2], time);

      updateObjectAttributeCSV(&shape._specCoeff, time);
      updateObjectAttributeCSV(&shape._extra, time);

      rT = rotateModelica2OSG(osg::Vec3f(shape._r[0].exp, shape._r[1].exp, shape._r[2].exp),
          osg::Vec3f(shape._rShape[0].exp, shape._rShape[1].exp, shape._rShape[2].exp),
          osg::Matrix3(shape._T[0].exp, shape._T[1].exp, shape._T[2].exp,
          shape._T[3].exp, shape._T[4].exp, shape._T[5].exp,
          shape._T[6].exp, shape._T[7].exp, shape._T[8].exp),
          osg::Vec3f(shape._lDir[0].exp, shape._lDir[1].exp, shape._lDir[2].exp),
          osg::Vec3f(shape._wDir[0].exp, shape._wDir[1].exp, shape._wDir[2].exp),
          shape._length.exp,/* shape._width.exp, shape._height.exp,*/ shape._type);

      assemblePokeMatrix(shape._mat, rT._T, rT._r);
      // Update the shapes.
      mpUpdateVisitor->_shape = shape;
      //shape.dumpVisAttributes();
      // Get the scene graph nodes and stuff.
      child = mpOMVisScene->getScene().getRootNode()->getChild(shapeIdx);  // the transformation
      child->accept(*mpUpdateVisitor);
      ++shapeIdx;
    }
  } catch (std::exception& ex) {
    std::string msg = "Error in VisualizerCSV::updateVisAttributes at time point " + std::to_string(time)
        + "\n" + std::string(ex.what());
    throw(msg);
  }
}

void VisualizerCSV::updateScene(const double time)
{
  mpTimeManager->updateTick();  //for real-time measurement
  double visTime = mpTimeManager->getRealTime();
  updateVisAttributes(time);
  mpTimeManager->updateTick();  //for real-time measurement
  visTime = mpTimeManager->getRealTime() - visTime;
  mpTimeManager->setRealTimeFactor(mpTimeManager->getHVisual() / visTime);
}

void VisualizerCSV::updateObjectAttributeCSV(ShapeObjectAttribute* attr, double time)
{
  if (!attr->isConst) {
    attr->exp = omcGetVarValue(attr->cref.c_str(), time);
  }
}

double VisualizerCSV::omcGetVarValue(const char* varName, double time)
{
  double *timeDataSet = read_csv_dataset(mpCSVData, "time");
  for (int i = 0 ; i < mpCSVData->numsteps ; i++) {
    if (timeDataSet[i] == time) {
      double *varDataSet = read_csv_dataset(mpCSVData, varName);
      if (varDataSet) {
        return varDataSet[i];
      } else {
        std::cout<<"Did not get variable from result file. Variable name is "<<std::string(varName)<<std::endl;
      }
    } else if ((time > timeDataSet[i]) && (i + 1 < mpCSVData->numsteps) && (time < timeDataSet[i + 1])) { // interpolate
      double *varDataSet = read_csv_dataset(mpCSVData, varName);
      if (varDataSet) {
        return (varDataSet[i] + varDataSet[i + 1]) / 2;
      } else {
        std::cout<<"Did not get variable from result file. Variable name is "<<std::string(varName)<<std::endl;
      }
    }
  }
  return 0.0;
}
