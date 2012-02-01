#include "stdafx.h"
//#define BOOST_EXTENSION_GLOBALSETTINGS_DECL BOOST_EXTENSION_EXPORT_DECL
#include "GlobalSettings.h"


GlobalSettings::GlobalSettings()
: _startTime			(0.0)
, _endTime			(1)
, _hOutput			(1e-4)
, _resultsOutput		(true)	
, _infoOutput		(true)
, selected_solver("Euler")
{
	
}

GlobalSettings::~GlobalSettings()
{
}
///< Start time of integration (default: 0.0)
double GlobalSettings::getStartTime()
{
	return _startTime;
}
void GlobalSettings::setStartTime(double time)
{
	_startTime = time;
}
///< End time of integraiton (default: 1.0)
double GlobalSettings::getEndTime()
{
	return _endTime;
}
void GlobalSettings::getEndTime(double time)
{
	_endTime=time;
}
///< Output step size (default: 20 ms)
double GlobalSettings::gethOutput()
{
	return _hOutput;
}
void GlobalSettings::sethOutput(double h)
{
	_hOutput=h;
}
///< Write out results ([false,true]; default: true)
bool GlobalSettings::getResultsOutput()
{
	return _resultsOutput;
}
void GlobalSettings::setResultsOutput(bool output)
{
	_resultsOutput  =output;
}
///< Write out statistical simulation infos, e.g. number of steps (at the end of simulation); [false,true]; default: true)
bool GlobalSettings::getInfoOutput()
{
	return _infoOutput;
}
void GlobalSettings::setInfoOutput(bool output)
{
	_infoOutput =output;
}
string	GlobalSettings::getOutputPath()
{
	return _output_path ;
}	
void GlobalSettings::setOutputPath(string path)
{
	_output_path=path;
}		

string	GlobalSettings::getSelectedSolver()
{
	return selected_solver;
}
void GlobalSettings::setSelectedSolver(string solver)
{
	selected_solver = solver;
}

/**
initializes settings object by an xml file
*/
void GlobalSettings::load(std::string xml_file)
 {
	try
	{

	std::ifstream ifs(xml_file.c_str());
	if(!ifs.good())
	cout<< "Settings file not found for :"  << xml_file << std::endl;
	else
	{
	boost::archive::xml_iarchive xml(ifs);
	xml >>boost::serialization::make_nvp("GlobalSettings", *this); 
	ifs.close();
	}
	}
	catch(std::exception& ex)
	{
	std::string error = ex.what();
	cout<< error <<std::endl;
	}
  
}

 /* std::fstream ofs;
	ofs.open("C:\\Temp\\GlobalSettings.xml", ios::out);
	boost::archive::xml_oarchive xml(ofs);
	xml << boost::serialization::make_nvp("GlobalSettings", *this); 
	ofs.close();*/