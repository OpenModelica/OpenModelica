#pragma once
#include "FactoryExport.h"
#include <Core/Solver/SolverSettings.h>


class CppDASSLSettings :  public  SolverSettings
{

public:
  CppDASSLSettings(IGlobalSettings* globalSettings);
  virtual ~CppDASSLSettings();
  /**
  Equidistant output(by interpolation polynominal) ([true,false]; default: false)
  */
   virtual bool getDenseOutput();
   virtual void setDenseOutput(bool);
private:
   bool _denseOutput;      ///< Equidistant output(by interpolation polynominal) ([true,false]; default: false)
};
