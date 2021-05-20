/*
Name: Code Killer
BUS4022_FinalAssignment
*/


*Part 1 Age;
*Step 1. Read the Age dataset with group;
libname mylib '/home/u50063318/MyData'; 
data mylib.Age;
   infile "/home/u50063318/BUS4022_Data/Age.csv" dsd dlm=',';
   input GEO_Code GEO_Level GEO_Name $ GNR DATA_Quality_Flag ALT_GEO_Code	
   Census_Year Age Total_Sex Male Female; 
   if Age LE 4 and not missing(age) then AgeGroup = 1;
   else if Age GE 5 and Age LE 9 then AgeGroup = 2;
   else if Age GE 10 and Age LE 14 then AgeGroup = 3;
   else if Age GE 15 and Age LE 19 then AgeGroup = 4; 
run;

proc contents data=mylib.Age;
run;

proc means data=mylib.Age;
run;



*Step 2. Analyse the Age dataset;
*1. Calculate the number of gender by each groups in 2016;
title 'The number of gender of each age groups in 2016';
proc sql;
create table gender_2016 as
select
AgeGroup,
sum(Male) as Total_Male_2016,
sum(Female) as Total_Female_2016
from mylib.Age
where Census_Year=2016 and GEO_Level=0
group by AgeGroup;
run;

proc print data=gender_2016 noobs;
run;


*2. Top 10 locations of each group in 2016;
%macro agegrop(g);
title "Top 10 locations of: AgeGroup&g in 2016";
proc sql;
create table location&g  as
select
ALT_GEO_Code,
GEO_Name,
AgeGroup,
sum(Total_Sex) as Total_Sex_2016,
sum(Male) as Total_Male_2016,
sum(Female) as Total_Female_2016
from mylib.Age
where Census_Year=2016 and AgeGroup=&g and GEO_Level=2
group by ALT_GEO_Code, GEO_Name, AgeGroup
order by total_Sex_2016 desc;
run;

proc print data=location&g (obs=10);
run;

%mend agegrop;
%agegrop(1);
%agegrop(2);
%agegrop(3);
%agegrop(4);


*3. The 2011 vs. 2016 numbers in each of the 3 age groups;
/*a.Calculate the percentage of each group.*/
%macro agegrop(ag);
proc sql;
create table Difference&ag as
select
Census_Year,
AgeGroup,
sum(Total_Sex) as Total_Sex
from mylib.Age
where AgeGroup=&ag and GEO_Level=0
group by Census_Year,AgeGroup;
run;

data Percent&ag;
   set Difference&ag;
   Diff_total = (Total_Sex - lag(Total_Sex))/lag(Total_Sex);
   Percent_Diff_YtY=put(Diff_total,percent8.2);
run;

%mend agegrop;
%agegrop(1);
%agegrop(2);
%agegrop(3); 

/*b. Put all the datasets into one dataset.*/
data Percent;
   set Percent1-Percent3;           
run;

title 'The percent of each group gone up or down 2016 vs. 2011';
proc print data=Percent noobs;
run;


*4. Calculate the percentage of each group in top 10 locations;
/*a. Calculate the total number in 2016 and 2011.*/
%macro yar(y);

title "Top 10 locations in &y";
proc sql;
create table location_&y as
select
ALT_GEO_Code,
GEO_Name,
sum(Total_Sex) as Total_Sex_&y
from mylib.Age
where Census_Year=&y and GEO_Level=2
group by ALT_GEO_Code, GEO_Name
order by Total_Sex_&y desc;
run;

%mend yar;
%yar(2011);
%yar(2016);

/*b. Put two datasets into one dataset.*/
proc sql;
create table location_2011_2016 as
select
n.*,
p.Total_Sex_2011 
from location_2016 as n 
   left join location_2011 as p
   on n.ALT_GEO_Code = p.ALT_GEO_Code;
quit;

/*c. add a new column(Percent_Diff_YtY).*/
data Difference_location;
set location_2011_2016;
    Diff_total=(Total_Sex_2016-Total_Sex_2011)/Total_Sex_2011;
    Percent_Diff_YtY=put(Diff_total,percent8.2);
run;

/*d. Calculate the percentage of top 10 locations.*/
title "Top 10 locations in 2011 vs. 2016";
proc sql;
create table Percent_location as
select
  ALT_GEO_Code,
  GEO_Name,
  Total_Sex_2011,
  Total_Sex_2016,
  Percent_Diff_YtY
from Difference_location
order by Total_Sex_2016 desc;
run;

proc print data=Percent_location (obs=10);
run;





*Part 2 Income;
*Step 1. Read the Income dataset with group;
data mylib.Income;
   infile "/home/u50063318/BUS4022_Data/Income.csv" dsd dlm=',';
      length GEO_Name $ 50 
             Income_Source_and_Taxes $ 30;
   input GEO_Name $ Income_Source_and_Taxes $ Population_Age15_and_Over Income_Amount Median_amount;
   format Income_Amount Median_amount dollar10.;
run;

proc contents data=mylib.Income;
run;

proc means data=mylib.Income mean max min maxdec=1;
run;



*Step 2. Analyse the Age dataset;
*1. Calculate the 25th,50th and 75th Percentile of the Median Income;
title 'Percentile of Median Income';
proc univariate data=mylib.income;
  var Median_amount;
  output pctlpre=P_ pctlpts= 25, 50 ,75;
run;


*2. Catergorize Income Group Based on Percentile;
title 'Income Group of Top 10 city';
PROC SQL;
create table IncomeGrp as
 SELECT GEO_Name, Median_amount,
 CASE
 WHEN Median_amount BETWEEN 0 AND 29665 THEN 'LOW'
 WHEN Median_amount BETWEEN 29666 AND 37275 THEN 'MIDDLE'
 WHEN Median_amount ge 37276 THEN 'HIGH'
 END AS IncomeGrp
 FROM mylib.Income
order by Median_amount desc;
run;
proc print data=IncomeGrp;
run;





*Part 3 Language in total age;
*Step 1. Read the language dataset;
data mylib.Languages;
   infile "/home/u50063318/BUS4022_Data/Language1.csv" dsd dlm=',';
   length GEO_NAME $ 15 DIM_Lang_at_home $ 30;
   input GEO_NAME $ GNR DIM_Lang_at_home $ English French Eng_Fre_Speak Neither_EngFre;
run;

proc contents data=mylib.Languages;
run;

proc means data=mylib.Languages;
run;



*Step 2. Analyse the Language dataset;
*1. Except English & French Top 3 languages at 10 area in 2016;
%macro lang(l);
title "Top 3 languages most used at home at &l in 2016";
proc sql;
create table Top3_languages&l  as
select
GEO_NAME,
DIM_Lang_at_home,
sum(Neither_EngFre) as Neither_EngFre_2016
from mylib.Languages
where GEO_NAME="&l"
group by GEO_NAME,GNR,DIM_Lang_at_home
order by Neither_EngFre_2016 desc;
run;

proc print data=Top3_languages&l (obs=3);
run;

%mend lang;
%lang(Calgary);
%lang(Edmonton);
%lang(Hamilton);
%lang(Kitchener);
%lang(Montreal);
%lang(Ottawa_Gatineau);
%lang(Quebec);
%lang(Toronto);
%lang(Vancouver);
%lang(Winnipeg);


*2.the number of people Speak English & French in 2016;
title "The number of people Speak English_French in 2016";
proc sql;
create table Eng_Fre  as
select
GEO_NAME,
sum(English) + sum(Eng_Fre_Speak/2) as total_eng,
sum(French) + sum(Eng_Fre_Speak/2) as total_fre
from mylib.Languages
group by GEO_NAME;

proc print data=Eng_Fre ;
run;



*Part 4 Language in 0-14 years old & 15-19 years old;
*Step 1. Read the language dataset;
data mylib.LanguagesGroup;
   infile "/home/u50063318/BUS4022_Data/Language2.csv" dsd dlm=',';
   length GEO_NAME $ 15 GNR $ 15 DIM_Lang_at_home $ 30 ;
   input GEO_NAME $ GNR DIM_Lang_at_home $ English French Eng_Fre_Speak Neither_EngFre;
   if GNR = "0 to 14 years" then AgeGroup = 5;
   else if GNR = "15 to 19 years" then AgeGroup = 4; 
run;


proc contents data=mylib.LanguagesGroup;
run;

proc means data=mylib.LanguagesGroup;
run;



*Step 2. Analyse the Language dataset;
*Except English & French Top 3 languages at 10 area in 2016, age group 0-14, 15-19;
%macro lang(l);
proc sql;
create table Top3_lGroup&l  as
select
GEO_NAME,
AgeGroup,
DIM_Lang_at_home,
sum(Neither_EngFre) as Neither_EngFre_2016
from mylib.LanguagesGroup
where GEO_NAME="&l"
group by GEO_NAME,AgeGroup,DIM_Lang_at_home
order by AgeGroup,Neither_EngFre_2016 desc;
run;

title "Top 3 languages most used at home at &l between 15-19 in 2016";
proc print data=Top3_lGroup&l (obs=3);
run;

title "Top 3 languages most used at home at &l between 0-14 in 2016";
proc print data=Top3_lGroup&l  (firstobs=178 obs=180);
run;

%mend lang;
%lang(Calgary);
%lang(Edmonton);
%lang(Hamilton);
%lang(Kitchener);
%lang(Montreal);
%lang(Ottawa_Gatineau);
%lang(Quebec);
%lang(Toronto);
%lang(Vancouver);
%lang(Winnipeg);



