package RecordStructs
  record Solid
    Real lambda = 1;
    Real rho = 1;
  end Solid;
  record Concrete = Solid(lambda = 1.75, rho = 2400);
  record Wall
    parameter Integer n = 1;
    parameter Solid mat[n];
  end Wall;
  record Recent = Wall(n = 2, mat = {Concrete(), Solid(lambda = 0.04)});

  record Liquid
    parameter Integer nc = 1;
    parameter String names[:] = {""};
    parameter Real ratio[:] = {1};
  end Liquid;
  record Water
    extends Liquid(nc = 1, names = {"Water"}, ratio = {1});
  end Water;

  function conductance
    input Wall w;
    output Real g = sum(w.mat[i].lambda for i in 1:w.n);
  end conductance;

  function components
    input Liquid l;
    output Integer n = l.nc + size(l.names, 1);
  end components;

  model M
    parameter Recent wall;
    Real g = conductance(wall);
    Integer n = components(Water());
  end M;
end RecordStructs;
