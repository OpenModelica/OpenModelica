#include <stdio.h>
#include "ExternalCFuncInputOnly.h"

void  WriteDataC(Data* data)
{
    if (data->value)
    {
      printf("received name: %s\n",data->name);
    }
}
