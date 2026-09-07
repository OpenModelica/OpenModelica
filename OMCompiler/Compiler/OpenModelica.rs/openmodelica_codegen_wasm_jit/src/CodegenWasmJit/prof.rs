//! The profiling plan (`-clock`, LOG_PROFILE hooks).

use super::*;

/// Visit `e` and every equation nested inside it, along the paths
/// [`lower_equation`] descends — the casual tearing set of a dynamically torn
/// system included.
pub(super) fn visit_nested_eqs(e: &Arc<SimCode::SimEqSystem>, f: &mut dyn FnMut(&Arc<SimCode::SimEqSystem>)) {
    use SimCode::SimEqSystem as E;
    fn visit_list(
        eqs: &List<Arc<SimCode::SimEqSystem>>,
        f: &mut dyn FnMut(&Arc<SimCode::SimEqSystem>),
    ) {
        for e in lst(eqs) {
            visit_nested_eqs(e, f);
        }
    }
    f(e);
    match &**e {
        E::SES_IFEQUATION { ifbranches, elsebranch, .. } => {
            for (_, branch) in lst(ifbranches) {
                visit_list(branch, f);
            }
            visit_list(elsebranch, f);
        }
        E::SES_ENTWINED_ASSIGN { single_calls, .. } => visit_list(single_calls, f),
        E::SES_MIXED { cont, discEqs, .. } => {
            visit_nested_eqs(cont, f);
            visit_list(discEqs, f);
        }
        E::SES_WHEN { elseWhen: Some(w), .. } => visit_nested_eqs(w, f),
        E::SES_FOR_EQUATION { body, .. } => visit_list(body, f),
        E::SES_LINEAR { lSystem, alternativeTearing, .. } => {
            for s in std::iter::once(lSystem).chain(alternativeTearing.iter()) {
                visit_list(&s.residual, f);
                for (_, _, inner) in lst(&s.simJac) {
                    visit_nested_eqs(inner, f);
                }
            }
        }
        E::SES_NONLINEAR { nlSystem, alternativeTearing, .. } => {
            for s in std::iter::once(nlSystem).chain(alternativeTearing.iter()) {
                visit_list(&s.eqs, f);
            }
        }
        _ => {}
    }
}
