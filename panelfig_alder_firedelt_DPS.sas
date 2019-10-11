%macro panelfig_alder_firedelt_DPS(aar1=2015, aar2=2016, aar3=2017, ds_en=, ds_to=, ds_tre=, ds_fire=, var=);

proc format;

value BoDPS_ny
1='Øst-Finnmark'
2='Midt-Finnmark'
3='Vest-Finnmark'
4='Nord-Troms'
5='Midt-Troms'
6='Tromsø'
7='Sør-Troms'
8='Ofoten'
9='Vesterålen'
10='Salten'
11='Lofoten'
12= "Mo i Rana"
13= "Mosjøen"
14= "Ytre Helgeland"
15= "Utenfor HN";


%let tsb=0;
%macro lag_rater(dsinn=, aldrsp=);

/*Grupperer til pasientdager og institusjonsopphold, aggregerer.*/
%DagAktivitet_Ptakst(inndata=&dsinn, utdata=&dsinn._DA);
%aggreger_psyk_DA(inndata=&dsinn._DA, utdata=agg_&dsinn, agg_var=alle, ut_komnr=1);

data agg_&dsinn._komnr;
set agg_&dsinn._komnr;
alder=kontaktAlder;
  aar=kontaktAar;
run;

/*Kjører rateprogram for å få justert rate*/
%let ratefil=agg_&dsinn._komnr;
%let RV_variabelnavn=&var; /*navn på ratevariabel i det aggregerte datasettet*/
%Let ratevariabel = &var; /*Brukes til å lage "pene" overskrifter*/
%let forbruksmal = &var._&dsinn; /*Brukes til å lage tabell-overskrift i Årsvarfig, gir også navn til 'ut'-datasett*/
/*Kun en alderskategori, aldersspesifikk rate som kjønnsjusteres:*/
%let aldersspenn = in &aldrsp;
%let Alderskategorier=99;
%macro Alderkat; /*Må fylles inn dersom egendefinert alderskategorier*/
alder_ny=1; 
%mend;
%include "&filbane\rateprogram\Rateprogram_aldersdelt.sas";

%mend;

%lag_rater(dsinn=&ds_en, aldrsp=&aldr_sp1);
%lag_rater(dsinn=&ds_to, aldrsp=&aldr_sp2);
%lag_rater(dsinn=&ds_tre, aldrsp=&aldr_sp3);
%lag_rater(dsinn=&ds_fire, aldrsp=&aldr_sp4);


/* dataset of this format is used to create figures with columns, with the vbarparm statement*/
data DPS_&figtittel;
set &var._&ds_en._boDPS (in=a)
    &var._&ds_to._boDPS (in=b)
    &var._&ds_tre._boDPS (in=c)
    &var._&ds_fire._boDPS (in=d);

  if a then alder="&aldr_str1";
  if b then alder="&aldr_str2";
  if c then alder="&aldr_str3";
  if d then alder="&aldr_str4";

  keep aar BoDPS rateSnitt alder;

aar=9999;

run;

/* dataset of this format is used to create figures with lines, with the series statement*/
/*data DPS_&figtittel.2;
merge agg_&ds_en._boDPS_rate (rename=(var_rate=var_rate1)) 
      agg_&ds_to._boDPS_rate (rename=(var_rate=var_rate2))
      agg_&ds_tre._boDPS_rate (rename=(var_rate=var_rate3))
      agg_&ds_fire._boDPS_rate (rename=(var_rate=var_rate4));
by aar boDPS_ny;
where boDPS_ny le 14;
run;*/



/*FIGURER*/

%let mappe=Panelfigurer\png\;

ODS Graphics ON /reset=All imagename="&figtittel._DPS_panel" imagefmt=png border=off;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe";


proc sgpanel data=DPS_&figtittel noautolegend sganno=&anno pad=(Bottom=5%);
styleattrs datacolors=(CX95BDE6 CX568BBF CX00509E black);
PANELBY boDPS / columns=7 rows=2 novarname spacing=2 HEADERATTRS=(Color=black Family=Arial Size=8) noheaderborder;
where aar=9999 and boDPS ne 8888;
vbarparm category=aar response=rateSnitt / group=alder groupdisplay=cluster outlineattrs=(thickness=1 color=bgr) missing;
keylegend / noborder position=bottom;
colaxis fitpolicy=thin display=(nolabel noticks novalues) valueattrs=(size=8);
rowaxis label="&xlabel" valueattrs=(size=8) labelattrs=(size=8)  ;
RUN; 

ods listing close;

%let mappe=Panelfigurer\pdf\;

ODS Graphics ON /reset=All imagename="&figtittel._DPS_panel" imagefmt=pdf border=off;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe";


proc sgpanel data=DPS_&figtittel noautolegend sganno=&anno pad=(Bottom=5%);
styleattrs datacolors=(CX95BDE6 CX568BBF CX00509E black);
PANELBY boDPS / columns=7 rows=2 novarname spacing=2 HEADERATTRS=(Color=black Family=Arial Size=8) noheaderborder;
where aar=9999 and boDPS ne 8888;
vbarparm category=aar response=rateSnitt / group=alder groupdisplay=cluster outlineattrs=(thickness=1 color=bgr) missing;
keylegend / noborder position=bottom;
colaxis fitpolicy=thin display=(nolabel noticks novalues) valueattrs=(size=8);
rowaxis label="&xlabel" valueattrs=(size=8) labelattrs=(size=8)  ;
RUN; 


ods listing close;

proc datasets nolist;
delete yr: del: innbygg_: agg: norge: bohf: bodps: behhf: dogn: tmp: rv:;
run;

%mend;
