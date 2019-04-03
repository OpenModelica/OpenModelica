// name:     Import1
// keywords: import
// status:   correct
//
// Demonstrating various form of import.
//
// Note that a qualified import takes
// precendence over a unqualified import.
//

package A
  package B
    partial model C
      Real x;
    end C;
    model D
      extends C(x=5);
    end D;
  end B;
  package B1
    model C
      extends B.C(x=4);
    end C;
  end B1;
  package B2
    model C
      extends B.C(x=7);
    end C;
    model E=B.C(x=6);
  end B2;
end A;

class Import1
  import A.B.*;
  import A.B2.*;
  import A.B1.C;
  import MyC=A.B2.C;
  C c;
  D d;
  E e;
  MyC myc;
end Import1;



/*   origfclass Import1 (Why is this here? moved to be able to use -b flag, BZ)
   Real c.x=4; // A.B1.C via import A.B1.C
   Real d.x=5; // A.B.D via import A.B.*;
   Real e.x=6; // A.B2.C via import A.B2.*;
   Real myc.x=7; // A.B2.E via import MyC=A.B2.C;
*/
// Result:
// class Import1
//   Real c.x = 4.0;
//   Real d.x = 5.0;
//   Real e.x = 6.0;
//   Real myc.x = 7.0;
// end Import1;
// endResult
