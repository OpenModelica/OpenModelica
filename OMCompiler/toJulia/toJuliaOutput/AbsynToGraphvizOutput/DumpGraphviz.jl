  module DumpGraphviz


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

        import Graphviz

        import Dump

         #= Dumps a Program to a Graphviz graph. =#
        function dump(p::Absyn.Program)
              local r::Graphviz.Node

              r = buildGraphviz(p)
              Graphviz.dump(r)
        end

         #= Build the graphviz graph for a Program. =#
        function buildGraphviz(inProgram::Absyn.Program)::Graphviz.Node
              local outNode::Graphviz.Node

              outNode = begin
                  local nl::IList
                  local cs::IList
                @match inProgram begin
                  Absyn.PROGRAM(classes = cs)  => begin
                      nl = printClasses(cs)
                    Graphviz.NODE("ROOT", list(), nl)
                  end
                end
              end
          outNode
        end

         #= Creates Nodes from a Class list. =#
        function printClasses(inAbsynClassLst::IList)::IList
              local outNodeLst::IList

              outNodeLst = begin
                  local node::Graphviz.Node
                  local nl::IList
                  local c::Absyn.Class
                  local cs::IList
                @match inAbsynClassLst begin
                   nil()  => begin
                    list()
                  end

                  c <| cs  => begin
                      node = printClass(c)
                      nl = printClasses(cs)
                    node <| nl
                  end
                end
              end
          outNodeLst
        end

         #= Creates a Node for a Class. =#
        function printClass(inClass::Absyn.Class)::Graphviz.Node
              local outNode::Graphviz.Node

              outNode = begin
                  local rs::String
                  local n::String
                  local nl::IList
                  local p::Bool
                  local f::Bool
                  local e::Bool
                  local r::Absyn.Restriction
                  local parts::IList
                @match inClass begin
                  Absyn.CLASS(restriction = r, body = Absyn.PARTS(classParts = parts))  => begin
                      rs = AbsynUtil.restrString(r)
                      nl = printParts(parts)
                    Graphviz.NODE(rs, list(), nl)
                  end
                end
              end
          outNode
        end

         #= Creates a Node list from a ClassPart list. =#
        function printParts(inAbsynClassPartLst::IList)::IList
              local outNodeLst::IList

              outNodeLst = begin
                  local node::Graphviz.Node
                  local nl::IList
                  local c::Absyn.ClassPart
                  local cs::IList
                @match inAbsynClassPartLst begin
                   nil()  => begin
                    list()
                  end

                  c <| cs  => begin
                      node = printClassPart(c)
                      nl = printParts(cs)
                    node <| nl
                  end
                end
              end
          outNodeLst
        end

         #= Creates a Node from A ClassPart. =#
        function printClassPart(inClassPart::Absyn.ClassPart)::Graphviz.Node
              local outNode::Graphviz.Node

              outNode = begin
                  local nl::IList
                  local el::IList
                  local eqs::IList
                  local als::IList
                @matchcontinue inClassPart begin
                  Absyn.PUBLIC(contents = el)  => begin
                      nl = printElementitems(el)
                    Graphviz.NODE("PUBLIC", list(), nl)
                  end

                  Absyn.PROTECTED(contents = el)  => begin
                      nl = printElementitems(el)
                    Graphviz.NODE("PROTECTED", list(), nl)
                  end

                  Absyn.EQUATIONS(contents = eqs)  => begin
                      nl = printEquations(eqs)
                    Graphviz.NODE("EQUATIONS", list(), nl)
                  end

                  Absyn.ALGORITHMS(contents = als)  => begin
                      nl = printAlgorithms(als)
                    Graphviz.NODE("ALGORITHMS", list(), nl)
                  end

                  _  => begin
                      Graphviz.NODE(" DumpGraphViz.printClassPart PART_ERROR", list(), list())
                  end
                end
              end
          outNode
        end

         #= Creates a Node list from ElementItem list. =#
        function printElementitems(inAbsynElementItemLst::IList)::IList
              local outNodeLst::IList

              outNodeLst = begin
                  local nl::IList
                  local el::IList
                  local node::Graphviz.Node
                  local e::Absyn.Element
                @match inAbsynElementItemLst begin
                   nil()  => begin
                    list()
                  end

                  Absyn.ELEMENTITEM(element = e) <| el  => begin
                      node = printElement(e)
                      nl = printElementitems(el)
                    node <| nl
                  end
                end
              end
          outNodeLst
        end

         #= Create an Attribute from a bool value and a description string. =#
        function makeBoolAttr(str::String, flag::Bool)::Graphviz.Attribute
              local outAttribute::Graphviz.Attribute

              local s::String

              s = Dump.selectString(flag, "true", "false")
              outAttribute = Graphviz.ATTR(str, s)
          outAttribute
        end

         #= Create a leaf Node from a string an a list of attributes. =#
        function makeLeaf(str::String, al::IList)::Graphviz.Node
              local outNode::Graphviz.Node

              outNode = Graphviz.NODE(str, al, list())
          outNode
        end

         #= Create a Node from an Element. =#
        function printElement(inElement::Absyn.Element)::Graphviz.Node
              local outNode::Graphviz.Node

              outNode = begin
                  local fa::Graphviz.Attribute
                  local elsp::Graphviz.Node
                  local finalPrefix::Bool
                  local spec::Absyn.ElementSpec
                @match inElement begin
                  Absyn.ELEMENT(finalPrefix = finalPrefix, specification = spec)  => begin
                      fa = makeBoolAttr("final", finalPrefix)
                      elsp = printElementspec(spec)
                    Graphviz.NODE("ELEMENT", list(fa), list(elsp))
                  end
                end
              end
          outNode
        end

         #= Create a Node from a Path. =#
        function printPath(p::Absyn.Path)::Graphviz.Node
              local pn::Graphviz.Node

              local s::String

              s = AbsynUtil.pathString(p)
              pn = makeLeaf(s, list())
          pn
        end

         #= Create a Node from an ElementSpec =#
        function printElementspec(inElementSpec::Absyn.ElementSpec)::Graphviz.Node
              local outNode::Graphviz.Node

              outNode = begin
                  local nl::Graphviz.Node
                  local en::Graphviz.Node
                  local pn::Graphviz.Node
                  local ra::Graphviz.Attribute
                  local repl::Bool
                  local cl::Absyn.Class
                  local p::Absyn.Path
                  local l::IList
                  local cns::IList
                  local attr::Absyn.ElementAttributes
                  local tspec::Absyn.TypeSpec
                  local cs::IList
                  local s::String
                @matchcontinue inElementSpec begin
                  Absyn.CLASSDEF(replaceable_ = repl, class_ = cl)  => begin
                      _ = printClass(cl)
                      ra = makeBoolAttr("replaceable", repl)
                    Graphviz.NODE("CLASSDEF", list(ra), list())
                  end

                  Absyn.EXTENDS(path = p)  => begin
                      en = printPath(p)
                    Graphviz.NODE("EXTENDS", list(), list(en))
                  end

                  Absyn.COMPONENTS(typeSpec = tspec, components = cs)  => begin
                      s = Dump.unparseTypeSpec(tspec)
                      pn = makeLeaf(s, list())
                      cns = printComponents(cs)
                    Graphviz.NODE("COMPONENTS", list(), pn <| cns)
                  end

                  _  => begin
                      Graphviz.NODE(" DumpGraphviz.printElementspec ELSPEC_ERROR", list(), list())
                  end
                end
              end
          outNode
        end

         #= Create a Node list from a ComponentItem list. =#
        function printComponents(inAbsynComponentItemLst::IList)::IList
              local outNodeLst::IList

              outNodeLst = begin
                  local n::Graphviz.Node
                  local nl::IList
                  local c::Absyn.ComponentItem
                  local cs::IList
                @match inAbsynComponentItemLst begin
                   nil()  => begin
                    list()
                  end

                  c <| cs  => begin
                      n = printComponentitem(c)
                      nl = printComponents(cs)
                    n <| nl
                  end
                end
              end
          outNodeLst
        end

         #= Create a Node from a ComponentItem. =#
        function printComponentitem(inComponentItem::Absyn.ComponentItem)::Graphviz.Node
              local outNode::Graphviz.Node

              outNode = begin
                  local nn::Graphviz.Node
                  local n::String
                  local a::IList
                  local m::Option
                @match inComponentItem begin
                  Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = n))  => begin
                      nn = Graphviz.NODE(n, list(), list())
                    Graphviz.LNODE("COMPONENT", list(n), list(), list(nn))
                  end
                end
              end
          outNode
        end

         #= Create a Node list from an EquationItem list. =#
        function printEquations(inAbsynEquationItemLst::IList)::IList
              local outNodeLst::IList

              outNodeLst = begin
                  local node::Graphviz.Node
                  local nl::IList
                  local eq::Absyn.Equation
                  local ann::Option
                  local el::IList
                @match inAbsynEquationItemLst begin
                   nil()  => begin
                    list()
                  end

                  Absyn.EQUATIONITEM(equation_ = eq) <| el  => begin
                      node = printEquation(eq)
                      nl = printEquations(el)
                    node <| nl
                  end
                end
              end
          outNodeLst
        end

         #=  Create a Node from an Equation. =#
        function printEquation(inEquation::Absyn.Equation)::Graphviz.Node
              local outNode::Graphviz.Node

              outNode = begin
                  local s1::String
                  local s2::String
                  local s3::String
                  local s::String
                  local s_1::String
                  local s_2::String
                  local es::String
                  local e1::Absyn.Exp
                  local e2::Absyn.Exp
                  local c1::Absyn.ComponentRef
                  local c2::Absyn.ComponentRef
                  local eqn::IList
                  local eqs::IList
                  local iterators::Absyn.ForIterators
                @matchcontinue inEquation begin
                  Absyn.EQ_EQUALS(leftSide = e1, rightSide = e2)  => begin
                      s1 = Dump.printExpStr(e1)
                      s2 = Dump.printExpStr(e2)
                      s = stringAppend(s1, " = ")
                      s_1 = stringAppend(s, s2)
                    Graphviz.LNODE("EQ_EQUALS", list(s_1), list(), list())
                  end

                  Absyn.EQ_PDE(leftSide = e1, rightSide = e2, domain = c1)  => begin
                      s1 = Dump.printExpStr(e1)
                      s2 = Dump.printExpStr(e2)
                      s3 = Dump.printComponentRefStr(c1)
                      s = stringAppend(s1, " = ")
                      s_1 = stringAppend(s, s2)
                      s_1 = stringAppend(s_1, " indomain ")
                      s_1 = stringAppend(s_1, s3)
                    Graphviz.LNODE("EQ_PDE", list(s_1), list(), list())
                  end

                  Absyn.EQ_CONNECT(connector1 = c1, connector2 = c2)  => begin
                      s1 = Dump.printComponentRefStr(c1)
                      s2 = Dump.printComponentRefStr(c2)
                      s = stringAppend("connect(", s1)
                      s_1 = stringAppend(s, s2)
                      s_2 = stringAppend(s_1, ")")
                    Graphviz.LNODE("EQ_CONNECT", list(s_2), list(), list())
                  end

                  Absyn.EQ_FOR(iterators = iterators, forEquations = eqs)  => begin
                      eqn = printEquations(eqs)
                      es = Dump.printIteratorsStr(iterators)
                    Graphviz.LNODE("EQ_FOR", list(es), list(), eqn)
                  end

                  _  => begin
                      Graphviz.NODE("EQ_ERROR", list(), list())
                  end
                end
              end
          outNode
        end

         #= Create a Node list from an AlgorithmItem list. =#
        function printAlgorithms(inAbsynAlgorithmItemLst::IList)::IList
              local outNodeLst::IList

              outNodeLst = begin
                  local node::Graphviz.Node
                  local nl::IList
                  local e::Absyn.AlgorithmItem
                  local el::IList
                @match inAbsynAlgorithmItemLst begin
                   nil()  => begin
                    list()
                  end

                  e <| el  => begin
                      node = printAlgorithmitem(e)
                      nl = printAlgorithms(el)
                    node <| nl
                  end
                end
              end
          outNodeLst
        end

         #= Create a Node from an AlgorithmItem. =#
        function printAlgorithmitem(inAlgorithmItem::Absyn.AlgorithmItem)::Graphviz.Node
              local outNode::Graphviz.Node

              outNode = begin
                  local node::Graphviz.Node
                  local alg::Absyn.Algorithm
                @matchcontinue inAlgorithmItem begin
                  Absyn.ALGORITHMITEM(algorithm_ = alg)  => begin
                      node = printAlgorithm(alg)
                    node
                  end

                  _  => begin
                      Graphviz.NODE("ALG_ERROR", list(), list())
                  end
                end
              end
          outNode
        end

         #= Create a Node from an Algorithm. =#
        function printAlgorithm(inAlgorithm::Absyn.Algorithm)::Graphviz.Node
              local outNode::Graphviz.Node

              outNode = begin
                  local e::Absyn.Exp
                @matchcontinue inAlgorithm begin
                  Absyn.ALG_ASSIGN()  => begin
                    Graphviz.NODE("ALG_ASSIGN", list(), list())
                  end

                  _  => begin
                      Graphviz.NODE(" DumpGraphviz.printAlgorithm ALG_ERROR", list(), list())
                  end
                end
              end
          outNode
        end

         #= Return Variability as a string. =#
        function variabilitySymbol(inVariability::Absyn.Variability)::String
              local outString::String

              outString = begin
                @match inVariability begin
                  Absyn.VAR()  => begin
                    ""
                  end

                  Absyn.DISCRETE()  => begin
                    "DISCRETE"
                  end

                  Absyn.PARAM()  => begin
                    "PARAM"
                  end

                  Absyn.CONST()  => begin
                    "CONST"
                  end
                end
              end
          outString
        end

         #= Return direction as a string. =#
        function directionSymbol(inDirection::Absyn.Direction)::String
              local outString::String

              outString = begin
                @match inDirection begin
                  Absyn.BIDIR()  => begin
                    ""
                  end

                  Absyn.INPUT()  => begin
                    "INPUT"
                  end

                  Absyn.OUTPUT()  => begin
                    "OUTPUT"
                  end
                end
              end
          outString
        end

    #=So that we can use wildcard imports and named imports when they do occur. Not good Julia practice=#
    @exportAll()
  end