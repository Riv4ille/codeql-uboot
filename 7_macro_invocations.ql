import cpp

from MacroAccess Ma
where
    Ma.getMacro().getName() in ["ntohl","ntohs","ntohll"]

select Ma