package CodegenModelica

import interface GraphvizDumpTV;
import CodegenUtil.*;

template dumpBackendDAE(BackendDAE.BackendDAE backendDAE)
::=
  match backendDAE
    case dae as BackendDAE.DAE(eqs=eqs, shared=BackendDAE.SHARED(info=info as BackendDAE.EXTRA_INFO(__))) then
      let var = (eqs |> eqSystem as BackendDAE.EQSYSTEM(__) hasindex clusterID fromindex 1 =>
        let varDeclaration = (BackendVariable.varList(eqSystem.orderedVars) |> var as BackendDAE.VAR(__) hasindex varID fromindex 1 =>
          let typeStr = match var.varType
            case T_INTEGER(__) then 'Integer'
            case T_REAL(__) then 'Real'
            case T_STRING(__) then 'String'
            case T_BOOL(__) then 'Boolean'
            case T_ENUMERATION(__) then 'enumeration'
            else '?unknown?'
          let attrStr = match var.values
            case SOME(v) then
              match v
                case VAR_ATTR_REAL(__) then
                  let startStr = match start
                    case SOME(e) then 'start=<%ExpressionDump.printExpStr(e)%>, '
                    else ''
                  end match
                  let fixedStr = match fixed
                    case SOME(e) then 'fixed=<%ExpressionDump.printExpStr(e)%>, '
                    else ''
                  end match
                  let nominalStr = match nominal
                    case SOME(e) then 'nominal=<%ExpressionDump.printExpStr(e)%>, '
                    else ''
                  end match
                  let miniMaxStr = (min |> (e1, e2) =>
                    let minStr = match e1
                      case SOME(e) then 'min=<%ExpressionDump.printExpStr(e)%>, '
                      else ''
                    end match
                    let maxStr = match e2
                      case SOME(e) then 'max=<%ExpressionDump.printExpStr(e)%>, '
                      else ''
                    end match
                    '<%minStr%><%maxStr%>')
                  '<%startStr%><%fixedStr%><%nominalStr%><%miniMaxStr%>'
                case VAR_ATTR_INT(__) then
                  let startStr = match start
                    case SOME(e) then 'start=<%ExpressionDump.printExpStr(e)%>, '
                    else ''
                  end match
                  let fixedStr = match fixed
                    case SOME(e) then 'fixed=<%ExpressionDump.printExpStr(e)%>, '
                    else ''
                  end match
                  '<%startStr%><%fixedStr%>'
                case VAR_ATTR_BOOL(__) then
                  let startStr = match start
                    case SOME(e) then 'start=<%ExpressionDump.printExpStr(e)%>, '
                    else ''
                  end match
                  let fixedStr = match fixed
                    case SOME(e) then 'fixed=<%ExpressionDump.printExpStr(e)%>, '
                    else ''
                  end match
                  '<%startStr%><%fixedStr%>'
                else '?unknown?'
              end match
            else ''
          
          '<%typeStr%> <%crefStr(var.varName)%>(<%attrStr%>);'
          ;separator="\n")
        <<
        /* system #<%clusterID%> */
        <%varDeclaration%>
        >>
        ;separator="\n\n")
        
      let eqn = (eqs |> eqSystem as BackendDAE.EQSYSTEM(__) hasindex clusterID fromindex 1 =>
        let eqnDeclaration = (BackendEquation.equationList(eqSystem.orderedEqs) |> eq hasindex eqID fromindex 1 =>
          '<%BackendDump.equationString(eq)%>;'
          ;separator="\n")
        <<
        /* system #<%clusterID%> */
        <%eqnDeclaration%>
        >>
        ;separator="\n\n")
        
      <<
      /* This is probably not complete. */
      model <%info.fileNamePrefix%>
        <%var%>
      equation
        <%eqn%>
      end <%info.fileNamePrefix%>;
      >>
end dumpBackendDAE;

end CodegenModelica;
