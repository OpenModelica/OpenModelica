#ifdef __cplusplus
extern "C" {
#endif
#include "openmodelica.h"       // Defines OPENMODELICA_H_ for libraries to test if called from OpenModelica.
#include "ModelicaUtilities.h"  // Make Modelica C util functions available for external includes.
#include "AbsynUtil.h"
#include "Ceval.h"
#include "CevalScript.h"
#include "CevalScriptBackend.h"
#include "ComponentReference.h"
#include "Error.h"
#include "ErrorExt.h"
#include "Expression.h"
#include "ExpressionSimplify.h"
#include "Flags.h"
#include "Static.h"
#include "StaticScript.h"
#ifdef __cplusplus
}
#endif
