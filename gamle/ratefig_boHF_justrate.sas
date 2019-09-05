%macro ratefig_BoHF_justrate(inndata=, var=poli, utfil_navn=);

proc format;

Value BoHF_ny
1='Finnmark'
2='UNN'
3='Nordland'
4='Helgeland'
5='Utenfor HN';

/*Grupperer til pasientdager og institusjonsopphold, aggregerer.*/
%DagAktivitet(inndata=&inndata, utdata=&inndata._DA);
%aggreger_psyk_DA(inndata=&inndata._DA, utdata=agg, agg_var=alle, ut_boHF=1, ut_BehHF=0, ut_komnr=1, ut_boDPS=0);

data agg_komnr;
  set agg_komnr;
  alder=kontaktAlder;
  aar=kontaktAar;
run;

/*Kjører rateprogram for å få justert rate*/
%let ratefil=agg_komnr;
%let RV_variabelnavn=&var; /*navn på ratevariabel i det aggregerte datasettet*/
%Let ratevariabel = &var; /*Brukes til å lage "pene" overskrifter*/
%Let forbruksmal = &utfil_navn; /*Brukes til å lage tabell-overskrift i Årsvarfig, gir også navn til 'ut'-datasett*/
%include "&filbane\rateprogram\rateprogram.sas";


/* save the rateprogram output to the same file structure as the unadjusted rates files so that we can use the same lager figurer codes */
data agg_bohf_sn_I_justrate;
  set &forbruksmal._s_bohf(rename=(bohf=bohf_ny rv_just_rate=var_rate ant_opphold=var_snitt_ny ant_innbyggere=innb_snitt_ny));
  keep bohf_ny var_snitt_ny innb_snitt_ny var_rate;
  where aar=9999 and 1<=bohf_ny<=4;
run;

/*Lager figurer*/

proc sort data=agg_boHF_sn_I_justrate;
 by descending var_rate;
run;

%let mappe=Ratefigurer\png\justrate\;

ODS Graphics ON /reset=All imagename="&utfil_navn._HF" imagefmt=png border=off ;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe";
proc sgplot data=agg_boHF_sn_I_justrate noborder noautolegend sganno=anno pad=(Bottom=5%);
where BoHF_ny le 4;

     hbarparm category=boHF_ny response=var_rate / fillattrs=(color=CX95BDE6) missing outlineattrs=(color=grey);  

 	     *yaxis min=24 display=(noticks noline) label='Opptaksområde' labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=8);
	 yaxis display=(noticks noline) label='Bosatte i opptaksområdene' labelpos=top labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=9);
     xaxis  offsetmin=0 offsetmax=0.02  valueattrs=(size=8) label="&xlabel" labelattrs=(size=8 weight=bold);
     Yaxistable &hoyretabell /Label location=inside labelpos=top position=right valueattrs=(size=9 family=arial) labelattrs=(size=9);
	 label &labeltabell;

format &formattabell;

run;Title; ods listing close;

%let mappe=Ratefigurer\pdf\justrate\;

ODS Graphics ON /reset=All imagename="&utfil_navn._HF" imagefmt=pdf border=off ;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe";
proc sgplot data=agg_boHF_sn_I_justrate noborder noautolegend sganno=anno pad=(Bottom=5%);
where BoHF_ny le 4;

     hbarparm category=boHF_ny response=var_rate / fillattrs=(color=CX95BDE6) missing outlineattrs=(color=grey);  

 	     *yaxis min=24 display=(noticks noline) label='Opptaksområde' labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=8);
	 yaxis display=(noticks noline) label='Bosatte i opptaksområdene' labelpos=top labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=9);
     xaxis  offsetmin=0 offsetmax=0.02  valueattrs=(size=8) label="&xlabel" labelattrs=(size=8 weight=bold);
     Yaxistable &hoyretabell /Label location=inside labelpos=top position=right valueattrs=(size=9 family=arial) labelattrs=(size=9);
	 label &labeltabell;

format &formattabell;


run;Title; ods listing close;

%mend;
