
encapsulated package BlockCallRewrite
" file:        BlockCallRewrite.mo
  package:     BlockCallRewrite
  description: This module implements an extension for properties modelling for calling blocks as functions.
               It rewrites block calls into block instantiations.
"

public import Absyn;
protected import Error;

public function rewriteBlockCall
  input Absyn.Program inPg "Model containing block calls";
  input Absyn.Program inDefs "Block definitions";
  output Absyn.Program newOut "Standard Modelica output";
algorithm
  (newOut) := match(inPg, inDefs)
    case (_, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"rewriteBlockCall is not implemented in RML; use the bootstrapped omc to use BlockCallRewrite.mo"});
      then fail();
  end match;
end rewriteBlockCall;

annotation(__OpenModelica_Interface="frontend");
end BlockCallRewrite;
