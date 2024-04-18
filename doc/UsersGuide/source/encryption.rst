.. _encryption :

OpenModelica Encryption
=======================

The encryption module allows the library developers to encrypt their libraries
for different platforms. Note that you need a special version of OpenModelica
with encryption support to do that, which is only released in binary form. This
version contains an OpenModelica-specific private key that is used internally
to decrypt the encrypted libraries for code generation only, not for display
purposes.

If you are a library developer and are interested in distributing your library
in encrypted form for use with OpenModelica, please contact us for further
information. Please note that distributing the special version of OpenModelica
with encryption support to the users of your library requires you to be a Level
2 member of the Open Source Modelica Consortium.

If you are a user of an encrypted library that is supported by OpenModelica,
please contact your library supplier for information on how to get the special
version of OpenModelica that runs it.

Encrypting the Library
----------------------

In order to encrypt the Modelica package call `buildEncryptedPackage(TopLevelPackageName)`
from mos script or from **OMEdit** right click the package in Libraries Browser and
select `Export Encrypted Package` or select `Export > Export Encrypted Package`
from the menu.

All the Modelica files are encrypted and the whole library is zipped into a
single file i.e., `PackageName.mol`. Note that you can only encrypt Modelica
packages saved in a folder structure. The complete folder structure remains
as it is. No encryption is done on the resource files.

Loading an Encrypted Library
----------------------------

To load the encrypted package call `loadEncryptedPackage(EncryptedPackage.mol)`
from the mos script or from **OMEdit** `File > Load Encrypted Package`.

Notes
-----

- Encryption support in OpenModelica does not include any license management,
  i.e., restricting the usage of a certain libraries based on some conditions,
  e.g., having paid a fee. It is only meant to prevent end users from seeing
  the Modelica source code of the encrypted parts of the libraries, for reasons
  of confidentiality or IP protection.
- The parts of the library that are protected by encryption are specified
  by the access control annotations defined by the Modelica Language Specification,
  `Section 18.9 <https://specification.modelica.org/maint/3.6/annotations.html#access-control-to-protect-intellectual-property>`_.
- The generated C code corresponding to the encrypted parts of the library is
  obfuscated: all comments are removed, and all component names are replaced by
  generic names such as n1, n2, n3, etc. This prevents easy reverse-engineering
  of the encrypted library starting from generated simulation code.
- Encryption in OpenModelica is based on the
  `SEMLA (Standardized Encryption of Modelica Libraries and Artifacts) <https://github.com/modelon-community/SEMLA>`_
  module from Modelon AB, which provides a tool-independent framework for Modelica
  library encryption.