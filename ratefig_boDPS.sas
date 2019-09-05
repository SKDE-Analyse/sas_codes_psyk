/*  This macro takes the kontaktID that is definied using Ptakst (Not pasientdager)
    runs rateprogram 2 times with each of var and var2 
    creates figures with adjusted rates */

%macro ratefig_BoDPS(inndata=, var=poli, var2=poli_unik_aar, utfil_navn=, aggvar=alle);

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

/*Grupperer til pasientdager og institusjonsopphold, aggregerer.*/
%DagAktivitet_Ptakst(inndata=&inndata, utdata=&inndata._DA);
%aggreger_psyk_DA(inndata=&inndata._DA, utdata=agg, agg_var=&aggvar, ut_boHF=0, ut_BehHF=0, ut_komnr=1, ut_boDPS=1);

data agg_komnr;
  set agg_komnr;
  alder=kontaktAlder;
  aar=kontaktAar;
run;

/*Kjører rateprogram for å få justert rate*/
%let ratefil=agg_komnr;
%let RV_variabelnavn=&var; /*navn på ratevariabel i det aggregerte datasettet*/
%Let ratevariabel = &var; /*Brukes til å lage "pene" overskrifter*/
%let forbruksmal = var_&utfil_navn; /*Brukes til å lage tabell-overskrift i Årsvarfig, gir også navn til 'ut'-datasett*/
%include "&filbane\rateprogram\rateprogram.sas";

%let ratefil=agg_komnr;
%let RV_variabelnavn=&var2; /*navn på ratevariabel i det aggregerte datasettet*/
%Let ratevariabel = &var2; /*Brukes til å lage "pene" overskrifter*/
%let forbruksmal = var2_&utfil_navn; /*Brukes til å lage tabell-overskrift i Årsvarfig, gir også navn til 'ut'-datasett*/
%include "&filbane\rateprogram\rateprogram.sas";



/* save the rateprogram output to the same file structure as the unadjusted rates files so that we can use the same lager figurer codes */

data snitt_var;
  set var_&utfil_navn._s_bodps(rename=(bodps=bodps_ny rv_just_rate=var_rate ant_opphold=var_snitt_ny ant_innbyggere=innb_snitt_ny));
  keep bodps_ny var_snitt_ny innb_snitt_ny var_rate;
  where aar=9999;
run;
data snitt_var2;
  set var2_&utfil_navn._s_bodps(rename=(bodps=bodps_ny rv_just_rate=var2_rate ant_opphold=var2_snitt_ny));
  keep bodps_ny var2_snitt_ny var2_rate;
  where aar=9999;
run;

%macro transpose_aar(data=,aar=);
data &data._&aar.;
  set &data._&utfil_navn._s_bodps(rename=(bodps=boDPS_ny ant_opphold=&data._tot_&aar._ny ant_innbyggere=&data._innb_tot_&aar._ny rv_just_rate=&data._rate_&aar.));
  keep bodps_ny &data._tot: &data._innb_tot: &data._rate:;
  where aar=&aar.;
run;
%mend;

%transpose_aar(data=var, aar=2015);
%transpose_aar(data=var, aar=2016);
%transpose_aar(data=var, aar=2017);

%transpose_aar(data=var2, aar=2015);
%transpose_aar(data=var2, aar=2016);
%transpose_aar(data=var2, aar=2017);


data &utfil_navn; /*used to be called agg_boDPS_sn_I_justrate*/
  merge snitt_var snitt_var2 var_2015 var_2016 var_2017 var2_2015 var2_2016 var2_2017;
  by bodps_ny;

  /*Snittrate ekstravariabel (for bruk i tabell)*/
  var_var2=var_rate/var2_rate;
  var2_var=var2_rate/var_rate;

  min=min(var_rate_2015, var_rate_2016, var_rate_2017);
  max=max(var_rate_2015, var_rate_2016, var_rate_2017);
run;


/*Lager figurer*/

proc sort data=&utfil_navn;
 by descending var_rate;
run;

%let mappe_png=&mappe.\png\justrate;
ODS Graphics ON /reset=All imagename="&utfil_navn._DPS" imagefmt=png border=off ;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe_png";
proc sgplot data=&utfil_navn noborder noautolegend sganno=anno pad=(Bottom=5%);
where BoDPS_ny le 14;

     hbarparm category=boDPS_ny response=var_rate / fillattrs=(color=CX95BDE6) missing outlineattrs=(color=grey);  

     scatter x=var_rate_2017 y=BoDPS_ny / markerattrs=(symbol=circle       color=black size=9pt) name="y3" legendlabel="2017"; 
	   scatter x=var_rate_2016 y=BoDPS_ny / markerattrs=(symbol=circlefilled color=grey  size=7pt) name="y2" legendlabel="2016"; 
     scatter x=var_rate_2015 y=boDPS_ny / markerattrs=(symbol=circlefilled color=black size=5pt) name="y1" legendlabel="2015";

     Highlow Y=BoDPS_ny low=Min high=Max / type=line name="hl2" lineattrs=(color=black thickness=1 pattern=1); 
     keylegend "y1" "y2" "y3" / across=3 position=bottom location=outside noborder valueattrs=(size=7pt);

 	   *yaxis min=24 display=(noticks noline) label='Opptaksområde' labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=8);
	   yaxis display=(noticks noline) label='Bosatte i opptaksområdene' labelpos=top labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=9);
     xaxis  offsetmin=0 offsetmax=0.02  valueattrs=(size=8) label="&xlabel" labelattrs=(size=8 weight=bold);
     Yaxistable &hoyretabell /Label location=inside labelpos=top position=right valueattrs=(size=9 family=arial) labelattrs=(size=9);
     
	 label &labeltabell;

format &formattabell;

run;Title; ods listing close;


%let mappe_pdf=&mappe.\pdf\justrate;
ODS Graphics ON /reset=All imagename="&utfil_navn._DPS" imagefmt=pdf border=off ;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe_pdf";
proc sgplot data=&utfil_navn noborder noautolegend sganno=anno pad=(Bottom=5%);
where BoDPS_ny le 14;

     hbarparm category=boDPS_ny response=var_rate / fillattrs=(color=CX95BDE6) missing outlineattrs=(color=grey); 

     scatter x=var_rate_2017 y=BoDPS_ny / markerattrs=(symbol=circle       color=black size=9pt) name="y3" legendlabel="2017"; 
	   scatter x=var_rate_2016 y=BoDPS_ny / markerattrs=(symbol=circlefilled color=grey  size=7pt) name="y2" legendlabel="2016"; 
	   scatter x=var_rate_2015 y=boDPS_ny / markerattrs=(symbol=circlefilled color=black size=5pt) name="y1" legendlabel="2015";

     Highlow Y=BoDPS_ny low=Min high=Max / type=line name="hl2" lineattrs=(color=black thickness=1 pattern=1); 
     keylegend "y1" "y2" "y3" / across=3 position=bottom location=outside noborder valueattrs=(size=7pt);
 

 	   *yaxis min=24 display=(noticks noline) label='Opptaksområde' labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=8);
	   yaxis display=(noticks noline) label='Bosatte i opptaksområdene' labelpos=top labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=9);
     xaxis  offsetmin=0 offsetmax=0.02  valueattrs=(size=8) label="&xlabel" labelattrs=(size=8 weight=bold);
     Yaxistable &hoyretabell /Label location=inside labelpos=top position=right valueattrs=(size=9 family=arial) labelattrs=(size=9);

	 label &labeltabell;

format &formattabell;

run;Title; ods listing close;



%mend;