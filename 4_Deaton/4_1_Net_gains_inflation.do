

/*===============================================================================================
	Combined consumption and production data
 ==============================================================================================*/

*Consumption Data
use "$output/dta/cons_hhid_coicop.dta" , clear 
keep hhid coicop cons1_nisr cons_ae_rwf14
*Production data
merge 1:1 hhid coicop using "$output/dta/prod_hhid_coicop.dta"	
drop _merge


/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       663,975
        from master                   645,878  (_merge==1)
        from using                     18,097  (_merge==2)

    matched                            27,270  (_merge==3)

*/


*Price vector

	preserve 
	import excel using "$pdta/Matching COICOP-SAM_June9.xlsx", clear sheet(coicop_sector) first
		drop H-N
		keep   COICOP ITEM Price_increase Weights
		rename *, lower
		
		collapse (mean) price_increase [aw=weights], by(coicop)
		
		tempfile delta_prices
		save `delta_prices', replace 
	restore 

	
	merge m:1 coicop using `delta_prices'
	drop if _merge==2
	


* Total expenditure 

bysort hhid : egen tot_exp=total(cons1_nisr)

*Shares
	gen prod_sh=value_sold/tot_exp 
	gen cons_share=cons1_nisr/tot_exp 

*Formula

gen delta_welfare=(cons_share*price_increase) - (prod_sh)*(1-small_prod)*$passtrough}*price_increase



