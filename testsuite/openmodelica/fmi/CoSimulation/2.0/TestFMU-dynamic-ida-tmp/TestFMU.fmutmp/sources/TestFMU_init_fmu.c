#include "simulation_data.h"

OMC_DISABLE_OPT

void TestFMU_read_simulation_info(SIMULATION_INFO* simulationInfo)
{
  simulationInfo->startTime = 0.0;
  simulationInfo->stopTime = 1.0;
  simulationInfo->stepSize = 0.002;
  simulationInfo->tolerance = 1e-6;
  simulationInfo->solverMethod = "dassl";
  simulationInfo->outputFormat = "mat";
  simulationInfo->variableFilter = ".*";
  simulationInfo->OPENMODELICAHOME = "E:/apps/workspace/topenmodelica/build_cmake/install_cmake";
}

void TestFMU_read_input_fmu(MODEL_DATA* modelData)
{
  modelData->realVarsData[0].info.id = 1000;
  modelData->realVarsData[0].info.name = "$outputAlias_x";
  modelData->realVarsData[0].info.comment = "";
  modelData->realVarsData[0].info.info.filename = "<interactive>";
  modelData->realVarsData[0].info.info.lineStart = 3;
  modelData->realVarsData[0].info.info.colStart = 1;
  modelData->realVarsData[0].info.info.lineEnd = 3;
  modelData->realVarsData[0].info.info.colEnd = 14;
  modelData->realVarsData[0].info.info.readonly = 0;
  modelData->realVarsData[0].attribute.unit = "";
  modelData->realVarsData[0].attribute.displayUnit = "";
  modelData->realVarsData[0].attribute.min = -DBL_MAX;
  modelData->realVarsData[0].attribute.max = DBL_MAX;
  modelData->realVarsData[0].attribute.fixed = 1;
  modelData->realVarsData[0].attribute.useNominal = 0;
  modelData->realVarsData[0].attribute.nominal = 1.0;
  modelData->realVarsData[0].attribute.start = 10.0;
  modelData->realVarsData[1].info.id = 1001;
  modelData->realVarsData[1].info.name = "der($outputAlias_x)";
  modelData->realVarsData[1].info.comment = "";
  modelData->realVarsData[1].info.info.filename = "<interactive>";
  modelData->realVarsData[1].info.info.lineStart = 3;
  modelData->realVarsData[1].info.info.colStart = 1;
  modelData->realVarsData[1].info.info.lineEnd = 3;
  modelData->realVarsData[1].info.info.colEnd = 14;
  modelData->realVarsData[1].info.info.readonly = 0;
  modelData->realVarsData[1].attribute.unit = "";
  modelData->realVarsData[1].attribute.displayUnit = "";
  modelData->realVarsData[1].attribute.min = -DBL_MAX;
  modelData->realVarsData[1].attribute.max = DBL_MAX;
  modelData->realVarsData[1].attribute.fixed = 0;
  modelData->realVarsData[1].attribute.useNominal = 0;
  modelData->realVarsData[1].attribute.nominal = 1.0;
  modelData->realVarsData[1].attribute.start = 0.0;
  modelData->realVarsData[2].info.id = 1002;
  modelData->realVarsData[2].info.name = "$x_der";
  modelData->realVarsData[2].info.comment = "";
  modelData->realVarsData[2].info.info.filename = "";
  modelData->realVarsData[2].info.info.lineStart = 0;
  modelData->realVarsData[2].info.info.colStart = 0;
  modelData->realVarsData[2].info.info.lineEnd = 0;
  modelData->realVarsData[2].info.info.colEnd = 0;
  modelData->realVarsData[2].info.info.readonly = 0;
  modelData->realVarsData[2].attribute.unit = "";
  modelData->realVarsData[2].attribute.displayUnit = "";
  modelData->realVarsData[2].attribute.min = -DBL_MAX;
  modelData->realVarsData[2].attribute.max = DBL_MAX;
  modelData->realVarsData[2].attribute.fixed = 0;
  modelData->realVarsData[2].attribute.useNominal = 0;
  modelData->realVarsData[2].attribute.nominal = 1.0;
  modelData->realVarsData[2].attribute.start = -20.0;
  modelData->realVarsData[3].info.id = 1003;
  modelData->realVarsData[3].info.name = "x";
  modelData->realVarsData[3].info.comment = "";
  modelData->realVarsData[3].info.info.filename = "<interactive>";
  modelData->realVarsData[3].info.info.lineStart = 3;
  modelData->realVarsData[3].info.info.colStart = 1;
  modelData->realVarsData[3].info.info.lineEnd = 3;
  modelData->realVarsData[3].info.info.colEnd = 14;
  modelData->realVarsData[3].info.info.readonly = 0;
  modelData->realVarsData[3].attribute.unit = "";
  modelData->realVarsData[3].attribute.displayUnit = "";
  modelData->realVarsData[3].attribute.min = -DBL_MAX;
  modelData->realVarsData[3].attribute.max = DBL_MAX;
  modelData->realVarsData[3].attribute.fixed = 0;
  modelData->realVarsData[3].attribute.useNominal = 0;
  modelData->realVarsData[3].attribute.nominal = 1.0;
  modelData->realVarsData[3].attribute.start = 10.0;
}