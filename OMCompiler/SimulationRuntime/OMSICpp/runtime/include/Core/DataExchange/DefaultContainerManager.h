#pragma once
/** @addtogroup dataexchange

 *
 *  @{
 */
#include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>

/**
 * A container manager that is designed for single threaded write output. It has just one container that can
 * be filled with values and written directly.
 */
class DefaultContainerManager : public Writer
{
  private:
    write_data_t _container;

  protected:
    /**
     * Write the given container to the result file.
     * @param container The container that should be written.
     */
    void writeContainer(const write_data_t& container)
    {
      write(get<0>(container),get<1>(container));
    }

  public:
    DefaultContainerManager() :
      _container()
    {
    }

    virtual ~DefaultContainerManager()
    {
    }
    /**
     * Get the internal container. It is always the same.
     * @return A reference to the internal container that can be filled with values.
     */
    virtual write_data_t& getFreeContainer()
    {
      return _container;
    };
    /**
     * Write the given container to the result file.
     * @param container The container that should be written.
     */
    virtual void addContainerToWriteQueue(const write_data_t& container)
    {
      writeContainer(container);
    };
};
/** @} */ // end of dataexchange
