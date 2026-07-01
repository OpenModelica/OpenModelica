/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

// No-op OMS C API for the wasm build: OMSimulator has no wasm build, so OMS is
// unavailable and every call fails. OMSProxy is still constructed at startup, so
// these must link. Generated from OMSimulator.h.
#include <OMSimulator/OMSimulator.h>

extern "C" {

oms_status_enu_t oms_addBus(const char* cref) { return oms_status_error; }
oms_status_enu_t oms_addConnection(const char* crefA, const char* crefB, bool suppressUnitConversion) { return oms_status_error; }
oms_status_enu_t oms_addConnector(const char* cref, oms_causality_enu_t causality, oms_signal_type_enu_t type) { return oms_status_error; }
oms_status_enu_t oms_addConnectorToBus(const char* busCref, const char* connectorCref) { return oms_status_error; }
oms_status_enu_t oms_addSubModel(const char* cref, const char* fmuPath) { return oms_status_error; }
oms_status_enu_t oms_addSystem(const char* cref, oms_system_enu_t type) { return oms_status_error; }
oms_status_enu_t oms_delete(const char* cref) { return oms_status_error; }
oms_status_enu_t oms_deleteConnection(const char* crefA, const char* crefB) { return oms_status_error; }
oms_status_enu_t oms_deleteConnectorFromBus(const char* busCref, const char* connectorCref) { return oms_status_error; }
oms_status_enu_t oms_export(const char* cref, const char* filename) { return oms_status_error; }
oms_status_enu_t oms_exportSnapshot(const char* cref, char** contents) { return oms_status_error; }
oms_status_enu_t oms_getBoolean(const char* cref, bool* value) { return oms_status_error; }
oms_status_enu_t oms_getComponentType(const char* cref, oms_component_enu_t* type) { return oms_status_error; }
oms_status_enu_t oms_getConnections(const char* cref, oms_connection_t*** connections) { return oms_status_error; }
oms_status_enu_t oms_getElements(const char* cref, oms_element_t*** elements) { return oms_status_error; }
oms_status_enu_t oms_getFMUInfo(const char* cref, const oms_fmu_info_t** fmuInfo) { return oms_status_error; }
oms_status_enu_t oms_getFixedStepSize(const char* cref, double* stepSize) { return oms_status_error; }
oms_status_enu_t oms_getInteger(const char* cref, int* value) { return oms_status_error; }
oms_status_enu_t oms_getReal(const char* cref, double* value) { return oms_status_error; }
oms_status_enu_t oms_getResultFile(const char* cref, char** filename, int* bufferSize) { return oms_status_error; }
oms_status_enu_t oms_getSolver(const char* cref, oms_solver_enu_t* solver) { return oms_status_error; }
oms_status_enu_t oms_getStartTime(const char* cref, double* startTime) { return oms_status_error; }
oms_status_enu_t oms_getStopTime(const char* cref, double* stopTime) { return oms_status_error; }
oms_status_enu_t oms_getSubModelPath(const char* cref, char** path) { return oms_status_error; }
oms_status_enu_t oms_getSystemType(const char* cref, oms_system_enu_t* type) { return oms_status_error; }
oms_status_enu_t oms_getTolerance(const char* cref, double* absoluteTolerance, double* relativeTolerance) { return oms_status_error; }
oms_status_enu_t oms_getVariableStepSize(const char* cref, double* initialStepSize, double* minimumStepSize, double* maximumStepSize) { return oms_status_error; }
const char* oms_getVersion() { return "OMSimulator-disabled"; }
oms_status_enu_t oms_importFile(const char* filename, char** cref) { return oms_status_error; }
oms_status_enu_t oms_importSnapshot(const char* cref, const char* snapshot, char** newCref) { return oms_status_error; }
oms_status_enu_t oms_newModel(const char* cref) { return oms_status_error; }
oms_status_enu_t oms_rename(const char* cref, const char* newCref) { return oms_status_error; }
oms_status_enu_t oms_replaceSubModel(const char* cref, const char* fmuPath, bool dryRun, int* warningCount) { return oms_status_error; }
oms_status_enu_t oms_setBoolean(const char* cref, bool value) { return oms_status_error; }
oms_status_enu_t oms_setBusGeometry(const char* bus, const ssd_connector_geometry_t* geometry) { return oms_status_error; }
oms_status_enu_t oms_setCommandLineOption(const char* cmd) { return oms_status_error; }
oms_status_enu_t oms_setConnectionGeometry(const char* crefA, const char* crefB, const ssd_connection_geometry_t* geometry) { return oms_status_error; }
oms_status_enu_t oms_setConnectorGeometry(const char* cref, const ssd_connector_geometry_t* geometry) { return oms_status_error; }
oms_status_enu_t oms_setElementGeometry(const char* cref, const ssd_element_geometry_t* geometry) { return oms_status_error; }
oms_status_enu_t oms_setFixedStepSize(const char* cref, double stepSize) { return oms_status_error; }
oms_status_enu_t oms_setInteger(const char* cref, int value) { return oms_status_error; }
oms_status_enu_t oms_setLogFile(const char* filename) { return oms_status_error; }
void oms_setLoggingCallback(void (*cb)(oms_message_type_enu_t type, const char* message)) { }
oms_status_enu_t oms_setLoggingInterval(const char* cref, double loggingInterval) { return oms_status_error; }
oms_status_enu_t oms_setLoggingLevel(int logLevel) { return oms_status_error; }
oms_status_enu_t oms_setReal(const char* cref, double value) { return oms_status_error; }
oms_status_enu_t oms_setResultFile(const char* cref, const char* filename, int bufferSize) { return oms_status_error; }
oms_status_enu_t oms_setSolver(const char* cref, oms_solver_enu_t solver) { return oms_status_error; }
oms_status_enu_t oms_setStartTime(const char* cref, double startTime) { return oms_status_error; }
oms_status_enu_t oms_setStopTime(const char* cref, double stopTime) { return oms_status_error; }
oms_status_enu_t oms_setTempDirectory(const char* newTempDir) { return oms_status_error; }
oms_status_enu_t oms_setTolerance(const char* cref, double absoluteTolerance, double relativeTolerance) { return oms_status_error; }
oms_status_enu_t oms_setVariableStepSize(const char* cref, double initialStepSize, double minimumStepSize, double maximumStepSize) { return oms_status_error; }
oms_status_enu_t oms_setWorkingDirectory(const char* newWorkingDir) { return oms_status_error; }

} // extern "C"
