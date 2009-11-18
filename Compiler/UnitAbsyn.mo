package UnitAbsyn " Copyright MathCore 2008.
author Peter Aronsson (peter.aronsson@mathcore.com)

This module contains the datatypes for representing unit terms.
"

public import DAE;
public import MMath;
public import HashTable;

public uniontype UnitCheckResult
  record CONSISTENT end CONSISTENT;  // May be complete or incomplete
  record INCONSISTENT 
     SpecUnit u1;  //Left unit    
     SpecUnit u2;  //Right unit    
  end INCONSISTENT;
end UnitCheckResult;

public   
uniontype SpecUnit   
  record SPECUNIT " "
    list<tuple<MMath.Rational,TypeParameter>> typeParameters "A type parameter also has an exponent."; 
    list<MMath.Rational> units "first seven elements are the SI base units";
  end SPECUNIT;
end SpecUnit;

public
uniontype TypeParameter
  record TYPEPARAMETER
    String name "a type parameter name has the form identifier followed by a apostrophe, e.g. p' ";
    Integer indx "indx in Store";
  end TYPEPARAMETER;
end TypeParameter;

public
uniontype Unit "A unit is either specified (including type parameters) or unspecified"
  
  record SPECIFIED " A specified unit"
    SpecUnit specified;
  end  SPECIFIED;
 
 record UNSPECIFIED "Unpspecified unit means that the unit is unknown and should be inferred" end UNSPECIFIED;  
end Unit;

public
uniontype UnitTerm "A unit term is either 
 - a binary operation, e.g. multiplication, addition, etc. 
 - an equation (equality)
 - a location with unique id
 "
  record ADD "addition ut1+ut2" 
    UnitTerm ut1 "left";
    UnitTerm ut2 "right";
    DAE.Exp origExp "for proper error reporting";
  end ADD;
  
  record SUB "subtraction ut1-ut2"
    UnitTerm ut1 "left";
    UnitTerm ut2 "right";
    DAE.Exp origExp "for proper error reporting";
  end SUB;

  record MUL "multiplication, ut1*ut2"
    UnitTerm ut1 "left";
    UnitTerm ut2 "right";
    DAE.Exp origExp "for proper error reporting";
  end MUL;

  record DIV "division nominator/denominator"
    UnitTerm ut1 "nominator"; 
    UnitTerm ut2 "denominator";
    DAE.Exp origExp "for proper error reporting";
  end DIV;
  
  record  EQN "equation"
    UnitTerm ut1;
    UnitTerm ut2;             
    DAE.Exp origExp "for proper error reporting";
  end EQN;
  
  record LOC "location"
    Integer loc "location is an integer(index in vector)";
    DAE.Exp origExp "for proper error reporting";
  end LOC;
    
  record POW "exponentiation"
      UnitTerm ut1;
    	MMath.Rational exponent "ut^exponent";    	 
    	DAE.Exp origExp "for proper error reporting"; 
  end POW;
end UnitTerm;

public
type UnitTerms = list<UnitTerm>;

uniontype Store  
  record STORE
    Option<Unit>[:] storeVector;
    Integer numElts "Number of elements stored in vector" ;
  end STORE;  
end Store; 

uniontype InstStore "A store used in Inst.mo 
requires a mapping from variable names to locations. Unit checking can be turned off using NOSTORE 
" 
  
  record INSTSTORE 
    Store store;
    HashTable.HashTable ht;
    Option<UnitCheckResult> checkResult "when a check is done the result is stored here";
  end INSTSTORE;
  
  record NOSTORE "used to skip unit checking" end NOSTORE;            
end InstStore;

public constant InstStore noStore = NOSTORE();

end UnitAbsyn;