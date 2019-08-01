  module StackOverflow


    using MetaModelica

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

        import Config
        import System

        function unmangle(inSymbol::String)::String
              local outSymbol::String
              outSymbol = inSymbol
              if stringLength(inSymbol) > 4
                if substring(inSymbol, 1, 4) == "omc_"
                  outSymbol = substring(outSymbol, 5, stringLength(outSymbol))
                  outSymbol = System.stringReplace(outSymbol, "__", "#")
                  outSymbol = System.stringReplace(outSymbol, "_", ".")
                  outSymbol = System.stringReplace(outSymbol, "#", "_")
                end
              end
          outSymbol
        end

        function stripAddresses(inSymbol::String)::String
          nil()
        end

        function triggerStackOverflow()
            #= Defined in the runtime =#
        end

        function generateReadableMessage(numFrames::ModelicaInteger, numSkip::ModelicaInteger, delimiter::String)::String
          str
        end

        function getReadableMessage(delimiter::String)::String
              local str::String

              str = stringDelimitList(StackOverflow.readableStacktraceMessages(), delimiter)
          str
        end

        function readableStacktraceMessages()::List
          nil()
        end

        function getStacktraceMessages()::List
              local symbols::List

            #= Defined in the runtime =#
          symbols
        end

        function setStacktraceMessages(numSkip::ModelicaInteger, numFrames::ModelicaInteger)
            #= Defined in the runtime =#
        end

        function hasStacktraceMessages()::Bool
              local b::Bool

            #= Defined in the runtime =#
          b
        end

        function clearStacktraceMessages()
            #= Defined in the runtime =#
        end

  end
