#include <windows.h>
#include <iostream>

//Returns the last Win32 error, in string format. Returns an empty string if there is no error.
std::string GetLastErrorAsString()
{
    //Get the error message, if any.
    DWORD errorMessageID = ::GetLastError();
    if(errorMessageID == 0)
        return std::string(); //No error message has been recorded

    LPSTR messageBuffer = NULL;
    size_t size = FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                                 NULL, errorMessageID, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPSTR)&messageBuffer, 0, NULL);

    std::string message(messageBuffer, size);

    //Free the buffer.
    LocalFree(messageBuffer);

    return message;
}

int main(int argc, char** argv)
{
  HINSTANCE dll = LoadLibrary("libomopcda.dll");

  if (dll == NULL) {
    std::cerr << "Failed to load dll file: " << GetLastErrorAsString() << std::endl;
    return EXIT_FAILURE;
  }

  void *func = (void*)GetProcAddress(dll, "opc_da_init");
  if (!func) {
    std::cerr << "Failed to load function opc_da_init: " << GetLastErrorAsString() << std::endl;
    return EXIT_FAILURE;
  }

  func = (void*)GetProcAddress(dll, "opc_da_deinit");
  if (!func) {
    std::cerr << "Failed to load function opc_da_deinit: " << GetLastErrorAsString() << std::endl;
    return EXIT_FAILURE;
  }

  func = (void*)GetProcAddress(dll, "opc_da_new_iteration");
  if (!func) {
    std::cerr << "Failed to load function opc_da_new_iteration: " << GetLastErrorAsString() << std::endl;
    return EXIT_FAILURE;
  }
  std::cout << "Success" << std::endl;
  return 0;
}
