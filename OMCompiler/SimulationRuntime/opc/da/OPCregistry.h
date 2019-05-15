#ifndef REGISTER_OPC_SERVER_DLL_H
#define REGISTER_OPC_SERVER_DLL_H

#ifdef __cplusplus
extern "C" {
#endif

#ifdef EXPORT_DLL
#define EXPORT_REGISTER_OPC_SERVER_DLL __declspec(dllexport)
#else
#define EXPORT_REGISTER_OPC_SERVER_DLL __declspec(dllimport)
#endif

// Initialize the COM interface for this thread
int EXPORT_REGISTER_OPC_SERVER_DLL __stdcall initCOM();

// Uninitialize the COM interface for this thread
int EXPORT_REGISTER_OPC_SERVER_DLL __stdcall uninitCOM();

// Register opc server. Zero if ok.
int EXPORT_REGISTER_OPC_SERVER_DLL __stdcall registerOPCServer(const char* apExeAndArguments, const char* apVersionIndependentProgrammaticId);

// Unregister opc server. Zero if ok.
int EXPORT_REGISTER_OPC_SERVER_DLL __stdcall unregisterOPCServer(const char* apVersionIndependentProgrammaticId);

#ifdef __cplusplus
}
#endif

#endif  // REGISTER_OPC_SERVER_DLL_H
