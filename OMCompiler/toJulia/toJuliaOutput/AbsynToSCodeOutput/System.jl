  module System


    using MetaModelica
    #= Necessary to write declarations for your uniontypes until Julia adds support for mutually recursive types =#


  ForkFunction = Function
  #=Reimplement me :(=#
  StringAllocator = Any
         #= /*
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
         * from the URLs: http:www.ida.liu.se/projects/OpenModelica or
         * http:www.openmodelica.org, and in the OpenModelica distribution.
         * GNU version 3 is obtained from: http:www.gnu.org/copyleft/gpl.html.
         *
         * This program is distributed WITHOUT ANY WARRANTY; without
         * even the implied warranty of  MERCHANTABILITY or FITNESS
         * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
         * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
         *
         * See the full OSMC Public License conditions for more details.
         *
         */ =#

        import Autoconf

         #= removes chars in charsToRemove from begin and end of inString =#
        function trim(inString::String, charsToRemove::String)::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

         #= removes chars in ' \\f\\n\\r\\t\\v' from begin and end of inString =#
        function trimWhitespace(inString::String)::String
              local outString::String

              outString = trim(inString)
          outString
        end

        function trimChar(inString1::String, inString2::String)::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

         #= This function returns:
          0 if inString1 == inString2
          1 if inString1 >  inString2
         -1 if inString1 <  inString2
         This is different from what C strcmp
         returns (negative values if <, positive values if >).
         We fix negative values to -1 and positive to +1 so
         we can pattern match on them directly in MetaModelica! =#
        function strcmp(inString1::String, inString2::String)::ModelicaInteger
              local outInteger::ModelicaInteger

            #= Defined in the runtime =#
          outInteger
        end

         #= Like strcmp, but also takes offset and lengths of the strings in order to avoid building them through substring =#
        function strcmp_offset(string1::String, offset1::ModelicaInteger, length1::ModelicaInteger, string2::String, offset2::ModelicaInteger, length2::ModelicaInteger)::ModelicaInteger
              local outInteger::ModelicaInteger

            #= Defined in the runtime =#
          outInteger
        end

         #= locates substring searchStr in str. If succeeds return position (starting from 0), otherwise return -1 =#
        function stringFind(str::String, searchStr::String)::ModelicaInteger
              local outInteger::ModelicaInteger

            #= Defined in the runtime =#
          outInteger
        end

         #= locates substring searchStr in str. If succeeds return the string, otherwise fail =#
        function stringFindString(str::String, searchStr::String)::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

         #= Fails and sets Error.mo if the regex does not compile.

          The returned result is the same as POSIX regex():
          The first value is the complete matched string
          The rest are the substrings that you wanted.
          For example:
          regex(lorem,\\\" \\\\([A-Za-z]*\\\\) \\\\([A-Za-z]*\\\\) \\\",maxMatches=3)
          => {\\\" ipsum dolor \\\",\\\"ipsum\\\",\\\"dolor\\\"}
          This means if you have n groups, you want maxMatches=n+1
         =#
        function regex(str::String, re::String, maxMatches #= The maximum number of matches that will be returned =#::ModelicaInteger, extended #= Use POSIX extended or regular syntax =#::Bool, ignoreCase::Bool)::Tuple{List, ModelicaInteger}
              local strs::List #= This list has length = maxMatches. Substrings that did not match are filled with the empty string =#
              local numMatches::ModelicaInteger #= 0 means no match, else returns a number 1..maxMatches (1 if maxMatches<0) =#

            #= Defined in the runtime =#
          (strs #= This list has length = maxMatches. Substrings that did not match are filled with the empty string =#, numMatches #= 0 means no match, else returns a number 1..maxMatches (1 if maxMatches<0) =#)
        end

        function strncmp(inString1::String, inString2::String, len::ModelicaInteger)::ModelicaInteger
              local outInteger::ModelicaInteger

            #= Defined in the runtime =#
          outInteger
        end

        function stringReplace(str::String, source::String, target::String)::String
              local res::String

            #= Defined in the runtime =#
          res
        end

         #= Replaces unknown characters with _ =#
        function makeC89Identifier(str::String)::String
              local res::String

            #= Defined in the runtime =#
          res
        end

        function toupper(inString::String)::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function tolower(inString::String)::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function strtok(string::String, token::String)::List
              local strings::List

            #= Defined in the runtime =#
          strings
        end

         #= as strtok but also includes *all* delimiters
         split the string at delimiters into a list of strings including *all* delimiters
         stringSplitInTokens(*a**b*, *) => {*, a, *, *, b, *} =#
        function strtokIncludingDelimiters(string::String, token::String)::List
              local strings::List

            #= Defined in the runtime =#
          strings
        end

        function setCCompiler(inString::String)
            #= Defined in the runtime =#
        end

        function getCCompiler()::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function setCFlags(inString::String)
            #= Defined in the runtime =#
        end

        function getCFlags()::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function setCXXCompiler(inString::String)
            #= Defined in the runtime =#
        end

        function getCXXCompiler()::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function getOMPCCompiler()::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function setLinker(inString::String)
            #= Defined in the runtime =#
        end

        function getLinker()::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function setLDFlags(inString::String)
            #= Defined in the runtime =#
        end

        function getLDFlags()::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function loadLibrary(inLib::String, inPrintDebug::Bool)::ModelicaInteger
              local outLibHandle::ModelicaInteger

            #= Defined in the runtime =#
          outLibHandle
        end

        function lookupFunction(inLibHandle::ModelicaInteger, inFunc::String)::ModelicaInteger
              local outFuncHandle::ModelicaInteger

            #= Defined in the runtime =#
          outFuncHandle
        end

        function freeFunction(inFuncHandle::ModelicaInteger, inPrintDebug::Bool)
            #= Defined in the runtime =#
        end

        function freeLibrary(inLibHandle::ModelicaInteger, inPrintDebug::Bool)
            #= Defined in the runtime =#
        end

         #= This function will write to the file given by first argument the given string =#
        function writeFile(fileNameToWrite #= a filename where to write the data =#::String, stringToBeWritten #= the data =#::String)
            #= Defined in the runtime =#
        end

        function appendFile(file::String, data::String)
            #= Defined in the runtime =#
        end

         #= Does not fail. Returns strings describing the error instead. =#
        function readFile(inString::String)::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function systemCall(command::String, outFile #= empty file means no redirection unless it is part of the command =#::String)::ModelicaInteger
              local outInteger::ModelicaInteger

            #= Defined in the runtime =#
          outInteger
        end

         #= Run the command and return the stdout as a string =#
        function popen(command::String)::Tuple{ModelicaInteger, String}
              local status::ModelicaInteger
              local contents::String

            #= Defined in the runtime =#
          (status, contents)
        end

        function systemCallParallel(inStrings::List, numThreads::ModelicaInteger)::List
              local outIntegers::List

            #= Defined in the runtime =#
          outIntegers
        end

        function spawnCall(path #= The absolute path to the executable =#::String, str #= The list of arguments with executable =#::String)::ModelicaInteger
              local outInteger::ModelicaInteger

            #= Defined in the runtime =#
          outInteger
        end

        function plotCallBackDefined()::Bool
              local outBoolean::Bool

            #= Defined in the runtime =#
          outBoolean
        end

        function plotCallBack(externalWindow::Bool, filename::String, title::String, grid::String, plotType::String, logX::String, logY::String, xLabel::String, yLabel::String, x1::String, x2::String, y1::String, y2::String, curveWidth::String, curveStyle::String, legendPosition::String, footer::String, autoScale::String, variables::String)
            #= Defined in the runtime =#
        end

        function cd(inString::String)::ModelicaInteger
              local outInteger::ModelicaInteger

            #= Defined in the runtime =#
          outInteger
        end

        function createDirectory(inString::String)::Bool
              local outBool::Bool

            #= Defined in the runtime =#
          outBool
        end

        function createTemporaryDirectory(inPrefix::String)::String
              local outName::String

            #= Defined in the runtime =#
          outName
        end

        function pwd()::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

         #= Reads the environment variable given as string, fails if variable not found =#
        function readEnv(inString::String)::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

         #=  =#
        function setEnv(varName::String, value::String, overwrite #= is always true on Windows, so recommended to always call it using true =#::Bool)::ModelicaInteger
              local outInteger::ModelicaInteger

            #= Defined in the runtime =#
          outInteger
        end

        function subDirectories(inString::String)::List
              local outStringLst::List

            #= Defined in the runtime =#
          outStringLst
        end

        function moFiles(inString::String)::List
              local outStringLst::List

            #= Defined in the runtime =#
          outStringLst
        end

        function mocFiles(inString::String)::List
              local outStringLst::List

            #= Defined in the runtime =#
          outStringLst
        end

        function getLoadModelPath(className::String, prios::List, mps::List, requireExactVersion::Bool)::Tuple{Bool, String, String}
              local isDir::Bool
              local name::String
              local dir::String

            #= Defined in the runtime =#
          (isDir, name, dir)
        end

        function time()::ModelicaReal
              local outReal::ModelicaReal

            #= Defined in the runtime =#
          outReal
        end

        function regularFileExists(inString::String)::Bool
              local outBool::Bool

            #= Defined in the runtime =#
          outBool
        end

         #= Removes a file, returns 0 if suceeds, implemented using remove() in stdio.h =#
        function removeFile(fileName::String)::ModelicaInteger
              local res::ModelicaInteger

            #= Defined in the runtime =#
          res
        end

        function directoryExists(inString::String)::Bool
              local outBool::Bool

            #= Defined in the runtime =#
          outBool
        end

        function copyFile(source::String, destination::String)::Bool
              local outBool::Bool

            #= Defined in the runtime =#
          outBool
        end

        function removeDirectory(inString::String)::Bool
              local outBool::Bool

              outBool = System.removeDirectory_dispatch(inString)
               #=  oh Windows crap: stat fails on very long paths!
               =#
              if ! outBool
                if Autoconf.os == "Windows_NT"
                  outBool = 0 == System.systemCall("rm -r " + inString)
                end
              end
               #=  try rm as that somehow works on long paths
               =#
          outBool
        end

        function removeDirectory_dispatch(inString::String)::Bool
              local outBool::Bool

            #= Defined in the runtime =#
          outBool
        end

        function getClassnamesForSimulation()::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function setClassnamesForSimulation(inString::String)
            #= Defined in the runtime =#
        end

        function getVariableValue(timeStamp::ModelicaReal, timeValues::List, varValues::List)::ModelicaReal
              local outValue::ModelicaReal

            #= Defined in the runtime =#
          outValue
        end

         #= @author adrpo
         this system function returns the modification time of a file as a
         SOME(Real) which represents the time elapsed since the
         Epoch (00:00:00 UTC, January 1, 1970).
         If the file does not exist or if there is an error the returned value
         will be NONE.
         =#
        function getFileModificationTime(fileName::String)::Option
              local outValue::Option

            #= Defined in the runtime =#
          outValue
        end

         #= @author adrpo
         this system function returns current time elapsed
         since the Epoch (00:00:00 UTC, January 1, 1970). =#
        function getCurrentTime()::ModelicaReal
              local outValue::ModelicaReal

            #= Defined in the runtime =#
          outValue
        end

         #= @author Frenkel TUD
         this system function returns current time elapsed
         since the Epoch (00:00:00 UTC, January 1, 1970). =#
        function getCurrentDateTime()::Tuple{ModelicaInteger, ModelicaInteger, ModelicaInteger, ModelicaInteger, ModelicaInteger, ModelicaInteger}
              local year::ModelicaInteger
              local mon::ModelicaInteger
              local mday::ModelicaInteger
              local hour::ModelicaInteger
              local min::ModelicaInteger
              local sec::ModelicaInteger

            #= Defined in the runtime =#
          (year, mon, mday, hour, min, sec)
        end

         #=
        returns current time in format Www Mmm dd hh:mm:ss yyyy
        using the asctime() function in time.h (libc)
         =#
        function getCurrentTimeStr()::String
              local timeStr::String

            #= Defined in the runtime =#
          timeStr
        end

        function readFileNoNumeric(inString::String)::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

         #= @author: adrpo
         sets the external flag that signals the
         presence of expandable connectors in a model =#
        function setHasExpandableConnectors(hasExpandable::Bool)
            #= Defined in the runtime =#
        end

         #= @author: adrpo
         retrieves the external flag that signals the
         presence of expandable connectors in a model =#
        function getHasExpandableConnectors()::Bool
              local hasExpandable::Bool

            #= Defined in the runtime =#
          hasExpandable
        end

         #= @author: adrpo
         sets the external flag that signals the
         presence of overconstrained connectors in a model =#
        function setHasOverconstrainedConnectors(hasOverconstrained::Bool)
            #= Defined in the runtime =#
        end

         #= @author: adrpo
         retrieves the external flag that signals the
         presence of overconstrained connectors in a model =#
        function getHasOverconstrainedConnectors()::Bool
              local hasOverconstrained::Bool

            #= Defined in the runtime =#
          hasOverconstrained
        end

         #= @author: adrpo
         sets the external flag that signals the
         presence of expandable connectors in a model =#
        function setPartialInstantiation(isPartialInstantiation::Bool)
            #= Defined in the runtime =#
        end

         #= @author: adrpo
         retrieves the external flag that signals the
         presence of expandable connectors in a model =#
        function getPartialInstantiation()::Bool
              local isPartialInstantiation::Bool

            #= Defined in the runtime =#
          isPartialInstantiation
        end

         #= @author: adrpo
         sets the external flag that signals the
         presence of stream connectors in a model =#
        function setHasStreamConnectors(hasStream::Bool)
            #= Defined in the runtime =#
        end

         #= @author: adrpo
         retrieves the external flag that signals the
         presence of stream connectors in a model =#
        function getHasStreamConnectors()::Bool
              local hasStream::Bool

            #= Defined in the runtime =#
          hasStream
        end

         #= Sets the external flag that signals the use of the cardinality operator. =#
        function setUsesCardinality(inUses::Bool)
            #= Defined in the runtime =#
        end

         #= Retrieves the external flag that signals the use of the cardinality operator. =#
        function getUsesCardinality()::Bool
              local outUses::Bool

            #= Defined in the runtime =#
          outUses
        end

         #= @author: adrpo
         sets the external flag that signals the presence
         of inner/outer comoponent definitions in a model =#
        function setHasInnerOuterDefinitions(hasInnerOuterDefinitions::Bool)
            #= Defined in the runtime =#
        end

         #= @author: adrpo
         retrieves the external flag that signals the presence
         of inner/outer comoponent definitions in a model =#
        function getHasInnerOuterDefinitions()::Bool
              local hasInnerOuterDefinitions::Bool

            #= Defined in the runtime =#
          hasInnerOuterDefinitions
        end

         #= returns a tick that can be reset =#
        function tmpTick()::ModelicaInteger
              local tickNo::ModelicaInteger

              tickNo = tmpTickIndex(index = 0)
          tickNo
        end

         #= resets the tick so it restarts on start =#
        function tmpTickReset(start::ModelicaInteger)
            #= Defined in the runtime =#
        end

         #= returns a tick that can be reset. TODO: remove me when bootstrapped (default argument index=0) =#
        function tmpTickIndex(index::ModelicaInteger)::ModelicaInteger
              local tickNo::ModelicaInteger

            #= Defined in the runtime =#
          tickNo
        end

         #= returns a tick that can be reset and reserves N values in it.
           TODO: remove me when bootstrapped (default argument index=0) =#
        function tmpTickIndexReserve(index::ModelicaInteger, reserve #= current tick + reserve =#::ModelicaInteger)::ModelicaInteger
              local tickNo::ModelicaInteger

            #= Defined in the runtime =#
          tickNo
        end

         #= resets the tick so it restarts on start. TODO: remove me when bootstrapped (default argument index=0) =#
        function tmpTickResetIndex(start::ModelicaInteger, index::ModelicaInteger)
            #= Defined in the runtime =#
        end

         #= sets the index, like tmpTickResetIndex, but does not reset the maximum counter =#
        function tmpTickSetIndex(start::ModelicaInteger, index::ModelicaInteger)
            #= Defined in the runtime =#
        end

         #= returns the max tick since the last reset =#
        function tmpTickMaximum(index::ModelicaInteger)::ModelicaInteger
              local maxIndex::ModelicaInteger

            #= Defined in the runtime =#
          maxIndex
        end

         #= Returns true if the current user is root.
        Used by main to disable running omc as root as it is very dangerous.
        Consider opening a socket and letting anyone run system() commands without authentication. As root. =#
        function userIsRoot()::Bool
              local isRoot::Bool

            #= Defined in the runtime =#
          isRoot
        end

        function getuid()::ModelicaInteger
              local uid::ModelicaInteger

            #= Defined in the runtime =#
          uid
        end

         #= Tock returns the time since the last tock; undefined if tick was never called.
        The clock index is 0-31. The function fails if the number is out of range. =#
        function realtimeTick(clockIndex::ModelicaInteger)
            #= Defined in the runtime =#
        end

         #= Tock returns the time since the last tock, undefined if tick was never called.
        The clock index is 0-31. The function fails if the number is out of range. =#
        function realtimeTock(clockIndex::ModelicaInteger)::ModelicaReal
              local outTime::ModelicaReal

            #= Defined in the runtime =#
          outTime
        end

         #= Clears the timer.
        The clock index is 0-31. The function fails if the number is out of range. =#
        function realtimeClear(clockIndex::ModelicaInteger)
            #= Defined in the runtime =#
        end

         #= Returns the number of ticks since last clear.
        The clock index is 0-31. The function fails if the number is out of range. =#
        function realtimeNtick(clockIndex::ModelicaInteger)::ModelicaInteger
              local n::ModelicaInteger

            #= Defined in the runtime =#
          n
        end

         #= @autor: adrpo
          this function will reset the timer to 0. =#
        function resetTimer()
            #= Defined in the runtime =#
        end

         #= @autor: adrpo
          this function will start counting the time
          that should be aggregated. =#
        function startTimer()
            #= Defined in the runtime =#
        end

         #= @autor: adrpo
          this function will stop counting the time
          that should be aggregated. =#
        function stopTimer()
            #= Defined in the runtime =#
        end

         #= @autor: adrpo
          this function will return the time that
          passed between the last [startTimer,stopTimer] interval.
          Notice that if start/stop are called recursively this
          function will return the time passed between the
          corresponding intervals.
          Example:
          (start1,
            (start2,
              (start3, stop3) call getTimerIntervalTime -> (stop3-start3)
             stop2) call getTimerIntervalTime -> (stop2-start2)
           stop1)  call getTimerIntervalTime -> (stop1-start1) =#
        function getTimerIntervalTime()::ModelicaReal
              local timerIntervalTime::ModelicaReal

            #= Defined in the runtime =#
          timerIntervalTime
        end

         #= @autor: adrpo
          this function will return the cummulated time
          by adding all the interval times [startTimer,stopTimer].
          Note that if you have recursive calls to start/stop
          this function will not return the *correct* time.
          Example:
           Recursive:
             (start1, (start2, (start3, stop3) stop2) stop1)
             getTimerCummulatedTime =
               stop3-start3 + stop2-start2 + stop1-start1.
           Serial:
             (start1, stop1) (start2, stop2) (start3, stop3)
             getTimerCummulatedTime =
               stop3-start3 + stop2-start2 + stop1-start1. =#
        function getTimerCummulatedTime()::ModelicaReal
              local timerCummulatedTime::ModelicaReal

            #= Defined in the runtime =#
          timerCummulatedTime
        end

         #= @autor: adrpo
          this function will return the time
          passed since the first call to startTimeer
          Example:
            (start1, (start2, (start3, stop3), stop2) ...
            getTimerSinceFirstStartTime = timeNow-start1. =#
        function getTimerElapsedTime()::ModelicaReal
              local timerElapsedTime::ModelicaReal

            #= Defined in the runtime =#
          timerElapsedTime
        end

         #= @autor: adrpo
          this function will return number of
          times start/stop was called recursively.
          You can use this function for pretty printing.
          Example:
             index 0
            (start1, index 1
               (start2, index 2
                  (start3, index 3
                   stop3), index 2
                stop2) index 1
             stop1) index 0 =#
        function getTimerStackIndex()::ModelicaInteger
              local stackIndex::ModelicaInteger

            #= Defined in the runtime =#
          stackIndex
        end

         #= creates the Globally Unique IDentifier and return it as String =#
        function getUUIDStr()::String
              local uuidStr::String

            #= Defined in the runtime =#
          uuidStr
        end

         #= Returns the name of the file without any leading directory path.
        See man 3 basename. =#
        function basename(filename::String)::String
              local base::String

            #= Defined in the runtime =#
          base
        end

         #= Returns the name of the file without any leading directory path.
        See man 3 dirname. =#
        function dirname(filename::String)::String
              local base::String

            #= Defined in the runtime =#
          base
        end

         #= Because list() requires escape-sequences to be in the AST, we need to be
        able to unescape them in some places of the code. =#
        function escapedString(unescapedString::String, unescapeNewline::Bool)::String
          unescapedString
        end

         #= Because list() requires escape-sequences to be in the AST, we need to be
        able to unescape them in some places of the code. =#
        function unescapedString(escapedString::String)::String
              local unescapedString::String
          escapedString
        end

         #= Calculates the C string length of the input, if the input was used as a string
        literal in C. For example unescapedStringLength('\\\"')=1, unescapedStringLength('ab')=2. =#
        function unescapedStringLength(unescapedString::String)::ModelicaInteger
              local length::ModelicaInteger

            #= Defined in the runtime =#
          length
        end

         #= Quoted identifiers, for example 'xyz' need to be translated into canonical form; for example _omcQuot_0x2778797A27 =#
        function unquoteIdentifier(str::String)::String
              local outStr::String

            #= Defined in the runtime =#
          outStr
        end

         #= Forced quoted identifiers, for example xyz is translated into canonical form; for example _omcQuot_0x78797A =#
        function forceQuotedIdentifier(str::String)::String
              local outStr::String

            #= Defined in the runtime =#
          outStr
        end

         #= Returns the maximum integer that can be represent using this version of the compiler =#
        function intMaxLit()::ModelicaInteger
              local outInt::ModelicaInteger

            #= Defined in the runtime =#
          outInt
        end

         #= Returns the maximum integer that can be represent using this version of the compiler =#
        function realMaxLit()::ModelicaReal
              local outReal::ModelicaReal

            #= Defined in the runtime =#
          outReal
        end

         #= Handles modelica: and file: URI's. The result is an absolute path on the local system.
          The result depends on the current MODELICAPATH. Sets the error buffer on failure. =#
        function uriToClassAndPath(uri::String)::Tuple{String, String, String}
              local pathname::String
              local classname::String #= empty if file: is used =#
              local scheme::String #= file: or modelica:, in lower-case =#

            #= Defined in the runtime =#
          (pathname, classname #= empty if file: is used =#, scheme #= file: or modelica:, in lower-case =#)
        end

         #= Returns the standardized platform name according to the Modelica specification:
          win32 [Microsoft Windows 32 bit]
          win64 [Microsoft Windows 64 bit]
          i386-pc-linux [Linux Intel 32 bit]
          x64_86-linux  [Linux Intel 64 bit]
          Else, the openModelicaPlatform() is returned
           =#
        function modelicaPlatform()::String
              local platform::String

            #= Defined in the runtime =#
          platform
        end

         #=
          Returns uname -sm (with spaces replaced by dashes and only lower-case letters) on Unix platforms
          mingw32 or mingw64 is returned for OMDev mingw
           =#
        function openModelicaPlatform()::String
              local platform::String

            #= Defined in the runtime =#
          platform
        end

         #=
          Returns gcc -dumpmachine
           =#
        function gccDumpMachine()::String
              local machine::String

            #= Defined in the runtime =#
          machine
        end

         #=
          Returns gcc --version
           =#
        function gccVersion()::String
              local version::String

            #= Defined in the runtime =#
          version
        end

         #= # dgesv from LAPACK

          ## Purpose
          DGESV computes the solution to a real system of linear equations
            A * X = B,
          where A is an N-by-N matrix and X and B are N-by-NRHS matrices.

          The LU decomposition with partial pivoting and row interchanges is
          used to factor A as
            A = P * L * U,
          where P is a permutation matrix, L is unit lower triangular, and U is
          upper triangular. The factored form of A is then used to solve the
          system of equations A * X = B.

          ## Return values
          ### output list<Real> X
          On exit, if info = 0, the N-by-NRHS solution matrix X.

          ### output Integer info
          = 0:  successful exit
          < 0:  if INFO = -i, the i-th argument had an illegal value
          > 0:  if INFO = i, U(i,i) is exactly zero. The factorization
                has been completed, but the factor U is exactly
                singular, so the solution could not be computed.
           =#
        function dgesv(A::List, B::List)::Tuple{ModelicaInteger, List}
              local info::ModelicaInteger
              local X::List

            #= Defined in the runtime =#
          (info, X)
        end

         #= lpsolve55 =#
        function lpsolve55(A::List, B::List, intIndices::List)::Tuple{ModelicaInteger, List}
              local info::ModelicaInteger
              local X::List

            #= Defined in the runtime =#
          (info, X)
        end

        function reopenStandardStream(_stream #= stdin,stdout,stderr =#::ModelicaInteger, filename::String)::Bool
              local success::Bool

            #= Defined in the runtime =#
          success
        end

         #= The iconv() function converts one multibyte characters from one character
          set to another.
          See man (3) iconv for more information.
         =#
        function iconv(string::String, from::String, to::String)::String
              local result::String

            #= Defined in the runtime =#
          result
        end

         #= /* Print errors */ =#

         #= sprintf format string that takes one double as argument =#
        function snprintff(format::String, maxlen::ModelicaInteger, val::ModelicaReal)::String
              local str::String

            #= Defined in the runtime =#
          str
        end

         #= sprintf format string that takes one double as argument, but unlike snprintff
           it takes no buffer size as argument.

           NOTE: This function doesn't actually call sprintf, since that would be unsafe.
                 It instead calls snprintf with a fixed buffer size that should be enough
                 for most cases, and if that fails it resizes the buffer to the size
                 snprintf said it needed and calls snprintf again. =#
        function sprintff(format::String, val::ModelicaReal)::String
              local str::String

            #= Defined in the runtime =#
          str
        end

         #= Returns a value in the intervals (0,1] =#
        function realRand()::ModelicaReal
              local r::ModelicaReal

            #= Defined in the runtime =#
          r
        end

         #= Returns a integer value in the interval (0,n].
          The number of possible values is n, the maximum value n-1. =#
        function intRand(n::ModelicaInteger)::ModelicaInteger
              local i::ModelicaInteger

              i = integer(realRand() * n)
          i
        end

         #= Returns a value in the interval [0,n) =#
        function intRandom(n::ModelicaInteger)::ModelicaInteger
              local ret::ModelicaInteger

              ret = intMod(intRandom0(), n)
          ret
        end

         #= Returns a value in the intervals [0,RAND_MAX) using the C method rand(). =#
        function intRandom0()::ModelicaInteger
              local ret::ModelicaInteger

            #= Defined in the runtime =#
          ret
        end

         #= Choose a locale for subsequent gettext calls. Prints warnings on failures. =#
        function gettextInit(locale #= Empty string choses automatically from the environment =#::String)
            #= Defined in the runtime =#
        end

         #= Translate a string from msgid to msgstr using the language of the chosen locale =#
        function gettext(msgid::String)::String
              local msgstr::String

            #= Defined in the runtime =#
          msgstr
        end

         #= Takes any boxed input =#
        function anyStringCode(any::Any)::String
              local str::String

            #= Defined in the runtime =#
          str
        end

        function numBits()::ModelicaInteger
              local n::ModelicaInteger

            #= Defined in the runtime =#
          n
        end

        function realpath(path::String)::String
              local fullpath::String

            #= Defined in the runtime =#
          fullpath
        end

        function getSimulationHelpText(detailed::Bool, sphinx::Bool)::String
              local text::String

            #= Defined in the runtime =#
          text
        end

        function getTerminalWidth()::ModelicaInteger
              local width::ModelicaInteger

            #= Defined in the runtime =#
          width
        end

        function fileIsNewerThan(file1::String, file2::String)::Bool
              local result::Bool

            #= Defined in the runtime =#
          result
        end

        function fileContentsEqual(file1::String, file2::String)::Bool
              local result::Bool

            #= Defined in the runtime =#
          result
        end

        function rename(source::String, dest::String)::Bool
              local result::Bool

            #= Defined in the runtime =#
          result
        end

        function numProcessors()::ModelicaInteger
              local result::ModelicaInteger

            #= Defined in the runtime =#
          result
        end

         #= Takes a list of inputs and produces a list of Boolean (true if the function call was successful). The function is called by not using forks (experimental version using threads because fork doesn't play nice). Only returns if all functions return. =#
        function launchParallelTasks(numThreads::ModelicaInteger, inData::List, func::ForkFunction)::List
              local result::List

            #= Defined in the runtime =#
          result
        end

         #= Exits the compiler at this point with the given exit status. =#
        function exit(status::ModelicaInteger)
            #= Defined in the runtime =#
        end

         #= Exits the current thread with a failure. =#
        function threadWorkFailed()
            #= Defined in the runtime =#
        end

        function getMemorySize()::ModelicaReal
              local memory::ModelicaReal(unit = "MB")

            #= Defined in the runtime =#
          memory
        end

         #= this needs to be called first in Main.mo =#
        function initGarbageCollector()
            #= Defined in the runtime =#
        end

        function ctime(t::ModelicaReal)::String
              local str::String

            #= Defined in the runtime =#
          str
        end

        function stat(filename::String)::Tuple{ModelicaReal, ModelicaReal, Bool}
              local st_mtime::ModelicaReal
              local st_size::ModelicaReal
              local success::Bool

            #= Defined in the runtime =#
          (st_mtime, st_size, success)
        end

        function alarm(seconds::ModelicaInteger)::ModelicaInteger
              local previousAlarm::ModelicaInteger

            #= Defined in the runtime =#
          previousAlarm
        end

        function covertTextFileToCLiteral(textFile::String, outFile::String, target #= this would be what is set for +target=msvc|gcc =#::String)::Bool
              local success::Bool

            #= Defined in the runtime =#
          success
        end

T = Any
        function dladdr(symbol::T)::Tuple{String, String, String}
          local name::String
          local file::String
          local info::String

          file, name = _dladdr(symbol)
          info = file + ": " + name
              function _dladdr(symbol::Any)::Tuple{String, String}
                T = Any
                local name::String
                local file::String

                #= Defined in the runtime =#
                (name, file)
              end
          (name, file, info)
        end

        function stringAllocatorStringCopy(dest::StringAllocator, source::String, destOffset::ModelicaInteger)
            #= Defined in the runtime =#
        end

        function stringAllocatorResult(sa::StringAllocator, dummy #= This is just added so we do not make an extra allocation for the string =# #= annotation(
          __OpenModelica_UnusedVariable = true) =#::T)::T
          T = Any
              local res::T

            #= Defined in the runtime =#
          res
        end

        function relocateFunctions(fileName #= shared object =#::String, names #= tuple of names to relocate; first is the local name and second is the name in the shared object =#::List)::Bool
              local res::Bool

            #= Defined in the runtime =#
          res
        end

        function fflush()
            #= Defined in the runtime =#
        end

        function updateUriMapping(namesAndDirs::Array)
            #= Defined in the runtime =#
        end

        function getSizeOfData(data::T)::Tuple{ModelicaReal, ModelicaReal, ModelicaReal}
          T = Any
              local nonSharedStringSize::ModelicaReal #= The size that could be saved if String sharing was enabled =#
              local raw_sz::ModelicaReal #= The size without granule overhead =#
              local sz::ModelicaReal

            #= Defined in the runtime =#
          (nonSharedStringSize #= The size that could be saved if String sharing was enabled =#, raw_sz #= The size without granule overhead =#, sz)
        end

  end
