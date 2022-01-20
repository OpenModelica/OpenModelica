model TestChoices "..."

  model MyModel1
    Real x;
  end MyModel1;

  model MyModel2
    Real x;
    Real y;
  end MyModel2;

  model MyModel3
    Real x;
    Real y;
    Real z;
  end MyModel3;

  replaceable MyModel c
   annotation(
     choices(
       choice(redeclare MyModel1 m "MyModel1"),
       choice(redeclare MyModel2 m "MyModel2"),
       choice(redeclare MyModel3 m "MyModel3")));

  replaceable model MyModel = MyModel1
   annotation(
     choices(
       choice(redeclare model MyModel = MyModel1 "MyModel1"),
       choice(redeclare model MyModel = MyModel2 "MyModel2"),
       choice(redeclare model MyModel = MyModel3 "MyModel3")));

  parameter String s = "blah1"
     annotation(
     choices(
       choice = "blah1",
       choice = "blah2",
       choice = "blah3"));

  parameter Real r = 1.0
     annotation(
     choices(
       choice = 1.0,
       choice = 2.0,
       choice = 3.0));

  parameter Integer i = 1
     annotation(
     choices(
       choice = 1,
       choice = 2,
       choice = 3));

  type MyEnum = enumeration(S1 "first", S2 "second", S3 "third");

  parameter MyEnum e = MyEnum.S1
     annotation(
     choices(
       choice = MyEnum.S1,
       choice = MyEnum.S2,
       choice = MyEnum.S3));

  MyModel m;
end TestChoices;

