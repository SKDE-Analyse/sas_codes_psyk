/* This macro makes a butterfly plot
Must run Ratefig_boDPS macro first to get the rates of the 2 parts (for plotting) + total (for sorting) 

fil1   to the left of the origin
data1  the rate we want to plot (var or var2, based on the variables used in Ratefig_boDPS macro)
fil2   to the right of the origin
data2  the rate we want to plot (var or var2)
fil3   the total that we want to sort the figure by
data3  the rate we want to sort (var or var2)

EXAMPLE:
%Let tabellvar1=var_snitt_ny;
%Let tabellvar2=var_rate;
%Let hoyretabell=&tabellvar1 ;
%Let labeltabell=&tabellvar1="Pasienter" &tabellvar2="Rate";
%Let xlabel=Pasienter per 10 000 innbyggere, justert for kjønn og alder;
%Let formattabell=&tabellvar1 &tabellvar2 nlnum8.0 boDPS_ny BoDPS_ny.;
%let tsb=0; 

%ratefig_BoDPS(inndata=phv1517, var=tot_unik_aar, var2=tot, utfil_navn=Pasienter_PHV);
%ratefig_BoDPS(inndata=phv1517, var=tot_unik_aar, var2=tot, utfil_navn=Pasienter_PHV_smi,  aggvar=smi);
%ratefig_BoDPS(inndata=phv1517, var=tot_unik_aar, var2=tot, utfil_navn=Pasienter_PHV_smi0, aggvar=ikke_smi);


%let label1=SMI;
%let label2=ikke SMI;
%Let tabellvar1=tot_rate;
%Let tabellvar2=left_antall;
%Let tabellvar3=right_antall;
%let tabellvar4=left_andel;
%Let hoyretabell=&tabellvar1 &tabellvar2 &tabellvar3 &tabellvar4;
%Let labeltabell=&tabellvar1="Total Rate" &tabellvar2="Antall pas. SMI" &tabellvar3="Antall pas. ikke SMI" &tabellvar4="Andel SMI";
%Let xlabel=Antall pasienter per 10 000 innbyggere, justert for kjønn og alder;
%Let formattabell=&tabellvar1 nlnum8.0 &tabellvar2 &tabellvar3 nlnum8.0 &tabellvar4 percent8.1 boDPS_ny BoDPS_ny.;
%let skala=values=(-10, 0, 20, 40, 60);

%ratefig_butterfly_boDPS(fil1=Pasienter_PHV_smi ,data1=var, fil2=Pasienter_PHV_smi0, data2=var, fil3=Pasienter_PHV, data3=var, figtittel=Pas_antall_PHV_SMI_butterfly);
*/

%macro ratefig_butterfly_boDPS(fil1=, data1=, fil2=, data2=, fil3=, data3=, figtittel=);

proc sort data=&fil1; by bodps_ny; run;
proc sort data=&fil2; by bodps_ny; run;
proc sort data=&fil3; by bodps_ny; run;

data butterfly;
  merge &fil1  (rename=(&data1._rate=left_rate  &data1._snitt_ny=left_antall  var2_var=left_ratio21  var_var2=left_ratio12)  keep=boDPS_ny &data1._rate &data1._snitt_ny var2_var var_var2)
        &fil2  (rename=(&data2._rate=right_rate &data2._snitt_ny=right_antall var2_var=right_ratio21 var_var2=right_ratio12) keep=boDPS_ny &data2._rate &data2._snitt_ny var2_var var_var2)
        &fil3  (rename=(&data3._rate=tot_rate)   keep=boDPS_ny &data3._rate); 
  by boDPS_ny;
  left_rate=left_rate*(-1);
  left_andel=left_antall/(left_antall+right_antall);
  right_andel=right_antall/(left_antall+right_antall);
run;

proc sort data=butterfly;
  by descending tot_rate;
run;

proc format;
  picture positive low-<0='0000' 0<-high='0000';


%macro plot_butterfly(fmt=);

%let mappe_&fmt=&mappe.\&fmt\justrate;
ODS Graphics ON /reset=All imagename="&figtittel" imagefmt=&fmt border=off ;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe.\&fmt\justrate";

proc sgplot data=butterfly noborder noautolegend sganno=anno pad=(Bottom=5%);
  where BoDPS_ny le 14;
  format left_rate right_rate positive.;

  hbarparm category=boDPS_ny response=left_rate  / fillattrs=graphdata1(color=CX568BBF) name="left"  legendlabel="&label1"  missing outlineattrs=(color=grey);  
  hbarparm category=boDPS_ny response=right_rate / fillattrs=graphdata2(color=CX95BDE6) name="right" legendlabel="&label2"  missing outlineattrs=(color=grey);
 
  keylegend "left" "right"; 
  xaxis &skala /*values=(-100 to 500 by 50)*/ grid offsetmin=0.02 offsetmax=0.02  valueattrs=(size=8) label="&xlabel" labelattrs=(size=8 weight=bold);
  yaxis display=(noticks noline) label='Bosatte i opptaksområdene' labelpos=top labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=9);

  Yaxistable &hoyretabell /Label location=inside labelpos=bottom position=right valueattrs=(size=9 family=arial) labelattrs=(size=9);
  label &labeltabell;
  format &formattabell;
run;

ods listing close;
%mend;

%plot_butterfly(fmt=png);
%plot_butterfly(fmt=pdf);

%mend;

