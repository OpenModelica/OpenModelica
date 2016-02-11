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
 * THIS OSMC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) License (OSMC-PL) are obtained
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
 * See the full OSMC License conditions for more details.
 *
 */

encapsulated package ErrorExt
"
  file:         ErrorExt.mo
  package:     ErrorExt
  description: Error handling External interface


  This file contains the external interface to the error handling.
  Error messages are stored externally, impl. in C++."


import Error;

function registerModelicaFormatError
  external "C" Error_registerModelicaFormatError() annotation(Documentation(info="<html>
<p>Registers the ModelicaFormatError function to output messages in the Error buffer instead of the default standard output.</p>
<p>Note: Only works in the bootstrapped compiler!</p>
</html>"),Library = "omcruntime");
end registerModelicaFormatError;

function updateCurrentComponent
  input String str;
  input Boolean writeable;
  input String fileName;
  input Integer rowstart;
  input Integer rowend;
  input Integer colstart;
  input Integer colend;
  external "C" ErrorImpl__updateCurrentComponent(OpenModelica.threadData(),str,writeable,fileName,rowstart,rowend,colstart,colend) annotation(Library = "omcruntime");
end updateCurrentComponent;

function addMessage
  input Error.ErrorID id;
  input Error.MessageType msg_type;
  input Error.Severity msg_severity;
  input String msg;
  input list<String> msg_tokens;

  external "C" Error_addMessage(OpenModelica.threadData(),id,msg_type,msg_severity,msg,msg_tokens) annotation(Library = "omcruntime");
end addMessage;

function addSourceMessage
  input Error.ErrorID id;
  input Error.MessageType msg_type;
  input Error.Severity msg_severity;
  input Integer sline;
  input Integer scol;
  input Integer eline;
  input Integer ecol;
  input Boolean read_only;
  input String filename;
  input String msg;
  input list<String> tokens;

  external "C" Error_addSourceMessage(OpenModelica.threadData(),id,msg_type,msg_severity,sline,scol,eline,ecol,read_only,filename,msg,tokens) annotation(Library = "omcruntime");
end addSourceMessage;

function printMessagesStr
  input Boolean warningsAsErrors = false;
  output String outString;

  external "C" outString=Error_printMessagesStr(OpenModelica.threadData(),warningsAsErrors) annotation(Library = "omcruntime");
end printMessagesStr;

function getNumMessages
  output Integer num;

  external "C" num=Error_getNumMessages(OpenModelica.threadData()) annotation(Library = "omcruntime");
end getNumMessages;

function getNumErrorMessages
  output Integer num;

  external "C" num=ErrorImpl__getNumErrorMessages(OpenModelica.threadData()) annotation(Library = "omcruntime");
end getNumErrorMessages;

function getNumWarningMessages
  output Integer num;

  external "C" num=ErrorImpl__getNumWarningMessages(OpenModelica.threadData()) annotation(Library = "omcruntime");
end getNumWarningMessages;

function getMessages
  output list<Error.TotalMessage> res;

  external "C" res=Error_getMessages(OpenModelica.threadData()) annotation(Library = "omcruntime");
end getMessages;

function clearMessages
  external "C" ErrorImpl__clearMessages(OpenModelica.threadData()) annotation(Library = "omcruntime");
end clearMessages;

function getNumCheckpoints "Used to rollback/delete checkpoints without considering the identifier. Used to reset the error messages after a stack overflow exception."
  output Integer n;
  external "C" n=ErrorImpl__getNumCheckpoints(OpenModelica.threadData()) annotation(Library = "omcruntime");
end getNumCheckpoints;

function rollbackNumCheckpoints "Used to rollback/delete checkpoints without considering the identifier. Used to reset the error messages after a stack overflow exception."
  input Integer n;
  external "C" ErrorImpl__rollbackNumCheckpoints(OpenModelica.threadData(), n) annotation(Library = "omcruntime");
end rollbackNumCheckpoints;

function deleteNumCheckpoints "Used to rollback/delete checkpoints without considering the identifier. Used to reset the error messages after a stack overflow exception."
  input Integer n;
  external "C" ErrorImpl__deleteNumCheckpoints(OpenModelica.threadData(), n) annotation(Library = "omcruntime");
end deleteNumCheckpoints;

function setCheckpoint "sets a checkpoint for the error messages, so error messages can be rolled back (i.e. deleted) up to this point
A unique identifier for this checkpoint must be provided. It is checked when doing rollback or deletion"
  input String id "uniqe identifier for the checkpoint (up to the programmer to guarantee uniqueness)";
  external "C" ErrorImpl__setCheckpoint(OpenModelica.threadData(),id) annotation(Library = "omcruntime");
end setCheckpoint;

function delCheckpoint "deletes the checkpoint at the top of the stack without
removing the error messages issued since that checkpoint.
If the checkpoint id doesn't match, the application exits with -1.
"

  input String id "unique identifier";
  external "C" ErrorImpl__delCheckpoint(OpenModelica.threadData(),id) annotation(Library = "omcruntime");
end delCheckpoint;

function printErrorsNoWarning
  output String outString;
  external "C" outString=Error_printErrorsNoWarning(OpenModelica.threadData()) annotation(Library = "omcruntime");
end printErrorsNoWarning;

function rollBack "rolls back error messages until the latest checkpoint,
deleting all error messages added since that point in time. A unique identifier for the checkpoint must be provided
The application will exit with return code -1 if this identifier does not match."
  input String id "unique identifier";
  external "C" ErrorImpl__rollBack(OpenModelica.threadData(),id) annotation(Library = "omcruntime");
end rollBack;

function isTopCheckpoint
"@author: adrpo
  This function checks if the specified checkpoint exists AT THE TOP OF THE STACK!.
  You can use it to rollBack/delete a checkpoint, but you're
  not sure that it exists (due to MetaModelica backtracking)."
  input String id "unique identifier";
  output Boolean isThere "tells us if the checkpoint exists (true) or doesn't (false)";
  external "C" isThere=ErrorImpl__isTopCheckpoint(OpenModelica.threadData(),id) annotation(Library = "omcruntime");
end isTopCheckpoint;

function setShowErrorMessages
  input Boolean inShow;
  external "C" Error_setShowErrorMessages(OpenModelica.threadData(),inShow) annotation(Library = "omcruntime");
end setShowErrorMessages;

function moveMessagesToParentThread
  external "C" Error_moveMessagesToParentThread(OpenModelica.threadData()) annotation(Library = "omcruntime");
end moveMessagesToParentThread;

annotation(__OpenModelica_Interface="util");
end ErrorExt;
