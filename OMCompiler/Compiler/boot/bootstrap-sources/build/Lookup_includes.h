#ifdef __cplusplus
extern "C" {
#endif
#include "openmodelica.h"       // Defines OPENMODELICA_H_ for libraries to test if called from OpenModelica.
#include "ModelicaUtilities.h"  // Make Modelica C util functions available for external includes.
#include "AbsynUtil.h"
#include "BaseHashTable.h"
#include "Builtin.h"
#include "ClassInfUtil.h"
#include "ComponentReference.h"
#include "ComponentReferenceBasics.h"
#include "Config.h"
#include "DAEUtil.h"
#include "Debug.h"
#include "Error.h"
#include "ErrorExt.h"
#include "Expression.h"
#include "ExpressionBasics.h"
#include "FCore.h"
#include "FGraph.h"
#include "FNode.h"
#include "Flags.h"
#include "HashTableStringToPath.h"
#include "Inst.h"
#include "InstExtends.h"
#include "InstFunction.h"
#include "InstUtil.h"
#include "List.h"
#include "Lookup.h"
#include "Mod.h"
#include "Mutable.h"
#include "PrefixUtil.h"
#include "SCodeDump.h"
#include "SCodeUtil.h"
#include "Static.h"
#include "Types.h"
#include "TypesDump.h"
#include "Util.h"
#include "ValuesUtil.h"
#ifdef __cplusplus
}
#endif
