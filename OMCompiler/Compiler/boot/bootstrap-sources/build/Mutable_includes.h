#ifdef __cplusplus
extern "C" {
#endif
static inline void* mutableCreate(void *data)
{
return mmc_mk_box1(0, data);
}
static inline void mutableUpdate(void *mutable, void *data)
{
MMC_STRUCTDATA(mutable)[0] = data;
}
static inline void* mutableAccess(void *mutable)
{
return MMC_STRUCTDATA(mutable)[0];
}
#ifdef __cplusplus
}
#endif
