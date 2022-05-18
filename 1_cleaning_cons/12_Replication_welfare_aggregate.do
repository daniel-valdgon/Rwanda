/*============================================================================================
 ======================================================================================
 ======================================================================================

Project:   Subsidies Rwanda
Author:    EPL (DV & MM) PE (JCP)
Creation Date:  May 2 2021
Objective: This dofiles aims to replicate the welfare aggregate based on cons_aggregate.do 
	

----------------------------------------------------
Notes: 
	
	-Current status: we replicate spending for 80% of households. We have not replicate the use value of durables. Once this subcategory is replicated we will replicate spending for 94% of households. Therefore we are currently taking use of durables directly from official microdata
	- We do not replicate own food consumption for 6% of the households
	- We do not perfectly replicate the spending in other subcategories because we do not correct for outliers
	
	- We focus on 16 official welfare subcategories listed below:
	
	% of obs replicated: .995 	exp1		education expenses 
	% of obs replicated: 1    	exp4		Imputed rents 
	% of obs replicated: 1    	exp5		Actual rents 
	% of obs replicated: .999 	exp6		Maintenance costs 
	% of obs replicated: 1    	exp7		Water expenses 
	% of obs replicated: 1    	exp8		Electricity expenses 
	% of obs replicated: .969 	exp9		in-kind payments mainly food
	% of obs replicated: .998 	exp10		Employer subsidy of house 
	% of obs replicated: 1    	exp11		Other in-kind employer benefits 
	% of obs replicated: .994 	exp12		Annual non-food expenditures 
	% of obs replicated: .991 	exp13		monthly non-food expenditures 
	% of obs replicated: .999 	exp14_2		frequent non-food expenditures 
	% of obs replicated: .997 	exp15_2		food expenditures 
	
	% of obs replicated: .942 	exp16_2		own food consumption 
	% of obs replicated: NA	  	exp17		use value of durable goods 
	
	% of obs replicated: .999 	exp18		Received in-kind transfers
	
	TOTAl welfare aggregate: % of obs replicated .943 when using durables consumption from the official microdata.

 ============================================================================================
 ============================================================================================
 ============================================================================================*/

/*=====================================================================================
	C. Keep components of official Welfare aggregate 
=======================================================================================*/


**FIRST CHECKING WHICH ITEMS WERE INCLUDED IN NISR CONSUMPTION AGGREGATE, FOR COMPARABILITY***
use "$data\EICV5_Poverty_file", clear

/*---------------------------------
* Spending subcategories: Identifying spending categories from official microdata 
*---------------------------------*/


	**FIRST CHECKING WHICH ITEMS WERE INCLUDED IN NISR CONSUMPTION AGGREGATE, FOR COMPARABILITY***
	
	/*nisr==cons1, which implies that we known the subcomponents that nisr included in its consumption aggregate:
	variable	label
							
	exp1		education expenses
	exp4		Imputed rents
	exp5		Actual rents
	exp6		Maintenance costs
	exp7		Water expenses
	exp8		Electricity expenses
	exp9		in-kind payments mainly food?
	exp10		Employer subsidy of house
	exp11		Other in-kind employer benefits
	exp12		Annual non-food expenditures
	exp13		monthly non-food expenditures
	exp14_2		frequent non-food expenditures
	exp15_2		food expenditures
	exp16_2		own food consumption
	exp17		use value of durable goods
	exp18		Received in-kind transfers: value
	
	Note: these are the same variables that were included in the eicv4 and eicv3 consumption aggregate
	*/
	
	*Validation of the spending compnents that go into the official welfare agregate 
	
	*
	egen cons1_nisr = rowtotal( exp1 exp4 exp5 exp6 exp7 exp8 exp9 exp10 exp11 exp12 exp13 exp14_2 exp15_2 exp16_2 exp17 exp18)
	compare cons1_nisr cons1
	

/*---------------------------------
* Comparing spending subcomponents 
*---------------------------------*/

	*File hltedu
	rename exp1	educ_nisr	  // education expenses : educ
	
	*File with replication `house'
	rename exp4 rent1_nisr   // imputed rents
	rename exp5 rent2_nisr   // Actual rents : rent
	
	rename exp6 manteinance_nisr   //  Maintenance cost  
	rename exp7 water_nisr   //  Water  : water
	rename exp8 elect_nisr   //  Electricity : elect
	
	*File with replication `wages'
	rename exp9  ikfood_nisr   // In-Kind food wages
	rename exp10 ikhous_nisr  // In-Kind housing wages
	rename exp11 ikothr_nisr  // Other In-Kind 
	
	*File name as the variable 
	rename exp12 nfyr_nisr    // Yr non-food : nfyr
	rename exp13 nfmt_nisr    // Monthly non-food : nfmt
	rename exp14_2 nfwk_nisr  // Weekly non-food : nfwk
	rename exp15_2 food_nisr  // Food : food
	rename exp16_2 auto_f_nisr  // Only food Autoconsumption. Note non-food autoconsumption is excluded in the replication file `auto' the variable's name is autonf  : auto  autonf
	*--> note autonf should not be included in replication 
	rename exp17   durables_nisr // use value of Durables
	rename exp18   trfin_nisr   // In kind transfers
	
	*Adjusted percapita
	
	* foreach v in educ_nisr rent1_nisr rent2_nisr manteinance_nisr water_nisr elect_nisr ikfood_nisr ikhous_nisr ikothr_nisr nfyr_nisr nfmt_nisr nfwk_nisr food_nisr auto_f_nisr durables_nisr trfin_nisr {
		* gen ae_`v'=`v'/ae
	* } 
	
	keep hhid  *_nisr
	tempfile cons_agg_nisr

	merge 1:1 hhid	using "$podta/WB_welfare.dta", nogen
	
	save "$podta/WB_welfare_comp.dta", replace 

	
*-----------
*-- Comparing Raw variables 
*-----------
 	local spend_cat_list "educ rent1 rent2 manteinance water elect ikfood ikhous ikothr nfyr nfmt nfwk food auto_f durables trfin"
	foreach v in cons1 `spend_cat_list' {
	
		*Dummy tha tidentifies when perfect matching 
		gen t_`v'=`v'/`v'_nisr
		replace t_`v'=1 if `v'==0 & `v'_nisr==0 
		replace t_`v'=1 if `v'==. & `v'_nisr==.
		replace t_`v'=0 if `v'!=0 & `v'_nisr==0
		
		
		gen tt_`v'=1 if t_`v'>0.995 & t_`v'<1.005
		replace tt_`v'=0 if tt_`v'==.  
			
		drop t_`v'
		
		gen ae_`v'=`v'/adeqtot
		quantiles `v' [aw=pop_wt], gen (q_`v') n(100)
		
		gen qq_`v'=1 		if tt_`v'==0 & q_`v'>=95
		replace qq_`v'=0	if tt_`v'==0 & q_`v'<95
		
		* preserve 
		
			* keep hhid `v'_nisr if tt_`v'==0 
			* save "$podta/outliers_`v'.dta"
		
		* restore 
		
	}

collapse (mean) tt_* qq* [aw=pop_wt]
gen i=1
reshape long tt_ qq_, i(i) j(spend_cat) string

drop i
ren tt_ matched 
label var matched    "Percentage of obs not replicated (weighted)"
ren qq_ outliers 
label var outliers "Percentage of not matched observations defined as outliers (spending above 95th percentile of household spending)"

replace spend_cat="Imputed rent"  		 	if spend_cat=="rent1"  		
replace spend_cat="Actual rent"   			if spend_cat=="rent2"  		
replace spend_cat="In-kind wage-food"   	if spend_cat=="ikfood" 		
replace spend_cat="In-kind wage-housing"   	if spend_cat=="ikhous"  		
replace spend_cat="In-kind wage-other"   	if spend_cat=="ikothr" 		
replace spend_cat="Non-food yearly"   		if spend_cat=="nfyr" 		
replace spend_cat="Non-food monthly"      	if spend_cat=="nfmt" 
replace spend_cat="Non-food weekly" 		if spend_cat=="nfwk" 		
replace spend_cat="Food" 					if spend_cat=="food"  			
replace spend_cat="Own consump. food" 		if spend_cat=="auto_f"  		
replace spend_cat="In-kind wage-transf" 	if spend_cat=="trfin"  		
replace spend_cat="Welfare aggregate" 		if spend_cat=="cons1"
replace spend_cat=proper(spend_cat)


format %5.4f matched outliers
tostring matched outliers, replace force
cap mkdir "$poe\1_cleaning"
export excel using "$poe\1_cleaning\2_comparison_spending.xlsx", sheet(subcomponents_analysis, replace) first(varlab)



