// name:     RecursiveFunctionCall
// keywords: function, recursiive calls
// status:   correct
//
// Just checks so that function calling itself will work.


package pkg
 function factorial
   input Integer n;
   output Integer y;
 algorithm
   if n <= 1 then
     y:=1;
   else y:=n*factorial(n - 1);
   end if;
 end factorial;
end pkg;

model RecursiveFunctionCall
  Integer y;
algorithm
  y:=pkg.factorial(2);
end RecursiveFunctionCall;
// Result:
// function pkg.factorial
//   input Integer n;
//   output Integer y;
// algorithm
//   if n <= 1 then
//     y := 1;
//   else
//     y := n * pkg.factorial(-1 + n);
//   end if;
// end pkg.factorial;
//
// class RecursiveFunctionCall
//   Integer y;
// algorithm
//   y := 2;
// end RecursiveFunctionCall;
// endResult
