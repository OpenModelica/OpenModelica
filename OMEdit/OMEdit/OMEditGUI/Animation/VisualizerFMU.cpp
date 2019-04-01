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


#include "VisualizerFMU.h"


VisualizerFMU::VisualizerFMU(const std::string& modelFile, const std::string& path)
    : VisualizerAbstract(modelFile, path, VisType::FMU),
      mpFMU(nullptr),
      mpSimSettings(new SimSettingsFMU())
{
}
 VisualizerFMU::~VisualizerFMU()
 {
   if (mpFMU){
     free(mpFMU);
   }
 }


void VisualizerFMU::initData()
{
  VisualizerAbstract::initData();
  loadFMU(mpOMVisualBase->getModelFile(), mpOMVisualBase->getPath());
  mpSimSettings->setTend(mpTimeManager->getEndTime());
  mpSimSettings->setHdef(0.001);
  setVarReferencesInVisAttributes();

  //OMVisualizerFMU::initializeVisAttributes(_omvManager->getStartTime());
}

void VisualizerFMU::loadFMU(const std::string& modelFile, const std::string& path)
{
  //load fmu
  allocateContext(modelFile, path);
  if (mVersion == fmi_version_1_enu)
  {
    std::cout<<"Loading FMU 1.0."<<std::endl;
    mpFMU = new FMUWrapper_ME_1();
    mpFMU->load(modelFile, path, mpContext.get());
  }
  else if (mVersion == fmi_version_2_0_enu)
  {
    std::cout<<"Loading FMU 2.0"<<std::endl;
    mpFMU = new FMUWrapper_ME_2();
    mpFMU->load(modelFile, path, mpContext.get());
  }
  else
  {
    std::cout<<"Unknown FMU version. Exciting."<<std::endl;
  }
  std::cout<<"VisualizerFMU::loadFMU: FMU was successfully loaded."<<std::endl;
}

void VisualizerFMU::allocateContext(const std::string& modelFile, const std::string& path)
{
  // First we need to define the callbacks and set up the context.
  mCallbacks.malloc = malloc;
  mCallbacks.calloc = calloc;
  mCallbacks.realloc = realloc;
  mCallbacks.free = free;
  mCallbacks.logger = jm_default_logger;
  mCallbacks.log_level = jm_log_level_error;  // jm_log_level_error;
  mCallbacks.context = 0;
  #ifdef FMILIB_GENERATE_BUILD_STAMP
    std::cout << "Library build stamp: \n" << fmilib_get_build_stamp() << std::endl;
  #endif
  mpContext = std::shared_ptr<fmi_import_context_t>(fmi_import_allocate_context(&mCallbacks), fmi_import_free_context);
  //get version
  std::string fmuFileName = path + modelFile;
  mVersion = fmi_import_get_fmi_version(mpContext.get(), fmuFileName.c_str(), path.c_str());
}

unsigned int VisualizerFMU::getVarReferencesForObjectAttribute(ShapeObjectAttribute* attr)
{
  unsigned int vr = 0;
  if (!attr->isConst)
  {
    vr = mpFMU->fmi_get_variable_by_name(attr->cref.c_str());
  }
  return vr;
}

int VisualizerFMU::setVarReferencesInVisAttributes()
{
  int isOk(0);

  try
  {
    size_t i = 0;
    for (auto& shape : mpOMVisualBase->_shapes)
    {
      shape = mpOMVisualBase->_shapes[i];

      shape._length.fmuValueRef = getVarReferencesForObjectAttribute(&shape._length);
      shape._width.fmuValueRef = getVarReferencesForObjectAttribute(&shape._width);
      shape._height.fmuValueRef = getVarReferencesForObjectAttribute(&shape._height);

      shape._lDir[0].fmuValueRef = getVarReferencesForObjectAttribute(&shape._lDir[0]);
      shape._lDir[1].fmuValueRef = getVarReferencesForObjectAttribute(&shape._lDir[1]);
      shape._lDir[2].fmuValueRef = getVarReferencesForObjectAttribute(&shape._lDir[2]);

      shape._wDir[0].fmuValueRef = getVarReferencesForObjectAttribute(&shape._wDir[0]);
      shape._wDir[1].fmuValueRef = getVarReferencesForObjectAttribute(&shape._wDir[1]);
      shape._wDir[2].fmuValueRef = getVarReferencesForObjectAttribute(&shape._wDir[2]);

      shape._r[0].fmuValueRef = getVarReferencesForObjectAttribute(&shape._r[0]);
      shape._r[1].fmuValueRef = getVarReferencesForObjectAttribute(&shape._r[1]);
      shape._r[2].fmuValueRef = getVarReferencesForObjectAttribute(&shape._r[2]);

      shape._rShape[0].fmuValueRef = getVarReferencesForObjectAttribute(&shape._rShape[0]);
      shape._rShape[1].fmuValueRef = getVarReferencesForObjectAttribute(&shape._rShape[1]);
      shape._rShape[2].fmuValueRef = getVarReferencesForObjectAttribute(&shape._rShape[2]);

      shape._T[0].fmuValueRef = getVarReferencesForObjectAttribute(&shape._T[0]);
      shape._T[1].fmuValueRef = getVarReferencesForObjectAttribute(&shape._T[1]);
      shape._T[2].fmuValueRef = getVarReferencesForObjectAttribute(&shape._T[2]);
      shape._T[3].fmuValueRef = getVarReferencesForObjectAttribute(&shape._T[3]);
      shape._T[4].fmuValueRef = getVarReferencesForObjectAttribute(&shape._T[4]);
      shape._T[5].fmuValueRef = getVarReferencesForObjectAttribute(&shape._T[5]);
      shape._T[6].fmuValueRef = getVarReferencesForObjectAttribute(&shape._T[6]);
      shape._T[7].fmuValueRef = getVarReferencesForObjectAttribute(&shape._T[7]);
      shape._T[8].fmuValueRef = getVarReferencesForObjectAttribute(&shape._T[8]);

      //shape.dumpVisAttributes();
      mpOMVisualBase->_shapes.at(i) = shape;
      ++i;
    }  //end for
  }  // end try

  catch (std::exception& e)
  {
    std::cout<<"Something went wrong in OMVisualizer::setVarReferencesInVisAttributes"<<std::endl;
    isOk = 1;
  }
  return isOk;
}

void VisualizerFMU::simulate(TimeManager& omvm)
{
  while (omvm.getSimTime() < omvm.getRealTime() + omvm.getHVisual() && omvm.getSimTime() < omvm.getEndTime())
    omvm.setSimTime(simulateStep(omvm.getSimTime()));
}

void VisualizerFMU::updateSystem()
{
  // Set states
  mpFMU->setContinuousStates();
  int zero_crossning_event = 0;
  mpFMU->prepareSimulationStep(mpTimeManager->getVisTime());
  bool zeroCrossingEvent = mpFMU->checkForTriggeredEvent();
  if (mpSimSettings->getIterateEvents() && (mpSimSettings->getCallEventUpdate() || zeroCrossingEvent || mpFMU->itsEventTime()))
  {
    mpFMU->handleEvents(mpSimSettings->getIntermediateResults());
  }
  // Solve system
  mpFMU->solveSystem();
  // Step is complete
  mpFMU->completedIntegratorStep(mpSimSettings->getCallEventUpdate());
  updateVisAttributes(mpTimeManager->getVisTime());
}


double VisualizerFMU::simulateStep(const double time)
{
  int zero_crossning_event = 0;
  mpFMU->prepareSimulationStep(time);

  // Check if an event indicator has triggered
  bool zeroCrossingEvent = mpFMU->checkForTriggeredEvent();

  // Handle any events
  if (mpSimSettings->getIterateEvents() && (mpSimSettings->getCallEventUpdate() || zeroCrossingEvent || mpFMU->itsEventTime()))
  {
    mpFMU->handleEvents(mpSimSettings->getIntermediateResults());
  }

  // Updated next time step
  mpFMU->updateNextTimeStep(mpSimSettings->getHdef());

  // last step
  mpFMU->setLastStepSize(mpSimSettings->getTend());

  // Solve system
  mpFMU->solveSystem();

  //print out some values for debugging:
  //std::cout<<"DO EULER at "<< mpFMU->getFMUData()->_tcur<<std::endl;
  //fmi1_import_variable_t* var = fmi1_import_get_variable_by_name(mpFMUl.mpFMU, "prismatic.s");
  //const fmi1_value_reference_t vr  = fmi1_import_get_variable_vr(var);
  //double value = -1.0;
  //fmi1_import_get_real(mpFMUl.mpFMU, &vr, 1, &value);
  //std::cout<<"value "<<value<<std::endl;

  // integrate a step with euler
  mpFMU->doEulerStep();

  // Set states
  mpFMU->setContinuousStates();

  // Step is complete
  mpFMU->completedIntegratorStep(mpSimSettings->getCallEventUpdate());

  return mpFMU->getFMUData()->_tcur;
}

void VisualizerFMU::initializeVisAttributes(const double time)
{
  mpFMU->initialize(mpSimSettings);
  std::cout<<"VisualizerFMU::loadFMU: FMU was successfully initialized."<<std::endl;

  mpTimeManager->setVisTime(mpTimeManager->getStartTime());
  mpTimeManager->setSimTime(mpTimeManager->getStartTime());
  setVarReferencesInVisAttributes();
  updateVisAttributes(mpTimeManager->getVisTime());
}

void VisualizerFMU::updateVisAttributes(const double time)
{
  // Update all shapes.
  rAndT rT;
  osg::ref_ptr<osg::Node> child = nullptr;
  try
  {
    size_t i = 0;
    for (auto& shape : mpOMVisualBase->_shapes)
    {
      // Get the values for the scene graph objects
      updateObjectAttributeFMU(&shape._length, mpFMU);
      updateObjectAttributeFMU(&shape._width, mpFMU);
      updateObjectAttributeFMU(&shape._height, mpFMU);

      updateObjectAttributeFMU(&shape._lDir[0], mpFMU);
      updateObjectAttributeFMU(&shape._lDir[1], mpFMU);
      updateObjectAttributeFMU(&shape._lDir[2], mpFMU);

      updateObjectAttributeFMU(&shape._wDir[0], mpFMU);
      updateObjectAttributeFMU(&shape._wDir[1], mpFMU);
      updateObjectAttributeFMU(&shape._wDir[2], mpFMU);

      updateObjectAttributeFMU(&shape._r[0], mpFMU);
      updateObjectAttributeFMU(&shape._r[1], mpFMU);
      updateObjectAttributeFMU(&shape._r[2], mpFMU);

      updateObjectAttributeFMU(&shape._rShape[0], mpFMU);
      updateObjectAttributeFMU(&shape._rShape[1], mpFMU);
      updateObjectAttributeFMU(&shape._rShape[2], mpFMU);

      updateObjectAttributeFMU(&shape._T[0], mpFMU);
      updateObjectAttributeFMU(&shape._T[1], mpFMU);
      updateObjectAttributeFMU(&shape._T[2], mpFMU);
      updateObjectAttributeFMU(&shape._T[3], mpFMU);
      updateObjectAttributeFMU(&shape._T[4], mpFMU);
      updateObjectAttributeFMU(&shape._T[5], mpFMU);
      updateObjectAttributeFMU(&shape._T[6], mpFMU);
      updateObjectAttributeFMU(&shape._T[7], mpFMU);
      updateObjectAttributeFMU(&shape._T[8], mpFMU);
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

      // Get the scene graph nodes and stuff.
      //mpOMVisScene->dumpOSGTreeDebug();
      child = mpOMVisScene->getScene().getRootNode()->getChild(i);  // the transformation
      child->accept(*mpUpdateVisitor);
      ++i;
    }  //end for
  }  // end try
  catch (std::exception& ex)
  {
    std::string msg = "Error in VisualizerFMU::updateVisAttributes at time point " + std::to_string(time)
                                        + "\n" + std::string(ex.what());
    std::cout<<msg<<std::endl;
    throw(msg);
  }
}

void VisualizerFMU::updateScene(const double time)
{
  mpTimeManager->updateTick(); //for real-time measurement

  mpTimeManager->setSimTime(mpTimeManager->getVisTime());
  double nextStep = mpTimeManager->getVisTime() + mpTimeManager->getHVisual();

  double vis1 = mpTimeManager->getRealTime();
  while (mpTimeManager->getSimTime() < nextStep)
  {
    //std::cout<<"simulate "<<omvManager->_simTime<<" to "<<nextStep<<std::endl;
    mpTimeManager->setSimTime(simulateStep(mpTimeManager->getSimTime()));
  }
  mpTimeManager->updateTick();                     //for real-time measurement
  mpTimeManager->setRealTimeFactor(mpTimeManager->getHVisual() / (mpTimeManager->getRealTime() - vis1));
  updateVisAttributes(mpTimeManager->getVisTime());
}

// Todo pass by const ref
void VisualizerFMU::updateObjectAttributeFMU(ShapeObjectAttribute* attr, FMUWrapperAbstract* fmuWrapper)
{
  if (!attr->isConst)
  {
    double a = attr->exp;
    fmuWrapper->fmi_get_real(&attr->fmuValueRef, &a);
    attr->exp = (float) a;
  }
}

void VisualizerFMU::setSimulationSettings(double stepsize, Solver solver, bool iterateEvents)
{
  mpSimSettings->setHdef(stepsize);
  mpSimSettings->setSolver(solver);
  mpSimSettings->setIterateEvents(iterateEvents);
}

FMUWrapperAbstract* VisualizerFMU::getFMU()
{
  return mpFMU;
};

