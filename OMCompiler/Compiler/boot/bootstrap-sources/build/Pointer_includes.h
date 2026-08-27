#ifdef __cplusplus
extern "C" {
#endif
static inline void* pointerCreate(void *data)
{
return mmc_mk_box1(0, data);
}
static inline void pointerUpdate(threadData_t *threadData, void *ptr, void *data)
{
if (valueConstructor(ptr)!=0) {
MMC_THROW_INTERNAL();
}
MMC_STRUCTDATA(ptr)[0] = data;
}
static inline void* pointerAccess(void *ptr)
{
return MMC_STRUCTDATA(ptr)[0];
}
#ifdef __cplusplus
}
#endif
