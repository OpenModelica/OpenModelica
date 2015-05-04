package TestPackageInheritance
  package BasePackage
    replaceable function f
      input Real x;
      output Real y;
    algorithm
      y := x;
    end f;

    replaceable partial function g
      input Real x;
      output Real y;
    end g;
  end BasePackage;

  package MyPackage
    extends BasePackage;
    redeclare replaceable function g
      input Real x;
      output Real y;
    algorithm
      y := 2*x;
    end g;

    replaceable function h
      input Real x;
      output Real y;
    algorithm
      y := 10*x;
    end h;
  end MyPackage;

  package ModifiedPackage
    extends MyPackage;
    redeclare replaceable function f
      input Real x;
      output Real y;
    algorithm
       y:= -x;
    end f;
  end ModifiedPackage;

  package WrongPackage
    extends BasePackage;
    redeclare replaceable function f
      input Real a;
      output Real b;
    algorithm
      b := a*5;
    end f;
  end WrongPackage;

  package Test
    model Test_f
      Real x = 1;
      Real y = MyPackage.f(x);
    end Test_f;

    model Test_g
      Real x = 1;
      Real y = MyPackage.g(x);
    end Test_g;

    model Test_h
      Real x = 1;
      Real y = MyPackage.h(x);
    end Test_h;

    model Test_f_modified
      Real x = 1;
      Real y = ModifiedPackage.f(x);
    end Test_f_modified;

    model Test_f_wrong
      Real x = 1;
      Real y = WrongPackage.f(x);
    end Test_f_wrong;
  end Test;
end TestPackageInheritance;
