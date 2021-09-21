%LET DIR = C:\Users\ericy\Documents\METRO\SAS project\project;
%LET TRAINLOC = C:\Users\ericy\Documents\METRO\SAS project\project\train.csv;

LIBNAME YEE "&DIR.";


/********************************************************************************
****** Back-ground: data collections and description of your project data *******
*********************************************************************************/

** IMPORT PROJECT DATA TO SAS (PROC IMPORT) **;
PROC IMPORT OUT= YEE.TRAIN 
            DATAFILE= "&TRAINLOC."
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

** Turn on macro options **;
Options MLogic MPrint SymbolGen;

** DESCRIBE PROPERTIES OF THE PROJECT DATA (PROC CONTENTS) **;
PROC SQL;
  DESCRIBE TABLE YEE.TRAIN;
QUIT;

PROC CONTENTS DATA=YEE.TRAIN VARNUM SHORT;
RUN;

*User_ID Product_ID Gender Age Occupation City_Category Stay_In_Current_City_Years
Marital_Status Product_Category_1 Product_Category_2 Product_Category_3 Purchase;


PROC PRINT DATA = YEE.TRAIN (OBS=20);
RUN;


*CONCEPTUAL FRAMEWORK;
* Y = Purchase;
* X = Gender Age Occupation City_Category Stay_In_Current_City_Years
Marital_Status Product_Category_1 Product_Category_2 Product_Category_3;

*SELECT FROM PROJECT DATA;

PROC SQL;
  CREATE TABLE T1 AS
  SELECT Purchase, Gender, Age, Occupation, City_Category, Stay_In_Current_City_Years,
	Marital_Status, Product_Category_1, Product_Category_2, Product_Category_3
  FROM YEE.TRAIN;
QUIT;

** TRANSFORM TO CATEGORICAL **;
DATA T11;
  SET T1;
  Marital_Status = PUT(Marital_Status, 1.);
  Occupation = PUT(Occupation, 2.);
  Product_Category_1 = PUT(Product_Category_1, 2.);
  Product_Category_2 = PUT(Product_Category_2, 2.);
  Product_Category_3 = PUT(Product_Category_3, 2.);
RUN;

*Purchase Occupation Marital_Status Product_Category_1 Product_Category_2 Product_Category_3 ARE CONTINUOUS;
*Gender, Age, City_Category, Stay_In_Current_City_Years ARE CATEGORICAL;
*Occupation Marital_Status MAY OR MAY NOT NEED TO CHANGE TYPE;

*MISSING VALUES;
PROC MEANS DATA = T1 N NMISS RANGE MIN MEAN STD MAX MAXDEC=2;
  VAR Occupation Marital_Status Purchase Product_Category_1 Product_Category_2 Product_Category_3;
RUN;


*REPLACE ALL MISSING VALUES WITH 0;
PROC STDIZE DATA = T1 OUT = T2 REPONLY MISSING=0;
  VAR Purchase Product_Category_1 Product_Category_2 Product_Category_3;
RUN;

*CHECK NEW DATASET VARIABLES/ MAKE SURE NO MORE MISSING;
PROC MEANS DATA = T2 N NMISS RANGE MIN MEAN STD MAX MAXDEC=2;
  VAR Occupation Marital_Status Purchase Product_Category_1 Product_Category_2 Product_Category_3;
RUN;


****************************************;
*UNIVARIATE ANALYSIS;
****************************************;

*FIVE NUMBER SUMMARY: CONTINUOUS VARIABLES;
PROC UNIVARIATE DATA = T2;
  VAR Purchase;
RUN;

*FREQUENCY COUNT FOR CATEGORICAL VARIABLES;
PROC FREQ DATA = T2;
  TABLE Product_Category_1 Product_Category_2 Product_Category_3 Occupation Marital_Status Gender Age City_Category Stay_In_Current_City_Years;
RUN;


*GRAPHICS;
*CONTINUOUS: HISTOGRAM/ DENSITY CURVE AND BOX PLOT;

*MACRO FOR HISTOGRAMS;

/*FIGURE 1*/
%MACRO HISTOUT(VARS, DSN=);
PROC SGPLOT DATA = &DSN;
  HISTOGRAM &VARS;
  DENSITY &VARS/ TYPE = KERNEL;
  KEYLEGEND/LOCATION = INSIDE POSITION = TOPLEFT;
  TITLE "HISTOGRAM DISTRIBUTION OF &VARS AMOUNT";
RUN;
%MEND HISTOUT;
%HISTOUT(VARS=Purchase,DSN=T2);


*MACRO FOR VBOX;

/*FIGURE 2*/
%MACRO VBOXOUT(VARS=, DSN=);
PROC SGPLOT DATA = &DSN;
  VBOX &VARS/LINETTRS =(PATTERN=SOLID);
  XAXIS DISPLAY =(NOLABEL);
  KEYLEGEND/LOCATION =INSIDE POSITION =TOPRIGHT;
  TITLE "BOXPLOT DISTRIBUTION OF &VARS AMOUNT";
RUN;
%MEND VBOXOUT;
%VBOXOUT(VARS=Purchase, DSN=T2);

*SKEWED TO THE RIGHT (positive skewed);
*OUTLIERS ARE SHOWN, NEED TO REMOVE;


*BINNING FOR Marital_Status;
PROC FORMAT;
  VALUE MARR 0 = "NOT MARRIED"
  			 1 = "MARRIED";
RUN;

PROC FREQ DATA=T2;
  TABLE Marital_Status;
  FORMAT Marital_Status MARR.;
RUN;


*REMOVE OUTLIERS FOR PURCHASE;
*OUTLIERS ARE LARGER THAN 12054 + 1.5*6231 = 21401;
PROC SQL;
  CREATE TABLE YEE.DATA1 AS 
  SELECT *, SUM(Product_Category_1,Product_Category_2,Product_Category_3) as Prod_Sum
  FROM T2
  WHERE Purchase LE 21401;
QUIT;



%HISTOUT(VARS=Purchase, DSN=YEE.DATA1);

%VBOXOUT(VARS=Purchase, DSN=YEE.DATA1);


*GRAPHICS FOR CATEGORICAL;
*Gender, Age, City_Category, Stay_In_Current_City_Years, Occupation, Marital_Status, Occupation, Product_Category;

/*FIGURES 3,4*/
%MACRO PIEOUT(VARS=, DSN=);
PROC GCHART DATA = &DSN;
  PIE &VARS;
  TITLE "PIE CHART DISTRIBUTION OF &VARS";
RUN;
QUIT;
%MEND PIEOUT;
%PIEOUT(VARS=Gender, DSN=YEE.DATA1);
%PIEOUT(VARS=Marital_Status, DSN=YEE.DATA1);


/*FIGURE 5,6,7*/
%MACRO VBAROUT(VARS=, DSN=);
PROC SGPLOT DATA = &DSN;
  VBAR &VARS;
  XAXIS DISPLAY =(NOLABEL);
  KEYLEGEND/LOCATION =INSIDE POSITION =TOPRIGHT;
  TITLE "DISTRIBUTION OF &VARS";
RUN;
%MEND VBAROUT;
%VBAROUT(VARS=Age, DSN=YEE.DATA1);
%VBAROUT(VARS=City_Category, DSN=YEE.DATA1);
%VBAROUT(VARS=Stay_In_Current_City_Years, DSN=YEE.DATA1);
%VBAROUT(VARS=Occupation, DSN=YEE.DATA1);
%VBAROUT(VARS=Product_Category_1, DSN=YEE.DATA1);
%VBAROUT(VARS=Product_Category_2, DSN=YEE.DATA1);
%VBAROUT(VARS=Product_Category_3, DSN=YEE.DATA1);


****************************************;
** BIVARIATE ANALYSIS **;
****************************************;
*VISUAL : CATEGORY VS CATEGORY;
*STACKED BAR CHART;

/*FIGURE 8*/
TITLE "PURCHASES BY GENDER/AGEGROUP";
PROC SGPLOT DATA = YEE.DATA1;
 VBAR Age/GROUP=Gender;
 YAXIS DISPLAY = (NOLABEL);
RUN;

*NARROWS THE MOST BUYERS TO MALES IN THE SPECIFIC AGE RANGE;

/*FIGURE 9*/
TITLE "PURCHASE AMOUNTS BY AGEGROUP";
PROC SGPLOT DATA = YEE.DATA1;
 VBOX Purchase/GROUP=Age;
 YAXIS DISPLAY = (NOLABEL);
RUN;

****************************************;
*CONCEPTUAL FRAMEWORK;
****************************************;
* Y = Purchase;
* Xs = Gender Age Occupation City_Category Stay_In_Current_City_Years
Marital_Status Product_Category_1 Product_Category_2 Product_Category_3;

****************************************;
**Hypothesis testing **;
****************************************;
*H0 : Purchase Amount and Gender are NOT CORRELATED;

** TURN PURCHASE INTO CATEGORICAL **;
*RANKED BY HIGH SPENDER LOW SPENDER **;
PROC FORMAT;
 VALUE amt LOW - 7000 = "LOW SPENDER"
		   7000 - 13000 = "MID SPENDER"
		   13000 - high  = "HIGH SPENDER";
RUN;


PROC FREQ DATA = YEE.DATA1;
  TABLE Gender * Purchase / NOCOL NOROW CHISQ;
  FORMAT Purchase amt.;
RUN;


%MACRO SG(VARS=, DSN=);
PROC SGPLOT DATA =&DSN;
  SCATTER X = &VARS Y = Purchase;
  TITLE "DISTRIBUTION OF PURCHASE AND &VARS";
RUN;
%MEND SG;

%SG(VARS=Product_Category_1, DSN=YEE.DATA1);
%SG(VARS=Product_Category_2, DSN=YEE.DATA1);
%SG(VARS=Product_Category_3, DSN=YEE.DATA1);
%SG(VARS=Prod_Sum, DSN=YEE.DATA1);


*CORRELATION MATRIX;
TITLE "CORRELATION MATRIX FOR PURCHASE AND PROD_CATEGORIES";
/*FIGURE 10*/
PROC CORR DATA = YEE.DATA1;
 VAR Product_Category_1 Product_Category_2 Product_Category_3 Purchase;
RUN;



***************************************************************************************************************************
*1.LINEAR RELATIONSHIP BETWEEN Y AND Xs;
* MODEL BUILDING *;
****************************************;

** ANOVA between Purchase and categorical masked variables;
PROC GLM DATA = YEE.DATA1 PLOTS = DIAGNOSTICS;
  CLASS Product_Category_1 Product_Category_2 Product_Category_3;
  MODEL Purchase = Product_Category_1 Product_Category_2 Product_Category_3/ SS3;
  MEANS Product_Category_1 Product_Category_2 Product_Category_3 / HOVTEST;
  FORMAT Purchase amt.;
RUN;
QUIT;



/*FIGURE 11*/
PROC REG DATA = YEE.DATA1;
 MODEL Purchase = Occupation Product_Category_1 Product_Category_2 Product_Category_3/STB CLB;
 OUTPUT OUT= STD_RESIDUAL P = PREDICT R = RESIDUAL;
 FORMAT Purchase amt.;
RUN;
QUIT;

PROC UNIVARIATE DATA = STD_RESIDUAL NORMAL;
 VAR RESIDUAL;
RUN;

/*FIGURE 12*/
*VIF: variant inflation factor;
PROC REG DATA = YEE.DATA1;
 MODEL Purchase = Occupation Product_Category_1 Product_Category_2 Product_Category_3/VIF;
 FORMAT Purchase amt.;
RUN;
QUIT;
*close to 1, so there is not really any collinearity between the masked variables, can proceed with our regression;


*I.VISUALIZE;
/*FIGURE 13*/
PROC REG DATA = YEE.DATA1;
 MODEL Purchase = Occupation Product_Category_1 Product_Category_2 Product_Category_3;
 PLOT R. *P.;
 TITLE "PLOT RESIDUALS BY PREDICTED VALUES";
 FORMAT Purchase amt.;
RUN;
QUIT;



*GENERAL LINEAR MODEL;
proc glm data=YEE.DATA1 order=freq ;
  class Gender Age Stay_In_Current_City_Years;
  model Purchase=Gender Age Marital_Status Stay_In_Current_City_Years Occupation Product_Category_1 Product_Category_2 Product_Category_3;
run;
quit;


