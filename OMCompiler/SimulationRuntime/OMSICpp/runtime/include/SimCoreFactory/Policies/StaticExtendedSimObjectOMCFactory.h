#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
#include <omsi.h>
shared_ptr<ISimData> createSimDataFunction();


shared_ptr<ISimVars> createExtendedSimVarsFunction(omsi_t * omsu);



shared_ptr<IHistory> createMatFileWriterFactory(shared_ptr<IGlobalSettings> globalSettings, size_t dim);
shared_ptr<IHistory> createTextFileWriterFactory(shared_ptr<IGlobalSettings> globalSettings, size_t dim);
shared_ptr<IHistory> createBufferReaderWriterFactory(shared_ptr<IGlobalSettings> globalSettings, size_t dim);
shared_ptr<IHistory> createDefaultWriterFactory(shared_ptr<IGlobalSettings> globalSettings, size_t dim);

/*
Policy class to create a OMC-,  Modelica- system or AlgLoopSolver
*/
template <class CreationPolicy>
struct StaticExtendedSimObjectOMCFactory : public ObjectFactory<CreationPolicy>
{
public:
    StaticExtendedSimObjectOMCFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
    {
    }

    virtual ~StaticExtendedSimObjectOMCFactory()
    {
    }

    shared_ptr<ISimData> createSimData()
    {
        return createSimDataFunction();
    }

    
   
    shared_ptr<ISimVars> createExtendedSimVars(omsi_t* omsu)
    {
        return createExtendedSimVarsFunction(omsu);
    }
   
    shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(shared_ptr<IGlobalSettings> globalSettings)
    {
        return createStaticAlgLoopSolverFactory(globalSettings, ObjectFactory<CreationPolicy>::_library_path,
                                                ObjectFactory<CreationPolicy>::_modelicasystem_path);
    }

    shared_ptr<IHistory> createMatFileWriter(shared_ptr<IGlobalSettings> settings, size_t dim)
    {
        shared_ptr<IHistory> writer = createMatFileWriterFactory(settings, dim);
        return writer;
    }

    shared_ptr<IHistory> createTextFileWriter(shared_ptr<IGlobalSettings> settings, size_t dim)
    {
        shared_ptr<IHistory> writer = createTextFileWriterFactory(settings, dim);
        return writer;
    }

    shared_ptr<IHistory> createBufferReaderWriter(shared_ptr<IGlobalSettings> settings, size_t dim)
    {
        shared_ptr<IHistory> writer = createBufferReaderWriterFactory(settings, dim);
        return writer;
    }

    shared_ptr<IHistory> createDefaultWriter(shared_ptr<IGlobalSettings> settings, size_t dim)
    {
        shared_ptr<IHistory> writer = createDefaultWriterFactory(settings, dim);
        return writer;
    }
};

/** @} */ // end of simcorefactoriesPolicies
