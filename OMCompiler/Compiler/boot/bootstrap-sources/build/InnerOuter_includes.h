#ifdef __cplusplus
extern "C" {
#endif
#include "openmodelica.h"       // Defines OPENMODELICA_H_ for libraries to test if called from OpenModelica.
#include "ModelicaUtilities.h"  // Make Modelica C util functions available for external includes.
#include "AbsynUtil.h"
#include "Array.h"
#include "BaseHashSet.h"
#include "ComponentReference.h"
#include "ComponentReferenceBasics.h"
#include "ConnectUtil.h"
#include "DAEUtil.h"
#include "Debug.h"
#include "Error.h"
#include "ErrorExt.h"
#include "FCore.h"
#include "FGraph.h"
#include "FNode.h"
#include "Flags.h"
#include "HashSet.h"
#include "InnerOuter.h"
#include "InstSection.h"
#include "List.h"
#include "Lookup.h"
#include "Mod.h"
#include "PrefixUtil.h"
#ifdef __cplusplus
}
#endif
