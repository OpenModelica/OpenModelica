package Main

import Types;
import Functions;

function main
  input list<String> arg;
algorithm
  _ := matchcontinue arg
    local
      list<Integer> orderedIntList;
      list<String> orderedStringList, stringList, strRealLst, strIntLst;
      list<Real> orderedRealList, realList;
    case (_)
      equation
        // your code here:
        // order the initial Int list
        // orderedIntList    = Functions.orderList(Types.intList, Functions.compareInt);
        // transform the ordered list to String for printing
        // strIntLst = Functions.map1(orderedIntList, Functions.transformInt2String);
        // print("Int String List:");
        // Functions.map0(strIntLst, Functions.printElement);

        // transforming the initial int list to a String list
        // stringList = Functions.map1(Types.intList, Functions.transformInt2String);
        // order the transformed String list
        // orderedStringList = Functions.orderList(stringList, Functions.compareString);
        // print("\nOrdered String List:");
        // Functions.map0(orderedStringList, Functions.printElement);

        // transforming the int list to a Real list
        // realList = Functions.map1(Types.intList, Functions.transformInt2Real);
        // order the transformed Real list
        // orderedRealList = Functions.orderList(realList, Functions.compareReal);
        // strRealLst = Functions.map1(orderedRealList, Functions.transformReal2String);
        // print("\nOrdered Real List:");
        // Functions.map0(strIntLst, Functions.printElement);
        print("\n");
      then ();
  end matchcontinue;
end main;

end Main;

