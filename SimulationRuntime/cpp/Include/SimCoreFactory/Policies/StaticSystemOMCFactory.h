#pragma once

#include <System/IAlgLoopSolverFactory.h>
#include <Policies/SystemOMCFactory.h>
#include <System/AlgLoopSolverFactory.h>
#include <SimController/ISimData.h>

/*
Policy class to create a OMC-,  Modelica- system or AlgLoopSolver
*/
template <class CreationPolicy>
struct StaticSystemOMCFactory : public SystemOMCFactory<CreationPolicy>
{
public:
    StaticSystemOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
        :SystemOMCFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
    {

    }

    virtual ~StaticSystemOMCFactory()
    {
    }

    virtual boost::shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(IGlobalSettings* globalSettings)
    {
      boost::shared_ptr<IAlgLoopSolverFactory>  algloopsolverfactory = boost::shared_ptr<IAlgLoopSolverFactory>(new AlgLoopSolverFactory(globalSettings,ObjectFactory<CreationPolicy>::_library_path,ObjectFactory<CreationPolicy>::_modelicasystem_path));
        return algloopsolverfactory;
    }

protected:
    virtual void initializeLibraries(PATH library_path,PATH modelicasystem_path,PATH config_path)
    {
    }
}; 
