# wasm-jit simulation

* Zeno/rest handling gap in the event loop: an unguarded bouncing ball (a bare
  `when h<=0 then reinit(v,-e*pre(v))`) falls through the floor (`h≈-0.96` vs C's
  rest at `0`; ~55 vs 40 bounces) — see HANDOFF-wasm-jit-simulation-correctness.md
  ("Pre-existing, unrelated"). The standard OM BouncingBall guards against this
  with a `flying` flag (`der(v)=if flying then -g else 0`, `flying = v_new > 0`);
  the web simulator's default model uses that guarded form. Fix the event loop so
  the unguarded formulation also comes to rest instead of tunnelling.

# mmtorust

* Function calls using named arguments or default arguments need macros (or lookup during generation)
* External "C" `ColPackBicoloring_starBicolor` (NBJacobian.colpackStarBicoloring, bidirectional/bicolored Jacobian) is not ported: no `external_c_impl_path` entry, so codegen emits `todo!()`. Needs a Rust star-bicoloring impl or FFI to the C++ ColPack wrapper. Test ignored: testsuite/simulation/modelica/NBackend/bicoloring/arrowhead.mos
