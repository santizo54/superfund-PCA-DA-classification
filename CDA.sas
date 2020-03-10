/* Import data */

proc import datafile='C:\Users\Christian Santizo\Google Drive\CSULB\Courses\STAT 550\Project\pdb_tract.csv'
	out = work.foo
	dbms = CSV
	replace;
run;

/* Reformat and label the variables */

data pdb_full;
	set foo (rename=(
					Civ_labor_16_24_ACS_09_13=v1
					Civ_labor_25_44_ACS_09_13=v2
					Civ_labor_45_64_ACS_09_13=v3
					Civ_labor_65plus_ACS_09_13=v4
					Pop_18_24_ACS_09_13=v5
					Pop_25_44_ACS_09_13=v6
					Pop_45_64_ACS_09_13=v7
					Pop_65plus_ACS_09_13=v8
					Med_HHD_Inc_ACS_09_13=s9
					has_superfund=v10));
		v9 = input(s9, comma12.);
	/* Use median income as a classification variable (low, middle, high).
		Group each analysis by whether the area is considered a Superfund site or a non-Superfund site. */
	If v10 = 1 then AREA = 'SUPERFUND'; else AREA = 'NONSUPERFUND';
	If v9 >= 118000 then WEALTH = 'UCLASS'; else if v9 <= 39500 then WEALTH = 'LCLASS'; else WEALTH = 'MCLASS';
	
	label	v1 = "Civilians aged 16 to 24 in the labor force"
			v2 = "Civilians aged 25 to 44 in the labor force"
			v3 = "Civilians aged 45 to 65 in the labor force"
			v4 = "Civilians aged 65 and over in the labor force"
			v5 = "Persons aged 18 to 24 in the ACS"
			v6 = "Persons aged 25 to 44 in the ACS"
			v7 = "Persons aged 45 to 64 in the ACS"
			v8 = "Persons aged 65 and over in the ACS";
	keep Flag v1-v8 AREA POVERTY WEALTH;
	drop s9;
run;

data pdb;
	set pdb_full;
	if Flag = 1 then delete;
	drop Flag;
run;

proc datasets noprint;
   delete foo pdb_full;
run;
quit;

/* Summary Statistics of predictors */

ODS RTF File="C:\Users\Christian Santizo\Google Drive\CSULB\Courses\STAT 550\Project\SS.rtf"; *this will make a rtf output file;
ODS Listing Close;
proc means data=pdb MAXDEC=2;
	var v1-v8;
run;
ODS Listing;
ODS RTF Close;

/* Check for strong correlation between predictors */

ODS RTF File="C:\Users\Christian Santizo\Google Drive\CSULB\Courses\STAT 550\Project\Corr.rtf"; *this will make a rtf output file;
ODS Listing Close;
proc corr data=pdb noprob nosimple;
	var v1-v8 ;
run;


proc corr data=pdb noprob nosimple;
	var v2 v3 v6 v7 ;
run;

ODS Listing;
ODS RTF Close;

/* Q-Q plots of the strongly-correlated predictors */

proc sort data=pdb;
	by WEALTH;
run;

proc univariate data=pdb normal plot noprint;
	var v2 v3 v6 v7;
	by WEALTH;
	qqplot/normal (mu=est sigma=est);
run; * Most variables are skewed (not normal) ;

/* Scatterplots against the strongly-correlated predictors */

proc gplot data=pdb;
 plot v2*v6 = WEALTH
		v3*v7 = WEALTH; 
 Symbol1 V=dot I=None C=RED;
 Symbol2 V=circle I=None C=BLUE;
 Symbol3 V=star I=None C=GREEN;
run; quit;

/* Principal Component Analysis on the strongly-correlated predictors */

proc sort data=pdb;
	by AREA;
run;

Proc PrinComp Data=pdb cov Out=PrinComp matrix; *Use covariance since variables vary in a similar range;
	var v2 v3 v6 v7;
Run;

/* Linear Discriminant Analysis using the PCA variables */

Proc Means Data=PrinComp NoPrint;
 Var Prin1 Prin2;
 Output Out=final1 Min=Min1 Min2 Max=Max1 Max2;
Run;

Data PlotF;
 If _N_=1 Then Set final1;
 Inc1=(Max1-Min1)/50;
 Inc2=(Max2-Min2)/50;


 Do Prin1 = (Min1-Inc1) To (Max1+Inc1) By Inc1;
   Do Prin2 = (Min2-Inc2) To (Max2+Inc2) By Inc2;
     Output;
     Keep Prin1 Prin2;
   End;
 End;
 Stop;
Run;

Title 'Linear Discrimination using PC1 and PC2';
proc sort data=PrinComp;
	by AREA;
run;

Proc DISCRIM Data=PrinComp
             Testdata=PlotF TestOut=PlotP TestOutD=PlotD;
   Class WEALTH;
   BY AREA;
   Var Prin1 Prin2;
Run;

Proc GPlot Data=PlotP;
 Plot Prin1*Prin2=_Into_/HAxis=Axis1 VAxis=Axis2;
 by AREA;
 Symbol1 V=circle H=0.7 I=None C=RED;
 Symbol2 V=Star H=0.7 I=None C=GREEN;
 symbol3 V=dot H=0.7 I=None C=BLUE;
 symbol4 V=circle H=0.7 I=None C=red;
Run; quit;

/* Quadratic Discriminant Analysis using the PCA variables */

Title 'Quadratic Discrimination using PC1 and PC2';
proc sort data=PrinComp;
	by AREA;
run;

Proc DISCRIM Data=PrinComp
             Testdata=PlotF TestOut=PlotP TestOutD=PlotD;
   Class WEALTH;
   BY AREA;
   Var Prin1 Prin2;
Run;

Proc GPlot Data=PlotP;
 Plot Prin1*Prin2=_Into_/HAxis=Axis1 VAxis=Axis2;
 by AREA;
 Symbol1 V=circle H=0.7 I=None C=RED;
 Symbol2 V=Star H=0.7 I=None C=GREEN;
 symbol3 V=dot H=0.7 I=None C=BLUE;
 symbol4 V=circle H=0.7 I=None C=red;
Run; quit;








