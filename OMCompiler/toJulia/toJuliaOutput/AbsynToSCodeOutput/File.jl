#= Partly automatically generated=#
module File


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

abstract type SMode end;
struct Read <: SMode end;
struct Write <: SMode end;
Mode = SMode;
struct FILE #=I am a dummy=# end

struct None #= "No escape string", =# end
struct  C #= "Escapes C strings (minimally): \\n and \"", =# end
struct JSON #= "Escapes JSON strings (quotes and control characters)" =# end
struct XML #= "Escapes strings to XML text" =# end

struct Escape
  None #= "No escape string", =#
  C #= "Escapes C strings (minimally): \\n and \"", =#
  JSON #= "Escapes JSON strings (quotes and control characters)" =#
  XML #= "Escapes strings to XML text" =#
end;

        function open(file, filename::String, mode::Mode)
            #= Defined in the runtime =#
        end

        function write(file, data::String)
            #= Defined in the runtime =#
        end

        function writeInt(file, data::ModelicaInteger, format::String)
            #= Defined in the runtime =#
        end

        function writeReal(file, data::ModelicaReal, format::String)
            #= Defined in the runtime =#
        end



        function writeEscape(file, data::String, escape)
            #= Defined in the runtime =#
        end



        function seek(file, offset::ModelicaInteger, whence)::Bool
              local success::Bool

            #= Defined in the runtime =#
          success
        end

        function tell(file)::ModelicaInteger
              local pos::ModelicaInteger

            #= Defined in the runtime =#
          pos
        end

        function getFilename(file::Option)::String
              local fileName::String

            #= Defined in the runtime =#
          fileName
        end

         #= Returns NULL (an opaque pointer; not actually Option<Integer>) =#
        function noReference()::Option
              local reference::Option

            #= Defined in the runtime =#
          reference
        end

         #= Returns an opaque pointer (not actually Option<Integer>) =#
        function getReference(file)::Option
              local reference::Option

            #= Defined in the runtime =#
          reference
        end

        function releaseReference(file)
            #= Defined in the runtime =#
        end

        function writeSpace(file, n::ModelicaInteger)
              for i in 1:n
                File.write(file, " ")
              end
        end

  end
