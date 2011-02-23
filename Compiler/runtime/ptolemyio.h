/* Interface for ptolemy plot data */

void* read_ptolemy_dataset(const char* filename, int size,const char**vars,int);
int read_ptolemy_dataset_size(const char* filename);
void* read_ptolemy_variables(const char* filename);
