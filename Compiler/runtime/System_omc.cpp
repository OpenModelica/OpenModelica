/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "systemimpl.c"

extern "C" {

extern void System_writeFile(const char* filename, const char* data)
{
  if (SystemImpl__writeFile(filename, data))
    throw 1;
}

extern char* System_readFile(const char* filename)
{
  return SystemImpl__readFile(filename);
}

extern const char* System_stringReplace(const char* str, const char* source, const char* target)
{
  char* res = _replace(str,source,target);
  if (res == NULL)
    throw 1;
  return res;
}

extern int System_stringFind(const char* str, const char* searchStr)
{
  const char *found = strstr(str, searchStr);
  if (found == NULL)
    return -1;
  else
    return found-str;
}

extern const char* System_stringFindString(const char* str, const char* searchStr)
{
  const char *found = strstr(str, searchStr);
  if (found == NULL)
    throw 1;
  return strdup(found);
}

extern void System_realtimeTick(int ix)
{
  if (ix < 0 || ix >= NUM_USER_RT_CLOCKS) throw 1;
  rt_tick(ix);
}

extern double System_realtimeTock(int ix)
{
  if (ix < 0 || ix >= NUM_USER_RT_CLOCKS) throw 1;
  return rt_tock(ix);
}

static modelica_integer tmp_tick_no = 0;

extern int System_tmpTick()
{
  return tmp_tick_no++;
}

extern void System_tmpTickReset(int start)
{
  tmp_tick_no = start;
}

extern const char* System_getSendDataLibs()
{
  return LDFLAGS_SENDDATA;
}

extern const char* System_getCCompiler()
{
  return strdup(cc);
}

extern const char* System_getCXXCompiler()
{
  return strdup(cxx);
}

extern const char* System_getLinker()
{
  return strdup(linker);
}

extern const char* System_getLDFlags()
{
  return strdup(ldflags);
}

extern const char* System_getCFlags()
{
  return strdup(cflags);
}

extern const char* System_getExeExt()
{
  return CONFIG_EXE_EXT;
}

extern const char* System_getDllExt()
{
  return CONFIG_DLL_EXT;
}

extern const char* System_os()
{
  return CONFIG_OS;
}

extern const char* System_trim(const char* str, const char* chars_to_remove)
{
  return SystemImpl__trim(str,chars_to_remove);
}

extern const char* System_basename(const char* str)
{
  return strdup(SystemImpl__basename(str));
}

extern const char* System_configureCommandLine()
{
  return CONFIGURE_COMMANDLINE;
}

extern const char* System_platform()
{
  return CONFIG_PLATFORM;
}

extern const char* System_pathDelimiter()
{
  return CONFIG_PATH_DELIMITER;
}

extern const char* System_groupDelimiter()
{
  return CONFIG_GROUP_DELIMITER;
}

extern int System_strncmp(const char *str1, const char *str2, int len)
{
  int res= strncmp(str1,str2,len);
  /* adrpo: 2010-10-07, return -1, 0, +1 so we can pattern match on it directly! */
  if      (res>0) res =  1;
  else if (res<0) res = -1;
  return res;
}

extern int System_strcmp(const char *str1, const char *str2)
{
  int res = strcmp(str1,str2);
  /* adrpo: 2010-10-07, return -1, 0, +1 so we can pattern match on it directly! */
  if      (res>0) res =  1;
  else if (res<0) res = -1;
  return res;
}

extern int System_getHasExpandableConnectors()
{
  return hasExpandableConnector;
}

extern void System_setHasExpandableConnectors(int b)
{
  hasExpandableConnector = b;
}

extern int System_hasInnerOuterDefinitions()
{
  return hasInnerOuterDefinitions;
}

extern void System_setHasInnerOuterDefinitions(int b)
{
  hasInnerOuterDefinitions = b;
}

extern void* System_strtok(const char *str0, const char *delimit)
{
  char *s;
  void *res = mmc_mk_nil();
  char *str = strdup(str0);
  s=strtok(str,delimit);
  if (s == NULL)
  {
    free(str);
    throw 1;
  }
  res = mmc_mk_cons(mmc_mk_scon(s),res);
  while (s=strtok(NULL,delimit))
  {
    res = mmc_mk_cons(mmc_mk_scon(s),res);
  }
  free(str);
  return listReverse(res);
}

}
