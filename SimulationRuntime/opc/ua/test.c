#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>

int main(int argc, char** argv)
{
  const char *strs[3] = {"omc_embedded_server_init","omc_embedded_server_deinit","omc_embedded_server_update"};
  void *so = dlopen("./libomopcua.so", RTLD_LAZY);

  if (so == NULL) {
    fprintf(stderr, "Failed to load shared object: %s\n", dlerror());
    return EXIT_FAILURE;
  }

  for (int i=0; i<3; i++) {
    void *func = (void*)dlsym(so, strs[i]);
    if (!func) {
      fprintf(stderr, "Failed to load shared object %s: %s\n", strs[i], dlerror());
      return EXIT_FAILURE;
    }
  }
  return 0;
}
