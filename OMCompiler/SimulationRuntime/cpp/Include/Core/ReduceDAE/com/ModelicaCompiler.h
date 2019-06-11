#pragma once
extern "C" {
#include <OMC.h>
}
class ModelicaCompiler
{
public:
  ModelicaCompiler(string model,string file_name, string modelpath,bool loadFile, bool loadPackage);
  ~ModelicaCompiler(void);
  void generateLabeledSimCode(string reduction_method);
  void loadFile();
  void generateReferenceSolution();
  void reduceTerms(std::vector<unsigned int>& labels,double startTime, double endTime);
private:
  void loadFile(bool load);

  string _model;
  string _model_path;
  string _file_name;
  OMCData* _omcPtr;
  bool _load_package;
};