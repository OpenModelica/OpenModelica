#pragma once

/*****************************************************************************/
/**

Encapsulation of global simulation settings.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
#ifdef ANALYZATION_MODE
#include <string.h>
using std::string;
#endif

enum OutputFormat {CSV, MAT, EMPTY};
enum LogType {OFF,STATS, NLS, ODE};
class IGlobalSettings
{

public:
    virtual  ~IGlobalSettings() {}
    ///< Start time of integration (default: 0.0)
    virtual double getStartTime()=0;
    virtual void setStartTime(double)=0;
    ///< End time of integraiton (default: 1.0)
    virtual double getEndTime()=0;
    virtual void setEndTime(double)=0;
    ///< Output step size (default: 20 ms)
    virtual double gethOutput()=0;
    virtual void sethOutput(double)=0;
    ///< Write out results ([false,true]; default: true)
    virtual bool getResultsOutput()=0;
    virtual void setResultsOutput(bool)=0;
    virtual OutputFormat getOutputFormat() = 0;
    virtual void setOutputFormat(OutputFormat) = 0;
    virtual LogType getLogType() = 0;
    virtual void setLogType(LogType) = 0;
    
    virtual bool useEndlessSim()=0;
    virtual void useEndlessSim(bool)=0;
    ///< Write out statistical simulation infos, e.g. number of steps (at the end of simulation); [false,true]; default: true)
    virtual bool getInfoOutput()=0;
    virtual void setInfoOutput(bool)=0;
    virtual string    getOutputPath() =0;
    virtual void setOutputPath(string)=0;
    virtual string    getSelectedSolver()=0;
    virtual void setSelectedSolver(string)=0;
    virtual string    getSelectedNonLinSolver()=0;
    virtual void setSelectedNonLinSSolver(string)=0;
    virtual void load(std::string xml_file)=0;
  virtual void setResultsFileName(string)=0;
  virtual string getResultsFileName()=0;
  virtual void setRuntimeLibrarypath(string)=0;
  virtual string getRuntimeLibrarypath()=0;
};
