package Functions

import Types;

function test
  input String s;
  output Integer x;
algorithm
  x := matchcontinue s
         case "one"   then 1;
         case "two"   then 2;
         case "three" then 3;
         case _ then 0;
       end matchcontinue;
end test;

function factorial
  input Integer inValue;
  output Integer outValue;
algorithm
  outValue := matchcontinue inValue
    local Integer n;
    case 0 then 1;
    case n then n*factorial(n-1);
  end matchcontinue;
end factorial;

// an alias for the Real type
// type Alias = Real;
// constant Alias aliasConstant = 1.0;
function printAlias
  input Types.Alias aliasVariable;
algorithm
  print(realString(aliasVariable));
end printAlias;

// an option type which can be SOME(Alias) or NONE()
// type OptionType = Option<Alias>;
// constant OptionType optionAliasConstant = SOME(aliasConstant);
function printOptionType
  input Types.OptionType oVar;
algorithm
  _ := matchcontinue(oVar)
    local Types.Alias alias;
    case NONE()
      equation
        print("NONE()");
      then ();
    case SOME(alias)
      equation
        printAlias(alias);
      then ();
  end matchcontinue;
end printOptionType;

// a tuple type with 3 elements
//type TupleType = tuple<String, Alias, OptionType>;
//constant TupleType tupleConstant = ("a tuple element", aliasConstant, optionAliasConstant);
function printTupleType
  input Types.TupleType tupleVar;
algorithm
  _ := match (tupleVar)
    local
      Types.Alias alias;
      Types.OptionType optionAlias;
      String str;
    case ((str, alias, optionAlias))
      equation
        print("(");
        print("\"" + str + "\"");
        print(", ");
        printAlias(alias);
        print(", ");
        printOptionType(optionAlias);
        print(")");
      then ();
  end match;
end printTupleType;


// a list type
//type ListType = list<TupleType>;
//constant ListType listConstant = {tupleConstant, ("another element", 2.0, NONE())};
function printListType
  input Types.ListType listVar;
algorithm
  _ := matchcontinue(listVar)
    local
      Types.TupleType element;
      Types.ListType rest;
      String str;
    case ({}) then ();
    case (element::{})
      equation
        printTupleType(element);
      then ();
    case (element::rest)
      equation
        printTupleType(element);
        print(", ");
        printListType(rest);
      then ();
  end matchcontinue;
end printListType;


// complex record types
//record OneRecord
//  String k;
//  Alias z;
//end OneRecord;
//constant OneRecord oneRecord = OneRecord("first element", 3.0);
function printOneRecord
  input Types.OneRecord oneRecordVar;
algorithm
  _ := match (oneRecordVar)
    local
      String cmp1;
      Types.Alias cmp2;
    case (Types.OneRecord(cmp1, cmp2))
      equation
        print("OneRecord(");
        print("\"" + cmp1 + "\"");
        print(", ");
        printAlias(cmp2);
        print(")");
      then ();
  end match;
end printOneRecord;


// complex uniontypes
//uniontype Select

//  record FirstAlternative
//    String x1;
//    String x2;
//  end FirstAlternative;

//  record SecondAlternative
//    Select x1;
//    Select x2;
//  end SecondAlternative;
//
//  record ThirdAlternative
//    Select next;
//  end ThirdAlternative;
//end Select;

//constant Select select =
//  ThirdAlternative(
//    SecondAlternative(
//      FirstAlternative("one", "First"),
//      FirstAlternative("two", "Second")));
function printSelect
  input Types.Select selectVar;
algorithm
  _ := matchcontinue(selectVar)
    local
      String cmp1, cmp2;
      Types.Select sel1, sel2;
    case (Types.FirstAlternative(cmp1, cmp2))
      equation
        print("FirstAlternative(");
        print("\"" + cmp1 + "\"");
        print(", ");
        print("\"" + cmp2 + "\"");
        print(")");
      then ();
    case (Types.SecondAlternative(sel1, sel2))
      equation
        print("SecondAlternative(");
        printSelect(sel1);
        print(", ");
        printSelect(sel2);
        print(")");
      then ();
    case (Types.ThirdAlternative(sel1))
      equation
        print("ThirdAlternative(");
        printSelect(sel1);
        print(")");
      then ();
  end matchcontinue;
end printSelect;

end Functions;

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
     print("\nTypes.aliasConstant: ");
     Functions.printAlias(Types.aliasConstant);

     // print Types.optionAliasConstant
     print("\nTypes.optionAliasConstant: ");
     Functions.printOptionType(Types.optionAliasConstant);

     // print Types.optionAliasConstantNone
     print("\nTypes.optionAliasConstantNone: ");
     Functions.printOptionType(Types.optionAliasConstantNone);

     // print Types.tupleConstant
     print("\nTypes.tupleConstant: ");
     Functions.printTupleType(Types.tupleConstant);

     // print Types.listConstant
     print("\nTypes.listConstant: {");
     Functions.printListType(Types.listConstant);
     print("}");

     // print Types.oneRecord
     print("\nTypes.oneRecord: ");
     Functions.printOneRecord(Types.oneRecord);

     // print Types.select
     print("\nTypes.select: ");
     Functions.printSelect(Types.select);
 then ();
 end match;
end main;

end Main;
