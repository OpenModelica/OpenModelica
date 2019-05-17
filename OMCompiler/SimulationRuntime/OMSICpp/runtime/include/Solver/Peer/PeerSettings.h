#pragma once
#include "FactoryExport.h"
#include <Core/Solver/SolverSettings.h>


class PeerSettings :  public  SolverSettings
{

public:
  PeerSettings(IGlobalSettings* globalSettings);
  virtual ~PeerSettings();
  /**
  Equidistant output(by interpolation polynominal) ([true,false]; default: false)
  */
   virtual bool getDenseOutput();
   virtual void setDenseOutput(bool);
private:
   bool _denseOutput;      ///< Equidistant output(by interpolation polynominal) ([true,false]; default: false)
};
