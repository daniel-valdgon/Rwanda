/*============================================================================================
 ======================================================================================
 
Project:   Subsidies Rwanda
Author:    EPL (DV & MM) PE (JCP)
Creation Date:  May 2 2021
Objective: Compute cost push for petroleoum reform and equivalent variation dataset 
----------------------------------------------------
	
 
============================================================================================
============================================================================================*/


*==================================================================================
*==============      Price vector at sam level 							===========
*==================================================================================

/*---------------------------------
*Price and  and consumption for weights
*---------------------------------*/

use "$po/dta/cons_hhid_coicop.dta" , clear 

collapse (sum) cons   [iw=weight], by(coicop)

*adding inflation 
merge 1:1 coicop using `delta_prices' 

/* coicop		item
01.1.1.2.14		Other flours of cereals,
04.3.1.1.02		Construction wood
05.1.1.1.02		Mattresses
05.2.0.2.01		Bed Pillows
05.2.0.3.01		Blanket
05.2.0.3.02		Bed Sheets
05.3.1.3.01		Local Energy saving Stove
06.1.1.1.02		Heart disease medicines
06.1.1.1.03		High/low blood pressure drugs
06.1.1.1.04		Asthma drugs
06.1.1.1.05		ARV drugs
06.1.3.1.01		Spectacles / eye lenses
06.1.3.1.02		Dentures
06.1.3.1.03		Hearing aids/prosthetic limbs/ disability aids
06.3.0.1.01		Hospitalization
06.3.0.3.01		Givingbirth
07.3.4.1.01		Motor boat transport
08.3.0.2.01		Rwandatel/MTN fixed line charges
09.4.2.6.01		Subscription to DSTV, Star times e.t.c
10.1.0.1.01		Nursery and daycare fees
12.3.2.1.01		Metal/Wooden Case
*/

replace cons=0 if _merge==2 // 21 coicop codes with no consumption at all 
drop _merge

/*---------------------------------
* Merging coicop to sam 
*---------------------------------*/

preserve
	import excel using "$proj/inputs/${xls_nm_pmts}.xlsx", clear sheet("coicop_sector")  firstrow
	ren _all , lower
	
	keep coicop sam_${io}
	
	tempfile sam_codes
	save `sam_codes', replace 
	
restore

merge 1:1 coicop using `sam_codes'

/*---------------------------------
* Inflation at sam level 
*---------------------------------*/

egen aux_w=total(cons)
gen w=cons/aux_w

collapse (mean) price_increase [aw=w] , by( sam_${io} )

replace price_increase=price_increase-1

clonevar $io=sam_${io}
tempfile sam_code_prices
save `sam_code_prices'



*==================================================================================
*==============       parameters for cost push 						===========
*==================================================================================

	/*---------------------------------
	Input-Output 
	*---------------------------------*/
	
	import excel "${proj}/inputs/${xls_nm_pmts}.xlsx", sheet("${io}") firstrow clear
	
	/*---------------------------------
	Prices = dp 
	*---------------------------------*/
	
	merge 1:1 ${io} using `sam_code_prices' 
	
	replace sam_${io}=$io if sam_${io}=="" // sam coes that have no coicop mapping 
	ren price_increase dp
	
	replace dp=0 if _merge==1 // =0 because here we use growth format for changes in prices. Merge ==1 are commodities not mapped to any coicop therefore do not have inflation data. In the future the price should exist for sam sectors with not direct coicop associated  
	
	/*---------------------------------
	Fixed sectors 
	*---------------------------------*/
	
	*Fixed sectors? sectors regulated by government + import sectors 
	gen fixed = 0	
	*	replace fixed = 1 if commodity == "cpetr"
	
	/*---------------------------------
	Running cost push with total effect and indirect effect 
	*---------------------------------*/
	
	costpush ${io}_*, fixed(fixed) price(dp) genptot(total_eff_$io) genpind(ind_eff_$io) fix
	
	tempfile ind_dp
	save `ind_dp'


	/*---------------------------------
	COICOP dataset with price vectors: direct and indirect 
	*---------------------------------*/
	
	//coicop level codes 
	use `sam_codes' , clear 
	
	// add sam level indirect effects 
	merge m:1 sam_${io} using `ind_dp', nogen assert(match using) keep(match) keepusing (total_eff_$io ind_eff_$io dp) // using are sam sector withouth coicop mapping. All their influence on welfare is trough indirect effects 
	
	// add coicop level direct effects 
	merge 1:1 coicop using `delta_prices', nogen assert(match) keep(match) keepusing (price_increase) // using are sam sector withouth coicop mapping. All their influence on welfare is trough indirect effects 
	clonevar dir_eff=price_increase
	replace dir_eff=dir_eff-1 // all price changes in growth rate format 
	drop price_increase

	keep coicop sam_${io} ind_eff_${io}  dir_eff // notice total effect is not equal to direct + indirect because are computed at different scales 
	
	tempfile vector_prices
	save `vector_prices'

*==================================================================================
*==============  HH with price data  						===========
*==================================================================================
use "$po/dta/cons_hhid_coicop.dta", clear

global welfare cons_ae_rwf14 
keep ${welfare} hhid coicop

*add sam codes to household data
merge m:1 coicop using `vector_prices', nogen assert(match using) keep(match)


*Direct effects 
gen ${welfare}_dir = ${welfare} * dir_eff

*Indirect effects 
gen ${welfare}_ind = ${welfare} * ind_eff_${io}


*creating variable for looping reasons
egen ${welfare}_tot=rowtotal(${welfare}_dir ${welfare}_ind)

egen dp_tot= rowtotal(dir_eff ind_eff_${io})
label var dp_tot "Change in prices using ${io} level sam"

ren dir_eff 		dp_dir_eff
ren ind_eff_${io} 	dp_ind_eff

ren cons_ae_rwf14 cons_ae_rwf14_benchmark

save "${proj}\outputs\final\dta\cons_hhid_simulated.dta", replace



