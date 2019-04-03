#include <stdio.h>
#include <string.h>
#include <assert.h>

void *fooCtor()
{
  fprintf(stderr,"Foo ctor called\n");

  return (void*)0x11111111;
}

void fooDtor(void *obj)
{
  fprintf(stderr,"Foo dtor called\n");

  assert(obj==(void*)0x11111111);
}

void *barCtor(void *param)
{
  fprintf(stderr,"Bar ctor called (param=%p)\n",param);

  assert(param==(void*)0x11111111);
  return (void*)0x222222222;
}

void barDtor(void *obj)
{
  fprintf(stderr,"Bar dtor called\n");

  assert(obj==(void*)0x222222222);
}
