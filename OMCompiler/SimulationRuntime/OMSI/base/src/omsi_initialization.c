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

/** \file omsi_initialization.c
 */

/** \defgroup Initialization Initialization
 *  \ingroup OMSIBase
 *
 * \brief Base initialization functions.
 *
 * Defines basic functions for creating and setting up an OSU_data instance of
 * type `struct omsi_t`.
 */

/** \addtogroup Initialization
  *  \{ */

#include <omsi_global.h>
#include <omsi_posix_func.h>

#include <omsi_initialization.h>

#ifdef _WIN32
#define ON_WINDOWS 1
#else
#define ON_WINDOWS 0
#endif
omsi_callback_functions* global_callback;
omsi_string global_instance_name;
omsi_bool*  global_logCategories;
ModelState* global_model_state;

#define UNUSED(x) (void)(x)     /* ToDo: delete later */


/**
 * \brief Allocate memory for omsi_t struct
 *
 * `omsi_t` contains all informations for simulation, the experiment data and model
 * infos. Processes modelDescription,  init-XML file and optional JASON file
 * to allocate memory and initialize structs with constant values.
 * Gets called from OMSIC or OMSICpp library
 *
 * \param [in] instanceName         Unique identifier for OMSU instance, e.g. the model name.
 * \param [in] fmuType              Type of OMSU: ModelExchange or CoSimulation.
 *                                  Parameter is ignored at the moment, only ModelExchange is supported.
 * \param [in] fmuGUID              Globally unique identifier to check that modelDescription.xml
 *                                  and generated code are compatible.
 * \param [in] fmuResourceLocation  URI to get "resources" directory of unzipped OMSU archive.
 * \param [in] functions            Callback functions to be used from OMSI functions, e.g for
 *                                  memory management or logging.
 * \param [in] template_functions   Callback functions for functions in generated code.
 * \param [in] visible              Defines, if interaction with user should be minimal or
 *                                  OMSU is executed in interactive mode.
 *                                  Parameter is ignored at the moment.
 * \param [in] loggingOn            If `loggingOn=omsi_true` debug logging is enabled.
 *                                  If `loggingIn=omsi_false` debug logging is disabled.
 * \param [in] model_state          Current model state.
 *
 * \return  `omsi_t`*                 Pointer to newly created struct of type omsi_t.
 */
omsi_t* omsi_instantiate(omsi_string                            instanceName,
                         omsu_type                              fmuType,
                         omsi_string                            fmuGUID,
                         omsi_string                            fmuResourceLocation,
                         const omsi_callback_functions*         functions,
                         omsi_template_callback_functions_t*    template_functions,
                         omsi_bool                              visible,
                         omsi_bool                              loggingOn,
                         ModelState*                            model_state)
{
    /* Variables */
    omsi_int i;

    omsi_t* osu_data;
    omsi_string modelName=NULL;
    omsi_char* omsi_resource_location;
    omsi_char* initXMLFilename;
    omsi_char* infoJsonFilename;
    omsi_status status;

    /* check all input arguments */
    /* ignoring arguments: visible and fmuType */
    UNUSED(fmuType);
    UNUSED(visible);

    if (!functions->logger) {
        printf("(Fatal Error) fmi2Instantiate: No logger function set.\n");
        return NULL;
    }

    /* Log function call
    filtered_base_logger(NULL, log_fmi2_call, omsi_ok,
            "fmi2Instantiate: Instantiate osu_data.");
    */
    if (!functions->allocateMemory || !functions->freeMemory) {
        filtered_base_logger(NULL, log_statuserror, omsi_error,
                "fmi2Instantiate: Missing callback function.");
        return NULL;
    }
    if (!instanceName || strlen(instanceName) == 0) {
        filtered_base_logger(NULL, log_statuserror, omsi_error,
                "fmi2Instantiate: Missing instance name.");
        return NULL;
    }
    if (!fmuGUID || strlen(fmuGUID) == 0) {
        filtered_base_logger(NULL, log_statuserror, omsi_error,
                "fmi2Instantiate: Missing GUID.");
        return NULL;
    }

    /* Allocate memory for osu_data */
    osu_data = functions->allocateMemory(1, sizeof(omsi_t));
    if (!osu_data) {
        filtered_base_logger(NULL, log_statuserror, omsi_error,
                "fmi2Instantiate: Could not allocate memory for omsi_data.");
        return NULL;
    }

    /* Set model state to be pointer to OSU model state */
    osu_data->state = model_state;

    /* Set logCategories an loggingOn*/
    for (i = 0; i < NUMBER_OF_CATEGORIES; i++) { /* set all categories to on or off */
        osu_data->logCategories[i] = loggingOn;
    }
    osu_data->loggingOn = loggingOn;

    /* set global callback functions */
    global_callback = (omsi_callback_functions*) functions;
    global_instance_name = instanceName;
    global_logCategories = osu_data->logCategories;
    global_model_state = osu_data->state;

    /* check fmuResourceLocation for network path e.g. starting with "file://" */
    omsi_resource_location = omsi_strdup(fmuResourceLocation);
    if (strncmp(omsi_resource_location, "file:///", 8) == 0 && ON_WINDOWS){
        memmove(omsi_resource_location, omsi_resource_location+8, strlen(omsi_resource_location) - 8 + 1);
    }
    else if(strncmp(omsi_resource_location, "file://", 7) == 0 ){
        memmove(omsi_resource_location, omsi_resource_location+7, strlen(omsi_resource_location) - 7 + 1);
    }

    /* Read model name from modelDescription */
    modelName = omsi_get_model_name(omsi_resource_location);
    if (!modelName) {
        filtered_base_logger(osu_data->logCategories, log_statuserror, omsi_error,
                "fmi2Instantiate: Could not read modelName from %s/modelDescription.xml.",
                omsi_resource_location);
        omsu_free_osu_data(osu_data);
        functions->freeMemory(omsi_resource_location);
        return NULL;
    }

    /* process Inti-XML file and read experiment_data and parts of model_data in osu_data*/
    initXMLFilename = functions->allocateMemory(20 + strlen(omsi_resource_location) + strlen(modelName), sizeof(omsi_char));
    sprintf(initXMLFilename, "%s/%s_init.xml", omsi_resource_location, modelName);
    if (omsu_process_input_xml(osu_data, initXMLFilename, fmuGUID, instanceName, functions) == omsi_error) {
        filtered_base_logger(osu_data->logCategories, log_statuserror, omsi_error,
                "fmi2Instantiate: Could not process %s.", initXMLFilename);
        omsu_free_osu_data(osu_data);
        functions->freeMemory(initXMLFilename);
        functions->freeMemory(omsi_resource_location);
        return NULL;
    }

    /* process JSON file and read missing parts of model_data in osu_data */
    infoJsonFilename = functions->allocateMemory(20 + strlen(omsi_resource_location) + strlen(modelName), sizeof(omsi_char));
    sprintf(infoJsonFilename, "%s/%s_info.json", omsi_resource_location, modelName);

    /* temporarily disabled because omsicpp doesn't generate the json file */
    /*if (omsu_process_input_json(osu_data, infoJsonFilename, fmuGUID, instanceName, functions) == omsi_error) {
        filtered_base_logger(osu_data->logCategories, log_statuserror, omsi_error,
                "fmi2Instantiate: Could not process %s.", infoJsonFilename);
        omsu_free_osu_data(osu_data);
        functions->freeMemory(infoJsonFilename);
        functions->freeMemory(omsi_resource_location);
        return NULL;
    }
    */

    /* ************************************************************************* */

    /* Instantiate and initialize sim_data */
    status = omsu_allocate_sim_data(osu_data, functions, instanceName);
    if (status != omsi_ok) {
        filtered_base_logger(osu_data->logCategories, log_statuserror, omsi_error,
                "fmi2Instantiate: Could not allocate memory for sim_data.");
        /* ToDo: free stuff */
        return NULL;
    }

    status = omsi_allocate_model_variables(osu_data, functions);   /* ToDo: move this function into omsu_allocate_sim_data */
    if (status != omsi_ok) {
        filtered_base_logger(osu_data->logCategories, log_statuserror, omsi_error,
                "fmi2Instantiate: Could not allocate memory for sim_data->model_vars_and_params.");
        /* Todo: free stuff */
        return NULL;
    }

    status = omsu_setup_sim_data(osu_data, template_functions, functions);
    if (status != omsi_ok) {
        filtered_base_logger(osu_data->logCategories, log_statuserror, omsi_error,
                "fmi2Instantiate: Could not initialize sim_data->simulation.");
        /*******temporarily disabled because omsicpp doesn't generate omsi functions**********/
        /* Todo: free stuff */
        /* return NULL; */
        /**********************************************************************************/
    }

    status = omsi_initialize_model_variables(osu_data, functions, instanceName);
    if (status != omsi_ok) {
        filtered_base_logger(osu_data->logCategories, log_statuserror, omsi_error,
                "fmi2Instantiate: Could not initialize sim_data->model_vars_and_params.");
        /* Todo: free stuff */
        return NULL;
    }

    /* Free local variables */
    functions->freeMemory((omsi_char*) modelName);
    functions->freeMemory(infoJsonFilename);
    functions->freeMemory(omsi_resource_location);
    functions->freeMemory(initXMLFilename);

    return osu_data;
}


/**
 * \brief Initialize callbacks for initialization and simulation problem.
 *
 * Gets called from OMSIC or OMSICpp library and uses generated functions for initialization.
 *
 * \param [in,out]      omsu                Central data structure containing all informations.
 * \param [in]          template_functions  Struct containing pointers to functions in generated code.
 * \return `omsi_status`                    Returns `omsi_ok` on success.
 */
omsi_status omsi_intialize_callbacks(omsi_t*                                omsu,
                                     omsi_template_callback_functions_t*    template_functions )
{

    /* Set up initialization problem. */
    omsu_setup_sim_data_omsi_function(omsu->sim_data,
                                      "initialization",
                                      template_functions->initialize_initialization_problem);

    /* Set up simulation problem */
    omsu_setup_sim_data_omsi_function(omsu->sim_data,
                                      "simulation",
                                      template_functions->initialize_simulation_problem);

    return omsi_ok;
}

/*
 * Helper function for XML parser.
 * Defines what happens on start tag in XML files.
 */
void XMLCALL startElement_2(void*           userData,
                            omsi_string     name,
                            omsi_string*    attr) {

    omsi_long i = 0;
    modelDescriptionData* md = (modelDescriptionData*) userData;
    omsi_char* modelName;

    /* handle fmiModelDescription */
    if (!strcmp(name, "ModelExchange")) {
        for (i = 0; attr[i]; i += 2) {
            if (strcmp("modelIdentifier", attr[i]) == 0 ) {
                modelName = omsi_strdup(attr[i+1]);
                md->modelName = modelName;
                return;
            }
        }
    }

    return;

}


/*
 * Reads modelName from modelDescription.xml and returns it as string.
 * modelDescription.xml should be located at fmuResourceLocation/..
 */
omsi_string omsi_get_model_name(omsi_string fmuResourceLocation) {

    /* Variables */
    omsi_int done;
    omsi_char* fileName;
    modelDescriptionData md = {0};

    omsi_char buf[BUFSIZ] = {0};
    FILE* file = NULL;
    XML_Parser parser = NULL;

    /* file name */
    fileName = global_callback->allocateMemory(26 + strlen(fmuResourceLocation), sizeof(omsi_char));
    sprintf(fileName, "%s/../modelDescription.xml", fmuResourceLocation);

    /* open xml file */
    file = fopen(fileName, "r");
    if(!file) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2Instantiate: Can not read input file %s.", fileName);
        global_callback->freeMemory(fileName);
        return NULL;
    }

    /* create the XML parser */
    parser = XML_ParserCreate("UTF-8");
    if(!parser) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2Instantiate: Can not create XML parser");
        fclose(file);
        global_callback->freeMemory(fileName);
        return NULL;
    }

    /* set our user data */
    XML_SetUserData(parser, &md);
    /* set the handlers for start/end of element. */
    XML_SetElementHandler(parser, startElement_2, endElement);

    /* read XML */
    do {
        omsi_unsigned_int len = fread(buf, 1, sizeof(buf), file);
        done = len < sizeof(buf);
        if(XML_STATUS_ERROR == XML_Parse(parser, buf, len, done)) {
            filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                    "fmi2Instantiate: failed to read the XML file %s: %s at line %lu.",
                    fileName,
                    XML_ErrorString(XML_GetErrorCode(parser)),
                    XML_GetCurrentLineNumber(parser));

            fclose(file);
            XML_ParserFree(parser);
            global_callback->freeMemory(fileName);
            return NULL;
        }
    } while(!done);

    /* Deallocate memory */
    fclose(file);
    XML_ParserFree(parser);
    global_callback->freeMemory(fileName);

    return md.modelName;
}

/** \} */
