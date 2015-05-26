/** @addtogroup simcorefactoriesPolicies
 *  
 *  @{
 */
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

#elif defined(__TRICORE__)

  /*Policy include*/
    #include <SimCoreFactory/Policies/SolverBodasFactory.h>
    #include <SimCoreFactory/Policies/SolverSettingsBodasFactory.h>
    #include <SimCoreFactory/Policies/SystemBodasFactory.h>
    #include <SimCoreFactory/Policies/NonLinSolverBodasFactory.h>
  #include <SimCoreFactory/Policies/LinSolverBodasFactory.h>
    /*Policy defines*/
    typedef SystemBodasFactory<BodasFactory> SimControllerPolicy;
    typedef SolverBodasFactory<BodasFactory> ConfigurationPolicy;
    //typedef LinSolverBodasFactory<BodasFactory> NonLinSolverPolicy;
    typedef NonLinSolverBodasFactory<BodasFactory> NonLinSolverPolicy;
    typedef SolverSettingsBodasFactory<BodasFactory> SolverSettingsPolicy;
    typedef LinSolverBodasFactory<BodasFactory> LinSolverPolicy;

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

#elif defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

  /*Policy include*/
    #include <SimCoreFactory/Policies/SolverOMCFactory.h>
    #include <SimCoreFactory/Policies/SolverSettingsOMCFactory.h>
    #include <SimCoreFactory/Policies/SystemOMCFactory.h>
    #include <SimCoreFactory/Policies/NonLinSolverOMCFactory.h>
    #include <SimCoreFactory/Policies/LinSolverOMCFactory.h>
    /*Policy defines*/
    typedef OMCFactory BaseFactory;
    typedef SystemOMCFactory<BaseFactory> SimControllerPolicy;
    typedef SolverOMCFactory<BaseFactory> ConfigurationPolicy;
    typedef LinSolverOMCFactory<BaseFactory> LinSolverPolicy;
    typedef NonLinSolverOMCFactory<BaseFactory> NonLinSolverPolicy;
    typedef SolverSettingsOMCFactory<BaseFactory> SolverSettingsPolicy;

#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
  /*include needed for object creation in factory classes*/
  #include <Core/Utils/Modelica/ModelicaSimulationError.h>
  #include <Core/Math/Array.h>
  #include <Solver/CVode/CVode.h>
  #include <Solver/IDA/IDA.h>
  #include <Solver/UmfPack/UmfPack.h>
  #include <Solver/UmfPack/UmfPackSettings.h>
  #include <Solver/Newton/Newton.h>
  #include <Solver/Kinsol/Kinsol.h>
  #include <Solver/Kinsol/KinsolSettings.h>
  #include <Core/Solver/SolverSettings.h>
  #include <Core/SimulationSettings/IGlobalSettings.h>
    /*Base Policy include*/
    #include <SimCoreFactory/Policies/SolverOMCFactory.h>
    #include <SimCoreFactory/Policies/SolverSettingsOMCFactory.h>
    #include <SimCoreFactory/Policies/SystemOMCFactory.h>
    #include <SimCoreFactory/Policies/NonLinSolverOMCFactory.h>
    #include <SimCoreFactory/Policies/LinSolverOMCFactory.h>
    /*Policy include*/
    #include <SimCoreFactory/Policies/StaticSolverOMCFactory.h>
    #include <SimCoreFactory/Policies/StaticSolverSettingsOMCFactory.h>
    #include <SimCoreFactory/Policies/StaticSystemOMCFactory.h>
    #include <SimCoreFactory/Policies/StaticLinSolverOMCFactory.h>
    #include <SimCoreFactory/Policies/StaticNonLinSolverOMCFactory.h>
    /*Policy defines*/
    typedef StaticOMCFactory BaseFactory;
    typedef StaticSystemOMCFactory<BaseFactory> SimControllerPolicy;
    typedef StaticSolverOMCFactory<BaseFactory> ConfigurationPolicy;
    typedef StaticLinSolverOMCFactory<BaseFactory> LinSolverPolicy;
    typedef StaticNonLinSolverOMCFactory<BaseFactory> NonLinSolverPolicy;
    typedef StaticSolverSettingsOMCFactory<BaseFactory> SolverSettingsPolicy;

//#else
//    #error "operating system not supported"
#endif

/** @} */ // end of simcorefactoriesPolicies

