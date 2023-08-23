use crate::prelude::*;

pub type Path = Vec<String>;

pub type Symbol = String;
impl<'t, S> SInto<S, Symbol> for rustc_span::symbol::Symbol {
    fn sinto(&self, _s: &S) -> Symbol {
        self.to_ident_string()
    }
}

pub type Mutability = bool;
impl<S> SInto<S, Mutability> for rustc_hir::Mutability {
    fn sinto(&self, _s: &S) -> Mutability {
        match self {
            rustc_hir::Mutability::Mut => true,
            _ => false,
        }
    }
}

pub type Const = Box<Expr>;

impl<'tcx, S: BaseState<'tcx>> SInto<S, Const> for rustc_middle::ty::Const<'tcx> {
    fn sinto(&self, s: &S) -> Const {
        let x = self.eval(s.base().tcx, get_param_env(s));
        use rustc_middle::query::Key;
        Box::new(const_to_constant_expr(s, x.clone(), x.ty(), x.default_span(s.base().tcx)).into())
    }
}