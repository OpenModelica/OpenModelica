  module Autoconf


    using MetaModelica

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
         configureCommandLine = "Configured 2019-07-03 16:13:02 using arguments:  '--disable-option-checking' '--prefix=/home/johti17/OpenModelica/build' 'CC=clang-9' 'CXX=clang++-9' '--without-omc' '--with-ombuilddir=/home/johti17/OpenModelica/build' '--cache-file=/dev/null' '--srcdir=.'"::String
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
         systemLibs = list("-lomcruntime", "-lexpat", "-lsqlite3", "-llpsolve55", corbaLibs, "-lomcgc", hwloc)::List
         triple = "x86_64-linux-gnu"::String

  end