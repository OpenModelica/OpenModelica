package Modelica_DeviceDrivers  "Modelica_DeviceDrivers - A collection of drivers interfacing hardware like input devices, communication devices, shared memory, analog-digital converters and else" 
  extends Modelica.Icons.Package;

  package Blocks  "This package contains Modelica 3.2 compatible drag'n'drop device driver blocks." 
    extends Modelica.Icons.Package;

    package Packaging  
      extends Modelica.Icons.Package;

      package SerialPackager  "Blocks for constructing packages" 
        extends Modelica.Icons.Package;

        package Internal  
          extends Modelica_DeviceDrivers.Utilities.Icons.InternalPackage;

          partial block PartialSerialPackager  
            parameter Integer nu(min = 0, max = 1) = 0 "Output connector size" annotation(HideResult = true);
            Interfaces.PackageIn pkgIn;
            Interfaces.PackageOut[nu] pkgOut(dummy(each start = 0, each fixed = true));
          equation
            if nu == 1 then
              pkgOut.pkg = fill(pkgIn.pkg, nu);
              pkgOut.trigger = fill(pkgIn.trigger, nu);
              pkgOut.backwardTrigger = fill(pkgIn.backwardTrigger, nu);
              pkgOut.userPkgBitSize = fill(pkgIn.userPkgBitSize, nu);
            else
              pkgIn.backwardTrigger = false;
              pkgIn.userPkgBitSize = -1;
            end if;
          end PartialSerialPackager;

          package DummyFunctions  
            extends Modelica_DeviceDrivers.Utilities.Icons.InternalPackage;

            function integerBitUnpack  "Unpack integer value encoded at bit level" 
              input .Modelica_DeviceDrivers.Packaging.SerialPackager pkg;
              input Integer bitOffset "Bit offset from current packager position until first encoding bit";
              input Integer width "Number of bits that encode the integer value";
              input Real dummy;
              output Integer value "Decoded integer value";
              output Real dummy2;
            algorithm
              value := .Modelica_DeviceDrivers.Packaging.SerialPackager_.integerBitUnpack(pkg, bitOffset, width);
              dummy2 := dummy;
            end integerBitUnpack;
          end DummyFunctions;
        end Internal;

        model UnpackUnsignedInteger  "decode integer value encoded at bit level" 
          extends Modelica_DeviceDrivers.Utilities.Icons.SerialPackagerReadIcon;
          extends Modelica_DeviceDrivers.Blocks.Packaging.SerialPackager.Internal.PartialSerialPackager;
          parameter Integer bitOffset = 0 "Bit offset from current packager position until first encoding bit";
          parameter Integer width = 32 "Number of bits that encode the integer value";
          Modelica.Blocks.Interfaces.IntegerOutput y(min = 0, start = 0, fixed = true);
        protected
          Real dummy(start = 0, fixed = true);
        equation
          when initial() then
            pkgIn.autoPkgBitSize = if nu == 1 then pkgOut[1].autoPkgBitSize + bitOffset + width else bitOffset + width;
          end when;
          when pkgIn.trigger then
            (y, dummy) = Internal.DummyFunctions.integerBitUnpack(pkgIn.pkg, bitOffset, width, pkgIn.dummy);
            pkgOut.dummy = fill(dummy, nu);
          end when;
        end UnpackUnsignedInteger;
      end SerialPackager;
    end Packaging;

    package Communication  
      extends Modelica.Icons.Package;

      block SerialPortReceive  "A block for receiving serial datagrams using the serial interface" 
        extends Modelica_DeviceDrivers.Utilities.Icons.SerialPortIcon;
        extends Modelica_DeviceDrivers.Blocks.Communication.Internal.PartialSampleTrigger;
        parameter Boolean autoBufferSize = true "true, buffer size is deduced automatically, otherwise set it manually";
        parameter Integer userBufferSize = 16 * 64 "Buffer size of message data in bytes (if not deduced automatically)";
        parameter String Serial_Port = "/dev/ttyPS1" "Serial port to send data";
        parameter .Modelica_DeviceDrivers.Utilities.Types.SerialBaudRate baud = .Modelica_DeviceDrivers.Utilities.Types.SerialBaudRate.B9600 "Serial port baud rate";
        parameter Integer parity = 0 "set parity (0 - no parity, 1 - even, 2 - odd)";
        Interfaces.PackageOut pkgOut(pkg = .Modelica_DeviceDrivers.Packaging.SerialPackager(if autoBufferSize then bufferSize else userBufferSize), dummy(start = 0, fixed = true));
      protected
        Integer bufferSize;
        .Modelica_DeviceDrivers.Communication.SerialPort sPort = .Modelica_DeviceDrivers.Communication.SerialPort(Serial_Port, if autoBufferSize then bufferSize else userBufferSize, parity, receiver, baud);
        parameter Integer receiver = 1 "Set to be a receiver port";
      equation
        when initial() then
          bufferSize = if autoBufferSize then .Modelica_DeviceDrivers.Packaging.alignAtByteBoundary(pkgOut.autoPkgBitSize) else userBufferSize;
        end when;
        pkgOut.trigger = actTrigger "using inherited trigger";
        when pkgOut.trigger then
          pkgOut.dummy = Internal.DummyFunctions.readSerial(sPort, pkgOut.pkg, time);
        end when;
      end SerialPortReceive;

      package Internal  
        extends Modelica.Icons.InternalPackage;

        package DummyFunctions  
          extends Modelica_DeviceDrivers.Utilities.Icons.InternalPackage;

          function readSerial  
            input Modelica_DeviceDrivers.Communication.SerialPort sPort "Serial Port object";
            input Modelica_DeviceDrivers.Packaging.SerialPackager pkg;
            input Real dummy;
            output Real dummy2;
          algorithm
            Modelica_DeviceDrivers.Communication.SerialPort_.read(sPort, pkg);
            dummy2 := dummy;
          end readSerial;
        end DummyFunctions;

        block PartialSampleTrigger  "Common code for triggering calls to external I/O devices" 
          parameter Boolean enableExternalTrigger = false "true, enable external trigger input signal, otherwise use sample time settings below";
          parameter .Modelica.SIunits.Period sampleTime = 0.1 "Sample period of component";
          parameter .Modelica.SIunits.Time startTime = 0 "First sample time instant";
          Modelica.Blocks.Interfaces.BooleanInput trigger if enableExternalTrigger;
        protected
          Modelica.Blocks.Interfaces.BooleanInput internalTrigger;
          Modelica.Blocks.Interfaces.BooleanInput conditionalInternalTrigger if not enableExternalTrigger;
          Modelica.Blocks.Interfaces.BooleanInput actTrigger annotation(HideResult = true);
        equation
          internalTrigger = sample(startTime, sampleTime);
          connect(internalTrigger, conditionalInternalTrigger);
          connect(conditionalInternalTrigger, actTrigger);
          connect(trigger, actTrigger);
        end PartialSampleTrigger;
      end Internal;
    end Communication;

    package Interfaces  
      extends Modelica.Icons.InterfacesPackage;

      connector PackageIn  "Packager input connector" 
        input Modelica_DeviceDrivers.Packaging.SerialPackager pkg;
        input Boolean trigger;
        input Real dummy;
        output Boolean backwardTrigger;
        output Integer userPkgBitSize;
        output Integer autoPkgBitSize;
      end PackageIn;

      connector PackageOut  "Packager output connector" 
        output Modelica_DeviceDrivers.Packaging.SerialPackager pkg;
        output Boolean trigger;
        output Real dummy;
        input Boolean backwardTrigger;
        input Integer userPkgBitSize;
        input Integer autoPkgBitSize;
      end PackageOut;
    end Interfaces;
  end Blocks;

  package Packaging  "Package/Unpackage of variables for sending/receiving with communication devices" 
    extends Modelica.Icons.Package;

    class SerialPackager  "Serial packaging of data" 
      extends ExternalObject;

      encapsulated function constructor  "Claim the memory" 
        extends .Modelica.Icons.Function;
        input Integer bufferSize = 16 * 1024;
        output .Modelica_DeviceDrivers.Packaging.SerialPackager pkg;
        external "C" pkg = MDD_SerialPackagerConstructor(bufferSize) annotation(Include = "#include \"MDDSerialPackager.h\"", __iti_dll = "ITI_MDD.dll", __iti_dllNoExport = true);
      end constructor;

      encapsulated function destructor  "Free memory" 
        extends .Modelica.Icons.Function;
        input .Modelica_DeviceDrivers.Packaging.SerialPackager pkg;
        external "C" MDD_SerialPackagerDestructor(pkg) annotation(Include = "#include \"MDDSerialPackager.h\"", __iti_dll = "ITI_MDD.dll", __iti_dllNoExport = true);
      end destructor;
    end SerialPackager;

    package SerialPackager_  "Accompanying functions for the SerialPackager object" 
      extends Modelica_DeviceDrivers.Utilities.Icons.DriverIcon;

      encapsulated function integerBitUnpack  "Unpack integer value encoded at bit level" 
        extends .Modelica.Icons.Function;
        input .Modelica_DeviceDrivers.Packaging.SerialPackager pkg;
        input Integer bitOffset "Bit offset from current packager position until first encoding bit";
        input Integer width "Number of bits that encode the integer value";
        output Integer value "Decoded integer value";
        external "C" value = MDD_SerialPackagerIntegerBitunpack2(pkg, bitOffset, width) annotation(Include = "#include \"MDDSerialPackager.h\"", __iti_dll = "ITI_MDD.dll", __iti_dllNoExport = true);
      end integerBitUnpack;
    end SerialPackager_;

    function alignAtByteBoundary  "Returns the minimum number of bytes required to encode the specified number of bits" 
      extends .Modelica.Icons.Function;
      input Integer bitSize;
      output Integer nBytes;
    algorithm
      nBytes := div(bitSize + 7, 8);
    end alignAtByteBoundary;
  end Packaging;

  package Communication  "This package contains drivers for packet based communication devices such as network, CAN, shared memory, etc." 
    extends Modelica.Icons.Package;

    class SerialPort  "A driver for serial port communication." 
      extends ExternalObject;

      encapsulated function constructor  "Creates a SerialPort instance with a given listening port." 
        extends .Modelica.Icons.Function;
        input String deviceName "Serial port (/dev/ttyX or \\\\.\\COMX)";
        input Integer bufferSize = 16 * 1024 "Size of receive buffer";
        input Integer parity = 0 "0 - no parity, 1 - even, 2 - odd";
        input Integer receiver = 1 "0 - sender, 1 - receiver";
        input .Modelica_DeviceDrivers.Utilities.Types.SerialBaudRate baud;
        output .Modelica_DeviceDrivers.Communication.SerialPort sPort;
        external "C" sPort = MDD_serialPortConstructor(deviceName, bufferSize, parity, receiver, baud) annotation(Include = "#include \"MDDSerialPort.h\"", Library = "pthread", __iti_dll = "ITI_MDD.dll", __iti_dllNoExport = true);
      end constructor;

      encapsulated function destructor  
        extends .Modelica.Icons.Function;
        input .Modelica_DeviceDrivers.Communication.SerialPort sPort;
        external "C" MDD_serialPortDestructor(sPort) annotation(Include = "#include \"MDDSerialPort.h\"", Library = "pthread", __iti_dll = "ITI_MDD.dll", __iti_dllNoExport = true);
      end destructor;
    end SerialPort;

    package SerialPort_  "Accompanying functions for the SerialPort object" 
      extends Modelica_DeviceDrivers.Utilities.Icons.DriverIcon;

      encapsulated function read  
        extends .Modelica.Icons.Function;
        input .Modelica_DeviceDrivers.Communication.SerialPort sPort;
        input .Modelica_DeviceDrivers.Packaging.SerialPackager pkg;
        external "C" MDD_serialPortReadP(sPort, pkg) annotation(Include = "#include \"MDDSerialPort.h\"", Library = "pthread", __iti_dll = "ITI_MDD.dll", __iti_dllNoExport = true);
      end read;
    end SerialPort_;
  end Communication;

  package Utilities  "Collection of utility elements used within the library" 
    extends Modelica.Icons.UtilitiesPackage;

    package Icons  "Collection of icons used for library components" 
      extends Modelica.Icons.IconsPackage;

      partial package InternalPackage  "Icon for packages that contain elements that are not intended to be directly used by library users" end InternalPackage;

      partial block BaseIcon  "Base icon for blocks providing access to external devices" end BaseIcon;

      partial package DriverIcon  "An icon for a package with device driver functions." end DriverIcon;

      partial block SerialPackagerReadIcon  end SerialPackagerReadIcon;

      partial block SerialPortIcon  "Base icon for serial port communication blocks" 
        extends BaseIcon;
      end SerialPortIcon;
    end Icons;

    package Types  "Custom type definitions" 
      extends Modelica.Icons.TypesPackage;
      type SerialBaudRate = enumeration(B115200 "115.2k baud", B57600 "56k baud", B38400 "38.4k baud", B19200 "19.2k baud", B9600 "9600 baud", B4800 "4800 baud", B2400 "2400 baud") "Baud rate of serial device";
    end Types;
  end Utilities;
  annotation(version = "1.4.4", versionDate = "2016-04-12"); 
end Modelica_DeviceDrivers;

package Modelica  "Modelica Standard Library - Version 3.2.2" 
  extends Modelica.Icons.Package;

  package Blocks  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)" 
    extends Modelica.Icons.Package;

    package Interfaces  "Library of connectors and partial models for input/output blocks" 
      extends Modelica.Icons.InterfacesPackage;
      connector BooleanInput = input Boolean "'input Boolean' as connector";
      connector IntegerOutput = output Integer "'output Integer' as connector";
    end Interfaces;
  end Blocks;

  package Utilities  "Library of utility functions dedicated to scripting (operating on files, streams, strings, system)" 
    extends Modelica.Icons.Package;

    package Files  "Functions to work with files and directories" 
      extends Modelica.Icons.Package;

      function fullPathName  "Get full path name of file or directory name" 
        extends Modelica.Icons.Function;
        input String name "Absolute or relative file or directory name";
        output String fullName "Full path of 'name'";
        external "C" fullName = ModelicaInternal_fullPathName(name) annotation(Library = "ModelicaExternalC", __ModelicaAssociation_Impure = true);
        annotation(__ModelicaAssociation_Impure = true); 
      end fullPathName;
    end Files;
  end Utilities;

  package Icons  "Library of icons" 
    extends Icons.Package;

    partial package Package  "Icon for standard packages" end Package;

    partial package InterfacesPackage  "Icon for packages containing interfaces" 
      extends Modelica.Icons.Package;
    end InterfacesPackage;

    partial package UtilitiesPackage  "Icon for utility packages" 
      extends Modelica.Icons.Package;
    end UtilitiesPackage;

    partial package TypesPackage  "Icon for packages containing type definitions" 
      extends Modelica.Icons.Package;
    end TypesPackage;

    partial package IconsPackage  "Icon for packages containing icons" 
      extends Modelica.Icons.Package;
    end IconsPackage;

    partial package InternalPackage  "Icon for an internal package (indicating that the package should not be directly utilized by user)" end InternalPackage;

    partial function Function  "Icon for functions" end Function;
  end Icons;

  package SIunits  "Library of type and unit definitions based on SI units according to ISO 31-1992" 
    extends Modelica.Icons.Package;
    type Time = Real(final quantity = "Time", final unit = "s");
    type Period = Real(final quantity = "Time", final unit = "s");
  end SIunits;
  annotation(version = "3.2.2", versionBuild = 3, versionDate = "2016-04-03", dateModified = "2016-04-03 08:44:41Z"); 
end Modelica;

model Bug4124
  Modelica_DeviceDrivers.Blocks.Communication.SerialPortReceive serialReceive(baud = Modelica_DeviceDrivers.Utilities.Types.SerialBaudRate.B9600, parity = 0, enableExternalTrigger = false, startTime = 0.0, autoBufferSize = false, userBufferSize = 6, sampleTime = 0.1, Serial_Port = "COM3");
  Modelica_DeviceDrivers.Blocks.Packaging.SerialPackager.UnpackUnsignedInteger unpackInt(bitOffset = 0, width = 16, nu = 1);
  Modelica_DeviceDrivers.Blocks.Packaging.SerialPackager.UnpackUnsignedInteger unpackInt1(bitOffset = 0, width = 16);
equation
  connect(serialReceive.pkgOut, unpackInt.pkgIn);
  connect(unpackInt.pkgOut[1], unpackInt1.pkgIn);
  annotation(experiment(StopTime = 15, Tolerance = 0.001, __Dymola_fixedstepsize = 0.001, __Dymola_Algorithm = "Euler")); 
end Bug4124;
