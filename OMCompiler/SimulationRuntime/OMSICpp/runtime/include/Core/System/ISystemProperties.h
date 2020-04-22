#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */
/*****************************************************************************/
/**

Abstract interface class for system properties in open modelica.


*/


class ISystemProperties
{
public:
    virtual ~ISystemProperties()
    {
    };

    /// M is regular
    virtual bool isODE() /*const*/ = 0;

    /// M is singular
    virtual bool isAlgebraic() /*const*/ = 0;

    /// System is able to provide the Jacobian symbolically
    virtual bool provideSymbolicJacobian() /*const*/ = 0;
};

/** @} */ // end of coreSystem
