// name: ExternalObject6
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model ExternalObject6
  class EO
    extends ExternalObject;

    function constructor
      output EO e;
      external "C" e = init();
    end constructor;

    function destructor
      input EO e;
      external "C" deinit(e);
    end destructor;
  end EO;

  parameter Integer N = 2;
  EO e[N] = {EO() for i in 1:N};
end ExternalObject6;

// Result:
// impure function ExternalObject6.EO.constructor
//   output ExternalObject6.EO e;
//
//   external "C" e = init();
// end ExternalObject6.EO.constructor;
//
// impure function ExternalObject6.EO.destructor
//   input ExternalObject6.EO e;
//
//   external "C" deinit(e);
// end ExternalObject6.EO.destructor;
//
// class ExternalObject6
//   final parameter Integer N = 2;
//   ExternalObject6.EO e[1] = ExternalObject6.EO.constructor();
//   ExternalObject6.EO e[2] = ExternalObject6.EO.constructor();
// end ExternalObject6;
// endResult
