package SimCodeTest

function test
protected
  Absyn.Path path;
  DAE.Function func;
  GlobalScript.Statements stmts;
algorithm
  // Make the test link
  stmts := GlobalScript.ISTMTS(GlobalScript.IEXP(Absyn.INTEGER(1),Absyn.dummyInfo)::GlobalScript.IALG(Absyn.ALGORITHMITEMCOMMENT(""))::{},Absyn.isDerCref(Absyn.INTEGER(1)));
  // Begin actual code
  Flags.new({"+g=Modelica"});
  path:=Absyn.QUALIFIED("SimCodeC",Absyn.IDENT("abc"));
  func:=DAE.FUNCTION(path,{DAE.FUNCTION_DEF({})},DAE.T_FUNCTION({},DAE.T_NORETCALL_DEFAULT,DAE.FUNCTION_ATTRIBUTES_DEFAULT,{path}),SCode.PUBLIC(),false,false,DAE.NO_INLINE(),DAE.emptyElementSource,NONE());
  SimCodeMain.translateFunctions(Absyn.PROGRAM({},Absyn.TOP()),"SimCodeC_abc", SOME(func), {}, {}, {});
end test;

end SimCodeTest;
