#ifdef __cplusplus
extern "C" {
#endif
#include "openmodelica.h"       // Defines OPENMODELICA_H_ for libraries to test if called from OpenModelica.
#include "ModelicaUtilities.h"  // Make Modelica C util functions available for external includes.
#include "AbsynUtil.h"
#include "BaseHashSet.h"
#include "ClassInfUtil.h"
#include "ComponentReferenceBasics.h"
#include "Config.h"
#include "ConnectUtil.h"
#include "DAEUtil.h"
#include "Debug.h"
#include "ElementSource.h"
#include "Error.h"
#include "ErrorExt.h"
#include "Expression.h"
#include "ExpressionBasics.h"
#include "FGraph.h"
#include "Flags.h"
#include "InnerOuter.h"
#include "Inst.h"
#include "InstBinding.h"
#include "InstDAE.h"
#include "InstFunction.h"
#include "InstSection.h"
#include "InstUtil.h"
#include "InstVar.h"
#include "List.h"
#include "Lookup.h"
#include "Mod.h"
#include "PrefixUtil.h"
#include "SCodeDump.h"
#include "SCodeUtil.h"
#include "Types.h"
#include "TypesDump.h"
#include "UnitAbsynBuilder.h"
#include "Util.h"
#include "ValuesUtil.h"
#ifdef __cplusplus
}
#endif
