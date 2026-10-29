// name:     ClassExtends1
// keywords: class,extends
// status:   correct
//
//

model Y
  replaceable model X
    Integer x;
  end X;
end Y;

model ClassExtends1
 extends Y;

 redeclare replaceable model extends X(x=y)
   discrete Integer y;
 end X;

 X component;
initial equation
 component.y = 5;
end ClassExtends1;

// Result:
// class ClassExtends1
//   Integer component.x = component.y;
//   discrete Integer component.y;
// initial equation
//   component.y = 5;
// end ClassExtends1;
// endResult
