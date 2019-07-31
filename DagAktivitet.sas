%macro DagAktivitet(inndata=, utdata=);


/* Create a new variable, KontaktID, to identify contacts per pid per dag per institusjonID2 */

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

run;

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
  by pid inndato utdatoKombi institusjonID2;
run;
 
data tmp;
  set tmp;
  
 
  by pid inndato utdatoKombi institusjonID2;
  retain kontaktID; 
  
  * assign kontaktID for opphold within the same day, within the same institution;
  if first.institusjonID2 then do;
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
/* 14/06/2019 - change the code so that overføring from other institution is also grouped together in the same Institusjonsopphold */
/*              exception: keep public and private separated */

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
run;

proc sort data=dogn;
  by sektor priv pid inndatotid;
run;

/* it's possible this doesn't take of more than 2 døgn to be assigned to the same kontaktID */
data dogn/*(drop=lag_: tid_diff)*/;
  set dogn;
  by sektor priv pid inndatotid;
  retain KontaktID;

  lag_oppholdsnr=lag(oppholdsnr);
  lag_utdatotid=lag(utdatotid);
  lag_utdatoKombi=lag(utdatoKombi);
  lag_varighet=lag(varighet);
  tid_diff=inndatotid-lag_utdatotid;

   /* assign a new contact id if the first instance of institution or if the stay is more than 8 hours from the last discharge */
  if first.pid or (first.pid=0 and tid_diff>28800) then do;
      KontaktID=pid*1000+oppholdsnr;
	  KontaktNOpphold_tmp=0;* number of opphold within each contact;
	  KontaktVarighet_tmp=0;* contact duration - sum up duration for each opphold, even if there are overlap;
  end;

    KontaktNOpphold_tmp+1;* number of opphold within each contact;
  KontaktVarighet_tmp+varighet;* contact duration - sum up duration for each opphold, even if there are overlap;
  format lag_utdatotid datetime18.;
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
  
  KontaktTotTimer=KontaktUtdatotid-KontaktInndatotid;
  KontaktLiggetid=KontaktUtdato-KontaktInndato;
  
  format KontaktInndatotid KontaktUtdatotid datetime18.;
  format KontaktInndato    KontaktUtdato    date10.;

 run;
 
%mend;
