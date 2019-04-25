%macro off_priv_psyk(inndata=, utdata=);

data &utdata;
set &inndata;

if sektor in (4,5) then do;
    priv=1;
    AvtSpes=1;
end;
else if BehHF=27 then do;
    priv=1;
    privSH=1;
end;
else if BehHF ne 27 then off=1;

run;

%mend;