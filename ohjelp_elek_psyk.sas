%macro ohjelp_elek_psyk(inndata=, utdata=);

data &utdata;
set &inndata;

if innmateHast in (4,5) then elektiv = 1;
if innmateHast in (1,2,3) then ohjelp = 1;

run;

%mend;