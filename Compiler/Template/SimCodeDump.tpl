package SimCodeDump

import interface SimCodeTV;
import CodegenUtil.*;
import DAEDumpTpl.*;
import SCodeDumpTpl.*;

template dumpSimCode(SimCode code, Boolean withOperations)
::=
  match code
  case sc as SIMCODE(modelInfo=mi as MODELINFO(vars=vars as SIMVARS(__))) then
  let res = dumpSimCodeBase(code,withOperations)
  let() = textFile(res,'<%fileNamePrefix%>_info.xml')
  '<%fileNamePrefix%>_info'
end dumpSimCode;

template dumpSimCodeToC(SimCode code, Boolean withOperations)
::=
  match code
  case sc as SIMCODE(modelInfo=mi as MODELINFO(vars=vars as SIMVARS(__))) then
  let _ = dumpSimCode(code,withOperations)
  let _ = covertTextFileToCLiteral('<%fileNamePrefix%>_info.xml','<%fileNamePrefix%>_info.c')
  '<%fileNamePrefix%>_info'
end dumpSimCodeToC;

template dumpSimCodeBase(SimCode code, Boolean withOperations)
::=
  match code
  case sc as SIMCODE(modelInfo=mi as MODELINFO(vars=vars as SIMVARS(__))) then
  let name = Util.escapeModelicaStringToXmlString(dotPath(mi.name))
  <<
  <?xml version="1.0" encoding="UTF-8"?>
  <?xml-stylesheet type="application/xml" href="simcodedump.xsl"?>
  <simcodedump model="<%name%>">
  <variables>
    <%dumpVars(vars.stateVars,withOperations)%>
    <%dumpVars(vars.derivativeVars,withOperations)%>
    <%dumpVars(vars.algVars,withOperations)%>
    <%dumpVars(vars.intAlgVars,withOperations)%>
    <%dumpVars(vars.boolAlgVars,withOperations)%>
    <%dumpVars(vars.inputVars,withOperations)%>
    <%dumpVars(vars.outputVars,withOperations)%>
    <%dumpVars(vars.aliasVars,withOperations)%>
    <%dumpVars(vars.intAliasVars,withOperations)%>
    <%dumpVars(vars.boolAliasVars,withOperations)%>
    <%dumpVars(vars.paramVars,withOperations)%>
    <%dumpVars(vars.intParamVars,withOperations)%>
    <%dumpVars(vars.boolParamVars,withOperations)%>
    <%dumpVars(vars.stringAlgVars,withOperations)%>
    <%dumpVars(vars.stringParamVars,withOperations)%>
    <%dumpVars(vars.stringAliasVars,withOperations)%>
    <%dumpVars(vars.extObjVars,withOperations)%>
    <%dumpVars(vars.constVars,withOperations)%>
    <%dumpVars(vars.jacobianVars,withOperations)%>
  </variables>
  <initial-equations size="<%listLength(initialEquations)%>">
    <%dumpEqs(SimCodeUtil.sortEqSystems(initialEquations),0,withOperations)%>
  </initial-equations>
  <residual-equations size="<%listLength(residualEquations)%>">
    <%dumpEqs(SimCodeUtil.sortEqSystems(residualEquations),0,withOperations)%>
  </residual-equations>
  <equations size="<%listLength(allEquations)%>">
    <%dumpEqs(SimCodeUtil.sortEqSystems(allEquations),0,withOperations)%>
  </equations>
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
  </simcodedump><%\n%>
  >>
end dumpSimCodeBase;

template dumpVarsShort(list<SimVar> vars)
::=
  let varsString = (vars |> v as SIMVAR(__) hasindex index0 =>
  <<
  <%index0%>: <%Util.escapeModelicaStringToXmlString(crefStrNoUnderscore(v.name))%>
  >>
  ;separator="\n";empty)
  <<
  <%varsString%>

  >>
end dumpVarsShort;


template dumpVars(list<SimVar> vars, Boolean withOperations)
::=
  vars |> v as SIMVAR(__) =>
  let variability = getVariablity(varKind)
  <<
  <%match v
  case SIMVAR(arrayCref=SOME(c)) then
  <<
  <variable name="<%Util.escapeModelicaStringToXmlString(crefStrNoUnderscore(c))%>" comment="<%escapeModelicaStringToXmlString(v.comment)%>" variability = "<%variability%>" isDiscrete = "<%isDiscrete%>">
    <%ScalarVariableType(unit, displayUnit, minValue, maxValue, initialValue, nominalValue, isFixed, type_)%>
    <%dumpAlias(v.aliasvar)%>
    <%dumpElementSource(v.source,withOperations)%>
  </variable><%\n%>
  >>
  %><variable name="<%Util.escapeModelicaStringToXmlString(crefStrNoUnderscore(v.name))%>" comment="<%escapeModelicaStringToXmlString(v.comment)%>" variability = "<%variability%>" isDiscrete = "<%isDiscrete%>">
    <%ScalarVariableType(unit, displayUnit, minValue, maxValue, initialValue, nominalValue, isFixed, type_)%>
    <%dumpAlias(v.aliasvar)%>
    <%dumpElementSource(v.source,withOperations)%>
  </variable><%\n%>
  <variable name="$PRE.<%Util.escapeModelicaStringToXmlString(crefStrNoUnderscore(v.name))%>" comment="<%escapeModelicaStringToXmlString(v.comment)%>" variability = "<%variability%>" isDiscrete = "true">
    <%ScalarVariableType(unit, displayUnit, minValue, maxValue, initialValue, nominalValue, isFixed, type_)%>
    <%dumpAlias(v.aliasvar)%>
    <%dumpElementSource(v.source,withOperations)%>
  </variable><%\n%>
  >>
end dumpVars;

template dumpAlias(AliasVariable alias)
::=
  match alias
  case ALIAS(__) then '<alias><%Util.escapeModelicaStringToXmlString(crefStrNoUnderscore(varName))%></alias>'
  case NEGATEDALIAS(__) then ' <alias negated="true"><%Util.escapeModelicaStringToXmlString(crefStrNoUnderscore(varName))%></alias>'
end dumpAlias;

template eqIndex(SimEqSystem eq)
::=
match eq
    case SES_RESIDUAL(__)
    case SES_SIMPLE_ASSIGN(__)
    case SES_ARRAY_CALL_ASSIGN(__)
    case SES_ALGORITHM(__)
    case SES_LINEAR(__)
    case SES_NONLINEAR(__)
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
      <<
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
        <residual><%printExpStrEscaped(e.exp)%></residual>
        <%dumpElementSource(e.source,withOperations)%>
      </equation><%\n%>
      >>
    case e as SES_SIMPLE_ASSIGN(__) then
      <<
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
        <assign>
          <defines name="<%crefStrNoUnderscore(e.cref)%>" />
          <% extractUniqueCrefsFromExp(e.exp) |> cr => '<depends name="<%crefStrNoUnderscore(cr)%>" />' ; separator = "\n" %>
          <rhs><%printExpStrEscaped(e.exp)%></rhs>
        </assign>
        <%dumpElementSource(e.source,withOperations)%>
      </equation><%\n%>
      >>
    case e as SES_ARRAY_CALL_ASSIGN(__) then
      <<
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
        <assign type="array">
          <defines name="<%crefStrNoUnderscore(e.componentRef)%>" />
          <rhs><%printExpStrEscaped(e.exp)%></rhs>
        </assign>
        <%dumpElementSource(e.source,withOperations)%>
      </equation><%\n%>
      >>
    case e as SES_ALGORITHM(statements={}) then 'empty algorithm<%\n%>'
    case e as SES_ALGORITHM(statements=first::_)
      then
      <<
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
        <statement>
          <%e.statements |> stmt => escapeModelicaStringToXmlString(ppStmtStr(stmt,2)) %>
        </statement>
        <%dumpElementSource(getStatementSource(first),withOperations)%>
      </equation><%\n%>
      >>
    case e as SES_LINEAR(__) then
      <<
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
        <linear size="<%listLength(e.vars)%>" nnz="<%listLength(simJac)%>">
          <%e.vars |> SIMVAR(name=cr) => '<defines name="<%crefStrNoUnderscore(cr)%>" />' ; separator = "\n" %>
          <row>
            <%beqs |> exp => '<cell><%printExpStrEscaped(exp)%></cell>' ; separator = "\n" %><%\n%>
          </row>
          <matrix>
            <%simJac |> (i1,i2,eq) =>
            <<
            <cell row="<%i1%>" col="<%i2%>">
              <%match eq case e as SES_RESIDUAL(__) then '<residual><%printExpStrEscaped(e.exp)%></residual>' %>
            </cell>
            >>
            %>
          </matrix>
          <%e.sources |> source => dumpElementSource(source,withOperations) %>
        </linear>
      </equation><%\n%>
      >>
    case e as SES_NONLINEAR(__) then
      <<
      <%dumpEqs(SimCodeUtil.sortEqSystems(e.eqs),e.index,withOperations)%>
      <%match e.jacobianMatrix case SOME(({(eqns,_,_)},_,_,_,_,_)) then dumpEqs(SimCodeUtil.sortEqSystems(eqns),e.index,withOperations) else ''%>
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
        <nonlinear indexNonlinear="<%indexNonLinearSystem%>">
          <%e.crefs |> cr => '<defines name="<%crefStrNoUnderscore(cr)%>" />' ; separator = "\n" %>
          <%e.eqs |> eq => '<eq index="<%eqIndex(eq)%>"/>' ; separator = "\n" %>
        </nonlinear>
      </equation><%\n%>
      >>
    case e as SES_MIXED(__) then
      <<
      <%dumpEqs(fill(e.cont,1),e.index,withOperations)%>
      <%dumpEqs(e.discEqs,e.index,withOperations)%><%\n%>
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
        <mixed>
          <continuous index="<%eqIndex(e.cont)%>" />
          <%e.discVars |> SIMVAR(name=cr) => '<defines name="<%crefStrNoUnderscore(cr)%>" />' ; separator = ","%>
          <%e.discEqs |> eq => '<discrete index="<%eqIndex(eq)%>" />'%>
        </mixed>
      </equation>
      >>
    case e as SES_WHEN(__) then
      <<
      <equation index="<%eqIndex(eq)%>"<%hasParent(parent)%>>
        <when>
          <%conditions |> cond => '<cond><%crefStrNoUnderscore(cond)%></cond>' ; separator="\n" %>
          <defines name="<%crefStrNoUnderscore(e.left)%>" />
          <rhs><%printExpStrEscaped(e.right)%></rhs>
        </when>
        <%dumpElementSource(e.source,withOperations)%>
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
      <%dumpElementSource(e.source,withOperations)%>
      </equation><%\n%>
      >>
    else error(sourceInfo(),"dumpEqs: Unknown equation")
end dumpEqs;

template dumpWithin(Within w)
::=
  match w
    case TOP(__) then "within ;"
    case WITHIN(__) then 'within <%dotPath(path)%>;'
end dumpWithin;

template dumpElementSource(ElementSource source, Boolean withOperations)
::=
  match source
    case s as SOURCE(info=info as INFO(__)) then
      <<
      <source>
        <%dumpInfo(info)%>
        <%s.partOfLst |> w => '<part-of><%dumpWithin(w)%></part-of>' %>
        <%match s.instanceOpt case SOME(cr) then '<instance><%crefStrNoUnderscore(cr)%></instance>' %>
        <%s.connectEquationOptLst |> p => "<connect-equation />"%>
        <%s.typeLst |> p => '<type><%escapeModelicaStringToXmlString(dotPath(p))%></type>' ; separator = "\n" %>
      </source>
      <% if withOperations then <<
      <operations>
        <%s.operations |> op => dumpOperation(op,s.info) ; separator="\n" %>
      </operations>
      >> %>
      >>
end dumpElementSource;

template dumpOperation(SymbolicOperation op, Info info)
::=
  match op
    case FLATTEN(__) then
      <<
      <flattening>
        <original><% Util.escapeModelicaStringToXmlString(dumpEEquation(scode,SCodeDump.defaultOptions)) %></original>
        <% match dae case SOME(dae) then '<flattened><% Util.escapeModelicaStringToXmlString(dumpEquation(dae)) %></flattened>' %>
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

template dumpInfo(Info info)
::=
  match info
  case info as INFO(__) then
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

end SimCodeDump;

// vim: filetype=susan sw=2 sts=2
