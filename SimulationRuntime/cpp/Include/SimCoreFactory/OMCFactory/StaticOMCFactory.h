#pragma once

#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>

#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/SimController/SimController.h>
#include <Core/SimulationSettings/ISimControllerSettings.h>

class StaticOMCFactory : public OMCFactory
{
    public:
    StaticOMCFactory();
    StaticOMCFactory(PATH library_path, PATH modelicasystem_path);
    virtual ~StaticOMCFactory();

    virtual std::pair<boost::shared_ptr<ISimController>, SimSettings> createSimulation(int argc, const char* argv[]);
};