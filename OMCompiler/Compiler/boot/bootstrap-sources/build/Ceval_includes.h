#ifdef __cplusplus
extern "C" {
#endif
#include "openmodelica.h"       // Defines OPENMODELICA_H_ for libraries to test if called from OpenModelica.
#include "ModelicaUtilities.h"  // Make Modelica C util functions available for external includes.
#include "AbsynUtil.h"
#include "BackendCevalInterface.h"
#include "Ceval.h"
#include "ComponentReference.h"
#include "ComponentReferenceBasics.h"
#include "Config.h"
#include "Debug.h"
#include "Error.h"
#include "Expression.h"
#include "ExpressionBasics.h"
#include "ExpressionDump.h"
#include "ExpressionSimplify.h"
#include "FCore.h"
#include "FGraph.h"
#include "Flags.h"
#include "InstBinding.h"
#include "InstUtil.h"
#include "List.h"
#include "Lookup.h"
#include "Mutable.h"
#include "Print.h"
#include "SCodeUtil.h"
#include "Static.h"
#include "System.h"
#include "Types.h"
#include "TypesDump.h"
#include "Util.h"
#include "ValuesDump.h"
#include "ValuesMake.h"
#include "ValuesUtil.h"
#ifdef __cplusplus
}
#endif
