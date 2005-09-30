/* Interface for ptolemy plot data */

extern "C"
{
  void * read_ptolemy_dataset(char*filename, int size,char**vars,int);
  void * read_ptolemy_dataset_size(char*filename);
}
