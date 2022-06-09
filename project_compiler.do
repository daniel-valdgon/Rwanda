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
	adopath ++ "$pdo/_programs"
	
	*download new packages either from github or from repec. We turn off this line, in principle could be dangerous to have always the lastest packages.
	
		*include "$proj/scripts/_programs/_install_stata_packages.do"
		
		* if "$DisableR"!="1" rscript using "$proj/scripts/_programs/_install_R_packages.R" //  R packages can be installed manually (see README) or installed automatically by uncommenting the following line
	
	*Required packages 	written by others 
	sysdir set PERSONAL "$pdo/_programs/libraries/Stata"  // This is not right, PELAOOOOO
	mata: mata mlib index
	
	* Stata and R version control
	version 16.1
	*if "$DisableR"!="1" rscript using "$MyProject/scripts/programs/_rversion.R", args(3.6 4.0.1 1 0)


/*===============================================================================================
	0. Setting up parameters
 ==============================================================================================*/
	
	*dis "Loading settings:"
	*include "$pdo\settings.do"
	*Note: Define $folder for each step. This makes that each table, figure, ster file is saved in a independent folder.  For eaxample :  "$pot/31_an" saves tables for analysis 31_an
	
	
/*===============================================================================================
	1. Welfare aggregate 
 ==============================================================================================*/

/*	
	// Replication of official consumption aggregate ...
	qui: include "$pdo\1_cleaning_cons\11_poverty_numbers.do"
	
	//Compare to official welfare aggregate
	qui: include "$pdo\1_cleaning_cons\12_Replication_welfare_aggregate.do"
	
*/

/*===============================================================================================
	2. Tax excise exercise
 ==============================================================================================*/
/*	
	// Coicop-household consumption microdata
	qui:  include "$pdo\2_Cost_push\21_Create_coicop_data.do"
	
	// from Coicop to I-O am level 
	qui: include "$pdo\2_Cost_push\22_coicop2sam.do" // this is currently not used
*/		
	// from Coicop to I-O am level 
	 include "$pdo\2_Cost_push\23_direct_indirect_simulations.do"
	

/*===============================================================================================
	3. Welfare stats
 ==============================================================================================*/
	
/*
*/

	// Coicop-household consumption microdata
	qui:  include "$pdo\3_Stats\31_Welfare_stats.do"
	
	// Coicop-household consumption microdata
	qui: include "$pdo\3_Stats\32_stats_post_file.do"
	

	
 
* End log
display  "End date and time: $S_DATE $S_TIME"
log close

** EOF
