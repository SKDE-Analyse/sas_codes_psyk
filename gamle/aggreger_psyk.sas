%macro aggreger_psyk(inndata = , utdata = , agg_var = , mappe = work, ut_boHF=1, ut_boDPS=0, ut_komnr=0, ut_BehHF=1);

/*Makro for å aggregere psykiatridata*/

/*Må først kjøre off_priv_psyk.sas og ohjelp_elek_psyk.sas*/

/*Variablene ut_boHF, ut_boDPS...etc definerer type utfil (hva slags variabel du ønsker å aggregere på). For aggregering til rateprogram må du ha bo_komnr=1 */

%macro unik_pasient_aar(datasett = , variabel =);

/* 
Macro for å markere unike pasienter pr år

Ny variabel, &variabel._unik_aar, lages i samme datasett
*/

/*1. Sorter på år, aktuell hendelse (merkevariabel), PID, InnDato, UtDato;*/
proc sort data=&datasett;
by aar &variabel pid inndato utdato;
run;

/*2. By-statement sørger for at riktig opphold med hendelse velges i kombinasjon med First.-funksjonen og betingelse på hendelse*/
data &datasett;
set &datasett;
&variabel._unik_aar = .;
by aar &variabel pid inndato utdato;
if first.pid and &variabel = 1 then &variabel._unik_aar = 1;	
run;

%mend;

%macro unik_pasient_dag(datasett = , variabel =);

/* 
Macro for å markere unike pasienter pr dag

Ny variabel, &variabel._unik_dag, lages i samme datasett
*/

/* JS - for å bruke EoC samme med aggregere makro, sette KontaktInndato i sted av inndato */

/*1. Sorter på år, aktuell hendelse (merkevariabel), PID, InnDato, UtDato;*/
proc sort data=&datasett;
by &variabel pid inndato institusjonID2;
run;

/*2. By-statement sørger for at riktig opphold med hendelse velges i kombinasjon med First.-funksjonen og betingelse på hendelse*/
data &datasett;
set &datasett;
&variabel._unik_dag = .;
by &variabel pid inndato institusjonID2;
if &variabel = 1 and ErDogn = 0 then do;    /*Skal bare gjøres for poli/dag*/
    if first.inndato then do;
        &variabel._unik_dag = 1;
    end;
    else do;
        if first.InstitusjonID2 then &variabel._unik_dag = 1;
    end;
end;
run;

%mend;

/*Tar bare med opphold som har aktuell variabel lik 1*/
data &inndata._&agg_var;
set &inndata;
where &agg_var=1;
tot=1;
if liggetid = . then liggetid_ny=liggetidSatt;
else liggetid_ny=liggetid;
run;

/*Setter variabler for innleggelser, akutte og elektive*/
data &inndata._&agg_var;
set &inndata._&agg_var;
  if erDogn=1 then do;
    inn = 1;
    if elektiv = 1 then inn_elektiv = 1;
    if ohjelp = 1 then inn_ohjelp = 1;
  end;
run;

/*Setter variabler for poli/døgn-kontakter, offentlige eller private, hos avtalespesialist eller på privat sykehus*/
data &inndata._&agg_var;
set &inndata._&agg_var;
  if erDogn = 0 then do;
    poli = 1;
   
    if AvtSpes = 1 then do; /*Avtalespesialister*/
        poli_priv = 1;    
        poli_as = 1;
    end;
    else if privSH = 1 then do; /*Privat sykehus*/
        poli_priv = 1;      
        poli_psh = 1;
    end;
    else if off = 1 then poli_off = 1;    /*Offentlige institusjoner*/    
  end;
run;


/**/
%unik_pasient_aar(datasett = &inndata._&agg_var., variabel = tot);

%unik_pasient_aar(datasett = &inndata._&agg_var., variabel = poli);
%unik_pasient_dag(datasett = &inndata._&agg_var., variabel = poli);

%unik_pasient_aar(datasett = &inndata._&agg_var., variabel = poli_off);
%unik_pasient_dag(datasett = &inndata._&agg_var., variabel = poli_off);

%unik_pasient_aar(datasett = &inndata._&agg_var., variabel = poli_priv);
%unik_pasient_dag(datasett = &inndata._&agg_var., variabel = poli_priv);

%unik_pasient_dag(datasett = &inndata._&agg_var., variabel = poli_as);

%unik_pasient_dag(datasett = &inndata._&agg_var., variabel = poli_psh);

%unik_pasient_aar(datasett = &inndata._&agg_var., variabel = inn);

%if &ut_komnr=1 %then %do;

  proc sql;
    create table &mappe..&utdata._komnr as 
    select distinct aar, ermann, alder_omkodet, komnr, bydel, borhf,
    SUM(tot_unik_aar) as tot_unik_aar,
    SUM(inn) as inn, SUM(inn_unik_aar) as inn_unik_aar,
    SUM(inn_elektiv) as inn_elek, 
    SUM(inn_ohjelp) as inn_ohj, 
    SUM(poli_unik_dag) as poli_unik_dag, SUM(poli_unik_aar) as poli_unik_aar,
    SUM(poli_off_unik_dag) as poli_off_unik_dag, SUM(poli_off_unik_aar) as poli_off_unik_aar,
    SUM(poli_priv_unik_dag) as poli_priv_unik_dag, SUM(poli_priv_unik_aar) as poli_priv_unik_aar,
    SUM(poli_as_unik_dag) as poli_as_unik_dag, 
    SUM(poli_psh_unik_dag) as poli_psh_unik_dag, 
    SUM(liggetid_ny) as liggetid
    from &inndata._&agg_var
    group by aar, ermann, alder_omkodet, komnr, bydel;
  quit; run;

%end;

%if &ut_boHF=1 %then %do;

  proc sql;
    create table &mappe..&utdata._boHF as 
    select distinct aar, ermann, alder_omkodet, boHF,
    SUM(tot_unik_aar) as tot_unik_aar,
    SUM(inn) as inn, SUM(inn_unik_aar) as inn_unik_aar,
    SUM(inn_elektiv) as inn_elek, 
    SUM(inn_ohjelp) as inn_ohj, 
    SUM(poli_unik_dag) as poli_unik_dag, SUM(poli_unik_aar) as poli_unik_aar,
    SUM(poli_off_unik_dag) as poli_off_unik_dag, SUM(poli_off_unik_aar) as poli_off_unik_aar,
    SUM(poli_priv_unik_dag) as poli_priv_unik_dag, SUM(poli_priv_unik_aar) as poli_priv_unik_aar,
    SUM(poli_as_unik_dag) as poli_as_unik_dag, 
    SUM(poli_psh_unik_dag) as poli_psh_unik_dag, 
    SUM(liggetid_ny) as liggetid
    from &inndata._&agg_var
    group by aar, ermann, alder_omkodet, boHF;
  quit; run;

%end;

%if &ut_boDPS=1 %then %do;

  proc sql;
    create table &mappe..&utdata._boDPS as 
    select distinct aar, ermann, alder_omkodet, boDPS,
    SUM(tot_unik_aar) as tot_unik_aar,
    SUM(inn) as inn, SUM(inn_unik_aar) as inn_unik_aar,
    SUM(inn_elektiv) as inn_elek, 
    SUM(inn_ohjelp) as inn_ohj, 
    SUM(poli_unik_dag) as poli_unik_dag, SUM(poli_unik_aar) as poli_unik_aar,
    SUM(poli_off_unik_dag) as poli_off_unik_dag, SUM(poli_off_unik_aar) as poli_off_unik_aar,
    SUM(poli_priv_unik_dag) as poli_priv_unik_dag, SUM(poli_priv_unik_aar) as poli_priv_unik_aar,
    SUM(poli_as_unik_dag) as poli_as_unik_dag, 
    SUM(poli_psh_unik_dag) as poli_psh_unik_dag, 
    SUM(liggetid_ny) as liggetid
    from &inndata._&agg_var
    group by aar, ermann, alder_omkodet, boDPS;
  quit; run;

%end;

%if &ut_behHF=1 %then %do;

  proc sql;
    create table &mappe..&utdata._behHF as 
    select distinct aar, ermann, alder_omkodet, BehHF, type_beh,
    SUM(inn) as inn,
    SUM(inn_elektiv) as inn_elek, 
    SUM(inn_ohjelp) as inn_ohj, 
    SUM(poli_unik_dag) as poli_unik_dag, 
    SUM(poli_off_unik_dag) as poli_off_unik_dag, 
    SUM(poli_priv_unik_dag) as poli_priv_unik_dag, 
    SUM(poli_as_unik_dag) as poli_as_unik_dag, 
    SUM(poli_psh_unik_dag) as poli_psh_unik_dag, 
    SUM(liggetid_ny) as liggetid
    from &inndata._&agg_var
    group by aar, ermann, alder_omkodet, BehHF, type_beh;
  quit; run;

%end;


proc datasets nolist;
delete &inndata._&agg_var;
run;

%mend;