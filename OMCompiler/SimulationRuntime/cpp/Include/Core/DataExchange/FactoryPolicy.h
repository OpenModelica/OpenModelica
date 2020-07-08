/** @addtogroup dataexchange
*
*  @{
*/
#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
  #include <Core/DataExchange/ParallelContainerManager.h>
  typedef ParallelContainerManager ContainerManager;
#else
  #include <Core/DataExchange/DefaultContainerManager.h>
  typedef DefaultContainerManager ContainerManager;
#endif
  /** @} */
