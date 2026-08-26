#ifdef __cplusplus
extern "C" {
#endif
#include "openmodelica.h"       // Defines OPENMODELICA_H_ for libraries to test if called from OpenModelica.
#include "ModelicaUtilities.h"  // Make Modelica C util functions available for external includes.
#include "AbsynUtil.h"
#include "AvlSetPath.h"
#include "AvlTreePathFunction.h"
#include "BaseHashTable.h"
#include "ClassInfUtil.h"
#include "ComponentReference.h"
#include "ComponentReferenceBasics.h"
#include "Config.h"
#include "DAEDump.h"
#include "DAEUtil.h"
#include "Debug.h"
#include "ElementSource.h"
#include "Error.h"
#include "Expression.h"
#include "ExpressionBasics.h"
#include "ExpressionSimplify.h"
#include "Flags.h"
#include "HashTableCG.h"
#include "Inline.h"
#include "List.h"
#include "SCodeUtil.h"
#include "Types.h"
#include "TypesDump.h"
#include "Util.h"
#include "VarTransform.h"
#ifdef __cplusplus
}
#endif
