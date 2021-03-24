import cpp

from Macro mc
where mc.getName()="ntohl" or mc.getName()="ntohs" or mc.getName()="ntohll"
select mc,"a macro of network ordering conversion"
