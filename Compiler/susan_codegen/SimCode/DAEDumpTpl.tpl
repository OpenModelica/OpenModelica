package DAEDumpTpl

import interface DAEDumpTV;

template dumpStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_ASSIGN(__) then
    let lhs_str = dumpExp(exp1)
    let rhs_str = dumpExp(exp)
    '<%lhs_str%> := <%rhs_str%>'
end dumpStatement;

template dumpStatements(list<DAE.Statement> stmts)
::= (stmts |> stmt => dumpStatement(stmt) ;separator="\n")
end dumpStatements;

template dumpExp(DAE.Exp exp)
::= ExpressionDumpTpl.dumpExp(exp, "\"")
end dumpExp;

end DAEDumpTpl;
