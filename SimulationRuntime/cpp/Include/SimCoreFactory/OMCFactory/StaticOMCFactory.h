#pragma once

#include <Modelica.h>
#include <Policies/FactoryConfig.h>
#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/SimController/SimController.h>

class StaticOMCFactory : public OMCFactory
{
    public:
    StaticOMCFactory();
        StaticOMCFactory(PATH library_path, PATH modelicasystem_path);

        virtual ~StaticOMCFactory();

        virtual std::pair<boost::shared_ptr<ISimController>,SimSettings> createSimulation(int argc,  const char* argv[]);
};
