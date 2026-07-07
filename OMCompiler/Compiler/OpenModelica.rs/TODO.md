# mmtorust

* Function calls using named arguments or default arguments need macros (or lookup during generation)
* External "C" `ColPackBicoloring_starBicolor` (NBJacobian.colpackStarBicoloring, bidirectional/bicolored Jacobian) is not ported: no `external_c_impl_path` entry, so codegen emits `todo!()`. Needs a Rust star-bicoloring impl or FFI to the C++ ColPack wrapper. Test ignored: testsuite/simulation/modelica/NBackend/bicoloring/arrowhead.mos
