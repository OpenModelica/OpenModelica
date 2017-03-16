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
    output String f2;
  end int_string;  

  function real_string
    input Real g1;
    output Integer g3;
  end real_string;

  function numeric_string = $overload(int_string,real_string);
  
  function bool_string
    input Boolean g1;
    output Integer g3;
  end bool_string;
  
  function any_string = $overload(numeric_string,bool_string);  
  
  String x = any_string(true);
  String x = any_string(1);
  String x = any_string(1.0);
end FuncOverloadMulti;

// Result:
// function bool_string
//   input Boolean g1;
//   output Integer g3;
// end bool_string;
//
// function int_string
//   input Integer f1;
//   output String f2;
// end int_string;
//
// function real_string
//   input Real g1;
//   output Integer g3;
// end real_string;
//
// class FuncOverloadMulti
//   String x = bool_string(true);
//   String x = int_string(1);
//   String x = real_string(1.0);
// end FuncOverloadMulti;
// endResult
