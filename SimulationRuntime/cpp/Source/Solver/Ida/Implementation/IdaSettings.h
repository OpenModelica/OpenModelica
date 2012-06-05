#pragma once
#define BOOST_EXTENSION_SOLVERSETTINGS_DECL BOOST_EXTENSION_IMPORT_DECL
#include "Solver/Implementation/SolverSettings.h"
#include "Solver/Ida/Interfaces/IIdaSettings.h"

class IdaSettings : public IIdaSettings, public  SolverSettings
{

public:
  IdaSettings(IGlobalSettings* globalSettings);
  /**
  Equidistant output(by interpolation polynominal) ([true,false]; default: false)
  */
   virtual bool getDenseOutput();
   virtual void setDenseOutput(bool);  
   virtual bool getEventOutput();
   virtual void setEventOutput(bool);  
private:
     bool
    _denseOutput,      ///< Equidistant output(by interpolation polynominal) ([true,false]; default: false)
    _eventOutput;


};
