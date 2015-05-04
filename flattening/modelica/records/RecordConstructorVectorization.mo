// name:     RecordConstructorVectorization.mo
// keywords: tests the vectorization of records
// status:   correct
//
// tests the vectorization of records. this is used in Modelica.Media
//
// more work is needed to get rid of the infinite recursion if the record extends from an unknown path.
// also, if nS is defined as size(substanceNames, 1) and used to define FluidConstants[nS] this test will fail!
//

package Crap

  constant String mediumName = "unusablePartialMedium" "Name of the medium";
  constant String substanceNames[:] = {mediumName} "Names of the mixture substances. Set substanceNames={mediumName} if only one substance.";

  constant Integer nS = 1; // size(substanceNames, 1) "Number of substances" annotation(Evaluate = true);

  replaceable record FluidConstants "critical, triple, molecular and other standard data of fluid"
    // extends Modelica.Icons.Record; // <--- infinite recursion if this is uncommented
    String iupacName "complete IUPAC name (or common name, if non-existent)";
    String casRegistryNumber "chemical abstracts sequencing number (if it exists)";
    String chemicalFormula "Chemical formula, (brutto, nomenclature according to Hill";
    String structureFormula "Chemical structure formula";
    annotation(Documentation(info = "<html></html>"));
  end FluidConstants;

  constant FluidConstants[2] fluidConstants =
     FluidConstants(iupacName = {"simple air","1"},
                    casRegistryNumber = {"not a real substance","2"},
                    chemicalFormula = {"N2, O2","3"},
                    structureFormula = {"N2, O2","4"}) "constant data for the fluid";

  record Whatever
    String x;
    Real y;
  end Whatever;
end Crap;

model RecordConstructorVectorization
  Crap.FluidConstants[:] fluidConstants = Crap.fluidConstants;
  Crap.Whatever w = Crap.Whatever("Shipot", 5.5);
 equation
  w = Crap.Whatever("Nothing", 4.7);
end RecordConstructorVectorization;

// Result:
// function Crap.FluidConstants "Automatically generated record constructor for Crap.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   output FluidConstants res;
// end Crap.FluidConstants;
//
// function Crap.Whatever "Automatically generated record constructor for Crap.Whatever"
//   input String x;
//   input Real y;
//   output Whatever res;
// end Crap.Whatever;
//
// class RecordConstructorVectorization
//   String fluidConstants[1].iupacName = "simple air" "complete IUPAC name (or common name, if non-existent)";
//   String fluidConstants[1].casRegistryNumber = "not a real substance" "chemical abstracts sequencing number (if it exists)";
//   String fluidConstants[1].chemicalFormula = "N2, O2" "Chemical formula, (brutto, nomenclature according to Hill";
//   String fluidConstants[1].structureFormula = "N2, O2" "Chemical structure formula";
//   String fluidConstants[2].iupacName = "1" "complete IUPAC name (or common name, if non-existent)";
//   String fluidConstants[2].casRegistryNumber = "2" "chemical abstracts sequencing number (if it exists)";
//   String fluidConstants[2].chemicalFormula = "3" "Chemical formula, (brutto, nomenclature according to Hill";
//   String fluidConstants[2].structureFormula = "4" "Chemical structure formula";
//   String w.x = "Shipot";
//   Real w.y = 5.5;
// equation
//   w.x = "Nothing";
//   w.y = 4.7;
// end RecordConstructorVectorization;
// endResult
