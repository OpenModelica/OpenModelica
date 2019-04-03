//name:        ExpandableVariableUsed.mo [BUG: #2385]
//keyword:     expandable
//status:      correct
//
// instantiate/check model example
//

package ExpandablePack

  expandable connector B
    Real x;
  end B;

  block Bsource
    output B bout;
  equation
    bout.x = sin(time);
  end Bsource;

  model Areceiver
    input B bin;
    Real y;
  equation
    y = 2 * bin.x;
  end Areceiver;

  model Test
    Areceiver a1;
    Bsource b1;
  equation
    connect(b1.bout,a1.bin);
  end Test;

end ExpandablePack;

model ExpandableVariableUsed
  extends ExpandablePack.Test;
end ExpandableVariableUsed;

// Result:
// class ExpandableVariableUsed
//   Real a1.bin.x;
//   Real a1.y;
//   Real b1.bout.x;
// equation
//   a1.y = 2.0 * a1.bin.x;
//   b1.bout.x = sin(time);
//   a1.bin.x = b1.bout.x;
// end ExpandableVariableUsed;
// endResult
