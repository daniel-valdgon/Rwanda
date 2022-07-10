/*============================================================================================
 ======================================================================================
 ======================================================================================

Project:   Subsidies Rwanda
Author:    EPL (DV & MM) PE (JCP)
Creation Date:  June 8 2022
Objective: Clean and merge all datasets 
	

----------------------------------------------------
Notes: Depending on the module the prduction code means something different, we change the production code to avoid that. You will find duplicates of ccode and module that need to be checked at the end of the dofile:  duplicates drop code module, force  duplicates report code  duplicates tag code, gen(e) br if e!=0

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
	ren s7eq2 code
	decode code, gen(label)
	replace label=subinstr(label, "_", "", .)
	replace label=subinstr(label, "  ", " ", .)
	replace label=ltrim(itrim(label))
	
	*long dataset 
	gen module="7e"
	drop if  (v_sold_7e==0 & q_sold_7e==0 & q_cons_7e==0 ) |  (v_sold_7e==. & q_sold_7e==. & q_cons_7e==. )
	keep v_sold_7e q_sold_7e q_cons_7e code label module hhid
	tempfile small_crop 
	save `small_crop', // save "$proj/outputs/intermediate/dta/cs_S7E_small_crop_long.dta", replace 
	
	*Write label 
	collapse (first) label, by(code)
		
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
	ren crop code
	decode code, gen(label)
	replace label=subinstr(label, "_", "", .)
	replace label=subinstr(label, "  ", " ", .)
	replace label=ltrim(itrim(label))
		
	*long dataset 
	gen module="7d"
	drop if (q_sold_7d==0 & v_sold_7d==0) | (q_sold_7d==. & v_sold_7d==.)
	keep q_sold_7d v_sold_7d  code label module hhid
	tempfile large_crop 
	save `large_crop', // save "$proj/outputs/intermediate/dta/cs_S7D_large_crop_long.dta", replace 
	
	*Write label 
	collapse (first) label, by(code)
	
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
	ren s7gqcode code
	decode code, gen(label)
	replace label=subinstr(label, "_", "", .)
	replace label=subinstr(label, "  ", " ", .)
	replace label=ltrim(itrim(label))

	*write labels 
	collapse (first) label, by(code)
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
gen v_sold_7f=s7fq3

preserve 
	*list of products 
	ren s7fqcode code
	decode code, gen(label)
	replace label=subinstr(label, "_", "", .)
	replace label=subinstr(label, "  ", " ", .)
	replace label=ltrim(itrim(label))
	replace code=100+code //*Change codes in order to not have overlap with code from module S7D
	
	*long dataset 
	gen module="7f"
	drop if  v_sold_7f==0 | v_sold_7f==.
	
	keep v_sold_7f  code label module hhid
	tempfile other_non_food 
	
	save `other_non_food', // save "$proj/outputs/intermediate/dta/cs_S7F_income_agriculture_long.dta", replace 
	
	* labels 
	collapse (first) label, by(code)
	
	*labels 
	local formulario "7f"
	include "$pdo/1_Cleaning_cons/13_a_write_labels.do"
	
restore

keep v_sold_7f  hhid s7fqcode
reshape wide v_sold_7f  , i(hhid) j(s7fqcode) // 

egen t_v_sold_7f=rowtotal(v_sold_7f*)

include "$pdo/1_Cleaning_cons/13_e_labels_other_non_food.do"
	
drop if t_v_sold_7f==0 
keep t_v_sold_7f v_sold_7f* hhid 
save "$proj/outputs/intermediate/dta/cs_S7F_income_agriculture_wide.dta", replace 

/*=====================================================================================
	E. Append production datasets and merge with coicop correspondence 
=======================================================================================*/

	use `small_crop', clear 
	gen small_prod=1 if v_sold_7e!=. & v_sold_7e!=0
	
	append using `large_crop'
	append using `other_non_food'
	
	replace small_prod=0 if small_prod==.
	
		//we use rototal below because every line should have a value for only one variable
		egen quant_sold=rowtotal(q_sold_7e q_sold_7d)
		drop q_sold_7e q_sold_7d
		
		egen value_sold=rowtotal(v_sold_7d v_sold_7e v_sold_7f )
		drop v_sold_7d v_sold_7e v_sold_7f 
		
		ren q_cons_7e quant_cons
		
		
		// Products merged to leave coicop correspondence as unique
		replace code=2 if code==13
		replace label="Maize" if label=="Fresh Maize"
		
		replace code=9 if code==37
		replace label="Bean" if label=="Fresh Beans"
		
		collapse (sum) quant_cons quant_sold value_sold (max) small_prod , by(hhid code label)
		
		//Pendent to check code	quant_cons	label:   Green Beans code 38 in questionnarie, may be Green pea
		
		preserve 
			import excel using "$pdta/Matching COICOP-SAM_June9.xlsx", clear sheet(coicop_sector) first
			drop H-N
			
			keep if production_code!=.
			keep production_code  COICOP ITEM
			rename COICOP ITEM, lower
			tempfile coicop_for_prod
			
			replace coicop="01.1.7.3.01" if coicop=="01.1.7.3.02" & production_code==9
			replace coicop="01.1.7.8.05" if coicop=="01.1.7.8.06" & production_code==18
			replace coicop="01.1.6.1.03" if coicop=="01.1.6.1.04" & production_code==29
			
			duplicates drop coicop production_code, force
			save `coicop_for_prod'
		
		restore 
	
	clonevar production_code=code
	merge m:1 production_code using `coicop_for_prod' 
	
	
	label var quant_sold "Quantities sold (kg), last 12 mts (mod 7d,7e & 7f)"
	label var value_sold "Value sold, last 12 mts (mod 7d,7e & 7f)"
	label var quant_cons "Quantities consumed (kg), last 12 mts (mod 7e)"
	label var code 	"Production codes"
	label var label "Production labels"
	*label var module "Questionnarie module"
	
	
	collapse (sum) quant_cons quant_sold value_sold (max) small_prod, by(hhid coicop)
	
	
	drop if coicop==""
	save "$output/dta/prod_hhid_coicop.dta" , replace 
