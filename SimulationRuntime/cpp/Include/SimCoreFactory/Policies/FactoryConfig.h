#if defined(__vxworks)

    /*Defines*/
    #define PATH string
    #include <VxWorksFactory/VxWorksFactory.h>

#elif defined(SIMSTER_BUILD)




     /*Defines*/
    #define PATH fs::path

     #include <Genericfactory/Factory.h>
#elif defined(OMC_BUILD)


     /*Defines*/
    #define PATH fs::path
    #include "LibrariesConfig.h"
    #include <System/IAlgLoop.h>
    #include <Solver/IAlgLoopSolver.h>
    #include <System/IAlgLoopSolverFactory.h>
    #include <SimController/ISimData.h>
    #include <System/IMixedSystem.h>
    #include <SimulationSettings/IGlobalSettings.h>
    #include <SimController/ISimController.h>
    #include <SimCoreFactory/OMCFactory/OMCFactory.h>
#else
    #error "operating system not supported"
#endif
