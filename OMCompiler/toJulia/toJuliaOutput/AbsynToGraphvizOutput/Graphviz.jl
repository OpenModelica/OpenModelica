  module Graphviz


    using MetaModelica
    #= ExportAll is not good practice but it makes it so that we do not have to write export after each function :( =#
    using ExportAll
    #= Necessary to write declarations for your uniontypes until Julia adds support for mutually recursive types =#

    @UniontypeDecl Attribute
    @UniontypeDecl Node

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
        Type = String
        Ident = String
        Label = String

          #= an Attribute is a pair of name an value. =#
         @Uniontype Attribute begin
              @Record ATTR begin

                       name #= name =#::String
                       value #= value =#::String
              end
         end

        Attributes = IList

          #= A graphviz Node is a node of the graph.
             It has a type and attributes and children.
             It can also have a list of labels, provided by the LNODE
             constructor. =#
         @Uniontype Node begin
              @Record NODE begin

                       type_::Type
                       attributes::Attributes
                       children::IList
              end

              @Record LNODE begin

                       type_::Type
                       labelLst::IList
                       attributes::Attributes
                       children::IList
              end
         end

        Children = IList
         box = ATTR("shape", "box")::Attribute

         #= Relations
          function: dump
          Dumps a Graphviz Node on stdout. =#
        function dump(node::Node)
              local nm::Label

              print("graph AST {\n")
              nm = dumpNode(node)
              print("}\n")
        end

         #= Dumps a node to a string. =#
        function dumpNode(inNode::Node)::Ident
              local outIdent::Ident

              outIdent = begin
                  local nm::Label
                  local typlbl::Label
                  local out::Label
                  local typ::Label
                  local lblstr::Label
                  local newattr::Attributes
                  local attr::Attributes
                  local children::Children
                  local lbl_1::IList
                  local lbl::IList
                @match inNode begin
                  NODE(type_ = typ, attributes = attr, children = children)  => begin
                      nm = nodename(typ)
                      typlbl = makeLabel(list(typ))
                      newattr = ATTR("label", typlbl) <| attr
                      out = makeNode(nm, newattr)
                      print(out)
                      dumpChildren(nm, children)
                    nm
                  end

                  LNODE(type_ = typ, labelLst = lbl, attributes = attr, children = children)  => begin
                      nm = nodename(typ)
                      lbl_1 = typ <| lbl
                      lblstr = makeLabel(lbl_1)
                      newattr = ATTR("label", lblstr) <| attr
                      out = makeNode(nm, newattr)
                      print(out)
                      dumpChildren(nm, children)
                    nm
                  end
                end
              end
          outIdent
        end

         #= Creates a label from a list of strings. =#
        function makeLabel(sl::IList)::String
              local s2::String

              local s0::Label
              local s1::Label

              s0 = makeLabelReq(sl, "")
              s1 = stringAppend("\"", s0)
              s2 = stringAppend(s1, "\"")
          s2
        end

         #= Helper function to makeLabel =#
        function makeLabelReq(inStringLst::IList, inString::String)::String
              local outString::String

              outString = begin
                  local s::Label
                  local s1::Label
                  local s2::Label
                  local rest::IList
                @match inStringLst begin
                  s <|  nil()  => begin
                    stringAppend(inString, s)
                  end

                  s1 <| s2 <|  nil()  => begin
                      s = stringAppend(inString, s1)
                      s = stringAppend(s, "\\n")
                      s = stringAppend(s, s2)
                    s
                  end

                  s1 <| rest  => begin
                      s = stringAppend(inString, s1)
                      s = stringAppend(s, "\\n")
                    makeLabelReq(rest, s)
                  end
                end
              end
          outString
        end

         #= Helper function to dumpNode =#
        function dumpChildren(inIdent::Ident, inChildren::Children)
              _ = begin
                  local nm::Label
                  local parent::Label
                  local node::Node
                  local rest::Children
                @match (inIdent, inChildren) begin
                  (_,  nil())  => begin
                    ()
                  end

                  (parent, node <| rest)  => begin
                      nm = dumpNode(node)
                      printEdge(nm, parent)
                      dumpChildren(parent, rest)
                    ()
                  end
                end
              end
        end

         #= Creates a unique node name,
          changed use of str as part of nodename, since it may contain spaces =#
        function nodename(str::String)::String
              local s::String

              local i::ModelicaInteger
              local is::Label

              i = tick()
              is = intString(i)
              s = stringAppend("GVNOD", is)
          s
        end

         #= Prints an edge between two nodes. =#
        function printEdge(n1::Ident, n2::Ident)
              local str::Label

              str = makeEdge(n1, n2)
              print(str)
              print(";\n")
        end

         #= Creates a string representing an edge between two nodes. =#
        function makeEdge(n1::Ident, n2::Ident)::String
              local str::String

              local s::Label

              s = stringAppend(n1, " -- ")
              str = stringAppend(s, n2)
          str
        end

         #= Creates string from a node. =#
        function makeNode(nm::Ident, attr::Attributes)::String
              local str::String

              local s::Label
              local s_1::Label

              s = makeAttr(attr)
              s_1 = stringAppend(nm, s)
              str = stringAppend(s_1, ";")
          str
        end

         #= Creates a string from an Attribute list. =#
        function makeAttr(l::IList)::String
              local str::String

              local res::Label
              local s::Label

              res = makeAttrReq(l, "")
              s = stringAppend("[", res)
              str = stringAppend(s, "]")
          str
        end

         #= Helper function to makeAttr. =#
        function makeAttrReq(inAttributeLst::IList, inString::String)::String
              local outString::String

              outString = begin
                  local s::Label
                  local name::Label
                  local v::Label
                  local rest::IList
                @match inAttributeLst begin
                  ATTR(name = name, value = v) <|  nil()  => begin
                      s = stringAppend(inString, name)
                      s = stringAppend(s, "=")
                    stringAppend(s, v)
                  end

                  ATTR(name = name, value = v) <| rest  => begin
                      s = stringAppend(inString, name)
                      s = stringAppend(s, "=")
                      s = stringAppend(s, v)
                      s = stringAppend(s, ",")
                    makeAttrReq(rest, s)
                  end
                end
              end
          outString
        end

    #=So that we can use wildcard imports and named imports when they do occur. Not good Julia practice=#
    @exportAll()
  end