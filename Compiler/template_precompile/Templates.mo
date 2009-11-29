package Templates

import TemplCG;
import Util;

record TemplateSet
  String name;
  String generateFunctions;
  String generateFunctionBodies;
end TemplateSet;

record CompiledTemplateSet
  String name;
  TemplCG.TemplateTreeSequence generateFunctions;
  TemplCG.TemplateTreeSequence generateFunctionBodies;
end CompiledTemplateSet;

constant list<TemplateSet> templateList = {
  TemplateSet("C89", "C__GenerateFunctions.tpl","C__GenerateFunctionBodies.tpl")
};

public function CompileTemplateSets
  input list<TemplateSet> templates;
  output list<CompiledTemplateSet> out;
algorithm
  out := Util.listMap(templates,CompileTemplateSet);
end CompileTemplateSets;

public function CompileTemplateSet
  input TemplateSet templateSet;
  output CompiledTemplateSet out;
algorithm
  out := matchcontinue (templateSet)
    local
      String name, funcs, bodies;
      TemplCG.TemplateTreeSequence cFuncs, cBodies;
    case TemplateSet(name,funcs,bodies) equation
      cBodies = TemplCG.CompileTemplateFromFile(bodies, {});
      cFuncs = TemplCG.CompileTemplateFromFile(funcs, {});
    then CompiledTemplateSet(name,cFuncs,cBodies);
  end matchcontinue;
end CompileTemplateSet;

public function PrintCompiledTemplates
  input list<CompiledTemplateSet> templates;
algorithm
  _ := matchcontinue (templates)
    local
      CompiledTemplateSet cur;
      list<CompiledTemplateSet> rest;
    case {} then ();
    case (cur :: rest) equation
      PrintCompiledTemplate(cur);
      print("\n");
      PrintCompiledTemplates(rest);
    then ();
    case (cur :: rest) equation
      PrintCompiledTemplate(cur);
      print(",\n");
      PrintCompiledTemplates(rest);
    then ();
  end matchcontinue;
end PrintCompiledTemplates;

public function PrintCompiledTemplate
  input CompiledTemplateSet template;
algorithm
  _ := matchcontinue (template)
    local
      String name;
      TemplCG.TemplateTreeSequence functions, bodies;
    case CompiledTemplateSet(name,functions,bodies) equation
      print("CompiledTemplateSet(\"");
      print(name);
      print("\",");
      TemplCG.PrintTemplateTreeSequence(functions);
      print(",");
      TemplCG.PrintTemplateTreeSequence(bodies);
      print(")");
    then ();
  end matchcontinue;
end PrintCompiledTemplate;

end Templates;