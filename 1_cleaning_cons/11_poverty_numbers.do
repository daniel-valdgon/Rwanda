/*============================================================================================
 ======================================================================================
 ======================================================================================

Project:   Subsidies Rwanda
Author:    EPL (DV & MM) PE (JCP)
Creation Date:  May 2 2021
Objective: This dofiles aims to replicate the welfare aggregate based on cons_aggregate.do 
	

----------------------------------------------------
Notes: See below code that tries to replicate durables and also code to continue improving over the replication of own food consumption
	
 ============================================================================================
 ============================================================================================
 ============================================================================================*/


/*===============================================================================================
					PATH SETTING 
 ==============================================================================================*/

set more off
clear all
set mem 900m

*DATA LOCATION
global data "$proj/Survey_data"

*RESULTS STORAGE
cd "$data/results"
global output "$po"


*Log outputs
cap log close
log using "$output/log/EICV5.log", replace


/*===============================================================================================
	A. CONSTRUCTING CONSUMPTION AGGREGATES
 ==============================================================================================*/

/*---------------------------------
 YEARLY NON-FOOD (exp 12)
*---------------------------------*/

	use "$data\cs_S8A1_expenditure.dta" , clear
	
	gen ynonfood = s8a1q3 if s8a1q1~=21 & s8a1q1~=29 & s8a1q1~=30 & s8a1q1~=31 & s8a1q1~=36 & s8a1q1~=37 & s8a1q1~=38 ///
	& s8a1q1~=44 & s8a1q1~=56 & s8a1q1~=60 & s8a1q1~=62 & s8a1q1~=63 & s8a1q1~=64 & s8a1q1~=65 & s8a1q1~=66 & s8a1q1~=68 // 138 cases (ynonfood>official) look like adjustment for outliers

	*aggregate
	collapse (sum) nfyr=ynonfood, by(hhid)
	tempfile nfyr
	label variable nfyr "yearly non-food expenditures (exp 12 NISR)"
	save `nfyr'

/*---------------------------------
 MONTHLY NON-FOOD (exp13)
*---------------------------------*/

	use "$data\cs_S8A2_expenditure.dta" , clear

	gen mnonfood = s8a2q3 if s8a2q1 ~= 43 & s8a2q1 ~= 44 & s8a2q1 ~= 45 & s8a2q1 ~= 46 // remaining 218 differences (mnonfood>official) seem to be adjusted for outliers
	
	*aggregate
	gen nfmt = 12 * mnonfood
	
	collapse (sum) nfmt, by(hhid)
	label variable nfmt "monthly non-food expenditures (exp 13 NISR)"
	tempfile nfmt
	
	save `nfmt'

/*---------------------------------
  WEEKLY NONFOOD (exp 14)
*---------------------------------*/

	use "$data\cs_S8A3_expenditure.dta" , clear

	egen spend = rowtotal(s8a3q4 -s8a3q13), m // adding up visits2-11, info from the first visit is not used at all 
	
	*aggregate 
	*->from weekly to monthly
	replace spend = (365/12) * spend/30 if  province==1 // Kigali City, consumption over 30 days
	replace spend = (365/12) * spend/14 if  province>1 // All other provinces were interview during 14 days 

	*-> from monthly to annual 
	gen nfwk = spend * 12 //
		
	collapse (sum)  nfwk, by(hhid)
	label variable nfwk "weekly non-food expenditures (exp 14 NISR)"
	tempfile nfwk
	save `nfwk'

/*---------------------------------
  FOOD
*---------------------------------*/
	use "$data\cs_S8B_expenditure.dta" , clear

	egen spend = rowtotal( s8bq4 - s8bq13), m // from 2nd to last visit (11 visits asking fro consumption of 3 days in Kigaly or 7 visits asking for consumption of 2 days in the rest of provinces 
	
	*aggregate 
	*->from weekly to monthly
	replace spend = (365/12) * spend/30 if  province==1 // Kigali City, consumption over 30 days
	replace spend = (365/12) * spend/14 if  province>1 // All other provinces were interview during 14 days 

	*-> from monthly to annual 
	gen food = spend * 12 
	
	collapse (sum)  food , by(hhid)
	tempfile food
	label variable food "food expenditures (exp 15_2 NISR)"
	save `food'

/*---------------------------------
 AUTO-CONSUMPTION  (exp 16_2)
*---------------------------------*/
	use "$data\cs_S8C_farming.dta" , clear
	
	*Quantities from 2nd to last interview 
		egen spend_q = rowtotal(s8cq4 - s8cq13), m 
	
	*Prices Imputation. Replace missing data with median price by province-item or by item depending on data availability
		*-> Cleaning price data
		replace s8cq15=. if s8cq15==9999
		replace s8cq15=. if s8cq15==0 // Not compute the median with obs with zero prices. This lead to minor improvement over previous imputation method
		*-> Compute median of prices by province an article 
		bysort province district s8cq0 : egen medprc = median (s8cq15) 
		bysort province  s8cq0 : egen medprc2 = median (s8cq15)  
		bysort s8cq0 : egen medprc3 = median (s8cq15)  
		*-> Imputing prices 
		replace s8cq15 = medprc if  (s8cq15==. | s8cq15==0 | s8cq15==9999) // added by DV: redundant & s8cq2>0 & s8cq2<99
		replace s8cq15 = medprc2 if (s8cq15==. | s8cq15==0 | s8cq15==9999) // added by DV: redundant & s8cq2>0 & s8cq2<99
		replace s8cq15 = medprc3 if (s8cq15==. | s8cq15==0 | s8cq15==9999) // added by DV: redundant & s8cq2>0 & s8cq2<99
	
	/*Monetary value: prices X quantities. 
		Note 1: Do not use s8cq2 (frequency of purchase). It assumes autoconsumption patterns are the same across the year
		Note 2: s8cq0 of the questionarie is different from the microdata. for example, the code 98 in the quest. is 97 in the microdata. */
		
		gen auto_f = spend_q  * s8cq15 if s8cq0<=98 //  we include up to Dried tobacco leaves for matching the official aggregate. See validation test below 
		gen auto_nf=spend_q  * s8cq15 if s8cq0>98 //  food autoconsumption 
	
	*Aggregate 
	foreach v in auto_f auto_nf {
	*->from weekly to monthly
	replace `v' = (365/12) * `v'/30 if  province==1 // Kigali City, consumption over 30 days
	replace `v' = (365/12) * `v'/14 if  province>1 // All other provinces were interview during 14 days 

	*-> from monthly to annual 
	replace `v' = `v' * 12 //by multiplying by 12 (instead of self-reported number of months consumed)
	}	
	
	collapse (sum)  auto*, by(hhid)
	
	label variable auto_f  "auto-consumption: food (exp 16_2 NISR)"
	label variable auto_nf "auto-consumption: non-food "
	
	tempfile auto
	save `auto'

*---------------------------------
** IN-KIND TRANFERS (EXP18)
*---------------------------------
	use "$data\cs_S9B_transfers_in.dta" , clear
	
	replace s9bq10=. if s9bq10>=9999999
	replace s9bq12=. if s9bq12>=9999999
	
	*aggregate
	egen trfin = rowtotal(s9bq10 s9bq12), m
	egen trfin_f = rowtotal(s9bq10), m
	egen trfin_nf = rowtotal(s9bq12), m
	collapse (sum)  trfin*, by(hhid)
	
	label variable trfin  "Received In-kind f & nf transfers (exp 18 NISR)"
	label variable trfin_f  "Received In-kind food transfers "
	label variable trfin_nf "Received In-kind non-food tansfers "
	
	tempfile trfin
	save `trfin'



/*---------------------------------
 DURABLES 
Notes: We could not replicate it. See code and progress made at the end of this do-file
*---------------------------------*/

	* We data from NISR durables consumption 
	use "$data\EICV5_Poverty_file", clear
	rename exp17 durables
	keep hhid durables
	tempfile durables
	save `durables'

/*---------------------------------
  EDUCATION (EXP 1 )
*---------------------------------*/

	use "$data\cs_S1_S2_S3_S4_S6A_S6E_Person.dta" , clear
	
	*Both health and travel were covered by yearly non-food. We do not save them as the other researchers
	gen health = 0 
	gen travel = 0 
	
	*Education
	egen educ = rowtotal(s4aq11a-s4aq11h ), m // Not included: s4bq2 || to match NISR poverty file, 42 differences seem to be outliers
	
	*aggregate
	collapse (sum)  educ,  by(hhid)
	label variable educ "education expenditures (exp 1 NISR)"

	tempfile educt
	save `educt'

/*---------------------------------
  RENT AND UTILITIES (EXP 4&5, EXP 7, EXP 8)
*---------------------------------*/
	use "$data\cs_S0_S5_Household.dta" , clear
	
	*Rent
	gen estrnt = cond(s5bq3b==1, s5bq3a*12,0)+cond(s5bq3b==2, s5bq3a*4,0)+cond(s5bq3b==3, s5bq3a*1,0) // estimated rent
	gen actrnt = cond(s5bq4b==1, s5bq4a*12,0)+cond(s5bq4b==2, s5bq4a*4,0)+cond(s5bq4b==3, s5bq4a*1,0) // paid rent
	gen padrnt = cond(s5bq6b==1, s5bq6a*12,0)+cond(s5bq6b==2, s5bq6a*4,0)+cond(s5bq6b==3, s5bq6a*1,0) // paid in-kind
	*52 cases (rent<official) of dwelling provided by employer (pending) and 18 cases (rent>official) that might be adjusted as outliers
	*gen padrnt = cond(s5bq9b==1, s5bq9a*12,0)+cond(s5bq9b==2, s5bq9a*4,0)+cond(s5bq9b==3, s5bq9a*1,0)
	
	egen rent1 = rowtotal(estrnt  ), m 
	egen rent2 = rowtotal( actrnt ), m 
	egen rent = rowtotal(estrnt actrnt padrnt), m
	
	gen prvwat= s5cq11 * (365/7) // annualizing weekly payments 
	gen mntwat= s5cq9b *(12/s5cq9a)  
	egen water= rowtotal(mntwat prvwat), m // 2 cases where (water>official) look like adjustment for outliers
	
	
	gen elect= 13*s5cq17 // we multiply by 13 to match official estimates. 4 cases look like adjustment for outliers
	
	
	*aggregate
	collapse (sum) rent*  water elect, by(hhid)
	
	label variable rent1 "Imputed rent (exp 4 NISR)"
	label variable rent2 "Actual rent (exp 5 NISR)"
	label variable rent  "rent expenditures (exp 4+ exp 5 NISR)"
	label variable water "water (utility) expenditures (exp 7 NISR)"
	label variable elect "electricity (utility) expenditures (exp 8 NISR)"
	
	tempfile house
	save `house'

/*---------------------------------
  MANTEINANCE (EXP 6)
*---------------------------------*/
	
	use "$data\cs_S8A1_expenditure.dta" , clear

	gen manteinance = s8a1q3 if s8a1q1==29 | s8a1q1==30
	
	*aggregate
	collapse (sum)  manteinance , by(hhid)
	label variable manteinance "manteinance (exp 6 NISR)"

	tempfile manteinance
	save `manteinance'


/*---------------------------------
* WAGES IN KIND -- NOTE: DATASET AT THE PERSON JOB LEVEL  HHID PID EID
*---------------------------------*/

	use "$data\cs_S6B_Employement_6C_Salaried_S6D_Business.dta" , clear
	
	sort hhid pid
	merge m:1 hhid pid using "$data\cs_S1_S2_S3_S4_S6A_S6E_Person.dta", keepusing(s1q2) nogen
	replace s6bq5 = 1 if hhid == 200820 * pid == 1 & eid == 3 // correcting an observation with s6bq5=0
	
	gen ikfood = s6bq5 * (cond(s6cq19b==1, s6cq19a*(260/12)*cond(s6bq09~=.,s6bq09/5,cond(s6bq11~=.,s6bq11/5,1),1),0) + cond(s6cq19b==2, s6cq19a*(13/3),0) + cond(s6cq19b==3, s6cq19a,0) + cond(s6cq19b==4, s6cq19a/s6bq5,0)) // (exp9)
	
	gen ikhous = s6bq5 * (cond(s6cq21b==1, s6cq21a*(260/12)*cond(s6bq09~=.,s6bq09/5,cond(s6bq11~=.,s6bq11/5,1),1),0) + cond(s6cq21b==2, s6cq21a*(13/3),0) + cond(s6cq21b==3, s6cq21a,0) + cond(s6cq21b==4, s6cq21a/s6bq5,0)) // employer subsidy of house (exp10)
	
	gen ikothr = s6bq5 * (cond(s6cq23b==1, s6cq23a*(260/12)*cond(s6bq09~=.,s6bq09/5,cond(s6bq11~=.,s6bq11/5,1),1),0) + cond(s6cq23b==2, s6cq23a*(13/3),0) + cond(s6cq23b==3, s6cq23a,0) + cond(s6cq23b==4, s6cq23a/s6bq5,0)) // (exp11)
	
	
	replace ikfood = 0 if s1q2 == 12 | s6bq12 == 2 // one remaining case is an outlier
	replace ikhous = 0 if s1q2 == 12 // 33 cases remaining where official=0 and ikhous>0
	replace ikothr = 0 if s1q2 == 12
	egen ikwages = rowtotal(ikfood ikhous ikothr), m
	
	*aggregate
	collapse (sum) ikwages ikfood ikothr ikhous, by(hhid)
	
	label variable ikfood "In-kind wages paid in food (exp 9 NISR)"
	label variable ikhous "In-kind wages paid in housing (exp 10 NISR)"
	label variable ikothr "In-kind wages other goods (exp 11 NISR)"
	label variable ikwages "In-kind wages (exp 9 + exp 10 + exp 11 NISR)"
	
	tempfile wages
	save `wages'


/*===============================================================================================
	B. ADULT EQUIVALENT, PRICE INDEX AND POVERTY LINE
 ==============================================================================================*/

/*---------------------------------
* ADULT EQUIVALENT 
*---------------------------------*/

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
	replace adeq = .90 if s1q1==1 & s1q3y>=60 & s1q3y<70 // NISR should be 0.8? "EICV5_Rwanda_Poverty_Profile.pdf" pg 25
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
	
	collapse (sum) adeqtot= adeq , by(hhid)
	label var adeqtot "Number of adult equivalent by household" 
	tempfile adeq
	save `adeq'

/*---------------------------------
* PRICE INDEX
*---------------------------------*/

	use "$data\EICV5_Poverty_file", clear
	
	* We obtain the implicit price index by the ratio of current/real spending. This deflator is built at the month province level and use food, non-food price indexes. See detils in pg 11 of EICV5_Rwanda_Poverty_Profile.pdf
	gen idx = cons1_ae / sol 
	label var idx "Spatial and price deflator from 2017 to 2014 Rwf prices"

	keep hhid idx // 576 observations with sd>0 within cluster 
	tempfile idx
	save `idx'


/*---------------------------------
* POVERTY LINE 
*---------------------------------*/
	
	use "$data\EICV5_Poverty_file", clear
	
	gen pline_ext=105064
	gen pline_mod=159375  // http://www.ipar-rwanda.org/IMG/pdf/understanding_the_dynamics_of_poverty_in_rwanda.pdf
		
	label var pline_ext "Extreme poverty line (2014 Rwf prices)" 
	label var pline_mod "Moderate poverty line (2014 Rwf prices)"
	
	keep hhid pline_ext pline_mod
	tempfile pline
	save `pline'


/*=====================================================================================
	C. Welfare aggregate 
=======================================================================================*/

	
	use "$data\cs_S0_S5_Household.dta" , clear
	keep hhid clust province district region weight pop_wt  s0qb s0q18m s0q18y
	*ikfood
	local spend_cat_list "educ rent1 rent2 manteinance water elect ikfood ikhous ikothr nfyr nfmt nfwk food auto_f durables trfin"
	
	merge 1:1 hhid using `nfyr', nogen
	merge 1:1 hhid using `nfmt', nogen
	merge 1:1 hhid using `nfwk', nogen
	merge 1:1 hhid using `food', nogen
	merge 1:1 hhid using `auto', nogen
	merge 1:1 hhid using `trfin', nogen
	merge 1:1 hhid using `durables', nogen
	merge 1:1 hhid using `educt', nogen
	merge 1:1 hhid using `manteinance', nogen
	merge 1:1 hhid using `house', nogen
	merge 1:1 hhid using `wages', nogen
	merge 1:1 hhid	using `adeq', nogen
	merge 1:1 hhid	using `pline', nogen
	merge 1:1 hhid	using `idx', nogen
	
	
	egen cons1=rowtotal(`spend_cat_list'), m
	gen cons_ae_wb=cons1/adeqtot
	gen cons_ae_rp_wb=cons_ae_wb/idx
	
	
	save "$output/dta/WB_welfare.dta" , replace 


exit 

/*==================================================
 ==================================================
 ==================================================


/*---------------------------------
**Autoconsumption 
Notes: 
*The key factor is the decisions behind how to impute prices: 
 - 2% of observations with missing if 0 is a valid price if not 
 - count if s8cq15==0 & spend>0: 1742
 - Does not seem to be relevant to convert unit price to kilo **replace s8cq15 = s8cq15*3 if s8cq14=="Piece" & (s8cq0<30 | s8cq0>32)  // not used because prices are reported in the units measured. This seems to be more relevant for comparing quantities or calories*/

*---------------------------------*/

	*Validation (about 1% wrong)
	gen d98=s8cq0==98 & spend_q!=0 & spend_q!=.
	bysort hhid: egen d98_hh=max(d98)
	bysort hhid: egen total_auto=total(auto_f)
	
	merge m:1 hhid using "$data/EICV5_Poverty_file"
	gen t= exp16_2/total_auto
	replace t=1 if exp16_2==0 & total_auto==0 
	replace t=0 if exp16_2!=0 & total_auto==0 
	sum t, d
	count if exp16_2!=0 & total_auto==0 // 404 obs when using 97 
	
	
		*Notes: Include item 98!!!
		*Not clear improvement mean vs median prices
		*Including zero prices in the price imputation  
		*Small improvement in distrbution when only using prices of households who report consumption 
	
	duplicates drop hhid, force 
	
	gen tt=1 if t>0.98 & t<1.02
	replace tt=0 if tt==.  
	ta tt
	
	count if exp16_2!=0 & total_auto==0 // shows 404 obs (hh-product pairs) when using s8cq0<=97. 
	sum t if d98_hh (has 98 consumption) // shows much more mistmatch when using s8cq0<=97.  
	
	



/*---------------------------------
**DURABLES 

	*I try 3 articles tht I know have the same duration, not clear relation in between the empiric distributions
	*sum age_art1 avgage  if   ( s10b2q1==16 | s10b2q1==19 | s10b2q1==20), d
	
	*Also they add 0 when items says 0 
			/*price1	exp17	durables	s10b2q1	s10b2q2	yr_a1
			3000	0	750	Cooker	None	2016*/

*---------------------------------*/

	use "$data\cs_S10B2_Durable_household_goods.dta" , clear 
	
	*Rename variables of price, year and month of up to 3 item of the same article 
	
	*Year
	clonevar yr_a1=s10bq5ay
	clonevar yr_a2=s10bq5by
	clonevar yr_a3=s10bq5cy
	*Month
	clonevar mt_a1=s10bq5am
	clonevar mt_a2=s10bq5bm
	clonevar mt_a3=s10bq5cm
	*Price
	clonevar price1=s10bq7a
	clonevar price2=s10bq7b
	clonevar price3=s10bq7c
		
	forval i=1/3 {
		replace yr_a`i'=. if yr_a`i'==0
		replace mt_a`i'=. if mt_a`i'==0
		replace price`i'=. if price`i'==0
		
		*Defining the age of each article
		gen age_art`i' = (12* 2017) +9 - (12* yr_a`i' + mt_a`i') // Assumption that all households year ends in 2017:june. Not including the month of the purchase made the difference + mt_a`i', it should not be. 
		*One year old at least 
		replace age_art`i' = 12 if age_art`i'<=12    //
		*Change to year units 
		replace age_art`i' = age_art`i'/12
	}
	
	
	*Imputations 
		*median age by article
		egen missing_age = rowmiss(age_art*)
		egen avgage = rowmean(age_art*) if s10b2q2!=0 & s10b2q2!=. ,  // Does not change if we use age_art1 or the avgage
		bysort s10b2q1: egen medage = median (avgage) // neither mean or mode make the magic 
		
		egen avgprice = rowmean(s10bq7a s10bq7b s10bq7c), 
		bysort s10b2q1: egen medprice = median (avgprice)
		
		
	*Cost of use by item
		forval i=1/3 {
			gen prc`i' = price`i' / round(2*medage)  //1.6 is what EICV3 used
		
		}
		
	*Clean data to analyze
	egen missing_durables = rowmiss(prc1 prc2 prc3) 
	drop if missing_durables==3 & s10b2q2==0
	
	*Compute value of use for three or less items 
	egen durables = rowtotal(prc1 prc2 prc3),
	replace durables=. if durables==0
	
	*Compute value of use when having more than three items
	egen durables_mean = rowmean(prc1 prc2 prc3)
	replace durables=durables_mean*s10b2q2 if s10b2q2>3 & s10b2q2!=. & durables_mean!=0 & durables_mean!=.
	
		*Validation 
		bysort hhid: egen total_durables=total(durables)
		bysort hhid: egen N_durables=count(durables)
		merge m:1 hhid using "$data/EICV5_Poverty_file"
		gen t= exp17/total_durables
		replace t=1 if exp17==0 & total_durables==0
		replace t=1 if exp17==. & total_durables==.
		replace t=0 if exp17!=0 & exp17!=. & total_durables==0
		
		compare exp17 total_durables if total_durables!=0

		
		count if exp17==0 & total_durables!=0 // 3000 obs whre we overimpute not related to our imputatio with median values nor the finl imputation of number of items
		
		sum t, d
		
		
		*s10b2q1==6  	has 4 year of depreciation mobile
		*s10b2q1==5  	has 9 year of depreciation radio
		*s10b2q1==7 	has 9 year of depreciation TV set
		*s10b2q1==13 	has 9 year of depreciation living room
		*s10b2q1=14 	has 1.5 yrs Bycycle
		*s10b2q1==15 	has 9 year of depreciation cupboard
		*s10b2q1==16 	has 4 year of depreciation Cooker
		*s10b2q1==19 	has 4 year of depreciation sewing machine
		*s10b2q1==20 	has 4 year of depreciation Refrigeration
		*s10b2q1==29 	has 0 value!!? only for outliers have value!!? Water 
		
		
		duplicates drop hhid, force
		gen tt=1 if t>0.99 & t<1.01
		replace tt=0 if tt==.
		ta tt
		drop t
	
	*aggregate
	*collapse (sum)  durables, by(hhid)
	
*/	