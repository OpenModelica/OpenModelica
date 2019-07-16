  module Settings


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

         #= Returns the version number of this release =#
        function getVersionNr()::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function setCompilePath(inString::String)
            #= Defined in the runtime =#
        end

         #= /* TODO: Implement an external C function for bootstrapped omc or remove me. DO NOT SIMPLY REMOVE THIS COMMENT
        public function getCompilePath
          output String outString;

          external \"C\" outString=Settings_getCompilePath() annotation(Library = \"omcruntime\");
        end getCompilePath;*/ =#

        function setCompileCommand(inString::String)
            #= Defined in the runtime =#
        end

        function getCompileCommand()::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function setTempDirectoryPath(inString::String)
            #= Defined in the runtime =#
        end

        function getTempDirectoryPath()::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function setInstallationDirectoryPath(inString::String)
            #= Defined in the runtime =#
        end

        function getInstallationDirectoryPath()::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function setModelicaPath(inString::String)
            #= Defined in the runtime =#
        end

        function getModelicaPath(runningTestsuite::Bool)::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function getHomeDir(runningTestsuite::Bool)::String
              local outString::String

            #= Defined in the runtime =#
          outString
        end

        function getEcho()::ModelicaInteger
              local echo::ModelicaInteger

            #= Defined in the runtime =#
          echo
        end

        function setEcho(echo::ModelicaInteger)
            #= Defined in the runtime =#
        end

         #= /* TODO: Implement an external C function for bootstrapped omc or remove me. DO NOT SIMPLY REMOVE THIS COMMENT
        public function dumpSettings
          external \"C\" Settings_dumpSettings() annotation(Library = \"omcruntime\");
        end dumpSettings;*/ =#

  end