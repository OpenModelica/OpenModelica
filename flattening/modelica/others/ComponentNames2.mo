// name: ComponentNames2
// keywords: component
// status: correct
//
// Tests whether or not a component can have the same name as the last ident of its type specifier
//

package P
  record R
    Real x;
  end R;
end P;

model ComponentNames
  P.R R;
end ComponentNames;

// Result:
// function P.R "Automatically generated record constructor for P.R"
//   input Real x;
//   output R res;
// end P.R;
//
// class ComponentNames
//   Real R.x;
// end ComponentNames;
// endResult
