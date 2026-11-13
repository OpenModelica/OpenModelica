"""
    OMCompiler

The OpenModelica compiler (the Rust port's `libOpenModelicaCompiler`) loaded into Julia.
`instantiate` runs omc's frontend and returns the flat model as a `Node`: a handle to the
compiler's own value, read field by field (`node.variables`, `ctor(node)`).
"""
module OMCompiler

import Libdl

export Node, EnumLiteral, Opaque, ctor, typename, fields, nodeid

const FPTR = Dict{Symbol, Ptr{Cvoid}}()
const SYMBOLS = (:omjl_init, :omjl_last_error, :omjl_eval, :omjl_instantiate, :omjl_free, :omjl_kind,
                 :omjl_integer, :omjl_real, :omjl_name, :omjl_type_name, :omjl_length, :omjl_field_name,
                 :omjl_child, :omjl_identity, :omjl_apply, :omc_compiler_free_string)

fp(s::Symbol) = FPTR[s]

const KIND_INTEGER, KIND_REAL, KIND_BOOLEAN, KIND_STRING, KIND_ENUM, KIND_NODE,
      KIND_LIST, KIND_ARRAY, KIND_TUPLE, KIND_OPTION, KIND_OPAQUE = 0:10

"A handle to a record or uniontype value inside omc."
mutable struct Node
  ptr::Ptr{Cvoid}
  function Node(p::Ptr{Cvoid})
    n = new(p)
    finalizer(n -> ccall(fp(:omjl_free), Cvoid, (Ptr{Cvoid},), getfield(n, :ptr)), n)
  end
end

"A literal of a MetaModelica enumeration (`Variability.PARAMETER`); `index` is its ordinal."
struct EnumLiteral
  type::Symbol
  literal::Symbol
  index::Int
end

"A value of a type omc gives no view of (a function pointer, a hash table)."
struct Opaque
  type::String
end

function takestring(p::Ptr{Cchar})::String
  p == C_NULL && return ""
  s = unsafe_string(p)
  ccall(fp(:omc_compiler_free_string), Cvoid, (Ptr{Cchar},), p)
  return s
end

function strfield(f::Symbol, p::Ptr{Cvoid})::String
  len = Ref{Csize_t}(0)
  s = ccall(fp(f), Ptr{UInt8}, (Ptr{Cvoid}, Ref{Csize_t}), p, len)
  return unsafe_string(s, len[])
end

function fieldname(p::Ptr{Cvoid}, i::Int)::String
  len = Ref{Csize_t}(0)
  s = ccall(fp(:omjl_field_name), Ptr{UInt8}, (Ptr{Cvoid}, Int64, Ref{Csize_t}), p, i, len)
  return unsafe_string(s, len[])
end

"""
The compiler library in the installation `omhome`: `lib/<triple>/omc/libOpenModelicaCompiler`.
omc finds its installation from the library's location, so a library outside one does not work.
"""
function findLibrary(omhome::AbstractString)::String
  local name = string("libOpenModelicaCompiler.", Libdl.dlext)
  local libdir = joinpath(omhome, "lib")
  isdir(libdir) || error("OMCompiler: $omhome is not an OpenModelica installation (no lib directory)")
  for triple in readdir(libdir)
    local path = joinpath(libdir, triple, "omc", name)
    isfile(path) && return path
  end
  error("OMCompiler: no $name in $libdir/*/omc; build OpenModelica with -DOM_OMC_ENABLE_RUST=ON")
end

"""
    init(; omhome = ENV["OPENMODELICAHOME"], lib = findLibrary(omhome), args = String[])

Load the compiler library of the OpenModelica installation `omhome` (a build's
`install_cmake`) and start omc with the command-line flags `args`.
"""
function init(; omhome::AbstractString = get(ENV, "OPENMODELICAHOME", ""), lib::AbstractString = "",
              args::Vector{String} = String[])
  isempty(lib) && isempty(omhome) && error("OMCompiler.init: set OPENMODELICAHOME or pass omhome")
  isempty(omhome) || (ENV["OPENMODELICAHOME"] = omhome)
  init(isempty(lib) ? findLibrary(omhome) : lib; args)
end

function init(lib::AbstractString; args::Vector{String} = String[])
  h = Libdl.dlopen(lib, Libdl.RTLD_GLOBAL)
  for s in SYMBOLS
    FPTR[s] = Libdl.dlsym(h, s)
  end
  rc = ccall(fp(:omjl_init), Cint, (Ptr{Ptr{Cchar}}, Cint), args, length(args))
  rc == 0 || error("OMCompiler.init: ", lasterror())
  return nothing
end

lasterror() = takestring(ccall(fp(:omjl_last_error), Ptr{Cchar}, ()))

"Evaluate a scripting command, `evaluate(\"loadModel(Modelica)\")`, and return omc's reply."
evaluate(cmd::AbstractString)::String = takestring(ccall(fp(:omjl_eval), Ptr{Cchar}, (Cstring,), cmd))

"""
    instantiate(className) -> (model, functions)

Instantiate `className` with omc's frontend: its flat model (an `NFFlatModel` node) and the
functions it calls (a vector of `NFFunction` nodes).
"""
function instantiate(className::AbstractString)
  fns = Ref{Ptr{Cvoid}}(C_NULL)
  p = ccall(fp(:omjl_instantiate), Ptr{Cvoid}, (Cstring, Ref{Ptr{Cvoid}}), className, fns)
  if p == C_NULL
    error("OMCompiler.instantiate($className): ", lasterror(), "\n", evaluate("getErrorString()"))
  end
  return (convertvalue(p), convertvalue(fns[]))
end

"""
The Julia value of the omc value `p`, taking ownership of the handle: a scalar, a `String`,
an `EnumLiteral`, a `Node`, a `Vector` (list or array), a `Tuple`, `nothing` or the value of an
option, or an `Opaque`.
"""
function convertvalue(p::Ptr{Cvoid})
  p == C_NULL && return nothing
  k = ccall(fp(:omjl_kind), Cint, (Ptr{Cvoid},), p)
  k == KIND_NODE && return Node(p)
  v = try
    if k == KIND_INTEGER
      ccall(fp(:omjl_integer), Int64, (Ptr{Cvoid},), p)
    elseif k == KIND_REAL
      ccall(fp(:omjl_real), Float64, (Ptr{Cvoid},), p)
    elseif k == KIND_BOOLEAN
      ccall(fp(:omjl_integer), Int64, (Ptr{Cvoid},), p) != 0
    elseif k == KIND_STRING
      strfield(:omjl_name, p)
    elseif k == KIND_ENUM
      EnumLiteral(Symbol(strfield(:omjl_type_name, p)), Symbol(strfield(:omjl_name, p)),
                  ccall(fp(:omjl_integer), Int64, (Ptr{Cvoid},), p))
    elseif k == KIND_OPAQUE
      Opaque(strfield(:omjl_name, p))
    else
      elems = Any[convertvalue(ccall(fp(:omjl_child), Ptr{Cvoid}, (Ptr{Cvoid}, Int64), p, i - 1))
                  for i in 1:ccall(fp(:omjl_length), Int64, (Ptr{Cvoid},), p)]
      k == KIND_TUPLE ? Tuple(elems) : k == KIND_OPTION ? (isempty(elems) ? nothing : elems[1]) : elems
    end
  finally
    ccall(fp(:omjl_free), Cvoid, (Ptr{Cvoid},), p)
  end
  return v
end

nodeptr(n::Node) = getfield(n, :ptr)

"The constructor of a node: `:CREF` for an `NFExpression.CREF`."
ctor(n::Node)::Symbol = Symbol(strfield(:omjl_name, nodeptr(n)))

"The type of a node: `:NFExpression`."
typename(n::Node)::Symbol = Symbol(strfield(:omjl_type_name, nodeptr(n)))

const FIELD_INDEX = Dict{Tuple{Symbol, Symbol}, Dict{Symbol, Int}}()

"The field names of a node."
function fields(n::Node)::Vector{Symbol}
  p = nodeptr(n)
  Symbol[Symbol(fieldname(p, i)) for i in 0:ccall(fp(:omjl_length), Int64, (Ptr{Cvoid},), p) - 1]
end

function fieldindex(n::Node)::Dict{Symbol, Int}
  get!(FIELD_INDEX, (typename(n), ctor(n))) do
    Dict(f => i - 1 for (i, f) in enumerate(fields(n)))
  end
end

"Equal for two handles to the same omc value."
nodeid(n::Node)::UInt = ccall(fp(:omjl_identity), Csize_t, (Ptr{Cvoid},), nodeptr(n))

"""
    apply(function, node)

Call one of omc's frontend functions on `node`: `"Expression.typeOf"`,
`"Expression.toString"`, `"ComponentRef.getSubscriptedType"`, `"ComponentRef.toString"`,
`"Type.toString"`, `"Equation.toString"`, `"Function.name"`, `"Path.toString"`.
"""
function apply(function_::AbstractString, n::Node)
  p = ccall(fp(:omjl_apply), Ptr{Cvoid}, (Cstring, Ptr{Cvoid}), function_, nodeptr(n))
  p == C_NULL && error("OMCompiler.apply($function_): ", lasterror())
  return convertvalue(p)
end

Base.propertynames(n::Node) = fields(n)

function Base.getproperty(n::Node, f::Symbol)
  i = get(fieldindex(n), f, nothing)
  i === nothing && error("$(typename(n)).$(ctor(n)) has no field $f")
  return convertvalue(ccall(fp(:omjl_child), Ptr{Cvoid}, (Ptr{Cvoid}, Int64), nodeptr(n), i))
end

Base.hasproperty(n::Node, f::Symbol) = haskey(fieldindex(n), f)

Base.show(io::IO, n::Node) = print(io, typename(n), ".", ctor(n), "(", join(fields(n), ", "), ")")

end # module OMCompiler
