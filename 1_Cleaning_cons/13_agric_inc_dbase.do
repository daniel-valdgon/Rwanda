/*============================================================================================
 ======================================================================================
 ======================================================================================

Project:   Subsidies Rwanda
Author:    EPL (DV & MM) PE (JCP)
Creation Date:  June 8 2022
Objective: Clean and merge all datasets 
	

----------------------------------------------------
Notes: 

 ============================================================================================
 ============================================================================================
 ============================================================================================*/

/*=====================================================================================
	A. Small crops 
=======================================================================================*/

use "$proj/Survey_data/cs_S7E_small_crop.dta", clear

/*
// Note: there are duplicates
duplicates tag hhid  s7eq2, gen (d) , this should not happen 
*/

*Annualized quantity consume last 7 days
gen q_cons_7e=s7eq10a*365 if s7eq10b==1
replace q_cons_7e=s7eq10a*365/7  if q_cons_7e==. // the rest are weekly and assume missing values of s7eq10b are weekly

*Value and quantity sold last 12 months
gen q_sold_7e=s7eq6a
gen v_sold_7e=s7eq7

collapse (sum) v_sold_7e q_sold_7e q_cons_7e  , by(hhid s7eq2) //* 

/*---------------------------------
	Long dataset and labels 
*---------------------------------*/

preserve 
	*list of products 
	decode s7eq2, gen(label)
	replace label=subinstr(label, "_", "", .)
	replace label=subinstr(label, "  ", " ", .)
	replace label=ltrim(itrim(label))
	
	*long dataset 
	gen survey="7e"
	drop if  v_sold_7e==0 & q_sold_7e==0 & q_cons_7e==0 
	tempfile small_crop 
	save `small_crop', // save "$proj/outputs/intermediate/dta/cs_S7E_small_crop_long.dta", replace 
	
	*labels dataset 
	collapse (first) label, by(s7eq2)
	ren s7eq2 code
	tempfile labels_dbase
	save `labels_dbase', replace 
	
	*labels 
	local formulario "7e"
	include "$pdo/1_Cleaning_cons/13_a_write_labels.do"
	
restore


/*---------------------------------
	wide dataset 
*---------------------------------*/

reshape wide v_sold_7e q_sold_7e q_cons_7e , i(hhid) j(s7eq2) // 

egen t_v_sold=rowtotal(v_sold_7e*)
egen t_q_sold=rowtotal(q_sold_7e*)
egen t_q_cons=rowtotal(q_cons_7e*)

include "$pdo/1_Cleaning_cons/13_b_labels_small.do"
	
drop if t_v_sold==0 & t_q_sold==0 & t_q_cons==0

save "$proj/outputs/intermediate/dta/cs_S7E_small_crop_wide.dta", replace 
	

/*=====================================================================================
	B. Large crops 
=======================================================================================*/

use "$proj/Survey_data/cs_S7D_large_crop.dta", clear

*Value and quantity sold last 12 months
gen q_sold_7d=s7dq5
gen v_sold_7d=s7dq6*q_sold_7d

collapse (sum) q_sold_7d v_sold_7d   , by(hhid crop) //* 


/*---------------------------------
	Long dataset and labels 
*---------------------------------*/
		
preserve 
	
	*list of products 
	decode crop, gen(label)
	replace label=subinstr(label, "_", "", .)
	replace label=subinstr(label, "  ", " ", .)
	replace label=ltrim(itrim(label))
	
	
	*long dataset 
	gen survey="7d"
	drop if q_sold_7d==0 & v_sold_7d==0
	tempfile large_crop 
	save `large_crop', // save "$proj/outputs/intermediate/dta/cs_S7D_large_crop_long.dta", replace 
	
	*labels dataset 
	collapse (first) label, by(crop)
	ren crop code
	tempfile labels_dbase
	save `labels_dbase', replace 
	
	*labels 
	local formulario "7d"
	include "$pdo/1_Cleaning_cons/13_a_write_labels.do"
	
restore

/*---------------------------------
	wide dataset 
*---------------------------------*/


reshape wide q_sold_7d v_sold_7d , i(hhid) j(crop) // 

egen t_v_sold=rowtotal(v_sold_7d*)
egen t_q_sold=rowtotal(q_sold_7d*)
include "$pdo/1_Cleaning_cons/13_c_labels_large.do"
drop if t_v_sold==0 & t_q_sold==0 

save "$proj/outputs/intermediate/dta/cs_S7D_large_crop_wide.dta", replace 

/*=====================================================================================
	C. Cost of ag activities 
=======================================================================================*/

use "$proj/Survey_data/cs_S7G_expenditure_agriculture.dta", clear

*Value and quantity sold last 12 months
gen v_spent_7g=s7gq2

preserve 
	*list of products 
	decode s7gqcode, gen(label)
	replace label=subinstr(label, "_", "", .)
	replace label=subinstr(label, "  ", " ", .)
	replace label=ltrim(itrim(label))

	collapse (first) label, by(s7gqcode)
	ren s7gqcode code
	tempfile labels_dbase
	save `labels_dbase', replace 
	
	*labels 
	local formulario "7g"
	include "$pdo/1_Cleaning_cons/13_a_write_labels.do"
	
restore

drop s7gq1 s7gq2
reshape wide v_spent_7g  , i(hhid) j(s7gqcode) // 

egen t_v_spent=rowtotal(v_spent_7g*)

include "$pdo/1_Cleaning_cons/13_d_labels_inputs.do"
	
drop if t_v_spent==0 
keep t_v_spent v_spent_7g* hhid 
save "$proj/outputs/intermediate/dta/cs_S7G_expenditure_agriculture_wide.dta", replace 



/*=====================================================================================
	D. Other income from fishing, wood and other primary sector activities
=======================================================================================*/

use "$proj/Survey_data/cs_S7F_income_agriculture.dta", clear

*Value and quantity sold last 12 months
gen v_spent_7f=s7fq3

preserve 
	*list of products 
	decode s7fqcode, gen(label)
	replace label=subinstr(label, "_", "", .)
	replace label=subinstr(label, "  ", " ", .)
	replace label=ltrim(itrim(label))

	collapse (first) label, by(s7fqcode)
	ren s7fqcode code
	tempfile labels_dbase
	save `labels_dbase', replace 
	
	*labels 
	local formulario "7f"
	include "$pdo/1_Cleaning_cons/13_a_write_labels.do"
	
restore

keep v_spent_7f  hhid s7fqcode
reshape wide v_spent_7f  , i(hhid) j(s7fqcode) // 

egen t_v_sold_7f=rowtotal(v_spent_7f*)

include "$pdo/1_Cleaning_cons/13_e_labels_other_non_food.do"
	
drop if t_v_sold_7f==0 
keep t_v_sold_7f v_spent_7f* hhid 
save "$proj/outputs/intermediate/dta/cs_S7F_income_agriculture_wide.dta", replace 



/*=====================================================================================
	E. Merge all datasets to compare production with own consumption 
=======================================================================================*/

use 