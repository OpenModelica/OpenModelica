// name: ErrorInvalidMetarecord
// cflags: +g=MetaModelica
// status: incorrect

model ErrorInvalidMetarecord
  uniontype Ut
    record ABC end ABC;
    record DEF ABC abc; end DEF;
  end Ut;
  constant Ut ut = DEF(ABC());
end ErrorInvalidMetarecord;

// Result:
// Error processing file: ErrorInvalidMetarecord.mo
// [metamodelica/meta/ErrorInvalidMetarecord.mo:10:3-10:30:writable] Error: The called uniontype record (ErrorInvalidMetarecord.Ut.DEF) contains a member (abc) that has a uniontype record as its type instead of a uniontype.
// Error: Error occurred while flattening model ErrorInvalidMetarecord
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
