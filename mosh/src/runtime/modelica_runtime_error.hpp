//
// Copyright PELAB, Linkoping University
//

#ifndef MODELICA_RUNTIME_ERROR_
#define MODELICA_RUNTIME_ERROR_

#include <stdexcept>

class modelica_runtime_error : public runtime_error
{
public:
  modelica_runtime_error (const char* what_arg)
    : runtime_error(what_arg) {};

};

#endif
