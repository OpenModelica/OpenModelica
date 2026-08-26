#ifdef __cplusplus
extern "C" {
#endif
#include "openmodelica.h"       // Defines OPENMODELICA_H_ for libraries to test if called from OpenModelica.
#include "ModelicaUtilities.h"  // Make Modelica C util functions available for external includes.
#include "BackendCevalInterface.h"
#include "BackendInterface.h"
#include "BackendInterfaceImplementation.h"
#include "CevalScript.h"
#include "InstHashTable.h"
#include "RewriteRules.h"
#include "StaticScript.h"
#include "SymbolTable.h"
#ifdef __cplusplus
}
#endif
