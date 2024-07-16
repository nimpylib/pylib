
import ./inner_decl
export inner_decl except hashcode, `hashcode=`, isfold
#[
  we split decl into inner_decl, decl
  and we did not merge this to ./meth.nim as we control export:
  ``export inner_decl except hashcode, `hashcode=` ``
]#
