/*============================================================================================
 ======================================================================================
 ======================================================================================

Project:   Subsidies Rwanda
Author:    EPL (DV & MM) PE (JCP)
Creation Date:  May 25 2021
Objective: compute poverty stats
----------------------------------------------------
	
 ============================================================================================
 ============================================================================================
 ============================================================================================*/

*Parameters 
local namexls "welf_measures"

*Tempfiles
tempfile tf_postfile1 
tempname tn1
postfile `tn1' str50(sample type effect ind_l1 ind_l2 value) using `tf_postfile1', replace


foreach sample in    all urban rural has_vehicle has_not {
	
	if "`sample'"=="all" local cond=""
	if "`sample'"=="urban" local cond="if ur==1"
	if "`sample'"=="rural" local cond="if ur==2"
	if "`sample'"=="has_vehicle" local cond="if has_vehicle==1"
	if "`sample'"=="has_not" local cond="if has_vehicle==0"
	
	use "$ppd/dta_for_stats.dta" `cond', clear 
	
	/*---------------------------------
	National characteristics 
	*---------------------------------*/
	// Inputs for incidence analysis 
	quantiles cons_ae_rwf14_benchmark_10, gen (q) n(10) // same if you use welfare_benchmark_t20 the index is just to faciliate the loop of calculations 
	
	
	foreach t in benchmark dir ind_commodity total {
	
		foreach effect in 10 20 {
		
		*Poverty rates 
		
		sum pov_`t'_`effect' [aw=pop_wt]
		local rate=`r(mean)'*100
		post `tn1' ("`sample'") ("`t'") ("`effect'") ("Poverty") ("NA") ("`rate'") 
				
		*Gini
		ainequal lcons_ae_rwf14_`t'_`effect'  [aw=pop_wt]
		local gini=`r(gini_1)'*100
		post `tn1' ("`sample'") ("`t'") ("`effect'") ("Inequality") ("NA") ("`gini'")  
		
		*Mean income 
		sum lcons_ae_rwf14_`t'_`effect' [aw=pop_wt] 
		post `tn1' ("`sample'") ("`t'") ("`effect'") ("Mean income by quantile") ("mean") ("`r(mean)'") 
		
		foreach quantile of numlist 1/10 {
			
			* Per-capita income 
			sum lcons_ae_rwf14_`t'_`effect' [aw=pop_wt] if q==`quantile'
			post `tn1' ("`sample'") ("`t'") ("`effect'") ("Mean income by quantile") ("`quantile'") ("`r(mean)'") 
		}
		
		}
	}
}

postclose `tn1' 
use `tf_postfile1', clear 
destring *, replace

* Computing changes with respect baseline
gen bench=value if type=="benchmark"
bysort sample effect ind_l1 ind_l2: egen b_value=mean(bench)
// for testing pourpose bysort sample effect ind_l1 ind_l2: egen sd_value=max(bench)

*gen absolute 
gen abs_value=value-b_value
gen rel_value=100*((value-b_value)/b_value)


export excel "${ppf}/`namexls'.xlsx", sheetreplace firstrow(variables) sheet("stats_database") 

