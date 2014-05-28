#include "Modelica.h"
//#define BOOST_EXTENSION_GLOBALSETTINGS_DECL BOOST_EXTENSION_EXPORT_DECL
#include "GlobalSettings.h"

GlobalSettings::GlobalSettings()
: _startTime            (0.0)
, _endTime            (5.0)
, _hOutput            (0.001)
, _resultsOutput        (true)
, _infoOutput        (true)
, _selected_solver("Euler")
,_selected_nonlin_solver("Newton")
,_resultsfile_name("results.csv")
,_endless_sim(false)
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
void GlobalSettings::setEndTime(double time)
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
 bool GlobalSettings::useEndlessSim()
 {
     return _endless_sim ;
 }
 void GlobalSettings::useEndlessSim(bool endles)
 {
     _endless_sim = endles;
 }

OutputFormat GlobalSettings::getOutputFormat()
{
    return _outputFormat;
}
void GlobalSettings::setOutputFormat(OutputFormat format)
{
   _outputFormat=format;
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

 void  GlobalSettings::setResultsFileName(string name)
 {
     _resultsfile_name = name;
 }
 string  GlobalSettings::getResultsFileName()
 {
     return _resultsfile_name;
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
string   GlobalSettings::getOutputPath()
{
    return _output_path ;
}
void GlobalSettings::setOutputPath(string path)
{
    _output_path=path;
}

string   GlobalSettings::getSelectedSolver()
{
    return _selected_solver;
}
void GlobalSettings::setSelectedSolver(string solver)
{
    _selected_solver = solver;
}
string   GlobalSettings::getSelectedNonLinSolver()
{
 return _selected_nonlin_solver;
}
void GlobalSettings::setSelectedNonLinSSolver(string solver)
{
    _selected_nonlin_solver= solver;
}
/**
initializes settings object by an xml file
*/
void GlobalSettings::load(std::string xml_file)
 {
    /*try
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
    }*/

}
  void GlobalSettings::setRuntimeLibrarypath(string path)
  {
  _runtimeLibraryPath=path;
  }
   string GlobalSettings::getRuntimeLibrarypath()
   {
   return _runtimeLibraryPath;
   }
 /* std::fstream ofs;
    ofs.open("C:\\Temp\\GlobalSettings.xml", ios::out);
    boost::archive::xml_oarchive xml(ofs);
    xml << boost::serialization::make_nvp("GlobalSettings", *this);
    ofs.close();*/
