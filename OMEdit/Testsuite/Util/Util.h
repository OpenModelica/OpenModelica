/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef UTIL_H
#define UTIL_H

#include <QtGlobal>
#include <QtTest/QtTest>

#if (QT_VERSION >= QT_VERSION_CHECK(6, 0, 0))
#define OM_QTEST_ADD_GPU_BLACKLIST_SUPPORT_DEFS
#define OM_QTEST_ADD_GPU_BLACKLIST_SUPPORT
#else // #if (QT_VERSION >= QT_VERSION_CHECK(6, 0, 0))
#define OM_QTEST_ADD_GPU_BLACKLIST_SUPPORT_DEFS = QTEST_ADD_GPU_BLACKLIST_SUPPORT_DEFS
#define OM_QTEST_ADD_GPU_BLACKLIST_SUPPORT = QTEST_ADD_GPU_BLACKLIST_SUPPORT
#endif // #if (QT_VERSION >= QT_VERSION_CHECK(6, 0, 0))

#define OMEDITTEST_MAIN(TestObject) \
static int execution_failed() \
{ \
  fflush(NULL); \
  fprintf(stderr, "Execution failed!\n"); \
  fflush(NULL); \
  exit(1); \
} \
QT_BEGIN_NAMESPACE \
OM_QTEST_ADD_GPU_BLACKLIST_SUPPORT_DEFS \
QT_END_NAMESPACE \
int main(int argc, char *argv[]) \
{ \
  MMC_INIT(); \
  MMC_TRY_TOP() \
  Q_INIT_RESOURCE(resource_omedit); \
  OMEditApplication app(argc, argv, threadData, true); \
  app.setAttribute(Qt::AA_Use96Dpi, true); \
  QTEST_DISABLE_KEYPAD_NAVIGATION \
  OM_QTEST_ADD_GPU_BLACKLIST_SUPPORT \
  TestObject tc; \
  QTEST_SET_MAIN_SOURCE_PATH \
  return QTest::qExec(&tc,argc, argv); \
  MMC_CATCH_TOP(execution_failed()); \
}

#define OMEDITTEST_SKIP(description) \
QSKIP(description)

class LibraryTreeItem;
namespace Util {

 bool expandLibraryTreeItemParentHierarchy(const LibraryTreeItem *pLibraryTreeItem);

} // namespace Util

#endif // UTIL_H
