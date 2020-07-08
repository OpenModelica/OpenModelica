#include <Core/Modelica.h>
#include <Core/ReduceDAE/com/ModelicaCompiler.h>
#include <boost/foreach.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/algorithm/string/join.hpp>
#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>

//#include <string>
//#include <iostream>
#include <tchar.h>
namespace fs = boost::filesystem;

ModelicaCompiler::ModelicaCompiler(string model,string file_name,string model_path,bool load_file, bool load_package)
:
_model(model)
,_file_name(file_name)
,_model_path(model_path)
,_load_package(load_package)
,_omcPtr(0)
{

  std::cout << "Modelica compiler file "<< std::endl;
  char* omhome= getenv ("OPENMODELICAHOME");//should get value for OM home

  std::cout << "omhome " << omhome << std::endl;

  if(omhome==NULL)
    std::cout << "OPENMODELICAHOME variable doesn't set" << std::endl;

  //string path = getTempPath();
  int status =0;
  std::cout << "Intialize OMC, use gcc" << std::endl;


  status = InitOMC(&_omcPtr,"gcc",omhome);
  if(status > 0)
  {
    std::cout << "..ok" << std::endl;
    loadFile(load_file);
  }
  else
  {
    std::cout << "..failed" << std::endl;
    char* errorMsg = 0;
    status = GetError(_omcPtr, &errorMsg);
    string errorMsgStr(errorMsg);
    throw std::runtime_error("error to intialize OMC: " + errorMsgStr);
  }

}

ModelicaCompiler::~ModelicaCompiler(void)
{
   FreeOMC(_omcPtr);
}

void ModelicaCompiler::loadFile(bool load_file)
{

  string command;
  int status;
  char* result =0;
  /*if(load_file)
  {
    //command="loadModel(Modelica)";
    command="loadModel(Modelica,{\"3.2.2\"})";
    status=SendCommand(_omcPtr,command.c_str(),&result);
    if(status>0)
      cout<<"load Modelica Library : "<< result<<std::endl;
    else
    {
      throw std::runtime_error("error while loading Modelica library");
    }
  }*/

  if(load_file && _file_name!="")
  {
    loadFile();
  }
  else
  {
    //command="loadModel(Modelica)";
    command="loadModel(Modelica,{\"3.2.2\"})";
    status=SendCommand(_omcPtr,command.c_str(),&result);

    if(status>0)
      cout<<"load Modelica Library : "<< result<<std::endl;
    else
    {
      throw std::runtime_error("error while loading Modelica library");
    }
  }
}

void ModelicaCompiler::loadFile()
{

  string command;
  int status;
  char* result =0;

  command="loadModel(Modelica,{\"3.2.2\"})";
  status = SendCommand(_omcPtr, command.c_str(), &result);

  if(status>0)
    cout<<"load Modelica Library : "<< result<<std::endl;
  else
  {
    throw std::runtime_error("error while loading Modelica library");
  }

  const char * fileToLoad;

  string str;

  if(_load_package)
    str= "package.mo";
  else
    str=_model_path==""?_file_name+".mo":_model_path+".mo";

  /*
  if(packageName=="")
    str = fileName+".mo";
  else
   str = packageName+".mo";
  */


  fileToLoad=str.c_str();

  cout << "PackageName : " << str << std::endl;

  status=LoadFile(_omcPtr,fileToLoad);
  //status=LoadFile(_omcPtr,"package.mo");

  if(status>0)
    cout<<"load file : "<<str<<std::endl;
  else
  {

    std::cout << "failed to load "<<str << std::endl;
    char* errorMsg=0;
    status = GetError(_omcPtr,&errorMsg);
    string errorMsgStr(errorMsg);
    throw std::runtime_error("error while loading file: " + str+" " + errorMsgStr);
  }
}


void ModelicaCompiler::generateLabeledSimCode(string reduction_method)
{
  string command;
   string modelName=_model_path==""? _model:_model_path+"."+_model;
  char* result =0;

  command = "buildLabel(";
  command.append(modelName);
  command.append(",fileNamePrefix=");
  command.append("\"");
  command.append(_model);
  command.append("\"");
  command.append(",outputFormat=");
  command.append("\"");
  command.append("buffer");
  command.append("\"");
  //command.append(reduction_method);
  //command.append("\",{");
  //command.append(s);
  command.append(")");
  cout << command << std::endl;
  int status = SendCommand(_omcPtr, command.c_str(), &result);
  if(status>0)
    cout<<"generated labeled simcode for: "<<_model<<" "<< result<<std::endl;
  else
  {

    std::cout << "..failed" << std::endl;
    char* errorMsg=0;
    status = GetError(_omcPtr, &errorMsg);

    throw std::runtime_error("error while executing " + command+ " with error " + errorMsg);
  }
}

void ModelicaCompiler::generateReferenceSolution()
{

  string command;
  char* result =0;
  command = "writeToBuffer(";
  command.append(_model);
  command.append(_model);
  command.append(")");
  int status = SendCommand(_omcPtr, command.c_str(), &result);

  if(status>0)
    cout<<"generated reference solution for: "<<_model<<" "<< result<<std::endl;
  else
  {

    std::cout << "..failed" << std::endl;
    char* errorMsg = 0;
    status = GetError(_omcPtr, &errorMsg);

    throw std::runtime_error("error while executing  " + command+ " with error " + errorMsg);
  }
}

void ModelicaCompiler::reduceTerms(std::vector<unsigned int>& labels, double startTime, double endTime)
{
  cout << "here is reduceterms " << std::endl;
  bool first=true;
  string s1,s2,command;
  char* result =0;
  vector<string> slabels;
  vector<string> svalues;
  int status;
  unsigned int i;
  BOOST_FOREACH(i, labels)
  {
    slabels.push_back(boost::lexical_cast<std::string>(i));
  }
  s1 = boost::algorithm::join(slabels,",");

  string modelName=_model_path==""? _model:_model_path+"."+_model;
  command = "reduceTerms(";
  command.append(modelName);
  command.append(",fileNamePrefix=");
  command.append("\"");
  command.append(_model);
  command.append("\"");
  command.append(",outputFormat=");
  command.append("\"");
  command.append("mat");//buffer
  command.append("\"");
  command.append(",labelstoCancel=");
  command.append("\"");
  command.append(s1);
  command.append("\")");
  //command.append("},{");
  //command.append(s2);
  //command.append(")");

  cout<<command<<std::endl;
  status = SendCommand(_omcPtr, command.c_str(), &result);
  if(status>0)
    cout<<"reduceTerms for: "<<_model<<" "<< result<<std::endl;
  else
  {

    std::cout << "..failed" << std::endl;
    char* errorMsg = 0;
    status = GetError(_omcPtr, &errorMsg);

    throw std::runtime_error("error while executing " + command+ " with error " + errorMsg);
  }

  /*
  command="";
  command = "simulate(";
  command.append(modelName);
  command.append(",fileNamePrefix=");
  command.append("\"");
  command.append(_model);
  command.append("\"");
  command.append(",outputFormat=");
  command.append("\"");
  command.append("csv");//buffer
  command.append("\"");
  command.append(",startTime=0.0,stopTime = 20.0)");

  cout<<command<<std::endl;
  status=SendCommand(_omcPtr,command.c_str(),&result);
  if(status>0)
    cout<<"simulation for reduced model: "<<_model<<" "<< result<<std::endl;
  else
  {

    std::cout << "simulation for reduced model failed" << std::endl;
    char* errorMsg=0;
    status = GetError(_omcPtr, &errorMsg);

    throw std::runtime_error("error while executing " + command+ " with error " + errorMsg);
  }
  */

}

//#ifdef _UNICODE
//#define tstring std::wstring
//#else
//#define tstring std::string
//#endif
