encapsulated package SerializeModelInfo

import Absyn;
import DAE;
import MessagePack;
import SimCode;

protected
import Error;
import MessagePack.Pack.SimpleBuffer;
import MessagePack.Pack;
import MessagePack.Utilities;
import crefStr = ComponentReference.printComponentRefStrFixDollarDer;

public function serialize
  input SimCode.SimCode code;
algorithm
  true := serializeWork(code);
end serialize;

protected function serializeWork "Always succeeds in order to clean-up external objects"
  input SimCode.SimCode code;
  output Boolean success; // We always need to return
protected
  SimpleBuffer.SimpleBuffer sb = SimpleBuffer.SimpleBuffer();
  Pack.Packer pack = Pack.Packer(sb);
algorithm
  success := matchcontinue code
    local
      String fileName;
      SimCode.ModelInfo mi;
      SimCode.SimVars vars;
    case SimCode.SIMCODE(modelInfo=mi as SimCode.MODELINFO(vars=vars))
      equation
        fileName = code.fileNamePrefix + "_info.msgpack";
        print(fileName + "\n");
        Pack.map(pack,2);
        Pack.string(pack,"format");
        Pack.string(pack,"OpenModelica debug info");
        Pack.string(pack,"version");
        Pack.integer(pack,1);
        serializeVars(pack,vars);
        SimpleBuffer.writeFile(sb,fileName);
      then true;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SerializeModelInfo.serialize failed"});
      then false;
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
        i=listLength(vars.stateVars) + listLength(vars.derivativeVars) + listLength(vars.algVars) + listLength(vars.intAlgVars) +
          listLength(vars.boolAlgVars) + listLength(vars.inputVars) + listLength(vars.intAliasVars)+ listLength(vars.boolAliasVars) +
          listLength(vars.paramVars) + listLength(vars.intParamVars) + listLength(vars.boolParamVars) + listLength(vars.stringAlgVars) +
          listLength(vars.stringParamVars) + listLength(vars.stringAliasVars) + listLength(vars.extObjVars) + listLength(vars.constVars) + listLength(vars.jacobianVars);
        Pack.map(pack,i);
        true = min(serializeVar(pack,v) for v in vars.stateVars);
        true = min(serializeVar(pack,v) for v in vars.derivativeVars);
        true = min(serializeVar(pack,v) for v in vars.algVars);
        true = min(serializeVar(pack,v) for v in vars.intAlgVars);
        true = min(serializeVar(pack,v) for v in vars.boolAlgVars);
        true = min(serializeVar(pack,v) for v in vars.inputVars);
        true = min(serializeVar(pack,v) for v in vars.intAliasVars);
        true = min(serializeVar(pack,v) for v in vars.boolAliasVars);
        true = min(serializeVar(pack,v) for v in vars.paramVars);
        true = min(serializeVar(pack,v) for v in vars.intParamVars);
        true = min(serializeVar(pack,v) for v in vars.boolParamVars);
        true = min(serializeVar(pack,v) for v in vars.stringAlgVars);
        true = min(serializeVar(pack,v) for v in vars.stringParamVars);
        true = min(serializeVar(pack,v) for v in vars.stringAliasVars);
        true = min(serializeVar(pack,v) for v in vars.extObjVars);
        true = min(serializeVar(pack,v) for v in vars.constVars);
        true = min(serializeVar(pack,v) for v in vars.jacobianVars);
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
      Absyn.Info info;
    case SimCode.SIMVAR(source=DAE.SOURCE(info=info))
      equation
        Pack.string(pack,crefStr(var.name));
        Pack.map(pack,2);
        Pack.string(pack,"comment");
        Pack.string(pack,var.comment);
        Pack.string(pack,"info");
        serializeInfo(pack,info);
      then true;
  end match;
end serializeVar;

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

/*
    DAE.ComponentRef name;
    BackendDAE.VarKind varKind;
    String comment;
    String unit;
    String displayUnit;
    Integer index;
    Option<DAE.Exp> minValue;
    Option<DAE.Exp> maxValue;
    Option<DAE.Exp> initialValue;
    Option<DAE.Exp> nominalValue;
    Boolean isFixed;
    DAE.Type type_;
    Boolean isDiscrete;
    // arrayCref is the name of the array if this variable is the first in that
    // array
    Option<DAE.ComponentRef> arrayCref;
    AliasVariable aliasvar;
    DAE.ElementSource source;
    Causality causality;
    Option<Integer> variable_index;
    list<String> numArrayElement;
    Boolean isValueChangeable;
    Boolean isProtected;
*/

end SerializeModelInfo;
