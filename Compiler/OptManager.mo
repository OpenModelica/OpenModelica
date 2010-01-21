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
 
package OptManager 
" file:	       OptManager.mo
  Author:      BZ
  module:      OptManager
  description: Runtime options
 

  This module takes care of command line options. It is possible to 
  ask it what flags are set, what arguments were given etc.
   
  This module is used pretty much everywhere where debug calls are made."

public function dumpOptions "
Author BZ 2008-06
Dump all options."
external "C";
end dumpOptions;

public function setOption "
Author: BZ 2008-06
Set one option, to set an option requires that the option to be set already exists in the program.
This is done in runtime/OptManager.cpp->OptManager_5finit.
"
  input String option;
  input Boolean optionValue;
  output Boolean succeded;
  external "C";
end setOption;

public function getOption "
Author: BZ 2008-06 
Get option as String.
"
  input String option;
  output Boolean optionValue;
  external "C";
end getOption;

end OptManager;