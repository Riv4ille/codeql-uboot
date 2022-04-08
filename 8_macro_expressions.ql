import cpp

from MacroInvocation MI
where MI.getMacro().getName().regexpMatch("ntoh(s|l|ll)")
select MI.getExpr()