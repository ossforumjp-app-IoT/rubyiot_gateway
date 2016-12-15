#!/usr/bin/ruby -Ku

args=["a","b","c"]
p args.inject(:+)


p sprintf("%02x", (~(["10010013a20040b189bcfffe0000302c312c2b3033302e302c2b3031312e30"].pack("H*")).sum(8) & 0xff))
p sprintf("%02x", ~(["10010013a20040b189bcfffe0000302c312c2b3033302e302c2b3031312e30"].pack("H*").sum(8) & 0xff))
