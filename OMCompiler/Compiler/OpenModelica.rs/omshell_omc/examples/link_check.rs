// Builds an executable that constructs the backend, to verify the compiler crate
// links in. Does NOT call init (that would start omc); it only forces the linker
// to pull in openmodelica_backend_main via the trait object.
fn main() {
    let backend = omshell_omc::backend();
    std::hint::black_box(&backend);
    println!("linked openmodelica_backend_main OK");
}
