typedef struct gzFile_s *gzFile;
gzFile gzopen(const char *path, const char *mode);
int gzclose(gzFile file);

double FmuZlibLinkOrder_missing(double t)
{
  gzFile f = gzopen("FmuZlibLinkOrder-missing.gz", "rb");
  if (f) {
    gzclose(f);
    return 0.0;
  }
  return 1.0;
}
