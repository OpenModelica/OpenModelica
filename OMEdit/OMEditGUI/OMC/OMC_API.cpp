/* TODO: Automatically generate this */

#if USE_OMC_SHARED_OBJECT

#include "OMC_API.h"
#include <stdexcept>

namespace OMC {
namespace API {

getClassInformation_result getClassInformation(threadData_t *threadData, void* &st, QString className)
{
  getClassInformation_result result;
  QByteArray className_utf8 = className.toUtf8();
  void *restriction = NULL;
  void *comment = NULL;
  void *fileName = NULL;
  void *dimensions = NULL;

  MMC_TRY_TOP_INTERNAL()

  st = omc_OpenModelicaScriptingAPI_getClassInformation(threadData, st, mmc_mk_scon(className_utf8.data()),
    &restriction, &comment, &result.partialPrefix, &result.finalPrefix, &result.encapsulatedPrefix,
    &fileName, &result.fileReadOnly, &result.lineNumberStart, &result.columnNumberStart,
    &result.lineNumberEnd, &result.columnNumberEnd, &dimensions);

  MMC_CATCH_TOP(throw std::runtime_error("getClassInformation failed");)

  result.restriction = QString::fromUtf8(MMC_STRINGDATA(restriction));
  result.comment = QString::fromUtf8(MMC_STRINGDATA(comment));
  result.fileName = QString::fromUtf8(MMC_STRINGDATA(fileName));
  while (!MMC_NILTEST(dimensions)) {
    result.dimensions.push_back(MMC_STRINGDATA(MMC_CAR(dimensions)));
    dimensions = MMC_CDR(dimensions);
  }

  return result;
}

}
}

#endif
