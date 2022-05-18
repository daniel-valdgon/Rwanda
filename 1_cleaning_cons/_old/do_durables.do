


use "$data\cs_S10B2_Durable_household_goods.dta" , clear 

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