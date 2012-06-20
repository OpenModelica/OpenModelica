interface package DAEDumpTV

// Susan can't handle cyclic includes of templates, so this is a bit of a hack
// to allow DAEDumpTpl to dump expressions without actually including
// ExpressionDumpTpl.
package ExpressionDumpTpl
  function dumpExp
    input Tpl.Text in_txt;
    input DAE.Exp in_a_exp;
    input String in_a_stringDelimiter;
    output Tpl.Text out_txt;
  end dumpExp;
end ExpressionDumpTpl;

package DAE
  uniontype Statement
    record STMT_ASSIGN
      Exp exp1;
      Exp exp;
    end STMT_ASSIGN;

    record STMT_TUPLE_ASSIGN
      list<Exp> expExpLst;
      Exp exp;
    end STMT_TUPLE_ASSIGN;

    record STMT_ASSIGN_ARR
      ComponentRef componentRef;
      Exp exp;
    end STMT_ASSIGN_ARR;

    record STMT_IF
      Exp exp;
      list<Statement> statementLst;
      Else else_;
    end STMT_IF;

    record STMT_FOR
      Boolean iterIsArray;
      Ident iter;
      Exp range;
      list<Statement> statementLst;
    end STMT_FOR;

    record STMT_WHILE
      Exp exp;
      list<Statement> statementLst;
    end STMT_WHILE;

    record STMT_WHEN
      Exp exp;
      list<Statement> statementLst;
      Option<Statement> elseWhen;
      list<Integer> helpVarIndices;
    end STMT_WHEN;

    record STMT_ASSERT
      Exp cond;
      Exp msg;
    end STMT_ASSERT;

    record STMT_TERMINATE
      Exp msg;
    end STMT_TERMINATE;

    record STMT_REINIT
      Exp var;
      Exp value;
    end STMT_REINIT;

    record STMT_NORETCALL
      Exp exp;
    end STMT_NORETCALL;

    record STMT_RETURN
      ElementSource source;
    end STMT_RETURN;

    record STMT_BREAK
      ElementSource source;
    end STMT_BREAK;

    record STMT_FAILURE
      list<Statement> body;
      ElementSource source;
    end STMT_FAILURE;

    record STMT_TRY
      list<Statement> tryBody;
    end STMT_TRY;

    record STMT_CATCH
      list<Statement> catchBody;
    end STMT_CATCH;

    record STMT_THROW
      ElementSource source;
    end STMT_THROW;
  end Statement;
end DAE;

end DAEDumpTV;
