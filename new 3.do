/*==================================================
Project:   Subsidies Rwanda
Author:    EPL (DV & MM) PE (JCP)
----------------------------------------------------
Creation Date:  May 2 2021

Notes: This dofiles takes the cons_aggregate.do to replicate the poverty numbers 

datasets already created in other files 
	cs_S0_S5_Household.dta // includes poverty 


datasets created here
	merged18.dta is created here and has the total consumption at household level of different consumption categories created in the following tempfiles:
	nfyr, 
	nfmt, 
	nfwk, 
	food, 
	auto, 
	trfin, 
	trfout, 
	social, 
	durables, 
	hltedu, 
	house, 
	wages, 
	adeq, 
	idx
 
==================================================*/


set more off
clear all
set mem 900m

*DATA LOCATION
global data "$a_proj_eicv"

*RESULTS STORAGE
cd "$a_proj_eicv/results"

*Log outputs
cap log close
log using EICV5.log, replace

/*===============================================================================================
					CONSTRUCTING CONSUMPTION AGGREGATES
 ==============================================================================================*/
*---------------------------------
**YEARLY NON-FOOD
*---------------------------------

	use "$data\cs_S8A1_expenditure.dta" , clear
	
	**replace missing values
	*amount purchased
	bysort province s8a1q0: egen medspd = median (s8a1q3)
	replace s8a1q3 = medspd if ((s8a1q3>=. | s8a1q3==0) & s8a1q2==1)
	
	*aggregate
	collapse (sum)  nfyr=s8a1q3, by(hhid)
	tempfile nfyr
	save `nfyr'

*---------------------------------
**MONTHLY NON-FOOD
*---------------------------------

	use "$data\cs_S8A2_expenditure.dta" , clear

	**replace missing values
	*amount purchased
	bysort province s8a2q0: egen medspd = median (s8a2q3)
	replace s8a2q3 = medspd if ((s8a2q3>=. | s8a2q3==0) & s8a2q2==1)

	*aggregate
	collapse (sum)  s8a2q3, by(hhid)
	gen nfmth = 12 *s8a2q3
	tempfile nfmt
	save `nfmt'
*---------------------------------
**WEEKLY NONFOOD
*---------------------------------
	use "$data\cs_S8A3_expenditure.dta" , clear

	egen spend = rowtotal(s8a3q4 -s8a3q13), m //variable s8a3q3 was added in eicv5 summing up purchases over past 7 days. may affect calculations. for comparability, we keep same method as eicv4 (adding up visits2-11)
	replace spend = 2 * spend if /*(province==1 & ur==2) |*/ province>1 //after checking, we realised that 11 visits were carried out even in rural areas in Kigali City, meaning that they use a recall period of 30 days. So we have changed this to reflect that. Otherwise, we would be over-estimating consumption in rural kigali
	
	**replace missing values
	*months purchased
	replace s8a3q2 = . if s8a3q2==99 
	bysort 	province s8a3q0: egen medmth = median (s8a3q2) //
	replace s8a3q2 = medmth if ((s8a3q2>=. | s8a3q2==0) & s8a3q3>0 & s8a3q3<.)
	
	*amount purchased
		bysort  province s8a3q0: egen medspd = mean (spend) // 
		replace spend = medspd if ((spend>=. | spend==0) & s8a3q2>0 & s8a3q2<99)
	
	**Aggregate
	gen nfwk = spend * s8a3q2
	collapse (sum)  nfwk, by(hhid)
	tempfile nfwk
	save `nfwk'

*---------------------------------
**FOOD
*---------------------------------
	use "$data\cs_S8B_expenditure.dta" , clear
	
	egen spend = rowtotal(s8bq4 - s8bq13), m //variable s8bq3 added in eicv5 summing up purchases over past 7 days. may affect calculations. for comparability, we keep same method as eicv4 (adding up visits2-11)
	replace spend = 2 * spend if /*(province==1 & ur==2) |*/ province>1 //after checking, we realised that 11 visits were carried out even in rural areas in Kigali City, meaning that they use a recall period of 30 days. So we have changed this to reflect that. Otherwise, we would be over-estimating consumption in rural kigali
	
	**replace missing values
	*months purchased
	replace s8bq2 = . if s8bq2==99  
	bysort province s8bq0: egen medmth = mean(s8bq2) if  spend>0 & spend<.
	replace s8bq2 = medmth if ((s8bq2>=. | s8bq2==0) & spend>0 & spend<.) 
	
	*amount purchased
	bysort province s8bq0: egen medspd = mean (spend) if  s8bq2>0 & s8bq2<.
	*replace spend = medspd if ((spend>=. | spend==0) & s8bq2>0 & s8bq2<99) //we have removed these imputations, as we were better able to replicate official NISR food basket (table B4 in EICV4 poverty profile) by removing this line and multiplying total consumption by 12.
	
	*aggregate
	gen food = spend * 12 //s8bq2 if s8bq2<99 //by multiplying by 12 (instead of self-reported number of months consumed) were were able to replicate the official NISR food basket almost exactly, so we assume that this is a better assumption than the one used before.
	decode s8bq0 , gen(TXT)
	keep hhid spend food TXT s8bq0
	
	sort hhid TXT
	tempfile foodqty
	save `foodqty'
	save "foodqty18.dta", replace
	
	collapse (sum)  food , by(hhid)
	tempfile food
	save `food'

*---------------------------------
**AUTO-CONSUMPTION (annualised)
*---------------------------------
	use "$data\cs_S8C_farming.dta" , clear
	
	*replace s8cq15 = s8cq15*135/150
	egen spend = rowtotal(s8cq4 - s8cq13), m //variable added in eicv5 summing up purchases over past 7 days. may affect calculations. for comparability, we keep same method as eicv4 (adding up visits2-11)
	replace spend = 2 * spend if /*(province==1 & ur==2) |*/ province>1 //after checking, we realised that 11 visits were carried out even in rural areas in Kigali City, meaning that they use a recall period of 30 days. So we have changed this to reflect that. Otherwise, we would be over-estimating consumption in rural kigali
	
	**replace missing values
	*months purchased
	replace s8cq2 = . if s8cq2==99  
	bysort province s8cq0: egen medmth = mean (s8cq2) if spend>0 & spend<.
	replace s8cq2 = medmth if ((s8cq2>=. | s8cq2==0) & spend>0 & spend<.)
	
	*amount purchased
	bysort province s8cq0: egen medspd = mean (spend)  if spend>0 & spend<.
	*replace spend = medspd if ((spend>=. | spend==0) & s8cq2>0 & s8cq2<99) //we have removed these imputations, as we were better able to replicate official NISR food basket (table B4 in EICV4 poverty profile) by removing this line and multiplying total consumption by 12.
	
	*price purchased
	replace s8cq15=. if s8cq15==9999
	bysort `prov' s8cq0 : egen medprc = median (s8cq15)  if spend>0 & spend<. //
	replace s8cq15 = medprc if ((s8cq15>=. | s8cq15==0 | s8cq15==9999) & s8cq2>0 & s8cq2<99)
	
	replace s8cq2=12 //by multiplying by 12 (instead of self-reported number of months consumed) were were able to replicate the official NISR food basket almost exactly, so we assume that this is a better assumption than the one used before.
	*aggregate
	gen auto = spend * s8cq2 *s8cq15 if s8cq0<=97 //here we removed non-food item from auto-food consumption
	gen autonf=spend * s8cq2 *s8cq15 if s8cq0>97
	
	decode s8cq0 , gen(TXT)
	
	*convert unit price to kilo 
	replace s8cq15 = s8cq15*3 if s8cq14=="Piece" & (s8cq0<30 | s8cq0>32) 
	
	keep hhid-s8cq0 s8cq2 s8cq14 s8cq15 auto* spend TXT 
	
	tempfile autoqty
	save `autoqty'
	save "autoqty18.dta", replace
	
	collapse (sum)  auto* (mean) weight, by(hhid)
	tempfile auto
	save `auto'

*---------------------------------
**TRANSFERS OUT (yearly)
*---------------------------------
	use "$data\cs_S9A_transfers_out.dta" , clear
	
	*aggregate
	egen trfout = rowtotal(s9aq10 s9aq12), m 
	
	collapse (sum)  trfout, by(hhid)
	tempfile trfout
	save `trfout'

*---------------------------------
**TRANSFERS IN (yearly)
*---------------------------------
	use "$data\cs_S9B_transfers_in.dta" , clear
	
	replace s9bq10=. if s9bq10>=9999999
	replace s9bq12=. if s9bq12>=9999999
	
	*aggregate
	egen trfin = rowtotal(s9bq10 s9bq12), m 
	collapse (sum)  trfin, by(hhid)
	tempfile trfin
	save `trfin'

*---------------------------------
**SOCIAL PROTECTION (yearly)
*---------------------------------
	use "$data\cs_s9d_other_income.dta" , clear
	
	gen  social =s9dq3 if s9dq0==8 
	*aggregate
	collapse (sum)  social, by(hhid)
	
	tempfile social
	save `social'

*---------------------------------
**DURABLES (annualised)
*---------------------------------
	use "$data\cs_S10B2_Durable_household_goods.dta" , clear 
	
	*calculate average age of durables
	gen art1 = 12* 2017 + 6  - (12* s10bq5ay) //S11BQ3A1 + S11BQ3A 
	gen art2 = 12* 2017 + 6  - (12* s10bq5by)  //S11BQ3B1 + S11BQ3B
	gen art3 = 12* 2017 + 6  - (12* s10bq5cy)  //S11BQ3C1 + S11BQ3C
	replace art1 = 12 if art1<=0 //
	replace art2 = 12 if art2<=0
	replace art3 = 12 if art3<=0
	
	egen avgage = rowmean(art1 art2 art3), 
	bysort s10b2q1: egen medage = median (avgage)
	
	*impute missing values
	forval i=1/3 {
	}
	*calculate the flow value of durables
	gen prc1 = s10bq7a / (2*medage/12)  //1.6 is what we used in EICV3
	gen prc2 = s10bq7b / (2*medage/12)
	gen prc3 = s10bq7c / (2*medage/12)
	
	
	*impute missing values
	forval i=1/3 {
	bysort s10b2q1: egen medprc`i' = median (prc`i')
	replace prc`i' = medprc`i' if prc`i'>=999999 & art`i'!=.
	} 
	egen durables = rowtotal(prc1 prc2 prc3), 
	
	*aggregate
	collapse (sum)  durables, by(hhid)
	tempfile durables
	save `durables'

*---------------------------------
*HEALTH / EDUCATION
*---------------------------------
	use "$data\cs_S1_S2_S3_S4_S6A_S6E_Person.dta" , clear
	
	*health //NOTE THAT THIS IS COVERED BY YEARLY NON-FOOD IN 2014 
	gen health = 0 //24* health1
	
	*education
	egen educ = rowtotal(s4aq11h s4bq2), m //S2CQ7 S2CQ8 S2DQ14 S2DQ15
	
	*travel //NOTE THAT THIS IS COVERED UNDER YEARLY NON FOOD IN EICV 4 (ALSO IN EICV5)
	gen travel = 0 //rowtotal(S4BQ9A - S4BQ9H), m
	
	*aggregate
	collapse (sum)  health educ travel, by(hhid)
	tempfile hltedu
	save `hltedu'

*---------------------------------
*RENT / UTILITIES
*---------------------------------
	use "$data\cs_S0_S5_Household.dta" , clear
	
	gen estrnt = cond(s5bq3b==1, s5bq3a*12,0)+cond(s5bq3b==2, s5bq3a*4,0)+cond(s5bq3b==3, s5bq3a*1,0)
	gen actrnt = cond(s5bq4b==1, s5bq4a*12,0)+cond(s5bq4b==2, s5bq4a*4,0)+cond(s5bq4b==3, s5bq4a*1,0)
	gen padrnt = cond(s5bq9b==1, s5bq9a*12,0)+cond(s5bq9b==2, s5bq9a*4,0)+cond(s5bq9b==3, s5bq9a*1,0)
	egen rent = rowtotal(estrnt actrnt padrnt), m
	
	gen s5bq11=0 // s5bq11(construction) does not exist in eicv5 so we're adding it here. Value is set to zero further below in eicv4 too, so no problem
	egen house= rowtotal( s5bq11), m  
	gen prvwat= 4*s5cq11 
	gen mntwat= s5cq9b *(12/(s5cq9a *2))  
	gen conwat= 12*s5cq14 
	egen water= rowtotal( mntwat prvwat conwat), m
	
	gen elect= 12*s5cq17
	
	*aggregate
	collapse (sum)  rent house water elect, by(hhid)
	tempfile house
	save `house'

*---------------------------------
*WAGES IN KIND
*---------------------------------
	use "$data\cs_S6B_Employement_6C_Salaried_S6D_Business.dta" , clear
	
	gen ikfood = cond(s6cq19b==1, s6cq19a*240,0) + cond(s6cq19b==2, s6cq19a*50,0) + cond(s6cq19b==3, s6cq19a*12,0) + cond(s6cq19b==4, s6cq19a*1,0)
	gen ikhous = cond(s6cq21b==1, s6cq21a*240,0) + cond(s6cq21b==2, s6cq21a*50,0) + cond(s6cq21b==3, s6cq21a*12,0) + cond(s6cq21b==4, s6cq21a*1,0)
	gen ikothr = cond(s6cq23b==1, s6cq23a*240,0) + cond(s6cq23b==2, s6cq23a*50,0) + cond(s6cq23b==3, s6cq23a*12,0) + cond(s6cq23b==4, s6cq23a*1,0)
	
	egen wages = rowtotal(ikfood ikhous ikothr), m
	*aggregate
	collapse (sum)  wages ikfood, by(hhid)
	tempfile wages
	save `wages'


/*===============================================================================================
	B. Adult equivalent scales 
 ==============================================================================================*/


*---------------------------------
***ADULT EQUIVALENCE (SEE REPORT)
*---------------------------------

use "$data\cs_S1_S2_S3_S4_S6A_S6E_Person.dta", clear

gen adeq = .
*males
replace adeq = .41 if s1q1==1 & s1q3y<1 
replace adeq = .56 if s1q1==1 & s1q3y>=1 & s1q3y<4  
replace adeq = .76 if s1q1==1 & s1q3y>=4 & s1q3y<7  
replace adeq = .91 if s1q1==1 & s1q3y>=7 & s1q3y<10 
replace adeq = .97 if s1q1==1 & s1q3y>=10 & s1q3y<13 
replace adeq = .97 if s1q1==1 & s1q3y>=13 & s1q3y<16 
replace adeq =1.02 if s1q1==1 & s1q3y>=16 & s1q3y<20 
replace adeq =1.00 if s1q1==1 & s1q3y>=20 & s1q3y<40 
replace adeq = .95 if s1q1==1 & s1q3y>=40 & s1q3y<50 
replace adeq = .90 if s1q1==1 & s1q3y>=50 & s1q3y<60 
replace adeq = .80 if s1q1==1 & s1q3y>=60 & s1q3y<70 
replace adeq = .70 if s1q1==1 & s1q3y>=70 & s1q3y<. 

*females
replace adeq = .41 if s1q1==2 & s1q3y<1 
replace adeq = .56 if s1q1==2 & s1q3y>=1 & s1q3y<4  
replace adeq = .76 if s1q1==2 & s1q3y>=4 & s1q3y<7  
replace adeq = .91 if s1q1==2 & s1q3y>=7 & s1q3y<10 
replace adeq =1.08 if s1q1==2 & s1q3y>=10 & s1q3y<13 
replace adeq =1.13 if s1q1==2 & s1q3y>=13 & s1q3y<16 
replace adeq =1.05 if s1q1==2 & s1q3y>=16 & s1q3y<20 
replace adeq =1.00 if s1q1==2 & s1q3y>=20 & s1q3y<40 
replace adeq = .95 if s1q1==2 & s1q3y>=40 & s1q3y<50 
replace adeq = .90 if s1q1==2 & s1q3y>=50 & s1q3y<60 
replace adeq = .80 if s1q1==2 & s1q3y>=60 & s1q3y<70 
replace adeq = .70 if s1q1==2 & s1q3y>=70 & s1q3y<. 

gen member = 1

collapse (sum) adeqtot= adeq member, by(hhid)


tempfile adeq
save `adeq'
*}


/*===============================================================================================
	C. Poverty 
 ==============================================================================================*/


use "$data\EICV5_Poverty_file", clear

gen idx = cons1_ae / sol   //dividing price adjusted consumption aggregate by raw one to get price index used in EICV5

*center index of median price across time/space (this is what will be used for poverty line)
egen tmp_medidx = mean(idx) //added this in eicv5 (do the same in eicv4 do-file if you want to use the nisr price index)
replace idx = (idx / tmp_medidx) //added this in eicv5 

keep hhid idx member
tempfile idx
save `idx'

***CONSUMPTION AGGREGATES

**FIRST CHECKING WHICH ITEMS WERE INCLUDED IN NISR CONSUMPTION AGGREGATE, FOR COMPARABILITY***
use "$data\EICV5_Poverty_file", clear
egen nisr = rowtotal( exp1 exp4 exp5 exp6 exp7 exp8 exp9 exp10 exp11 exp12 exp13 exp14_2 exp15_2 exp16_2 exp17 exp18)
compare nisr cons1 /*these two are identical, which means that nisr included the following items in its consumption aggregate:
variable	name	type	format	label	variable label
						
exp1		double	%9.0g		education expenses
exp4		double	%9.0g		Imputed rents
exp5		double	%9.0g		Actual rents
exp6		double	%9.0g		Maintenance costs
exp7		double	%9.0g		Water expenses
exp8		double	%9.0g		Electricity expenses
exp9		double	%9.0g		in-kind payments mainly food?
exp10		double	%9.0g		Employer subsidy of house
exp11		double	%9.0g		Other in-kind employer benefits
exp12		double	%9.0g		Annual non-food expenditures
exp13		double	%9.0g		monthly non-food expenditures
exp14_2		double	%9.0g		frequent non-food expenditures
exp15_2		double	%9.0g		food expenditures
exp16_2		double	%9.0g		own food consumption
exp17		double	%9.0g		use value of durable goods
exp18		double	%9.0g		Received in-kind transfers: value

THESE ARE THE SAME VARIABLES THAT WERE INCLUDED IN THE EICV4 and EICV3 CONSUMPTION AGGREGATE
*/


*merge
use "$data\cs_S0_S5_Household.dta" , clear
merge 1:1 hhid using `nfyr', nogen
merge 1:1 hhid using `nfmt', nogen
merge 1:1 hhid using `nfwk', nogen
merge 1:1 hhid using `food', nogen
merge 1:1 hhid using `auto', nogen
merge 1:1 hhid using `trfin', nogen
merge 1:1 hhid using `trfout', nogen
merge 1:1 hhid using `social', nogen
merge 1:1 hhid using `durables', nogen
merge 1:1 hhid using `hltedu', nogen
merge 1:1 hhid using `house', nogen
merge 1:1 hhid using `wages', nogen
merge 1:1 hhid	using `adeq', nogen




*merge 1:1 hhid using `month', nogen //removed in eicv5
*merge m:1 QUART province using `price', nogen //removed in eicv5
merge 1:1 hhid using `idx', nogen //added in eicv5 
recode s0q18m (2 3 =1)(5 6 =4)(8 9 =7)(11 12=10), gen(QUART) //added in eicv5

duplicates drop hhid, force

save "merged18.dta", replace

use "merged18.dta", clear

*remove things that are counted elsewhere
replace health = 0
replace house  = 0
replace trfout = 0
replace travel = 0

**adult equivalence
foreach var in nfyr nfmt nfwk food auto autonf  trfin trfout social durables health educ travel rent house water elect wages {
gen ad`var' = `var' / adeqtot
gen ln`var' = ln(ad`var') if ad`var'>0
replace ln`var'= 0 if ln`var'==.

} 

**aggregate

egen total = rowtotal(nfyr nfmt nfwk food auto autonf  trfin trfout social durables health educ travel rent house water elect wages ), m

** remove outliers
foreach var in nfyr nfmt nfwk food auto autonf  trfin trfout social durables health educ travel rent house water elect wages {

*exceptional expenditures

*outliers
replace ln`var'= . if ln`var'==0

bysort province: egen mn`var' =  mean(ad`var')
bysort province: egen mu`var' =  mean(ln`var')
bysort province: egen sd`var' = sd(ln`var')
gen outl`var'= (ln`var'>mu`var'+3.5*sd`var') if ln`var'<.

replace  ad`var' = mn`var'  if outl`var'==1

} 

replace nfyr = . if nfyr>20000000 //manually removing some outliers to get same results as official

egen adtot = rowtotal(ad* ), m

foreach var in nfyr nfmt nfwk food auto autonf  trfin trfout social durables health educ travel rent house water elect wages {
gen shrad`var' = ad`var' / adtot
} 

* price adjustment
gen prcadtot = adtot / idx //  


*tempfile consag
*save `consag', replace



/*===============================================================================================
	D. Poverty line 
 ==============================================================================================*/

********POVERTY LINE**********
preserve

keep QUART hhid weight  prcadtot adfood adauto adtrfin adwages adtot adeqtot member autonf s0q18m // 

*share of non-food
xtile decile = prcadtot [aw=weight*member], n(10) //

egen foodtot  =  rowtotal(adfood adauto adtrfin adwages) 
*replace foodtot= foodtot - (autonf / adtot)
gen  foodshr  =  foodtot /adtot

sum foodshr [iw=weight*member] if decile == 5 //

local foodshr = r(mean)

*quantites
merge 1:m hhid using foodqty18, nogen
drop spend

merge 1:1 hhid TXT using autoqty18, update //

replace s8cq15 = . if s8cq15>=9999 
replace s8cq15 = . if s8cq15==0 //added this to remove zero prices (impossible)
drop if decile >4 //|   s0q19m>1 //

//removed s8cq14  because i don't need it
collapse (sum) food auto spend (median)  QUART weight member adeqtot /*s8cq14*/ s8cq15 s8cq2 province s8cq0 s8bq0 ur s0q18m, by(hhid TXT) //price  foodqae14

*replace missing prices
*replace s8cq14 =. if (s8cq13==3 | s8cq13==.) //remove prices in non-standard units

bysort province QUART TXT: egen medprcpro = median (s8cq15) //
replace s8cq15 = medprcpro if ((s8cq15>=. | s8cq15==0))

*here we calculate the daily qty expended on different s8cq0s

egen foodval = rowtotal(food )
gen  foodqty = (foodval /365) / s8cq15 //price
gen  foodqae1 = foodqty / adeqtot
replace foodqae1 = 0 if foodqae1==.

*gen autoqty = (s8cq2*spend) / 365
gen autoqty = (auto / 365) / s8cq15
replace autoqty =0 if autoqty==.
gen autoqae1 = autoqty / adeqtot

egen foodqae = rowtotal(foodqae1 autoqae1), m

collapse (mean) foodqae  (median) s8cq15 s8cq0 s8bq0 ur [iw=weight *member ], by(TXT) //(median) price = s8cq14 foodqae14
gen foodshr = `foodshr'

br
log close
