// name:     RecordBindingsOrdered
// keywords: record parameter
// status:   correct
//
// Tests records elements get bindings properly and in the correct order.
// Fix for bug #1675: https://openmodelica.org:8443/cb/issue/1675
//

record GenericData
  parameter Integer dataOne = 1;
  parameter Integer dataTwo = 1;
end GenericData;

record DataSetOne = GenericData(dataOne = 5, dataTwo = 10);
record DataSetTwo = GenericData(dataOne = 15, dataTwo = 20);

model HasRecordAsParameter
  parameter GenericData data;
  Integer variable;
equation
  variable = data.dataOne;
end HasRecordAsParameter;

model PassesRecordAsParameter
  parameter DataSetOne data;
  HasRecordAsParameter parameterReceiver(data = data);
  Integer variable;
equation
  variable = parameterReceiver.variable;
end PassesRecordAsParameter;

model PassesRecordArrayAsParameter
  parameter DataSetOne data1;
  parameter DataSetTwo data2;
  parameter GenericData data[2]={data1,data2};
  HasRecordAsParameter parameterReceiver[2](data = data);
  Integer variable;
equation
  variable = parameterReceiver[1].variable;
end PassesRecordArrayAsParameter;

// Result:
// function DataSetOne "Automatically generated record constructor for DataSetOne"
//   input Integer dataOne = 5;
//   input Integer dataTwo = 10;
//   output DataSetOne res;
// end DataSetOne;
//
// function DataSetTwo "Automatically generated record constructor for DataSetTwo"
//   input Integer dataOne = 15;
//   input Integer dataTwo = 20;
//   output DataSetTwo res;
// end DataSetTwo;
//
// function GenericData "Automatically generated record constructor for GenericData"
//   input Integer dataOne = 1;
//   input Integer dataTwo = 1;
//   output GenericData res;
// end GenericData;
//
// class PassesRecordArrayAsParameter
//   parameter Integer data1.dataOne = 5;
//   parameter Integer data1.dataTwo = 10;
//   parameter Integer data2.dataOne = 15;
//   parameter Integer data2.dataTwo = 20;
//   parameter Integer data[1].dataOne = data1.dataOne;
//   parameter Integer data[1].dataTwo = data1.dataTwo;
//   parameter Integer data[2].dataOne = data2.dataOne;
//   parameter Integer data[2].dataTwo = data2.dataTwo;
//   parameter Integer parameterReceiver[1].data.dataOne = data[1].dataOne;
//   parameter Integer parameterReceiver[1].data.dataTwo = data[1].dataTwo;
//   Integer parameterReceiver[1].variable;
//   parameter Integer parameterReceiver[2].data.dataOne = data[2].dataOne;
//   parameter Integer parameterReceiver[2].data.dataTwo = data[2].dataTwo;
//   Integer parameterReceiver[2].variable;
//   Integer variable;
// equation
//   parameterReceiver[1].variable = parameterReceiver[1].data.dataOne;
//   parameterReceiver[2].variable = parameterReceiver[2].data.dataOne;
//   variable = parameterReceiver[1].variable;
// end PassesRecordArrayAsParameter;
// endResult
