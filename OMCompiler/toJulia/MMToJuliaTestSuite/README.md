# Temporary testsuite for the MetaModelica to Julia converter
## Structure
### syntaxCheck.jl
    Tests that the generated code forfills the syntactic rules of
    the Julia language. It first does so for primitives, complex types such as lists
    and union types. Last but not least it also checks the syntactic structures of algorithms

### TODO: semanticCheck.jl


### TODO: compilerTranslationCheck.jl ...

## Usage
Simple run allTests.jl
> julia allTests.jl
Or run a single a test in isolation such as syntaxCheck.jl
> julia syntaxCheck.jl
