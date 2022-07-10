/*============================================================================================
 ======================================================================================
 
Project:   Subsidies Rwanda
Author:    EPL (DV & MM) PE (JCP)
Creation Date:  May 2 2021
Objective: add the I-O sector & commodity to the microdata
	
----------------------------------------------------
	
 
============================================================================================
============================================================================================*/


/*===============================================================================================
					Paramteter setting 
 ==============================================================================================*/

set more off
clear all
set mem 900m

local io "commodity" // select "sector" or "commodity"

/*===============================================================================================
					Paramteter setting 
 ==============================================================================================*/

if "`io'"=="sector" {

	*Cleaning coicop-sector correspondence
	
	//correspondence 
	import excel using "$proj/inputs/Matching COICOP-SAM_May23.xlsx", clear sheet("sector_list") firstrow
	ren description sam_description
	tempfile prev_tmp
	save `prev_tmp'
	
	//description
	import excel using "$proj/inputs/Matching COICOP-SAM_May23.xlsx", clear sheet("coicop_sector")  firstrow
	ren _all , lower 
	keep item coicop sam_sector
 
	
	foreach v in item coicop sam_sector {
		replace `v'=ltrim(itrim(trim(`v')))
	}
	
	merge m:1 sam using `prev_tmp'
	drop if _merge==2
	drop _merge
	
	// A coicop can be mapped to more than one I-O sector. In that case we need to add another digit to the coicop and redistribute spending in the proportion of total output. We will do that later given the time constraints. In the meantime we eliminate duplicates. See the list of the sectors for which we ignore this problem at the bottom of the do-file 
	/* duplicates tag coicop, gen (t) br if t!=0  */
	
	duplicates drop coicop, force 
	
	tempfile coicop_sam
	save `coicop_sam', replace 
}
else if "`io'"=="commodity"  {


	*Cleaning coicop-sector correspondence
	
	//correspondence 
	import excel using "$proj/inputs/Matching COICOP-SAM_May23.xlsx", clear sheet("commodity_list") firstrow
	ren description sam_description
	tempfile prev_tmp
	save `prev_tmp'
	
	//description
	import excel using "$proj/inputs/Matching COICOP-SAM_May23.xlsx", clear sheet("coicop_sector")  firstrow
	ren _all , lower 
	keep item coicop sam_commodity
 
	
	foreach v in item coicop sam_commodity  {
		replace `v'=ltrim(itrim(trim(`v')))
	}
	
	merge m:1 sam_commodity using `prev_tmp'
	
	
	drop if _merge==2
	drop _merge
	
	
	// A coicop can be mapped to more than one I-O sector. In that case we need to add another digit to the coicop and redistribute spending in the proportion of total output. We will do that later given the time constraints. In the meantime we eliminate duplicates. See the list of the sectors for which we ignore this problem at the bottom of the do-file 
	/* duplicates tag coicop, gen (t) br if t!=0  */
	
	duplicates drop coicop, force 
	
	tempfile coicop_sam
	save `coicop_sam', replace 

}


dis "creating a hhid `io' level dataset "

use "$output/dta/cons_hhid_coicop.dta" , clear 
merge m:1 coicop using `coicop_sam'
drop if _merge==2
drop _merge

collapse (sum) cons cons_ae cons_ae_rwf14  (first) pline_mod pline_ext cons1_nisr idx adeqtot spend_cat  , by(hhid sam_`io')


	
	label var cons1_nisr		"Oficial household consumpt"
	label var spend_cat			"Consumption category"
	label var cons				"Consumption"
	label var cons_ae       	"Consumption per ae"
	label var cons_ae_rwf14  	"Consumption per ae, 2014 Rwf"
	label var idx  				"Spatial-time deflator"
	label var adeqtot  			"Adult equivalent"

merge m:1 hhid using "$data/EICV5_Poverty_file.dta", keepusing (province district hhid clust ur region weight pop_wt epov_jan pov_jan quintile decile) nogen
	
	
save "$podta/cons_hhid_sam.dta" , replace  

exit 

/*Note : Below coicops with more than one sector. Some of them already fixed
coicop	sam
01.1.1.6.07	ammll
01.1.1.6.07	asmll

coicop	sam
01.1.1.6.08	awmll
01.1.1.6.08	asmll

coicop	sam
01.1.1.6.09	asmll
01.1.1.6.09	awmll

coicop	sam
01.1.1.6.10	afood
01.1.1.6.10	ammll

coicop	sam
01.1.6.2.02	abana
01.1.6.2.02	agnut

coicop	sam
01.1.6.7.04	afrui
01.1.6.7.04	cfrui

coicop	sam
01.1.9.4.03	afood
01.1.9.4.03	aocrp

*/



