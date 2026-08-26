#ifdef __cplusplus
extern "C" {
#endif
#include "openmodelica.h"       // Defines OPENMODELICA_H_ for libraries to test if called from OpenModelica.
#include "ModelicaUtilities.h"  // Make Modelica C util functions available for external includes.
#include "AbsynJLDumpTpl.h"
#include "AbsynUtil.h"
#include "BackendInterfaceImplementation.h"
#include "CevalScript.h"
#include "CevalScriptBackend.h"
#include "Config.h"
#include "Debug.h"
#include "Dump.h"
#include "DumpGraphviz.h"
#include "Error.h"
#include "ErrorExt.h"
#include "ExecStat.h"
#include "FCore.h"
#include "FGraph.h"
#include "Flags.h"
#include "FlagsUtil.h"
#include "GCExt.h"
#include "Global.h"
#include "Interactive.h"
#include "List.h"
#include "Main.h"
#include "Parser.h"
#include "Print.h"
#include "ProgramUtil.h"
#include "Settings.h"
#include "Socket.h"
#include "StackOverflow.h"
#include "SymbolTable.h"
#include "System.h"
#include "Testsuite.h"
#include "Tpl.h"
#include "TplMain.h"
#include "Util.h"
#include "ZeroMQ.h"
#ifdef __cplusplus
}
#endif
