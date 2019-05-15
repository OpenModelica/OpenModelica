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

/** \file omsi_input_json.c
 */

/** \defgroup initJson Initialize JSON
 * \ingroup Initialization
 *
 * \brief Process modelName_info.json file
 *
 * Functions to process informations from optional modelName_info.json file in
 * FMU resources folder.
 */

/** \addtogroup initJson
 *  \{
 */

#include <omsi_global.h>
#include <omsi_input_json.h>

#define UNUSED(x) (void)(x)     /* ToDo: delete later */

/* prototypes for static functions */
static omsi_string skipSpace(omsi_string str);

static omsi_string assertStringValue(omsi_string str,
                                     omsi_string value);

static omsi_string assertChar (omsi_string  str,
                               omsi_char    c);

static omsi_string omsu_assertCharOrEnd (omsi_string    str,
                                         omsi_char      expected_char,
                                         omsi_bool*     endNotFound);

static omsi_string assertNumber(omsi_string str,
                                omsi_real   expected);

static omsi_string skipObjectRest(omsi_string   str,
                                  omsi_int      first);

static omsi_string skipValue(omsi_string str);

static omsi_string skipFieldIfExist(omsi_string str,
                                    omsi_string name);

static void readInfoJson(omsi_string    str,
                         model_data_t*  model_data);


/**
 * \brief Process all informations from input.json file.
 *
 * Read values, allocates memory and writes everything in model_data->equation_info.
 *
 * \param [in,out]  osu_data        Central data structure containing all informations.
 * \param [in]      fileName        Path to JSON file.
 * \param [in]      fmuGUID         GUID of FMU for checking purpose. Ignored at the moment.
 * \param [in]      instanceName    Name of MFU instance for logging. Ignored at the moment.
 * \param [in]      functions       Pointer to callback functions provided by user.
 * \return `omsi_status`            Returns `omsi_ok` on success.
 */
omsi_status omsu_process_input_json(omsi_t*                         osu_data,
                                    omsi_string                     fileName,
                                    omsi_string                     fmuGUID,
                                    omsi_string                     instanceName,
                                    const omsi_callback_functions*  functions) {

    /* Variables */
    omc_mmap_read mmap_reader;

    UNUSED(fmuGUID); UNUSED(instanceName);      /* ToDo: delete or change function */

    /* set global function pointer */
    global_callback = (omsi_callback_functions*) functions;
    global_instance_name = instanceName;

    /* Log function call */
    filtered_base_logger(global_logCategories, log_all, omsi_ok,
                "fmi2Instantiate: Process JSON file %s.", fileName);

    /* read JSON file */
    mmap_reader = omc_mmap_open_read (fileName);
    readInfoJson(mmap_reader.data, osu_data->model_data);

    /* free memory */
    omc_mmap_close_read(mmap_reader);

    return omsi_ok;
}


/*
 * Helper function for reading JSON.
 * Skip whitespace.
 */
static omsi_string skipSpace(omsi_string str) {
    do {
        switch (*str) {
            case '\0': return str;
            case ' ':
            case '\n':
            case '\r':
                str++;
                break;
            default: return str;
        }
    } while (1);
}


/*
 * Helper function for reading JSON.
 * Assert string value is written in `str`. Returns the rest of the string to parse.
 * Does not work for escaped strings.
 */
static omsi_string assertStringValue(omsi_string str,
                                     omsi_string value) {
    int len = strlen(value);
    str = skipSpace(str);
    if ('\"' != *str || strncmp(str+1,value,len) || str[len+1] != '\"') {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2Instantiate: JSON string value %s expected, got: %.20s\n",
                value, str);
        abort();
    }
    return str + len + 2;
}


/*
 * Helper function for reading JSON.
 * Assert char value is written in `str`. Returns the rest of the string to parse.
 * Does not work for escaped strings.
 */
static omsi_string assertChar (omsi_string  str,
                               omsi_char    expected_char) {
    str = skipSpace(str);
    if (expected_char != *str) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2Instantiate: Expected '%c', got: %.20s\n",
                expected_char, str);
        abort();
    }
    return str + 1;
}

/*
 * Helper function for reading JSON.
 * Assert pointer `*str` points to char that is equal to expected_char or end
 * of array ']' is reached.
 */
static omsi_string omsu_assertCharOrEnd (omsi_string    str,
                                         omsi_char      expected_char,
                                         omsi_bool*     endNotFound) {
    str = skipSpace(str);

    if (*str == ']') {
        *endNotFound = omsi_false;
        return str;
    }

    if (*str != expected_char) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2Instantiate: Expected '%c', got: %.20s\n",
                expected_char, str);
        abort();
    }
    return str + 1;
}


/*
 * Helper function for reading JSON.
 * Assert real value is written in `str`. Returns the rest of the string to parse.
 * Does not work for escaped strings.
 */
static omsi_string assertNumber(omsi_string str,
                                omsi_real   expected) {
    omsi_char* endptr = NULL;
    omsi_real d;
    str = skipSpace(str);
    d = strtod(str, &endptr);
    if (str == endptr) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2Instantiate: Expected number, got: %.20s\n", str);
        abort();
    }
    if (d != expected) {
        filtered_base_logger(global_logCategories, log_statuswarning, omsi_warning,
                "fmi2Instantiate: Got number %f, expected: %f\nProceeding any way.\n",
                d, expected);
    }
    return endptr;
}


/*
 * Helper function for reading JSON.
 * Skip rest of current object in `str`.
 */
static omsi_string skipObjectRest(omsi_string   str,
                                  omsi_int      first) {
    str=skipSpace(str);
    while (*str != '}') {
        if (!first) {
            if (*str != ',') {
                filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                        "fmi2Instantiate: JSON object expected ',' or '}', got: %.20s\n", str);
                abort();
            }
            str++;
        } else {
            first = 0;
        }
        str = skipValue(str);
        str = skipSpace(str);
        if (*str++ != ':') {
            filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                    "fmi2Instantiate: JSON object expected ':', got: %.20s\n", str);
            abort();
        }
        str = skipValue(str);
        str = skipSpace(str);
    }
    return str+1;
}


/*
 * Helper function for reading JSON.
 * Skip everything inside string that is between braces, brackets or
 * quotation marks, e.g. everything between {..}, [..] or "..".
 */
static omsi_string skipValue(omsi_string str) {

    /* Variables*/
    omsi_int first;
    omsi_char *endptr;

    str = skipSpace(str);
    switch (*str) {
        case '{':
            str = skipObjectRest(str+1,1);
            return str;
        case '[':
            first = 1;
            str = skipSpace(str+1);
            while (*str != ']') {
                if (!first && *str++ != ',') {
                    filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                            "fmi2Instantiate: JSON array expected ',' or ']', got: %.20s\n", str);
                    abort();
                }
                first = 0;
                str = skipValue(str);
                str = skipSpace(str);
            }
            return str+1;
        case '"':
            str++;
            do {
                switch (*str) {
                    case '\0':
                        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                                "fmi2Instantiate: Found end of file, expected end of string");
                        abort();
                    case '\\':
                        if (str+1 == '\0') {
                            filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                                    "fmi2Instantiate: Found end of file, expected end of string");
                            abort();
                        }
                        str+=2;
                        break;
                    case '"':
                        return str+1;
                        default:
                        str++;
                }
            } while (1);
            abort();
            break;
        case '-':
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
            endptr = NULL;
            strtod(str,&endptr);
            if (str == endptr) {
                filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                        "fmi2Instantiate: Not a number, got %.20s\n", str);
                abort();
            }
            return endptr;
        default:
            filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                    "fmi2Instantiate: JSON value expected, got: %.20s\n", str);
            abort();
    }

    /* function should never reach this point */
    filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
            "fmi2Instantiate: Function should not be able to reach this point. Report a bug and get a cooky!");
    return str;
}


/*
 * Helper function for reading JSON.
 * Skip everything inside field, if it exists.
 */
static omsi_string skipFieldIfExist(omsi_string str,
                                    omsi_string name) {
    omsi_string s = str;
    omsi_int len = strlen(name);

    if (*s != ',') {
        return str;
    }
    s++;
    if (*s != '\"' || strncmp(s+1,name,len)) {
        return str;
    }
    s += len + 1;
    if (strncmp("\":", s, 2)) {
        return str;
    }
    s += 2;
    s = skipSpace(s);
    s = skipValue(s);
    s = skipSpace(s);
    s = skipSpace(s);
    return s;
}


/*
 * Helper function for reading JSON.
 * Read single equation from string created from JSON file.
 * Save detailed informations about equation in equation_info.
 */
omsi_string readEquation(omsi_string        str,
                         equation_info_t*   equation_info,
                         omsi_unsigned_int  expected_id,
                         omsi_unsigned_int* count_init_eq,
                         omsi_unsigned_int* count_regular_eq,
                         omsi_unsigned_int* count_alias_eq) {

    /* variables */
    omsi_int n = 0;
    omsi_int j = 0;
    omsi_string str2;
    omsi_char* tmp_number;

    /* read equation index */
    str=assertChar(str,'{');
    str=assertStringValue(str,"eqIndex");
    str=assertChar(str,':');
    str=assertNumber(str,expected_id);      /* checks if expected id matches found value */
    str=skipSpace(str);
    equation_info->id = expected_id;

    /* read field parent if exists*/
    if (strncmp(",\"parent\"", str, 9) == 0) {
        str=assertChar(str,',');
        str=assertStringValue(str, "parent");
        str=assertChar(str,':');
        while (*str != ',') {
            str = str+1;
            j++;
        }
        tmp_number = (omsi_char *) global_callback->allocateMemory(j+1, sizeof(omsi_char));
        strncpy (tmp_number, str-j, sizeof(omsi_char)*j);
        tmp_number[j+1] = '\0';
        equation_info->parent = (omsi_int) strtol(tmp_number,NULL ,10);
        global_callback->freeMemory(tmp_number);
    }
    str=skipSpace(str);

    /* read field section */
     if (strncmp(",\"section\"", str, 9) == 0) {
         str=assertChar(str,',');
         str=assertStringValue(str, "section");
         str=assertChar(str,':');
         str=skipSpace(str);
         if (strncmp("\"initial\"", str, 9) == 0) {
             *count_init_eq = *count_init_eq +1;
             str += 9;
         }
         else if (strncmp("\"regular\"", str, 9) == 0) {
             *count_regular_eq = *count_regular_eq +1;
             str += 9;
         }
         else if (strncmp("\"start\"", str, 7) == 0) {
             *count_init_eq = *count_init_eq +1;
             str += 7;
         }
         else {
             str = skipValue(str);
         }
     }

    if (0==strncmp(",\"tag\":\"system\"", str, 15)) {
        equation_info->profileBlockIndex = -1;
        str += 15;
    } else if (0==strncmp(",\"tag\":\"tornsystem\"", str, 19)) {
        equation_info->profileBlockIndex = -1;
        str += 19;
    } else if (0==strncmp(",\"tag\":\"alias\"", str, 14)) {
        *count_alias_eq = *count_alias_eq +1;
        equation_info->profileBlockIndex = 0;
    } else {
        equation_info->profileBlockIndex = 0;
    }
    str = skipFieldIfExist(str, "tag");
    str = skipFieldIfExist(str, "display");
    str = skipFieldIfExist(str, "unknowns");
    /* read defines */
    if (strncmp(",\"defines\":[", str, 12)) {       /* case no ",\"defines\":[" was found */
        equation_info->numVar = 0;
        equation_info->variables = NULL;
        str = skipObjectRest(str,0);
        return str;
    }
    str += 12;
    str = skipSpace(str);
    if (*str == ']') {      /* case there is nothing in defines */
        equation_info->numVar = 0;
        equation_info->variables = NULL;
        return skipObjectRest(str-1,0);
    }

    /* count number of defining variables */
    str2 = skipSpace(str);
    while (1) {
        str=skipValue(str);
        n++;
        str=skipSpace(str);
        if (*str != ',') {
            break;
        }
        str++;
    };
    assertChar(str, ']');
    equation_info->numVar = n;
    equation_info->variables = (omsi_string*) global_callback->allocateMemory(n, sizeof(omsi_string));

    /* save defining variables */
    str = str2;
    for (j=0; j<n; j++) {
        omsi_string str3 = skipSpace(str);
        omsi_char* tmp;
        omsi_unsigned_int len=0;
        str = assertChar(str, '\"');
        while (*str != '\"' && *str) {
            len++;
            str++;
        }
        str = assertChar(str, '\"');
        tmp = (omsi_char*) global_callback->allocateMemory(len+1, sizeof(omsi_char));
        strncpy(tmp, str3+1, len);
        tmp[len] = '\0';
        equation_info->variables[j] = tmp;
        if (j != n-1) {
            str = assertChar(str, ',');
        }
    }
    str = assertChar(skipSpace(str), ']');

    /* ToDo: read file info */

    return skipObjectRest(str,0);
}

/*
 * Helper function for reading JSON.
 * Read equations part from string created from JSON file.
 * For every equation a sub function is called to save detailed informations in equation_info.
 */
omsi_string readEquations(omsi_string       str,
                          model_data_t*     model_data) {

    /* Variables */
    omsi_int i = 0;
    omsi_bool endNotFound = omsi_true;
    omsi_string str_start;

    /* Check model_data */
    if (!model_data) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2Instantiate: In function readEquations: Memory for model_data not allocated.\n");
        abort();
    }

    /* Initialize counter for regular and initial equations*/
    model_data->n_regular_equations = 0;
    model_data->n_init_equations = 0;
    model_data->n_alias_equations = 0;

    /* skip first dummy equation */
    str = assertChar(str,'[');
    str = assertChar(str,'{');
    str = assertStringValue(str,"eqIndex");
    str = assertChar(str,':');
    str = assertChar(str,'0');
    str = assertChar(str,',');
    str = assertStringValue(str,"tag");
    str = assertChar(str,':');
    str = assertStringValue(str,"dummy");
    str = assertChar(str,'}');
    str = skipSpace(str);

    str_start = str;     /*save current location on string */

    /* count number of equations */
    do {
        str = omsu_assertCharOrEnd (str, ',', &endNotFound);
        if (!endNotFound) {
            break;
        }
        i++;
        str = skipSpace(str);
        str = skipValue(str);
    }while (omsi_true);

    model_data->n_equations = i;
    model_data->equation_info = (equation_info_t*) global_callback->allocateMemory(model_data->n_equations, sizeof(equation_info_t));

    str = str_start;    /* reset str to start of equations */
    endNotFound = omsi_true;
    i=0;
    do {
        str = omsu_assertCharOrEnd (str, ',', &endNotFound);
        if (!endNotFound) {
            break;
        }
        i++;
        str = skipSpace(str);
        str = readEquation(str, &(model_data->equation_info[i-1]), i, &model_data->n_init_equations, &model_data->n_regular_equations, &model_data->n_alias_equations);
    }while (omsi_true);

    str=assertChar(str,']');
    return str;
}


/**
 * \brief Reads all informations from JSON file.
 *
 * Actually skips everything except for equations, but checks if format of JSON is correct.
 *
 * \param [in]      str         String containing content of JSON file.
 * \param [in,out]  model_data  Pointer to struct used for saving data read from JSON file.
 */
static void readInfoJson(omsi_string    str,
                         model_data_t*  model_data) {
    /* check and skip content until begin of equations */
    str=assertChar(str,'{');
    str=assertStringValue(str,"format");
    str=assertChar(str,':');
    str=assertStringValue(str,"Transformational debugger info");
    str=assertChar(str,',');
    str=assertStringValue(str,"version");
    str=assertChar(str,':');
    str=assertChar(str,'1');
    str=assertChar(str,',');
    str=assertStringValue(str,"info");
    str=assertChar(str,':');
    str=skipValue(str);
    str=assertChar(str,',');
    str=assertStringValue(str,"variables");
    str=assertChar(str,':');
    str=skipValue(str);
    str=assertChar(str,',');

    /* read equations */
    str=assertStringValue(str,"equations");
    str=assertChar(str,':');
    str=readEquations(str, model_data);
    str=assertChar(str,',');

    /* check and skip remaining content */
    str=assertStringValue(str,"functions");
    str=assertChar(str,':');
    str=skipValue(str);
    assertChar(str,'}');
}

/** \} */
