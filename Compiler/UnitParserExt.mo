package UnitParserExt "external package interface for UnitParser. Copyright MathCore engineering AB 2008"

public import UnitAbsyn;

public function initSIUnits "initialize the UnitParser with the SI units"
  external "C";
end initSIUnits;


public function unit2str"Translate a unit to a string"
  input list<Integer> noms "nominators";
  input list<Integer> denoms"denominators";
  input list<Integer> tpnoms ;
  input list<Integer> tpdenoms;
  input list<String> tpstrs;
  input Real scaleFactor;
  input Real offset;     
  output String res;
  external "C";  
end unit2str;

public function str2unit "Translate a unit string to a unit"
  input String res;
  output list<Integer> noms;
  output list<Integer> denoms;
  output list<Integer> tpnoms;
  output list<Integer> tpdenoms;
  output list<String> tpstrs;
  output Real scaleFactor;
  output Real offset;
  external "C";
end str2unit;

public function addBase "adds a base unit without weight"
  input String name;
  external "C";
end addBase;

public function registerWeight "registers a weight to be multiplied with the weigth factor of a derived unit"
  input String name;
  input Real weight;
  external "C";
end registerWeight;


public function addDerived "adds a derived unit without weight"
  input String name;
  input String exp;
  external "C";
end addDerived;

public function addDerivedWeight "adds a derived unit with weight"
  input String name;
  input String exp;
  input Real weight;
  external "C";
end addDerivedWeight;

public function checkpoint "copies all unitparser information to allow changing unit weights locally for a component"
   external "C";
end checkpoint;

public function rollback "rollback the copy made in checkPoint call"
  external "C";
end rollback;  

public function clear "clears the unitparser from stored units"
  external "C";
end clear;

public function commit "commits all units, must be run before doing unit checking and after last unit has been added
with addBase or addDerived."
  external "C";
end commit;

end UnitParserExt;
