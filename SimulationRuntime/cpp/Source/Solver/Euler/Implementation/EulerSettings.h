#pragma once
#define BOOST_EXTENSION_SOLVERSETTINGS_DECL BOOST_EXTENSION_IMPORT_DECL
#include "../../Implementation/SolverSettings.h"
#include "../Interfaces/IEulerSettings.h"

/*****************************************************************************/
/**

Encapsulation of settings for euler solver

\date     October, 1st, 2008
\author 


*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class /*BOOST_EXTENSION_EULERSETTINGS_DECL*/ EulerSettings : public IEulerSettings, public SolverSettings
{

public:
	/*DLL_EXPORT*/ EulerSettings(IGlobalSettings* globalSettings);
  /**
	Choise of solution method according to EULERMETHOD ([0,1,2,3,4,5]; default: 0)
	**/
	/*DLL_EXPORT*/ virtual unsigned int getEulerMethod();
	/*DLL_EXPORT*/ virtual  void setEulerMetoh(unsigned int);
	/**
	 Choise of method for zero search according to ZEROSEARCHMETHOD ([0,1]; default: 0)
	*/
	/*DLL_EXPORT*/ virtual unsigned int getZeroSearchMethod();
    /*DLL_EXPORT*/ virtual void setZeroSearchMethod(unsigned int );		
        
	/**
	Determination of number of zeros in one intervall (used only for methods [2,3]) ([true,false]; default: false)
	*/
	/*DLL_EXPORT*/ virtual bool getUseSturmSequence();
	/*DLL_EXPORT*/ virtual void setUseSturmSequence(bool);
	/**
	For implicit methods only. Choise between fixpoint and newton-iteration  kann eine Newtoniteration gewählt werden. ([false,true]; default: false = Fixpunktiteration)
	*/
	/*DLL_EXPORT*/ virtual bool getUseNewtonIteration();
	/*DLL_EXPORT*/ virtual void setUseNewtonIteration(bool);	
	/**
	Equidistant output(by interpolation polynominal) ([true,false]; default: false)
	*/
	/*DLL_EXPORT*/ virtual bool getDenseOutput();
	/*DLL_EXPORT*/ virtual void setDenseOutput(bool);	
        /**
	Tolerance for newton iteration (used when _useNewtonIteration=true) (default: 1e-8)	
	*/
	/*DLL_EXPORT*/ virtual double getIterTol();
	/*DLL_EXPORT*/ virtual void setIterTol(double);
	//initializes the settings object by an xml file
	/*DLL_EXPORT*/ virtual void load(std::string xml_file);
private:
	int 
		_method,				///< Choise of solution method according to EULERMETHOD ([0,1,2,3,4,5]; default: 0)
		_zeroSearchMethod;		///< Choise of method for zero search according to ZEROSEARCHMETHOD ([0,1]; default: 0)

	bool
		_denseOutput,			///< Equidistant output(by interpolation polynominal) ([true,false]; default: false)
		_useNewtonIteration,		///< For implicit methods only. Choise between fixpoint and newton-iteration  kann eine Newtoniteration gewählt werden. ([false,true]; default: false = Fixpunktiteration)
		_useSturmSequence;		///< Determination of number of zeros in one intervall (used only for methods [2,3]) ([true,false]; default: false)

	double
		_iterTol;				///< Tolerance for newton iteration (used when _useNewtonIteration=true) (default: 1e-8)

	//Serialization of settings class
	friend class boost::serialization::access;
    template<class archive>
	void serialize(archive& ar, const unsigned int version)

	{

		try
		{
			using boost::serialization::make_nvp;
			// serialize base class information
            //ar & boost::serialization::base_object<SolverSettings>(*this);
			ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(SolverSettings);
			ar & make_nvp("EulerMethod", _method);
			ar & make_nvp("ZeroSearchMethod", _zeroSearchMethod);
			ar & make_nvp("UseDenseOutput", _denseOutput);
			ar & make_nvp("UseNewtonIteration", _useNewtonIteration);
			ar & make_nvp("UseSturm", _useSturmSequence);

		}
		catch(std::exception& ex)
		{
			string error = ex.what();
		}


	}

};
