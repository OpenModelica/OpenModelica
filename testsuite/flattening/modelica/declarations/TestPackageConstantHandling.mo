// name:     TestPackageConstantHandling.mo
// keywords: declaration, import
// status:   correct
//
// test that the imported constant can be used
//

package TestPackage
  type MyType = Real;

  package Water
  import TestPackage.Water.ConstantPropertyLiquidWater.simpleWaterConstants;
  package ConstantPropertyLiquidWater
    constant MyType simpleWaterConstants = blah;
    constant MyType blah = 1.0;
  end ConstantPropertyLiquidWater;

  end Water;
end TestPackage;

model TestPackageConstantHandling
  constant TestPackage.MyType x = TestPackage.Water.simpleWaterConstants;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end TestPackageConstantHandling;


// Result:
// class TestPackageConstantHandling
//   constant Real x = 1.0;
// end TestPackageConstantHandling;
// endResult
