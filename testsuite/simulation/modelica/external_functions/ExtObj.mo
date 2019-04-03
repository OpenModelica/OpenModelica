// name:     ExternalObject
// keywords: ExternalObject
// status:   correct
//
// Testing the instantiation part of an external object.
//

package ExtObj
  class MyTable
    extends ExternalObject;
    function constructor
      input String fileName="";
      input String tableName="";
      input Real[:] vals={1,2,3};
      output MyTable outTable;

      external "C" outTable=initMyTable(fileName,tableName,vals,size(vals,1)) ;
      annotation(Include="#include \"ExtObj.h\"",Library="ExtObj.lib");
    end constructor;
    function destructor
          input MyTable inTable;

      external "C" closeMyTable(inTable) ;
      annotation(Include="#include \"ExtObj.h\"",Library="ExtObj.lib");
    end destructor;
  end MyTable;
  model ExtObjtest "define a new table and interpolate in it"
    //MyTable table=MyTable(fileName="testTables.txt", tableName="table1");
    MyTable myTable=MyTable("testTables.txt","table1",{1,2,3});
    Real y;

  equation
    y=interpolateMyTable(myTable, time);
  end ExtObjtest;
  function interpolateMyTable "Interpolate in table"
      input MyTable interpolTable;
    input Real u;
    output Real y;

    external "C" y=interpolateMyTable(interpolTable,u) ;

  end interpolateMyTable;
end ExtObj;

model testextobj
  ExtObj.ExtObjtest t;
end testextobj;
