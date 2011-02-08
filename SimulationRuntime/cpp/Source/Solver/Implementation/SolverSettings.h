#pragma once

#include "../Interfaces/ISolverSettings.h"
#include "../../SettingsFactory/Interfaces/IGlobalSettings.h"
//#include "../Interfaces/API.h"
#include "../../Math/Implementation/Constants.h"

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
	/*DLL_EXPORT*/ SolverSettings( IGlobalSettings* globalSettings);

	/// Initial step size (default: 1e-2)
	/*DLL_EXPORT*/ virtual double gethInit();
	/*DLL_EXPORT*/ virtual void sethInit(double);
	/// Lower limit for step size during integration (default: should be machine precision)
	/*DLL_EXPORT*/ virtual double getLowerLimit();
	/*DLL_EXPORT*/ virtual void setLowerLimit(double);
	/// Upper limit for step size during integration (default: _endTime-_startTime)
	/*DLL_EXPORT*/ virtual double getUpperLimit();
	/*DLL_EXPORT*/ virtual void setUpperLimit(double);
	/// Tolerance to reach _endTime (default: 1e-6)
	/*DLL_EXPORT*/ virtual double getEndTimeTol();
	/*DLL_EXPORT*/ virtual void setEndTimeTol(double);
	/// Tolerance to find a zero search (abs(f(t))<_zeroTol) (default: 1e-5)
	/*DLL_EXPORT*/ virtual double getZeroTol();
	/*DLL_EXPORT*/ virtual void setZeroTol(double);
	/// Tolerance to find the time of a zero ((t-t_last)<_zeroTimeTol) (default: 1e-12)
	/*DLL_EXPORT*/ virtual double getZeroTimeTol();
	/*DLL_EXPORT*/ virtual void setZeroTimeTol(double) ;
	///  Global simulation settings
	/*DLL_EXPORT*/ virtual IGlobalSettings* getGlobalSettings();
	virtual void load(string);
private:
	double
		_hInit,				///< Initial step size (default: 1e-2)
		_hLowerLimit,		///< Lower limit for step size during integration (default: should be machine precision)
		_hUpperLimit,		///< Upper limit for step size during integration (default: _endTime-_startTime)
		_endTimeTol,			///< Tolerance to reach _endTime (default: 1e-6)
		_zeroTol,			///< Tolerance to find a zero search (abs(f(t))<_zeroTol) (default: 1e-5)
		_zeroTimeTol;		///< Tolerance to find the time of a zero ((t-t_last)<_zeroTimeTol) (default: 1e-12)
		
	 IGlobalSettings*	
		_globalSettings;	///< Global simulation settings


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
