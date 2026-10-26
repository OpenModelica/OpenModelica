// name:     Extends8
// keywords: extends
// status:   correct
//
// Testing that you can extend and still keep all classdefs.
// See bug: http://openmodelica.ida.liu.se:8080/cb/issue/1192?navigation=true

package MyPackage

  package SI
    type Abs = Integer;
  end SI;

  class Z
    Abs abc;
    type Abs = SI.Abs(min = 1, max = 4);
  end Z;

  class X
    extends Z(abc = 3);
  end X;

end MyPackage;

class Extends8
  extends MyPackage.X;
end Extends8;

// Result:
// class Extends8
//   Integer abc(min = 1, max = 4) = 3;
// end Extends8;
// endResult
