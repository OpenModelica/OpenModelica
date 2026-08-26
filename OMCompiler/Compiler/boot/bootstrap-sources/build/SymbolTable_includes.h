#ifdef __cplusplus
extern "C" {
#endif
#include "openmodelica.h"       // Defines OPENMODELICA_H_ for libraries to test if called from OpenModelica.
#include "ModelicaUtilities.h"  // Make Modelica C util functions available for external includes.
#include "AbsynToSCode.h"
#include "AbsynUtil.h"
#include "AvlTreeStringString.h"
#include "CevalFunction.h"
#include "ComponentReferenceBasics.h"
#include "Error.h"
#include "FCore.h"
#include "FGraph.h"
#include "Inst.h"
#include "List.h"
#include "Lookup.h"
#include "MetaUtil.h"
#include "SCodeUtil.h"
#include "SymbolTable.h"
#include "System.h"
#include "Vector.h"
#ifdef __cplusplus
}
#endif
