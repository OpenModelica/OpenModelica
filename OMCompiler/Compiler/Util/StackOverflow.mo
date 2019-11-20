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

encapsulated package StackOverflow

protected

import System;
import Testsuite;

function unmangle
  input String inSymbol;
  output String outSymbol;
algorithm
  outSymbol := inSymbol;
  if stringLength(inSymbol)>4 then
    if substring(inSymbol, 1, 4) == "omc_" then
      outSymbol := substring(outSymbol, 5, stringLength(outSymbol));
      outSymbol := System.stringReplace(outSymbol, "__", "#");
      outSymbol := System.stringReplace(outSymbol, "_", ".");
      outSymbol := System.stringReplace(outSymbol, "#", "_");
    end if;
  end if;
end unmangle;

function stripAddresses
  input String inSymbol;
  output String outSymbol;
protected
  Integer n;
  list<String> strs;
  String so,fun;
algorithm
  // regex for Linux messages
  (n,strs) := System.regex(inSymbol, "^([^(]*)[(]([^+]*[^+]*)[+][^)]*[)] *[[]0x[0-9a-fA-F]*[]]$", 3, extended=true);
  if n == 3 then
    {_,so,fun} := strs;
    outSymbol := so + "(" + unmangle(fun) + ")";
  else
    // regex for OSX messages
    (n,strs) := System.regex(inSymbol, "^[0-9 ]*([A-Za-z0-9.]*) *0x[0-9a-fA-F]* ([A-Za-z0-9_]*) *[+] *[0-9]*$", 3, extended=true);
    if n == 3 then
      {_,so,fun} := strs;
      outSymbol := so + "(" + unmangle(fun) + ")";
    else
      outSymbol := inSymbol;
    end if;
  end if;
end stripAddresses;

public

function triggerStackOverflow
  external "C" mmc_do_stackoverflow(OpenModelica.threadData()) annotation(Documentation(info="<html>
<p>Fakes a stack overflow (useful for debugging; forces earlier exit
since most functions do not catch stack overflow, and gives you a
stacktrace of the position you triggered this from).</p>
</html>"));
end triggerStackOverflow;

function generateReadableMessage
  input Integer numFrames=1000;
  input Integer numSkip=4;
  input String delimiter="\n";
  output String str;
algorithm
  StackOverflow.setStacktraceMessages(numSkip, numFrames);
  str := getReadableMessage(delimiter=delimiter);
end generateReadableMessage;

function getReadableMessage
  input String delimiter="\n";
  output String str;
algorithm
  str := stringDelimitList(StackOverflow.readableStacktraceMessages(),delimiter);
end getReadableMessage;

function readableStacktraceMessages
  output list<String> symbols = {};
protected
  String prev = "";
  Integer n = 1, prevN = 1;
algorithm
  if Testsuite.isRunning() then
    symbols := {"[bt] [Symbols are not generated when running the test suite]"};
    return;
  end if;
  for symbol in list(stripAddresses(s) for s in getStacktraceMessages()) loop
    if prev == "" then

    elseif symbol <> prev then
      symbols := ("[bt] #" + String(prevN) + (if n <> prevN then ("..."+String(n)) else "") + " " + prev)::symbols;
      n := n + 1;
      prevN := n;
    else
      n := n + 1;
    end if;
    prev := symbol;
  end for;
  symbols := ("[bt] #" + String(prevN) + (if n <> prevN then ("..."+String(n)) else "") + " " + prev)::symbols;
  symbols := listReverse(symbols);
end readableStacktraceMessages;

function getStacktraceMessages
  output list<String> symbols;
  external "C" symbols=mmc_getStacktraceMessages_threadData(OpenModelica.threadData())annotation(Documentation(info="<html>
<p>Returns a list of symbol names to print in error messages.</p>
</html>"));
end getStacktraceMessages;

function setStacktraceMessages
  input Integer numSkip;
  input Integer numFrames;
  external "C" mmc_setStacktraceMessages_threadData(OpenModelica.threadData(), numSkip, numFrames)annotation(Documentation(info="<html>
<p>Generate a stacktrace at the current position of code.</p>
</html>"));
end setStacktraceMessages;

function hasStacktraceMessages
  output Boolean b;
  external "C" b=mmc_hasStacktraceMessages(OpenModelica.threadData())annotation(Documentation(info="<html>
<p>Returns true if a stack overflow has occurred.</p>
</html>"));
end hasStacktraceMessages;

function clearStacktraceMessages
  external "C" mmc_clearStacktraceMessages(OpenModelica.threadData())annotation(Documentation(info="<html>
<p>Clears the stacktrace from a stack overflow.</p>
</html>"));
end clearStacktraceMessages;

annotation(__OpenModelica_Interface="util");
end StackOverflow;
