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
    /// Tolerance to find a zero search (abs(f(t))<_zeroTol) (default: 1e-5)
     virtual double getZeroTol();
     virtual void setZeroTol(double);
    /// Tolerance to find the time of a zero ((t-t_last)<_zeroTimeTol) (default: 1e-12)
     virtual double getZeroTimeTol();
   virtual void setZeroTimeTol(double) ;

        virtual double getZeroRatio();
    virtual void setZeroRatio(double) ;
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
    _zeroTol,      ///< Tolerance to find a zero search (abs(f(t))<_zeroTol) (default: 1e-5)
    _zeroTimeTol,    ///< Tolerance to find the time of a zero ((t-t_last)<_zeroTimeTol) (default: 1e-12)
    _zeroRatio,    ///< = Hinit_{afterZero} / Hinit_{orig} Verhältnis zwischen Originaler Initialschrittweite und Anfangsschrittweite nach Neustart des Solvers
  _dRtol,
   _dAtol;
    IGlobalSettings*
    _globalSettings;  ///< Global simulation settings


     //Serialization of settings class
    friend class boost::serialization::access;
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


    }

};
