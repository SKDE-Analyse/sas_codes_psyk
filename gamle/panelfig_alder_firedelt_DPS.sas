%macro panelfig_alder_firedelt_DPS(aar1=2015, aar2=2016, aar3=2017, ds_en=, ds_to=, ds_tre=, ds_fire=, aldr_gr1=, aldr_gr2=, aldr_gr3=, aldr_gr4=, var=);

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

/*Beregner innbyggertall på ny boDPS variabel*/

data innbyggere_1517;
set innbygg.innb_2004_2017_bydel_allebyer;
where aar in (2015, 2016, 2017) and alder ge 18;
%boomraaderPsyk;
run;

%macro lag_innb_ds(dsinn=, aldr=);

proc sql;
create table innbygg_&dsinn._boDPS as
select distinct aar, boDPS, sum(innbyggere) as innb
from innbyggere_1517
where &aldr
group by aar, boDPS;
quit;
run;

data innbygg_&dsinn._boDPS2;
set innbygg_&dsinn._boDPS;
where boDPS ne .;

if boDPS gt 14 then boDPS_ny=15;
else boDPS_ny=boDPS;

format boDPS_ny boDPS_ny.;

run;

proc sql;
create table innbygg_&dsinn._boDPS_ny as
select distinct aar, boDPS_ny, sum(innb) as innb_ny
from innbygg_&dsinn._boDPS2
group by aar, boDPS_ny;
quit;
run;

%mend;

%lag_innb_ds(dsinn=&ds_en,   aldr=&aldr_gr1);
%lag_innb_ds(dsinn=&ds_to,   aldr=&aldr_gr2);
%lag_innb_ds(dsinn=&ds_tre,  aldr=&aldr_gr3);
%lag_innb_ds(dsinn=&ds_fire, aldr=&aldr_gr4);


%macro lag_rater(dsinn=);

/*Grupperer til pasientdager og institusjonsopphold, aggregerer.*/
%DagAktivitet_Ptakst(inndata=&dsinn, utdata=&dsinn._DA);
%aggreger_psyk_DA(inndata=&dsinn._DA, utdata=agg_&dsinn, agg_var=alle, ut_boHF=0, ut_BehHF=0, ut_boDPS=1);

/*Lager ny boDPS variabel, grupperer alle boDPS i sør til ett boDPS.*/
data agg_&dsinn._boDPS2;
set agg_&dsinn._boDPS;
where boDPS ne .;

if boDPS gt 14 then boDPS_ny=15;
else boDPS_ny=boDPS;

format boDPS_ny boDPS_ny.;

var=&var;

run;

/*aggregerer på ny boDPS variabel*/
proc sql;
create table agg_&dsinn._boDPS_ny as
select distinct aar, boDPS_ny, sum(var) as var_ny
from agg_&dsinn._boDPS2
group by aar, boDPS_ny;
quit;
run;


/*Setter sammen datasett med aggregerte tall og innbyggertall og beregner ujustert rate.*/
proc sort data=agg_&dsinn._boDPS_ny;
by aar boDPS_ny;
quit;

proc means data=agg_&dsinn._boDPS_ny noprint nway;
  class boDPS_ny;
  var var_ny;
  output out=agg_&dsinn._boDPS_tot(drop=_type_ _freq_) sum=var_ny;
run;

data agg_&dsinn._boDPS_tot;
  set agg_&dsinn._boDPS_tot;
  aar=9999;
run;

proc sort data=innbygg_&dsinn._boDPS_ny;
by aar boDPS_ny;
quit;

proc means data=innbygg_&dsinn._boDPS_ny noprint nway;
  class boDPS_ny;
  var innb_ny;
  output out=innbygg_&dsinn._boDPS_tot(drop=_type_ _freq_) sum=innb_ny;
run;

data innbygg_&dsinn._boDPS_tot;
  set innbygg_&dsinn._boDPS_tot;
  aar=9999;
run;


data agg_&dsinn._boDPS_rate;
merge agg_&dsinn._boDPS_ny 
      agg_&dsinn._boDPS_tot
      innbygg_&dsinn._boDPS_ny
      innbygg_&dsinn._boDPS_tot;
by aar boDPS_ny;

var_rate=10000*var_ny/innb_ny;

run;

%mend;

%lag_rater(dsinn=&ds_en);
%lag_rater(dsinn=&ds_to);
%lag_rater(dsinn=&ds_tre);
%lag_rater(dsinn=&ds_fire);




/* dataset of this format is used to create figures with columns, with the vbarparm statement*/
data DPS_&figtittel;
set agg_&ds_en._boDPS_rate (in=a)
    agg_&ds_to._boDPS_rate (in=b)
    agg_&ds_tre._boDPS_rate(in=c)
    agg_&ds_fire._boDPS_rate(in=d);

  if a then alder="&aldr_str1";
  if b then alder="&aldr_str2";
  if c then alder="&aldr_str3";
  if d then alder="&aldr_str4";

where boDPS_ny le 14;
run;

/* dataset of this format is used to create figures with lines, with the series statement*/
data DPS_&figtittel.2;
merge agg_&ds_en._boDPS_rate (rename=(var_rate=var_rate1)) 
      agg_&ds_to._boDPS_rate (rename=(var_rate=var_rate2))
      agg_&ds_tre._boDPS_rate (rename=(var_rate=var_rate3))
      agg_&ds_fire._boDPS_rate (rename=(var_rate=var_rate4));
by aar boDPS_ny;
where boDPS_ny le 14;
run;



/*FIGURER*/

%let mappe=Panelfigurer\png\;

ODS Graphics ON /reset=All imagename="&figtittel._DPS_panel" imagefmt=png border=off;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe";


proc sgpanel data=DPS_&figtittel noautolegend sganno=&anno pad=(Bottom=5%);
styleattrs datacolors=(CX95BDE6 CX568BBF CX00509E black);
PANELBY boDPS_ny / columns=7 rows=2 novarname spacing=2 HEADERATTRS=(Color=black Family=Arial Size=8) noheaderborder;
where aar=9999;
vbarparm category=aar response=var_rate / group=alder groupdisplay=cluster outlineattrs=(thickness=1 color=bgr) missing;
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
PANELBY boDPS_ny / columns=7 rows=2 novarname spacing=2 HEADERATTRS=(Color=black Family=Arial Size=8) noheaderborder;
where aar=9999;
vbarparm category=aar response=var_rate / group=alder groupdisplay=cluster outlineattrs=(thickness=1 color=bgr) missing;
keylegend / noborder position=bottom;
colaxis fitpolicy=thin display=(nolabel noticks novalues) valueattrs=(size=8);
rowaxis label="&xlabel" valueattrs=(size=8) labelattrs=(size=8)  ;
RUN; 


ods listing close;

proc datasets nolist;
delete yr: del: innbygg_: agg:;
run;

%mend;
