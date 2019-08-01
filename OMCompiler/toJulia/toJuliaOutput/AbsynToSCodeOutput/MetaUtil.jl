  module MetaUtil


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
        import SCode

        import Config
        import Error
        import MetaModelica.ListUtil
        import MetaModelica.Dangerous

         #= This function goes through a program and changes all records inside of
           uniontype into metarecords. It also makes a copy of them outside of the
           uniontype where they are found so that they can be used without prefixing
           with the uniontype name. =#
        function createMetaClassesInProgram(inProgram::Absyn.Program)::Absyn.Program
              local outProgram::Absyn.Program = inProgram

              local classes::List{Absyn.Class} = nil()
              local meta_classes::List{Absyn.Class}

              if ! Config.acceptMetaModelicaGrammar()
                return outProgram
              end
              _ = begin
                @match outProgram begin
                  Absyn.PROGRAM(__)  => begin
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
        function createMetaClasses(inClass::Absyn.Class)::Tuple{Absyn.Class, List{Absyn.Class}}
              local outMetaClasses::List{Absyn.Class} = nil()
              local outClass::Absyn.Class = inClass

              local body::Absyn.ClassDef
              local parts::List{Absyn.ClassPart}

              _ = begin
                  local typeVars::List{String}
                @match outClass begin
                  Absyn.CLASS(restriction = Absyn.R_UNIONTYPE(__), body = body && Absyn.PARTS(classParts = parts))  => begin
                      (parts, outMetaClasses) = fixClassParts(parts, outClass.name, body.typeVars)
                      body.classParts = parts
                      outClass.body = body
                    ()
                  end

                  Absyn.CLASS(restriction = Absyn.R_UNIONTYPE(__), body = body && Absyn.CLASS_EXTENDS(parts = parts))  => begin
                      (parts, outMetaClasses) = fixClassParts(parts, outClass.name, nil())
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
                  Absyn.CLASS(body = body && Absyn.PARTS(__))  => begin
                      body.classParts = createMetaClassesFromClassParts(body.classParts)
                      outClass.body = body
                    ()
                  end

                  Absyn.CLASS(body = body && Absyn.CLASS_EXTENDS(__))  => begin
                      body.parts = createMetaClassesFromClassParts(body.parts)
                      outClass.body = body
                    ()
                  end

                  _  => begin
                      ()
                  end
                end
              end
          (outClass, outMetaClasses)
        end

        function createMetaClassesFromClassParts(inClassParts::Union{List{<:Absyn.ClassPart}, Nil{Any}})::List{Absyn.ClassPart}
              local outClassParts::List{Absyn.ClassPart}

              outClassParts = list(begin
                @match p begin
                  Absyn.PUBLIC(__)  => begin
                      p.contents = createMetaClassesFromElementItems(p.contents)
                    p
                  end

                  Absyn.PROTECTED(__)  => begin
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

        function createMetaClassesFromElementItems(inElementItems::Union{List{<:Absyn.ElementItem}, Nil{Any}})::List{Absyn.ElementItem}
              local outElementItems::List{Absyn.ElementItem} = nil()

              local cls::Absyn.Class
              local meta_classes::List{Absyn.Class}
              local els::List{Absyn.ElementItem}

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
                  Absyn.ELEMENTITEM(element = e && Absyn.ELEMENT(specification = es && Absyn.CLASSDEF(__)))  => begin
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

              @match Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = outClass))) = inElementItem
          outClass
        end

        function fixClassParts(inClassParts::Union{List{<:Absyn.ClassPart}, Nil{Any}}, inClassName::Absyn.Ident, typeVars::Union{List{<:String}, Nil{Any}})::Tuple{List{Absyn.ClassPart}, List{Absyn.Class}}
              local outMetaClasses::List{Absyn.Class} = nil()
              local outClassParts::List{Absyn.ClassPart}

              local meta_classes::List{Absyn.Class}
              local els::List{Absyn.ElementItem}

              outClassParts = list(begin
                @match p begin
                  Absyn.PUBLIC(__)  => begin
                      (els, meta_classes) = fixElementItems(p.contents, inClassName, typeVars)
                      p.contents = els
                      outMetaClasses = listAppend(meta_classes, outMetaClasses)
                    p
                  end

                  Absyn.PROTECTED(__)  => begin
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
          (outClassParts, outMetaClasses)
        end

        function fixElementItems(inElementItems::Union{List{<:Absyn.ElementItem}, Nil{Any}}, inName::String, typeVars::Union{List{<:String}, Nil{Any}})::Tuple{List{Absyn.ElementItem}, List{Absyn.Class}}
              local outMetaClasses::List{Absyn.Class} = nil()
              local outElementItems::List{Absyn.ElementItem}

              local index::ModelicaInteger = 0
              local singleton::Bool = sum(if AbsynUtil.isElementItem(e)
                    1
                  else
                    0
                  end for e in inElementItems) == 1
              local c::Absyn.Class
              local r::Absyn.Restriction

              outElementItems = list(begin
                  local body::Absyn.ClassDef
                @match e begin
                  Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = c && Absyn.CLASS(restriction = Absyn.R_RECORD(__)))))  => begin
                      body = c.body
                      _ = begin
                        @match body begin
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
          (outElementItems, outMetaClasses)
        end

        function transformArrayNodesToListNodes(inList::Union{List{<:Absyn.Exp}, Nil{Any}})::List{Absyn.Exp}
              local outList::List{Absyn.Exp}

              outList = list(begin
                @match e begin
                  Absyn.ARRAY( nil())  => begin
                    Absyn.LIST(nil())
                  end

                  Absyn.ARRAY(__)  => begin
                    Absyn.LIST(transformArrayNodesToListNodes(e.arrayExp))
                  end

                  _  => begin
                      e
                  end
                end
              end for e in inList)
          outList
        end

    #= So that we can use wildcard imports and named imports when they do occur. Not good Julia practice =#
    @exportAll()
  end