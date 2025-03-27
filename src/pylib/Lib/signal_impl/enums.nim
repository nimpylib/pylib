
import std/tables
import ./pylifecycle except SigInfo
import ./pynsig
import ../enum_impl/[intEnum, enumType]
import ./enums_decl

# ITIMER*  (not enum)
template Exp(sym) =
  when declared(sym):
    let sym* = int sym

Exp ITIMER_REAL
Exp ITIMER_VIRTUAL
Exp ITIMER_PROF

template genEnum(name) =
  GenIntEnumMeth name
  GenPyEnumInit(name, int, name)

# SIG*
genEnum Signals

template add_enum(E, sym, val) =
  let sym* = enums_decl.E.add_member(astToStr(sym), val)

template add_sig(sym) =
  when declared(sym):
    when sym != DEF_SIG:
      add_enum(Signals, sym, sym)

when true:  # just convenient for code folding
  add_sig CTRL_C_EVENT
  add_sig CTRL_BREAK_EVENT

  add_sig SIGHUP
  add_sig SIGINT
  add_sig SIGBREAK
  add_sig SIGQUIT
  add_sig SIGILL
  add_sig SIGTRAP
  add_sig SIGIOT
  add_sig SIGABRT
  add_sig SIGEMT
  add_sig SIGFPE
  add_sig SIGKILL
  add_sig SIGBUS
  add_sig SIGSEGV
  add_sig SIGSYS
  add_sig SIGPIPE
  add_sig SIGALRM
  add_sig SIGTERM
  add_sig SIGUSR1
  add_sig SIGUSR2
  add_sig SIGCLD
  add_sig SIGCHLD
  add_sig SIGPWR
  add_sig SIGIO
  add_sig SIGURG
  add_sig SIGWINCH
  add_sig SIGPOLL
  add_sig SIGSTOP
  add_sig SIGTSTP
  add_sig SIGCONT
  add_sig SIGTTIN
  add_sig SIGTTOU
  add_sig SIGVTALRM
  add_sig SIGPROF
  add_sig SIGXCPU
  add_sig SIGXFSZ
  add_sig SIGRTMIN
  add_sig SIGRTMAX
  add_sig SIGINFO
  add_sig SIGSTKFLT


# SIG_*
genEnum Handlers

template add_handler(sym) =
  when declared(sym):
    add_enum(Handlers, sym, cast[int](sym))

add_handler SIG_DFL
add_handler SIG_IGN


# Sigmasks
genEnum Sigmasks

template add_sigmask(sym) =
  when declared(sym):
    add_enum(Sigmasks, sym, sym)

when not defined(windows):
  add_sigmask SIG_BLOCK
  add_sigmask SIG_UNBLOCK
  add_sigmask SIG_SETMASK

export Signals, Handlers, Sigmasks
