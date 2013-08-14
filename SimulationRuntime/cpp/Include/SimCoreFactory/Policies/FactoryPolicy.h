#pragma once

   template<class T>
  struct ObjectFactory 
    {
        ObjectFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
            :_library_path(library_path)
            ,_modelicasystem_path(modelicasystem_path)
            ,_config_path(config_path)
        {
              _factory = boost::shared_ptr<T>(new T(library_path,modelicasystem_path));
        }
        
    protected:
            boost::shared_ptr<T>  _factory;
            PATH _library_path;
            PATH _modelicasystem_path;
            PATH _config_path;
    };
    

#if defined(__vxworks)

      /*Policy include*/
    #include <Policies/SolverVxWorksFactory.h>
    #include <Policies/SolverSettingsVxWorksFactory.h>
    #include <Policies/SystemVxWorksFactory.h>
    #include <Policies/NonLinSolverVxWorksFactory.h>
    /*Policy defines*/
    typedef SystemVxWorksFactory<VxWorksFactory> SimControllerPolicy;
    typedef SolverVxWorksFactory<VxWorksFactory> ConfigurationPolicy;
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
    typedef NonLinSolverFactory<GenericFactory> NonLinSolverPolicy;
    typedef SolverSettingsFactory<GenericFactory> SolverSettingsPolicy;
#elif defined(OMC_BUILD)
   /*Policy include*/
  
    #include <Policies/SolverOMCFactory.h>
    #include <Policies/SolverSettingsOMCFactory.h>
    #include <Policies/SystemOMCFactory.h>
    #include <Policies/NonLinSolverOMCFactory.h>
    /*Policy defines*/
    typedef SystemOMCFactory<OMCFactory> SimControllerPolicy;
    typedef SolverOMCFactory<OMCFactory> ConfigurationPolicy;
    typedef NonLinSolverOMCFactory<OMCFactory> NonLinSolverPolicy;
    typedef SolverSettingsOMCFactory<OMCFactory> SolverSettingsPolicy;
   
#else
    #error "operating system not supported"
#endif
