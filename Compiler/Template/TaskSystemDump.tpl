package TaskSystemDump

import interface SimCodeTV;
import CodegenUtil.*;
import DAEDumpTpl.*;
import SCodeDumpTpl.*;

template dumpTaskSystem(SimCode code, Boolean withOperations)
::=
  match code
  case sc as SIMCODE(modelInfo=mi as MODELINFO(vars=vars as SIMVARS(__))) then
  let res = tasksystemdump_dispatch(code,withOperations)
  let() = textFile(res,'<%fileNamePrefix%>_tasks.xml')
  '<%fileNamePrefix%>_info'
end dumpTaskSystem;

template tasksystemdump_dispatch(SimCode code, Boolean withOperations)
::=
  match code
  case sc as SIMCODE(modelInfo=mi as MODELINFO(vars=vars as SIMVARS(__))) then
  let name = Util.escapeModelicaStringToXmlString(dotPath(mi.name))
  <<
  <?xml version="1.0" encoding="UTF-8"?>
  <?xml-stylesheet type="application/xml" href="tasksystemdump.xsl"?>
  <tasksystemdump model="<%name%>">
  <initial-equations size="<%listLength(initialEquations)%>">
    <%dumpEqs(SimCodeUtil.sortEqSystems(initialEquations),0,withOperations)%>
  </initial-equations>
  <dae-equations size="<%listLength(allEquations)%>">
    <%dumpEqs(SimCodeUtil.sortEqSystems(allEquations),0,withOperations)%>
  </dae-equations>
  <ode-equations size="<%if odeEquations then listLength(listGet(odeEquations,1)) else 0%>">
    <%if odeEquations then dumpEqs(SimCodeUtil.sortEqSystems(listGet(odeEquations,1)),0,withOperations)%>
  </ode-equations>
  <alg-equations size="<%if algebraicEquations then listLength(listGet(algebraicEquations,1)) else 0%>">
    <%if algebraicEquations then dumpEqs(SimCodeUtil.sortEqSystems(listGet(algebraicEquations,1)),0,withOperations)%>
  </alg-equations>
  <start-equations size="<%listLength(startValueEquations)%>">
    <%dumpEqs(SimCodeUtil.sortEqSystems(startValueEquations),0,withOperations)%>
  </start-equations>
  <nominal-equations size="<%listLength(nominalValueEquations)%>">
    <%dumpEqs(SimCodeUtil.sortEqSystems(nominalValueEquations),0,withOperations)%>
  </nominal-equations>
  <min-equations size="<%listLength(minValueEquations)%>">
    <%dumpEqs(SimCodeUtil.sortEqSystems(minValueEquations),0,withOperations)%>
  </min-equations>
  <max-equations size="<%listLength(maxValueEquations)%>">
    <%dumpEqs(SimCodeUtil.sortEqSystems(maxValueEquations),0,withOperations)%>
  </max-equations>
  <parameter-equations size="<%listLength(parameterEquations)%>">
    <%dumpEqs(SimCodeUtil.sortEqSystems(parameterEquations),0,withOperations)%>
  </parameter-equations>
  <assertions size="<%listLength(algorithmAndEquationAsserts)%>">
    <%dumpEqs(SimCodeUtil.sortEqSystems(algorithmAndEquationAsserts),0,withOperations)%>
  </assertions>
  <jacobian-equations>
    <%dumpEqs(SimCodeUtil.sortEqSystems(jacobianEquations),0,withOperations)%>
  </jacobian-equations>
  <literals size="<%listLength(literals)%>">
    <% literals |> exp => '<exp><%printExpStrEscaped(exp)%></exp>' ; separator="\n" %>
  </literals>
  <functions size="<%listLength(mi.functions)%>">
    <% mi.functions |> func => match func
      case FUNCTION(__)
      case EXTERNAL_FUNCTION(__)
      case KERNEL_FUNCTION(__)
      case PARALLEL_FUNCTION(__)
      case RECORD_CONSTRUCTOR(__) then
      '<function name="<%Util.escapeModelicaStringToXmlString(dotPath(name))%>"><%dumpInfo(info)%></function>' ; separator="\n"
    %>
  </functions>
  </tasksystemdump><%\n%>
  >>
end tasksystemdump_dispatch;

template eqIndex(SimEqSystem eq)
::=
match eq
    case SES_RESIDUAL(__)
    case SES_SIMPLE_ASSIGN(__)
    case SES_ARRAY_CALL_ASSIGN(__)
    case SES_ALGORITHM(__) then index
    case SES_LINEAR(lSystem=ls as LINEARSYSTEM(__)) then ls.index
    case SES_NONLINEAR(nlSystem=nls as NONLINEARSYSTEM(__)) then nls.index
    case SES_MIXED(__)
    case SES_WHEN(__)
    case SES_IFEQUATION(__) then index
    else error(sourceInfo(), "dumpEqs: Unknown equation")
end eqIndex;

template hasParent(Integer parent)
::=
  if intEq(parent,0) then "" else ' parent="<%parent%>"'
end hasParent;

template dumpEqs(list<SimEqSystem> eqs, Integer parent, Boolean withOperations)
::= eqs |> eq hasindex i0 =>
  match eq
    case e as SES_RESIDUAL(__) then
      let &defines = buffer ""
      let &depends = buffer ""
      let _ = eqDefinesDepends(e, defines, depends)
      <<
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
        <residual>
          <%defines%>
          <%depends%>
          <rhs><%printExpStrEscaped(e.exp)%></rhs>
        </residual>
      </equation><%\n%>
      >>
    case e as SES_SIMPLE_ASSIGN(__) then
      let &defines = buffer ""
      let &depends = buffer ""
      let _ = eqDefinesDepends(e, defines, depends)
      <<
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
        <assign>
          <%defines%>
          <%depends%>
          <rhs><%printExpStrEscaped(e.exp)%></rhs>
        </assign>
      </equation><%\n%>
      >>
    case e as SES_ARRAY_CALL_ASSIGN(__) then
      let &defines = buffer ""
      let &depends = buffer ""
      let _ = eqDefinesDepends(e, defines, depends)
      <<
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
        <assign_array>
          <%defines%>
          <%depends%>
          <rhs><%printExpStrEscaped(e.exp)%></rhs>
        </assign_array>
      </equation><%\n%>
      >>
    case e as SES_ALGORITHM(statements={}) then 'empty algorithm<%\n%>'
    case e as SES_ALGORITHM(statements=first::_)
      then
      let uniqcrefs = getdependcies(extractUniqueCrefsFromStatmentS(e.statements))
      <<
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
        <statement>
          <%uniqcrefs%>
          <stmt>
          <%e.statements |> stmt => escapeModelicaStringToXmlString(ppStmtStr(stmt,2)) %>
          </stmt>
        </statement>
      </equation><%\n%>
      >>
    case e as SES_LINEAR(lSystem=ls as LINEARSYSTEM(__)) then
      let &defines = buffer ""
      let &depends = buffer ""
      let &defines += ls.vars |> SIMVAR(name=cr) => '<defines name="<%crefStrNoUnderscore(cr)%>" />' ; separator = "\n"
      let _ = SimCodeUtil.sortEqSystems(ls.residual) |> reseq  =>
                eqDefinesDepends(reseq, defines, depends)
      let _ = (match ls.jacobianMatrix
        case SOME(({(eqns,_,_)},_,_,_,_,_,_)) then
          let _ = SimCodeUtil.sortEqSystems(eqns) |> jeq  =>
                  eqDefinesDepends(jeq, defines, depends)
          ""
       )
      <<
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
        <linear size="<%listLength(ls.vars)%>" nnz="<%listLength(ls.simJac)%>">
          <%defines%>
          <%depends%>
          <residuals>
          <%ls.residual |> eq => '<eq index="<%eqIndex(eq)%>"/>' ; separator = "\n" %>
          </residuals>
          <jacobian>
          <%match ls.jacobianMatrix case SOME(({(eqns,_,_)},_,_,_,_,_,_)) then (eqns |> eq => '<eq index="<%eqIndex(eq)%>"/>' ; separator = "\n") else ''%>
          </jacobian>
        </linear>
      </equation><%\n%>
      >>
    case e as SES_NONLINEAR(nlSystem=nls as NONLINEARSYSTEM(__)) then
      let &defines = buffer ""
      let &depends = buffer ""
      let &defines += nls.crefs |> cr => '<defines name="<%crefStrNoUnderscore(cr)%>"/>' ; separator = "\n"
      let _ = SimCodeUtil.sortEqSystems(nls.eqs) |> nleq  =>
                eqDefinesDepends(nleq, defines, depends)
      let _ = (match nls.jacobianMatrix
        case SOME(({(eqns,_,_)},_,_,_,_,_,_)) then
          let _ = SimCodeUtil.sortEqSystems(eqns) |> jeq  =>
                  eqDefinesDepends(jeq, defines, depends)
          ""
       )
      <<
      <%match nls.jacobianMatrix case SOME(({(eqns,_,_)},_,_,_,_,_,_)) then dumpEqs(SimCodeUtil.sortEqSystems(eqns),nls.index,withOperations) else ''%>
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
        <nonlinear indexNonlinear="<%nls.indexNonLinearSystem%>">
          <%defines%>
          <%depends%>
          <%nls.eqs |> eq => '<eq index="<%eqIndex(eq)%>"/>' ; separator = "\n" %>
        </nonlinear>
      </equation><%\n%>
      >>
    case e as SES_MIXED(__) then
      <<
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
        <mixed size="<%intAdd(listLength(e.discEqs),1)%>">
          <%e.discVars |> SIMVAR(name=cr) => '<defines name="<%crefStrNoUnderscore(cr)%>" />' ; separator = ","%>
          <%e.discEqs |> eq => '<discrete index="<%eqIndex(eq)%>" />'%>
          <continuous index="<%eqIndex(e.cont)%>" />
        </mixed>
      </equation><%\n%>
      <%dumpEqs(fill(e.cont,1),e.index,withOperations)%>
      <%dumpEqs(e.discEqs,e.index,withOperations)%>
      >>
    case e as SES_WHEN(__) then
      let body = dumpWhenOps(whenStmtLst)
      <<
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
      <when>
        <%conditions |> cond => '<cond><%crefStrNoUnderscore(cond)%></cond>' ; separator="\n" %>
        <%body%>
      </when>
      </equation><%\n%>
      >>
    case e as SES_IFEQUATION(__) then
      let branches = ifbranches |> (_,eqs) => dumpEqs(eqs,e.index,withOperations)
      let elsebr = dumpEqs(elsebranch,e.index,withOperations)
      <<
      <%branches%>
      <%elsebr%>
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
      <ifequation /> <!-- TODO: Fix me -->
      </equation><%\n%>
      >>
    else error(sourceInfo(),"dumpEqs: Unknown equation")
end dumpEqs;

template dumpWhenOps(list<BackendDAE.WhenOperator> whenOps)
::=
  match whenOps
  case ({}) then <<>>
  case ((e as BackendDAE.ASSIGN(__))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    <defines name="<%crefStrNoUnderscore(e.left)%>" />
    <% extractUniqueCrefsFromExpDerPreStart(e.right) |> cr => '<depends name="<%crefStrNoUnderscore(cr)%>" />' ; separator = "\n" %>
    <rhs><%printExpStrEscaped(e.right)%></rhs>
    <%restbody%>
    >>
  case ((e as BackendDAE.REINIT(__))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    <whenReinit>
      TODO: fix this case.
    </whenReinit>
    <%restbody%>
    >>
  case ((e as BackendDAE.ASSERT(__))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    <whenAssertion>
      TODO: fix this case.
    </whenAssertion>
    <%restbody%>
    >>
  case ((e as BackendDAE.TERMINATE(__))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    <whenTerminate>
      TODO: fix this case.
    </whenTerminate>
    <%restbody%>
    >>
  case ((e as BackendDAE.NORETCALL(__))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    <whenNoRetCall>
      TODO: fix this case.
    </whenNoRetCall>
    <%restbody%>
    >>
  else error(sourceInfo(),"dumpEqs: Unknown equation")
end dumpWhenOps;

template getdependcies(tuple<list<DAE.ComponentRef>, list<DAE.ComponentRef>> ocrefs)
::=
  match ocrefs
  case (olhscrefs,orhscrefs) then
  <<
  <%olhscrefs |> cr => '<defines name="<%crefStrNoUnderscore(cr)%>" />' ; separator = "\n"%>
  <%orhscrefs |> cr => '<depends name="<%crefStrNoUnderscore(cr)%>" />' ; separator = "\n"%>
  >>
  else "Error Printing dependenices"
end getdependcies;

template eqDefinesDepends(SimEqSystem eq, Text &defines, Text &depends)
::=
  match eq
  case e as SES_RESIDUAL(__) then
    let &depends += extractUniqueCrefsFromExpDerPreStart(e.exp) |> cr => '<depends name="<%crefStrNoUnderscore(cr)%>"/>' ; separator = "\n"
    ""
  case e as SES_SIMPLE_ASSIGN(__) then
    let &defines += '<defines name="<%crefStrNoUnderscore(e.cref)%>"/><%\n%>'
    let &depends += extractUniqueCrefsFromExpDerPreStart(e.exp) |> cr => '<depends name="<%crefStrNoUnderscore(cr)%>" />' ; separator = "\n"
    ""
  case e as SES_ARRAY_CALL_ASSIGN(__) then
    let &defines += extractUniqueCrefsFromExpDerPreStart(e.lhs) |> cr => '<defines name="<%crefStrNoUnderscore(cr)%>" />' ; separator = "\n"
    let &depends += extractUniqueCrefsFromExpDerPreStart(e.exp) |> cr => '<depends name="<%crefStrNoUnderscore(cr)%>" />' ; separator = "\n"
    ""
  else "Unrecognized Equation in eqDefinesDepends"
end eqDefinesDepends;

template dumpWithin(Within w)
::=
  match w
    case TOP(__) then "within ;"
    case WITHIN(__) then 'within <%dotPath(path)%>;'
end dumpWithin;

template dumpOperation(SymbolicOperation op, builtin.SourceInfo info)
::=
  match op
    case FLATTEN(__) then
      <<
      <flattening>
        <original><% Util.escapeModelicaStringToXmlString(dumpEEquation(scode,SCodeDump.defaultOptions)) %></original>
        <% match dae case SOME(dae) then '<flattened><% Util.escapeModelicaStringToXmlString(dumpEquationElement(dae)) %></flattened>' %>
      </flattening>
      >>
    case SIMPLIFY(__) then
      <<
      <simplify>
        <before><%printEquationExpStrEscaped(before)%></before>
        <after><%printEquationExpStrEscaped(after)%></after>
      </simplify>
      >>
    case SUBSTITUTION(__) then
      <<
      <substitution>
        <before><%printExpStrEscaped(source)%></before>
        <%listReverse(substitutions) |> target => '<exp><%printExpStrEscaped(target)%></exp>' ; separator="\n" %>
      </substitution>
      >>
    case op as OP_INLINE(__) then
      <<
      <inline>
        <before><%printEquationExpStrEscaped(op.before)%></before>
        <after><%printEquationExpStrEscaped(op.after)%></after>
      </inline>
      >>
    case op as OP_SCALARIZE(__) then
      <<
      <scalarize index="<%op.index%>">
        <before><%printEquationExpStrEscaped(op.before)%></before>
        <after><%printEquationExpStrEscaped(op.after)%></after>
      </scalarize>
      >>
    case op as SOLVED(__) then
      <<
      <solved>
        <lhs><%crefStrNoUnderscore(op.cr)%></lhs>
        <rhs><%printExpStrEscaped(op.exp)%></rhs>
      </solved>
      >>
    case op as LINEAR_SOLVED(__) then
      <<
      <linear-solved>
        simple equation from linear system:
          [<%vars |> v => crefStrNoUnderscore(v) ; separator = " ; "%>] = [<%result |> r => r ; separator = " ; "%>]
          [
            <% jac |> row => (row |> r => r ; separator = " "); separator = "\n"%>
          ]
        *
          X
        =
          [<%rhs |> r => r ; separator = " ; "%>]
      </linear-solved>
      >>
    case op as SOLVE(__) then
      <<
      <solve>
        <old>
          <lhs><%printExpStrEscaped(op.exp1)%></lhs>
          <rhs><%printExpStrEscaped(op.exp2)%></rhs>
        </old>
        <new>
          <lhs><%crefStrNoUnderscore(op.cr)%></lhs>
          <rhs><%printExpStrEscaped(op.res)%></rhs>
        </new>
        <assertions>
          <%op.assertConds |> cond => '<assertion><%printExpStrEscaped(cond)%></assertion>'; separator="\n"%>
        </assertions>
      </solve>
      >>
    case op as OP_DIFFERENTIATE(__) then
      <<
      <derivative>
        <exp><%printExpStrEscaped(op.before)%></exp>
        <with-respect-to><%crefStrNoUnderscore(op.cr)%></with-respect-to>
        <result><%printExpStrEscaped(op.after)%></result>
      </derivative>
      >>
    case OP_RESIDUAL(__) then
      <<
      <op-residual>
        <lhs><%printExpStrEscaped(e1)%></lhs>
        <rhs><%printExpStrEscaped(e2)%></rhs>
        <result><%printExpStrEscaped(e)%></result>
      </op-residual>
      >>
    case op as NEW_DUMMY_DER(__) then
      <<
      <dummyderivative>
        <chosen><%crefStrNoUnderscore(op.chosen)%></chosen>
        <%op.candidates |> cr => '<candidate><%crefStrNoUnderscore(cr)%></candidate>' ; separator = "\n"%>
      </dummyderivative>
      >>
    else Tpl.addSourceTemplateError("Unknown operation",info)
end dumpOperation;

template dumpInfo(builtin.SourceInfo info)
::=
  match info
  case info as SOURCEINFO(__) then
  '<info file="<%escapeModelicaStringToXmlString(info.fileName)%>" lineStart="<%info.lineNumberStart%>" lineEnd="<%info.lineNumberEnd%>" colStart="<%info.columnNumberStart%>" colEnd="<%info.columnNumberEnd%>"/>'
end dumpInfo;

template printExpStrEscaped(Exp exp)
::=
  escapeModelicaStringToXmlString(printExpStr(exp))
end printExpStrEscaped;

template printEquationExpStrEscaped(EquationExp eq)
::=
  match eq
  case PARTIAL_EQUATION(__)
  case RESIDUAL_EXP(__) then
    printExpStrEscaped(exp)
  case EQUALITY_EXPS(__) then
    '<%printExpStrEscaped(lhs)%> = <%printExpStrEscaped(rhs)%>'
end printEquationExpStrEscaped;

annotation(__OpenModelica_Interface="backend");
end TaskSystemDump;

// vim: filetype=susan sw=2 sts=2
