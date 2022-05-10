/*==================================================
Project:   Subsidies Rwanda
Author:    EPL (DV & MM) PE (JCP)
----------------------------------------------------
Creation Date:  May 2 2021

Notes: This dofiles takes the cons_aggregate.do to replicate the poverty numbers 

datasets already created in other files 
	cs_S0_S5_Household.dta // includes poverty 


datasets created here
	merged18.dta is created here and has the total consumption at household level of different 		consumption categories created in the following tempfiles:
		nfyr: yr non-food
		nfmt: monthly non-food 
		nfwk: weekly  non-food 
		food: food 
		auto: autoconsumption 
		trfin: transfers in 
		trfout: transfers out
		social: social protection
		durables: durables annualized
		hltedu: healt & education  
		house: rent utilities
		wages: wages in kind 
		adeq: adult equivalent 
		idx: Price index to adjust consumption 


Note: By Looking at blog_EICV_original.do it seems (see lines 1401-1430) that prcadtot is cons aggregate. Also built here in lines 451: "gen prcadtot = adtot / idx"



Questions!!!!!!!
*What do we need ???? *Rebuild from COICOP all the expenditure!!!!?????
* Where is the input output ???
* we go from COICOP (s8bq1) to sectors from sectors to input -output?
		
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

/*---------------------------------
 YEARLY NON-FOOD (exp 12)
*---------------------------------*/

	use "$data\cs_S8A1_expenditure.dta" , clear
	
	gen ynonfood = s8a1q3 if s8a1q1~=21 & s8a1q1~=29 & s8a1q1~=30 & s8a1q1~=31 & s8a1q1~=36 & s8a1q1~=37 & s8a1q1~=38 ///
	& s8a1q1~=44 & s8a1q1~=56 & s8a1q1~=60 & s8a1q1~=62 & s8a1q1~=63 & s8a1q1~=64 & s8a1q1~=65 & s8a1q1~=66 & s8a1q1~=68 // 138 cases (ynonfood>official) look like adjustment for outliers

	*aggregate
	collapse (sum) nfyr=ynonfood, by(hhid)
	tempfile nfyr
	save `nfyr'

/*---------------------------------
**MONTHLY NON-FOOD (exp13)
*---------------------------------*/

	use "$data\cs_S8A2_expenditure.dta" , clear

	gen mnonfood = s8a2q3 if s8a2q1 ~= 43 & s8a2q1 ~= 44 & s8a2q1 ~= 45 & s8a2q1 ~= 46 // remaining 218 differences (mnonfood>official) seem to be adjusted for outliers
	
	*aggregate
	collapse (sum) mnonfood, by(hhid)
	gen nfmth = 12 * mnonfood
	tempfile nfmt
	
	save `nfmt'

	
*---------------------------------
**WEEKLY NONFOOD
*---------------------------------
	use "$data\cs_S8A3_expenditure.dta" , clear

	egen spend = rowtotal(s8a3q4 -s8a3q13), m // adding up visits2-11, info from the first visit is not used at all 
	
	*aggregate 
	*->from weekly to monthly
	replace spend = (365/12) * spend/30 if  province==1 // Kigali City, consumption over 30 days
	replace spend = (365/12) * spend/14 if  province>1 // All other provinces were interview during 14 days 

	*-> from monthly to annual 
	gen nfwk = spend * 12 //
	
	*Validation 
	bysort hhid: egen total_nfwk=total(nfwk)
	merge m:1 hhid using "$data/EICV5_Poverty_file"
	gen t= exp14_2/total_nfwk
	
	compare exp14_2 total_nfwk
	sum t, d
	drop t
	
	
	
	
	collapse (sum)  nfwk, by(hhid)
	tempfile nfwk
	save `nfwk'

*---------------------------------
**FOOD
*---------------------------------
	use "$data\cs_S8B_expenditure.dta" , clear
	
/* Notes:
 -	For the 27 predominantly rural districts, the survey calendar for 12 months is divided into 10 cycles, and each cycle is
divided into two sub-cycles, for a total of 20 enumeration periods of 16 days each. Each enumerator visited a group of 3
sample households every other day. A team of enumerators covers two sample EAs in each sub-cycle, or four EAs during a
full cycle. In other words, each sample household in rural districts was visited 8 times over a period of 16 days.
Questionnaire section 8Aiii, 8B and 8C were asked on every visit, while the other sections were spread out over the 8 visits
(e.g. section 0-3 during 1st visit; section 4, 5a-5d, 8Ai, 8Aii during 2nd visit; section 5e, 6a-6c on 3rd visit; section 6d-6f on
4th visit; section 7a-7c on 5th visit; section 7d-7h on 6th visit; section 9 on 7th visit; section 10 on 8th visit)

- In the case of the three predominantly urban districts in Kigali Province, the data collection in each sample EA was
conducted over a period of 33 days (one cycle). The 9 households in each sample EA were divided into 3 groups of 3
households each. Each enumerator visited one group of 3 sample households each day, so each sample household was
visited every three days. Five EAs are covered in each cycle. In other words, each sample household in Kigali was visited 11
times over a period of 33 days. Questionnaire section 8Aiii, 8B and 8C were asked on every visit, while the other sections
were spread out over the 11 visits (e.g. section 0 and 1 on 1st visit; section 2 and 3 on 2nd visit; section 4 on 3rd visit;
section 5 on 4th visit; section 6a-6c on 5th visit; section 6d-6f on 6th visit; section 7a-7c on 7th visit; section 7d-7h on 8th
visit; section 9 on 9th visit; section 10 on the 10th visit)
*/

*Questions  Household were visited 11 times, each time they ask how much did you spent.this happens in what timeframe? they are asked how many months did they spend on a specific item. Is this used at all? There is one month that is missing?? there is 11 visits because there is 11 point in the middle of 12.... nope

*--> Compute monthly spending (Kigali has difference reference period than the resto of the country)
	
	egen spend = rowtotal( s8bq4 - s8bq13), m // They exclude first visit because it considers a 7 days time frame See Old notes.
			// Old notes: variable s8bq3 added in eicv5 summing up purchases over past 7 days. may affect calculations. for comparability, we keep same method as eicv4 (adding up visits 2-11)
	
	replace spend = (365/12) * spend/30 if  province==1
	replace spend = (365/12) * spend/14 if  province>1 // All districts but the ones of Kigali Province were interview in a lapse of 16 days. Therefore their monthly consumption is the spendinging recorded in 16 times two.
			//	Old notes: we realised that 11 visits were carried out even in rural areas in Kigali City, meaning that they use a recall period of 30 days. So we have changed this to reflect that. Otherwise, we would be over-estimating consumption in rural kigali

*--> Imputation exercise. Not carried out by belgian because it leads to replication problems 
		/*	*Impute frequency of purchase (mean of number of months-s8bq2 by by province
			
			replace s8bq2 = . if s8bq2==99  
			bysort province s8bq0: egen medmth = mean(s8bq2) if  spend>0 & spend<.
			replace s8bq2 = medmth if ((s8bq2>=. | s8bq2==0) & spend>0 & spend<.) 
			
			*Amount bought by month
			bysort province s8bq0: egen medspd = mean (spend) if  s8bq2>0 & s8bq2<.
			*replace spend = medspd if ((spend>=. | spend==0) & s8bq2>0 & s8bq2<99) //we have removed these imputations, as we were better able to replicate official NISR food basket (table B4 in EICV4 poverty profile) by removing this line and multiplying total consumption by 12.
		*/	
	
	*Aggregate
	gen food = spend * 12 // s8bq2 if s8bq2<99 //by multiplying by 12 (instead of self-reported number of months consumed) were were able to replicate the official NISR food basket almost exactly, so we assume that this is a better assumption than the one used before.
	
	
	*Validation 
	bysort hhid: egen total_food=total(food)
	merge m:1 hhid using "$data/EICV5_Poverty_file"
	gen t= exp15_2/total_food
	
	compare exp15_2 total_food
	sum t, d
	gen tt=1 if t>0.99 & t<1.01
	replace tt=0 if tt==.
	ta tt
	
	drop t
	
	
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
	
	replace spend = (365/12) * spend/30 if  province==1
	replace spend = (365/12) * spend/14 if  province>1 // All districts but the ones of Kigali Province were interview in a lapse of 16 days. Therefore their monthly consumption is the spendinging recorded in 16 times two.
		
	*--> Imputation 
	*Frequency of purchase (s8cq2: # of months out of 12 months) using mean of article by provinnce
		*Alternative 1 
			*replace s8cq2 = . if s8cq2==99  
			*bysort province s8cq0: egen medmth = mean (s8cq2) if spend>0 & spend<.
			*replace s8cq2 = medmth if ((s8cq2>=. | s8cq2==0) & spend>0 & spend<.)
		
		*Alternative 2 
		replace s8cq2=12  //by multiplying by 12 (instead of self-reported number of months consumed) were were able to replicate the official NISR food basket almost exactly, so we assume that this is a better assumption than the one used before.
	
	
	*Price per Kg  using median of article by province 
		*Notes: 2% of observations with missing if 0 is a valid price if not 
		*Note: count if s8cq15==0 & spend>0: 1742
	
	*convert unit price to kilo 
	*replace s8cq15 = s8cq15*3 if s8cq14=="Piece" & (s8cq0<30 | s8cq0>32) 
	
	replace s8cq15=. if s8cq15==9999
	replace s8cq15=. if s8cq15==0 // This is added line, lead to different imputed prices have minor improvement effects 
	bysort province s8cq0 : egen medprc = mean (s8cq15)  // I use all valid observatins about prices to compute the median. This has minor improvements in households with high nsir-autoconsumption compared to ours  if spend>0 & spend<. //
	replace s8cq15 = medprc if (s8cq15==. | s8cq15==0 | s8cq15==9999) // added by DV: redundant & s8cq2>0 & s8cq2<99
	
	*Compute prices using similar products for relevant products withouth price s8cq0=6, s8cq0==23, 39
	
	
	*Yearly aggregate: Monthly spending X 12 X Price 
		*Note: The code s8cq0 of the questionarie is different from the microdata. In the questionarie athe code 98 is actually 97 in the microdata. Including s8==99 leads to importnat mistmatch in the bottom 1% so it suggest that 98 includes food . There is a small improvement between code 98 rather than 97
	gen auto = spend * s8cq2 * s8cq15 if s8cq0<=98 //  here we removed non-food item from auto-food consumption
	
	gen autonf=spend * s8cq2 * s8cq15 if s8cq0>98
	
	decode s8cq0 , gen(TXT)
		
	
	*Validation (about 1% wrong)
	bysort hhid: egen total_auto=total(auto)
		/*Old code to verify*/ //bysort hhid: egen total_auto2=total(auto2)
	merge m:1 hhid using "$data/EICV5_Poverty_file"
	gen t= exp16_2/total_auto
	replace t=1 if exp16_2==0 & total_auto==0 
	/*Old code to verify*/ // gen t2= exp16_2/total_auto2
	sum t, d
	count if exp16_2!=0 & total_auto==0 // 404 obs when using 97 
	/*Old code to verify*/ // sum t2, d
	*NOte: count if exp16_2!=0 & total_auto==0 : 7 obs that suggest they impute autocon from somewhere else-> oual include item 98!!!
	*Mean vs median improve cases where they have higher value bt made worse cases where we have higher values overall  not clear improvement 
	* Including zero prices in the MEAN prices improves cases where they were below dramatically but made worse the cases where they are above . with median it produces an error of zero observatons in ours 
	*Small improvement in distrbution when only using prices of households who observe but more cases where exp16_2!=0 & total_auto==0
	
	duplicates drop hhid, force 
	
	gen tt=1 if t>0.98 & t<1.02
	replace tt=0 if tt==.  
	ta tt
	
	
	
	
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
	
	*Calculate average age: Survey made in Jun 2017 against the year of purchase (s10bq5ay) 
	
	clonevar yr_a1=s10bq5ay
	clonevar yr_a2=s10bq5by
	clonevar yr_a3=s10bq5cy
	
	clonevar mt_a1=s10bq5am
	clonevar mt_a2=s10bq5bm
	clonevar mt_a3=s10bq5cm
	
	clonevar price1=s10bq7a
	clonevar price2=s10bq7b
	clonevar price3=s10bq7c
		
	forval i=1/3 {
		replace yr_a`i'=. if yr_a`i'==0
		replace mt_a`i'=. if mt_a`i'==0
		replace price`i'=. if price`i'==0
	}
	
	gen art1 = (12* 2017) + 6  - (12* yr_a1) // - mt_a1 //S11BQ3A1 + S11BQ3A 
	gen art2 = (12* 2017) + 6  - (12* yr_a2) // - mt_a2 //S11BQ3B1 + S11BQ3B
	gen art3 = (12* 2017) + 6  - (12* yr_a3) // - mt_a3 //S11BQ3C1 + S11BQ3C
	
	  
	*When purchased was made in the future assign at least one year...? no changes in the code because of it 
		replace art1 = 12 if art1<=0 //
		replace art2 = 12 if art2<=0
		replace art3 = 12 if art3<=0
	
	*Imputations 
		*Age for each article
		egen avgage = rowmean(art1 art2 art3), 
		bysort s10b2q1: egen medage = median (avgage)
		
		egen avgprice = rowmean(s10bq7a s10bq7b s10bq7c), 
		bysort s10b2q1: egen medprice = median (avgprice)
		
		
		forval i=1/3 {
			*replace art`i'=medage if art`i'==. & price`i'!=. & price`i'!=0
			gen prc`i' = price`i' / (2*art`i'/12)  //1.6 is what we used in EICV3
			*gen  prc`i' = price`i' / (2*medage/12) if art`i'==.   //1.6 is what we used in EICV3
			*replace prc`i'=. if prc`i'==0
			
			*replace prc`i'=price`i'/(2*medage/12) if art`i'==.
			*replace prc`i'=medprice/(2*art`i'/12) if price`i'==.
		}
		
	/* Bfore everything with the median age , so no household heterogeneity
	*Calculate the flow value of durables
		gen prc1 = s10bq7a / (2*medage/12)  //1.6 is what we used in EICV3
		gen prc2 = s10bq7b / (2*medage/12)
		gen prc3 = s10bq7c / (2*medage/12)
	*/
	
	*Impute missing values or very big values 
	*forval i=1/3 {
	*bysort s10b2q1: egen medprc`i' = median (prc`i')
	*dis "Imputing aggregate median "
	*replace prc`i' = medprc`i' if prc`i'>=999999 & art`i'!=.
	*} 
	
	egen durables = rowtotal(prc1 prc2 prc3), 
	egen durables_mean = rowmean(prc1 prc2 prc3)
	*replace durables=durables_mean*s10b2q2 if s10b2q2>3 & durables_mean!=0 & durables_mean!=.
	
	*Validation 
	bysort hhid: egen total_durables=total(durables)
	merge m:1 hhid using "$data/EICV5_Poverty_file"
	gen t= exp17/total_durables
	replace t=1 if exp17==0 & total_durables==0
	
	compare exp17 total_durables
	
	count if exp17==0 & total_durables!=0 // 3000 obs whre we overimpute not related to our imputatio with median values nor the finl imputation of number of items
	
	sum t, d
	duplicates drop hhid, force
	gen tt=1 if t>0.99 & t<1.01
	replace tt=0 if tt==.
	ta tt
	
	
	drop t
	
	
	
	*aggregate
	collapse (sum)  durables, by(hhid)
	tempfile durables
	save `durables'


*---------------------------------
**Manteinance 
*---------------------------------

use "$data\cs_S0_S5_Household.dta" , clear

merge 1:1 hhid using  "$data/EICV5_Poverty_file",  

ta s5aq11 if exp6!=0 // 95% owner , some tenancy other dwelling provided free of charge




use "$data\cs_S8A1_expenditure.dta" , clear

	gen manteinance = s8a1q3 if s8a1q1==29 | s8a1q1==30
	
	*bysort hh
	*bysort province s8a1q0: egen medspd = median (s8a1q3)
	*replace s8a1q3 = medspd if ((s8a1q3>=. | s8a1q3==0) & s8a1q2==1)
	
	*Validation 
	bysort hhid: egen total_manteinance=total(manteinance)
	merge m:1 hhid using "$data/EICV5_Poverty_file"
	gen t= exp6/total_manteinance
	replace t=1 if exp6==0 & total_manteinance==0
	replace t=99999998 if exp6>0 & exp6!=. & total_manteinance==0
	
	sort hhid 
	br hhid-s8a1q3 total_manteinance exp6 if  s8a1q3!=.

	*quantiles total_manteinance, gen (qtiles) n(100)
	*sum qtiles if total_manteinance!=exp6
	
	
	
	sum t, d
	duplicates drop hhid, force
	drop if exp6==0
	gen tt=1 if t>0.99 & t<1.01
	replace tt=0 if tt==.
	ta tt
	
	compare exp6 total_manteinance
	count if exp6==0 & total_manteinance!=0 // 3000 obs whre we overimpute not related to our imputatio with median values nor the finl imputation of number of items
	
*merge 1:m using ""

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


/**---------------------------------
*WAGES IN KIND 
*Note: dataset at the person job level  hhid pid eid
*---------------------------------*/

	use "$data\cs_S6B_Employement_6C_Salaried_S6D_Business.dta" , clear
	
	gen ikfood = cond(s6cq19b==1, s6cq19a*240,0) + cond(s6cq19b==2, s6cq19a*50,0) + cond(s6cq19b==3, s6cq19a*12,0) + cond(s6cq19b==4, s6cq19a*1,0)
	gen ikhous = cond(s6cq21b==1, s6cq21a*240,0) + cond(s6cq21b==2, s6cq21a*50,0) + cond(s6cq21b==3, s6cq21a*12,0) + cond(s6cq21b==4, s6cq21a*1,0)
	gen ikothr = cond(s6cq23b==1, s6cq23a*240,0) + cond(s6cq23b==2, s6cq23a*50,0) + cond(s6cq23b==3, s6cq23a*12,0) + cond(s6cq23b==4, s6cq23a*1,0)
	
	egen wages = rowtotal(ikfood ikhous ikothr), m
	*aggregate
	collapse (sum)  wages ikfood ikhous ikothr, by(hhid)
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



/*===============================================================================================
	C. Implicit price Index
 ==============================================================================================*/


use "$data\EICV5_Poverty_file", clear

gen idx = cons1_ae / sol   //dividing price adjusted consumption aggregate by raw one to get price index used in EICV5

*center index of median price across time/space (this is what will be used for poverty line)
egen tmp_medidx = mean(idx) //added this in eicv5 (do the same in eicv4 do-file if you want to use the nisr price index)
replace idx = (idx / tmp_medidx) //added this in eicv5 

keep hhid idx member
tempfile idx
save `idx'


/*===============================================================================================
	D. Verify construction of consumption aggregate from oficial data? 
==============================================================================================*/

***CONSUMPTION AGGREGATES

**FIRST CHECKING WHICH ITEMS WERE INCLUDED IN NISR CONSUMPTION AGGREGATE, FOR COMPARABILITY***
use "$data\EICV5_Poverty_file", clear
egen nisr = rowtotal( exp1 exp4 exp5 exp6 exp7 exp8 exp9 exp10 exp11 exp12 exp13 exp14_2 exp15_2 exp16_2 exp17 exp18)
compare nisr cons1

* rename variables to compare 
*----> Pendent to analyze : trfin trfout social durables health  travel   wages

*File hltedu
rename exp1	educ_nisr	  // education expenses : educ

*File with replication `house'
rename exp4 rent1_nisr   // imputed rents
rename exp5 rent2_nisr   // Actual rents : rent
egen rent_nisr=rowtotal(rent1_nisr rent2_nisr)
rename exp6 house_nisr   //  Maintenance cost  : house==0 in replication here not if exp6=house
rename exp7 water_nisr   //  Water  : water
rename exp8 elect_nisr   //  Electricity : elect



*File with replication `wages'
rename exp9  ikfood_nisr   // In-Kind food wages
rename exp10 ikhous_nisr  // In-Kind housing wages
rename exp11 ikothr_nisr  // Other In-Kind 
egen wages_nisr=rowtotal (ikfood_nisr ikhous_nisr ikothr_nisr)

*File name as the variable 
rename exp12 nfyr_nisr    // Yr non-food : nfyr
rename exp13 nfmt_nisr    // Monthly non-food : nfmt
rename exp14_2 nfwk_nisr  // Weekly non-food : nfwk
rename exp15_2 food_nisr  // Food : food
rename exp16_2 auto_nisr  // Only food Autoconsumption. Note non-food autoconsumption is excluded in the replication file `auto' the variable's name is autonf  : auto  autonf
*--> note autonf should not be included in replication 
rename exp17   durables_nisr // use value of Durables
rename exp18  trfin_social_trout_nisr // transfers (in &out) and social

*addded by Daniel V
*Adjusted percapita
gen nisr_ae=nisr/ae 
foreach v in educ_nisr rent_nisr wages_nisr rent1_nisr rent2_nisr house_nisr water_nisr elect_nisr ikfood_nisr ikhous_nisr ikothr_nisr nfyr_nisr nfmt_nisr nfwk_nisr food_nisr auto_nisr durables_nisr trfin_social_trout_nisr {
	gen ae_`v'=`v'/ae
} 


keep hhid nisr_ae nisr *_nisr
tempfile cons_agg_nisr
save `cons_agg_nisr', replace


/*nisr==cons1, which implies that we known the subcomponents that nisr included in its consumption aggregate:
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

/*===============================================================================================

Building the consumption aggregate
	Daniel Note: it clean each component from outliers, applies adult equivalent scales and price index
	However it does not store the data bc it has commented the line that saves the data "save `consag', replace"
==============================================================================================*/

*--Merge of spending categories, ae and idx 
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

*-----------
*--Cleaning 
*-----------

*-- Remove things that are counted elsewhere
replace health = 0
replace house  = 0
replace trfout = 0
replace travel = 0

*-- Adult equivalent spending and log values (which will be used for outlier analysis)
	foreach var in nfyr nfmt nfwk food auto autonf  trfin trfout social durables health educ travel rent house water elect wages {
	gen ad`var' = `var' / adeqtot
	gen ln`var' = ln(ad`var') if ad`var'>0
	replace ln`var'= 0 if ln`var'==.
} 

*-- Household aggregate 
	egen total = rowtotal(nfyr nfmt nfwk food auto autonf  trfin trfout social durables health educ travel rent house water elect wages ), m

*-- Outliers: impute the mean by province for ouliers in each spending category
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
	
// Additional outliers 	
	replace nfyr = . if nfyr>20000000 //manually removing some outliers to get same results as official
	
*--> Consumption shares
	egen adtot = rowtotal(ad* ), m
 	foreach var in nfyr nfmt nfwk food auto autonf  trfin trfout social durables health educ travel rent house water elect wages {
	gen shrad`var' = ad`var' / adtot
	} 

*-- price adjustment
	gen prcadtot = adtot / idx //  

*-- Compare this aggregate with the aggregate from NISR
	
	merge 1:1 hhid	using `cons_agg_nisr', nogen

	compare adtot nisr_ae 
	compare total nisr 
	
*---Comparison by component
	
	foreach var in  nfyr nfmt nfwk food auto durables educ rent house water elect wages {
		dis "*******comparision of `var'***************"
		
		dis "---- levels `var'"
		sum `var' `var'_nisr, meanonly 
		compare `var' `var'_nisr
		
		dis "---- adult equivalent `var'"
		sum ad`var' ae_`var'_nisr
		compare ad`var' ae_`var'_nisr
	}
	
	
*Note Never saved 
*tempfile consag
*save `consag', replace

/*Daniel's note: This dataset does not reproduce stats on total cons in 2014 prices. 
Not sure what is the poverty line 
*/












/*===============================================================================================
	F. Poverty line 
	Note: Incomplete 
	By Looking at blog_EICV_original.do from lines 1401-1430 we have that prcadtot is used for most of the poverty definitions 
 ==============================================================================================*/

********POVERTY LINE**********
preserve // Daniel: "This presever was never closed

keep QUART hhid weight  prcadtot adfood adauto adtrfin adwages adtot adeqtot member autonf s0q18m // 

*---> Obtain food share of decile 5
*share of non-food
xtile decile = prcadtot [aw=weight*member], n(10) //

egen foodtot  =  rowtotal(adfood adauto adtrfin adwages) 
*replace foodtot= foodtot - (autonf / adtot)
gen  foodshr  =  foodtot /adtot

sum foodshr [iw=weight*member] if decile == 5 //
local foodshr = r(mean)

*---> Obtain quantities of each household for each goods
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
