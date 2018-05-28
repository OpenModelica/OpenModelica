// name: FuncOverloadMulti
// keywords: overload, cast
// status: correct
// cflags: -d=newInst
//
// Tests handling of multiple overload, i.e, and overload of overloaded function
//

model FuncOverloadMulti
  function int_string
    input Integer f1;
    output String f2 = "Integer";
  end int_string;

  function real_string
    input Real g1;
    output String g3 = "Real";
  end real_string;

  function numeric_string = $overload(int_string,real_string);

  function bool_string
    input Boolean g1;
    output String g3 = "Boolean";
  end bool_string;

  function type_string = $overload(numeric_string,bool_string);

  String x = type_string(true);
  String y = type_string(1);
  String z = type_string(1.0);
end FuncOverloadMulti;

// Result:
// function FuncOverloadMulti.bool_string
//   input Boolean g1;
//   output String g3 = "Boolean";
// end FuncOverloadMulti.bool_string;
//
// function FuncOverloadMulti.int_string
//   input Integer f1;
//   output String f2 = "Integer";
// end FuncOverloadMulti.int_string;
//
// function FuncOverloadMulti.real_string
//   input Real g1;
//   output String g3 = "Real";
// end FuncOverloadMulti.real_string;
//
// class FuncOverloadMulti
//   String x = FuncOverloadMulti.bool_string(true);
//   String y = FuncOverloadMulti.int_string(1);
//   String z = FuncOverloadMulti.real_string(1.0);
// end FuncOverloadMulti;
// endResult
