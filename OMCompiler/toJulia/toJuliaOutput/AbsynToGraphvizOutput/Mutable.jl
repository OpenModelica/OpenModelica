module Mutable
using ExportAll
using MetaModelica
#= Creating mutable (shared) objects

This uniontype contains routines for creating and updating objects,
similar to array<> structures. =#

#= For julia just keep a presistant dictonary of all mutables =#
@Uniontype UMutable begin
  @Record MUTABLE begin
    data
  end
end

T = Any
function create(data::T)::UMutable
  local mutable::UMutable
  MUTABLE(data)
end

T = Any
function update(mutable::UMutable, data::T)
  #= Defined in the runtime =#
end

T = Any
function access(mutable::UMutable)::T
end

@exportAll()

end
