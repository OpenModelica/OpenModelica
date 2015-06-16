#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */
class IHistory;
class IWriteOutput
{
public:
  /// Enumeration to control the output
  enum OUTPUT
  {
    UNDEF_OUTPUT = 0x00000000,
    WRITEOUT     = 0x00000001,  ///< vxworks! Store current position of curser and write out current results
    RESET        = 0x00000002,  ///< Reset curser position
    OVERWRITE    = 0x00000003,  ///< RESET|WRITE
    HEAD_LINE    = 0x00000010,  ///< Write out head line
    RESULTS      = 0x00000020,  ///< Write out results
    SIMINFO      = 0x00000040   ///< Write out simulation info (e.g. number of steps)
  };

  virtual ~IWriteOutput() {};

  /// Output routine (to be called by the solver after every successful integration step)
  virtual void writeOutput(const OUTPUT command = UNDEF_OUTPUT) = 0;
  virtual IHistory* getHistory() = 0;
};
/** @} */ // end of coreSystem