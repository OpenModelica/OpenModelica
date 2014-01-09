/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package RewriteRules
" file:        RewriteRules.mo
  package:     RewriteRules
  description: RewriteRules applies user given rewrite rules to the Absyn expressions

  RCS: $Id: RewriteRules.mo 18167 2013-11-18 12:36:35Z perost $

"

public import Absyn;
public import Global;
public import DAE;

public uniontype Rule "rule to rewrite fromExp -> toExp, there are absyn and dae rules"
 record AST_RULE "rule to rewrite fromExp -> toExp, apply to Absyn"
   Absyn.Exp from;
   Absyn.Exp to;
 end AST_RULE;
 
 record DAE_RULE "rule to rewrite fromExp -> toExp, apply to DAE"
   Absyn.Exp from;
   Absyn.Exp to;
 end DAE_RULE;
end Rule;

public type Rules = list<Rule>;

protected import Parser;
protected import GlobalScript;
protected import Error;
protected import Interactive;
protected import Flags;
protected import Dump;
protected import Util;

public function rewrite
  input Absyn.Exp inExp;
  output Absyn.Exp outExp;
algorithm
  outExp := inExp;
end rewrite;

public function rewriteDAE
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := inExp;
end rewriteDAE;

public function loadRules
algorithm
  _ := matchcontinue()
    local
      String file;
    
    case ()
      equation
        file = Flags.getConfigString(Flags.REWRITE_RULES_FILE);
        loadRulesFromFile(file);
      then ();
  
  end matchcontinue;
end loadRules;

public function loadRulesFromFile
"load the rewite rules in the global array: Global.rewriteRules"
  input String inFile;
algorithm
  _ := matchcontinue(inFile)
    local
      list<GlobalScript.Statement> stmts;
      Rules rules;
      Option<Rules> oR;
    
    // no file, set it to NONE
    case ""
      equation
        setGlobalRoot(Global.rewriteRules, NONE());
      then ();
    
    // already loaded
    case _ 
      equation
        oR = getGlobalRoot(Global.rewriteRules);
        true = Util.isSome(oR);
      then ();
    
    // not loaded, load it
    case _ 
      equation
        NONE() = getGlobalRoot(Global.rewriteRules);
        GlobalScript.ISTMTS(stmts, _) = parse(inFile);
        rules = stmtsToRules(stmts, {});
        setGlobalRoot(Global.rewriteRules, SOME(rules));
      then 
        ();

    case _
      equation
        Error.addInternalError("Unable to parse rewrite rules file: " +& inFile);
        setGlobalRoot(Global.rewriteRules, NONE());
      then
        ();
  
  end matchcontinue;
end loadRulesFromFile;

protected function parse
  input String inFile;
  output GlobalScript.Statements outStmts;
algorithm
  outStmts := matchcontinue(inFile)
    local
      GlobalScript.Statements stmts;
    
    // parse OK
    case _
      equation
        stmts = Parser.parseexp(inFile);
      then
        stmts;
    
    // parse not OK
    case _
      equation
        failure(_ = Parser.parseexp(inFile));
      then
        fail();
  
  end matchcontinue;
end parse;

protected function stmtsToRules
  input list<GlobalScript.Statement> inStmts;
  input Rules inAcc;
  output Rules outRules;
algorithm
  outRules := matchcontinue(inStmts, inAcc)
    local 
      list<GlobalScript.Statement> rest;
      GlobalScript.Statement s;
      Rules acc;
      Absyn.Exp from, to;
    
    // empty case
    case ({}, _) then listReverse(inAcc);
    
    // ast-rules  
    case (GlobalScript.IEXP(
           Absyn.CALL(
             Absyn.CREF_IDENT(name = "rewrite"),
             Absyn.FUNCTIONARGS({from, to}, {}))
           )::rest, _)
      equation
        print("AST rule: " +& Dump.printExpStr(from) +& " -> " +& Dump.printExpStr(to) +& "\n"); 
        acc = stmtsToRules(rest, AST_RULE(from, to)::inAcc);
      then 
        acc;
    
    // dae-rules 
    case (GlobalScript.IEXP(
           Absyn.CALL(
             Absyn.CREF_IDENT(name = "rewriteDAE"),
             Absyn.FUNCTIONARGS({from, to}, {}))
           )::rest, _)
      equation
        print("DAE rule: " +& Dump.printExpStr(from) +& " -> " +& Dump.printExpStr(to) +& "\n"); 
        acc = stmtsToRules(rest, DAE_RULE(from, to)::inAcc);
      then 
        acc;
    
    case (s::rest, _)
      equation
        Error.addInternalError("Unable to parse rewrite rule: " +& 
          Interactive.printIstmtStr(GlobalScript.ISTMTS({s}, true)));
      then
        fail();
  
  end matchcontinue;
end stmtsToRules;

end RewriteRules;
