package org.openmodelica;

import java.util.Map;

/** Interface that tags a ModelicaRecord because Uniontypes
 * are tagged using interfaces and cannot inherit from ModelicaRecord.
 * Instead, they are tagged using this interface... Thus, external
 * Java uniontypes also use this function for consistency.
 */
public interface IModelicaRecord extends ModelicaObject,Map<String,ModelicaObject> {
  /** ctor_index is -2 for ModelicaRecord and should be set to
   * -1 for any regular record that is returned to OMC.
   * The DefinitionsCreator will create record classes that fulfill
   * this criteria.
   * For a record in a uniontype, the value is 0..n where the index
   * corresponds to the order in which the the records were declared
   * in the uniontype.
   */
  int get_ctor_index();
}
