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
global data "$pdta/Survey_data"

*RESULTS STORAGE
cd "$data/results"
global output "$po"


*Log outputs
cap log close
log using "$output/log/EICV5.log", replace


/*===============================================================================================
	A. NON-FOOD COICOP LEVEL 
 ==============================================================================================*/
qui {
/*---------------------------------
 YEARLY NON-FOOD (exp 12)
*---------------------------------*/

	use "$data\cs_S8A1_expenditure.dta" , clear
	
	gen ynonfood = s8a1q3 if s8a1q1~=21 & s8a1q1~=29 & s8a1q1~=30 & s8a1q1~=31 & s8a1q1~=36 & s8a1q1~=37 & s8a1q1~=38 ///
	& s8a1q1~=44 & s8a1q1~=56 & s8a1q1~=60 & s8a1q1~=62 & s8a1q1~=63 & s8a1q1~=64 & s8a1q1~=65 & s8a1q1~=66 & s8a1q1~=68 // 138 cases (ynonfood>official) look like adjustment for outliers
	
	*coicop
	decode s8a1q1, gen(coicop)
	
	*aggregate
	collapse (sum) nfyr=ynonfood, by(hhid coicop)
	ren nfyr spend_item
	
	*share
	bysort hhid: egen  t_spend=total(spend_item)
	gen sh_item=spend_item/t_spend
	drop if sh_item==0 |  sh_item==.
	
	*spending 
	merge m:1 hhid using "$podta/WB_welfare_comp.dta", keepusing (nfyr_nisr)
	
	*spending by coicop
	gen spending=nfyr_nisr*sh_item
	gen spend_cat="non-food yrly"
	
	*database 
	keep hhid coicop spending spend_cat	
		
	label variable spending "spending by coicop"
	tempfile nfyr
	save `nfyr'


/*---------------------------------
 MONTHLY NON-FOOD (exp13)
*---------------------------------*/

	use "$data\cs_S8A2_expenditure.dta" , clear

	gen mnonfood = s8a2q3 if s8a2q1 ~= 43 & s8a2q1 ~= 44 & s8a2q1 ~= 45 & s8a2q1 ~= 46 // remaining 218 differences (mnonfood>official) seem to be adjusted for outliers
	
	*coicop
	decode s8a2q1, gen(coicop)
	
	*aggregate
	gen nfmt = 12 * mnonfood
	
	collapse (sum) nfmt, by(hhid coicop)
	ren nfmt spend_item
	
	*share
	bysort hhid: egen  t_spend=total(spend_item)
	gen sh_item=spend_item/t_spend
	drop if sh_item==0 | sh_item==.
	
	*spending 
	merge m:1 hhid using "$podta/WB_welfare_comp.dta", keepusing (nfmt_nisr)
	
	*spending by coicop
	gen spending=nfmt_nisr*sh_item
	gen spend_cat="non-food monthly"
	
	*database 
	keep hhid coicop spending spend_cat	
	label variable spending "spending by coicop"
	
	*saving
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
		
	*coicop
	ren s8a3q1 coicop

	collapse (sum)  nfwk, by(hhid coicop)
	ren nfwk spend_item
	
	*share
	bysort hhid: egen  t_spend=total(spend_item)
	gen sh_item=spend_item/t_spend
	drop if sh_item==0 | sh_item==.
	
	*spending 
	merge m:1 hhid using "$podta/WB_welfare_comp.dta", keepusing (nfwk_nisr)
	
	*spending by coicop
	gen spending=nfwk_nisr*sh_item
	gen spend_cat="non-food wk"
	
	*database 
	keep hhid coicop spending spend_cat	
		
	label variable spending "spending by coicop"
	
	*saving
	tempfile nfwk
	save `nfwk'

/*---------------------------------
 DURABLES 
Notes: We use the closest replication that we have 
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
		
		*Impute known agge parameters 
		replace medage=2 if s10b2q1==6  	/*has 4 year of depreciation mobile */
		replace medage=4.5 if s10b2q1==5  	/*has 9 year of depreciation radio */
		replace medage=4.5 if s10b2q1==7 	/*has 9 year of depreciation TV set */
		replace medage=4.5 if s10b2q1==13 	/*has 9 year of depreciation living room */
		replace medage=0.75 if s10b2q1==14 	/*has 1.5 yrs Bycycle */
		replace medage=4.5 if s10b2q1==15 	/*has 9 year of depreciation cupboard */
		replace medage=2 if s10b2q1==16 	/*has 4 year of depreciation Cooker */
		replace medage=2 if s10b2q1==19 	/*has 4 year of depreciation sewing machine */
		replace medage=2 if s10b2q1==20 	/*has 4 year of depreciation Refrigeration */
		replace medage=0 if s10b2q1==29 	/*has 0 value for water*/ 
		
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
	
	*Add COICOP structure 
	gen coicop=""
	replace coicop="09.1.1.0.00" if s10b2q1==5  // Radio _with or without CD player_
	replace coicop="08.2.0.3.02" if s10b2q1==6  // Mobile telephone
	replace coicop="09.1.1.0.00" if s10b2q1==7  // TV set
	replace coicop="09.1.1.0.00" if s10b2q1==8  // Satellite dish
	replace coicop="09.1.1.0.00" if s10b2q1==9  // Video / DVD  player
	replace coicop="09.1.1.0.00" if s10b2q1==10 // Decoder
	replace coicop="09.1.1.0.00" if s10b2q1==11 // Music system
	replace coicop="09.1.1.0.00" if s10b2q1==12 // Computer and accessories
	replace coicop="05.1.1.1.01" if s10b2q1==13 // Living room suite  _arm chairs, couch,  coffee tables_
	replace coicop="07.3.2.1.04" if s10b2q1==14 // Bicycle _For home use only_
	replace coicop="05.1.1.1.01" if s10b2q1==15 // Cupboard
	replace coicop="05.3.1.0.00" if s10b2q1==16 // Cooker
	replace coicop="05.3.1.0.00" if s10b2q1==17 // Laundry machine
	replace coicop="05.3.2.0.00" if s10b2q1==18 // Electric fan
	replace coicop="05.3.1.0.00" if s10b2q1==19 // Sewing machine
	replace coicop="05.3.1.0.00" if s10b2q1==20 // Refrigerator/Freezer
	replace coicop="05.5.2.2.02" if s10b2q1==21 // Electric generator
	replace coicop="05.3.2.0.00" if s10b2q1==22 // Electric hotplate _burner_
	replace coicop="05.5.2.2.02" if s10b2q1==23 // Power Stabiliser
	replace coicop="09.1.1.0.00" if s10b2q1==24 // Still Camera
	replace coicop="09.1.1.0.00" if s10b2q1==25 // Video camera
	replace coicop="07.3.2.1.04" if s10b2q1==26 // Motorcycle _For home use only_
	replace coicop="07.1.0.0.00" if s10b2q1==27 // Car _for home use only_
	replace coicop="09.1.1.0.00" if s10b2q1==28 // Printer
	replace coicop="05.6.1.5.03" if s10b2q1==29 // Water Filter
	
	
	collapse (sum) durables, by(hhid coicop)
	ren durables spend_item
	
	*share
	bysort hhid: egen  t_spend=total(spend_item)
	gen sh_item=spend_item/t_spend
	drop if sh_item==0 | sh_item==.
	
	*spending 
	merge m:1 hhid using "$podta/WB_welfare_comp.dta", keepusing (durables_nisr)
	drop if _merge==2 // all observations have zero durables spending aas it should be
	
	*spending by coicop
	gen spending=durables_nisr*sh_item
	gen spend_cat="durables"
	
	
	*saving
	keep hhid coicop spending spend_cat
	tempfile durables
	save `durables'


}

/*===============================================================================================
	B. FOOD COICOP LEVEL 
 ==============================================================================================*/
qui {
/*---------------------------------
  FOOD
*---------------------------------*/
	use "$data\cs_S8B_expenditure.dta" , clear

	egen spend = rowtotal( s8bq4 - s8bq13), m // from 2nd to last visit (11 visits asking fro consumption of 3 days in Kigaly or 7 visits asking for consumption of 2 days in the rest of provinces 
	
	*aggregate 
	*->from weekly to monthly
	replace spend = (365/12) * spend/30 if  province==1 // Kigali City, consumption over 30 days
	replace spend = (365/12) * spend/14 if  province>1 // All other provinces were interview during 14 days 

	*coicop
	ren s8bq1 coicop
	
	*-> from monthly to annual 
	gen food = spend * 12 
	
	
	collapse (sum)  food , by(hhid coicop)
	ren food spend_item
	
	*share
	bysort hhid: egen  t_spend=total(spend_item)
	gen sh_item=spend_item/t_spend
	drop if sh_item==0 | sh_item==.
	
	*spending 
	merge m:1 hhid using "$podta/WB_welfare_comp.dta", keepusing (food_nisr)
	
	*spending by coicop
	gen spending=food_nisr*sh_item
	gen spend_cat="food"
	
	*database 
	keep hhid coicop spending spend_cat	
	label variable spending "spending by coicop"
	
	*saving
	tempfile food
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
	
	*coicop
	ren s8cq1 coicop 
	
	
	collapse (sum)  auto_f, by(hhid coicop)
	ren auto_f spend_item
	
	*share
	bysort hhid: egen  t_spend=total(spend_item)
	gen sh_item=spend_item/t_spend
	drop if sh_item==0 | sh_item==.
	
	*spending 
	merge m:1 hhid using "$podta/WB_welfare_comp.dta", keepusing (auto_f_nisr)
	
	*spending by coicop
	gen spending=auto_f_nisr*sh_item
	gen spend_cat="auto"
	
	
	*database 
	keep hhid coicop spending spend_cat
		
	label variable spending "spending by coicop"
	
	*saving
	tempfile auto
	save `auto'
	
}

/*===============================================================================================
	C. NON-FOOD NO COICOP - LEVEL (One sngle item or coicop per dataset)
 ==============================================================================================*/
qui {
/*---------------------------------
  EDUCATION (EXP 1 )
*---------------------------------*/

	use "$data\cs_S1_S2_S3_S4_S6A_S6E_Person.dta" , clear
	
	*Education
	egen educ = rowtotal(s4aq11a-s4aq11h ), m // Not included: s4bq2 || to match NISR poverty file, 42 differences seem to be outliers
	
	gen coicop="10.1.0.0.00"
	
	*aggregate
	collapse (sum)  educ,  by(hhid coicop)
	
	*share
	gen sh_item=1
	
	*spending 
	merge m:1 hhid using "$podta/WB_welfare_comp.dta", keepusing (educ_nisr)
	
	*spending by coicop
	gen spending=educ_nisr*sh_item
	gen spend_cat="educ"
	
	
	*database 
	keep hhid coicop spending spend_cat
		
	label variable spending "spending by coicop"
	
	*saving
	tempfile educt
	save `educt'

/*---------------------------------
  RENT AND UTILITIES (EXP 4&5, EXP 7, EXP 8) have only one code!
*---------------------------------*/
	use "$podta/WB_welfare_comp.dta" , clear
	
	ren rent1_nisr ru_1
	ren rent2_nisr ru_2
	ren elect_nisr ru_3
	ren water_nisr ru_4
	
	*aggregate
	collapse (sum) ru_*, by(hhid)
	reshape long ru_, i(hhid) j(type)
	
	gen coicop=""
	replace coicop="04.1.1.0.00" if type==1
	replace coicop="04.2.1.0.00" if type==2
	replace coicop="04.4.1.0.00" if type==3
	replace coicop="04.5.1.0.01" if type==4
	
	*spending by coicop
	ren ru_ spending
	gen spend_cat="house"
	
	*database 
	keep hhid coicop spending spend_cat
		
	label variable spending "spending by coicop"
	
	tempfile house
	save `house'
	
/*---------------------------------
  MANTEINANCE (EXP 6)
*---------------------------------*/
	
	use "$data\cs_S8A1_expenditure.dta" , clear

	gen manteinance = s8a1q3 if s8a1q1==29 | s8a1q1==30
	
	*coicop
	decode s8a1q1, gen(coicop)
	
	*aggregate
	collapse (sum) manteinance, by(hhid coicop)
	ren manteinance spend_item
	
	*share
	bysort hhid: egen  t_spend=total(spend_item)
	gen sh_item=spend_item/t_spend
	drop if sh_item==0 | sh_item==.
	
	*spending 
	merge m:1 hhid using "$podta/WB_welfare_comp.dta", keepusing (manteinance_nisr)
	
	*spending by coicop
	gen spending=manteinance_nisr*sh_item
	gen spend_cat="manteinance"
	
	*database 
	keep hhid coicop spending spend_cat
	label variable spending "spending by coicop"
	tempfile manteinance
	save `manteinance'

}

/*===============================================================================================
	D. IN KIND TRANSFERS & WAGES 
 ==============================================================================================*/

*qui {
/*---------------------------------
* DEFINING FOOD & NON-FOOD CONSUMPTION STRUCTURE 
*---------------------------------*/
	
use "$podta/WB_welfare_comp.dta"	
keep hhid 
tempfile ids
save `ids' // to create a bundle for all households 
save "$podta/ids.dta", replace 

foreach structure in food and non_food {
	
	if "`structure'"=="food" {
		use `food', clear 
		append using `auto'
		
	}
	else {
		use `nfyr', clear 
		append using `nfmt'
		append using `nfwk'
		append using `durables'
		append using `educt'
		append using `manteinance'
		append using `house'
	}
	
	*----A. National spending structure
	preserve
		
		*Consumption shares
		collapse (sum) spend_item=spending, by(coicop)
		
		egen  t_spend=total(spend_item)
		gen sh_item=spend_item/t_spend //share of spending by coicop 
		drop if sh_item==0 | sh_item==.
		
		gen hhid=200001 // we make this a one household dataset to replicate national structure for all households below with the command fillin 
		
		keep sh_item coicop hhid
		
		merge m:1 hhid using `ids'
		drop _merge
		fillin hhid coicop
		bysort coicop: ereplace sh_item=mean(sh_item)
		drop if coicop==""
		
		*saving
		tempfile nat_`structure'
		save `nat_`structure''
		save "$podta/nat_`structure'.dta", replace 
	restore	
	
	*----B. Household spending structure 
		
		collapse (sum) spend_item=spending, by(hhid coicop)
		bysort hhid: egen t_spend=total(spend_item)
		gen sh_item=spend_item/t_spend
		drop if sh_item==0 | sh_item==.
		keep hhid sh_item coicop
		*saving
		tempfile hh_`structure'
		save `hh_`structure''
		save "$podta/hh_`structure'.dta", replace 
		
		
	*----C. Combining household and national consumption structure
	
	merge m:1 hhid using `ids', 
	preserve 
		*households withouth hhid structure
		keep if _merge==2
		drop _merge
		drop coicop sh_item 
		merge 1:m hhid using `nat_`structure'', update
		
		drop if _merge!=3
		tempfile hh_tmp
		save `hh_tmp', replace 
	restore
		
	drop if _merge==2
	append using `hh_tmp'

	*----D. Saving
	keep hhid sh_item coicop
	tempfile `structure'_cons_str
	save ``structure'_cons_str'
	save "$podta/`structure'_cons_str.dta", replace 
}
	



wsq	
/*---------------------------------
* WAGES IN KIND -- NOTE: DATASET AT THE PERSON JOB LEVEL  HHID PID EID
*---------------------------------*/
	
*--------------------
	*In kind food
	
	use "$podta/WB_welfare_comp.dta", clear 
	keep hhid ikfood_nisr
	ren ikfood_nisr hh_spend
	
	merge 1:m hhid using `hh_food'
	
	*replace national structure for households withouth infomration about spending on food
	preserve 
		keep if _merge==1
		drop _merge
		merge 1:m hhid using `nat_food'
		drop if _merge!=3
		drop _merge
		tempfile tmp
		save `tmp'
	restore
	
	*Delete household with no information on food
	drop if _merge==1
	append using `tmp'
	
	*spending by coicop
	bysort hhid: ereplace hh_spend=mean(hh_spend)
	*local or national spending
	gen spending=hh_spend*sh_item
	replace  spending=hh_spend*sh_item_plu if sh_item==. 
	
	*saving
	gen spend_cat="ikfood"
	keep hhid spend_cat  spending coicop
	tempfile ikfood
	save `ikfood'
	
	*---Test ------
	collapse (sum) spending , by(hhid)
	merge 1:1 hhid using "$podta/WB_welfare_comp.dta", keepusing (ikfood_nisr)
	compare spending *nisr
	*---Test ------
	
	
*--------------------
	*In kind housing
	use "$podta/WB_welfare_comp.dta" , clear
	
	ren ikhous_nisr spending
	gen coicop="04.2.1.0.00"
	collapse (sum) spending, by(hhid coicop)
	
	gen spend_cat="ikhous"
	
	drop if spending==. | spending==0
	
	*saving
	keep hhid spend_cat  spending coicop
	tempfile ikhous
	save `ikhous'
	
*-----------------
	*In kind other (non food weekly and monthly)
	
	use "$podta/WB_welfare_comp.dta", clear 
	keep hhid ikothr_nisr
	
	merge 1:m hhid using `nf_structure'
	
	preserve 
		keep if _merge==1
		drop _merge
		merge 1:m hhid using `plut_nfood_struc'
		drop if _merge!=3
		drop _merge
		tempfile add_hhid_aux
		save `add_hhid_aux'
	restore
	
	drop if _merge==1
	append using `add_hhid_aux'
	
	bysort hhid: egen tikothr_nisr=mean(ikothr_nisr)
	
	*spending by coicop
	gen spending=tikothr_nisr*sh_item
	replace  spending=tikothr_nisr*sh_item_plu if sh_item==. 
	
	*saving
	gen spend_cat="ikothr"
	
	keep hhid coicop spending spend_cat	
	label variable spending "spending by coicop"
	tempfile ikothr
	save `ikothr'
	
*---------------------------------
** IN-KIND TRANFERS (EXP18)
* Food + own / Non-food consumption 
*---------------------------------
	
	*------Food component of in-kind  transfers
	
	*From ik transfer to ikfood 
	use "$data\cs_S9B_transfers_in.dta" , clear
	
	replace s9bq10=. if s9bq10>=9999999
	replace s9bq12=. if s9bq12>=9999999
	
	egen trfin = rowtotal(s9bq10 s9bq12), m
	egen trfin_f = rowtotal(s9bq10), m
	collapse (sum)  trfin*, by(hhid)
	
	collapse (sum) trfin_f trfin, by (hhid)
	gen sh_food_transf=trfin_f/trfin
	replace sh_food=0 if trfin_f==. 
	drop if  sh_food==. | trfin==0
	
	keep hhid sh_food_transf
	tempfile aux_trfin_f
	*save `aux_trfin_f'
	save "$podta/aux_trfin_f.dta" , replace 
	
	*household level dataset 
	use "$podta/WB_welfare_comp.dta", clear 
	keep hhid trfin
	
	*merge 1:1 hhid using `aux_trfin_f'
	merge 1:1 hhid using "$podta/aux_trfin_f.dta"
	drop _merge
	
	
	gen trfin_f_nisr=trfin*sh_food_transf
	keep hhid trfin_f_nisr sh_food_transf
	
	*-----From food to coicop 
	
	*merge 1:m hhid using `f_structure'
	merge 1:m hhid using "$podta/f_structure.dta" 
	
	preserve 
		keep if _merge==1
		drop _merge
		*merge 1:m hhid using `plut_food_struc'
		merge 1:m hhid using "$podta/plut_food_struc.dta" 
		drop if _merge!=3
		drop _merge
		tempfile add_hhid_aux
		save `add_hhid_aux'
	restore
	
	gen w=1
	drop if _merge==1
	append using `add_hhid_aux'
	
	bysort hhid: egen ttrfin_f_nisr=mean(trfin_f_nisr)
	
	*Spending by coicop
	gen spending=ttrfin_f_nisr*sh_item
	replace  spending=ttrfin_f_nisr*sh_item_plu if sh_item==. 
	
	*saving
	gen spend_cat="trfin_food"
	keep hhid coicop spending spend_cat	 sh_food_transf w
	label variable spending "spending by coicop"
	tempfile trfin_food
	save `trfin_food'
	
	*Validation 
		
	*---Test ------
	collapse (sum) spending (mean) sh_food_transf w, by(hhid)
	merge 1:1 hhid using "$podta/WB_welfare_comp.dta", keepusing (trfin_nisr)
	gen food_tr=trfin_nisr*sh_food_transf
	compare spending food_tr if w==1
	*---Test ------
	
	
	
	*-----------------------------
	*Non food in kind transfers
	*-----------------------------
	
	*---> Create food transfers
	use "$data\cs_S9B_transfers_in.dta" , clear
	
	replace s9bq10=. if s9bq10>=9999999
	replace s9bq12=. if s9bq12>=9999999
	
	*aggregate
	egen trfin = rowtotal(s9bq10 s9bq12), m
	egen trfin_nf = rowtotal(s9bq12), m
	collapse (sum)  trfin*, by(hhid)
	
	gen sh_non_food=trfin_nf/trfin
	drop if  sh_non_food==.
	
	*spending 
	merge m:1 hhid using "$podta/WB_welfare_comp.dta", keepusing (trfin_nisr)
	drop if _merge==2 // All observations have zero durables spending aas it should be ...
	
	*spending by coicop
	gen spending=trfin_nisr*sh_non_food
	tempfile aux_trfin_nf
	save `aux_trfin_nf'
	
	*---> Add structure to transfers
	use `nf_structure', clear 
	
	merge m:1 hhid using `aux_trfin_f', keepusing (spending)
	drop if _merge==2 // all observations have zero durables spending aas it should be
	
	*spending by coicop
	replace spending=spending*sh_item
	gen spend_cat="trfin_nfood"
	
	*saving
	
	keep hhid coicop spending spend_cat	
	label variable spending "spending by coicop"
	
	tempfile trfin_nfood
	save `trfin_nfood'
	
	
	
	use `trfin_nfood'
	append using `trfin_nfood'
	
	
	
	
	*---Test ------
	collapse (sum) spending, by(hhid)
	merge 1:1 hhid using "$podta/WB_welfare_comp.dta", keepusing (trfin_nisr)
	compare spending *_nisr
	*---Test ------
	
	*educt house manteinance durables ikfood ikhous ikothr

}

	
/*===============================================================================================
	B. Building consumption aggregate
 ==============================================================================================*/
	
	
	*non-food
	use `nfyr', clear 
	
	append using `nfmt'
	append using `nfwk'
	append using `durables'
	
	
	
	
	
	append using `educt'
	append using `manteinance'
	append using `house'
	*food
	append using `food'
	append using `auto'
	
	*In-kind
	append using `ikhous'
	append using `ikfood'
	append using `ikothr'
	*Transfers
	append using `trfin_food'
	append using `trfin_nfood'
	
	*---Test ------
	collapse (sum) spending, by(hhid)
	merge 1:1 hhid using "$podta/WB_welfare_comp.dta", keepusing (cons1_nisr)
	compare spending cons1
	*---Test ------
	
	
	egen cons1=rowtotal(`spend_cat_list'), m
	gen cons_ae_wb=cons1/adeqtot
	gen cons_ae_rp_wb=cons_ae_wb/idx
	
	
	save "$output/dta/WB_welfare.dta" , replace 


exit 

