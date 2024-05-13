
import ../pystring/strimpl

proc input*(prompt = str("")): PyStr =
  ## Python-like ``input()`` procedure.
  when defined(js):
    var jsResStr: cstring
    let jsPs = $(prompt).cstring
    when not defined(nodejs):  # browesr or deno
      asm "`jsResStr` = prompt(`jsPs`);"
    else:
      asm """ // XXX: only support ASCII charset now.
        if (`jsPs`) process.stdout.write(`jsPs`);
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
    if prompt.len > 0:
      stdout.write($prompt)
    result = str stdin.readLine()
