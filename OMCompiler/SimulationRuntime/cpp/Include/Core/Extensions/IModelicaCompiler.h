
#pragma once

//#include <OMCProxy/API.h>

class IModelicaCompiler
{
public:
  virtual void StartModelicaCompiler() = 0;
  virtual void StopModelicaCompiler() = 0;
  virtual void RestStartModelicaCompiler() = 0;
  virtual bool SendCommand(string command,string& results) = 0;
  virtual void LoadModel(string model_path,bool loadMSL) = 0;
  virtual void CreateModelicaSystem(string model_name) = 0;
  virtual void destroy()=0;
};
//extern "C" EXPORT  IModelicaCompiler* createModelicaCompiler();