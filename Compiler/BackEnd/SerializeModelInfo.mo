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
        Pack.map(pack,2);
        Pack.string(pack,"format");
        Pack.string(pack,"OpenModelica debug info");
        Pack.string(pack,"version");
        Pack.integer(pack,1);
        serializeVars(pack,vars);
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
      DAE.ElementSource source;
    case SimCode.SIMVAR()
      equation
        Pack.string(pack,crefStr(var.name));
        Pack.map(pack,2);
        Pack.string(pack,"comment");
        Pack.string(pack,var.comment);
        Pack.string(pack,"source");
        serializeSource(pack,var.source);
      then true;
  end match;
end serializeVar;

protected function serializeSource
  input Pack.Packer pack;
  input DAE.ElementSource source;
protected
  Absyn.Info info;
  list<Absyn.Path> typeLst;
  list<Absyn.Within> partOfLst;
  Option<DAE.ComponentRef> iopt;
  Integer i;
  Boolean withInstance;
  list<String> paths;
algorithm
  DAE.SOURCE(typeLst=typeLst,info=info,instanceOpt=iopt,partOfLst=partOfLst) := source;
  withInstance := Util.isSome(iopt);
  Pack.map(pack,3 + (if withInstance then 1 else 0));
  Pack.string(pack,"info");
  serializeInfo(pack,info);
  paths := list(match w case Absyn.WITHIN() then Absyn.pathString(w.path); end match
                for w guard (match w case Absyn.TOP() then false; else true; end match)
                in partOfLst);
  Pack.string(pack,"within");
  Pack.sequence(pack,listLength(paths));
  min(Pack.string(pack,s) for s in paths);

  if withInstance then
    Pack.string(pack,"instance");
    Pack.string(pack,crefStr(Util.getOption(iopt)));
  end if;
  Pack.string(pack,"typeLst");
  Pack.sequence(pack,listLength(typeLst));
  min(Pack.string(pack,Absyn.pathStringNoQual(ty)) for ty in typeLst);
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

end SerializeModelInfo;
