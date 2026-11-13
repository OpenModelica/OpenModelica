/* header
 * licence
*/
package P
  model M
    // leading comment of x
    // trailing comment of x
    Real y(start = 1,  // why start=1
    fixed = true);
    // floating comment
    Real z;
    Real w;
  equation
    x = 1;
// eq comment
    y = 2;
    z = 3;
// comment before end
  end M;
  annotation(
    uses(Modelica(version = "4.0.0")));
end P;