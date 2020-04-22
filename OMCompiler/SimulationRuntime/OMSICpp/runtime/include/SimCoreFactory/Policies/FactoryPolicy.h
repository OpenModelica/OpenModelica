/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
#include <SimCoreFactory/ObjectFactory.h>

#if defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)


    /*Policy include*/
    #include <SimCoreFactory/Policies/SolverOMCFactory.h>
    #include <SimCoreFactory/Policies/SolverSettingsOMCFactory.h>
    #include <SimCoreFactory/Policies/SystemOMCFactory.h>
    #include <SimCoreFactory/Policies/NonLinSolverOMCFactory.h>
    #include <SimCoreFactory/Policies/LinSolverOMCFactory.h>
    #include <SimCoreFactory/Policies/SimObjectOMCFactory.h>
    #include <SimCoreFactory/Policies/ExtendedSimObjectOMCFactory.h>
    /*Policy defines*/
    typedef OMCFactory BaseFactory;
    typedef SystemOMCFactory<BaseFactory> SimControllerPolicy;
    typedef SimObjectOMCFactory<BaseFactory> SimObjectPolicy;
    typedef ExtendedSimObjectOMCFactory<BaseFactory> ExtendedSimObjectPolicy;
    typedef SolverOMCFactory<BaseFactory> ConfigurationPolicy;
    typedef LinSolverOMCFactory<BaseFactory> LinSolverPolicy;
    typedef NonLinSolverOMCFactory<BaseFactory> NonLinSolverPolicy;
    typedef SolverSettingsOMCFactory<BaseFactory> SolverSettingsPolicy;

#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)

  /*Policy include*/
  #include <SimCoreFactory/OMCFactory/OMCFactory.h>
  #include <SimCoreFactory/Policies/StaticSolverOMCFactory.h>
  #include <SimCoreFactory/Policies/StaticSolverSettingsOMCFactory.h>
  #include <SimCoreFactory/Policies/StaticSystemOMCFactory.h>
  #include <SimCoreFactory/Policies/StaticLinSolverOMCFactory.h>
  #include <SimCoreFactory/Policies/StaticNonLinSolverOMCFactory.h>
  #include <SimCoreFactory/Policies/StaticSimObjectOMCFactory.h>
#include <SimCoreFactory/Policies/StaticExtendedSimObjectOMCFactory.h>
  /*Policy defines*/
  typedef BaseOMCFactory BaseFactory;
  typedef StaticSystemOMCFactory<BaseFactory> SimControllerPolicy;
  typedef StaticSimObjectOMCFactory<BaseFactory> SimObjectPolicy;
  typedef StaticExtendedSimObjectOMCFactory<BaseFactory> ExtendedSimObjectPolicy;
  typedef StaticSolverOMCFactory<BaseFactory> ConfigurationPolicy;
  typedef StaticLinSolverOMCFactory<BaseFactory> LinSolverPolicy;
  typedef StaticNonLinSolverOMCFactory<BaseFactory> NonLinSolverPolicy;
  typedef StaticSolverSettingsOMCFactory<BaseFactory> SolverSettingsPolicy;

//#else
//    #error "operating system not supported"
#endif
/** @} */ // end of simcorefactoriesPolicies
