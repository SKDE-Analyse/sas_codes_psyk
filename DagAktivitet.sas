%macro DagAktivitet(inndata=, utdata=);


/* Create a new variable, KontaktID, to identify contacts per pid per dag per institusjonID2 */

/* If a pid has dag/poli during the day, they are considered together in the same KontaktID,
   and if the same pid has an overnight stay on the same day, that is considered as another KontaktID */

 
/*
Nye tidsvariabler, både dato og tidspunkt på døgnet for ut og inn
*/
data &inndata;
  set &inndata;

  if inntid=. then inntid=0;
  if uttid=. then uttid=0;

  inndatotid=dhms(innDato,0,0,innTid);
  utdatotid=dhms(utDatoKombi,0,0,utTid);
  format inndatotid utdatotid datetime18.;

  varighet=utdatotid-inndatotid;

run;

proc sort data=&inndata;
  by pid inndato utdatoKombi descending varighet;
run;

data &inndata;
  set &inndata;
  
  by pid inndato utdatoKombi descending varighet;
  
  * each pid receives sequencial numbers for all opphold;
  if first.pid=1 then oppholdsnr=0;
  oppholdsnr+1;

  * each pid receives sequencial numbers for all opphold within the same date;
  if first.inndato then inndato_teller=0;
  inndato_teller+1;

run;


* create kontakt level information;

proc sort data=&inndata;
  by pid inndato utdatoKombi institusjonID2;
run;
 
data &inndata;
  set &inndata;
  
 
  by pid inndato utdatoKombi institusjonID2;
  retain kontaktID; 
  
  * assign kontaktID for opphold within the same day, within the same institution;
  if first.institusjonID2 then do;
    KontaktID=pid*1000+oppholdsnr;
	KontaktNOpphold_tmp=0;* number of opphold within each contact;
	KontaktVarighet_tmp=0;* contact duration - sum up duration for each opphold;

  end;
  
  KontaktNOpphold_tmp+1;
  KontaktVarighet_tmp+varighet;

run;


PROC SQL;
	CREATE TABLE &utdata AS 
	SELECT *,
	      MAX(KontaktNOpphold_tmp) AS KontaktNOpphold , max(KontaktVarighet_tmp) as KontaktVarighet, 
	      min(inndatotid) as KontaktInndatotid, max(utdatotid)   as KontaktUtdatotid,
 	      min(inndato   ) as KontaktInndato   , max(utdatoKombi) as KontaktUtdato, 
		  max(aar) as KontaktAar, max(alder_omkodet) as KontaktAlder
	FROM &inndata
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
