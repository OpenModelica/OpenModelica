#= Automatically generated some dependencies removed=#
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
              local outProgram::Absyn.Program = inProgram

              local classes::List = list()
              local meta_classes::List

              if ! Config.acceptMetaModelicaGrammar()
                return outProgram
              end
              _ = begin
                @match outProgram begin
                  Absyn.PROGRAM()  => begin
                      for c in outProgram.classes
                        (c, meta_classes) = createMetaClasses(c)
                        classes = c <| listAppend(meta_classes, classes)
                      end
                      outProgram.classes = Dangerous.listReverseInPlace(classes)
                       #=  print(Dump.unparseStr(outProgram));
                       =#
                    ()
                  end

                  _  => begin
                      ()
                  end
                end
              end
          outProgram
        end

         #= Takes a class, and if it's a uniontype it converts all records inside it into
           metarecords and returns the updated uniontype and a list of all metarecords.
           It then recursively applies the same operation to all subclasses. =#
        function createMetaClasses(inClass::Absyn.Class)::Tuple{List, Absyn.Class}
              local outMetaClasses::List = list()
              local outClass::Absyn.Class = inClass

              local body::Absyn.ClassDef
              local parts::List

              _ = begin
                  local typeVars::List
                @match outClass begin
                  Absyn.CLASS(restriction = Absyn.R_UNIONTYPE(), body = body = Absyn.PARTS(classParts = parts))  => begin
                      (parts, outMetaClasses) = fixClassParts(parts, outClass.name, body.typeVars)
                      body.classParts = parts
                      outClass.body = body
                    ()
                  end

                  Absyn.CLASS(restriction = Absyn.R_UNIONTYPE(), body = body = Absyn.CLASS_EXTENDS(parts = parts))  => begin
                      (parts, outMetaClasses) = fixClassParts(parts, outClass.name, list())
                      body.parts = parts
                      outClass.body = body
                    ()
                  end

                  _  => begin
                      ()
                  end
                end
              end
              _ = begin
                @match outClass begin
                  Absyn.CLASS(body = body = Absyn.PARTS())  => begin
                      body.classParts = createMetaClassesFromClassParts(body.classParts)
                      outClass.body = body
                    ()
                  end

                  Absyn.CLASS(body = body = Absyn.CLASS_EXTENDS())  => begin
                      body.parts = createMetaClassesFromClassParts(body.parts)
                      outClass.body = body
                    ()
                  end

                  _  => begin
                      ()
                  end
                end
              end
          (outMetaClasses, outClass)
        end

        function createMetaClassesFromClassParts(inClassParts::List)::List
              local outClassParts::List

              outClassParts = list(begin
                @match p begin
                  Absyn.PUBLIC()  => begin
                      p.contents = createMetaClassesFromElementItems(p.contents)
                    p
                  end

                  Absyn.PROTECTED()  => begin
                      p.contents = createMetaClassesFromElementItems(p.contents)
                    p
                  end

                  _  => begin
                      p
                  end
                end
              end for p in inClassParts)
          outClassParts
        end

        function createMetaClassesFromElementItems(inElementItems::List)::List
              local outElementItems::List = list()

              local cls::Absyn.Class
              local meta_classes::List
              local els::List

              for e in listReverse(inElementItems)
                e = begin
                  @match e begin
                    Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = cls)))  => begin
                        (cls, meta_classes) = createMetaClasses(cls)
                        els = list(setElementItemClass(e, c) for c in meta_classes)
                        outElementItems = listAppend(els, outElementItems)
                      setElementItemClass(e, cls)
                    end

                    _  => begin
                        e
                    end
                  end
                end
                outElementItems = e <| outElementItems
              end
          outElementItems
        end

        function setElementItemClass(inElementItem::Absyn.ElementItem, inClass::Absyn.Class)::Absyn.ElementItem
              local outElementItem::Absyn.ElementItem = inElementItem

              outElementItem = begin
                  local e::Absyn.Element
                  local es::Absyn.ElementSpec
                @match outElementItem begin
                  Absyn.ELEMENTITEM(element = e = Absyn.ELEMENT(specification = es = Absyn.CLASSDEF()))  => begin
                      es.class_ = inClass
                      e.specification = es
                      outElementItem.element = e
                    outElementItem
                  end

                  _  => begin
                      outElementItem
                  end
                end
              end
          outElementItem
        end

        function convertElementToClass(inElementItem::Absyn.ElementItem)::Absyn.Class
              local outClass::Absyn.Class

              Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = outClass))) = inElementItem
          outClass
        end

        function fixClassParts(inClassParts::List, inClassName::Absyn.Ident, typeVars::List)::Tuple{List, List}
              local outMetaClasses::List = list()
              local outClassParts::List

              local meta_classes::List
              local els::List

              outClassParts = list(begin
                @match p begin
                  Absyn.PUBLIC()  => begin
                      (els, meta_classes) = fixElementItems(p.contents, inClassName, typeVars)
                      p.contents = els
                      outMetaClasses = listAppend(meta_classes, outMetaClasses)
                    p
                  end

                  Absyn.PROTECTED()  => begin
                      (els, meta_classes) = fixElementItems(p.contents, inClassName, typeVars)
                      p.contents = els
                      outMetaClasses = listAppend(meta_classes, outMetaClasses)
                    p
                  end

                  _  => begin
                      p
                  end
                end
              end for p in inClassParts)
          (outMetaClasses, outClassParts)
        end

        function fixElementItems(inElementItems::List, inName::String, typeVars::List)::Tuple{List, List}
              local outMetaClasses::List = list()
              local outElementItems::List

              local index::ModelicaInteger = 0
              local singleton::Bool = sum(if AbsynUtil.isElementItem(e)
                    1
                  else
                    0
                  end for e in inElementItems) == 1
              local c::Absyn.Class
              local r::Absyn.Restriction

              outElementItems = list(begin
                @match e begin
                  Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = c = Absyn.CLASS(restriction = Absyn.R_RECORD()))))  => begin
                      _ = begin
                        @match body = c.body begin
                          Absyn.PARTS(typeVars = _ <| _)  => begin
                              Error.addSourceMessage(Error.METARECORD_WITH_TYPEVARS, list(stringDelimitList(body.typeVars, ",")), c.info)
                            fail()
                          end

                          _  => begin
                              ()
                          end
                        end
                      end
                       #=  Change the record into a metarecord and add it to the list of metaclasses.
                       =#
                      r = Absyn.R_METARECORD(Absyn.IDENT(inName), index, singleton, true, typeVars)
                      c.restriction = r
                      outMetaClasses = c <| outMetaClasses
                       #=  Change the record into a metarecord and update the original class.
                       =#
                      r = Absyn.R_METARECORD(Absyn.IDENT(inName), index, singleton, false, typeVars)
                      c.restriction = r
                      index = index + 1
                    setElementItemClass(e, c)
                  end

                  _  => begin
                      e
                  end
                end
              end for e in inElementItems)
          (outMetaClasses, outElementItems)
        end
  end
