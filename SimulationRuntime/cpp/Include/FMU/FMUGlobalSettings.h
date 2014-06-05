#pragma once
#include <SimulationSettings/IGlobalSettings.h>


class  FMUGlobalSettings : public IGlobalSettings
{

public:
    virtual  ~FMUGlobalSettings() {}
    ///< Start time of integration (default: 0.0)
    virtual double getStartTime() { return 0.0; }
    virtual void setStartTime(double) {}
    ///< End time of integraiton (default: 1.0)
    virtual double getEndTime() { return 1.0; }
    virtual void setEndTime(double) {}
    ///< Output step size (default: 20 ms)
    virtual double gethOutput() { return 20; }
    virtual void sethOutput(double) {}
    ///< Write out results ([false,true]; default: true)
    virtual bool getResultsOutput() { return false; }
    virtual void setResultsOutput(bool) {}
    virtual bool useEndlessSim() {return true; }
    virtual void useEndlessSim(bool) {}
    ///< Write out statistical simulation infos, e.g. number of steps (at the end of simulation); [false,true]; default: true)
    virtual bool getInfoOutput() { return false; }
    virtual void setInfoOutput(bool) {}
    virtual string    getOutputPath() { return "./"; }
    virtual OutputFormat getOutputFormat(){return CSV;}
     virtual LogType getLogType() {return OFF;}
    virtual void setLogType(LogType) {}
    virtual void setOutputFormat(OutputFormat) {}
    virtual void setOutputPath(string) {}
    virtual string    getSelectedSolver() { return "Euler"; }
    virtual void setSelectedSolver(string) {}
    virtual string    getSelectedNonLinSolver() { return "Newton"; }
    virtual void setSelectedNonLinSSolver(string) {}
    virtual void load(std::string xml_file) {};
    virtual void setResultsFileName(string) {}
    virtual string getResultsFileName() { return "fmuresults.csv"; }
    virtual void setRuntimeLibrarypath(string) {}
    virtual string getRuntimeLibrarypath() { return "";}
private:
};
