#pragma once
#include "FactoryExport.h"
#include <Core/Solver/SolverSettings.h>


class ARKodeSettings :  public  SolverSettings
{

public:
  ARKodeSettings(IGlobalSettings* globalSettings);
  virtual ~ARKodeSettings();
  /**
  Equidistant output(by interpolation polynominal) ([true,false]; default: false)
  */
   virtual bool getDenseOutput();
   virtual void setDenseOutput(bool);
private:
   bool _denseOutput;      ///< Equidistant output(by interpolation polynominal) ([true,false]; default: false)
};
