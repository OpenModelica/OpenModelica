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

#include "VisualizerMAT.h"

VisualizerMAT::VisualizerMAT(const std::string& modelFile, const std::string& path)
  : VisualizerAbstract(modelFile, path, VisType::MAT),
    _matReader()
{

}

/*!
 * \brief VisualizerMAT::~VisualizerMAT
 * Free the ModelicaMatReader
 */
VisualizerMAT::~VisualizerMAT()
{
  if (_matReader.file) {
    omc_free_matlab4_reader(&_matReader);
  }
}

void VisualizerMAT::initData()
{
  VisualizerAbstract::initData();
  readMat(mpOMVisualBase->getModelFile(), mpOMVisualBase->getPath());
  mpTimeManager->setStartTime(omc_matlab4_startTime(&_matReader));
  mpTimeManager->setEndTime(omc_matlab4_stopTime(&_matReader));
}

void VisualizerMAT::initializeVisAttributes(const double time)
{
  if (0.0 > time)
    std::cout<<"Cannot load visualization attributes for time point < 0.0."<<std::endl;
  updateVisAttributes(time);
}

void VisualizerMAT::readMat(const std::string& modelFile, const std::string& path)
{
  std::string resFileName = path + modelFile;     // + "_res.mat";

  // Check if the MAT file exists.
  if (!fileExists(resFileName))
  {
    std::string msg = "Could not find MAT file" + resFileName + ".";
    std::cout<<msg<<std::endl;
  }
  else
  {
    // Read mat file.
    auto ret = omc_new_matlab4_reader(resFileName.c_str(), &_matReader);
    // Check return value.
    if (0 != ret)
    {
      std::string msg(ret);
      std::cout<<msg<<std::endl;
    }
  }

  /*
     FILE * fileA = fopen("allVArs.txt", "w+");
     omc_matlab4_print_all_vars(fileA, &matReader);
     fclose(fileA);
     */
}

void VisualizerMAT::setSimulationSettings(const UserSimSettingsMAT& simSetMAT)
{
  auto newVal = simSetMAT.speedup * mpTimeManager->getHVisual();
  mpTimeManager->setHVisual(newVal);
}

void VisualizerMAT::updateVisAttributes(const double time)
{
  //std::cout<<"updateVisAttributes at "<<time <<std::endl;
  // Update all shapes.
  unsigned int shapeIdx = 0;
  rAndT rT;
  osg::ref_ptr<osg::Node> child = nullptr;
  ModelicaMatReader* tmpReaderPtr = &_matReader;
  try
  {
    for (auto& shape : mpOMVisualBase->_shapes)
    {
      //std::cout<<"shape "<<shape._id <<std::endl;

      // Get the values for the scene graph objects
      updateObjectAttributeMAT(&shape._length, time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._width, time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._height, time, tmpReaderPtr);

      updateObjectAttributeMAT(&shape._lDir[0], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._lDir[1], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._lDir[2], time, tmpReaderPtr);

      updateObjectAttributeMAT(&shape._wDir[0], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._wDir[1], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._wDir[2], time, tmpReaderPtr);

      updateObjectAttributeMAT(&shape._r[0], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._r[1], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._r[2], time, tmpReaderPtr);

      updateObjectAttributeMAT(&shape._rShape[0], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._rShape[1], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._rShape[2], time, tmpReaderPtr);

      updateObjectAttributeMAT(&shape._T[0], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._T[1], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._T[2], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._T[3], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._T[4], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._T[5], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._T[6], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._T[7], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._T[8], time, tmpReaderPtr);

      updateObjectAttributeMAT(&shape._color[0], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._color[1], time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._color[2], time, tmpReaderPtr);

      updateObjectAttributeMAT(&shape._specCoeff, time, tmpReaderPtr);
      updateObjectAttributeMAT(&shape._extra, time, tmpReaderPtr);

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
  }
  catch (std::exception& ex)
  {
    std::string msg = "Error in VisualizerMAT::updateVisAttributes at time point " + std::to_string(time)
        + "\n" + std::string(ex.what());
    throw(msg);
  }
}

void VisualizerMAT::updateScene(const double time)
{
  mpTimeManager->updateTick();  //for real-time measurement
  double visTime = mpTimeManager->getRealTime();
  updateVisAttributes(time);
  mpTimeManager->updateTick();  //for real-time measurement
  visTime = mpTimeManager->getRealTime() - visTime;
  mpTimeManager->setRealTimeFactor(mpTimeManager->getHVisual() / visTime);
}

void VisualizerMAT::updateObjectAttributeMAT(ShapeObjectAttribute* attr, double time, ModelicaMatReader* reader)
{
  if (!attr->isConst)
    attr->exp = omcGetVarValue(reader, attr->cref.c_str(), time);
}

double VisualizerMAT::omcGetVarValue(ModelicaMatReader* reader, const char* varName, double time)
{
    double val = 0.0;
    ModelicaMatVariable_t* var = nullptr;
    var = omc_matlab4_find_var(reader, varName);
    if (var == nullptr)
        std::cout<<"Did not get variable from result file. Variable name is "<<std::string(varName)<<std::endl;
    else
        omc_matlab4_val(&val, reader, var, time);

    return val;
}

