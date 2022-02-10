#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Core/System/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>
#include <Core/System/EventHandling.h>
#include <Core/System/ExtendedSystem.h>
#include <Core/System/SimObjects.h>
#include <Core/System/IExtendedSimObjects.h>
#include <Core/System/OMSUSystem.h>

// OpenModelica Simulation Interface
#include <omsi.h>

//3rdparty header
#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>

namespace fs = boost::filesystem;

//osu helper struct
struct omsi_me
{
    jm_callbacks callbacks;
    fmi_import_context_t* context;
    fmi2_callback_functions_t callback_functions;
    fmi2_import_t* instance;
    omsi_solving_mode_t solving_mode;
    fmi2_event_info_t* event_info;
    int debug_logging;
};


/* Logger function used by the C-API */
void importFMU2logger(jm_callbacks* c, jm_string module, jm_log_level_enu_t log_level, jm_string message)
{
   // std::cout << message << std::endl;
}


/* Logger function used by the FMU internally */
void fmi2logger(fmi2_component_environment_t env, fmi2_string_t instanceName, fmi2_status_t status,
                fmi2_string_t category, fmi2_string_t message, ...)
{
    int len;
    char msg[256];
    va_list argp;
    va_start(argp, message);
    len = vsnprintf(msg, 256, message, argp);
    va_end(argp);
    /*std::cout << fmi2_status_to_string((fmi2_status_t)status) << " " << instanceName << " " << category << " " << msg <<
        std::endl;*/
}


/**
 *   Constructor for osu system
 */
OMSUSystem::OMSUSystem(shared_ptr<IGlobalSettings> globalSettings, string osu_name)
    : ExtendedSystem(globalSettings)
      , _osu_name(osu_name)
      , _osu_me(NULL)
      , _instantiated(false)
      , _zeroVal(NULL)
      ,_real_vr(NULL)
      ,_int_vr(NULL)
      ,_bool_vr(NULL)
{
    /*get temp dir, for working directory, unzip fmu*/
    fs::path temp_path = fs::temp_directory_path();
    _osu_working_dir = temp_path.string();
    //fs::path current_path = fs::current_path();
    fmi_version_enu_t version;
    _osu_me = new omsi_me();
    _osu_me->callbacks.malloc = malloc;
    _osu_me->callbacks.calloc = calloc;
    _osu_me->callbacks.realloc = realloc;
    _osu_me->callbacks.free = free;
    _osu_me->callbacks.logger = importFMU2logger;
    _osu_me->callbacks.log_level = jm_log_level_nothing/*jm_log_level_all*/;
    _osu_me->callbacks.context = 0;

    _osu_me->context = fmi_import_allocate_context(&_osu_me->callbacks);
    /*unzip fmu */
    version = fmi_import_get_fmi_version(_osu_me->context, _osu_name.c_str(), _osu_working_dir.c_str());
    if (version != fmi_version_2_0_enu)
    {
        throw ModelicaSimulationError(MODEL_EQ_SYSTEM, "Only FMI version 2.0 is supported");
    }
    _osu_me->instance = fmi2_import_parse_xml(_osu_me->context, _osu_working_dir.c_str(), NULL);
    if (!_osu_me->instance)
    {
        _osu_me->solving_mode = omsi_none_mode;
        std::string error = std::string("Error parsing the XML file contained in ") + _osu_working_dir;
        throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
    }
    if (fmi2_import_get_fmu_kind(_osu_me->instance) == fmi2_fmu_kind_cs)
    {
        std::string error = std::string("Only FMI ME 2.0 is supported by this component");
        throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
    }


    /* FMI callback functions */
    _osu_me->callback_functions.logger = fmi2logger;
    _osu_me->callback_functions.allocateMemory = calloc;
    _osu_me->callback_functions.freeMemory = free;
    _osu_me->callback_functions.componentEnvironment = _osu_me->instance;
    _osu_me->debug_logging = 0;
    jm_status_enu_t status, instantiateModelStatus;
    /* Load the binary (dll/so) */
    status = fmi2_import_create_dllfmu(_osu_me->instance, fmi2_import_get_fmu_kind(_osu_me->instance),
                                       &_osu_me->callback_functions);
    if (status == jm_status_error)
    {
        _osu_me->solving_mode = omsi_none_mode;
        const char* log_str = jm_log_level_to_string((jm_log_level_enu_t)status);
        std::string error = std::string("Loading of FMU dynamic link library failed with status ") + std::
            string(log_str);
        throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
    }


    /* Only call fmi2SetDebugLogging if debugLogging is true */
    if (_osu_me->debug_logging)
    {
        int i;
        size_t categoriesSize = 0;
        fmi2_status_t debugLoggingStatus;
        fmi2_string_t* categories;
        /* Read the log categories size */
        categoriesSize = fmi2_import_get_log_categories_num(_osu_me->instance);
        categories = (fmi2_string_t*)malloc(categoriesSize * sizeof(fmi2_string_t));
        for (i = 0; i < categoriesSize; i++)
        {
            categories[i] = fmi2_import_get_log_category(_osu_me->instance, i);
        }
        debugLoggingStatus = fmi2_import_set_debug_logging(_osu_me->instance, _osu_me->debug_logging, categoriesSize,
                                                           categories);
        if (debugLoggingStatus != fmi2_status_ok && debugLoggingStatus != fmi2_status_warning)
        {
            const char* log_str = fmi2_status_to_string((fmi2_status_t)debugLoggingStatus);
            std::string error = std::string("fmi2SetDebugLogging failed with status :") + std::string(log_str);
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
        }
    }
}

OMSUSystem::OMSUSystem(OMSUSystem& instance) : ExtendedSystem(instance)
{
    throw ModelicaSimulationError(MODEL_EQ_SYSTEM, "copy of osu system is not implemented yet");
}

/**
 *   Destructor
 */
OMSUSystem::~OMSUSystem()
{
    fmi2_import_terminate(_osu_me->instance);
    fmi2_import_free_instance(_osu_me->instance);
    fmi2_import_destroy_dllfmu(_osu_me->instance);
    fmi2_import_free(_osu_me->instance);
    fmi_import_free_context(_osu_me->context);
    free(_osu_me->event_info);
    if(_real_vr)
        delete[] _real_vr;
    if(_int_vr)
       delete[] _int_vr;
    if(_bool_vr)
       delete[] _bool_vr;
    if (_osu_me)
    {
        delete _osu_me;
    }
    if (_zeroVal)
    {
        delete[] _zeroVal;
    }
}

/**
 *  Initializes osu
 */
void OMSUSystem::initialize()
{
    fs::path resources_foler("resources");
    fs::path resource_location = fs::path(_osu_working_dir);
    resource_location /= resources_foler;
    string path = string("file:") + resource_location.string();
    
    jm_status_enu_t instantiateModelStatus = fmi2_import_instantiate(
        _osu_me->instance, _osu_name.c_str(), fmi2_model_exchange,
        path.c_str(), fmi2_false);
    if (instantiateModelStatus == jm_status_error)
    {
        _osu_me->solving_mode = omsi_none_mode;
        const char* log_str = jm_log_level_to_string(
            (jm_log_level_enu_t)instantiateModelStatus);
        std::string error = std::string(
                "fmi2InstantiateModel failed with status :")
            + std::string(log_str);
        throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
    }
    /* allocate event info*/
    _osu_me->event_info = (fmi2_event_info_t*)malloc(
        sizeof(fmi2_event_info_t));
    _osu_me->solving_mode = omsi_instantiated_mode;

    //get variable dimensions
    _dimContinuousStates = fmi2_import_get_number_of_continuous_states(
        _osu_me->instance);
    _dimRHS = _dimContinuousStates;
    _dimZeroFunc = fmi2_import_get_number_of_event_indicators(
        _osu_me->instance);
    _modelName = fmi2_import_get_model_identifier_ME(_osu_me->instance);
    //string init_file_path = fmi_import_get_dll_path(_osu_working_dir.c_str(), _modelName.c_str() ,&_osu_me->callbacks);

    //Initialize the state vector
    SystemDefaultImplementation::initialize();
    _zeroVal = new double[_dimZeroFunc];

    fmi2_import_setup_experiment(_osu_me->instance, false, 0.0, 0.0, false,
                                 0.0);
    _osu_me->solving_mode = omsi_instantiated_mode;
    fmi2_status_t status = fmi2_import_enter_initialization_mode(
        _osu_me->instance);
    if (status != fmi2_status_ok && status != fmi2_status_warning)
    {
        const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
        std::string error = std::string(
                "fmi2EnterInitializationMode failed with status :")
            + std::string(log_str);
        throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
    }
    _osu_me->solving_mode = omsi_initialization_mode;

    initializeMemory();
    initializeFreeVariables();

    initializeBoundVariables();

    status = fmi2_import_exit_initialization_mode(_osu_me->instance);
    _osu_me->solving_mode = omsi_event_mode;
    if (status != fmi2_status_ok && status != fmi2_status_warning)
    {
        const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
        std::string error = std::string(
                "ffmi2ExitInitializationMode failed with status  :")
            + std::string(log_str);
        throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
    }
    _instantiated = true;

   /*
   
   _osu_me->solving_mode = omsi_event_mode;

    fmi2_event_info_t* eventInfo = _osu_me->event_info;
    eventInfo->newDiscreteStatesNeeded = fmi2_true;
    eventInfo->terminateSimulation = fmi2_false;
    unsigned int iter = 0;

    while (eventInfo->newDiscreteStatesNeeded && !eventInfo->terminateSimulation
        && !(iter++ > 100))
    {
        status = fmi2_import_new_discrete_states(_osu_me->instance, eventInfo);
        if (status != fmi2_status_ok && status != fmi2_status_warning)
        {
            const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
            std::string error = std::string(
                    "fmi2EnterEventMode failed with status  :")
                + std::string(log_str);
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
        }
    }
    if (eventInfo->newDiscreteStatesNeeded && !eventInfo->terminateSimulation)
        throw ModelicaSimulationError(MODEL_EQ_SYSTEM,
                                      "eventFMUUpdate failed: Number of event iterations exeeded");

   */
    status = fmi2_import_enter_continuous_time_mode(_osu_me->instance);
    if (status != fmi2_status_ok && status != fmi2_status_warning)
    {
        const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
        std::string error = std::string(
                "fmi2EnterEventMode failed with status  :")
            + std::string(log_str);
        throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
    }

    for (int i = 0; i < _dimZeroFunc; i++)
    {
        if (_zeroVal[i] > 0)
            _conditions[i] = true;
        else
            _conditions[i] = false;
    }

    _osu_me->solving_mode = omsi_continuousTime_mode;
    saveAll();

    if (getGlobalSettings()->getOutputPointType() != OPT_NONE)
    {
       
        _writeOutput = (dynamic_pointer_cast<IExtendedSimObjects>(_simObjects))->LoadWriter(
            _dimReal + _dimInteger + _dimBoolean).lock();
        _writeOutput->init();
        _writeOutput->clear();
       
    }
}

void OMSUSystem::initEquations()
{
}

void OMSUSystem::setInitial(bool status)
{
    _initial = status;
    if (_initial)
        _callType = IContinuous::DISCRETE;
    else
        _callType = IContinuous::CONTINUOUS;
}

bool OMSUSystem::initial()
{
    return _initial;
}


/**
 *  \brief Intializes SimVars memory for real, bool, int variables and parameter
 *
 *
 *
 *  \details
 *   Creates a SimVars object which holds memory for all simulation variables
 *   Therefore it parses ModelDescription to get the model variable information
 */
void OMSUSystem::initializeMemory()
{
    size_t nv, i;
    bool isParameter;
    fmi2_base_type_enu_t bt;
    fmi2_causality_enu_t causality;
    //list of all variables in the model
    fmi2_import_variable_list_t* vl = fmi2_import_get_variable_list(
        _osu_me->instance, 0);
    //list of all variable references
    const fmi2_value_reference_t* vrl = fmi2_import_get_value_referece_list(vl);
    //number of alle variables
    nv = fmi2_import_get_variable_list_size(vl);

    //Sort all variables for results outputs routine
    for (i = 0; i < nv; i++)
    {
        fmi2_import_variable_t* var = fmi2_import_get_variable(vl, i);
        if (var)
        {
            bt = fmi2_import_get_variable_base_type(var);

            if (bt == fmi2_base_type_real)
            {
                isParameter = addVariable(var, _real_out_vars,
                                                _real_param_vars, _dimReal);
                _dimReal++;
            }
            else if (bt == fmi2_base_type_int)
            {
                isParameter = addVariable(var, _int_out_vars,
                                                _int_param_vars, _dimInteger);
                _dimInteger++;
            }
            else if (bt == fmi2_base_type_bool)
            {
                isParameter = addVariable(var, _bool_out_vars,
                                                _bool_param_vars, _dimBoolean);
                _dimBoolean++;
            }
            else if (bt == fmi2_base_type_str)
            {
                isParameter = addVariable(var, _string_out_vars,
                                                _string_param_vars, _dimString);
                _dimString++;
            }
        }
        else
        {
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM,
                                          "Intialisation of value references failed");
        }
    }

    fmi2_import_free_variable_list(vl);
    _simVars = _simObjects->LoadSimVars(_modelName, _dimReal, _dimInteger,
                                        _dimBoolean, _dimString,
                                        _dimReal + _dimInteger + _dimBoolean + _dimString,
                                        _dimContinuousStates, -1).lock();
    __z = _simObjects->getSimVars(_modelName)->getStateVector();
    __zDot = _simObjects->getSimVars(_modelName)->getDerStateVector();
    _real_vr = new fmi2_value_reference_t[_dimReal];
    _int_vr = new fmi2_value_reference_t[_dimInteger];
    _bool_vr = new fmi2_value_reference_t[_dimBoolean];
    addValueReferences();
    initializeResultOutputVars();
    //Initialize SimVars
    getReal(_simVars->getRealVarsVector());
    getInteger(_simVars->getIntVarsVector());
   //ToDo: Boolean vars are not yet supported
}

/**
 *  \brief adds variable  tho the list of output variables and paramater
 *
 *  \param [in] v fmu variable
 *  \param [in] output_value_references list of output references
 *  \param [in] param_value_references list of parameter references
 *  \return true if fmu variable is a parameter
 *
 *  \details Details
 */
bool OMSUSystem::addVariable(fmi2_import_variable_t* v,
                                  out_vars_t& vars,
                                  out_vars_t& params,
                                  unsigned int var_idx)
{
    fmi2_causality_enu_t causality = fmi2_import_get_causality(v);
    //size_t vr = fmi2_import_get_variable_vr(v);
    if ((causality == fmi2_causality_enu_parameter)
        || (causality == fmi2_causality_enu_calculated_parameter))
    {
        params.push_back(make_tuple(v, var_idx));
        return true;
    }
    else
    {
        vars.push_back(make_tuple(v, var_idx));
        return false;
    }
}
void OMSUSystem::addValueReferences()
{
   if(!_real_vr)
        throw ModelicaSimulationError(MODEL_EQ_SYSTEM, "real variable value references are not set");
    if(!_int_vr)
       throw ModelicaSimulationError(MODEL_EQ_SYSTEM, "integer variable value references are not set");
    if(!_bool_vr)
      throw ModelicaSimulationError(MODEL_EQ_SYSTEM, "boolean variable value references are not set");


   for (out_vars_t::iterator iter = _real_out_vars.begin();
         iter != _real_out_vars.end(); iter++)
    {
        fmi2_import_variable_t* v = get < 0 > (*iter);
        unsigned int index = get < 1> (*iter);
        size_t vr = fmi2_import_get_variable_vr(v);
        _real_vr[index]=vr;
    }
    //add real parameter to write output structure
    for (out_vars_t::iterator iter = _real_param_vars.begin();
         iter != _real_param_vars.end(); iter++)
    {
        fmi2_import_variable_t* v = get < 0 > (*iter);
        unsigned int index = get < 1> (*iter);
        size_t vr = fmi2_import_get_variable_vr(v);
        _real_vr[index]=vr;
    }

    //add boolean output variables to write output structure
    for (out_vars_t::iterator iter = _bool_out_vars.begin();
         iter != _bool_out_vars.end(); iter++)
    {
       fmi2_import_variable_t* v = get < 0 > (*iter);
        unsigned int index = get < 1> (*iter);
        size_t vr = fmi2_import_get_variable_vr(v);
        _bool_vr[index]=vr;
    }
    //add boolean parameter to write output structure
    for (out_vars_t::iterator iter = _bool_param_vars.begin();
         iter != _bool_param_vars.end(); iter++)
    {
       fmi2_import_variable_t* v = get < 0 > (*iter);
        unsigned int index = get < 1> (*iter);
        size_t vr = fmi2_import_get_variable_vr(v);
        _bool_vr[index]=vr;
    }

    //add integer output variables to write output structure
    for (out_vars_t::iterator iter = _int_out_vars.begin();
         iter != _int_out_vars.end(); iter++)
    {
        fmi2_import_variable_t* v = get < 0 > (*iter);
        unsigned int index = get < 1> (*iter);
        size_t vr = fmi2_import_get_variable_vr(v);
        _int_vr[index]=vr;

    }
    //add integer parameter to write output structure
    for (out_vars_t::iterator iter = _int_param_vars.begin();
         iter != _int_param_vars.end(); iter++)
    {
       fmi2_import_variable_t* v = get < 0 > (*iter);
        unsigned int index = get < 1> (*iter);
        size_t vr = fmi2_import_get_variable_vr(v);
        _int_vr[index]=vr;
    }


}
void OMSUSystem::initializeResultOutputVars()
{
    //add real output variables to writeoutput structure
    for (out_vars_t::iterator iter = _real_out_vars.begin();
         iter != _real_out_vars.end(); iter++)
    {
        fmi2_import_variable_t* v = get < 0 > (*iter);
        string name = string(fmi2_import_get_variable_name(v));
        const char* descripton_cstr = fmi2_import_get_variable_description(v);
        const char* name_cstr = name.c_str();

        string descripton;
        if (descripton_cstr)
            descripton = string(descripton_cstr);
        const double& realVar = _simVars->getRealVar(get < 1 > (*iter));
        const double* realVarPtr = &realVar;
        _real_vars.addOutputVar(name, descripton, realVarPtr, false);

    }
    //add real parameter to write output structure
    for (out_vars_t::iterator iter = _real_param_vars.begin();
         iter != _real_param_vars.end(); iter++)
    {
        fmi2_import_variable_t* v = get < 0 > (*iter);
        string name = string(fmi2_import_get_variable_name(v));
        const char* descripton_cstr = fmi2_import_get_variable_description(v);
        string descripton;
        if (descripton_cstr)
            descripton = string(descripton_cstr);
        const double& realVar = _simVars->getRealVar(get < 1 > (*iter));
        const double* realVarPtr = &realVar;
        _real_vars.addParameter(name, descripton, realVarPtr, false);

    }

    //add boolean output variables to write output structure
    for (out_vars_t::iterator iter = _bool_out_vars.begin();
         iter != _bool_out_vars.end(); iter++)
    {
        fmi2_import_variable_t* v =  get < 0 > (*iter);
        string name = string(fmi2_import_get_variable_name(v));
        const char* descripton_cstr = fmi2_import_get_variable_description(v);
        string descripton;
        if (descripton_cstr)
            descripton = string(descripton_cstr);
        const bool& boolVar = _simVars->getBoolVar(get < 1 > (*iter));
        const bool* boolVarPtr = &boolVar;
        _bool_vars.addOutputVar(name, descripton, boolVarPtr, false);
    }
    //add boolean parameter to write output structure
    for (out_vars_t::iterator iter = _bool_param_vars.begin();
         iter != _bool_param_vars.end(); iter++)
    {
        fmi2_import_variable_t* v = get < 0 > (*iter);
        string name = string(fmi2_import_get_variable_name(v));
        const char* descripton_cstr = fmi2_import_get_variable_description(v);
        string descripton;
        if (descripton_cstr)
            descripton = string(descripton_cstr);
        const bool& boolVar = _simVars->getBoolVar(get < 1 > (*iter));
        const bool* boolVarPtr = &boolVar;
        _bool_vars.addParameter(name, descripton, boolVarPtr, false);
    }

    //add integer output variables to write output structure
    for (out_vars_t::iterator iter = _int_out_vars.begin();
         iter != _int_out_vars.end(); iter++)
    {
        fmi2_import_variable_t* v = get < 0 > (*iter);
        string name = string(fmi2_import_get_variable_name(v));
        const char* descripton_cstr = fmi2_import_get_variable_description(v);
        string descripton;
        if (descripton_cstr)
            descripton = string(descripton_cstr);
        const int& intVar = _simVars->getIntVar(get < 1 > (*iter));
        const int* intVarPtr = &intVar;
        _int_vars.addOutputVar(name, descripton, intVarPtr, false);
    }
    //add integer parameter to write output structure
    for (out_vars_t::iterator iter = _int_param_vars.begin();
         iter != _int_param_vars.end(); iter++)
    {
        fmi2_import_variable_t* v = get < 0 > (*iter);
        string name = string(fmi2_import_get_variable_name(v));
        const char* descripton_cstr = fmi2_import_get_variable_description(v);
        string descripton;
        if (descripton_cstr)
            descripton = string(descripton_cstr);
        const int& intVar = _simVars->getIntVar(get < 1 > (*iter));
        const int* intVarPtr = &intVar;
        _int_vars.addParameter(name, descripton, intVarPtr, false);
    }
}

void OMSUSystem::initializeFreeVariables()
{
    _simTime = 0.0;
}

void OMSUSystem::initializeBoundVariables()
{
}

void OMSUSystem::saveAll()
{
}

string OMSUSystem::getModelName()
{
    return _osu_name;
}


bool OMSUSystem::handleSystemEvents(bool* events)
{
    if ((_osu_me->solving_mode == omsi_continuousTime_mode))
    {
        fmi2_event_info_t* eventInfo = _osu_me->event_info;
        fmi2_status_t status = fmi2_import_enter_event_mode(_osu_me->instance);
        if (status != fmi2_status_ok && status != fmi2_status_warning)
        {
            const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
            std::string error = std::string(
                    "fmi2EnterEventMode failed with status  :")
                + std::string(log_str);
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
        }
        _osu_me->solving_mode = omsi_event_mode;
        eventInfo->newDiscreteStatesNeeded = fmi2_true;
        eventInfo->terminateSimulation = fmi2_false;
        unsigned int iter = 0;
        while (eventInfo->newDiscreteStatesNeeded
            && !eventInfo->terminateSimulation && !(iter++ > 100))
        {
            status = fmi2_import_new_discrete_states(_osu_me->instance,
                                                     eventInfo);
            if (status != fmi2_status_ok && status != fmi2_status_warning)
            {
                const char* log_str = fmi2_status_to_string(
                    (fmi2_status_t)status);
                std::string error = std::string(
                        "fmi2EnterEventMode failed with status  :")
                    + std::string(log_str);
                throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
            }
        }
        if (eventInfo->newDiscreteStatesNeeded
            && !eventInfo->terminateSimulation)
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM,
                                          "eventFMUUpdate failed: Number of event iterations exeeded");

        status = fmi2_import_enter_continuous_time_mode(_osu_me->instance);
        if (status != fmi2_status_ok && status != fmi2_status_warning)
        {
            const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
            std::string error = std::string(
                    "fmi2EnterEventMode failed with status  :")
                + std::string(log_str);
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
        }
        _osu_me->solving_mode = omsi_continuousTime_mode;

        status = fmi2_import_get_event_indicators(_osu_me->instance,
                                                  (fmi2_real_t*)_zeroVal, _dimZeroFunc);
        if ((status != fmi2_status_ok) && (status != fmi2_status_warning)
            && (status != fmi2_status_discard))
        {
            const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
            std::string error = std::string(
                    "fmi2GetEventIndicators failed with status ::")
                + std::string(log_str);
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
        }

        for (int i = 0; i < _dimZeroFunc; i++)
        {
            if (_zeroVal[i] > 0)
                _conditions[i] = true;
            else
                _conditions[i] = false;
        }
    }
    return true;
}

IMixedSystem* OMSUSystem::clone()
{
    throw ModelicaSimulationError(MATH_FUNCTION, "clone is for osu system not supported");
}

bool OMSUSystem::evaluateAll(const UPDATETYPE command)
{
    evaluateODE(command);
    return false;
}

void OMSUSystem::evaluateODE(const UPDATETYPE command)
{
    if ((_osu_me->solving_mode == omsi_continuousTime_mode)
        || (_osu_me->solving_mode == omsi_event_mode))
    {
        //write inputs
        //read outputs
       
        getRHS(__zDot);
        getReal(_simVars->getRealVarsVector());
       
    }
   
}

void OMSUSystem::evaluateDAE(const UPDATETYPE command)
{
    throw ModelicaSimulationError(MATH_FUNCTION,
                                  "evaluateAll is for osu system not supported");
}

void OMSUSystem::evaluateZeroFuncs(const UPDATETYPE command)
{
    if ((_osu_me->solving_mode == omsi_continuousTime_mode)
        || (_osu_me->solving_mode == omsi_event_mode))
    {
        //write inputs
        //read outputs
        getReal(_simVars->getRealVarsVector());
     
       
        
    }
}

bool OMSUSystem::evaluateConditions(const UPDATETYPE command)
{
    return false;
}

// Release instance
void OMSUSystem::destroy()
{
    delete this;
}

// Set current integration time
void OMSUSystem::setTime(const double& t)
{
    if ((_instantiated) && (_osu_me->solving_mode == omsi_continuousTime_mode))
    {
        _simTime = t;
        fmi2_status_t status = fmi2_import_set_time(_osu_me->instance, t);
        if (status != fmi2_status_ok && status != fmi2_status_warning)
        {
            const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
            std::string error = std::string("fmi2SetTime failed with status  :")
                + std::string(log_str);
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
        }
    }
}

double OMSUSystem::getTime()
{
    return SystemDefaultImplementation::getTime();
}

// Computes the conditions of time event samplers for the current time
double OMSUSystem::computeNextTimeEvents(double currTime)
{
   
        //fmi2_event_info_t* eventInfo = _osu_me->event_info;
      
        //if (eventInfo->nextEventTimeDefined)
        //{
        //    double tnext = eventInfo->nextEventTime;
        //    fmi2_real_t nextTimeEvent = std::min(tnext, _global_settings->getEndTime());
        //        return nextTimeEvent; //SystemDefaultImplementation::computeNextTimeEvents(currTime, getTimeEventData());
        //}
        //else
        //    return _global_settings->getEndTime();
       
      return std::numeric_limits<double>::max();;
}

// Computes the conditions of time event samplers for the current time
void OMSUSystem::computeTimeEventConditions(double currTime)
{
    SystemDefaultImplementation::computeTimeEventConditions(currTime);
}

// Resets the conditions of time event samplers to false
void OMSUSystem::resetTimeConditions()
{
    SystemDefaultImplementation::resetTimeConditions();
}

// Provide number (dimension) of variables according to the index
int OMSUSystem::getDimContinuousStates() const
{
    return (SystemDefaultImplementation::getDimContinuousStates());
}

int OMSUSystem::getDimAE() const
{
    return (SystemDefaultImplementation::getDimAE());
}

// Provide number (dimension) of variables according to the index
int OMSUSystem::getDimBoolean() const
{
    return (SystemDefaultImplementation::getDimBoolean());
}

// Provide number (dimension) of variables according to the index
int OMSUSystem::getDimInteger() const
{
    return (SystemDefaultImplementation::getDimInteger());
}

// Provide number (dimension) of variables according to the index
int OMSUSystem::getDimReal() const
{
    return (SystemDefaultImplementation::getDimReal());
}

// Provide number (dimension) of variables according to the index
int OMSUSystem::getDimString() const
{
    return (SystemDefaultImplementation::getDimString());
}

// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
int OMSUSystem::getDimRHS() const
{
    return (SystemDefaultImplementation::getDimRHS());
}

void OMSUSystem::getContinuousStates(double* z)
{
    if ((_osu_me->solving_mode == omsi_continuousTime_mode)
        || (_osu_me->solving_mode == omsi_event_mode))
    {
        fmi2_status_t status = fmi2_import_get_continuous_states(
            _osu_me->instance, (fmi2_real_t*)z, _dimContinuousStates);
        if (status != fmi2_status_ok && status != fmi2_status_warning)
        {
            const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
            std::string error = std::string(
                    "fmi2GetContinuousStates failed with status :")
                + std::string(log_str);
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
        }
    }
}

void OMSUSystem::getNominalStates(double* z)
{
    if (_osu_me->solving_mode == omsi_continuousTime_mode)
    {
        fmi2_status_t status = fmi2_import_get_nominals_of_continuous_states(
            _osu_me->instance, (fmi2_real_t*)z, _dimContinuousStates);
        if (status != fmi2_status_ok && status != fmi2_status_warning)
        {
            const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
            std::string error = std::string(
                    "fmi2SetContinuousStates failed with status :")
                + std::string(log_str);
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
        }
    }
}

void OMSUSystem::setContinuousStates(const double* z)
{
    if (_osu_me->solving_mode == omsi_continuousTime_mode)
    {
        fmi2_status_t status = fmi2_import_set_continuous_states(
            _osu_me->instance, (fmi2_real_t*)z, _dimContinuousStates);
        if (status != fmi2_status_ok && status != fmi2_status_warning)
        {
            const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
            std::string error = std::string(
                    "fmi2SetContinuousStates failed with status :")
                + std::string(log_str);
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
        }
    }
}

double& OMSUSystem::getRealStartValue(double& var)
{
    return SystemDefaultImplementation::getRealStartValue(var);
}

bool& OMSUSystem::getBoolStartValue(bool& var)
{
    return SystemDefaultImplementation::getBoolStartValue(var);
}

int& OMSUSystem::getIntStartValue(int& var)
{
    return SystemDefaultImplementation::getIntStartValue(var);
}

string& OMSUSystem::getStringStartValue(string& var)
{
    return SystemDefaultImplementation::getStringStartValue(var);
}

void OMSUSystem::setRealStartValue(double& var, double val)
{
    SystemDefaultImplementation::setRealStartValue(var, val);
}

void OMSUSystem::setBoolStartValue(bool& var, bool val)
{
    SystemDefaultImplementation::setBoolStartValue(var, val);
}

void OMSUSystem::setIntStartValue(int& var, int val)
{
    SystemDefaultImplementation::setIntStartValue(var, val);
}

void OMSUSystem::setStringStartValue(string& var, string val)
{
    SystemDefaultImplementation::setStringStartValue(var, val);
}

void OMSUSystem::setNumPartitions(int numPartitions)
{
}

int OMSUSystem::getNumPartitions()
{
    return 0;
}

void OMSUSystem::setPartitionActivation(bool* partitions)
{
}

void OMSUSystem::getPartitionActivation(bool* partitions)
{
}

int OMSUSystem::getActivator(int state)
{
    return 0;
}

// Provide the right hand side (according to the index)
void OMSUSystem::getRHS(double* f)
{
    if ((_osu_me->solving_mode == omsi_continuousTime_mode)
        || (_osu_me->solving_mode == omsi_event_mode))
    {
        fmi2_status_t status = fmi2_import_get_derivatives(_osu_me->instance,
                                                           (fmi2_real_t*)f, _dimRHS);
        if (status != fmi2_status_ok && status != fmi2_status_warning)
        {
            const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
            std::string error = std::string(
                    "fmi2GetDerivatives failed with status  :")
                + std::string(log_str);
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
        }
    }
}

void OMSUSystem::setStateDerivatives(const double* f)
{
    throw ModelicaSimulationError(MODEL_EQ_SYSTEM,
                                  "setStateDerivatives is not yet implemented");
}

bool OMSUSystem::stepCompleted(double time)
{
    if (_osu_me->solving_mode == omsi_continuousTime_mode)
    {
        fmi2_boolean_t callEventUpdate = fmi2_false;
        fmi2_boolean_t terminateSimulation = fmi2_false;
        fmi2_status_t status = fmi2_import_completed_integrator_step(
            _osu_me->instance, fmi2_true, &callEventUpdate,
            &terminateSimulation);
        if (status != fmi2_status_ok && status != fmi2_status_warning)
        {
            const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
            std::string error = std::string(
                    "fmi2CompletedIntegratorStep failed with status :")
                + std::string(log_str);
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
        }
        return callEventUpdate;
    }
    return false;
}

void OMSUSystem::setTerminal(bool terminal)
{
    _terminal = terminal;
}

bool OMSUSystem::terminal()
{
    return _terminal;
}

bool OMSUSystem::isAlgebraic()
{
    return false; // Indexreduction is enabled
}

bool OMSUSystem::provideSymbolicJacobian()
{
    throw ModelicaSimulationError(MODEL_EQ_SYSTEM,
                                  "provideSymbolicJacobian is not yet implemented");
}

void OMSUSystem::handleEvent(const bool* events)
{
}

bool OMSUSystem::checkForDiscreteEvents()
{
    return false;
}

void OMSUSystem::getZeroFunc(double* f)
{
    if ((_osu_me->solving_mode == omsi_continuousTime_mode)
        || (_osu_me->solving_mode == omsi_event_mode))
    {
        fmi2_status_t status = fmi2_import_get_event_indicators(
            _osu_me->instance, (fmi2_real_t*)_zeroVal, _dimZeroFunc);
        if ((status != fmi2_status_ok) && (status != fmi2_status_warning)
            && (status != fmi2_status_discard))
        {
            const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
            std::string error = std::string(
                    "fmi2GetEventIndicators failed with status ::")
                + std::string(log_str);
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, error);
        }
        for (int i = 0; i < _dimZeroFunc; i++)
        {
            if (_conditions[i])
                f[i] = -_zeroVal[i] - 1e-9;
            else
                f[i] = _zeroVal[i] - 1e-9;
        }
    }
}

void OMSUSystem::setConditions(bool* c)
{
    SystemDefaultImplementation::setConditions(c);
}

void OMSUSystem::getConditions(bool* c)
{
    SystemDefaultImplementation::getConditions(c);
}

void OMSUSystem::getClockConditions(bool* c)
{
    SystemDefaultImplementation::getClockConditions(c);
}

/*bool OMSUSystem::isConsistent()
 {
 return SystemDefaultImplementation::isConsistent();
 }
 */

void OMSUSystem::restoreOldValues()
{
}

void OMSUSystem::restoreNewValues()
{
}

int OMSUSystem::getDimTimeEvent() const
{
    return _dimTimeEvent;
}

std::pair<double, double>* OMSUSystem::getTimeEventData() const
{
    return _timeEventData;
}

void OMSUSystem::initTimeEventData()
{
}

bool OMSUSystem::isODE()
{
    return true;
}

int OMSUSystem::getDimZeroFunc()
{
    return _dimZeroFunc;
}

int OMSUSystem::getDimClock()
{
    return _dimClock;
}

double* OMSUSystem::clockInterval()
{
    return SystemDefaultImplementation::clockInterval();
}

void OMSUSystem::setIntervalInTimEventData(int clockIdx, double interval)
{
    SystemDefaultImplementation::setIntervalInTimEventData(clockIdx, interval);
}

void OMSUSystem::setClock(const bool* tick, const bool* subactive)
{
    SystemDefaultImplementation::setClock(tick, subactive);
}

bool OMSUSystem::getCondition(unsigned int index)
{
    return false;
}

shared_ptr<ISimObjects> OMSUSystem::getSimObjects()
{
    return _simObjects;
}

shared_ptr < IHistory> OMSUSystem::getHistory()
{
    return _writeOutput;
}

void OMSUSystem::writeOutput(const IWriteOutput::OUTPUT command)
{
    if (command & IWriteOutput::HEAD_LINE)
    {
        const all_names_t outputVarNames = make_tuple(_real_vars.ourputVarNames,
                                                      _int_vars.ourputVarNames, _bool_vars.ourputVarNames,
                                                      _der_vars.ourputVarNames, _res_vars.ourputVarNames);
        const all_description_t outputVarDescription = make_tuple(
            _real_vars.ourputVarDescription, _int_vars.ourputVarDescription,
            _bool_vars.ourputVarDescription, _der_vars.ourputVarDescription,
            _res_vars.ourputVarDescription);
        const all_names_t parameterVarNames = make_tuple(
            _real_vars.parameterNames, _int_vars.parameterNames,
            _bool_vars.parameterNames, _der_vars.ourputVarNames,
            _res_vars.ourputVarNames);
        const all_description_t parameterVarDescription = make_tuple(
            _real_vars.parameterDescription, _int_vars.parameterDescription,
            _bool_vars.parameterDescription, _der_vars.ourputVarDescription,
            _res_vars.ourputVarDescription);
        _writeOutput->write(outputVarNames, outputVarDescription,
                            parameterVarNames, parameterVarDescription);
        const all_vars_t params = make_tuple(_real_vars.outputParams,
                                             _int_vars.outputParams, _bool_vars.outputParams,
                                             _der_vars.outputParams, _res_vars.outputParams);
        
        neg_all_vars_t neg_all_params = make_tuple(_real_vars.negateParams,
            _int_vars.negateParams, _bool_vars.negateParams,
            _der_vars.negateParams, _res_vars.negateParams);

        _writeOutput->write(params, neg_all_params, _global_settings->getStartTime(),
                            _global_settings->getEndTime());
    }
        //Write the current values
    else
    {
        write_data_t& container = _writeOutput->getFreeContainer();

        /*debug output*/
       /* var_names_t::iterator name_iter =  _real_vars.ourputVarNames.begin();
        boost::container::vector<const double*>::iterator values_iter =  _real_vars.outputVars.begin();
        for(;name_iter!=_real_vars.ourputVarNames.end();++name_iter)
        {

                cout << "vars name: " << *name_iter << " value: " << *(*values_iter) << std::endl;
                values_iter++;

        }


        var_names_t::iterator name_iter2 =  _real_vars.parameterNames.begin();
        boost::container::vector<const double*>::iterator values_iter2 =  _real_vars.outputParams.begin();
        for(;name_iter2!=_real_vars.parameterNames.end();++name_iter2)
        {

                cout << "param name: " << *name_iter2 << " value: " << *(*values_iter2) << std::endl;
                values_iter2++;

        }
        */

        /*debug output*/
        all_vars_time_t all_vars = make_tuple(_real_vars.outputVars,
                                              _int_vars.outputVars, _bool_vars.outputVars, _simTime,
                                              _der_vars.outputVars, _res_vars.outputVars);
        neg_all_vars_t neg_all_vars = make_tuple(_real_vars.negateOutputVars,
                                                 _int_vars.negateOutputVars, _bool_vars.negateOutputVars,
                                                 _der_vars.negateOutputVars, _res_vars.negateOutputVars);
        _writeOutput->addContainerToWriteQueue(
            make_tuple(all_vars, neg_all_vars));
    }
}

void OMSUSystem::getReal(double* z)
{
    if (_real_out_vars.size() > 0)
    {
        /*size_t vr = fmi2_import_get_variable_vr(get < 0 > (_real_out_vars[0]));

        fmi2_value_reference_t* value_reference_list = &(get < 0
            > (_real_out_vars[0]));*/
        fmi2_status_t status = fmi2_import_get_real(_osu_me->instance,
                                                   _real_vr, _dimReal,
                                                    (fmi2_real_t*)z);

        if (status != fmi2_status_ok && status != fmi2_status_warning)
        {
            const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
            std::string error = std::string("getReal failed with status  :")
                + std::string(log_str);
            throw std::runtime_error(error);
        }
    }
}

void OMSUSystem::setReal(const double* z)
{
}

void OMSUSystem::getInteger(int* z)
{
    if (_int_out_vars.size() > 0)
    {
        /*fmi2_value_reference_t* value_reference_list = &(get < 0
            > (_int_out_vars[0]));*/
        fmi2_status_t status = fmi2_import_get_integer(_osu_me->instance,
                                                      _int_vr, _dimInteger,
                                                       (fmi2_integer_t*)z);

        if (status != fmi2_status_ok && status != fmi2_status_warning)
        {
            const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
            std::string error = std::string("getInteger failed with status  :")
                + std::string(log_str);
            throw std::runtime_error(error);
        }
    }
}

void OMSUSystem::getBoolean(bool* z)
{
    if (_bool_out_vars.size() > 0)
    {
        /*fmi2_value_reference_t* value_reference_list = &(get < 0
            > (_bool_out_vars[0]));*/
        fmi2_status_t status = fmi2_import_get_boolean(_osu_me->instance,
                                                       _bool_vr, _dimBoolean,
                                                       (fmi2_boolean_t*)z);

        if (status != fmi2_status_ok && status != fmi2_status_warning)
        {
            const char* log_str = fmi2_status_to_string((fmi2_status_t)status);
            std::string error = std::string("getBoolean failed with status  :")
                + std::string(log_str);
            throw std::runtime_error(error);
        }
    }
}

void OMSUSystem::getString(string* z)
{
}

void OMSUSystem::setInteger(const int* z)
{
}

void OMSUSystem::setBoolean(const bool* z)
{
}

void OMSUSystem::setString(const string* z)
{
}

int OMSUSystem::getDimStateSets() const
{
    return 0;
}

int OMSUSystem::getDimStates(unsigned int index) const
{
    return 0;
}

int OMSUSystem::getDimCanditates(unsigned int index) const
{
    return 0;
}

int OMSUSystem::getDimDummyStates(unsigned int index) const
{
    return 0;
}

void OMSUSystem::getStates(unsigned int index, double* z)
{
}

void OMSUSystem::setStates(unsigned int index, const double* z)
{
}

void OMSUSystem::getStateCanditates(unsigned int index, double* z)
{
}

bool OMSUSystem::getAMatrix(unsigned int index, DynArrayDim2<int>& A)
{
    return false;
}

bool OMSUSystem::getAMatrix(unsigned int index, DynArrayDim1<int>& A)
{
    return false;
}

void OMSUSystem::setAMatrix(unsigned int index, DynArrayDim2<int>& A)
{
}

void OMSUSystem::setAMatrix(unsigned int index, DynArrayDim1<int>& A)
{
}

bool OMSUSystem::isJacobianSparse()
{
    throw ModelicaSimulationError(MATH_FUNCTION,
                                  "isJacobianSparse is for osu system not supported");
}

/* DAE residuals is empty */
void OMSUSystem::getResidual(double* f)
{
    throw ModelicaSimulationError(MATH_FUNCTION,
                                  "getResidual is for osu system not supported");
}

void OMSUSystem::setAlgebraicDAEVars(const double* y)
{
    throw ModelicaSimulationError(MATH_FUNCTION,
                                  "setAlgebraicDAEVars is for osu system not supported");
}

/* get algebraic variables */
void OMSUSystem::getAlgebraicDAEVars(double* y)
{
    throw ModelicaSimulationError(MATH_FUNCTION,
                                  "getAlgebraicDAEVars is for osu system not supported");
}

bool OMSUSystem::isAnalyticJacobianGenerated()
{
    throw ModelicaSimulationError(MATH_FUNCTION,
                                  "isAnalyticJacobianGenerated is for osu system not supported");
}

const matrix_t& OMSUSystem::getJacobian()
{
    throw ModelicaSimulationError(MATH_FUNCTION,
                                  "getJacobian is for osu system not supported");
}

const matrix_t& OMSUSystem::getJacobian(unsigned int index)
{
    throw ModelicaSimulationError(MATH_FUNCTION,
                                  "getJacobian is for osu system not supported");
}

sparsematrix_t& OMSUSystem::getSparseJacobian()
{
    throw ModelicaSimulationError(MATH_FUNCTION,
                                  "getSparseJacobian is for osu system not supported");
}

sparsematrix_t& OMSUSystem::getSparseJacobian(unsigned int index)
{
    throw ModelicaSimulationError(MATH_FUNCTION,
                                  "getSparseJacobian is for osu system not supported");
}

const matrix_t& OMSUSystem::getStateSetJacobian(unsigned int index)
{
    throw ModelicaSimulationError(MATH_FUNCTION,
                                  "getStateSetJacobian is for osu system not supported");
}

sparsematrix_t& OMSUSystem::getStateSetSparseJacobian(unsigned int index)
{
    throw ModelicaSimulationError(MATH_FUNCTION,
                                  "getStateSetSparseJacobian is for osu system not supported");
}

void OMSUSystem::getAColorOfColumn(int* aSparsePatternColorCols, int size)
{
    throw ModelicaSimulationError(MATH_FUNCTION,
                                  "getAColorOfColumn is for osu system not supported");
}

int OMSUSystem::getAMaxColors()
{
    return _dimContinuousStates;
}
