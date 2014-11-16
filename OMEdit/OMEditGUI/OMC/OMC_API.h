/* TODO: Automatically generate this */

extern "C" {
#include "meta/meta_modelica.h"
modelica_metatype omc_OpenModelicaScriptingAPI_getClassInformation(threadData_t *threadData, modelica_metatype _st, modelica_string _className, modelica_string *out_restriction, modelica_string *out_comment, modelica_boolean *out_partialPrefix, modelica_boolean *out_finalPrefix, modelica_boolean *out_encapsulatedPrefix, modelica_string *out_fileName, modelica_boolean *out_fileReadOnly, modelica_integer *out_lineNumberStart, modelica_integer *out_columnNumberStart, modelica_integer *out_lineNumberEnd, modelica_integer *out_columnNumberEnd, modelica_metatype *out_dimensions);
}

#include <QtCore>

namespace OMC {

namespace API {

typedef struct {
  QString restriction;
  QString comment;
  modelica_boolean partialPrefix;
  modelica_boolean finalPrefix;
  modelica_boolean encapsulatedPrefix;
  QString fileName;
  modelica_boolean fileReadOnly;
  modelica_integer lineNumberStart;
  modelica_integer columnNumberStart;
  modelica_integer lineNumberEnd;
  modelica_integer columnNumberEnd;
  QStringList dimensions;
} getClassInformation_result;

getClassInformation_result getClassInformation(threadData_t *threadData, void* &st, QString className);

}

}
