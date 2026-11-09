# cmake -DDIR=<dir> -P web_assets_index.cmake
# Writes <dir>/index.json: each file under <dir> mapped to the start of its
# SHA-256. web_assets.cpp downloads only the files listed there.
file(GLOB_RECURSE _files RELATIVE ${DIR} ${DIR}/*)
list(REMOVE_ITEM _files index.json)
list(SORT _files)
set(_json "{")
set(_sep "")
foreach(_file IN LISTS _files)
  file(SHA256 ${DIR}/${_file} _sum)
  string(SUBSTRING ${_sum} 0 16 _sum)
  string(APPEND _json "${_sep}\n  \"${_file}\": \"${_sum}\"")
  set(_sep ",")
endforeach()
string(APPEND _json "\n}\n")
file(WRITE ${DIR}/index.json ${_json})
