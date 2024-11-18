Backwards Compatibility of OpenModelica Released Versions
=========================================================

The development of OpenModelica is guided by two basic principles:

#. Follow the `Modelica Language Specification <https://specification.modelica.org>`_ (MLS) as strictly as possible.
#. Preserve backwards compatibility as much as possible.

The Open Source Modelica Consortium strongly believes in open standards, as enablers of strong
and healthy eco-systems involving software tool developers and software tool users. Strict
compliance with the MLS is the key factor to enable portability of models among different
Modelica tools, which gives a huge added value to the Modelica community, compared to other
communities of users of software using proprietary modelling languages. Compliance to the
standard not only gives you the freedom to switch from one tool to another, avoiding vendor
lock-in and protecting the value of your investment in modelling in the long term, but also
allows you to use different tools simultaneously on the same Modelica code for different purposes,
e.g., simulation, generation of FMUs, sensitivity analysis, parameter optimization, optimal
control, etc. Hence, the development of OpenModelica development strives to implement the
MLS standard as strictly as possible.

The Open Source Modelica Consortium also recognizes the value of the code developed by the
users of OpenModelica. There is hardly anything more annoying than not being able to use legacy
code with up-to-date versions of a software tool. Hence, the Consortium strives to keep
newer versions of OpenModelica fully backwards compatible with older ones and is committed
to releasing patch versions of the latest x.y.0 release of the software, in case regressions
from previously released versions are reported on the
`OpenModelica issue tracker <https://github.com/OpenModelica/OpenModelica/issues>`_.

Given this commitment, we strongly recommend OpenModelica users to always use the latest released
version of the software, to benefit from bug fixes, performance improvements and new added
features. If you find any backwards-compatibility issue with new released versions, we strongly
encourage you to report them on the `issue tracker <https://github.com/OpenModelica/OpenModelica/issues>`_;
chances are that it can get fixed in the nightly build in a short time, if possible.

Given the first stated principle, compliance to the MLS, there is one exception to the rule of
keeping backwards compatibility: if we find that OpenModelica is not following the MSL for some
reason, we try to fix it as soon as possible. This means that a model or library developed with
older versions of OpenModelica may not work with more recently released version of the software
*because the Modelica code was invalid according to the MLS*, but the older version of OpenModelica
accepted it anyway. You can check ticket `#10386 <https://github.com/OpenModelica/OpenModelica/issues/10386>`_
for one such example.

In these cases, one may be tempted to stick indefinitely to the latest version of OpenModelica
that handled the invalid Modelica code successfully. Although you are of course free to do so,
we do not recommend this policy because you are going to miss all the improvements to the OpenModelica
software in the future. More importantly, if you then discover bugs that prevent you from using your
Modelica code in new situations, we can't help you in any way, because you are locked to an
old version for which we cannot provide maintenance support.

The ideal solution to handle these cases is to update the Modelica source code of the models to make it
fully compliant with the MLS. This ensures maximum portability and long-term support of your Modelica code.

In case this is not possible for some reason, e.g. lack of time and resources, or the fact that the
legacy code belongs to Modelica libraries you did not develop yourself, we provide a way to cope
with non-standard Modelica code in newer version of OpenModelica: the 
`--allowNonStandardModelica <https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/omchelptext.html#omcflag-allownonstandardmodelica>`_
compiler flag allows to disable some Modelica compatibility checks and continue using your legacy
code with newer versions of the compiler. This flag can be set in OMEdit in the
*Tools | Options | Simulation | Additional Translation Flags*.
