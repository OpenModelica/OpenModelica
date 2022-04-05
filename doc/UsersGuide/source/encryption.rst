.. _encryption :

OpenModelica Encryption
=======================

The encryption module allows the library developers to encrypt their libraries
for different platforms. Note that you need a special version of OpenModelica
with encryption support. Contact us if you want one.

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

- There is no license management and obfuscation of the generated code and
  files. However just a basic encryption and decryption is supported along with
  full support for protection access annotation as defined in
  Modelica specification 18.9. This means that anyone who has an OpenModelica
  version with encryption support can encrypt or decrypt files.

- OpenModelica encryption is based on
  `SEMLA (Standardized Encryption of Modelica Libraries and Artifacts) <https://github.com/modelon-community/SEMLA>`_
  module from Modelon AB.
