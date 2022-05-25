/*============================================================================================
 ======================================================================================
 ======================================================================================

Project:   Subsidies Rwanda
Author:    EPL (DV & MM) PE (JCP)
Creation Date:  May 25 2021
Objective: add the I-O sector & commodity to the microdata
----------------------------------------------------
	
 ============================================================================================
 ============================================================================================
 ============================================================================================*/


/*---------------------------------
  Household characteristics 
*---------------------------------*/
	
*Has motorcycle or automobile 

use "$data\cs_S10B2_Durable_household_goods.dta" , clear 

	keep if s10b2q1==26 | s10b2q1==27
	gen has_vehicle=s10b2q2>0 & s10b2q2!=.
	keep hhid has_vehicle
	collapse (max) has_vehicle, by(hhid)
	
	tempfile has_vehicle

save `has_vehicle', replace 



/*---------------------------------
  Poverty measurement 
*---------------------------------*/

* Collapsing houshoeld welfare 
use "$podta/cons_hhid_sam.dta" , replace  

*TO be replaced when misha share the dataset and do-files 
	*Ideally we will merge a price vector with the policy changes produced by the costpush.ado Here I mimick as policy chnage an 10% increase in price of  cheal, cmaiz, cchem
	
	gen price_changes =1.1 if  sam_commodity=="cheal" | sam_commodity=="cmaiz" | sam_commodity=="cchem" 
	replace price_change=1 if price_change==.
	
	*Apply the price change to the welfare
	
	gen welf_benchmark_t10	= cons_ae_rwf14
	gen welf_direct_t10	= cons_ae_rwf14/price_changes 
	gen welf_indirect_t10= cons_ae_rwf14/price_changes*price_changes
	gen welf_total_t10	= cons_ae_rwf14/price_changes*price_changes

	gen welf_benchmark_t20 = cons_ae_rwf14
	gen welf_direct_t20	= -100 + cons_ae_rwf14/price_changes 
	gen welf_indirect_t20= -100 + cons_ae_rwf14/price_changes*price_changes
	gen welf_total_t20	= -100 + cons_ae_rwf14/price_changes*price_changes

*Prepare data to compute poverty 

collapse (sum) welf_*  (first) pline_mod pline_ext pop_wt ur , by(hhid)

*gen poverty dummies
foreach t in benchmark direct indirect total {
	foreach effect in t10 t20 {
		gen pov_`t'_`effect'=welf_`t'_`effect'< pline_mod
	}
}


/*---------------------------------
  Final dataset 
*---------------------------------*/

* Merge household characteristics 

merge 1:1 hhid using `has_vehicle'

tempfile data_stats
save `data_stats'

* Next do-file computes statistics 