#pragma once

#include "ISolverSettings.h"



/*****************************************************************************/
/**

Encapsulation of general solver settings.

\date     October, 1st, 2008
\author


*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
#if defined(ANALYZATION_MODE)
#undef BOOST_EXTENSION_SOLVERSETTINGS_DECL
#define BOOST_EXTENSION_SOLVERSETTINGS_DECL
#endif
class BOOST_EXTENSION_SOLVERSETTINGS_DECL SolverSettings : public ISolverSettings
{
public:
     SolverSettings( IGlobalSettings* globalSettings);

  /// Initial step size (default: 1e-2)
   virtual double gethInit();
  virtual void sethInit(double);
  /// Lower limit for step size during integration (default: should be machine precision)
  virtual double getLowerLimit();
  virtual void setLowerLimit(double);
  /// Upper limit for step size during integration (default: _endTime-_startTime)
  virtual double getUpperLimit();
  virtual void setUpperLimit(double);
  /// Tolerance to reach _endTime (default: 1e-6)
   virtual double getEndTimeTol();
  virtual void setEndTimeTol(double);

  //dense Output 
  virtual bool getDenseOutput();
   virtual void setDenseOutput(bool);
   //Event Output 
   virtual bool getEventOutput();
   virtual void setEventOutput(bool);
  
   
   virtual double getATol();
  virtual void setATol(double);
   virtual double getRTol();
  virtual void setRTol(double);

   ///  Global simulation settings
    virtual IGlobalSettings* getGlobalSettings();
    virtual void load(string);
private:
  double
    _hInit,        ///< Initial step size (default: 1e-2)
    _hLowerLimit,    ///< Lower limit for step size during integration (default: should be machine precision)
    _hUpperLimit,    ///< Upper limit for step size during integration (default: _endTime-_startTime)
    _endTimeTol,      ///< Tolerance to reach _endTime (default: 1e-6)
  _dRtol,
    _dAtol;
    IGlobalSettings*  
    _globalSettings;  ///< Global simulation settings

  bool
    _denseOutput,
    _eventOutput;
   

   //Serialization of settings class
  /*friend class boost::serialization::access;     vxworkstodo
    template<class archive>
  void serialize(archive& ar, const unsigned int version)

    {

        try
        {
            using boost::serialization::make_nvp;
            ar & make_nvp("HInit", _hInit);
            ar & make_nvp("LowerLimit", _hLowerLimit);
            ar & make_nvp("UpperLimit", _hUpperLimit);
            ar &   make_nvp("EndTimeTol", _endTimeTol);
            ar &   make_nvp("ZeroTol", _zeroTol);
            ar &   make_nvp("ZeroTimeTol", _zeroTimeTol);

        }
        catch(std::exception& ex)
        {
            string error = ex.what();
        }


  }*/
};
