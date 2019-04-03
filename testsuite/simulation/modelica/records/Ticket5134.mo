within ;
model RecordPassedToFunction
  record R
    Integer i=2;
  end R;
  parameter R r(i=3);
  function f
    input R r;
    output Real y;
    external "C" y = doSomething(r) annotation(Include="
    struct CRecordType {
    int i;
    };
    double doSomething(void* vp) {
    struct CRecordType *rp = (struct CRecordType*) vp;
    return rp->i;
    }
    ");
  end f;
  Real y = f(r);
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end RecordPassedToFunction;
