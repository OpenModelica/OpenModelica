#pragma once
#include "FactoryExport.h"
#include <Solver/SolverSettings.h>


class CVodeSettings :  public  SolverSettings
{

public:
  CVodeSettings(IGlobalSettings* globalSettings);
  virtual ~CVodeSettings();
  /**
  Equidistant output(by interpolation polynominal) ([true,false]; default: false)
  */
   virtual bool getDenseOutput();
   virtual void setDenseOutput(bool);
private:
   bool _denseOutput;      ///< Equidistant output(by interpolation polynominal) ([true,false]; default: false)
};
