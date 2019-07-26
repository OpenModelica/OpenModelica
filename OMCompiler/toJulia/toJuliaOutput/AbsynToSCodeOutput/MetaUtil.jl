#= Automatically generated most things removed=#
module MetaUtil

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
        import Absyn
        import AbsynUtil
        import Config
        import Error
        import MetaModelica.Dangerous

         #= This function goes through a program and changes all records inside of
           uniontype into metarecords. It also makes a copy of them outside of the
           uniontype where they are found so that they can be used without prefixing
           with the uniontype name. =#
        function createMetaClassesInProgram(inProgram::Absyn.Program)::Absyn.Program
          #=TODO=#
          inProgram
        end

         #= Takes a class, and if it's a uniontype it converts all records inside it into
           metarecords and returns the updated uniontype and a list of all metarecords.
           It then recursively applies the same operation to all subclasses. =#
        function createMetaClasses(inClass::Absyn.Class)::Tuple{List, Absyn.Class}
          outClassParts
        end

        function createMetaClassesFromElementItems(inElementItems::List)::List
          outElementItems
        end

        function setElementItemClass(inElementItem::Absyn.ElementItem, inClass::Absyn.Class)::Absyn.ElementItem
          outElementItem
        end

        function convertElementToClass(inElementItem::Absyn.ElementItem)::Absyn.Class
              local outClass::Absyn.Class
          outClass
        end

        function fixClassParts(inClassParts::List, inClassName::Absyn.Ident, typeVars::List)::Tuple{List, List}
          list()
        end

        function fixElementItems(inElementItems::List, inName::String, typeVars::List)::Tuple{List, List}
          (outMetaClasses, outElementItems)
        end
  end
