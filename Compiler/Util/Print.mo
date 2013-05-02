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

encapsulated package Print
" file:        Print.mo
  package:     Print
  description: Printing to buffers

  RCS: $Id$

  This module contains a buffered print function to be used instead of
  the built in print function, when the output should be redirected to
  some other place. It also contains print functions for error messages, to be
  used in interactive mode."

 public function saveAndClearBuf "saves and clears content of buffer and return a handle to the saved buffer so it can be restored by restorBuf later on"
  output Integer handle;
  external "C" handle = Print_saveAndClearBuf() annotation(Library = "omcruntime");
end saveAndClearBuf;

public function restoreBuf
  input Integer handle;
  external "C" Print_restoreBuf(handle) annotation(Library = "omcruntime");
end restoreBuf;

public function setBufSize
  input Integer newSize;

  external "C" Print_setBufSize(newSize) annotation(Library = "omcruntime");
end setBufSize;

public function unSetBufSize
  input Integer newSize "not used, this is a debuging func";

  external "C" Print_unSetBufSize(newSize) annotation(Library = "omcruntime");
end unSetBufSize;

public function printErrorBuf
  input String inString;

  external "C" Print_printErrorBuf(inString) annotation(Library = "omcruntime");
end printErrorBuf;

public function clearErrorBuf

  external "C" Print_clearErrorBuf() annotation(Library = "omcruntime");
end clearErrorBuf;

public function getErrorString
  output String outString;

  external "C" outString = Print_getErrorString() annotation(Library = "omcruntime");
end getErrorString;

public function printBuf
  input String inString;

  external "C" Print_printBuf(inString) annotation(Library = "omcruntime");
end printBuf;

public function clearBuf

  external "C" Print_clearBuf() annotation(Library = "omcruntime");
end clearBuf;

public function getString "Does not clear the buffer"
  output String outString;

  external "C" outString = Print_getString() annotation(Library = "omcruntime");
end getString;

public function writeBuf
  input String inString;

  external "C" Print_writeBuf(inString) annotation(Library = "omcruntime");
end writeBuf;

public function getBufLength
"Gets the actual length of the filled space in the print buffer."
  output Integer outBufFilledLength;

  external "C" outBufFilledLength = Print_getBufLength() annotation(Library = "omcruntime");
end getBufLength;

public function printBufSpace
"Prints the given number of spaces to the print buffer."
  input Integer inNumOfSpaces;

  external "C" Print_printBufSpace(inNumOfSpaces) annotation(Library = "omcruntime");
end printBufSpace;

public function printBufNewLine
"Prints one new line character to the print buffer."

  external "C" Print_printBufNewLine() annotation(Library = "omcruntime");
end printBufNewLine;

public function hasBufNewLineAtEnd
"Tests if the last outputted character in the print buffer is a new line.
 It is a (temporary) workaround to stringLength()'s O(n) cost."
  output Boolean outHasNewLineAtEnd ;

  external "C" outHasNewLineAtEnd = Print_hasBufNewLineAtEnd() annotation(Library = "omcruntime");
end hasBufNewLineAtEnd;

end Print;


