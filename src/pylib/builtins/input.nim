
import ./print
import ../pystring/strimpl
import ../Lib/sys
import ../pyerrors/rterr


proc inputImpl: PyStr =
  when defined(nimscript):
    # XXX: currently sys.stdin is not available on nimscript
    static: assert not compiles(sys.stdin)
    readLineFromStdin()
  elif defined(js):
    static: assert defined(nodejs)
    var jsResStr: cstring
    asm """// XXX: FIXME: only support ASCII charset now.
        const fs = require('fs');
        let fd = (process.platform == 'win32') ?
          process.stdin.fd :
          fs.openSync('/dev/tty', 'rs');
        let buf = Buffer.alloc(4);
        let str = '', read;
        while (true) {
          read = fs.readSync(fd, buf, 0, 1);
          if(read==0) continue;
          let chr = buf[0];
          
          // catch the newline character
          if (chr == 10) {
            fs.closeSync(fd);
            break;
          }
          str += buf.slice(0,1).toString();
        }
        `jsResStr` = str;
      """
      #[
      asm """ ;{
    let rlmod = require("readline")
    let rlinter = rlmod.createInterface(
      {input: process.stdin, output: process.stdout});
    rlinter.question(`jsPs`, inp=>{
      rlinter.close();
      `jsResStr` = inp  // XXX: this is executed asynchronously... 
      // So `result` will be just null when returned
    });
    }
    """]#
    result = str $jsResStr
  else:
    sys.stdin.readline()


proc inputImpl(prompt: string): PyStr =
  when defined(js) and not defined(nodejs):# browesr or deno
    proc prompt(ps: cstring): cstring{.importjs: "prompt(#)".}
    return str $prompt(cstring prompt)
  else:
    if prompt.len != 0:
      print(prompt, endl="")
    inputImpl()

proc input*(prompt = str("")): PyStr =
  ##
  ## when on non-nodejs JavaScript backend,
  ## uses `prompt`
  template lost(std) = raise newException(RuntimeError, "input() lost " & std)
  if sys.stdin.isNil: lost "stdin"
  if sys.stdout.isNil: lost "stdout"
  inputImpl prompt
  
