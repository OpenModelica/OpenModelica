package Domains
  type Coordinate = Real;
  //built-in

  type Domain
    //built-in

    type Region
      parameter Integer ndim;
    end Region;

    parameter Integer ndimD;
    Coordinate coord[ndimD];
    replaceable Region interior;
  end Domain;

  type Domain1D
    extends Domain(ndimD = 1);
    type Region0D = Region(ndim = 0);
    type Region1D = Region(ndim = 1);
  end Domain1D;

  type DomainLineSegment1D
    extends Domain1D;
    parameter Real l = 1;
    Coordinate x(name = "cartesian") = coord[1];
    Region1D interior(x in (0,l) /*or 0<x and x<l ??*/);
    Region0D left(x = 0);
    Region0D right(x = l);
  end DomainLineSegment1D;

  type Domain2D
    extends Domain(ndimD = 2);
    type RegionIn2DDomain = Region(ndimD = ndimD);
    type Region0D = Region(ndim = 0);
    type Region1D = Region(ndim = 1);
    type Region2D = Region(ndim = 2);
  end Domain2D;

  DomainLineSegment1D d(l = 10);
end Domains;
