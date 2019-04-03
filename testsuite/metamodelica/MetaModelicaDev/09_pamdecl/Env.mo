package Env

type Ident = String;

uniontype Value
  record INTVAL
    Integer integer;
  end INTVAL;

  record REALVAL
    Real real;
  end REALVAL;

  record BOOLVAL
    Boolean boolean;
  end BOOLVAL;

end Value;

uniontype Value2
  record INTVAL2
    Integer integer1;
    Integer integer2;
  end INTVAL2;

  record REALVAL2
    Real real1;
    Real real2;
  end REALVAL2;

end Value2;

uniontype Type
  record INTTYPE end INTTYPE;

  record REALTYPE end REALTYPE;

  record BOOLTYPE end BOOLTYPE;

end Type;

uniontype Bind
  record BIND
    Ident ident;
    Type type_;
    Value value;
  end BIND;

end Bind;

type Env = list<Bind>;

function initial_
  output BindLst outBindLst;
  type BindLst = list<Bind>;
algorithm
  outBindLst:=
  matchcontinue ()
    case () then {BIND("false",BOOLTYPE(),BOOLVAL(false)),
          BIND("true",BOOLTYPE(),BOOLVAL(true))};
  end matchcontinue;
end initial_;

function lookup
  input Env inEnv;
  input Ident inIdent;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inEnv,inIdent)
    local
      Ident idenv,id;
      Value v;
      Env rest;
    case ((BIND(ident = idenv,value = v) :: rest),id)
      then if id == idenv then v else lookup(rest, id);
  end matchcontinue;
end lookup;

function lookuptype
  input Env inEnv;
  input Ident inIdent;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inEnv,inIdent)
    local
      Ident idenv,id;
      Type t;
      Env rest;
    case ((BIND(ident = idenv,type_ = t) :: rest),id)
      then if id == idenv then t else lookuptype(rest, id);
  end matchcontinue;
end lookuptype;

function update
  input Env env;
  input Ident id;
  input Type ty;
  input Value v;
  output Env newenv;
algorithm
  newenv := (BIND(id,ty,v) :: env);
end update;
end Env;

