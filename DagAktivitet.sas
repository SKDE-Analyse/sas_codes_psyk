%macro DagAktivitet(inndata=, utdata=);


/* Create a new variable, KontaktID, to identify contacts per pid per dag per behandlende institusjon */

/* If a pid has dag/poli during the day, they are considered together in the same KontaktID,
   and if the same pid has an overnight stay on the same day, that is considered as another KontaktID */

 
/*
Nye tidsvariabler, både dato og tidspunkt på døgnet for ut og inn
*/
data tmp;
  set &inndata;

  if inntid=. then inntid=0;
  if uttid=. then uttid=0;

  inndatotid=dhms(innDato,0,0,innTid);
  utdatotid=dhms(utDatoKombi,0,0,utTid);
  format inndatotid utdatotid datetime18.;

  varighet=utdatotid-inndatotid;

/*Variabel som identifiserer behandlende institusjon, til bruk i def. av pasientdag.*/
  if BehHF in (1,2,3,4) then sep_inst=institusjon;
  else sep_inst=institusjonID2;

run;

/*Lager tellevariabler oppholdsnr og inndato_teller*/
proc sort data=tmp;
  by pid inndato utdatoKombi descending varighet;
run;

data tmp;
  set tmp;
  
  by pid inndato utdatoKombi descending varighet;
  
  * each pid receives sequencial numbers for all opphold;
  if first.pid=1 then oppholdsnr=0;
  oppholdsnr+1;

  * each pid receives sequencial numbers for all opphold within the same date;
  if first.inndato then inndato_teller=0;
  inndato_teller+1;

run;


* create kontakt level information;

proc sort data=tmp;
  by pid inndato utdatoKombi sep_inst;
run;
 
data tmp;
  set tmp;
  
 
  by pid inndato utdatoKombi sep_inst;
  retain kontaktID; 
  
  * assign kontaktID for opphold within the same day, within the same institution (def. by sep_inst);
  if first.sep_inst then do;
    KontaktID=pid*1000+oppholdsnr;
	  KontaktNOpphold_tmp=0;* number of opphold within each contact;
	  KontaktVarighet_tmp=0;* contact duration - sum up duration for each opphold, even if there are overlap;
  end;
  
  KontaktNOpphold_tmp+1;
  KontaktVarighet_tmp+varighet;

/*Lager BehHF_kontakt-variabel slik at den kan brukes i aggregering (egentlig kun aktuell for enkelte døgnopphold der flere HF er del av et opphold)*/
  BehHF_kontakt=BehHF;

run;

/* døgn at the same institution that are less than 8 hours apart are considered as the same contact */
/* 14/06/2019 - change the code so that transfers from other institution is also grouped together in the same Institusjonsopphold if:*/
/* 1 the stays are all in the same sector (handled by sorting data by sektor)
   2 the stays are all in a public hospital (handled by sorting data by variable sep, created below*/

proc sort data=tmp (keep=pid institusjonID2 inndatotid inndato utdatotid utdatoKombi varighet erDogn oppholdsnr inndato_teller sektor behHF) out=dogn;
  where erDogn=1;
  by sektor pid  inndatotid;
run;

%let filbanePSYK=\\hn.helsenord.no\RHF\SKDE\Analyse\Prosjekter\2019_Psyk_HN\;
%include "&filbanePSYK.SAS-prosjekter\sas_codes_psyk\off_priv_psyk.sas";
%off_priv_psyk(inndata=dogn, utdata=dogn);

data dogn;
  set dogn;
  if priv ne 1 then priv=0;

  /*lager ny variabel som ikke skiller off. institusjoner, men skiller private institusjoner*/
  if priv=0 then sep=112233445;
  else if priv=1 then sep=institusjonID2;

run;

proc sort data=dogn;
  by sektor sep pid inndatotid utdatoKombi;
run;

/* it's possible this doesn't take of more than 2 døgn to be assigned to the same kontaktID */
data dogn/*(drop=lag_: tid_diff)*/;
  set dogn;
  by sektor sep pid inndatotid utdatoKombi;
  retain KontaktID cross_ny;

  lag_oppholdsnr=lag(oppholdsnr);
  lag_utdatotid=lag(utdatotid);
  lag_inndatotid=lag(inndatotid);
  lag_utdatoKombi=lag(utdatoKombi);
  lag_varighet=lag(varighet);
  tid_diff=inndatotid-lag_utdatotid;

   /* assign a new contact id if 
   A: if the stay is more than 8 hours from the last discharge or
   B: The stay crosses newyear (and has a duplicate contact in the next year)*/
  if first.pid or (first.pid=0 and tid_diff>28800) or (inndatotid=lag_inndatotid and lag_utdatotid in ('31DEC15:00:00:00'dt,'31DEC16:00:00:00'dt)) then do;
      KontaktID=pid*1000+oppholdsnr;
    cross_ny=.;
	  KontaktNOpphold_tmp=0;* number of opphold within each contact;
	  KontaktVarighet_tmp=0;* contact duration - sum up duration for each opphold, even if there are overlap;
    if inndatotid=lag_inndatotid and lag_utdatotid in ('31DEC15:00:00:00'dt,'31DEC16:00:00:00'dt) then cross_ny=1;
  end;

    KontaktNOpphold_tmp+1;* number of opphold within each contact;
  KontaktVarighet_tmp+varighet;* contact duration - sum up duration for each opphold, even if there are overlap;
  format lag_utdatotid lag_inndatotid datetime18.;
run;

/*Kode for å velge BehHF i tilfeller der pasienten har vært overført mellom helseforetak. Opphold med lengst varighet gir gjeldende BehHF for kontakten.*/
proc sql;
create table BehHF as
select KontaktID, varighet, BehHF, max(varighet) as max_varighet
from dogn
group by KontaktID;
quit;

data BehHF_valgt;
set BehHF;
where varighet=max_varighet;

BehHF_kontakt=BehHF;

run;

data BehHF_valgt2;
set BehHF_valgt;
drop BehHF varighet max_varighet;
run;

proc sort data=dogn;
by KontaktID;
quit;

proc sort data=BehHF_valgt2;
by KontaktID;
quit;

data dogn_ny;
merge dogn BehHF_valgt2;
by KontaktID;
run;

proc sort data=dogn_ny;
  by pid oppholdsnr;
run;

proc sort data=tmp;
  by pid oppholdsnr;
run;

data &inndata._2;
  merge tmp dogn_ny;
  by pid oppholdsnr;
run;

PROC SQL;
	CREATE TABLE &utdata AS 
	SELECT *,
	      MAX(KontaktNOpphold_tmp) AS KontaktNOpphold , max(KontaktVarighet_tmp) as KontaktVarighet, /*kontaktVarighet is probably not very useful as it often double counts.  KontaktTotTimer is more accurate */
	      min(inndatotid) as KontaktInndatotid, max(utdatotid)   as KontaktUtdatotid,
 	      min(inndato   ) as KontaktInndato   , max(utdatoKombi) as KontaktUtdato, 
		  max(aar) as KontaktAar, max(alder_omkodet) as KontaktAlder
	FROM &inndata._2
	GROUP BY KontaktID;
QUIT;

data &utdata;
  set &utdata(drop=KontaktNOpphold_tmp KontaktVarighet_tmp);

  /*If inndato is before jan 1 2015 then Kontaktinndato is set to jan 1 2015 to ensure correct liggetid for 2015*/
  if KontaktInndato lt '1JAN15'd then do;
    KontaktInndatotid='1JAN15:00:00:00'dt;
    KontaktInndato='1JAN15'd;
  end;
  
  /*If stay crosses new year then only count from jan 1*/
  if cross_ny=1 then do;
    if KontaktAar=2016 then do;
      KontaktInndatotid='1JAN16:00:00:00'dt;
      KontaktInndato='1JAN16'd;
    end;
    if KontaktAar=2017 then do;
      KontaktInndatotid='1JAN17:00:00:00'dt;
      KontaktInndato='1JAN17'd;
    end;
  end;

  KontaktTotTimer=KontaktUtdatotid-KontaktInndatotid;
  KontaktLiggetid=KontaktUtdato-KontaktInndato;

/*No stay can have more then 365 days of liggetid.*/
  if KontaktLiggetid gt 365 then KontaktLiggetid=365;
  
  format KontaktInndatotid KontaktUtdatotid datetime18.;
  format KontaktInndato    KontaktUtdato    date10.;

 run;
 
%mend;
