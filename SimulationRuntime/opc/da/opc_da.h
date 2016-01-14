#ifndef _OPC_UA_H
#define _OPC_UA_H

#include "addas.h"
#include "adopcs.h"
#include "simulation_data.h"

#ifdef __cplusplus
extern "C" {
#endif

struct Group {
  AddaModuleId aModuleId;
  double frequency;
  double lastOPCEmit;
  int handle;
};

// Initializes OPC DA server
int opc_da_init(DATA *data, double tout, double step, const char *argv_0);

// Deinitializes OPC DA server
void opc_da_deinit();

// Tells the OPC UA server that a simulation step has passed; the server
// can read/write values from/to the simulator
void opc_da_new_iteration(double tout);

#ifdef __cplusplus
}
#endif

#endif /* _OPC_UA_H */
