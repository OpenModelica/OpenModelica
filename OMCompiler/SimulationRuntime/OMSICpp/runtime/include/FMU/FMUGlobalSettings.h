/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#pragma once
#include <string.h>
using std::string;

#ifdef ENABLE_SUNDIALS_STATIC
  #define DEFAULT_NLS "kinsol"
#else
#define DEFAULT_NLS "newton"
#endif

#include <Core/SimulationSettings/IGlobalSettings.h>

class FMUGlobalSettings : public IGlobalSettings
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
    ///< Write out results (EMIT_NONE)
    virtual EmitResults getEmitResults() { return EMIT_NONE; }
    virtual void setEmitResults(EmitResults) {}
    virtual bool useEndlessSim() { return true; }
    virtual void useEndlessSim(bool) {}
    ///< Write out statistical simulation infos, e.g. number of steps (at the end of simulation); [false,true]; default: true)
    virtual bool getInfoOutput() { return false; }
    virtual void setInfoOutput(bool) {}
    virtual string    getOutputPath() { return "./"; }
    virtual string    getInputPath() { return "./"; }
    virtual LogSettings getLogSettings() { return LogSettings(LF_FMI); }
    virtual void setLogSettings(LogSettings) {}
    virtual OutputPointType getOutputPointType() { return OPT_ALL; };
    virtual void setOutputPointType(OutputPointType) {};
    virtual void setOutputPath(string) {}
    virtual void setInputPath(string) {}
    virtual string    getSelectedSolver() { return "euler"; }
    virtual void setSelectedSolver(string) {}
    virtual string    getSelectedLinSolver() { return "dgesvSolver"; }
    virtual void setSelectedLinSolver(string) {}
    virtual string    getSelectedNonLinSolver() { return DEFAULT_NLS; }
    virtual void setSelectedNonLinSolver(string) {}
    virtual void load(string xml_file) {};
    virtual void setResultsFileName(string) {}
    virtual string getResultsFileName() { return ""; }
    virtual void setRuntimeLibrarypath(string) {}
    virtual string getRuntimeLibrarypath() { return ""; }
    virtual void setAlarmTime(unsigned int) {}
    virtual unsigned int getAlarmTime() { return 0; }
    virtual void setNonLinearSolverContinueOnError(bool) {};
    virtual bool getNonLinearSolverContinueOnError() { return false; };
    virtual void setSolverThreads(int) {};
    virtual int getSolverThreads() { return 1; };
    virtual OutputFormat getOutputFormat() { return EMPTY; };
    virtual void setOutputFormat(OutputFormat) {};
    virtual void setZeroMQPubPort(int) {};
    virtual int getZeroMQPubPort() { return -1; };
    virtual void setZeroMQSubPort(int) {};
    virtual int getZeroMQSubPort() { return -1; };
    void setZeroMQJobiID(string) {};
    string getZeroMQJobiID() { return "empty"; };
    void setZeroMQServerID(string) {};
    string getZeroMQServerID() { return "empty"; };
    void setZeroMQClientID(string) {};
    string getZeroMQClientID() { return "empty"; };
    virtual string getInitfilePath(){ return "";}
    virtual void setInitfilePath(string){};


private:
};
