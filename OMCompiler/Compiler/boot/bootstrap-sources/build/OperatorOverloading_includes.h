#ifdef __cplusplus
extern "C" {
#endif
#include "openmodelica.h"       // Defines OPENMODELICA_H_ for libraries to test if called from OpenModelica.
#include "ModelicaUtilities.h"  // Make Modelica C util functions available for external includes.
#include "AbsynToSCode.h"
#include "AbsynUtil.h"
#include "Ceval.h"
#include "Config.h"
#include "Debug.h"
#include "Dump.h"
#include "Error.h"
#include "Expression.h"
#include "ExpressionBasics.h"
#include "ExpressionDump.h"
#include "ExpressionSimplify.h"
#include "FCore.h"
#include "FGraph.h"
#include "Flags.h"
#include "Inline.h"
#include "List.h"
#include "Lookup.h"
#include "OperatorOverloading.h"
#include "PrefixUtil.h"
#include "SCodeUtil.h"
#include "Static.h"
#include "Types.h"
#include "TypesDump.h"
#include "Util.h"
#ifdef __cplusplus
}
#endif
