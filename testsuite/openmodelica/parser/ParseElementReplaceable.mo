// name: ParseElementReplaceable
// status: correct
//
// This syntax is allowed by the grammar; the full MSL3.1 does not test it
//

model ParseElementReplaceable

class Palette
  replaceable Integer c1;
end Palette;

Palette p(redeclare replaceable Real c1);

end ParseElementReplaceable;

// Result:
// class ParseElementReplaceable
//   Real p.c1;
// end ParseElementReplaceable;
// endResult
