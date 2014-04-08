encapsulated package SerializeModelInfo

import Absyn;
import BackendDAE;
import DAE;
import MessagePack;
import SimCode;

protected
import DAEDump;
import Error;
import Expression;
import MessagePack.Pack.SimpleBuffer;
import MessagePack.Pack;
import MessagePack.Utilities;
import crefStr = ComponentReference.printComponentRefStrFixDollarDer;
import expStr = ExpressionDump.printExpStr;
import List;
import SCodeDump;
import Util;

public function serialize
  input SimCode.SimCode code;
  output String fileName;
algorithm
  (true,fileName) := serializeWork(code);
end serialize;

protected function serializeWork "Always succeeds in order to clean-up external objects"
  input SimCode.SimCode code;
  output Boolean success; // We always need to return
  output String fileName;
protected
  SimpleBuffer.SimpleBuffer sb = SimpleBuffer.SimpleBuffer();
  Pack.Packer pack = Pack.Packer(sb);
algorithm
  (success,fileName) := matchcontinue code
    local
      SimCode.ModelInfo mi;
      SimCode.SimVars vars;
    case SimCode.SIMCODE(modelInfo=mi as SimCode.MODELINFO(vars=vars))
      equation
        fileName = code.fileNamePrefix + "_info.msgpack";
        print(fileName + "\n");
        Pack.map(pack,3);
        Pack.string(pack,"format");
        Pack.string(pack,"OpenModelica debug info");
        Pack.string(pack,"version");
        Pack.integer(pack,1);
        Pack.string(pack,"equation-sections");
        Pack.sequence(pack,1);
        Pack.string(pack,"initial");
        serializeVars(pack,vars);
        min(serializeEquation(pack,eq,"initial") for eq in code.initialEquations);
        SimpleBuffer.writeFile(sb,fileName);
      then (true,fileName);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SerializeModelInfo.serialize failed"});
      then (false,"");
  end matchcontinue;
end serializeWork;

protected function serializeVars
  input Pack.Packer pack;
  input SimCode.SimVars vars;
algorithm
  _ := matchcontinue vars
    local
      Integer i;
    case SimCode.SIMVARS()
      equation
/*
        i=listLength(vars.stateVars) + listLength(vars.derivativeVars) + listLength(vars.algVars) + listLength(vars.intAlgVars) +
          listLength(vars.boolAlgVars) + listLength(vars.inputVars) + listLength(vars.intAliasVars)+ listLength(vars.boolAliasVars) +
          listLength(vars.paramVars) + listLength(vars.intParamVars) + listLength(vars.boolParamVars) + listLength(vars.stringAlgVars) +
          listLength(vars.stringParamVars) + listLength(vars.stringAliasVars) + listLength(vars.extObjVars) + listLength(vars.constVars) + listLength(vars.jacobianVars);
        Pack.map(pack,i);
*/
        min(serializeVar(pack,v) for v in vars.stateVars);
        min(serializeVar(pack,v) for v in vars.derivativeVars);
        min(serializeVar(pack,v) for v in vars.algVars);
        min(serializeVar(pack,v) for v in vars.intAlgVars);
        min(serializeVar(pack,v) for v in vars.boolAlgVars);
        min(serializeVar(pack,v) for v in vars.inputVars);
        min(serializeVar(pack,v) for v in vars.intAliasVars);
        min(serializeVar(pack,v) for v in vars.boolAliasVars);
        min(serializeVar(pack,v) for v in vars.paramVars);
        min(serializeVar(pack,v) for v in vars.intParamVars);
        min(serializeVar(pack,v) for v in vars.boolParamVars);
        min(serializeVar(pack,v) for v in vars.stringAlgVars);
        min(serializeVar(pack,v) for v in vars.stringParamVars);
        min(serializeVar(pack,v) for v in vars.stringAliasVars);
        min(serializeVar(pack,v) for v in vars.extObjVars);
        min(serializeVar(pack,v) for v in vars.constVars);
        min(serializeVar(pack,v) for v in vars.jacobianVars);
      then ();
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SerializeModelInfo.serializeVars failed"});
      then fail();
  end matchcontinue;
end serializeVars;

protected function serializeVar
  input Pack.Packer pack;
  input SimCode.SimVar var;
  output Boolean ok;
algorithm
  ok := match var
    local
      DAE.ElementSource source;
    case SimCode.SIMVAR()
      equation
        Pack.map(pack,7);
        Pack.string(pack,"name");
        Pack.string(pack,crefStr(var.name));
        Pack.string(pack,"comment");
        Pack.string(pack,var.comment);
        Pack.string(pack,"variability");
        serializeVarKind(pack,var.varKind);
        Pack.string(pack,"type");
        serializeTypeName(pack,var.type_);
        Pack.string(pack,"unit");
        Pack.string(pack,var.unit);
        Pack.string(pack,"displayUnit");
        Pack.string(pack,var.displayUnit);
        Pack.string(pack,"source");
        serializeSource(pack,var.source);
      then true;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SerializeModelInfo.serializeVar failed"});
      then false;
  end match;
end serializeVar;

protected function serializeTypeName
  input Pack.Packer pack;
  input DAE.Type ty;
  output Boolean b;
algorithm
  b := match ty
    case DAE.T_REAL() then Pack.string(pack,"Real");
    case DAE.T_INTEGER() then Pack.string(pack,"Integer");
    case DAE.T_STRING() then Pack.string(pack,"String");
    case DAE.T_BOOL() then Pack.string(pack,"Boolean");
    case DAE.T_ENUMERATION() then Pack.string(pack,"Enumeration");
    else Pack.nil(pack);
  end match;
end serializeTypeName;

protected function serializeSource
  input Pack.Packer pack;
  input DAE.ElementSource source;
protected
  Absyn.Info info;
  list<Absyn.Path> typeLst;
  list<Absyn.Within> partOfLst;
  Option<DAE.ComponentRef> iopt;
  Integer i;
  Boolean withInstance,withWithin,withTypeLst;
  list<String> paths;
  list<DAE.SymbolicOperation> operations;
algorithm
  DAE.SOURCE(typeLst=typeLst,info=info,instanceOpt=iopt,partOfLst=partOfLst,operations=operations) := source;
  withInstance := Util.isSome(iopt);
  withWithin := not List.isEmpty(partOfLst);
  withTypeLst := not List.isEmpty(typeLst);
  Pack.map(pack,2 + (if withInstance then 1 else 0) + (if withWithin then 1 else 0) + (if withTypeLst then 1 else 0));
  Pack.string(pack,"info");
  serializeInfo(pack,info);

  if withWithin then
    paths := list(match w case Absyn.WITHIN() then Absyn.pathString(w.path); end match
                  for w guard (match w case Absyn.TOP() then false; else true; end match)
                  in partOfLst);
    Pack.string(pack,"within");
    Pack.sequence(pack,listLength(paths));
    min(Pack.string(pack,s) for s in paths);
  end if;

  if withInstance then
    Pack.string(pack,"instance");
    Pack.string(pack,crefStr(Util.getOption(iopt)));
  end if;

  if withTypeLst then
    Pack.string(pack,"typeLst");
    Pack.sequence(pack,listLength(typeLst));
    min(Pack.string(pack,Absyn.pathStringNoQual(ty)) for ty in typeLst);
  end if;

  Pack.string(pack,"operations");
  Pack.sequence(pack,listLength(operations));
  min(serializeOperation(pack,op) for op in operations);
end serializeSource;

protected function serializeInfo
  input Pack.Packer pack;
  input Absyn.Info info;
algorithm
  _ := match i as info
    case Absyn.INFO()
      equation
        Pack.map(pack, 5);
        Pack.string(pack, "file");
        Pack.string(pack, i.fileName);
        Pack.string(pack, "lineStart");
        Pack.integer(pack, i.lineNumberStart);
        Pack.string(pack, "lineEnd");
        Pack.integer(pack, i.lineNumberEnd);
        Pack.string(pack, "colStart");
        Pack.integer(pack, i.columnNumberStart);
        Pack.string(pack, "colEnd");
        Pack.integer(pack, i.columnNumberEnd);
      then ();
  end match;
end serializeInfo;

protected function serializeOperation
  input Pack.Packer pack;
  input DAE.SymbolicOperation op;
  output Boolean success;
algorithm
  success := match op
    local
      DAE.Element elt;
    case DAE.FLATTEN(dae=SOME(elt))
      equation
        Pack.map(pack,3);
        Pack.string(pack,"op");
        Pack.string(pack,"before-after");
        Pack.string(pack,"display");
        Pack.string(pack,"flattening");
        Pack.string(pack,"data");
        Pack.sequence(pack,2);
        Pack.string(pack,SCodeDump.equationStr(op.scode,SCodeDump.defaultOptions));
        Pack.string(pack,DAEDump.dumpEquationStr(elt));
      then true;
    case DAE.FLATTEN()
      equation
        Pack.map(pack,3);
        Pack.string(pack,"op");
        Pack.string(pack,"before-after");
        Pack.string(pack,"display");
        Pack.string(pack,"flattening");
        Pack.string(pack,"data");
        Pack.sequence(pack,1);
        Pack.string(pack,SCodeDump.equationStr(op.scode,SCodeDump.defaultOptions));
      then true;
    case DAE.SIMPLIFY()
      equation
        Pack.map(pack,3);
        Pack.string(pack,"op");
        Pack.string(pack,"before-after");
        Pack.string(pack,"display");
        Pack.string(pack,"simplify");
        Pack.string(pack,"data");
        Pack.sequence(pack,2);
        Pack.string(pack,eqExpStr(op.before));
        Pack.string(pack,eqExpStr(op.after));
      then true;
    case DAE.OP_INLINE()
      equation
        Pack.map(pack,3);
        Pack.string(pack,"op");
        Pack.string(pack,"before-after");
        Pack.string(pack,"display");
        Pack.string(pack,"inline");
        Pack.string(pack,"data");
        Pack.sequence(pack,2);
        Pack.string(pack,eqExpStr(op.before));
        Pack.string(pack,eqExpStr(op.after));
      then true;
    case DAE.SOLVE(assertConds={})
      equation
        Pack.map(pack,3);
        Pack.string(pack,"op");
        Pack.string(pack,"before-after");
        Pack.string(pack,"display");
        Pack.string(pack,"solved");
        Pack.string(pack,"data");
        Pack.sequence(pack,2);
        Pack.string(pack,expStr(op.exp1) + " = " + expStr(op.exp2));
        Pack.string(pack,crefStr(op.cr) + " = " + expStr(op.res));
      then true;
    case DAE.SOLVE()
      equation
        Pack.map(pack,3);
        Pack.string(pack,"op");
        Pack.string(pack,"before-after-assert");
        Pack.string(pack,"display");
        Pack.string(pack,"solved");
        Pack.string(pack,"data");
        Pack.sequence(pack,3);
        Pack.string(pack,expStr(op.exp1) + " = " + expStr(op.exp2));
        Pack.string(pack,crefStr(op.cr) + " = " + expStr(op.res));
        Pack.sequence(pack,listLength(op.assertConds));
        min(Pack.string(pack,expStr(e)) for e in op.assertConds);
      then true;
    case DAE.OP_RESIDUAL()
      equation
        Pack.map(pack,3);
        Pack.string(pack,"op");
        Pack.string(pack,"before-after-assert");
        Pack.string(pack,"display");
        Pack.string(pack,"residual");
        Pack.string(pack,"data");
        Pack.sequence(pack,2);
        Pack.string(pack,expStr(op.e1) + " = " + expStr(op.e2));
        Pack.string(pack,"0 = " + expStr(op.e));
      then true;
    case DAE.SUBSTITUTION()
      equation
        Pack.map(pack,3);
        Pack.string(pack,"op");
        Pack.string(pack,"chain");
        Pack.string(pack,"display");
        Pack.string(pack,"substitution");
        Pack.string(pack,"data");
        Pack.sequence(pack,1+listLength(op.substitutions));
        Pack.string(pack,expStr(op.source));
        min(Pack.string(pack,expStr(e)) for e in op.substitutions);
      then true;
    case DAE.SOLVED()
      equation
        Pack.map(pack,3);
        Pack.string(pack,"op");
        Pack.string(pack,"info");
        Pack.string(pack,"display");
        Pack.string(pack,"solved");
        Pack.string(pack,"data");
        Pack.sequence(pack,1);
        Pack.string(pack,crefStr(op.cr) + " = " + expStr(op.exp));
      then true;
      // Custom operations - operations that can not be described in a general way because they are specialized
    case DAE.OP_DIFFERENTIATE()
      equation
        Pack.map(pack,2);
        Pack.string(pack,"op");
        Pack.string(pack,"differentiate");
        Pack.string(pack,"data");
        Pack.sequence(pack,3);
        Pack.string(pack,crefStr(op.cr));
        Pack.string(pack,expStr(op.before));
        Pack.string(pack,expStr(op.after));
      then true;

    case DAE.OP_SCALARIZE()
      equation
        Pack.map(pack,2);
        Pack.string(pack,"op");
        Pack.string(pack,"scalarize");
        Pack.string(pack,"data");
        Pack.sequence(pack,3);
        Pack.string(pack,eqExpStr(op.before));
        Pack.integer(pack,op.index);
        Pack.string(pack,eqExpStr(op.after));
      then true;
    else
      equation
        Pack.nil(pack);
      then false;
  end match;
end serializeOperation;

protected function serializeEquation
  input Pack.Packer pack;
  input SimCode.SimEqSystem eq;
  input String section;
  output Boolean success;
algorithm
  success := match eq
    local
      Integer i,j;
    case SimCode.SES_RESIDUAL()
      equation
        Pack.map(pack, 7);
        Pack.string(pack, "eqIndex");
        Pack.integer(pack, eq.index);
        Pack.string(pack, "section");
        Pack.string(pack, section);
        Pack.string(pack, "tag");
        Pack.string(pack, "residual");
        Pack.string(pack, "defines");
        Pack.sequence(pack, 0);
        Pack.string(pack, "uses");
        serializeUses(pack,Expression.extractUniqueCrefsFromExp(eq.exp));
        Pack.string(pack, "equation");
        Pack.sequence(pack, 1);
        Pack.string(pack,expStr(eq.exp));
        Pack.string(pack, "source");
        serializeSource(pack,eq.source);
      then true;
    case SimCode.SES_SIMPLE_ASSIGN()
      equation
        Pack.map(pack, 7);
        Pack.string(pack, "eqIndex");
        Pack.integer(pack, eq.index);
        Pack.string(pack, "section");
        Pack.string(pack, section);
        Pack.string(pack, "tag");
        Pack.string(pack, "assign");
        Pack.string(pack, "defines");
        Pack.sequence(pack, 1);
        Pack.string(pack, crefStr(eq.cref));
        Pack.string(pack, "uses");
        serializeUses(pack,Expression.extractUniqueCrefsFromExp(eq.exp));
        Pack.string(pack, "equation");
        Pack.sequence(pack, 1);
        Pack.string(pack,expStr(eq.exp));
        Pack.string(pack, "source");
        serializeSource(pack,eq.source);
      then true;
    case SimCode.SES_ARRAY_CALL_ASSIGN()
      equation
        Pack.map(pack, 7);
        Pack.string(pack, "eqIndex");
        Pack.integer(pack, eq.index);
        Pack.string(pack, "section");
        Pack.string(pack, section);
        Pack.string(pack, "tag");
        Pack.string(pack, "assign");
        Pack.string(pack, "defines");
        Pack.sequence(pack, 1);
        Pack.string(pack,crefStr(eq.componentRef));
        Pack.string(pack, "uses");
        serializeUses(pack,Expression.extractUniqueCrefsFromExp(eq.exp));
        Pack.string(pack, "equation");
        Pack.sequence(pack, 1);
        Pack.string(pack,expStr(eq.exp));
        Pack.string(pack, "source");
        serializeSource(pack,eq.source);
      then true;
    case SimCode.SES_LINEAR()
      equation
        i = listLength(eq.beqs);
        j = listLength(eq.simJac);
        Pack.map(pack, 4);
        Pack.string(pack, "eqIndex");
        Pack.integer(pack, eq.index);
        Pack.string(pack, "section");
        Pack.string(pack, section);
        Pack.string(pack, "tag");
        Pack.string(pack, "linear"); // Ax=b
        Pack.string(pack, "defines");
        Pack.sequence(pack, i);
        min(match v case SimCode.SIMVAR() equation Pack.string(pack,crefStr(v.name)); then true; end match
            for v in eq.vars);
        Pack.string(pack, "equation");
        Pack.map(pack, 4);
        Pack.string(pack,"size");
        Pack.integer(pack,i);
        Pack.string(pack,"density");
        Pack.double(pack,j / (i*i));
        Pack.string(pack,"A");
        Pack.sequence(pack,j);
        min(serializeLinearCell(pack,cell) for cell in eq.simJac);
        Pack.string(pack,"b");
        Pack.sequence(pack,i);
        min(Pack.string(pack,expStr(exp)) for exp in eq.beqs);
//        Pack.string(pack, "source");
//        serializeSource(pack,eq.source);
      then true;

    else
      equation
        Pack.map(pack, 1);
        Pack.string(pack, "failed");
        Pack.string(pack, "translation of equation failed");
      then true;
  end match;
end serializeEquation;

protected function serializeLinearCell
  input Pack.Packer pack;
  input tuple<Integer, Integer, SimCode.SimEqSystem> cell;
  output Boolean success;
algorithm
  success := match cell
    local
      Integer i,j;
      SimCode.SimEqSystem eq;
    case (i,j,eq as SimCode.SES_RESIDUAL())
      equation
        Pack.map(pack,4);
        Pack.string(pack,"row");
        Pack.integer(pack,i);
        Pack.string(pack,"column");
        Pack.integer(pack,j);
        Pack.string(pack,"exp");
        Pack.string(pack,expStr(eq.exp));
        Pack.string(pack,"source");
        serializeSource(pack,eq.source);
      then true;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"SerializeModelInfo.serializeLinearCell failed. Expected only SES_RESIDUAL as input."});
      then fail();
  end match;
end serializeLinearCell;

protected function serializeVarKind
  input Pack.Packer pack;
  input BackendDAE.VarKind varKind;
algorithm
  _ := match varKind
    case BackendDAE.VARIABLE()
      equation
        Pack.string(pack,"variable");
      then ();
    case BackendDAE.STATE()
      equation
        Pack.string(pack,"state"); // Output number of times it was differentiated?
      then ();
    case BackendDAE.STATE_DER()
      equation
        Pack.string(pack,"derivative");
      then ();
    case BackendDAE.DUMMY_DER()
      equation
        Pack.string(pack,"dummy derivative");
      then ();
    case BackendDAE.DUMMY_STATE()
      equation
        Pack.string(pack,"dummy state");
      then ();
    case BackendDAE.DISCRETE()
      equation
        Pack.string(pack,"discrete");
      then ();
    case BackendDAE.PARAM()
      equation
        Pack.string(pack,"parameter");
      then ();
    case BackendDAE.CONST()
      equation
        Pack.string(pack,"constant");
      then ();
    case BackendDAE.EXTOBJ()
      equation
        Pack.string(pack,"external object");
      then ();
    case BackendDAE.JAC_VAR()
      equation
        Pack.string(pack,"jacobian variable");
      then ();
    case BackendDAE.JAC_DIFF_VAR()
      equation
        Pack.string(pack,"jacobian differentiated variable");
      then ();
    case BackendDAE.OPT_CONSTR()
      equation
        Pack.string(pack,"constraint");
      then ();
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"serializeVarKind failed"});
      then fail();
  end match;
end serializeVarKind;

protected function serializeUses
  input Pack.Packer pack;
  input list<DAE.ComponentRef> crefs;
algorithm
  Pack.sequence(pack, listLength(crefs));
  min(Pack.string(pack, crefStr(cr)) for cr in crefs);
end serializeUses;

protected function eqExpStr
  input DAE.EquationExp eqExp;
  output String str;
algorithm
  str := match eqExp
    case DAE.PARTIAL_EQUATION() then expStr(eqExp.exp);
    case DAE.RESIDUAL_EXP() then "0 = " + expStr(eqExp.exp);
    case DAE.EQUALITY_EXPS() then expStr(eqExp.lhs) + " = " + expStr(eqExp.rhs);
  end match;
end eqExpStr;

end SerializeModelInfo;
