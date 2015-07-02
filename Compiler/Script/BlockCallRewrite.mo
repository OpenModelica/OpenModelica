
encapsulated package BlockCallRewrite
" file:        BlockCallRewrite.mo
  package:     BlockCallRewrite
  description: This module implements an extension for properties modelling for calling blocks as functions.
               It rewrites block calls into block instantiations.
"

public import Absyn;

protected import Dump;

public function rewriteBlockCall
  input Absyn.Program inPg "Model containing block calls";
  input Absyn.Program inDefs "Block definitions";
  output Absyn.Program newOut "Standard Modelica output";
algorithm

  (newOut) := match(inPg, inDefs)
    local
      Absyn.Program pg, pg2, defs;
      String res;
    case (_, _)
      equation
        pg2 = parseProgram(inPg, inDefs);

        res = Dump.unparseStr(pg2, false);
        print(res);

      then
        pg2;
  end match;
end rewriteBlockCall;

protected function parseProgram
  input Absyn.Program inPg, defs;
  output Absyn.Program outPg = inPg;
algorithm
  outPg := match outPg
    case Absyn.PROGRAM()
      equation
        outPg.classes = parseClasses(outPg.classes, defs);
      then outPg;
  end match;
end parseProgram;

public function parseClasses
  input list<Absyn.Class>  classes;
  input Absyn.Program defs;

  output list<Absyn.Class>  out_classes;
algorithm
  out_classes := match(classes)
    local
      list<Absyn.Class>  r_classes, nr_classes;
      Absyn.Class cls, n_cls;
    case({}) then {};
    case(cls :: r_classes)
      equation
        nr_classes = parseClasses(r_classes, defs);
        n_cls = parseClass(cls, defs);
      then
        n_cls :: nr_classes;
  end match;
end parseClasses;

public function parseClass
  input Absyn.Class  in_class;
  input Absyn.Program defs;


  output Absyn.Class  out_class;
algorithm
  out_class := match(in_class)
    local
      list<Absyn.Class>  r_classes, nr_classes;
      Absyn.Class cls, n_cls;
      Absyn.Ident name;
      Boolean     partialPrefix, finalPrefix, encapsulatedPrefix;
      Absyn.Restriction restriction;
      Absyn.ClassDef    body, nbody;
      SourceInfo       info ;
    case(Absyn.CLASS(name, partialPrefix, finalPrefix, encapsulatedPrefix, restriction, body, info))
      equation
        nbody = parseClassDef(body, defs);
      then
        Absyn.CLASS(name, partialPrefix, finalPrefix, encapsulatedPrefix, restriction, nbody, info);
  end match;
end parseClass;

protected function parseClassDef
  input Absyn.ClassDef  in_def;
  input Absyn.Program defs;

  output Absyn.ClassDef  out_def;
algorithm
  out_def := match(in_def)
    local
      list<String> typeVars ;
      list<Absyn.NamedArg> classAttrs ;
      list<Absyn.ClassPart> classParts, nclsp;
      list<Absyn.Annotation> ann ;
      Option<String>  comment;
      list<Absyn.EquationItem> contents;
      list<Absyn.EquationItem> eqs;
      list<Absyn.ElementItem> elems;
    case(Absyn.PARTS(typeVars, classAttrs, classParts, ann, comment))
      equation
        (nclsp, eqs, elems) = parseClassParts(classParts, defs, {}, {}, 0);
      then
        Absyn.PARTS(typeVars, classAttrs, Absyn.PUBLIC(elems)::Absyn.EQUATIONS(eqs)::nclsp, ann, comment);
  end match;
end parseClassDef;

protected function parseClassParts
  input list<Absyn.ClassPart>  classes;
  input Absyn.Program defs;
  input list<Absyn.EquationItem> oldEqs;
  input list<Absyn.ElementItem> oldElems;
  input Integer instNo;

  output list<Absyn.ClassPart>  out_classes;
  output list<Absyn.EquationItem> eqs;
  output list<Absyn.ElementItem> elems;
  output Integer newInstNo;
algorithm
  (out_classes, eqs, elems, newInstNo) := match(classes)
    local
      list<Absyn.ClassPart>  r_classes, nr_classes;
      Absyn.ClassPart cls, n_cls;
      list<Absyn.EquationItem> eqs1, eqs2;
      list<Absyn.ElementItem> elems1, elems2;
      Integer count, count1;
    case({}) then ({}, oldEqs, oldElems, instNo);
    case(cls :: r_classes)
      equation
        (n_cls,eqs2, elems2, count1) = parseClassPart(cls, defs, oldEqs, oldElems, instNo);
        (nr_classes, eqs1, elems1, count) = parseClassParts(r_classes, defs, eqs2, elems2, count1);
        //print("classparts" + intString(count) + intString(count1) + "\n");
      then
        (n_cls :: nr_classes, eqs1, elems1, count);
  end match;
end parseClassParts;

protected function parseClassPart
  input Absyn.ClassPart  in_def;
  input Absyn.Program defs;
  input list<Absyn.EquationItem> oldEqs;
  input list<Absyn.ElementItem> oldElems;
  input Integer instNo;

  output Absyn.ClassPart  out_def;
  output list<Absyn.EquationItem> reqs;
  output list<Absyn.ElementItem> relems;
  output Integer newInstNo;
algorithm
  (out_def, reqs, relems, newInstNo) := match(in_def)
    local
      list<Absyn.ElementItem> elems;
      list<Absyn.Exp> exps;
      list<Absyn.EquationItem> eqs, neqs;
      list<Absyn.AlgorithmItem> algs;
      Absyn.ExternalDecl externalDecl;
      Option<Absyn.Annotation> annotation_ ;
      list<Absyn.EquationItem> eqs1, eqs2;
      list<Absyn.ElementItem> elems1, elems2;
      Integer count;
    case(Absyn.PUBLIC(elems)) //TODO
    then
      (Absyn.PUBLIC(elems), {}, {}, instNo);
    case(Absyn.PROTECTED(elems)) //TODO
    then
      (Absyn.PROTECTED(elems), {}, {}, instNo); //TODO
    case(Absyn.CONSTRAINTS(exps))
    then
      (Absyn.CONSTRAINTS(exps), {}, {}, instNo);
    case(Absyn.EQUATIONS(eqs))
      equation
        (neqs, eqs1, elems1, count) = parseEquations(eqs, defs, oldEqs, oldElems, instNo);
         //print("equations" + intString(count) + "\n");
      then
        (Absyn.EQUATIONS(neqs), eqs1, elems1, count);
    case(Absyn.INITIALEQUATIONS(eqs))
      equation
        (neqs, eqs1, elems1, count) = parseEquations(eqs, defs, oldEqs, oldElems, instNo);
         //print("equations" + intString(count) + "\n");
      then
        (Absyn.INITIALEQUATIONS(neqs), eqs1, elems1, count);
    case(Absyn.ALGORITHMS(algs)) //TODO
    then
      (Absyn.ALGORITHMS(algs), {}, {}, instNo);
    case(Absyn.INITIALALGORITHMS(algs)) //TODO
    then
      (Absyn.INITIALALGORITHMS(algs), {}, {}, instNo);
    case(Absyn.EXTERNAL(externalDecl, annotation_))
    then
      (Absyn.EXTERNAL(externalDecl, annotation_), {}, {}, instNo);
  end match;
end parseClassPart;

protected function parseEquations
  input list<Absyn.EquationItem>  classes;
  input Absyn.Program defs;
  input list<Absyn.EquationItem> oldEqs;
  input list<Absyn.ElementItem> oldElems;
  input Integer instNo;

  output list<Absyn.EquationItem>  out_classes;
  output list<Absyn.EquationItem> eqs;
  output list<Absyn.ElementItem> elems;
  output Integer newInstNo;
algorithm
  (out_classes, eqs, elems, newInstNo) := match(classes)
    local
      Absyn.Equation eq, neq;
      Option<Absyn.Comment> cmt;
      String comment;
      SourceInfo info ;
      list<Absyn.EquationItem> r_classes, nr_classes;
      list<Absyn.EquationItem> eqs1, eqs2;
      list<Absyn.ElementItem> elems1, elems2;
      Integer count, count1;
    case({}) then ({}, oldEqs, oldElems, instNo);
    case(Absyn.EQUATIONITEM(eq, cmt, info) :: r_classes)
      equation
        //print("in equation item\n");
        (neq, eqs2, elems2, count1) = parseEquation(eq, defs, oldEqs, oldElems, instNo);
        (nr_classes, eqs1, elems1, count) = parseEquations(r_classes, defs, eqs2, elems2, count1);

      then
        (Absyn.EQUATIONITEM(neq, cmt, info) :: nr_classes, eqs1, elems1, count);
    case(Absyn.EQUATIONITEMCOMMENT(comment) :: r_classes)
      equation
        (nr_classes, eqs1, elems1, count) = parseEquations(r_classes, defs, oldEqs, oldElems, instNo);
      then
        (Absyn.EQUATIONITEMCOMMENT(comment) :: nr_classes, eqs1, elems1, count);
  end match;
end parseEquations;

protected function parseEquation
  input Absyn.Equation  in_eq;
  input Absyn.Program defs;
  input list<Absyn.EquationItem> oldEqs;
  input list<Absyn.ElementItem> oldElems;
  input Integer instNo;

  output Absyn.Equation  out_eq;
  output list<Absyn.EquationItem> eqs;
  output list<Absyn.ElementItem> elems;
  output Integer newInstNo;
algorithm
  (out_eq, eqs, elems, newInstNo) := match(in_eq)
    local
      Absyn.Exp exp1, exp2, nexp1, nexp2;
      Absyn.EquationItem eqi, neqi;
      list<Absyn.EquationItem> leq1, leq2, nleq1, nleq2;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> tup1, ntup1;
      Absyn.ComponentRef cr1, cr2;
      Absyn.ForIterators fi;
      Absyn.FunctionArgs farg;
      list<Absyn.EquationItem> eqs1, eqs2, eqs3;
      list<Absyn.ElementItem> elems1, elems2, elems3;
      Integer count, count1, count2;
    case(Absyn.EQ_IF(exp1, leq1, tup1, leq2))
      equation
       // print("IF STATEMENT\n");
        (nexp1, eqs1, elems1, count) = parseExpression(exp1, defs, oldEqs, oldElems, instNo);
        (nleq1, eqs2, elems2, count1) = parseEquations(leq1, defs, eqs1, elems1, count);
        (nleq2, eqs3, elems3, count2) = parseEquations(leq2, defs, eqs2, elems2, count1);
        //print("IF STATEMENT2\n");
        //ntup1 = parseEquationTuple(tup1); TODO
      then
        (Absyn.EQ_IF(nexp1, nleq1, tup1, nleq2),  eqs3, elems3, count2);
    case(Absyn.EQ_EQUALS(exp1, exp2))
      equation
        // print("EQUALS STATEMENT\n");
        (nexp1, eqs1, elems1, count) = parseExpression(exp1, defs, oldEqs, oldElems, instNo);
        (nexp2, eqs2, elems2, count1) = parseExpression(exp2, defs, eqs1, elems1, count);
       // print("EQ_Equals count1 " + intString(count1) + "\n");
      then
        (Absyn.EQ_EQUALS(nexp1, nexp2), eqs2, elems2, count1);
    case(Absyn.EQ_CONNECT(cr1, cr2))
    then
      (Absyn.EQ_CONNECT(cr1, cr2), oldEqs, oldElems, instNo);
    case(Absyn.EQ_FOR(fi, leq1))
      equation
        (nleq1, eqs2, elems2, count) = parseEquations(leq1, defs, oldEqs, oldElems, instNo);
      then
        (Absyn.EQ_FOR(fi, nleq1), eqs2, elems2, count);
    case(Absyn.EQ_WHEN_E(exp1, leq1, tup1))
      equation
        nexp1 = parseExpression(exp1, defs, oldEqs, oldElems, instNo);
        nleq1 = parseEquations(leq1, defs, oldEqs, oldElems, instNo);
        //ntup1 = parseEquationTuple(tup1); TODO
      then
        (Absyn.EQ_WHEN_E(nexp1, nleq1, tup1), oldEqs, oldElems, instNo);
    case(Absyn.EQ_NORETCALL(cr1, farg))
    then
      (Absyn.EQ_NORETCALL(cr1, farg), oldEqs, oldElems, instNo);
    case(Absyn.EQ_FAILURE(eqi))
      equation
        //neqi = parseEquation(eqi);
      then
        (Absyn.EQ_FAILURE(eqi), oldEqs, oldElems, instNo);
  end match;
end parseEquation;


protected function parseExpression
  input Absyn.Exp  in_eq;
  input Absyn.Program defs;
  input list<Absyn.EquationItem> oldEqs;
  input list<Absyn.ElementItem> oldElems;
  input Integer instNo;

  output Absyn.Exp  out_eq;
  output list<Absyn.EquationItem> eqs;
  output list<Absyn.ElementItem> elems;
  output Integer newInstNo;
algorithm
  (out_eq, eqs, elems, newInstNo) := match(in_eq)
    local
      Integer int;
      Real rl;
      Absyn.ComponentRef crf;
      String str;
      Boolean bool;
      Absyn.Exp exp1, exp2, nexp1, nexp2, ife, nife;
      Absyn.Operator op;
      Absyn.FunctionArgs fargs;
      list<Absyn.EquationItem> eqs1, eqs2, eqs3, eqs4;
      list<Absyn.ElementItem> elems1, elems2, elems3, elems4;
      Integer count, count2, count3, count4;
      list<tuple<Absyn.Exp, Absyn.Exp>> elif, nelif;

    case(Absyn.BINARY(exp1, op, exp2))
      equation
        (nexp1, eqs1, elems1, count) =  parseExpression(exp1, defs, oldEqs, oldElems, instNo);
        (nexp2, eqs2, elems2, count2)  = parseExpression(exp2, defs, eqs1, elems1, count);
      then (Absyn.BINARY(nexp1, op, nexp2), eqs2, elems2, count2);

    case(Absyn.LBINARY(exp1, op, exp2))
      equation
        (nexp1, eqs1, elems1, count) =  parseExpression(exp1, defs, oldEqs, oldElems, instNo);
        (nexp2, eqs2, elems2, count2)  = parseExpression(exp2, defs, eqs1, elems1, count);
      then (Absyn.LBINARY(nexp1, op, nexp2), eqs2, elems2, count2);

    case(Absyn.UNARY(op, exp2))
      equation
        (nexp2, eqs2, elems2, count) = parseExpression(exp2, defs, oldEqs, oldElems, instNo);
      then (Absyn.UNARY(op, nexp2), eqs2, elems2, count);

     case(Absyn.LUNARY(op, exp2))
      equation
        (nexp2, eqs2, elems2, count) = parseExpression(exp2, defs, oldEqs, oldElems, instNo);
      then (Absyn.LUNARY(op, nexp2), eqs2, elems2, count);

    case(Absyn.IFEXP(ife, exp1, exp2, elif))
      equation
        (nife, eqs1, elems1, count) =  parseExpression(ife, defs, oldEqs, oldElems, instNo);
        (nexp1, eqs2, elems2, count2) = parseExpression(exp1, defs, eqs1, elems1, count);
        (nexp2, eqs3, elems3, count3) =  parseExpression(exp2, defs, eqs2, elems2, count2);
        (nelif, eqs4, elems4, count4) = parseExpressionTuple(elif, defs, eqs3, elems3, count3);
      then (Absyn.IFEXP(nife, nexp1, nexp2, nelif), eqs4, elems4, count4);

    case(Absyn.CALL(crf,fargs))
      equation
        //print("call" + intString(instNo) + "\n");
        (nexp1, eqs1, elems1, count) = parseCall(Absyn.CALL(crf,fargs), defs, instNo, oldEqs, oldElems);
      then (nexp1, eqs1, elems1, count);
     case(_)
       then (in_eq, oldEqs, oldElems, instNo);
  end match;
end parseExpression;


protected function parseExpressionTuple
  input list<tuple<Absyn.Exp, Absyn.Exp>> tuple_list;
  input Absyn.Program defs;
  input list<Absyn.EquationItem> oldEqs;
  input list<Absyn.ElementItem> oldElems;
  input Integer instNo;

  output list<tuple<Absyn.Exp, Absyn.Exp>> out_tuple_list;
  output list<Absyn.EquationItem> eqs;
  output list<Absyn.ElementItem> elems;
  output Integer newInstNo;
algorithm
  (out_tuple_list, eqs, elems, newInstNo) := match(tuple_list)
    local
      Absyn.Equation eq, neq;
      Option<Absyn.Comment> cmt;
      String comment;
      SourceInfo info ;
      list<tuple<Absyn.Exp, Absyn.Exp>> r_tuple_list, ntuples;
      list<Absyn.EquationItem> eqs1, eqs2, eqs3;
      list<Absyn.ElementItem> elems1, elems2, elems3;
      Integer count2, count1, count3;
      Absyn.Exp exp1, exp2, nexp1, nexp2;
    case({}) then ({}, oldEqs, oldElems, instNo);
    case(((exp1, exp2):: r_tuple_list))
      equation
       // print("in equation item\n");
        (nexp1, eqs1, elems1, count1) = parseExpression(exp1, defs, oldEqs, oldElems, instNo);
        (nexp2,_,_,_) = parseExpression(exp2, defs, eqs1, elems1, count1);
        (ntuples, eqs3, elems3, count3) = parseExpressionTuple(r_tuple_list, defs, eqs1, elems1, count1);
      then
        ((nexp1, nexp2) :: ntuples, eqs3, elems3, count3);
  end match;
end parseExpressionTuple;


/**
 When a function call is found, we check if it is in the block definitions, and if it is we replace it
 */
protected function parseCall
  input Absyn.Exp  in_eq;
  input Absyn.Program defs;
  input Integer instNo;
  input list<Absyn.EquationItem> oldEqs;
  input list<Absyn.ElementItem> oldElems;

  output Absyn.Exp  res_expr;
  output list<Absyn.EquationItem> newEqs;
  output list<Absyn.ElementItem> newElems;
  output Integer newInstNo;
algorithm
  (res_expr, newEqs, newElems, newInstNo) := matchcontinue(in_eq)

    local
      Absyn.FunctionArgs fargs;
      Absyn.ComponentRef crf;
      String elName;
      Absyn.ElementItem elem;
      Absyn.Ident id;
      list<Absyn.ElementArg> mods;
      list<Absyn.EquationItem> eqs;
      Integer count;

    case(Absyn.CALL(Absyn.CREF_IDENT(id, _), fargs))
      equation
        //print("Found function call " + id + "\n");
        (eqs, mods, true, count) = getDefinition(id, instNo, defs, fargs, oldEqs, {});
        elName = "_autogen_" + id + intString(instNo);
        //print("Parsed function call " + id + "\n");
        // create element, instert modifiers here
        elem = Absyn.ELEMENTITEM(Absyn.ELEMENT(false, NONE(), Absyn.NOT_INNER_OUTER(), Absyn.COMPONENTS(Absyn.ATTR(false, false, Absyn.NON_PARALLEL(), Absyn.VAR(), Absyn.BIDIR(), {}), Absyn.TPATH(Absyn.IDENT(id), NONE()),
          {Absyn.COMPONENTITEM(Absyn.COMPONENT(elName,{}, SOME(Absyn.CLASSMOD(mods, Absyn.NOMOD()))), NONE(), NONE())}), Absyn.dummyInfo, NONE()));

      then (Absyn.CREF(Absyn.CREF_QUAL(elName, {}, Absyn.CREF_IDENT("out", {}))),  eqs, elem::oldElems, count);

    case(Absyn.CALL(crf, fargs))
    then (Absyn.CALL(crf,fargs), oldEqs, {}, instNo);

  end matchcontinue;
end parseCall;

protected function getDefinition
  input Absyn.Ident id;
  input Integer instNo;
  input Absyn.Program defs;
  input Absyn.FunctionArgs fargs;
   input list<Absyn.EquationItem> oldEqs "equations to add to component";
  input list<Absyn.ElementArg> oldModif ;

  output list<Absyn.EquationItem> newEqs;
  output list<Absyn.ElementArg> newModif;
  output Boolean found;
  output Integer newInstNo;
algorithm
  (newEqs, newModif, found, newInstNo)  := match(defs)
    case Absyn.PROGRAM()
    then
      parseClassesDefs(id, instNo, defs.classes, fargs, oldEqs, oldModif);
  end match;
end getDefinition;


/**
 Get the block definitions, go through all packages
 */
protected function parseClassesDefs
  input Absyn.Ident id;
  input Integer instNo;
  input list<Absyn.Class>  classes;
  input Absyn.FunctionArgs fargs;
  input list<Absyn.EquationItem> oldEqs "equations to add to component";
  input list<Absyn.ElementArg> oldModif ;

  output list<Absyn.EquationItem> newEqs;
  output list<Absyn.ElementArg> newModif;
  output Boolean found;
  output Integer newInstNo;
algorithm
  (newEqs, newModif, found, newInstNo) := matchcontinue(classes)
    local
      list<Absyn.Class>  r_classes;
      Absyn.Ident id2;
      list<Absyn.ElementArg> mods;
      list<Absyn.ClassPart>    classParts;
      list<Absyn.EquationItem> eqs;
    case({}) then ({}, {}, false, instNo);
      //R_PACKAGE
     case(Absyn.CLASS(_, _, _, _, Absyn.R_PACKAGE(), Absyn.PARTS(_, _, classParts, _, _), _) :: _)
       equation
      // print("In package: "); print(id2); print(" \n");

       (eqs, mods, true) = lookThroughClasses(id, instNo,  fargs, classParts, oldEqs, oldModif);
       then
       (eqs, mods, true, instNo + 1) ;
    case(Absyn.CLASS(id2, _, _, _, Absyn.R_BLOCK(), Absyn.PARTS(_, _, classParts, _, _), _) :: _)
      equation
        //print("TESTING1: "); print(id); print(" "); print(id2); print(" \n");
        true = (id2 == id);
        (eqs, mods) = parseArgs("_autogen_" + id + intString(instNo), classParts, fargs, oldEqs, oldModif);
        //print("TESTING2: "); print(id); print(" "); print(id2); print(" \n");
      then
        (eqs, mods, true, instNo + 1) ;
    case(_ :: r_classes) then parseClassesDefs(id, instNo, r_classes, fargs, oldEqs, oldModif);
  end matchcontinue;
end parseClassesDefs;

protected function lookThroughClasses
  input Absyn.Ident id;
  input Integer instNo;
  input Absyn.FunctionArgs fargs;
  input list<Absyn.ClassPart>  classes "fields to be initialize";
  input list<Absyn.EquationItem> oldEqs "equations to add to component";
  input list<Absyn.ElementArg> oldModif ;

  output list<Absyn.EquationItem> newEqs "equations to add to component";
  output list<Absyn.ElementArg> newModif "modifiers to add to component";
  output Boolean found;

algorithm
  (newEqs, newModif, found) := matchcontinue(classes)
    local
      list<Absyn.ClassPart>  r_classes;
      list<Absyn.ElementItem> elems1;
      list<Absyn.EquationItem> eq1, req;
      list<Absyn.Exp> r_args;
      list<Absyn.ElementArg> modif, rmodif;

    case({})
        then (oldEqs, oldModif, false);
    case(Absyn.PUBLIC(elems1) :: _)
      equation
        (eq1, modif, true) = lookThroughElems(id, instNo, fargs, elems1, oldEqs, oldModif);
        then (eq1, modif, true);
    case(_ :: r_classes)
      then
        lookThroughClasses(id, instNo, fargs, r_classes, oldEqs, oldModif);
  end matchcontinue;
end lookThroughClasses;


protected function lookThroughElems
  input Absyn.Ident id;
  input Integer instNo;
  input Absyn.FunctionArgs fargs;
  input list<Absyn.ElementItem>  elems "fields to be initialized";
  input list<Absyn.EquationItem> oldEqs "equations to add to component";
  input list<Absyn.ElementArg> oldModif "current list of modifiers";

  output list<Absyn.EquationItem> newEqs "equations to add to component";
  output list<Absyn.ElementArg> newModif "modifiers to add to component";
  output Boolean found;
algorithm
  (newEqs, newModif, found) := matchcontinue(elems)
    local
      list<Absyn.ElementItem>  r_elems;
      list<Absyn.EquationItem> eqs;
      list<Absyn.ElementArg> mods;
      list<Absyn.ComponentItem> comps;
      list<Absyn.Exp> r_args;
      list<Absyn.ClassPart>  classParts;
      Absyn.Exp arg;
      Absyn.Ident id2;

    case({}) then (oldEqs, oldModif, false);
   case(Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_,
       Absyn.CLASSDEF(_, Absyn.CLASS(id2, _, _, _, Absyn.R_BLOCK(), Absyn.PARTS(_, _, classParts, _, _), _)),_,_)) :: _)
       equation
          true = (id2 == id);
        (eqs, mods) = parseArgs("_autogen_" + id + intString(instNo), classParts, fargs, oldEqs, oldModif);
      then
        (eqs, mods, true);
     case(Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_,
       Absyn.CLASSDEF(_, Absyn.CLASS(_, _, _, _, Absyn.R_PACKAGE(), Absyn.PARTS(_, _, classParts, _, _), _)),_,_)) :: _)
    equation
        (eqs, mods, true)  =  lookThroughClasses(id, instNo, fargs, classParts, oldEqs, oldModif);
      then (eqs, mods, true);
    case( _ :: r_elems)
    then
      lookThroughElems(id, instNo, fargs, r_elems, oldEqs, oldModif);
  end matchcontinue;
end lookThroughElems;


protected function parseArgs
  input String elemId;
  input list<Absyn.ClassPart>  classes;
  input Absyn.FunctionArgs fargs;
  input list<Absyn.EquationItem> oldEqs "equations to add to component";
  input list<Absyn.ElementArg> oldModif ;

  output list<Absyn.EquationItem> eqs;
  output list<Absyn.ElementArg> mods;

algorithm
  (eqs, mods) := match(fargs)
    local
      list<Absyn.Exp> args "args" ;
      list<Absyn.NamedArg> argNames "argNames" ;
      list<Absyn.Ident> ids;
      list<Absyn.EquationItem> eqs1;
      list<Absyn.ElementArg> mods1;

    case(Absyn.FUNCTIONARGS(args, argNames))
      equation
        (eqs1, mods1) = matchArgsClass(elemId, args, classes, oldEqs, oldModif);
      then
        matchNamedArgsClass(elemId, argNames, classes, eqs1, mods1);
  end match;
end parseArgs;

/**
uniontype NamedArg "The NamedArg uniontype consist of an Identifier for the argument and an expression
  giving the value of the argument"
  record NAMEDARG
    Ident argName "argName" ;
    Exp argValue "argValue" ;
  end NAMEDARG;

end NamedArg;
*/

protected function matchArgsClass
  input String elemId;
  input list<Absyn.Exp> args "positional arguments" ;
  input list<Absyn.ClassPart>  classes "fields to be initialize";
  input list<Absyn.EquationItem> oldEqs "equations to add to component";
  input list<Absyn.ElementArg> oldModif ;

  output list<Absyn.EquationItem> newEqs "equations to add to component";
  output list<Absyn.ElementArg> newModif "modifiers to add to component";

algorithm
  (newEqs, newModif) := match(classes, args)
    local
      list<Absyn.ClassPart>  r_classes, nr_classes;
      list<Absyn.ElementItem> elems1;
      list<Absyn.EquationItem> eq1;
      list<Absyn.Exp> r_args;
      list<Absyn.ElementArg> modif;

    case(_, {}) then  (oldEqs, oldModif);
    case({}, _) then (oldEqs, oldModif);
    case(Absyn.PUBLIC(elems1) :: r_classes, _)
      equation
        (eq1, modif, r_args) = matchArgsElems(elemId, args, elems1, oldEqs, oldModif);
      then
        matchArgsClass(elemId, r_args, r_classes, eq1, modif);
    case(_ :: r_classes, _)
      equation
      then
        matchArgsClass(elemId, args, r_classes, oldEqs, oldModif);
  end match;
end matchArgsClass;


protected function matchArgsElems
  input String elemId;
  input list<Absyn.Exp> args "positional arguments" ;
  input list<Absyn.ElementItem>  elems "fields to be initialized";
  input list<Absyn.EquationItem> oldEqs "equations to add to component";
  input list<Absyn.ElementArg> oldModif "current list of modifiers";

  output list<Absyn.EquationItem> newEqs "equations to add to component";
  output list<Absyn.ElementArg> newModif "modifiers to add to component";
  output list<Absyn.Exp> newArgs "non initialized positional arguments" ;
algorithm
  (newEqs, newModif, newArgs) := match(args, elems)
    local
      list<Absyn.ElementItem>  r_elems;
      list<Absyn.EquationItem> eqs;
      list<Absyn.ElementArg> modif;
      list<Absyn.ComponentItem> comps;
      list<Absyn.Exp> r_args;
      Absyn.Exp arg;

    case({}, _) then (oldEqs, oldModif, args);
    case(_, {}) then (oldEqs, oldModif, args);
    case(_::r_args, Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_,Absyn.COMPONENTS(Absyn.ATTR(_,_,_,Absyn.PARAM(),_,_), _, comps),_,_)) :: r_elems)
      equation
        (modif, r_args) = matchParamArgs(args, comps, oldModif);
      then
        matchArgsElems(elemId, r_args, r_elems, oldEqs, modif) ;
    case(_::r_args, Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_,Absyn.COMPONENTS(Absyn.ATTR(_,_,_,Absyn.VAR(),_,_), _, comps),_,_)) :: r_elems)
      equation
        (eqs, r_args) = matchVarArgs(elemId, args, comps, oldEqs);
      then
        matchArgsElems(elemId, r_args, r_elems, eqs, oldModif);
    case(_, _ :: r_elems)
    then
      matchArgsElems(elemId, args, r_elems, oldEqs, oldModif);
  end match;
end matchArgsElems;


protected function matchParamArgs
  input list<Absyn.Exp> args "positional arguments" ;
  input list<Absyn.ComponentItem> comps "fields to be initialized";
  input list<Absyn.ElementArg> oldModif ;

  output list<Absyn.ElementArg> newModif "modifiers to add to component";
  output list<Absyn.Exp> newArgs "non initialized positional arguments" ;
algorithm
  (newModif, newArgs) := match(comps, args)
    local
      list<Absyn.ComponentItem>  r_comps;
      list<Absyn.Exp> r_args;
      Absyn.Exp arg;
      Absyn.Ident cName;
      Absyn.ElementArg modif;

    case({}, _) then (oldModif, args);
    case(_, {}) then (oldModif, args);
    case(Absyn.COMPONENTITEM(Absyn.COMPONENT(cName,_,_), _, _) :: r_comps, arg::r_args)
      equation
        modif = Absyn.MODIFICATION(false, Absyn.NON_EACH(), Absyn.IDENT(cName), SOME(Absyn.CLASSMOD({}, Absyn.EQMOD(arg, Absyn.dummyInfo))),
          NONE(), Absyn.dummyInfo);
      then
        matchParamArgs(r_args, r_comps, modif::oldModif);

  end match;
end matchParamArgs;


protected function matchVarArgs
  input String elemId;
  input list<Absyn.Exp> args "positional arguments" ;
  input list<Absyn.ComponentItem> comps "fields to be initialized";
  input list<Absyn.EquationItem> oldEqs ;

  output list<Absyn.EquationItem> newEqs "modifiers to add to component";
  output list<Absyn.Exp> newArgs "non initialized positional arguments" ;
algorithm
  (newEqs, newArgs) := match(comps, args)
    local
      list<Absyn.ComponentItem>  r_comps;
      list<Absyn.Exp> r_args;
      Absyn.Exp arg;
      Absyn.Ident cName;
      Absyn.EquationItem eq;

    case({}, _) then (oldEqs, args);
    case(Absyn.COMPONENTITEM(Absyn.COMPONENT(cName,_,_), _, _) :: r_comps, arg::r_args)
      equation
        eq = Absyn.EQUATIONITEM(Absyn.EQ_EQUALS(Absyn.CREF(Absyn.CREF_QUAL(elemId, {}, Absyn.CREF_IDENT(cName, {}))), arg), NONE(), Absyn.dummyInfo);
      then
        matchVarArgs(elemId, r_args, r_comps, eq::oldEqs);

  end match;
end matchVarArgs;


protected function matchNamedArgsClass
  input String elemId;
  input list<Absyn.NamedArg> nargs "positional arguments" ;
  input list<Absyn.ClassPart>  classes "fields to be initialize";
  input list<Absyn.EquationItem> oldEqs "equations to add to component";
  input list<Absyn.ElementArg> oldModif ;

  output list<Absyn.EquationItem> newEqs "equations to add to component";
  output list<Absyn.ElementArg> newModif "modifiers to add to component";

algorithm
  (newEqs, newModif) := match(classes, nargs)
    local
      list<Absyn.ClassPart>  r_classes, nr_classes;
      list<Absyn.ElementItem> elems1;
      list<Absyn.EquationItem> eq1;
      list<Absyn.NamedArg> r_nargs;
      list<Absyn.ElementArg> modif;
      Absyn.Ident argName "argName" ;
      Absyn.Exp argValue "argValue" ;

    case(_, {}) then  (oldEqs, oldModif);
    case({}, _) then (oldEqs, oldModif); // TODO fix to fail
    case(_, Absyn.NAMEDARG(argName, argValue)::r_nargs)
      equation
        (eq1, modif) = matchNamedArgClass(elemId, argName, argValue, classes, oldEqs, oldModif);
      then
        matchNamedArgsClass(elemId, r_nargs, classes, eq1, modif);
  end match;
end matchNamedArgsClass;

protected function matchNamedArgClass
  input String elemId;
  input Absyn.Ident argName "argName" ;
  input Absyn.Exp argValue "argValue" ;
  input list<Absyn.ClassPart>  classes "fields to be initialize";
  input list<Absyn.EquationItem> oldEqs "equations to add to component";
  input list<Absyn.ElementArg> oldModif ;

  output list<Absyn.EquationItem> newEqs "equations to add to component";
  output list<Absyn.ElementArg> newModif "modifiers to add to component";

algorithm
  (newEqs, newModif) := matchcontinue(classes)
    local
      list<Absyn.ClassPart>  r_classes, nr_classes;
      list<Absyn.ElementItem> elems1;
      list<Absyn.EquationItem> eq1;
      list<Absyn.Exp> r_args;
      list<Absyn.ElementArg> modif;

    case({}) then  (oldEqs, oldModif);
    case(Absyn.PUBLIC(elems1) :: _)
      equation
        (eq1, modif, true) = matchNamedArgElems(elemId, argName, argValue, elems1, oldEqs, oldModif);
      then
        (eq1, modif);
    case(_ :: r_classes)
      equation
      then
        matchNamedArgClass(elemId, argName, argValue, r_classes, oldEqs, oldModif);
  end matchcontinue;
end matchNamedArgClass;


protected function matchNamedArgElems
  input String elemId;
  input Absyn.Ident argName "argName" ;
  input Absyn.Exp argValue "argValue" ;
  input list<Absyn.ElementItem>  elems "fields to be initialized";
  input list<Absyn.EquationItem> oldEqs "equations to add to component";
  input list<Absyn.ElementArg> oldModif "current list of modifiers";

  output list<Absyn.EquationItem> newEqs "equations to add to component";
  output list<Absyn.ElementArg> newModif "modifiers to add to component";
  output Boolean found;
algorithm
  (newEqs, newModif, found) := matchcontinue(elems)
    local
      list<Absyn.ElementItem>  r_elems;
      list<Absyn.EquationItem> eqs;
      list<Absyn.ElementArg> modif;
      list<Absyn.ComponentItem> comps;
      list<Absyn.Exp> r_args;
      Absyn.Exp arg;

    case({}) then (oldEqs, oldModif, false);
    case(Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_,Absyn.COMPONENTS(Absyn.ATTR(_,_,_,Absyn.PARAM(),_,_), _, comps),_,_)) :: _)
      equation
        (modif, true) = matchParamNamedArg(argName, argValue, comps, oldModif);
      then
       (oldEqs, modif, true) ;
    case(Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_,Absyn.COMPONENTS(Absyn.ATTR(_,_,_,Absyn.VAR(),_,_), _, comps),_,_)) :: _)
      equation
        (eqs, true) = matchVarNamedArg(elemId, argName, argValue, comps, oldEqs);
      then
       (eqs, oldModif, true);
    case(_ :: r_elems)
    then
      matchNamedArgElems(elemId, argName, argValue, r_elems, oldEqs, oldModif);
  end matchcontinue;
end matchNamedArgElems;


protected function matchParamNamedArg
  input Absyn.Ident argName "argName" ;
  input Absyn.Exp argValue "argValue" ;
  input list<Absyn.ComponentItem> comps "fields to be initialized";
  input list<Absyn.ElementArg> oldModif ;

  output list<Absyn.ElementArg> newModif "modifiers to add to component";
  output Boolean found;
algorithm
  (newModif, found) := matchcontinue(comps)
    local
      list<Absyn.ComponentItem>  r_comps;
      list<Absyn.Exp> r_args;
      Absyn.Exp arg;
      Absyn.Ident cName;
      Absyn.ElementArg modif;

    case({}) then (oldModif, false);
    case(Absyn.COMPONENTITEM(Absyn.COMPONENT(cName,_,_), _, _) :: _)
      equation
        (cName == argName) = true;
        modif = Absyn.MODIFICATION(false, Absyn.NON_EACH(), Absyn.IDENT(cName), SOME(Absyn.CLASSMOD({}, Absyn.EQMOD(argValue, Absyn.dummyInfo))),
          NONE(), Absyn.dummyInfo);
      then
        (modif::oldModif, true);
       case(_ :: r_comps)
      equation
      then
        matchParamNamedArg(argName, argValue, r_comps, oldModif);

  end matchcontinue;
end matchParamNamedArg;


protected function matchVarNamedArg
  input String elemId;
  input Absyn.Ident argName "argName" ;
  input Absyn.Exp argValue "argValue" ;
  input list<Absyn.ComponentItem> comps "fields to be initialized";
  input list<Absyn.EquationItem> oldEqs ;

  output list<Absyn.EquationItem> newEqs "modifiers to add to component";
   output Boolean found;
algorithm
  (newEqs, found) := matchcontinue(comps)
    local
      list<Absyn.ComponentItem>  r_comps;
      list<Absyn.Exp> r_args;
      Absyn.Exp arg;
      Absyn.Ident cName;
      Absyn.EquationItem eq;

    case({}) then (oldEqs, false);
    case(Absyn.COMPONENTITEM(Absyn.COMPONENT(cName,_,_), _, _) :: _)
      equation
         (cName == argName) = true;
        eq = Absyn.EQUATIONITEM(Absyn.EQ_EQUALS(Absyn.CREF(Absyn.CREF_QUAL(elemId, {}, Absyn.CREF_IDENT(cName, {}))), argValue), NONE(), Absyn.dummyInfo);
      then
        (eq::oldEqs, true);
       case(_ :: r_comps)
         equation
         then
        matchVarNamedArg(elemId, argName, argValue, r_comps, oldEqs);
  end matchcontinue;
end matchVarNamedArg;

annotation(__OpenModelica_Interface="frontend");
end BlockCallRewrite;
