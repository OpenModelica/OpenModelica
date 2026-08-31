/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package GraphvizDump

import interface GraphvizDumpTV;
import CodegenUtil.*;

template dumpBackendDAE(BackendDAE.BackendDAE backendDAE, String suffix)
::=
  match backendDAE
    case dae as BackendDAE.DAE(shared=BackendDAE.SHARED(info=info as BackendDAE.EXTRA_INFO(__))) then
      let _ = dumpAdjacencyMatrix(dae, suffix)
      let _ = textFile(dumpMatching(dae, suffix), '<%info.fileNamePrefix%>_<%suffix%>_matching.dot')
      //let _ = textFile(dumpSorting(dae, suffix), '<%info.fileNamePrefix%>_<%suffix%>_sorting.dot')

      //this top-level template always returns an empty result
      //since generated texts are written to files directly
      ''
  end match
end dumpBackendDAE;

template dumpAdjacencyMatrix(BackendDAE.BackendDAE backendDAE, String suffix)
::=
  match backendDAE
    case dae as BackendDAE.DAE(shared=BackendDAE.SHARED(info=info as BackendDAE.EXTRA_INFO(__))) then
      let _ = textFile(dumpDependence(dae, suffix), '<%info.fileNamePrefix%>_<%suffix%>_dependence.dot')
      ''
  end match
end dumpAdjacencyMatrix;

template dumpDependence(BackendDAE.BackendDAE backendDAE, String suffix)
::=
  match backendDAE
    case dae as BackendDAE.DAE(eqs=eqs, shared=BackendDAE.SHARED(info=info as BackendDAE.EXTRA_INFO(__))) then
      let systems = (eqs |> eqSystem as BackendDAE.EQSYSTEM(__) hasindex clusterID fromindex 1 =>
        let varDeclaration = (BackendVariable.varList(eqSystem.orderedVars) |> var as BackendDAE.VAR(__) hasindex varID fromindex 1 =>
          if isStateVar(var) then
            'var<%clusterID%>_<%varID%> [label="der(<%crefStr(var.varName)%>)", shape="box"]'
          else
            'var<%clusterID%>_<%varID%> [label="<%crefStr(var.varName)%>", shape="box"]'
          ;separator="\n")
        let eqDeclaration = (BackendEquation.equationList(eqSystem.orderedEqs) |> eq hasindex eqID fromindex 1 =>
          'eq<%clusterID%>_<%eqID%> [label="<%BackendDump.equationString(eq)%>", shape="box"]'
          ;separator="\n")
        <<
        subgraph cluster_<%clusterID%> {
          label = "system #<%clusterID%>";
          color=white

          <%varDeclaration%>

          <%eqDeclaration%>

          <%dumpDependence2(clusterID, eqSystem.m)%>
        }
        >>
        ;separator="\n\n")

      <<
      digraph G {
        label="<%info.fileNamePrefix%> [<%suffix%> - dependence]";
        rankdir=LR;

        <%systems%>
      }
      >>
end dumpDependence;

template dumpDependence2(Integer clusterID, Option<BackendDAE.AdjacencyMatrix> m)
::=
  match m
    case SOME(incMatrix) then
      let incNodes = (arrayList(incMatrix) |> varList hasindex eqID fromindex 1 =>
        let foo = (varList |> varID =>
          if intGt(varID, 0) then
            'var<%clusterID%>_<%varID%> -> eq<%clusterID%>_<%eqID%> [style="dashed", arrowhead="none"];'
          ;separator="\n")
        '<%foo%>'
        ;separator="\n")
      '<%incNodes%>'
    else
      '// no adjacency matrix'
end dumpDependence2;

template dumpMatching(BackendDAE.BackendDAE backendDAE, String suffix)
::=
  match backendDAE
    case dae as BackendDAE.DAE(eqs=eqs, shared=BackendDAE.SHARED(info=info as BackendDAE.EXTRA_INFO(__))) then
      let systems = (eqs |> eqSystem as BackendDAE.EQSYSTEM(__) hasindex clusterID fromindex 1 =>
        let varDeclaration = (BackendVariable.varList(eqSystem.orderedVars) |> var as BackendDAE.VAR(__) hasindex varID fromindex 1 =>
          if isStateVar(var) then
            'var<%clusterID%>_<%varID%> [label="der(<%crefStr(var.varName)%>)", shape="box"]'
          else
            'var<%clusterID%>_<%varID%> [label="<%crefStr(var.varName)%>", shape="box"]'
          ;separator="\n")
        let eqDeclaration = (BackendEquation.equationList(eqSystem.orderedEqs) |> eq hasindex eqID fromindex 1 =>
          <<
          eq<%clusterID%>_<%eqID%> [label="<%BackendDump.equationString(eq)%>", shape="box"]
          >>
          ;separator="\n")
        <<
        subgraph cluster_<%clusterID%> {
          label = "system #<%clusterID%>";
          color=white

          <%varDeclaration%>

          <%eqDeclaration%>

          <%connections(clusterID, eqSystem.matching, eqSystem.m)%>
        }
        >>
        ;separator="\n\n")

      <<
      digraph G {
        label="<%info.fileNamePrefix%> [<%suffix%> - matching]";
        rankdir=LR;

        <%systems%>
      }
      >>
end dumpMatching;

template connections(Integer clusterID, BackendDAE.Matching matching, Option<BackendDAE.AdjacencyMatrix> m)
::=
  match m
    case SOME(incMatrix) then
      match matching
        case matching as BackendDAE.MATCHING(ass2=ass2) then
          let incNodes = (arrayList(incMatrix) |> varList hasindex eqID fromindex 1 =>
            let foo = (varList |> varID =>
              if intEq(listGet(arrayList(ass2), eqID), varID) then
                'var<%clusterID%>_<%varID%> -> eq<%clusterID%>_<%eqID%> [style="bold", arrowhead="none"];'
              else
                if intGt(varID, 0) then
                  'var<%clusterID%>_<%varID%> -> eq<%clusterID%>_<%eqID%> [style="dashed", arrowhead="none"];'
              ;separator="\n")
            '<%foo%>'
            ;separator="\n")
          '<%incNodes%>'
        else
          let incNodes = (arrayList(incMatrix) |> varList hasindex eqID fromindex 1 =>
            let foo = (varList |> varID =>
              if intGt(varID, 0) then
                'var<%clusterID%>_<%varID%> -> eq<%clusterID%>_<%eqID%> [style="dashed", arrowhead="none"];'
              ;separator="\n")
            '<%foo%>'
            ;separator="\n")
          <<
          // no matching
          <%incNodes%>
          >>
    else
      match matching
        case matching as BackendDAE.MATCHING(ass2=ass2) then
          let matchedNodes = (arrayList(ass2) |> varID hasindex eqID fromindex 1 =>
            if intGt(varID, 0) then
              'var<%clusterID%>_<%varID%> -> eq<%clusterID%>_<%eqID%> [style="bold", arrowhead="none"];'
            ;separator="\n")
          <<
          // no adjacency matrix
          <%matchedNodes%>
          >>
        else
          <<
          // no adjacency matrix
          // no matching
          >>
end connections;

template dumpSorting(BackendDAE.BackendDAE backendDAE, String suffix)
::=
  match backendDAE
    case dae as BackendDAE.DAE(eqs=eqs, shared=BackendDAE.SHARED(info=info as BackendDAE.EXTRA_INFO(__))) then
      let systems = (eqs |> eqSystem as BackendDAE.EQSYSTEM(__) hasindex clusterID fromindex 1 =>
        let varDeclaration = (BackendVariable.varList(eqSystem.orderedVars) |> var as BackendDAE.VAR(__) hasindex varID fromindex 1 =>
          'var<%clusterID%>_<%varID%> [label="<%crefStr(var.varName)%>", shape="box"]'
          ;separator="\n")
        let eqDeclaration = (BackendEquation.equationList(eqSystem.orderedEqs) |> eq hasindex eqID fromindex 1 =>
          'eq<%clusterID%>_<%eqID%> [label="<%BackendDump.equationString(eq)%>", shape="box"]'
          ;separator="\n")
        <<
        subgraph cluster_<%clusterID%> {
          label = "system #<%clusterID%>";
          color=white

          <%varDeclaration%>

          <%dumpStrongComponent(clusterID, eqSystem.matching)%>
        }
        >>
        ;separator="\n\n")

      <<
      digraph G {
        label="<%info.fileNamePrefix%> [<%suffix%> - sorting]";
        rankdir=LR;

        <%systems%>
      }
      >>
end dumpSorting;

template dumpStrongComponent(Integer clusterID, BackendDAE.Matching matching)
::=
  match matching
    case matching as BackendDAE.MATCHING(comps=comps) then
      let cmpNodes = (comps |> comp hasindex eqID fromindex 1 =>
        match comp
          case c as SINGLEEQUATION(__) then
            'var<%clusterID%>_<%c.var%>'
          case c as EQUATIONSYSTEM(__) then
            let foo = (c.vars |> v => 'var<%clusterID%>_<%v%>' ;separator=" <-> ")
            '<%foo%>'
          else
            'asd'
        ;separator=" -> ")
        '<%cmpNodes%>'
end dumpStrongComponent;

annotation(__OpenModelica_Interface="backend");
end GraphvizDump;
