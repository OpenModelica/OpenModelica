// name:     loadFileInteractiveQualified
// keywords: within test
// status: correct
//
// within test, first should load loadFileInteractiveQualifiedInit.mo
//

within Something.Somewhere;

class Stuff "Stuff Comment"

  Real x;
  Real y;

end Stuff;

class Stuff2 "Stuff2 Comment"
  extends Stuff;
  Real z;
end Stuff2;


class BlaBla "BlaBla Comment"
  import HelloWorld.*;
  type X = Y;
  record Z
   Real x;
   Real y;
  end Z;
end BlaBla;

