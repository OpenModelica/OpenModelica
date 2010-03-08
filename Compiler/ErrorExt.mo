/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
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
 * from Linköping University, either from the above address,
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
 */

package ErrorExt
"
  file:	       ErrorExt.mo
  package:     ErrorExt
  description: Error handling External interface

  RCS: $Id$

  This file contains the external interface to the error handling.
  Error messages are stored externally, impl. in C++."


public import Error;

public function updateCurrentComponent
  input String str;
  input Boolean writeable;
  input String fileName;
  input Integer rowstart;
  input Integer rowend;
  input Integer colstart;
  input Integer colend;
  external "C";
end updateCurrentComponent;

public function addMessage
  input Error.ErrorID inErrorID1;
  input String inString2;
  input String inString3;
  input String inString4;
  input list<String> inStringLst5;

  external "C" ;
end addMessage;

public function addSourceMessage
  input Error.ErrorID inErrorID1;
  input String inString2;
  input String inString3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  input Integer inInteger7;
  input Boolean inBoolean8;
  input String inString9;
  input String inString10;
  input list<String> inStringLst11;

  external "C" ;
end addSourceMessage;

public function printMessagesStr
  output String outString;

  external "C" ;
end printMessagesStr;

public function getNumMessages
  output Integer num;

  external "C";
end getNumMessages;

public function getNumErrorMessages
  output Integer num;

  external "C";
end getNumErrorMessages;

public function getMessagesStr
  output String outString;

  external "C" ;
end getMessagesStr;

public function clearMessages
  external "C" ;
end clearMessages;

public function errorOff

  external "C" ;
end errorOff;

public function errorOn

  external "C" ;
end errorOn;

public function setCheckpoint

  external "C" ;
end setCheckpoint;

public function delCheckpoint

  external "C" ;
end delCheckpoint;

public function printErrorsNoWarning
  output String outString;
  external "C" ;
end printErrorsNoWarning;

public function rollBack
  external "C" ;
end rollBack;

end ErrorExt;

