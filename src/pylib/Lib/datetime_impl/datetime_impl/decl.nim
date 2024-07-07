
import ./inner_decl
export inner_decl
#[
  we split decl into inner_decl, decl
  as if not, there will be cyclic deps between datetime_impl and timezone_impl

  And we did not merge this to ./meth.nim as we control export:
  ``export inner_decl except hashcode, `hashcode=` ``
]#
