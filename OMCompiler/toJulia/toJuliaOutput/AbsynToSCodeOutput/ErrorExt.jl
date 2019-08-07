  module ErrorExt


    using MetaModelica
    #= ExportAll is not good practice but it makes it so that we do not have to write export after each function :( =#
    using ExportAll

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
         * THIS OSMC LICENSE (OSMC-PL) VERSION 1.2.
         * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
         * RECIPIENT'S ACCEPTANCE OF THE OSMC LICENSE OR THE GPL VERSION 3,
         * ACCORDING TO RECIPIENTS CHOICE.
         *
         * The OpenModelica software and the Open Source Modelica
         * Consortium (OSMC) License (OSMC-PL) are obtained
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
         * See the full OSMC License conditions for more details.
         *
         */ =#
        import Error

        function registerModelicaFormatError()
            #= Defined in the runtime =#
        end

        function addSourceMessage(id::Error.ErrorID, msg_type::Error.MessageType, msg_severity::Error.Severity, sline::ModelicaInteger, scol::ModelicaInteger, eline::ModelicaInteger, ecol::ModelicaInteger, read_only::Bool, filename::String, msg::String, tokens::List)
            #= Defined in the runtime =#
        end

        function printMessagesStr(warningsAsErrors::Bool = false)::String
          ""
        end

        function getNumMessages()::ModelicaInteger
          0
        end

        function getNumErrorMessages()::ModelicaInteger
          0
        end

        function getNumWarningMessages()::ModelicaInteger
          0
        end

        function getMessages()::List
          0
        end

        function clearMessages()
            #= Defined in the runtime =#
        end

         #= Used to rollback/delete checkpoints without considering the identifier. Used to reset the error messages after a stack overflow exception. =#
        function getNumCheckpoints()::ModelicaInteger
          0
        end

         #= Used to rollback/delete checkpoints without considering the identifier. Used to reset the error messages after a stack overflow exception. =#
        function rollbackNumCheckpoints(n::ModelicaInteger)
            #= Defined in the runtime =#
        end

         #= Used to rollback/delete checkpoints without considering the identifier. Used to reset the error messages after a stack overflow exception. =#
        function deleteNumCheckpoints(n::ModelicaInteger)
            #= Defined in the runtime =#
        end

         #= sets a checkpoint for the error messages, so error messages can be rolled back (i.e. deleted) up to this point
        A unique identifier for this checkpoint must be provided. It is checked when doing rollback or deletion =#
        function setCheckpoint(id::String #= uniqe identifier for the checkpoint (up to the programmer to guarantee uniqueness) =#)
            #= Defined in the runtime =#
        end

         #= deletes the checkpoint at the top of the stack without
        removing the error messages issued since that checkpoint.
        If the checkpoint id doesn't match, the application exits with -1.
         =#
        function delCheckpoint(id::String #= unique identifier =#)
            #= Defined in the runtime =#
        end

        function printErrorsNoWarning()::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

         #= rolls back error messages until the latest checkpoint,
        deleting all error messages added since that point in time. A unique identifier for the checkpoint must be provided
        The application will exit with return code -1 if this identifier does not match. =#
        function rollBack(id::String #= unique identifier =#)
            #= Defined in the runtime =#
        end

         #= rolls back error messages until the latest checkpoint,
        returning all error messages added since that point in time. A unique identifier for the checkpoint must be provided
        The application will exit with return code -1 if this identifier does not match. =#
        function popCheckPoint(id::String #= unique identifier =#)::List
              local handles::List #= opaque pointers; you MUST pass them back or memory is leaked =#

            #= Defined in the runtime =#
          handles #= opaque pointers; you MUST pass them back or memory is leaked =#
        end

         #= Pushes stored pointers back to the error stack. =#
        function pushMessages(handles::List #= opaque pointers from popCheckPoint =#)
            #= Defined in the runtime =#
        end

         #= Pushes stored pointers back to the error stack. =#
        function freeMessages(handles::List #= opaque pointers from popCheckPoint =#)
            #= Defined in the runtime =#
        end

         #= @author: adrpo
          This function checks if the specified checkpoint exists AT THE TOP OF THE STACK!.
          You can use it to rollBack/delete a checkpoint, but you're
          not sure that it exists (due to MetaModelica backtracking). =#
        function isTopCheckpoint(id::String #= unique identifier =#)::Bool
          false
        end

        function setShowErrorMessages(inShow::Bool)
            #= Defined in the runtime =#
        end

        function moveMessagesToParentThread()
            #= Defined in the runtime =#
        end

         #= Makes assert() and other runtime assertions print to the error buffer =#
        function initAssertionFunctions()
            #= Defined in the runtime =#
        end

    #= So that we can use wildcard imports and named imports when they do occur. Not good Julia practice =#
    @exportAll()
  end
