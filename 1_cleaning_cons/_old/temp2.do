


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
	drop if sh_item==0
	
	*spending 
	merge m:1 hhid using "$podta/WB_welfare_comp.dta", keepusing (nfyr_nisr)
	
	*spending by coicop
	gen spending=nfyr_nisr*sh_item
	
	*database 
	keep hhid coicop spending	
	label variable spending "spending by coicop"
	tempfile nfyr
	save `nfyr'
