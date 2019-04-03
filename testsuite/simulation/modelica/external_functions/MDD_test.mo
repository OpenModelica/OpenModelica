within ;
model MDD_test

model Packager "Create a package which allows to add signals of various types"
  import
    Modelica_DeviceDrivers.Blocks.Packaging.SerialPackager.Internal.DummyFunctions;
  import Modelica_DeviceDrivers.Packaging.SerialPackager;
  import Modelica_DeviceDrivers.Packaging.alignAtByteBoundary;

  parameter Boolean enableExternalTrigger = false
      "true, enable external trigger input signal, otherwise use sample time settings below"
    annotation (Dialog(tab="Advanced", group="Activation"), choices(checkBox=true));
  parameter Boolean useBackwardSampleTimePropagation = true
      "true, use backward propagation for sample time, otherwise switch to forward propagation"
    annotation(Dialog(enable = not enableExternalTrigger, tab="Advanced", group="Activation"), choices(checkBox=true));
  parameter Modelica.SIunits.Period sampleTime=0.01
      "Sample time if forward propagation of sample time is used"
     annotation (Dialog(enable = (not useBackwardSampleTimePropagation) and (not enableExternalTrigger), tab="Advanced", group="Activation"));

  constant Boolean useBackwardPropagatedBufferSize = false
      "true, use backward propagated (automatic) buffer size for package, otherwise use manually specified buffer size below"
    annotation(Dialog(tab="Advanced", group="Buffer size settings"), choices(checkBox=true));
  parameter Integer userBufferSize = 16*1024
      "Buffer size for package if backward propagation of buffer size is deactivated"
     annotation (Dialog(enable = not useBackwardPropagatedBufferSize, tab="Advanced", group="Buffer size settings"));
  Modelica_DeviceDrivers.Blocks.Interfaces.PackageOut pkgOut(pkg = SerialPackager(if useBackwardPropagatedBufferSize then bufferSize else userBufferSize), dummy(start=0, fixed=true))
    annotation (Placement(transformation(extent={{-20,-128},{20,-88}})));
  Modelica.Blocks.Interfaces.BooleanInput trigger if                    enableExternalTrigger
    annotation (Placement(transformation(extent={{-140,-20},{-100,20}})));
  protected
  Modelica.Blocks.Interfaces.BooleanInput internalTrigger;
  Modelica.Blocks.Interfaces.BooleanInput conditionalInternalTrigger if not enableExternalTrigger;
  Modelica.Blocks.Interfaces.BooleanInput actTrigger
       annotation (HideResult=true);
  Integer backwardPropagatedBufferSize;
  Integer bufferSize;
equation
  /* Condional connect equations to either use external trigger or internal trigger */
  internalTrigger = if useBackwardSampleTimePropagation then pkgOut.backwardTrigger else sample(0,sampleTime);
  connect(internalTrigger, conditionalInternalTrigger);
  connect(conditionalInternalTrigger, actTrigger);
  connect(trigger, actTrigger);

  when initial() then
    /* If userPkgBitSize is set, use it. Otherwise use auto package size. */
    backwardPropagatedBufferSize = if pkgOut.userPkgBitSize > 0 then
        alignAtByteBoundary(pkgOut.userPkgBitSize)  else
        alignAtByteBoundary(pkgOut.autoPkgBitSize);
    bufferSize = if useBackwardPropagatedBufferSize then backwardPropagatedBufferSize
       else userBufferSize;
  end when;

  pkgOut.trigger = actTrigger;
  when pkgOut.trigger then
    pkgOut.dummy = DummyFunctions.clear(pkgOut.pkg, time);
  end when;

  annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
            -100},{100,100}}), graphics={Bitmap(extent={{-70,-70},{70,70}},
            fileName="Modelica://Modelica_DeviceDrivers/Resources/Images/Icons/package.png")}), Documentation(info="<html>
<p>
The <code>Packager</code> block creates a packager object to which payload can be added by subsequent blocks.
</p>
<h5>Advanced parameter settings</h5>
<p>
With the default parameter settings the buffer size (size of the serialized package), as well as the sample time of the block is determined automatically by
backward propagation. However, that values may also be set manually. An example there this functionality is used is the <a href=\"modelica://Modelica_DeviceDrivers.Blocks.Examples.TestSerialPackager\"><code>TestSerialPackager</code></a> model. In that model the parameter <code>sampleTime</code> is explicitly set, since backward propagation is not possible in that case.
</p>
<h4>Examples</h4>
<p>
The block is used in several examples, e.g. in,
<a href=\"modelica://Modelica_DeviceDrivers.Blocks.Examples.TestSerialPackager_UDP\"><code>TestSerialPackager_UDP</code></a>.
The figure below shows an arrangement in which a <code>Packager</code> object is created and after that a payload of three Real values
and one Integer value is added, serialized and finally sent using UDP.
</p>
<p><img src=\"modelica://Modelica_DeviceDrivers/Resources/Images/TestSerialPackager_UDP_model.png\"/></p>
</html>"));
end Packager;

  Modelica_DeviceDrivers.Blocks.Packaging.SerialPackager.ResetPointer
                                        resetPointer(nu=1)
    annotation (Placement(transformation(extent={{-46,20},{-26,40}})));
  Modelica_DeviceDrivers.Blocks.Packaging.SerialPackager.PackUnsignedInteger
                                               packInt(nu=1, width=32)
    annotation (Placement(transformation(extent={{-122,38},{-102,58}})));
  Packager packager(useBackwardSampleTimePropagation=false,
      sampleTime=0.1,
    userBufferSize=32)
    annotation (Placement(transformation(extent={{-122,78},{-102,98}})));
  Modelica.Blocks.Sources.IntegerExpression integerExpression(y=123)
    annotation (Placement(transformation(extent={{-162,38},{-142,58}})));
  Modelica_DeviceDrivers.Blocks.Packaging.SerialPackager.GetInteger getInteger
    annotation (Placement(transformation(extent={{-46,-10},{-26,10}})));
equation

  connect(packager.pkgOut, packInt.pkgIn) annotation (Line(
      points={{-112,77.2},{-112,58.8}},
      color={0,0,0},
      smooth=Smooth.None));
  connect(packInt.pkgOut[1], resetPointer.pkgIn) annotation (Line(
      points={{-112,37.2},{-112,-26},{-70,-26},{-70,46},{-36,46},{-36,40.8}},
      color={0,0,0},
      smooth=Smooth.None));
  connect(integerExpression.y, packInt.u) annotation (Line(
      points={{-141,48},{-124,48}},
      color={255,127,0},
      smooth=Smooth.None));
  connect(resetPointer.pkgOut[1], getInteger.pkgIn) annotation (Line(
      points={{-36,19.2},{-36,10.8}},
      color={0,0,0},
      smooth=Smooth.None));
end MDD_test;
