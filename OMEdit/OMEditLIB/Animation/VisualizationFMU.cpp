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

#include "VisualizationFMU.h"

VisualizationFMU::VisualizationFMU(const std::string& modelFile, const std::string& path)
  : VisualizationAbstract(modelFile, path, VisType::FMU),
    mpFMU(nullptr),
    mpSimSettings(new SimSettingsFMU())
{
}

 VisualizationFMU::~VisualizationFMU()
{
  if (mpFMU) {
    free(mpFMU);
  }
}

void VisualizationFMU::initData()
{
  VisualizationAbstract::initData();
  loadFMU(mpOMVisualBase->getModelFile(), mpOMVisualBase->getPath());
  mpSimSettings->setTend(mpTimeManager->getEndTime());
  mpSimSettings->setHdef(0.001);
  setFmuVarRefInVisAttributes();
}

void VisualizationFMU::loadFMU(const std::string& modelFile, const std::string& path)
{
  //load fmu
  allocateContext(modelFile, path);
  if (mVersion == fmi_version_1_enu)
  {
    //std::cout<<"Loading FMU 1.0."<<std::endl;
    mpFMU = new FMUWrapper_ME_1();
    mpFMU->load(modelFile, path, mpContext.get());
  }
  else if (mVersion == fmi_version_2_0_enu)
  {
    //std::cout<<"Loading FMU 2.0"<<std::endl;
    mpFMU = new FMUWrapper_ME_2();
    mpFMU->load(modelFile, path, mpContext.get());
  }
  else
  {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, QObject::tr("Unknown FMU version."),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
  //std::cout<<"VisualizationFMU::loadFMU: FMU was successfully loaded."<<std::endl;
}

void VisualizationFMU::allocateContext(const std::string& modelFile, const std::string& path)
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

unsigned int VisualizationFMU::getFmuVariableReferenceForVisualizerAttribute(VisualizerAttribute& attr)
{
  return getFmuVariableReferenceForVisualizerAttributeFMU(attr);
}

unsigned int VisualizationFMU::getFmuVariableReferenceForVisualizerAttributeFMU(VisualizerAttribute& attr)
{
  unsigned int vr = 0;
  if (!attr.isConst) {
    vr = mpFMU->fmi_get_variable_by_name(attr.cref.c_str());
  }
  return vr;
}

void VisualizationFMU::simulate(TimeManager& omvm)
{
  while (omvm.getSimTime() < omvm.getRealTime() + omvm.getHVisual() && omvm.getSimTime() < omvm.getEndTime())
    omvm.setSimTime(simulateStep(omvm.getSimTime()));
}

void VisualizationFMU::updateSystem()
{
  // Set states
  mpFMU->setContinuousStates();
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

double VisualizationFMU::simulateStep(const double time)
{
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

void VisualizationFMU::initializeVisAttributes(const double time)
{
  Q_UNUSED(time);
  mpFMU->initialize(mpSimSettings);
  //std::cout<<"VisualizationFMU::initializeVisAttributes: FMU was successfully initialized."<<std::endl;

  mpTimeManager->setVisTime(mpTimeManager->getStartTime());
  mpTimeManager->setSimTime(mpTimeManager->getStartTime());
  updateVisAttributes(mpTimeManager->getVisTime());
}

void VisualizationFMU::updateScene(const double time)
{
  Q_UNUSED(time);
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

void VisualizationFMU::updateVisualizerAttribute(VisualizerAttribute& attr, const double time)
{
  Q_UNUSED(time);
  updateVisualizerAttributeFMU(attr);
}

void VisualizationFMU::updateVisualizerAttributeFMU(VisualizerAttribute& attr)
{
  if (!attr.isConst) {
    double a = attr.exp;
    mpFMU->fmi_get_real(&attr.fmuValueRef, &a);
    attr.exp = (float) a;
  }
}

void VisualizationFMU::setSimulationSettings(double stepsize, Solver solver, bool iterateEvents)
{
  mpSimSettings->setHdef(stepsize);
  mpSimSettings->setSolver(solver);
  mpSimSettings->setIterateEvents(iterateEvents);
}

FMUWrapperAbstract* VisualizationFMU::getFMU()
{
  return mpFMU;
};
