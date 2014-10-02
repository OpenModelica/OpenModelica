#include <SimCoreFactory/ObjectFactory.h>

#if defined(__vxworks)

      /*Policy include*/
    #include <SimCoreFactory/Policies/SolverVxWorksFactory.h>
    #include <SimCoreFactory/Policies/SolverSettingsVxWorksFactory.h>
    #include <SimCoreFactory/Policies/SystemVxWorksFactory.h>
    #include <SimCoreFactory/Policies/NonLinSolverVxWorksFactory.h>
    #include <SimCoreFactory/Policies/LinSolverVxWorksFactory.h>
    /*Policy defines*/
    typedef SystemVxWorksFactory<VxWorksFactory> SimControllerPolicy;
    typedef SolverVxWorksFactory<VxWorksFactory> ConfigurationPolicy;
    //typedef LinSolverVxWorksFactory<VxWorksFactory> NonLinSolverPolicy;
    typedef NonLinSolverVxWorksFactory<VxWorksFactory> NonLinSolverPolicy;
    typedef SolverSettingsVxWorksFactory<VxWorksFactory> SolverSettingsPolicy;
    typedef LinSolverVxWorksFactory<VxWorksFactory> LinSolverPolicy;

#elif defined(SIMSTER_BUILD)

      /*Policy include*/

    #include <SimCoreFactory/Policies/SolverFactory.h>
    #include <SimCoreFactory/Policies/SolverSettingsFactory.h>
    #include <SimCoreFactory/Policies/SystemFactory.h>
    #include <SimCoreFactory/Policies/NonLinSolverFactory.h>
  #include <SimCoreFactory/Policies/LinSolverFactory.h>
    /*Policy defines*/
    typedef SystemFactory<GenericFactory> SimControllerPolicy;
    typedef SolverFactory<GenericFactory> ConfigurationPolicy;
    //typedef LinSolverFactory<GenericFactory> ConfigurationPolicy;
    typedef NonLinSolverFactory<GenericFactory> NonLinSolverPolicy;
    typedef SolverSettingsFactory<GenericFactory> SolverSettingsPolicy;
  typedef LinSolverFactory<GenericFactory> LinSolverPolicy;
#elif defined(OMC_BUILD) && !defined(ANALYZATION_MODE)
   /*Policy include*/

    #include <SimCoreFactory/Policies/SolverOMCFactory.h>
    #include <SimCoreFactory/Policies/SolverSettingsOMCFactory.h>
    #include <SimCoreFactory/Policies/SystemOMCFactory.h>
    #include <SimCoreFactory/Policies/NonLinSolverOMCFactory.h>
  #include <SimCoreFactory/Policies/LinSolverOMCFactory.h>
    /*Policy defines*/
    typedef SystemOMCFactory<OMCFactory> SimControllerPolicy;
    typedef SolverOMCFactory<OMCFactory> ConfigurationPolicy;
    typedef LinSolverOMCFactory<OMCFactory> LinSolverPolicy;
    typedef NonLinSolverOMCFactory<OMCFactory> NonLinSolverPolicy;
    typedef SolverSettingsOMCFactory<OMCFactory> SolverSettingsPolicy;
#elif defined(OMC_BUILD) && defined(ANALYZATION_MODE)
    class OMCFactory;

   /*Policy include*/

    #include <SimCoreFactory/Policies/StaticSolverOMCFactory.h>
    #include <SimCoreFactory/Policies/StaticSolverSettingsOMCFactory.h>
    #include <SimCoreFactory/Policies/StaticSystemOMCFactory.h>
    #include <SimCoreFactory/Policies/StaticLinSolverOMCFactory.h>
    #include <SimCoreFactory/Policies/StaticNonLinSolverOMCFactory.h>
    /*Policy defines*/
    typedef StaticSystemOMCFactory<OMCFactory> SimControllerPolicy;
    typedef StaticSolverOMCFactory<OMCFactory> ConfigurationPolicy;
    typedef StaticLinSolverOMCFactory<OMCFactory> LinSolverPolicy;
    typedef StaticNonLinSolverOMCFactory<OMCFactory> NonLinSolverPolicy;
    typedef StaticSolverSettingsOMCFactory<OMCFactory> SolverSettingsPolicy;
//#else
//    #error "operating system not supported"
#endif
