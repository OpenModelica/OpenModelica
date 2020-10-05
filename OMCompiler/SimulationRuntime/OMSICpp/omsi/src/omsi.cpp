/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

/**
 *  \file osi.cpp
 *  \brief Brief
 */


//Cpp Simulation kernel includes
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/System/IOMSI.h>
#include <Core/SimController/ISimController.h>
#include <Core/System/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>
#ifdef RUNTIME_STATIC_LINKING
   #include <SimCoreFactory/OMCFactory/StaticOMCFactory.h>
#endif


//OpenModelica Simulation Interface


#include <csignal>

extern "C" void handle_aborts(int signal_number)
{
    
    std::string error = std::string("Abort was called with error code: ") + to_string(signal_number);
    throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
       
}

extern "C" void handle_segmentaion_faults(int signal_number)
{
    
    std::string error = std::string("A memory access violation has occurred: ") + to_string(signal_number);
    throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
       
}




#include <omsi.h>


#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>
namespace fs = boost::filesystem;






#if defined(_MSC_VER) || defined(__MINGW32__)
#include <tchar.h>


int _tmain(int argc, const _TCHAR* argv[])
#else
int main(int argc, const char* argv[])
#endif
{
    
    //use handle_aborts for abort() calls
    signal(SIGABRT, &handle_aborts);
    //use handle_segmentaion_faults for segmentatino faults
    signal(SIGSEGV , &handle_segmentaion_faults);
    // default program options
    std::map<std::string, std::string> opts;

    try
    {
        Logger::initialize();
        Logger::setEnabled(true);

#ifdef RUNTIME_STATIC_LINKING
            shared_ptr<StaticOMCFactory>  _factory =  shared_ptr<StaticOMCFactory>(new StaticOMCFactory());
#else
        shared_ptr<OMCFactory> _factory = shared_ptr<OMCFactory>(new OMCFactory());
#endif //RUNTIME_STATIC_LINKING
        //SimController to start simulation

        std::pair<shared_ptr<ISimController>, SimSettings> simulation = _factory->createSimulation(argc, argv, opts);

        //create OSU system
        fs::path osu_path(simulation.second.osuPath);
        fs::path osu_name(simulation.second.osuName);
        osu_path /= osu_name;
        weak_ptr<IMixedSystem> system = simulation.first->LoadOSUSystem(osu_path.string(), simulation.second.osuName);
        simulation.first->Start(simulation.second, simulation.second.osuName);


        return 0;
    }
    catch (ModelicaSimulationError& ex)
    {
        if (!ex.isSuppressed())
            std::cerr << "Simulation stopped with error in " << error_id_string(ex.getErrorID()) << ": " << ex.what();
        return -1;
    }
}
