encapsulated package ElementSource "A package for recording symbolic operations (used by the debugger) as well as other operations recording where an equation came from"

import DAE;

protected

import Absyn;
import Algorithm;
import Error;
import Expression;
import List;
import SCode;

public

function mergeSources
  input DAE.ElementSource src1;
  input DAE.ElementSource src2;
  output DAE.ElementSource mergedSrc;
algorithm
  mergedSrc := match(src1,src2)
    local
      SourceInfo info;
      list<Absyn.Within> partOfLst1,partOfLst2,p;
      Option<DAE.ComponentRef> instanceOpt1,instanceOpt2,i;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst1,connectEquationOptLst2,c;
      list<Absyn.Path> typeLst1,typeLst2,t;
      list<DAE.SymbolicOperation> o,operations1,operations2;
      list<SCode.Comment> comment, comment1,comment2;
    case (DAE.SOURCE(info, partOfLst1, instanceOpt1, connectEquationOptLst1, typeLst1, operations1, comment1),
          DAE.SOURCE(_ /* Discard */, partOfLst2, instanceOpt2, connectEquationOptLst2, typeLst2, operations2, comment2))
      equation
        p = List.union(partOfLst1, partOfLst2);
        i = if isSome(instanceOpt1) then instanceOpt1 else instanceOpt2;
        c = List.union(connectEquationOptLst1, connectEquationOptLst2);
        t = List.union(typeLst1, typeLst2);
        o = listAppend(operations1, operations2);
        comment = List.union(comment1,comment2);
      then DAE.SOURCE(info,p,i,c,t, o,comment);
 end match;
end mergeSources;

function addCommentToSource
  input DAE.ElementSource src1;
  input Option<SCode.Comment> commentIn;
  output DAE.ElementSource mergedSrc;
algorithm
  mergedSrc := match(src1,commentIn)
    local
      SourceInfo info;
      list<Absyn.Within> partOfLst1;
      Option<DAE.ComponentRef> instanceOpt1;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst1;
      list<Absyn.Path> typeLst1;
      list<DAE.SymbolicOperation> operations1;
      list<SCode.Comment> comment1,comment2;
      SCode.Comment comment;
    case (DAE.SOURCE(info, partOfLst1, instanceOpt1, connectEquationOptLst1, typeLst1, operations1, comment1),SOME(comment))
      equation
        comment2 = comment::comment1;
      then DAE.SOURCE(info,partOfLst1,instanceOpt1,connectEquationOptLst1,typeLst1, operations1,comment2);
    else
      then
        src1;
 end match;
end addCommentToSource;

function createElementSource
"@author: adrpo
 set the various sources of the element"
  input SourceInfo fileInfo;
  input Option<Absyn.Path> partOf "the model(s) this element came from";
  input Option<DAE.ComponentRef> instanceOpt "the instance(s) this element is part of";
  input Option<tuple<DAE.ComponentRef, DAE.ComponentRef>> connectEquationOpt "this element came from this connect(s)";
  input Option<Absyn.Path> typeOpt "the classes where the type(s) of the element is defined";
  output DAE.ElementSource source;
algorithm
  // TODO: Optimize this to only do 1 allocation?
  source := addElementSourceFileInfo(DAE.emptyElementSource, fileInfo);
  source := addElementSourcePartOfOpt(source, partOf);
  source := addElementSourceInstanceOpt(source, instanceOpt);
  source := addElementSourceConnectOpt(source, connectEquationOpt);
  source := addElementSourceTypeOpt(source, typeOpt);
end createElementSource;

function addAdditionalComment
  input DAE.ElementSource source;
  input String message;
  output DAE.ElementSource outSource;
algorithm
  outSource := match (source,message)
    local
      SourceInfo info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Path> typeLst "the absyn type of the element" ;
      list<Absyn.Within> partOfLst "the models this element came from" ;
      Option<DAE.ComponentRef> instanceOpt "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;
      list<DAE.SymbolicOperation> operations;
      list<SCode.Comment> comment;
      Boolean b;
      SCode.Comment c;

    case (DAE.SOURCE(info, partOfLst, instanceOpt, connectEquationOptLst, typeLst, operations, comment),_)
      equation
        c = SCode.COMMENT(NONE(), SOME(message));
        b = listMember(c, comment);
        comment = if b then comment else (c::comment);
      then
        DAE.SOURCE(info, partOfLst, instanceOpt, connectEquationOptLst, typeLst, operations, comment);

  end match;
end addAdditionalComment;

function addAnnotation
  input DAE.ElementSource source;
  input SCode.Comment comment;
  output DAE.ElementSource outSource;
algorithm
  outSource := match (source,comment)
    local
      SourceInfo info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Path> typeLst "the absyn type of the element" ;
      list<Absyn.Within> partOfLst "the models this element came from" ;
      Option<DAE.ComponentRef> instanceOpt "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;
      list<DAE.SymbolicOperation> operations;
      list<SCode.Comment> commentLst;
      Boolean b;
      SCode.Comment c;

    case (DAE.SOURCE(info, partOfLst, instanceOpt, connectEquationOptLst, typeLst, operations, commentLst),SCode.COMMENT(annotation_=SOME(_)))
      then DAE.SOURCE(info, partOfLst, instanceOpt, connectEquationOptLst, typeLst, operations, comment::commentLst);
    else source;

  end match;
end addAnnotation;

function getCommentsFromSource
  input DAE.ElementSource source;
  output list<SCode.Comment> outComments;
algorithm
  outComments := match (source)
    local
      list<SCode.Comment> comment;

    case (DAE.SOURCE(comment = comment)) then comment;

  end match;
end getCommentsFromSource;

function addSymbolicTransformation
  input output DAE.ElementSource source;
  input DAE.SymbolicOperation op;
algorithm
  if not Flags.isSet(Flags.INFO_XML_OPERATIONS) then
    return;
  end if;
  source := match (source,op)
    local
      SourceInfo info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Path> typeLst "the absyn type of the element" ;
      list<Absyn.Within> partOfLst "the models this element came from" ;
      Option<DAE.ComponentRef> instanceOpt "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;
      list<DAE.SymbolicOperation> operations;
      DAE.Exp h1,t1,t2;
      list<DAE.Exp> es1,es2,es;
      list<SCode.Comment> comment;

    case (DAE.SOURCE(info, partOfLst, instanceOpt, connectEquationOptLst, typeLst, DAE.SUBSTITUTION(es1 as (h1::_),t1)::operations,comment),DAE.SUBSTITUTION(es2,t2))
      guard
        // The tail of the new substitution chain is the same as the head of the old one...
        Expression.expEqual(t2,h1)
      equation
        // Reference equality would be fine as otherwise it is not really a chain... But replaceExp is stupid :(
        // true = referenceEq(t2,h1);
        es = listAppend(es2,es1);
      then DAE.SOURCE(info, partOfLst, instanceOpt, connectEquationOptLst, typeLst, DAE.SUBSTITUTION(es,t1)::operations,comment);

    case (DAE.SOURCE(info, partOfLst, instanceOpt, connectEquationOptLst, typeLst, operations, comment),_)
      then DAE.SOURCE(info, partOfLst, instanceOpt, connectEquationOptLst, typeLst, op::operations,comment);
  end match;
end addSymbolicTransformation;

function condAddSymbolicTransformation
  input Boolean cond;
  input output DAE.ElementSource source;
  input DAE.SymbolicOperation op;
algorithm
  if not cond then
    return;
  end if;
  source := addSymbolicTransformation(source,op);
end condAddSymbolicTransformation;

function addSymbolicTransformationDeriveLst
  input output DAE.ElementSource source;
  input list<DAE.Exp> explst1;
  input list<DAE.Exp> explst2;
algorithm
  if not Flags.isSet(Flags.INFO_XML_OPERATIONS) then
    return;
  end if;
  source := match(explst1,explst2)
    local
      DAE.SymbolicOperation op;
      list<DAE.Exp> rexplst1,rexplst2;
      DAE.Exp exp1,exp2;
    case({},_) then source;
    case(exp1::rexplst1,exp2::rexplst2)
      equation
        op = DAE.OP_DIFFERENTIATE(DAE.crefTime,exp1,exp2);
        source = addSymbolicTransformation(source,op);
      then
        addSymbolicTransformationDeriveLst(source,rexplst1,rexplst2);
  end match;
end addSymbolicTransformationDeriveLst;

function addSymbolicTransformationFlattenedEqs
  input output DAE.ElementSource source;
  input DAE.Element elt;
algorithm
  if not Flags.isSet(Flags.INFO_XML_OPERATIONS) then
    return;
  end if;
  source := match (source,elt)
    local
      SourceInfo info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Path> typeLst "the absyn type of the element" ;
      list<Absyn.Within> partOfLst "the models this element came from" ;
      Option<DAE.ComponentRef> instanceOpt "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;
      list<DAE.SymbolicOperation> operations;
      DAE.Exp h1,t1,t2;
      list<SCode.Comment> comment;
      SCode.EEquation scode;
      list<DAE.Element> elts;
    case (DAE.SOURCE(info, partOfLst, instanceOpt, connectEquationOptLst, typeLst, DAE.FLATTEN(scode,NONE())::operations,comment),_)
      then DAE.SOURCE(info, partOfLst, instanceOpt, connectEquationOptLst, typeLst, DAE.FLATTEN(scode,SOME(elt))::operations,comment);
    case (DAE.SOURCE(info=info),_)
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"Tried to add the flattened elements to the list of operations, but did not find the SCode equation"}, info);
      then fail();
  end match;
end addSymbolicTransformationFlattenedEqs;

function addSymbolicTransformationSubstitutionLst
  input list<Boolean> add;
  input output DAE.ElementSource source;
  input list<DAE.Exp> explst1;
  input list<DAE.Exp> explst2;
algorithm
  if not Flags.isSet(Flags.INFO_XML_OPERATIONS) then
    return;
  end if;
  source := match(add,explst1,explst2)
    local
      list<Boolean> brest;
      list<DAE.Exp> rexplst1,rexplst2;
      DAE.Exp exp1,exp2;
    case({},_,_) then source;
    case(true::brest,exp1::rexplst1,exp2::rexplst2)
      equation
        source = addSymbolicTransformationSubstitution(true,source,exp1,exp2);
      then
        addSymbolicTransformationSubstitutionLst(brest,source,rexplst1,rexplst2);
    case(false::brest,_::rexplst1,_::rexplst2)
      then
        addSymbolicTransformationSubstitutionLst(brest,source,rexplst1,rexplst2);
  end match;
end addSymbolicTransformationSubstitutionLst;

function addSymbolicTransformationSubstitution
  input Boolean add;
  input output DAE.ElementSource source;
  input DAE.Exp exp1;
  input DAE.Exp exp2;
algorithm
  if not Flags.isSet(Flags.INFO_XML_OPERATIONS) then
    return;
  end if;
  source := condAddSymbolicTransformation(add,source,DAE.SUBSTITUTION({exp2},exp1));
end addSymbolicTransformationSubstitution;

function addSymbolicTransformationSimplifyLst
  input list<Boolean> add;
  input output DAE.ElementSource source;
  input list<DAE.Exp> explst1;
  input list<DAE.Exp> explst2;
algorithm
  if not Flags.isSet(Flags.INFO_XML_OPERATIONS) then
    return;
  end if;
  source := match(add,explst1,explst2)
    local
      list<Boolean> brest;
      list<DAE.Exp> rexplst1,rexplst2;
      DAE.Exp exp1,exp2;
    case({},_,_) then source;
    case(true::brest,exp1::rexplst1,exp2::rexplst2)
      equation
        source = addSymbolicTransformation(source, DAE.SIMPLIFY(DAE.PARTIAL_EQUATION(exp1),DAE.PARTIAL_EQUATION(exp2)));
      then
        addSymbolicTransformationSimplifyLst(brest,source,rexplst1,rexplst2);
    case(false::brest,_::rexplst1,_::rexplst2)
      then
        addSymbolicTransformationSimplifyLst(brest,source,rexplst1,rexplst2);
  end match;
end addSymbolicTransformationSimplifyLst;

function addSymbolicTransformationSimplify
  input Boolean add;
  input output DAE.ElementSource source;
  input DAE.EquationExp exp1;
  input DAE.EquationExp exp2;
algorithm
  if not Flags.isSet(Flags.INFO_XML_OPERATIONS) then
    return;
  end if;
  source := condAddSymbolicTransformation(add,source,DAE.SIMPLIFY(exp1,exp2));
end addSymbolicTransformationSimplify;

function addSymbolicTransformationSolve
  input Boolean add;
  input output DAE.ElementSource source;
  input DAE.ComponentRef cr;
  input DAE.Exp exp1;
  input DAE.Exp exp2;
  input DAE.Exp exp;
  input list<DAE.Statement> asserts;
protected
  DAE.SymbolicOperation op,op1,op2;
algorithm
  if not (add and Flags.isSet(Flags.INFO_XML_OPERATIONS)) then
    return;
  end if;
  op1 := DAE.SOLVE(cr,exp1,exp2,exp,list(Algorithm.getAssertCond(ass) for ass in asserts));
  op2 := DAE.SOLVED(cr,exp2) "If it was already on solved form";
  op := if Expression.expEqual(exp2,exp) then op2 else op1;
  source := addSymbolicTransformation(source,op);
end addSymbolicTransformationSolve;

function getSymbolicTransformations
  input DAE.ElementSource source;
  output list<DAE.SymbolicOperation> ops;
algorithm
  ops := source.operations;
end getSymbolicTransformations;

function getElementSource
  input DAE.Element element;
  output DAE.ElementSource source;
algorithm
  source := match element
    case DAE.VAR() then element.source;
    case DAE.DEFINE() then element.source;
    case DAE.INITIALDEFINE() then element.source;
    case DAE.EQUATION() then element.source;
    case DAE.EQUEQUATION() then element.source;
    case DAE.ARRAY_EQUATION() then element.source;
    case DAE.INITIAL_ARRAY_EQUATION() then element.source;
    case DAE.COMPLEX_EQUATION() then element.source;
    case DAE.INITIAL_COMPLEX_EQUATION() then element.source;
    case DAE.WHEN_EQUATION() then element.source;
    case DAE.IF_EQUATION() then element.source;
    case DAE.INITIAL_IF_EQUATION() then element.source;
    case DAE.INITIALEQUATION() then element.source;
    case DAE.ALGORITHM() then element.source;
    case DAE.INITIALALGORITHM() then element.source;
    case DAE.COMP() then element.source;
    case DAE.EXTOBJECTCLASS() then element.source;
    case DAE.ASSERT() then element.source;
    case DAE.TERMINATE() then element.source;
    case DAE.REINIT() then element.source;
    case DAE.NORETCALL() then element.source;
    case DAE.CONSTRAINT() then element.source;
    case DAE.INITIAL_NORETCALL() then element.source;

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"ElementSource.getElementSource failed: Element does not have a source"});
      then fail();
  end match;
end getElementSource;

function getStatementSource
  "Returns the element source associated with a statement."
  input DAE.Statement stmt;
  output DAE.ElementSource source;
algorithm
  source := match(stmt)
    case DAE.STMT_ASSIGN() then stmt.source;
    case DAE.STMT_TUPLE_ASSIGN() then stmt.source;
    case DAE.STMT_ASSIGN_ARR() then stmt.source;
    case DAE.STMT_IF() then stmt.source;
    case DAE.STMT_FOR() then stmt.source;
    case DAE.STMT_PARFOR() then stmt.source;
    case DAE.STMT_WHILE() then stmt.source;
    case DAE.STMT_WHEN() then stmt.source;
    case DAE.STMT_ASSERT() then stmt.source;
    case DAE.STMT_TERMINATE() then stmt.source;
    case DAE.STMT_REINIT() then stmt.source;
    case DAE.STMT_NORETCALL() then stmt.source;
    case DAE.STMT_RETURN() then stmt.source;
    case DAE.STMT_BREAK() then stmt.source;
    case DAE.STMT_ARRAY_INIT() then stmt.source;
    case DAE.STMT_FAILURE() then stmt.source;
  end match;
end getStatementSource;

function getElementSourceFileInfo
"Gets the file information associated with an element.
If there are several candidates, select the first one."
  input DAE.ElementSource source;
  output SourceInfo info;
algorithm
  info := source.info;
end getElementSourceFileInfo;

function getElementSourceTypes
"@author: adrpo
 retrieves the paths from the DAE.ElementSource.SOURCE.typeLst"
 input DAE.ElementSource source "the source of the element";
 output list<Absyn.Path> pathLst;
algorithm
  pathLst := source.typeLst;
end getElementSourceTypes;

function getElementSourceInstances
"@author: adrpo
 retrieves the paths from the DAE.ElementSource.SOURCE.instanceOpt"
 input DAE.ElementSource source "the source of the element";
 output Option<DAE.ComponentRef> instanceOpt;
algorithm
  instanceOpt := source.instanceOpt;
end getElementSourceInstances;

function getElementSourceConnects
"@author: adrpo
 retrieves the paths from the DAE.ElementSource.SOURCE.connectEquationOptLst"
 input DAE.ElementSource source "the source of the element";
 output list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst;
algorithm
  connectEquationOptLst := source.connectEquationOptLst;
end getElementSourceConnects;

function getElementSourcePartOfs
"@author: adrpo
 retrieves the withins from the DAE.ElementSource.SOURCE.partOfLst"
 input DAE.ElementSource source "the source of the element";
 output list<Absyn.Within> withinLst;
algorithm
  withinLst := source.partOfLst;
end getElementSourcePartOfs;

function addElementSourcePartOf
  input output DAE.ElementSource source;
  input Absyn.Within withinPath;
algorithm
  source.partOfLst := withinPath::source.partOfLst;
end addElementSourcePartOf;

function addElementSourcePartOfOpt
  input DAE.ElementSource inSource;
  input Option<Absyn.Path> classPathOpt;
  output DAE.ElementSource outSource;
algorithm
  outSource := match(inSource, classPathOpt)
    local
      Absyn.Path classPath;
      DAE.ElementSource src;
    // a top level
    case (_, NONE())
      equation
        _ = addElementSourcePartOf(inSource, Absyn.TOP());
      then inSource;
    case (_, SOME(classPath))
      equation
        src = addElementSourcePartOf(inSource, Absyn.WITHIN(classPath));
      then src;
  end match;
end addElementSourcePartOfOpt;

function addElementSourceFileInfo
  input DAE.ElementSource source;
  input SourceInfo fileInfo;
  output DAE.ElementSource outSource = source;
algorithm
  outSource.info := fileInfo;
end addElementSourceFileInfo;

function addElementSourceConnectOpt
  input DAE.ElementSource inSource;
  input Option<tuple<DAE.ComponentRef,DAE.ComponentRef>> connectEquationOpt;
  output DAE.ElementSource outSource;
algorithm
  outSource := match(inSource, connectEquationOpt)
    local
      SourceInfo info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Within> partOfLst "the models this element came from" ;
      Option<DAE.ComponentRef> instanceOpt "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;
      list<Absyn.Path> typeLst "the classes where the type of the element is defined" ;
      list<DAE.SymbolicOperation> operations;
      list<SCode.Comment> comment;

    // a top level
    case (_, NONE()) then inSource;
    case (DAE.SOURCE(info,partOfLst,instanceOpt,connectEquationOptLst,typeLst,operations,comment), _)
      then DAE.SOURCE(info,partOfLst,instanceOpt,connectEquationOpt::connectEquationOptLst,typeLst,operations,comment);
  end match;
end addElementSourceConnectOpt;

function addElementSourceType
  input DAE.ElementSource inSource;
  input Absyn.Path classPath;
  output DAE.ElementSource outSource;
algorithm
  outSource := match(inSource, classPath)
    local
      SourceInfo info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Path> typeLst "the absyn type of the element" ;
      list<Absyn.Within> partOfLst "the models this element came from" ;
      Option<DAE.ComponentRef> instanceOpt "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;
      list<DAE.SymbolicOperation> operations;
      list<SCode.Comment> comment;

    case (DAE.SOURCE(info, partOfLst, instanceOpt, connectEquationOptLst, typeLst, operations,comment), _)
      then DAE.SOURCE(info, partOfLst, instanceOpt, connectEquationOptLst, classPath::typeLst, operations,comment);
  end match;
end addElementSourceType;

protected

function addElementSourceInstanceOpt
  input DAE.ElementSource inSource;
  input Option<DAE.ComponentRef> instanceOpt;
  output DAE.ElementSource outSource;
algorithm
  outSource := match(inSource, instanceOpt)
    local
      SourceInfo info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Within> partOfLst "the models this element came from" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;
      list<Absyn.Path> typeLst "the classes where the type of the element is defined" ;
      list<DAE.SymbolicOperation> operations;
      list<SCode.Comment> comment;
      DAE.ComponentRef cr;

    // a NONE() means top level (equivalent to NO_PRE, SOME(cref) means subcomponent
    case (_, NONE())
      then inSource;
    case (DAE.SOURCE(info,partOfLst,_,connectEquationOptLst,typeLst,operations,comment), SOME(cr))
      then DAE.SOURCE(info,partOfLst,SOME(cr),connectEquationOptLst,typeLst,operations,comment);
  end match;
end addElementSourceInstanceOpt;

function addElementSourceTypeOpt
  input DAE.ElementSource inSource;
  input Option<Absyn.Path> classPathOpt;
  output DAE.ElementSource outSource;
algorithm
  outSource := match(inSource, classPathOpt)
    local
      Absyn.Path classPath;
      DAE.ElementSource src;
    case (_, NONE()) then inSource; // no source change.
    case (_, SOME(classPath))
      equation
        src = addElementSourceType(inSource, classPath);
      then src;
  end match;
end addElementSourceTypeOpt;

annotation(__OpenModelica_Interface="frontend");
end ElementSource;
