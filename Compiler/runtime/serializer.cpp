

#include <stack>
//#include <unordered_map>
#include <map>
#include <string>
#include <vector>
#include <fstream>
#include "meta_modelica.h"
#include <stdint.h>

extern "C"
{


/* This is used to keep track of generated record_description,
   that way we don't generate new every time something is de-serialized */
std::map<std::string,record_description*> record_cache;


static const uint8_t TAG_INT_TINY     = 0x00;
static const uint8_t TAG_INT_SMALL    = 0x10;
static const uint8_t TAG_INT_BIG      = 0x20;
static const uint8_t TAG_DOUBLE       = 0x30;
static const uint8_t TAG_STRING_SMALL = 0x40;
static const uint8_t TAG_STRING_BIG   = 0x50;
static const uint8_t TAG_STRUCT_SMALL = 0x60;
static const uint8_t TAG_STRUCT_BIG   = 0x70;
static const uint8_t TAG_SHARED_TINY  = 0x80;
static const uint8_t TAG_SHARED_SMALL = 0x90;
static const uint8_t TAG_SHARED_BIG   = 0xA0;


/*  SERIALIZATION */

/* Writes 8 bits to the buffer */
void write8(uint8_t v0,std::string& buffer){
    buffer.push_back(v0);
    //printf("%02X ",v0);
}

/* Writes 16 bits to the buffer */
void write16(uint16_t v0,std::string& buffer){
    uint8_t h = (v0 & 0xFF00)>>8;
    uint8_t l = v0 & 0xFF;
    buffer.push_back(h);
    buffer.push_back(l);
    //printf("%02X ",h);
    //printf("%02X ",l);
}

/* Writes 32 bits to the buffer */
void write32(uint32_t v0,std::string& buffer){
    write16((v0>>16) & 0xFFFF,buffer);
    write16(v0       & 0xFFFF,buffer);
}

/* Writes 64 bits to the buffer */
void write64(uint64_t v0,std::string& buffer){
    write32((v0>>32) & 0xFFFFFFFF,buffer);
    write32(v0       & 0xFFFFFFFF,buffer);
}

/* Writes a tag value */
void writeTag(uint8_t v0,std::string& buffer){
    write8(v0,buffer);
}

/* Writes an integer considering the required size */
void writeInt(mmc_sint_t value,std::string& buffer){
    if(value >= -8 && value <= 7){ // tiny integer
        writeTag(TAG_INT_TINY | (0x0F & value),buffer);
    }
    else if(value >= -2147483648 && value <= 2147483647) // regular 32 signed int
    {
        int32_t cropped = value;
        uint32_t* pv    = (uint32_t*)&cropped;
        writeTag(TAG_INT_SMALL,buffer);
        write32(*pv,buffer);
    }
    else
    {
        int64_t cropped = value;
        uint64_t* pv    = (uint64_t*)&cropped;
        writeTag(TAG_INT_BIG,buffer);
        write64(*pv,buffer);
    }

}

/* Writes an real value always as 64 bits */
void writeReal(double value,std::string& buffer){
    writeTag(TAG_DOUBLE,buffer);    // double -> 3
    unsigned long long* ivalue = (unsigned long long*) &value;
    write64(*ivalue,buffer);
}

/* Writes a string considering the required size */
void writeString(mmc_uint_t size,const char* data,std::string& buffer){
    if(size<256){
        writeTag(TAG_STRING_SMALL,buffer);
        write8(size,buffer);
    }
    else {
        writeTag(TAG_STRING_BIG,buffer);
        write64(size,buffer);
    }
    mmc_uint_t i = 0;
    while(i<size){
        write8(data[i],buffer);
        i++;
    }
}

void writeStruct(mmc_uint_t size,mmc_uint_t ctor,std::string& buffer){
    if(size<16){
        writeTag(TAG_STRUCT_SMALL|(size&0x0F),buffer);
    }
    else {
        writeTag(TAG_STRUCT_BIG,buffer);
        write64(size,buffer);
    }
    write8(ctor,buffer);
}

void writeShared(mmc_uint_t index,std::string& buffer){
    //printf("shared(%i) -> ",index);
    if(index<=0xFFFF){
        writeTag(TAG_SHARED_TINY,buffer);
        write16(index,buffer);
    }
    else if(index <= 0xFFFFFFFF)
    {
        writeTag(TAG_SHARED_SMALL,buffer);
        write32(index,buffer);
    }
    else
    {
        writeTag(TAG_SHARED_BIG,buffer);
        write64(index,buffer);
    }
    //printf("\n");
}

/* Tries to insert the object to the seen-object list. If it has been found before it writes a shared object instead.
   Returns true if the object is new, false if it's shared */
bool isNewObject(void* ptr,std::string& buffer, std::map<void*,uint64_t> &objcache){
    std::pair<std::map<void*,uint64_t>::iterator,bool> ret;
    ret = objcache.insert(std::pair<void*,uint64_t>(ptr,objcache.size()));
    if(ret.second==false){
        writeShared(ret.first->second,buffer);
        return false;
    }
    //printf("%i:",objcache.size()-1);
    return true;
}

/* Record descriptions are serialized as [path,name,[field1,...,fieldn]] */
void writeRecordDescription(struct record_description* desc,mmc_uint_t slots,std::string& buffer,std::map<void*,uint64_t> &objcache){
    mmc_uint_t size = 0;
    //printf("ctor(%i,%i) -> ", 3,255);
    writeStruct(3,255,buffer); // Serializes the objec as an array.
    //printf("\n");

    // Here's a hack that adds 1 to the pointer (&desc->path+1) since &desc == &desc->path
    bool new_path = isNewObject((void*)((char*)(&desc->path)+1),buffer,objcache);
    if(new_path){
        size = strlen(desc->path);
        //printf("%s ->", desc->path);
        writeString(size,desc->path,buffer);
        //printf("\n");
    }
    bool new_name = isNewObject((void*)(&desc->name),buffer,objcache);
    if(new_name){
        size = strlen(desc->name);
        //printf("%s ->", desc->name);
        writeString(size,desc->name,buffer);
        //printf("\n");
    }

    bool new_fields = isNewObject((void*)(&desc->fieldNames),buffer,objcache);
    if(new_fields){
        //printf("ctor(%i,%i) -> ", slots-1,255);
        writeStruct(slots-1,255,buffer);
        //printf("\n");
        for(mmc_uint_t i = 0; i<slots-1; i++){
            bool new_field = isNewObject((void*)(&desc->fieldNames[i]),buffer,objcache);
            size = strlen(desc->fieldNames[i]);
            //printf("%s -> ", desc->fieldNames[i]);
            writeString(size,desc->fieldNames[i],buffer);
            //printf("\n");
        }
    }
}

void serialize(modelica_metatype input_object,std::string& buffer){

    std::stack<modelica_metatype> objstack;
    std::map<void*,uint64_t> objcache;
    buffer.reserve(1024*1024);
    //Inserts the object to the stack
    objstack.push(input_object);

    while(!objstack.empty()){
        // Takes the next object in the stack
        modelica_metatype object = objstack.top();
        objstack.pop();

        /* Integer */
        if(MMC_IS_IMMEDIATE(object)){
            mmc_sint_t value = MMC_UNTAGFIXNUM(object);
            //printf("%i -> ",value);
            writeInt(value,buffer);
            //printf("\n");
            continue;
        }
        mmc_uint_t hdr = MMC_GETHDR(object);
        /* Real */
        if(hdr==MMC_REALHDR){
            double value = mmc_unbox_real(object);
            //printf("%f -> ",value);
            writeReal(value,buffer);
            //printf("\n");
            continue;
        }

        void* ptr = MMC_UNTAGPTR(object);

        /* any other value */
        if(isNewObject(ptr,buffer,objcache)){ // the element was not in the map
            if(MMC_HDRISSTRING(hdr)){
                //printf("%s -> ",MMC_STRINGDATA(object));
                writeString(MMC_HDRSTRLEN(hdr),MMC_STRINGDATA(object),buffer);
                //printf("\n");
            }
            else if(MMC_HDRISSTRUCT(hdr)){
                mmc_uint_t slots = MMC_HDRSLOTS(hdr);
                mmc_uint_t ctor  = MMC_HDRCTOR(hdr);
                int count        = slots;
                int left         = 0;

                //printf("ctor(%i,%i) -> ", slots,ctor);
                writeStruct(slots,ctor,buffer);
                //printf("\n");
                if(ctor>=3 && ctor!=255){ // It's a meta record
                    struct record_description* desc = (struct record_description*) MMC_FETCH(MMC_OFFSET(ptr,1));
                    if(isNewObject((void*)desc,buffer,objcache)){ // it's a new record
                        writeRecordDescription(desc,slots,buffer,objcache);
                    }
                    left=1;
                }
                // Push the sub-objects to the stack
                while(count>left){
                    objstack.push(MMC_FETCH(MMC_OFFSET(ptr, count)));
                    count--;
                }
            }
        }
    }
    write64(objcache.size(),buffer);
    //printf("\nserialized %i objects\n",objcache.size());
}


/*  DE-SERIALIZATION */


void readFile(char* filename,std::string& buffer){
    std::ifstream input_file(filename,std::ifstream::in | std::ifstream::binary);

    input_file.seekg(0, std::ios::end);
    buffer.reserve(input_file.tellg());
    input_file.seekg(0, std::ios::beg);

    buffer.assign((std::istreambuf_iterator<char>(input_file)),
                std::istreambuf_iterator<char>());
}

/* Reads 16 bits from the buffer and moves the index forward */
uint16_t read16(mmc_uint_t &index,unsigned char* data){
    uint16_t value = (uint16_t)data[index]<<8 | data[index+1];
    index+=2;
    return value;
}

/* Reads 32 bits from the buffer and moves the index forward */
uint32_t read32(mmc_uint_t &index,unsigned char* data){
    uint32_t value = (uint32_t)data[index]<<24 | (uint32_t)data[index+1]<<16 | (uint32_t)data[index+2]<<8 | (uint32_t)data[index+3];
    index+=4;
    return value;
}

/* Reads 32 bits from the buffer and moves the index forward */
uint64_t read64(mmc_uint_t &index,unsigned char* data){
    uint64_t value =
            (uint64_t)data[index]<<56 | (uint64_t)data[index+1]<<48 | (uint64_t)data[index+2]<<32 | (uint64_t)data[index+3] | (uint64_t)data[index+4]<<24 | (uint64_t)data[index+5]<<16 | (uint64_t)data[index+6]<<8 | (uint64_t)data[index+7];
    index+=8;
    return value;
}

modelica_metatype readInteger(uint8_t tag,mmc_uint_t &index,unsigned char* data){
    uint8_t uvalue8;
    int8_t  value8;
    int32_t value32;
    int64_t value64;
    switch(tag){
        case TAG_INT_TINY:
            uvalue8 = data[index]&0x0F;
            if(uvalue8>7)
                value8 = uvalue8 | 0xF0;
            else
                value8 = uvalue8;
            index=index+1;
            //printf("%i\n", value8);
            return mmc_mk_integer(value8);
        case TAG_INT_SMALL:
            index++;
            value32 = read32(index,data);
            //printf("%i\n", value32);
            return mmc_mk_integer(value32);
        case TAG_INT_BIG:
            index++;
            value64 = read64(index,data);
            //printf("%i\n", value64);
            return mmc_mk_integer(value64);
        default: return mmc_mk_integer(0);
    }
}


modelica_metatype readReal(uint8_t tag,mmc_uint_t &index,unsigned char* data){
    index++;
    uint64_t ivalue = read64(index,data);
    double* fvalue = (double*)(&ivalue);
    //printf("%f\n", *fvalue);
    return mmc_mk_real(*fvalue);
}


modelica_metatype readString(uint8_t tag,mmc_uint_t &index,unsigned char* data){
    uint64_t size = 0;
    switch(tag){
        case TAG_STRING_SMALL:
            index++;
            size = data[index];
            index++;
            break;
        case TAG_STRING_BIG:
            index++;
            size = read64(index,data);
            break;
        default: break;
    }

    modelica_metatype res = mmc_mk_scon_len(size+1);
    const char* str = (const char*)&(data[index]);
    index += size;

    // debug prints
    //for(int i = 0;i<size;i++){
    //    putchar(str[i]);
    //}
    //printf("\n");
    memcpy(MMC_STRINGDATA(res), str, size);
    MMC_STRINGDATA(res)[size]=0;
    return res;
}

char* readString_raw(uint8_t tag,mmc_uint_t &index,unsigned char* data){
    uint64_t size = 0;
    switch(tag){
        case TAG_STRING_SMALL:
            index++;
            size = data[index];
            index++;
            break;
        case TAG_STRING_BIG:
            index++;
            size = read64(index,data);
            break;
        default: break;
    }

    char* res = new char[size+1];
    const char* str = (const char*)&(data[index]);
    index += size;

    //for(int i = 0;i<size;i++){
    //    putchar(str[i]);
    //}
    //printf("\n");
    memcpy(res, str, size);
    res[size]=0;
    return res;
}

modelica_metatype readShared(uint8_t tag,mmc_uint_t &index,unsigned char* data,std::vector<modelica_metatype> &shared){
    uint64_t i64;
    uint16_t i16;
    uint32_t i32;
    index++;
    switch(tag){
        case TAG_SHARED_TINY:
            i16 = read16(index,data);
            //printf("shared(%i)\n",i16);
            return shared[i16];
            break;
        case TAG_SHARED_SMALL:
            i32 = read32(index,data);
            //printf("shared(%i)\n",i32);
            return shared[i32];
            break;
        case TAG_SHARED_BIG:
            i64 = read64(index,data);
            //printf("shared(%i)\n",i64);
            return shared[i64];
            break;
        default: break;
    }
    return 0;
}

void readStruct(uint8_t tag, mmc_uint_t &index, uint8_t* data, mmc_uint_t &size, mmc_uint_t &ctor){
    switch(tag){
        case TAG_STRUCT_SMALL:
            size = data[index] & 0x0F;
            index++;
            break;
        case TAG_STRUCT_BIG:
            index++;
            size = read64(index,data);
            break;
        default: break;
    }
    ctor = data[index];
    index++;
}

modelica_metatype allocValue(mmc_uint_t size,mmc_uint_t ctor){
  struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(size+1);
  p->header = MMC_STRUCTHDR(size, ctor);
  return MMC_TAGPTR(p);
}

void setToNextField(modelica_metatype sub,std::stack<std::pair<modelica_metatype,int> > &stack){
    std::pair<modelica_metatype,int> next = stack.top();
    stack.pop();
    MMC_STRUCTDATA(next.first)[next.second-1]=sub;
}

/* This is a special case of the de-serialization to restore the record_descriptions */
record_description* readRecordDescription(mmc_uint_t &index,unsigned char* data,std::vector<modelica_metatype> &shared){
    mmc_uint_t size,ctor;
    struct record_description* pdesc;
    uint8_t tag = data[index]&0xF0;
    switch(tag){
        case TAG_SHARED_TINY:
        case TAG_SHARED_SMALL:
        case TAG_SHARED_BIG:
            pdesc = (struct record_description*)readShared(tag,index,data,shared);
            break;

        case TAG_STRUCT_SMALL:
        case TAG_STRUCT_BIG:
            readStruct(tag,index,data,size,ctor); // skipping since we already know what it is
            // Read the path
            char* path = readString_raw(data[index]&0xF0,index,data);
            // check if we already have a description for this path
            std::map<std::string,record_description*>::iterator it = record_cache.find(std::string(path));

            if(it==record_cache.end()){
                pdesc = new struct record_description;
                shared.push_back(pdesc);

                shared.push_back(path);
                // Read the name
                char* name = readString_raw(data[index]&0xF0,index,data);
                shared.push_back(name);
                // Read the array
                readStruct(data[index]&0xF0,index,data,size,ctor); // this should be an array
                shared.push_back(0); // pushes anything since this objects are not reused
                char** fields = new char*[size];
                // Now read the fields
                for(int i=0;i<size;i++){
                    char* field = readString_raw(data[index]&0xF0,index,data);
                    shared.push_back(field);
                    fields[i] = field;
                }
                pdesc->path = path;
                pdesc->name = name;
                pdesc->fieldNames = (const char**) fields;
                // Insert the record description to the global cache of descriptions
                record_cache.insert( std::pair<std::string,record_description*>(std::string(path),pdesc));
            }
            else {
                pdesc = it->second;
                // Now we read the data but we release the memory since we are not gonna use it
                // (This part can be optimized)
                shared.push_back(pdesc);
                shared.push_back(0);
                // Read the name
                char* name = readString_raw(data[index]&0xF0,index,data);
                shared.push_back(0);
                // Read the array
                readStruct(data[index]&0xF0,index,data,size,ctor); // this should be an array
                shared.push_back(0); // pushes anything since this objects are not reused
                // Now read the fields
                for(int i=0;i<size;i++){
                    char* field = readString_raw(data[index]&0xF0,index,data);
                    delete[] field;
                    shared.push_back(0);
                }
                delete[] path;
                delete[] name;
            }
            break;
    }
    return pdesc;
}

modelica_metatype deserialize(std::string& buffer){
    modelica_metatype  result,current;
    result = allocValue(1,0);
    unsigned char* data = (unsigned char*) buffer.c_str();
    mmc_uint_t index = 0;
    mmc_uint_t size=0;
    mmc_uint_t ctor=0;
    std::vector<modelica_metatype> shared;
    std::stack<std::pair<modelica_metatype,int> > stack;

    stack.push(std::make_pair(result,1));

    while(!stack.empty()){
       unsigned char tag = data[index] & 0xF0;
       switch(tag){ // integer
          case TAG_INT_TINY:
          case TAG_INT_SMALL:
          case TAG_INT_BIG:
            current = readInteger(tag,index,data);
            setToNextField(current,stack);
            break;
          case TAG_DOUBLE:
            current = readReal(tag,index,data);
            setToNextField(current,stack);
            break;
          case TAG_STRING_SMALL:
          case TAG_STRING_BIG:
            current = readString(tag,index,data);
            setToNextField(current,stack);
            shared.push_back(current);
            break;
          case TAG_SHARED_TINY:
          case TAG_SHARED_SMALL:
          case TAG_SHARED_BIG:
            current = readShared(tag,index,data,shared);
            setToNextField(current,stack);
            break;
          case TAG_STRUCT_SMALL:
          case TAG_STRUCT_BIG:
            size = 0;
            ctor = 0;
            readStruct(tag,index,data,size,ctor);
            //printf("%i:ctor(%i,%i)\n",shared.size(),size,ctor);
            if(ctor>=3 && ctor!=255){ // not an array
                current = allocValue(size,ctor);
                shared.push_back(current);
                setToNextField(current,stack);
                while(size>0){
                    stack.push(std::make_pair(current,size));
                    size--;
                }
                modelica_metatype record_desc = readRecordDescription(index,data,shared);
                setToNextField(record_desc,stack);
            }
            else {
                current = allocValue(size,ctor);
                shared.push_back(current);
                setToNextField(current,stack);
                while(size>0){
                    stack.push(std::make_pair(current,size));
                    size--;
                }
            }
            break;
          default: break;
       }
    }
    uint64_t total = read64(index,data);
    //printf("Sent %i :  Received %i\n",total,shared.size());
    return MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(result), 1));
}


static int indent_level = 0;

void pushBlock(){
    indent_level++;
}

void popBlock(){
    indent_level--;
}

void indent(){
    int count = indent_level;
    while(count){
        putchar(' ');
        putchar(' ');
        count--;
    }
}

void Serializer_showBlocks(modelica_metatype object){
    if(MMC_IS_IMMEDIATE(object)){
        indent();
        printf("%i\n",MMC_UNTAGFIXNUM(object));
        return;
    }
    mmc_uint_t hdr = MMC_GETHDR(object);
    if(MMC_HDRISSTRING(hdr)){
        indent();
        printf("str(%i)=\"%s\"\n",MMC_HDRSTRLEN(hdr),MMC_STRINGDATA(object));
        return;
    }
    if(hdr==MMC_REALHDR){
        indent();
        printf("%f\n",mmc_unbox_real(object));
        return;
    }
    if(MMC_HDRISSTRUCT(hdr)){
        mmc_uint_t slots = MMC_HDRSLOTS(hdr);
        mmc_uint_t ctor  = MMC_HDRCTOR(hdr);
        int count = slots-1;
        if(ctor==255){// it's an array
            indent();
            printf("array(%i)\n",slots);
        }
        else {
            indent();
            printf("ctr(%i,%i)\n",ctor,slots);
            if(ctor>=3 && ctor!=255){ // It's a meta record
                struct record_description* desc = (struct record_description*) MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(object),1));
                indent();printf("  - %s\n",desc->path);
                count--;
            }
        }
        pushBlock();
        while(count>=0){
            Serializer_showBlocks(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(object), slots-count)));
            count--;
        }
        popBlock();
        return;
    }

    printf("Unknown object %i\n",hdr);
}


void Serializer_outputFile(modelica_metatype input_object,char* filename){
    std::fstream fs;
    std::string buffer;
    serialize(input_object,buffer);
    fs.open (filename,std::fstream::out | std::fstream::binary);
    fs.write(buffer.c_str(),buffer.size());
    fs.close();
}

modelica_metatype Serializer_bypass(modelica_metatype input_object){
    std::string buffer;
    serialize(input_object,buffer);
    modelica_metatype out = deserialize(buffer);
    //printf("Input object\n");
    //Serializer_showBlocks(input_object);
    //printf("Output object\n");
    //Serializer_showBlocks(out);
    return out;
}



}