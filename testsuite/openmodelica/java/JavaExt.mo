package JavaTest

record myEmptyRecord
end myEmptyRecord;

record myRecord
  Integer a;
  Real b;
  Boolean c;
  String d;
end myRecord;

record nestedRecord
  myRecord rec;
  String desc;
end nestedRecord;

function NestedRecordExtIdent
  input nestedRecord rec;
  output nestedRecord out;
  external "Java" 'JavaExt.RecordToRecord'(rec,out);
end NestedRecordExtIdent;

function RecordToRecord
  input myRecord inRecord;
  output myRecord out;
  external "Java" 'JavaExt.RecordToRecord'(inRecord,out);
end RecordToRecord;

function RecordToString
  input myRecord inRecord;
  output String out;
  external "Java" out='JavaExt.RecordToString'(inRecord);
end RecordToString;

function EmptyRecordToString
  input myEmptyRecord inRecord;
  output String out;
  external "Java" out='JavaExt.RecordToString'(inRecord);
end EmptyRecordToString;

function SumArray
  input Integer x[:];
  output Integer y;
  external "Java" y='JavaExt.SumArray'(x);
end SumArray;

function arrayTestInteger
  input Integer x[:];
  output Integer y[size(x,1)];
  external "Java" 'JavaExt.testArrays'(x,y);
end arrayTestInteger;

function arrayTestReal
  input Real x[:,:,:];
  output Real y[size(x,1),size(x,2),size(x,3)];
  external "Java" 'JavaExt.testArrays'(x,y);
end arrayTestReal;

function arrayTestBoolean
  input Boolean x[:];
  output Boolean y[size(x,1)];
  external "Java" 'JavaExt.testArrays'(x,y);
end arrayTestBoolean;

function arrayTestString
  input String xstr[:];
  output String ystr[size(xstr,1)];
  external "Java" 'JavaExt.testArrays'(xstr,ystr);
end arrayTestString;

function JavaIntegerToInteger
  input Integer o;
  output Integer out;
  external "Java" out='JavaExt.IntegerToInteger'(o);
end JavaIntegerToInteger;

function JavaRealToReal
  input Real o;
  output Real out;
  external "Java" out='JavaExt.RealToReal'(o);
end JavaRealToReal;

function JavaStringToString
  input String o;
  output String out;
  external "Java" out='JavaExt.StringToString'(o);
end JavaStringToString;

function JavaBooleanToBoolean
  input Boolean o;
  output Boolean out;
  external "Java" out='JavaExt.BooleanToBoolean'(o);
end JavaBooleanToBoolean;

function JavaMultipleInOut
  input Real i0;
  input Real i1;
  input Real i2;
  input Real i3;
  output Real o0;
  output Real o1;
  output Real o2;
  output Real o3;
  external "Java" o3='JavaExt.MultipleIO'(i0,i1,i2,i3,o0,o1,o2);
end JavaMultipleInOut;

function GetOMCInternalValues
  input Integer in_i;
  input Real in_r;
  output Integer out_i;
  output Real out_r;
  output String out_s;
algorithm
  out_i := in_i+1;
  out_r := in_r+1.5;
  out_s := "Values from OMC";
end GetOMCInternalValues;

function GetJavaInternalValues
  input Integer in_i;
  input Real in_r;
  output Integer out_i;
  output Real out_r;
  output String out_s;
  external "Java" 'JavaExt.GetValuesFromOMCThroughJava'(in_i,in_r,out_i,out_r,out_s);
end GetJavaInternalValues;

function RunInteractiveTestsuite
  output String out;
  external "Java" out='JavaExt.RunInteractiveTestsuite'();
end RunInteractiveTestsuite;

/* MetaModelica / Interactive Tests */

function listIntegerIdent
  input list<Integer> lst;
  output list<Integer> out;
algorithm
  out := lst;
end listIntegerIdent;

function someToNone
  input Option<Integer> opt;
  output Option<Integer> out;
algorithm
  out := NONE();
end someToNone;

function tupleIdent
  input tuple<Integer,Integer> tup;
  output tuple<Integer,Integer> out;
algorithm
  out := tup;
end tupleIdent;

function ApplyIntOp
  input FuncIntToInt inFunc;
  input Integer i;
  output Integer outInt;

  partial function FuncIntToInt
    input Integer in1;
    output Integer out1;
  end FuncIntToInt;
algorithm
  outInt := inFunc(i);
end ApplyIntOp;

function anyToString
  input Type_a inTypeA;
  output String out;
  replaceable type Type_a subtypeof Any;
algorithm
  out := "OK";
end anyToString;

uniontype fruit
  record APPLE
  end APPLE;
  record PEAR
  end PEAR;
end fruit;

function uniontypeIdent
  input fruit in1;
  output fruit out;
algorithm
  out := in1;
end uniontypeIdent;

uniontype Expression
  record ADD
    Expression lhs;
    Expression rhs;
  end ADD;
  record SUB
    Expression lhs;
    Expression rhs;
  end SUB;
  record ICONST
    Integer value;
  end ICONST;
  record RCONST
    Real value;
  end RCONST;
  record IFEXP
    Boolean cond; // Simple test
    Expression trueExp;
    Expression falseExp;
  end IFEXP;
  record STRLEN
    String str;
  end STRLEN;
end Expression;

function calcExpressionDummy
  input Expression exp;
  output Integer out;
algorithm
  out := 6; // Because matchcontinue is not working yet
end calcExpressionDummy;

function calcExpressionMatchcontinue
  input Expression exp;
  output Integer out;
algorithm
  out := matchcontinue(exp)
  local
    Expression lhs,rhs;
    Integer lval,rval;
  case ADD(lhs,rhs)
    equation
      lval = calcExpressionMatchcontinue(lhs);
      rval = calcExpressionMatchcontinue(rhs);
    then lval+rval;
  case SUB(lhs,rhs)
    equation
      lval = calcExpressionMatchcontinue(lhs);
      rval = calcExpressionMatchcontinue(rhs);
    then lval-rval;
  case ICONST(rval)
    then rval;
  end matchcontinue;
end calcExpressionMatchcontinue;

function calcExpressionExtJava
  input Expression exp;
  output Real out;
  external "Java" out='JavaExt.calcExpression'(exp);
end calcExpressionExtJava;

function expIdentExtJava
  input Expression in1;
  output Expression out;
  external "Java" out='JavaExt.expIdent'(in1);
end expIdentExtJava;

function expIdentExtJava2
  input Expression in1;
  output Expression out;
  external "Java" 'JavaExt.expIdent'(in1,out);
end expIdentExtJava2;

function extJavaTestAllMMCTypes
  output Expression out;
  external "Java" out='JavaExt.testAllMMCTypes'();
end extJavaTestAllMMCTypes;

function extJavaParseProgramFromFile
  input String filename;
  output Boolean out;
  external "Java" out='JavaExt.RunProgramParseTest'(filename);
end extJavaParseProgramFromFile;

end JavaTest;
