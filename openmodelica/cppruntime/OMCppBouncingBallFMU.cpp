// define model identifier and unique id
#define MODEL_IDENTIFIER BouncingBall
#define MODEL_SIMVARS_FACTORY BouncingBallFMU::createSimVars
#define MODEL_GUID "{8c4e810f-3df3-4a00-8276-176fa3c9f9e0}"

/* TODO: implement external functions in FMU wrapper for c++ target
*/
#define NUMBER_OF_EVENT_INDICATORS 2

#include "FMU/FMUWrapper.cpp"
#include "FMU/FMULibInterface.cpp"

// create simulation variables
#include <System/FactoryExport.h>
#include <System/SimVars.h>

ISimVars *BouncingBallFMU::createSimVars() {
  return new SimVars(8, 2, 6, 16, 2, 0);
}

// constructor
BouncingBallFMU::BouncingBallFMU(IGlobalSettings* globalSettings,
    boost::shared_ptr<IAlgLoopSolverFactory> nonLinSolverFactory,
    boost::shared_ptr<ISimData> simData,
    boost::shared_ptr<ISimVars> simVars):
  BouncingBall(globalSettings, nonLinSolverFactory, simData, simVars),
  BouncingBallExtension(globalSettings, nonLinSolverFactory, simData, simVars) {
}

// initialization
void BouncingBallFMU::initialize() {
  BouncingBallWriteOutput::initialize();
  BouncingBallInitialize::initializeMemory();
  BouncingBallInitialize::initializeFreeVariables();
  BouncingBallJacobian::initialize();
  BouncingBallJacobian::initializeColoredJacobianA();
}

// getters
void BouncingBallFMU::getReal(const unsigned int vr[], int nvr,  double value[]) {
  for (int i = 0; i < nvr; i++)
    switch (vr[i]) {
      case 0: /* h "height of ball" */
        value[i] = __z[0]; break;
      case 1: /* v "velocity of ball" */
        value[i] = __z[1]; break;
      case 2: /* der(h) "height of ball" */
        value[i] = __zDot[0]; break;
      case 3: /* der(v) "velocity of ball" */
        value[i] = __zDot[1]; break;
      case 4: /* v_new */
        value[i] = _v_new; break;
      case 5: /* e "coefficient of restitution" */
        value[i] = _e; break;
      case 6: /* g "gravity acceleration" */
        value[i] = _g; break;
      default:
        std::ostringstream message;
        message << "getReal with wrong value reference " << vr[i];
        throw std::invalid_argument(message.str());
    }
}

void BouncingBallFMU::getInteger(const unsigned int vr[], int nvr,  int value[]) {
  for (int i = 0; i < nvr; i++)
    switch (vr[i]) {
      case 0: /* n_bounce */
        value[i] = _n_bounce; break;
      default:
        std::ostringstream message;
        message << "getInteger with wrong value reference " << vr[i];
        throw std::invalid_argument(message.str());
    }
}

void BouncingBallFMU::getBoolean(const unsigned int vr[], int nvr,  int value[]) {
  for (int i = 0; i < nvr; i++)
    switch (vr[i]) {
      case 0: /* _D_whenCondition1 */
        value[i] = _$whenCondition1; break;
      case 1: /* _D_whenCondition2 */
        value[i] = _$whenCondition2; break;
      case 2: /* _D_whenCondition3 */
        value[i] = _$whenCondition3; break;
      case 3: /* flying "true, if ball is flying" */
        value[i] = _flying; break;
      case 4: /* impact */
        value[i] = _impact; break;
      default:
        std::ostringstream message;
        message << "getBoolean with wrong value reference " << vr[i];
        throw std::invalid_argument(message.str());
    }
}

void BouncingBallFMU::getString(const unsigned int vr[], int nvr,  string value[]) {
  for (int i = 0; i < nvr; i++)
    switch (vr[i]) {
      default:
        std::ostringstream message;
        message << "getString with wrong value reference " << vr[i];
        throw std::invalid_argument(message.str());
    }
}

// setters
void BouncingBallFMU::setReal(const unsigned int vr[], int nvr, const double value[]) {
  for (int i = 0; i < nvr; i++)
    switch (vr[i]) {
      case 0: /* h "height of ball" */
        __z[0] = value[i]; break;
      case 1: /* v "velocity of ball" */
        __z[1] = value[i]; break;
      case 2: /* der(h) "height of ball" */
        __zDot[0] = value[i]; break;
      case 3: /* der(v) "velocity of ball" */
        __zDot[1] = value[i]; break;
      case 4: /* v_new */
        _v_new = value[i]; break;
      case 5: /* e "coefficient of restitution" */
        _e = value[i]; break;
      case 6: /* g "gravity acceleration" */
        _g = value[i]; break;
      default:
        std::ostringstream message;
        message << "setReal with wrong value reference " << vr[i];
        throw std::invalid_argument(message.str());
    }
}

void BouncingBallFMU::setInteger(const unsigned int vr[], int nvr, const int value[]) {
  for (int i = 0; i < nvr; i++)
    switch (vr[i]) {
      case 0: /* n_bounce */
        _n_bounce = value[i]; break;
      default:
        std::ostringstream message;
        message << "setInteger with wrong value reference " << vr[i];
        throw std::invalid_argument(message.str());
    }
}

void BouncingBallFMU::setBoolean(const unsigned int vr[], int nvr, const int value[]) {
  for (int i = 0; i < nvr; i++)
    switch (vr[i]) {
      case 0: /* _D_whenCondition1 */
        _$whenCondition1 = value[i]; break;
      case 1: /* _D_whenCondition2 */
        _$whenCondition2 = value[i]; break;
      case 2: /* _D_whenCondition3 */
        _$whenCondition3 = value[i]; break;
      case 3: /* flying "true, if ball is flying" */
        _flying = value[i]; break;
      case 4: /* impact */
        _impact = value[i]; break;
      default:
        std::ostringstream message;
        message << "setBoolean with wrong value reference " << vr[i];
        throw std::invalid_argument(message.str());
    }
}

void BouncingBallFMU::setString(const unsigned int vr[], int nvr, const string value[]) {
  for (int i = 0; i < nvr; i++)
    switch (vr[i]) {
      default:
        std::ostringstream message;
        message << "setString with wrong value reference " << vr[i];
        throw std::invalid_argument(message.str());
    }
}

