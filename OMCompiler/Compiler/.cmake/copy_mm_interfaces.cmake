# Copies the interfaces and dependency lists of the MetaModelica sources from
# FROM to TO. Used by msvc_sources.cmake.
file(GLOB files ${FROM}/*.interface.mo ${FROM}/*.public.imports ${FROM}/*.depends)
file(COPY ${files} DESTINATION ${TO})
