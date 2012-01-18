#pragma once
#define BOOST_EXTENSION_SOLVERSETTINGS_DECL BOOST_EXTENSION_IMPORT_DECL
#include "../../Implementation/SolverSettings.h"
#include "../Interfaces/IIdasSettings.h"

class IdasSettings : public IIdasSettings, public  SolverSettings
{

public:
	IdasSettings(IGlobalSettings* globalSettings);
	/**
	Equidistant output(by interpolation polynominal) ([true,false]; default: false)
	*/
	 virtual bool getDenseOutput();
	 virtual void setDenseOutput(bool);	
	 virtual bool getEventOutput();
	 virtual void setEventOutput(bool);	
private:
	 	bool
		_denseOutput,			///< Equidistant output(by interpolation polynominal) ([true,false]; default: false)
		_eventOutput;


};
