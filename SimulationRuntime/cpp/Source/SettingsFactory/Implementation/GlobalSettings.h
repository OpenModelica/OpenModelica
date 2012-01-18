#pragma once
#include "SettingsFactory/Interfaces/IGlobalSettings.h"
//#include "../Interfaces/APi.h"

class  /*BOOST_EXTENSION_GLOBALSETTINGS_DECL*/ GlobalSettings : public IGlobalSettings
{

public:	
	GlobalSettings(void);
	~GlobalSettings(void);
	///< Start time of integration (default: 0.0)
	/*DLL_EXPORT*/ virtual double getStartTime();
	/*DLL_EXPORT*/ virtual void setStartTime(double);
	///< End time of integraiton (default: 1.0)
	/*DLL_EXPORT*/ virtual double getEndTime();
	/*DLL_EXPORT*/ virtual void getEndTime(double);
	///< Output step size (default: 20 ms)
	/*DLL_EXPORT*/ virtual double gethOutput();
	/*DLL_EXPORT*/ virtual void sethOutput(double);
	///< Write out results ([false,true]; default: true)
	/*DLL_EXPORT*/ virtual bool getResultsOutput();
	/*DLL_EXPORT*/ virtual void setResultsOutput(bool);
	///< Write out statistical simulation infos, e.g. number of steps (at the end of simulation); [false,true]; default: true)
	/*DLL_EXPORT*/ virtual bool getInfoOutput();
	/*DLL_EXPORT*/ virtual void setInfoOutput(bool);
	///path for simulation results in textfile
	/*DLL_EXPORT*/ virtual string	getOutputPath();	
	/*DLL_EXPORT*/ virtual void setOutputPath(string);
	//solver used for simulation
	/*DLL_EXPORT*/ virtual string	getSelectedSolver();	
	/*DLL_EXPORT*/ virtual void setSelectedSolver(string);
	//initializes the settings object by an xml file
	/*DLL_EXPORT*/ void load(std::string xml_file);
private:
	double
		_startTime,			///< Start time of integration (default: 0.0)
		_endTime,			///< End time of integraiton (default: 1.0)
		_hOutput;			///< Output step size (default: 20 ms)

	bool
		_resultsOutput,		///< Write out results ([false,true]; default: true)
		_infoOutput;			///< Write out statistical simulation infos, e.g. number of steps (at the end of simulation); [false,true]; default: true)
	string 
		_output_path,
		selected_solver;

	
	 //Serialization of settings class
	friend class boost::serialization::access;
    template<class archive>
	void serialize(archive& ar, const unsigned int version)

	{

		try
		{
			using boost::serialization::make_nvp;
			ar & make_nvp("SelectedSolver", selected_solver);
			ar & make_nvp("StartTime", _startTime);
			ar & make_nvp("EndTime", _endTime);
			ar & make_nvp("HOutput", _hOutput);
			ar &   make_nvp("ResultsOutput", _resultsOutput);
			ar &   make_nvp("InfoOutput", _infoOutput);
			ar &   make_nvp("OutputPath", _output_path);

		}
		catch(std::exception& ex)
		{
			string error = ex.what();
		}


	}
};
