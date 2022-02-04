/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

encapsulated package Testsuite
" file:        Testsuite.mo
  package:     Testsuite
  description: Functions used when running the testsuite."

protected

import Autoconf;
import Flags;
import System;

public

function isRunning
  output Boolean runningTestsuite;
algorithm
  runningTestsuite := not stringEq(Flags.getConfigString(Flags.RUNNING_TESTSUITE),"");
end isRunning;

public function getTempFilesFile
  output String tempFile "File containing a list of files created by running this test so rtest can remove them after";
algorithm
  tempFile := Flags.getConfigString(Flags.RUNNING_TESTSUITE);
end getTempFilesFile;

public function friendly "Testsuite friendly name (start after testsuite/ or build/)"
  input String name;
  output String friendly;
algorithm
  friendly := friendly2(isRunning(),name);
end friendly;

protected function friendly2
  "Testsuite friendly name (start after testsuite/ or build/)"
  input Boolean cond;
  input String name;
  output String friendly;
algorithm
  friendly := match cond
    local
      Integer i;
      list<String> strs;
      String newName;

    case true
      algorithm
        newName := if Autoconf.os == "Windows_NT" then System.stringReplace(name, "\\", "/") else name;
        (i,strs) := System.regex(newName, "^(.*/Compiler/)?(.*/testsuite/(libraries-for-testing/.openmodelica/libraries/)?)?(.*/lib/omlibrary/)?(.*/build/(install_cmake/)?)?(.*)$", 8, true, false);
        friendly := listGet(strs,i);

        // Remove the name of any temporary folders used to sandbox a test case,
        // since they contain the process id which changes each time the test is run.
        (i,strs) := System.regex(friendly, "^(.*)(/[_[:alnum:]]*\\.mos?_temp[0-9]*)(.*)$", 4, true, false);
        if i == 4 then
          friendly := listGet(strs, 2) + listGet(strs, 4);
        end if;
      then
        friendly;

    else name;
  end match;
end friendly2;

public function friendlyPath
  "Adds ../ in front of a relative file path if we're running
   the testsuite, to compensate for tests being sandboxed.
   adrpo: only when running with partest the tests are sandboxed!"
  input String inPath;
  output String outPath;
algorithm
  outPath := matchcontinue()
    local
      String path;

    case ()
      equation
        // we're running the testsuite
        true = isRunning();
        // directory or file does not exist in this directory
        false = System.directoryExists(inPath);
        false = System.regularFileExists(inPath);
        // prefix the path
        path = "../" + inPath;
        true = System.directoryExists(path) or System.regularFileExists(path);
      then
        path;

    else inPath;
  end matchcontinue;
end friendlyPath;

annotation(__OpenModelica_Interface="util");
end Testsuite;
