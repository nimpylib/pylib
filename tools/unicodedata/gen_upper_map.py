

from pathlib import Path

curSrcPath = Path(__file__)

with open(curSrcPath.with_name("unicase_outdir.txt"), encoding="utf-8") as f:
    outdir = f.read()

import sys

ofile = open(Path(outdir)/"toUpperMapper.nim", 'w', encoding='utf-8')
sys.stdout = ofile

print(f"""# Generated by /tools/unicodedata/{curSrcPath.name}
# where `/` refers to the root path of this project.
# to be included

# only one character that will be extended to more characters when tolower:
#  chr(304) a.k.a. LATIN CAPITAL LETTER I WITH DOT ABOVE""")

print("const OneUpperToMoreTableLit = {")

for i in range(0x110000):
  c = chr(i)
  uc = c.upper()
  le = len(uc)
  if le != 1:
    ucs_b = uc.encode('unicode-escape')
    ucs = ucs_b.decode('ascii')
    print(f"""  {i}'i32: "{ucs}",""")
    #ucs = ""
    #for ucc in uc: ucs += str(ord(ucc)) + ' '
    #print(f'{i:<7}->{ucs:>12}')

print("}")

ofile.close()
