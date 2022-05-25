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


*Tempfiles
tempfile tf_postfile1 
tempname tn1
postfile `tn1' str50(sample type effect ind_l1 ind_l2 value) using `tf_postfile1', replace


foreach sample in all urban rural has_vehicle has_not {
	
	if "`sample'"=="all" local cond=""
	if "`sample'"=="urban" local cond="if ur==1"
	if "`sample'"=="rural" local cond="if ur==2"
	if "`sample'"=="has_vehicle" local cond="if has_vehicle==1"
	if "`sample'"=="has_not" local cond="if has_vehicle==2"
	
	
	use `data_stats' `cond', clear 
	
	/*---------------------------------
	National characteristics 
	*---------------------------------*/
	// Inputs for incidence analysis 
	quantiles welf_benchmark_t10, gen (q) n(10) // same if you use welfare_benchmark_t20 the index is just to faciliate the loop of calculations 
}



dsadada	
	foreach t in benchmark direct indirect total {
	
		foreach effect in t10 t20 {
		
		*Poverty rates 
		
		sum pov_`t'_`effect' [aw=pop_wt]
		local rate=`r(mean)'*100
		post `tn1' ("`sample'") ("`t'") ("`effect'") ("Poverty") ("NA") ("`rate'") 
				
		*Gini
		ainequal welf_`t'_`effect'  [w=pop_wt]
		local gini=`r(gini_1)'*100
		post `tn1' ("`sample'") ("`t'") ("`effect'") ("Inequality") ("NA") ("`gini'")  
		
	
		foreach quantile of numlist 1/10 {
			
			* Per-capita income 
			sum welf_`t'_`effect' [aw=pop_wt] if q==`quantile'
			post `tn1' ("`sample'") ("`t'") ("`effect'") ("Mean income by quantile") ("`quantile'") ("`r(mean)'") 
		}
		
		}
	}
}



postclose `tn1' 
use `tf_postfile1', clear 
*destring year rate obs, replace

* Computing differences 