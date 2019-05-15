/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Author 2011: Adeel Asghar [adeel.asghar@liu.se]
 *
 */

 /*
 * On windows the -exec-interrupt command does not work.
 * Raises the SIGTRAP signal from the inferior process for GDB.
 */

#ifdef WIN32
#define _WIN32_WINNT 0x0502  // needed for DebugBreakProcess
#include <windows.h>
#  if !defined(PROCESS_SUSPEND_RESUME) // Check flag for MinGW
#     define PROCESS_SUSPEND_RESUME (0x0800)
#  endif // PROCESS_SUSPEND_RESUME
#endif
#include <stdio.h>

void printUsage() {
  printf("Usage: BreakProcess <pid>\n");
  printf("<pid>  Raises the SIGTRAP signal from the inferior process for GDB <pid>");
}

bool raise(unsigned long int pid) {
  bool ok = false;
    HANDLE inferior = NULL;
    do {
        const DWORD rights = PROCESS_QUERY_INFORMATION|PROCESS_SET_INFORMATION
                |PROCESS_VM_OPERATION|PROCESS_VM_WRITE|PROCESS_VM_READ
                |PROCESS_DUP_HANDLE|PROCESS_TERMINATE|PROCESS_CREATE_THREAD|PROCESS_SUSPEND_RESUME ;
        inferior = OpenProcess(rights, FALSE, pid);
        if (inferior == NULL) {
            printf("Inferior is NULL\n");
            break;
        }
        if (!DebugBreakProcess(inferior)) {
      printf("DebugBreakProcess failed: %s\n", GetLastError());
            break;
        }
        ok = true;
    } while (false);
    if (inferior != NULL)
        CloseHandle(inferior);
    return ok;
}

int main(int args, char *argv[]) {
  if (args != 2) {
    printUsage();
    return 1;
  } else if (strcasecmp(argv[1], "-h") == 0) {
    printUsage();
        return 1;
  } else if (strcasecmp(argv[1], "--help") == 0) {
    printUsage();
        return 1;
  } else {
    char *pId = argv[1];
    char *endptr;
    DWORD dwPid = strtoul(pId, &endptr, 0);
    bool result = raise(dwPid);
    if (result) {
      return 0;
    } else {
      return 1;
    }
  }
}
