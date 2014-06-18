#include <ObjectFactory.h>

#if defined(__vxworks)

      /*Policy include*/
    #include <Policies/SolverVxWorksFactory.h>
    #include <Policies/SolverSettingsVxWorksFactory.h>
    #include <Policies/SystemVxWorksFactory.h>
    #include <Policies/NonLinSolverVxWorksFactory.h>
    /*Policy defines*/
    typedef SystemVxWorksFactory<VxWorksFactory> SimControllerPolicy;
    typedef SolverVxWorksFactory<VxWorksFactory> ConfigurationPolicy;
    //typedef LinSolverVxWorksFactory<VxWorksFactory> NonLinSolverPolicy;
    typedef NonLinSolverVxWorksFactory<VxWorksFactory> NonLinSolverPolicy;
    typedef SolverSettingsVxWorksFactory<VxWorksFactory> SolverSettingsPolicy;

#elif defined(SIMSTER_BUILD)

      /*Policy include*/

    #include <Policies/SolverFactory.h>
    #include <Policies/SolverSettingsFactory.h>
    #include <Policies/SystemFactory.h>
    #include <Policies/NonLinSolverFactory.h>
    /*Policy defines*/
    typedef SystemFactory<GenericFactory> SimControllerPolicy;
    typedef SolverFactory<GenericFactory> ConfigurationPolicy;
    //typedef LinSolverFactory<GenericFactory> ConfigurationPolicy;
    typedef NonLinSolverFactory<GenericFactory> NonLinSolverPolicy;
    typedef SolverSettingsFactory<GenericFactory> SolverSettingsPolicy;
#elif defined(OMC_BUILD) && !defined(ANALYZATION_MODE)
   /*Policy include*/

    #include <Policies/SolverOMCFactory.h>
    #include <Policies/SolverSettingsOMCFactory.h>
    #include <Policies/SystemOMCFactory.h>
    #include <Policies/NonLinSolverOMCFactory.h>
  #include <Policies/LinSolverOMCFactory.h>
    /*Policy defines*/
    typedef SystemOMCFactory<OMCFactory> SimControllerPolicy;
    typedef SolverOMCFactory<OMCFactory> ConfigurationPolicy;
    typedef LinSolverOMCFactory<OMCFactory> LinSolverPolicy;
    typedef NonLinSolverOMCFactory<OMCFactory> NonLinSolverPolicy;
    typedef SolverSettingsOMCFactory<OMCFactory> SolverSettingsPolicy;
#elif defined(OMC_BUILD) && defined(ANALYZATION_MODE)
    class OMCFactory;

   /*Policy include*/

    #include <Policies/StaticSolverOMCFactory.h>
    #include <Policies/StaticSolverSettingsOMCFactory.h>
    #include <Policies/StaticSystemOMCFactory.h>
    #include <Policies/StaticLinSolverOMCFactory.h>
    #include <Policies/StaticNonLinSolverOMCFactory.h>
    /*Policy defines*/
    typedef StaticSystemOMCFactory<OMCFactory> SimControllerPolicy;
    typedef StaticSolverOMCFactory<OMCFactory> ConfigurationPolicy;
    typedef StaticLinSolverOMCFactory<OMCFactory> LinSolverPolicy;
    typedef StaticNonLinSolverOMCFactory<OMCFactory> NonLinSolverPolicy;
    typedef StaticSolverSettingsOMCFactory<OMCFactory> SolverSettingsPolicy;
//#else
//    #error "operating system not supported"
#endif
