// name: ErrorInvalidMetarecord
// cflags: +g=MetaModelica -d=-newInst
// status: incorrect
// suite: metamodelica

model ErrorInvalidMetarecord
  uniontype Ut
    record ABC end ABC;
    record DEF ABC abc; end DEF;
  end Ut;
  constant Ut ut = DEF(ABC());
end ErrorInvalidMetarecord;

// Result:
// Error processing file: ErrorInvalidMetarecord.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [metamodelica/meta/ErrorInvalidMetarecord.mo:11:3-11:30:writable] Error: The called uniontype record (ErrorInvalidMetarecord.Ut.DEF) contains a member (abc) that has a uniontype record as its type instead of a uniontype.
// Error: Error occurred while flattening model ErrorInvalidMetarecord
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
