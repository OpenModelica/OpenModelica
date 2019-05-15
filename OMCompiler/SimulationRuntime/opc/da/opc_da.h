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
int omc_embedded_server_init(DATA *data, double tout, double step, const char *argv_0);

// Deinitializes OPC DA server
void omc_embedded_server_deinit();

// Tells the OPC UA server that a simulation step has passed; the server
// can read/write values from/to the simulator
void omc_embedded_server_update(double tout);

#ifdef __cplusplus
}
#endif

#endif /* _OPC_UA_H */
