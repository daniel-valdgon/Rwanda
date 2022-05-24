/*============================================================================================
 ======================================================================================
 ======================================================================================

Project:   Subsidies Rwanda
Author:    EPL (DV & MM) PE (JCP)
Creation Date:  May 2 2021
Objective: add the I-O sector & commodity to the microdata
	
----------------------------------------------------
	
 ============================================================================================
 ============================================================================================
 ============================================================================================*/


use "$podta/cons_hhid_sam.dta" , replace  


*Ideally we will merge a price vector with the policy changes produced by the costpush.ado Here I mimick as policy chnage an 10% increase in price of  cheal, cmaiz, cchem

gen price_changes =1.1 if  sam_commodity=="cheal" | sam_commodity=="cmaiz" | sam_commodity=="cchem" 
replace price_change=1 if price_change==.

*Apply the price change to the welfare
gen new_cons_ae_rwf14= cons_ae_rwf14/price_changes 


*Prepare data to compute poverty 

collapse (sum) new_cons_ae_rwf14 cons_ae_rwf14 (first) pline_mod pline_ext pop_wt, by(hhid)

*Poverty dummies
gen new_poverty = new_cons_ae_rwf14< pline_mod
gen old_poverty = cons_ae_rwf14< pline_mod

*poverty rate before the change
sum old_poverty [aw= pop_wt]
sum new_poverty [aw= pop_wt]


