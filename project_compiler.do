/*============================================================================================
 ======================================================================================

	Project:   Subsidies Rwanda
	Author:    EPL (DV & MM) PE (JCP)
	Creation Date:  May 2 2021

============================================================================================
============================================================================================*/

/*===============================================================================================
	Main paths (Every user needs to add its own paths here)
 ==============================================================================================*/
 
clear 
macro drop all
set more off, perm

* Note you should define a folder for your inputs, outputs and do-files. They do not need to be in the same folder. This gives flexibility across collaborators to use different folders for heavy databases. 
	
	if "`c(username)'"=="danielsam" {
	
		global proj  "C:/Users/danielsam/Desktop/World Bank/Rwada_Subsidy/r_data/Energy" 
	}
	else if "`c(username)'"=="WB395877" {
		global proj  "C:\Users\wb395877\OneDrive - WBG\Equity_Policy_Lab\Rwanda\Energy"
	
		
	}


/*===============================================================================================
	Internal folder structure
	Note: Do not change paths here unless you want to change the structure of the project. Changes to this section may affect other users.						
 ==============================================================================================*/
	
	*--> Basic output and input paths 
	global pdo   		"$proj/analysis_subsidies" 	 // path do-files
	global pdta			"$proj/inputs"
	global pp 	  		"$proj/outputs/final" 		 // path paper output
	global po 	  		"$proj/outputs/intermediate"  // path raw output
	
	*--> Intermediate outputs
	global pol 	  		"$po/log" 	
	global pot 	  		"$po/tables" 	
	global poe 			"$po/excel"	
	global pof 	  		"$po/figures" 	
	global pov 	  		"$po/viz" 		
	global pos 			"$po/ster"
    global podta 		"$po/dta"  
	global PYTHONPATH 	`"$pdo/_programs/phyton"' // * path of phyton scripts for tables 
	
	*--> Final outputs 
	global ppt      "$pp\tables"    // Paper tables
	global ppf 	  	"$pp\figures"  // Paper figures
	global ppd 	  	"$pp\dta"  // Paper figures
	
	*--> Create the ouput folder extensions
	cap mkdir "${pdta}"
	cap mkdir "${proj_out}/outputs"
	cap mkdir "${po}"
	cap mkdir "${pp}"
	cap mkdir "${pol}"
	cap mkdir "${pot}"
	cap mkdir "${poe}"
	cap mkdir "${pof}"
	cap mkdir "${pov}"
	cap mkdir "${pos}"
	cap mkdir "${podta}" 
	cap mkdir "${ppt}" 
	cap mkdir "${ppf}" 
	
	*--> Excel files with parameters 
	
	global xls_nm_pmts "parameters"
	
/*===============================================================================================
	Log and loading programs 
 ==============================================================================================*/

* Initialize log and record system parameters

	cap log close
	cap mkdir "${po}/log"
	local datetime : display %tcCCYY.NN.DD!_HH.MM.SS `=clock("$S_DATE $S_TIME", "DMYhms")'
	local logfile "$pol/`datetime'.log"
	log using "`logfile'", text
	
	display "Begin date and time: $S_DATE $S_TIME"
	display "User: `c(username)'"


	* Stata programs and R scripts that are cross sectional and reused for several do-files in the paper
	
	*Required packages 	written by others 
	sysdir set PERSONAL "$pdo/_programs/libraries/Stata"  
	
		*-->Cost push program 
		run "${proj}\analysis_subsidies\_programs\libraries\Stata\c\costpush.ado"

		

/*===============================================================================================
	0. Setting up parameters
 ==============================================================================================*/
	
	dis "Loading paramters"
	include "$pdo\pull_pmts.do"
	

	
/*===============================================================================================
	1. Welfare aggregate 
 ==============================================================================================*/

/*
	*Welfare replication
	// Effort to replicate the welfare aggregate
	qui: include "$pdo\1_cleaning_cons\11_welfare_aggregate.do"
	
			// Compare our replication with official statistics 
			qui: include "$pdo\1_cleaning_cons\11a_comp_welfare_agregate.do"
	
	*Consumption data
	// Creates a long format dataset at the household coicop level that replicates (by construction) the official statistics 
	qui:  include "$pdo\1_cleaning_cons\12_coicop_hh_data.do"

*/	
	*Sales data
	// Creates a long format dataset at the household coicop level that capture gross income for agricultural producers  small and large producers 
	  include "$pdo\1_cleaning_cons\13_agric_inc_dbase.do"
	
	  include "$pdo\1_cleaning_cons\14_small_produc.do"
		
/*===============================================================================================
	2. Cost push 
 ==============================================================================================*/

	*Sam to COICOP 
	// from Coicop to I-O in order to apply cost push model 
	*qui: include "$pdo\2_Cost_push\22_coicop2sam.do" // this is currently not used
	
	*Tax excise 
	// from Coicop to I-O am level 
	* include "$pdo\2_Cost_push\23_direct_indirect_simulations.do"
	
	*Cost push on inflation 
	 include "$pdo\2_Cost_push\24_food_inflation.do"
	
	
/*===============================================================================================
	3. Welfare stats Tax ex
 ==============================================================================================*/
	
	// Coicop-household consumption microdata
	*qui:  include "$pdo\3_Stats\31_Welfare_stats.do"
	
	// Coicop-household consumption microdata
	*qui: include "$pdo\3_Stats\32_stats_post_file.do"
	

/*===============================================================================================
	4. Deaton Stats 
 ==============================================================================================*/

	include "$pdo/4_Inflation/4_1_Net_gains_inflation.do"
	
	include "$pdo/4_Inflation/42_Outputs.do"
	
 
* End log
display  "End date and time: $S_DATE $S_TIME"
log close

** EOF
