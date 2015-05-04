// name: InheritanceRestrictions
// keywords: inheritance
// status: incorrect
//
// Tests inheritance of specialized classes
//

record RecordA
end RecordA;

package PackageA
end PackageA;

// should work
package PackageB
  extends PackageA;
end PackageB;

// should work
model ModelA
  extends RecordA;
end ModelA;

// should NOT work
model ModelB
  extends PackageA;
end ModelB;
