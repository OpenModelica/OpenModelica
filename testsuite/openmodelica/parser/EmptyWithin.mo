// name: EmptyWithin
// status: correct
// cflags: -d=-newInst
//
// Checks that within; gives the top level scope

within;

class EmptyWithin
end EmptyWithin;
// Result:
// class EmptyWithin
// end EmptyWithin;
// endResult
