%macro aggreger_psyk_DA(inndata = , utdata = , agg_var = , mappe = work, ut_boHF=1, ut_boDPS=0, ut_komnr=0, ut_BehHF=1);

/*Makro for å aggregere psykiatridata*/

/*Må først kjøre off_priv_psyk.sas og ohjelp_elek_psyk.sas*/

/*Variablene ut_boHF, ut_boDPS...etc definerer type utfil (hva slags variabel du ønsker å aggregere på). For aggregering til rateprogram må du ha bo_komnr=1 */

%macro unik_pasient_aar(datasett = , variabel =);

/* 
Macro for å markere unike pasienter pr år

Ny variabel, &variabel._unik_aar, lages i samme datasett
*/

/*1. Sorter på år, aktuell hendelse (merkevariabel), PID, kontaktID;*/
proc sort data=&datasett;
by aar &variabel pid;
run;

/*2. By-statement sørger for at riktig opphold med hendelse velges i kombinasjon med First.-funksjonen og betingelse på hendelse*/
data &datasett;
set &datasett;
&variabel._unik_aar = .;
by aar &variabel pid;
if first.pid and &variabel = 1 then &variabel._unik_aar = 1;	
run;

%mend;

%macro unik_pas_aar_inst(datasett = , variabel =);

/* 
Macro for å markere unike pasienter pr år

Ny variabel, &variabel._unik_aar_inst, lages i samme datasett

Macroen er testet og fungerer som ønsket.

*/

/*1. Sorter på år, aktuell hendelse (merkevariabel), PID, kontaktID;*/
proc sort data=&datasett;
by aar &variabel pid behHF;
run;

/*2. By-statement sørger for at riktig opphold med hendelse velges i kombinasjon med First.-funksjonen og betingelse på hendelse*/
data &datasett;
set &datasett;
&variabel._unik_aar_inst = .;
by aar &variabel pid behHF;
if first.behHF and &variabel = 1 then &variabel._unik_aar_inst = 1;	
run;

%mend;

proc sort data=&inndata;
by &agg_var pid kontaktID;
run;

/*Tar bare med opphold/pasdager som har aktuell variabel lik 1. Tar med bare første kontakt for hvert opphold/pasdag*/
data &inndata._&agg_var;
set &inndata;
by &agg_var pid kontaktID;
where &agg_var=1;
if first.kontaktID then behold=1;
run;

data &inndata._&agg_var._red;
set &inndata._&agg_var;
where behold=1;
tot=1;      
run;

/*Setter variabler for innleggelser, akutte og elektive*/
data &inndata._&agg_var._red;
set &inndata._&agg_var._red;
  if erDogn=1 then do;
    inn = 1;
    if elektiv = 1 then inn_elektiv = 1;
    if ohjelp = 1 then inn_ohjelp = 1;
    if privSH = 1 then inn_privSH =1;
  end;
run;

/*Setter variabler for poli/døgn-kontakter, offentlige eller private, hos avtalespesialist eller på privat sykehus*/
data &inndata._&agg_var._red;
set &inndata._&agg_var._red;
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


/*Teller unike pasienter for utdata på bosted*/
%unik_pasient_aar(datasett = &inndata._&agg_var._red, variabel = tot);
%unik_pasient_aar(datasett = &inndata._&agg_var._red, variabel = poli);
%unik_pasient_aar(datasett = &inndata._&agg_var._red, variabel = poli_off);
%unik_pasient_aar(datasett = &inndata._&agg_var._red, variabel = poli_priv);
%unik_pasient_aar(datasett = &inndata._&agg_var._red, variabel = inn);

/*Teller unike pasienter for utdata på behandler*/
%unik_pas_aar_inst(datasett = &inndata._&agg_var._red, variabel = poli);
%unik_pas_aar_inst(datasett = &inndata._&agg_var._red, variabel = inn);

%if &ut_komnr=1 %then %do;

  proc sql;
    create table ut_komnr as 
    select distinct Kontaktaar, ermann, KontaktAlder, komnr, bydel, borhf,
    SUM(tot_unik_aar) as tot_unik_aar,
    SUM(inn) as inn, SUM(inn_unik_aar) as inn_unik_aar,
    SUM(inn_elektiv) as inn_elek, 
    SUM(inn_ohjelp) as inn_ohj, 
    SUM(inn_privSH) as inn_privSH, 
    SUM(poli) as poli, SUM(poli_unik_aar) as poli_unik_aar,
    SUM(poli_off) as poli_off, SUM(poli_off_unik_aar) as poli_off_unik_aar,
    SUM(poli_priv) as poli_priv, SUM(poli_priv_unik_aar) as poli_priv_unik_aar,
    SUM(poli_as) as poli_as, 
    SUM(poli_psh) as poli_psh, 
    SUM(KontaktLiggetid) as liggetid
    from &inndata._&agg_var._red
    group by Kontaktaar, ermann, KontaktAlder, komnr, bydel;
  quit; run;

  data &mappe..&utdata._komnr;
  set ut_komnr;
  aar=KontaktAar;
  alder_omkodet=KontaktAlder;
  run;

%end;

%if &ut_boHF=1 %then %do;

  proc sql;
    create table ut_boHF as 
    select distinct Kontaktaar, ermann, KontaktAlder, boHF,
    SUM(tot_unik_aar) as tot_unik_aar,
    SUM(inn) as inn, SUM(inn_unik_aar) as inn_unik_aar,
    SUM(inn_elektiv) as inn_elek, 
    SUM(inn_ohjelp) as inn_ohj, 
    SUM(inn_privSH) as inn_privSH, 
    SUM(poli) as poli, SUM(poli_unik_aar) as poli_unik_aar,
    SUM(poli_off) as poli_off, SUM(poli_off_unik_aar) as poli_off_unik_aar,
    SUM(poli_priv) as poli_priv, SUM(poli_priv_unik_aar) as poli_priv_unik_aar,
    SUM(poli_as) as poli_as, 
    SUM(poli_psh) as poli_psh, 
    SUM(KontaktLiggetid) as liggetid
    from &inndata._&agg_var._red
    group by Kontaktaar, ermann, KontaktAlder, boHF;
  quit; run;

  data &mappe..&utdata._boHF;
  set ut_boHF;
  aar=KontaktAar;
  alder_omkodet=KontaktAlder;
  run;

%end;

%if &ut_boDPS=1 %then %do;

  proc sql;
    create table ut_boDPS as 
    select distinct Kontaktaar, ermann, KontaktAlder, boDPS,
    SUM(tot_unik_aar) as tot_unik_aar,
    SUM(inn) as inn, SUM(inn_unik_aar) as inn_unik_aar,
    SUM(inn_elektiv) as inn_elek, 
    SUM(inn_ohjelp) as inn_ohj, 
    SUM(inn_privSH) as inn_privSH, 
    SUM(poli) as poli, SUM(poli_unik_aar) as poli_unik_aar,
    SUM(poli_off) as poli_off, SUM(poli_off_unik_aar) as poli_off_unik_aar,
    SUM(poli_priv) as poli_priv, SUM(poli_priv_unik_aar) as poli_priv_unik_aar,
    SUM(poli_as) as poli_as, 
    SUM(poli_psh) as poli_psh, 
    SUM(KontaktLiggetid) as liggetid
    from &inndata._&agg_var._red
    group by Kontaktaar, ermann, KontaktAlder, boDPS;
  quit; run;

  data &mappe..&utdata._boDPS;
  set ut_boDPS;
  aar=KontaktAar;
  alder_omkodet=KontaktAlder;
  run;

%end;

%if &ut_behHF=1 %then %do;

  proc sql;
    create table ut_behHF as 
    select distinct Kontaktaar, ermann, KontaktAlder, BehHF_kontakt, type_beh,
    SUM(inn) as inn, SUM(inn_unik_aar_inst) as inn_unik_aar_i,
    SUM(inn_elektiv) as inn_elek, 
    SUM(inn_ohjelp) as inn_ohj, 
    SUM(poli) as poli, SUM(poli_unik_aar_inst) as poli_unik_aar_i, 
    SUM(poli_off) as poli_off, 
    SUM(poli_priv) as poli_priv, 
    SUM(poli_as) as poli_as, 
    SUM(poli_psh) as poli_psh, 
    SUM(KontaktLiggetid) as liggetid
    from &inndata._&agg_var._red
    group by Kontaktaar, ermann, KontaktAlder, BehHF_kontakt, type_beh;
  quit; run;

  data &mappe..&utdata._behHF;
  set ut_behHF;
  aar=KontaktAar;
  alder_omkodet=KontaktAlder;
  BehHF=BehHF_kontakt;
  run;

%end;


proc datasets nolist;
delete ut: &inndata._&agg_var &inndata._&agg_var._red;
run;

%mend;