  module Autoconf


    using MetaModelica
    #= ExportAll is not good practice but it makes it so that we do not have to write export after each function :( =#
    using ExportAll

         haveBStatic = true::Bool
         bstatic = if haveBStatic
               "-Wl,-Bstatic"
             else
               ""
             end::String
         bdynamic = if haveBStatic
               "-Wl,-Bdynamic"
             else
               ""
             end::String
         configureCommandLine = "Configured 2019-07-26 11:09:56 using arguments:  '--disable-option-checking' '--prefix=/home/johti17/OpenModelica/build' '--with-omc=/~/OpenModelica/build/bin/omc' 'CC=clang-9' 'CXX=clang++-9' '--with-ombuilddir=/home/johti17/OpenModelica/build' '--cache-file=/dev/null' '--srcdir=.'"::String
         os = "linux"::String
         make = "make"::String
         exeExt = ""::String
         dllExt = ".so"::String
         ldflags_runtime = " -Wl,--no-as-needed -Wl,--disable-new-dtags -lOpenModelicaRuntimeC  -llapack -lblas   -lm -lomcgc -lpthread -rdynamic"::String
         ldflags_runtime_sim = " -Wl,--no-as-needed -Wl,--disable-new-dtags -lSimulationRuntimeC  -llapack -lblas   -lm -lomcgc -lpthread -rdynamic -Wl,--no-undefined"::String
         ldflags_runtime_fmu = " -Wl,--no-as-needed -Wl,--disable-new-dtags  -llapack -lblas   -lm -lpthread -rdynamic -Wl,--no-undefined"::String
         platform = "Unix"::String
         pathDelimiter = "/"::String
         groupDelimiter = ":"::String
         corbaLibs = ""::String
         hwloc = if 0 == 1
               "-lhwloc"
             else
               ""
             end::String
         systemLibs = list("-lomcruntime", "-lexpat", "-lsqlite3", "-llpsolve55", corbaLibs, "-lomcgc", hwloc)::List{String}
         triple = "x86_64-linux-gnu"::String

    #= So that we can use wildcard imports and named imports when they do occur. Not good Julia practice =#
    @exportAll()
  end