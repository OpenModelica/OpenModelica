within ;
package Ticket4674
  model BaseRecord
    parameter Real a = 1;
    parameter Real b = 1;
    parameter Real c = 1;
    annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(coordinateSystem(
            preserveAspectRatio=false)));
  end BaseRecord;

  model SpecialRecord
    extends Ticket4674.BaseRecord(
    a = 2.1,
    b = 4.1,
    c = 8.1);
    extends Ticket4674.Base2(d = 16.1);
    parameter Real e = 32.1;

    annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(coordinateSystem(
            preserveAspectRatio=false)));
  end SpecialRecord;

  model Base2
    parameter Real d = 1;
    annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(coordinateSystem(
            preserveAspectRatio=false)));
  end Base2;
end Ticket4674;
