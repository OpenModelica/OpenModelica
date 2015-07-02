encapsulated package RewriteRules

function rewriteFrontEnd<A>
  input A inExp;
  output A outExp = inExp;
  output Boolean isChanged = false;
end rewriteFrontEnd;

function noRewriteRulesFrontEnd
  output Boolean noRules = true;
end noRewriteRulesFrontEnd;

function noRewriteRulesBackEnd
  output Boolean noRules = true;
end noRewriteRulesBackEnd;

function loadRules
algorithm
  assert(false, getInstanceName());
end loadRules;

function clearRules
algorithm
  assert(false, getInstanceName());
end clearRules;

annotation(__OpenModelica_Interface="frontend");
end RewriteRules;
