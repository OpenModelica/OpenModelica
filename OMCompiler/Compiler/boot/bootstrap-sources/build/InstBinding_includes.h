#ifdef __cplusplus
extern "C" {
#endif
#include "openmodelica.h"       // Defines OPENMODELICA_H_ for libraries to test if called from OpenModelica.
#include "ModelicaUtilities.h"  // Make Modelica C util functions available for external includes.
#include "AbsynUtil.h"
#include "Ceval.h"
#include "ComponentReference.h"
#include "ComponentReferenceBasics.h"
#include "DAEUtil.h"
#include "Debug.h"
#include "ElementSource.h"
#include "Error.h"
#include "Expression.h"
#include "ExpressionBasics.h"
#include "ExpressionSimplify.h"
#include "FGraph.h"
#include "Flags.h"
#include "InstBinding.h"
#include "InstSection.h"
#include "InstUtil.h"
#include "List.h"
#include "Mod.h"
#include "PrefixUtil.h"
#include "SCodeUtil.h"
#include "Types.h"
#include "TypesDump.h"
#include "ValuesUtil.h"
#ifdef __cplusplus
}
#endif
