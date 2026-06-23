/*
 * Minimal stdio implementation of the four omc_file functions the OMPlot result
 * readers (read_matlab4.c / read_csv.c) use, so they can be compiled for the web
 * build without the simulation runtime (omc_file.c pulls in the MetaModelica
 * runtime via omc_error.h). omc_strdup and omc_fseek are header-only.
 */
#include <stdio.h>

FILE* omc_fopen(const char *filename, const char *mode)
{
  return fopen(filename, mode);
}

int omc_fclose(FILE *stream)
{
  return fclose(stream);
}

size_t omc_fread(void *buffer, size_t size, size_t count, FILE *stream, int allow_early_eof)
{
  (void) allow_early_eof;
  return fread(buffer, size, count, stream);
}

size_t omc_fwrite(void *buffer, size_t size, size_t count, FILE *stream)
{
  return fwrite(buffer, size, count, stream);
}
