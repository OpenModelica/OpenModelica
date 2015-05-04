// name:     DefaultRecordParameters
// keywords: record parameters with default values, record extends
// status:   correct
//
// Testing of record component parameters with default values and extends of records
//


package BodyModel
  model Body
  public
    BodyModel.BodyGeometry data;
    Real displacement;
    constant Real pi=3.1415956;
  equation
    displacement= pi/4 * data.length * data.volume;
  end Body;

  record BodyGeometry
  public
    parameter Real length = 5;
    parameter Real volume = 10;
  end BodyGeometry;

  record Extended
    extends BodyModel.BodyGeometry(length=0.09, volume=2.10);
  end Extended;

  record Extended2
    extends BodyModel.BodyGeometry(volume=6.0);
  end Extended2;

end BodyModel;

model DefaultRecordParameters
  BodyModel.Body body1(data=BodyModel.Extended());
  BodyModel.Body body2(data=BodyModel.Extended(length=3,volume=5));
  BodyModel.Body body3(data=BodyModel.Extended2());
end DefaultRecordParameters;


// Result:
// function BodyModel.BodyGeometry "Automatically generated record constructor for BodyModel.BodyGeometry"
//   input Real length = 5.0;
//   input Real volume = 10.0;
//   output BodyGeometry res;
// end BodyModel.BodyGeometry;
//
// function BodyModel.Extended "Automatically generated record constructor for BodyModel.Extended"
//   input Real length = 0.09;
//   input Real volume = 2.1;
//   output Extended res;
// end BodyModel.Extended;
//
// function BodyModel.Extended2 "Automatically generated record constructor for BodyModel.Extended2"
//   input Real length = 5.0;
//   input Real volume = 6.0;
//   output Extended2 res;
// end BodyModel.Extended2;
//
// class DefaultRecordParameters
//   parameter Real body1.data.length = 0.09;
//   parameter Real body1.data.volume = 2.1;
//   Real body1.displacement;
//   constant Real body1.pi = 3.1415956;
//   parameter Real body2.data.length = 3.0;
//   parameter Real body2.data.volume = 5.0;
//   Real body2.displacement;
//   constant Real body2.pi = 3.1415956;
//   parameter Real body3.data.length = 5;
//   parameter Real body3.data.volume = 6.0;
//   Real body3.displacement;
//   constant Real body3.pi = 3.1415956;
// equation
//   body1.displacement = 0.7853989 * body1.data.length * body1.data.volume;
//   body2.displacement = 0.7853989 * body2.data.length * body2.data.volume;
//   body3.displacement = 0.7853989 * body3.data.length * body3.data.volume;
// end DefaultRecordParameters;
// endResult
