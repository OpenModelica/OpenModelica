package Main

import Types;
import Functions;

function main
 input list<String> arg;
algorithm
 _ := match arg
  local
    Integer i, n;
    String str, n_str;
  case (n_str::_)
   equation
     // factorial
     print("Factorial of " + n_str + " is: ");
     n = stringInt(n_str);
     i = Functions.factorial(n);
     str = intString(i);
     print(str);
     // test function
     print("\nCalling Functions.test(\"one\"):   " + intString(Functions.test("one")));
     print("\nCalling Functions.test(\"two\"):   " + intString(Functions.test("two")));
     print("\nCalling Functions.test(\"three\"): " + intString(Functions.test("three")));
     print("\nCalling Functions.test(\"other\"): " + intString(Functions.test("other")));

     // print Types.aliasConstant
     // your code here -- uncomment these when you wrote the functions
     // print("\nTypes.aliasConstant: ");
     // Functions.printAlias(Types.aliasConstant);

     // print Types.optionAliasConstant
     // your code here -- uncomment these when you wrote the functions
     // print("\nTypes.optionAliasConstant: ");
     // Functions.printOptionType(Types.optionAliasConstant);

     // print Types.optionAliasConstantNone
     // your code here -- uncomment these when you wrote the functions
     // print("\nTypes.optionAliasConstantNone: ");
     // Functions.printOptionType(Types.optionAliasConstantNone);

     // print Types.tupleConstant
     // your code here -- uncomment these when you wrote the functions
     // print("\nTypes.tupleConstant: ");
     // Functions.printTupleType(Types.tupleConstant);

     // print Types.listConstant
     // your code here -- uncomment these when you wrote the functions
     // print("\nTypes.listConstant: {");
     // Functions.printListType(Types.listConstant);
     // print("}");

     // print Types.oneRecord
     // your code here -- uncomment these when you wrote the functions
     // print("\nTypes.oneRecord: ");
     // Functions.printOneRecord(Types.oneRecord);

     // print Types.select
     // your code here -- uncomment these when you wrote the functions
     // print("\nTypes.select: ");
     // Functions.printSelect(Types.select);
 then ();
 end match;
end main;

end Main;
