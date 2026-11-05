// SysML v2 textual form of the architecture model CoolingSystem_A1 (D2.1.1 3.1.4).
// Input of the future SysML v2 converter; CoolingSystem_A1.architecture.json is what it must produce.
package CoolingSystem {
  part def Pump_A {
    attribute id : ScalarValues::String;
    attribute NPSH_req : ScalarValues::Real[*];
  }
  part CoolingSystem_A1 {
    part pump1 : Pump_A { :>> id = "PO1"; }
    part pump2 : Pump_A { :>> id = "PO2"; }
    part pump3 : Pump_A { :>> id = "PO3"; }
  }
}
