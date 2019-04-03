// name:     testExternalObject
// keywords: external object
// cflags:   +i=ExtObjectTest.Ex
// status:   correct
//
// description: External object in extended class

package ExtObjectTest
  model Ex
    package ExtPackage1 = ExtPackage;
    ExtPackage1.ExtObj mapping = ExtPackage1.ExtObj();
  end Ex;

  package ExtPackage
    class ExtObj
      extends ExternalObject;
      function constructor
        output ExtObj mapping;
        external "C" mapping = initMapping();
      end constructor;
      function destructor
        input ExtObj mapping;
        external "C" destroyMapping(mapping);
      end destructor;
    end ExtObj;
  end ExtPackage;
end ExtObjectTest;

// Result:
// function ExtObjectTest.Ex.ExtPackage1.ExtObj.constructor
//   output ExtObjectTest.Ex.ExtPackage1.ExtObj mapping;
//
//   external "C" mapping = initMapping();
// end ExtObjectTest.Ex.ExtPackage1.ExtObj.constructor;
//
// function ExtObjectTest.Ex.ExtPackage1.ExtObj.destructor
//   input ExtObjectTest.Ex.ExtPackage1.ExtObj mapping;
//
//   external "C" destroyMapping(mapping);
// end ExtObjectTest.Ex.ExtPackage1.ExtObj.destructor;
//
// class ExtObjectTest.Ex
//   ExtObjectTest.Ex.ExtPackage1.ExtObj mapping = ExtObjectTest.Ex.ExtPackage1.ExtObj.constructor();
// end ExtObjectTest.Ex;
// endResult
