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

use "$proj/Survey_data/cs_S10B2_Durable_household_goods.dta" , clear 

	keep if s10b2q1==26 | s10b2q1==27
	gen has_vehicle=s10b2q2>0 & s10b2q2!=.
	keep hhid has_vehicle
	collapse (max) has_vehicle, by(hhid)
	
	tempfile has_vehicle

save `has_vehicle', replace 


*Line, weights and uban and rural 
use "$podta/cons_hhid_sam.dta" , clear 

duplicates drop hhid, force // this is a sam-hhid level dataset so the variable of interest are the same for each household

keep hhid pline* pop_wt ur
tempfile other_var
save `other_var', replace 


* Merge household characteristics with welfare dataset 

use "${proj}\outputs\intermediate\dta\cons_hhid_simulated.dta", replace  

merge 1:1 hhid using `has_vehicle', nogen 
merge 1:1 hhid using `other_var', nogen 

/*---------------------------------
  Poverty measurement 
*---------------------------------*/

*create welfare variables and delete them 

*gen poverty dummies
foreach t in benchmark dir ind_commodity total {
	foreach effect in 10 20 {
		
		if "`t'"!="benchmark" {
			gen lcons_ae_rwf14_`t'_`effect'=cons_ae_rwf14_benchmark_`effect'-cons_ae_rwf14_`t'_`effect'
			
			local text_label=substr("`v'",15,3)
			label var lcons_ae_rwf14_`t'_`effect' "level of welfare, `text_label' effect - tax exc of `effect'"
		}
		else {
			gen lcons_ae_rwf14_benchmark_`effect'=cons_ae_rwf14_benchmark_`effect'
		}
		
		gen pov_`t'_`effect'=lcons_ae_rwf14_`t'_`effect'< pline_mod
		
		local text_label=substr("`v'",15,3)
		label var pov_`t'_`effect' "poverty status, `text_label' effect - tax exc of `effect'"
	}
}


tempfile data_stats
save `data_stats'
save "$ppd/dta_for_stats.dta", replace 


* Next do-file computes statistics 