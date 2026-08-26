#ifdef __cplusplus
extern "C" {
#endif
#include "openmodelica.h"       // Defines OPENMODELICA_H_ for libraries to test if called from OpenModelica.
#include "ModelicaUtilities.h"  // Make Modelica C util functions available for external includes.
#include "AbsynUtil.h"
#include "BaseHashTable.h"
#include "ComponentReference.h"
#include "ComponentReferenceBasics.h"
#include "Config.h"
#include "DAEDump.h"
#include "DAEUtil.h"
#include "ElementSource.h"
#include "Error.h"
#include "Expression.h"
#include "ExpressionBasics.h"
#include "ExpressionSimplify.h"
#include "Flags.h"
#include "Graph.h"
#include "HashTableExpToIndex.h"
#include "HashTableStringToPath.h"
#include "List.h"
#include "Mod.h"
#include "Patternm.h"
#include "ProgramUtil.h"
#include "Settings.h"
#include "SimCodeFunctionUtil.h"
#include "StringUtil.h"
#include "System.h"
#include "Testsuite.h"
#include "Types.h"
#include "TypesDump.h"
#include "UnorderedMap.h"
#include "Util.h"
#ifdef __cplusplus
}
#endif
