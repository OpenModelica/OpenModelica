#pragma once
#define BOOST_EXTENSION_SOLVERSETTINGS_DECL BOOST_EXTENSION_EXPORT_DECL
#include <Solver/SolverSettings.h>
#include <CVode/ICVodeSettings.h>

class CVodeSettings : public ICVodeSettings, public  SolverSettings
{

public:
  CVodeSettings(IGlobalSettings* globalSettings);
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
