// name:     ClassExtends2
// keywords: class,extends
// status:   correct
//
//
class Y
  replaceable model X
    Integer x;
  end X;
end Y;

class ClassExtends1
 extends Y;

 redeclare replaceable model extends X(x=y)
   parameter Integer y = 5;
 end X;

 X component;
end ClassExtends1;

class ClassExtends2
  extends ClassExtends1;
end ClassExtends2;

// Result:
// class ClassExtends2
//   Integer component.x = component.y;
//   parameter Integer component.y = 5;
// end ClassExtends2;
// endResult
