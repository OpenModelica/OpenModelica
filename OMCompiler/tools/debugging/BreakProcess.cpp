/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
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
