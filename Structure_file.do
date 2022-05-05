

/*===============================================================================================
===============================================================================================

								Generic set up

===============================================================================================
==============================================================================================*/


/*===============================================================================================
								Main paths 
 ==============================================================================================*/
 
clear 
macro drop all
set more off, perm

* User must define two global macros in order to run the analysis:
	* (1) "MyProject" points to the project folder
	
	if "`c(username)'"=="danielsam" {
	
		global proj  "C:\Users\danielsam\Desktop\World Bank\Rwada_Subsidy\r_data\Energy" // just in case the line above fails, it does not work well with texdoc  
		
		global a_proj_eicv 	"C:\Users\danielsam\Desktop\World Bank\Rwada_Subsidy\r_data\EICV5" // path raw data: large and raw datasets
		
		global a_proj_ceq 	"C:\Users\danielsam\Desktop\World Bank\Rwada_Subsidy\r_data\CEQ" // path raw data: large and raw datasets
		
	}
	else if {
	
		
	}
	

	*	global pd_i		 	"$proj\Inputs"
	*	global pd_sd   		"$proj\Survey_data" 			// the one is temporal tomorrow	
	
/*===============================================================================================
								Internal folder paths 
 ==============================================================================================*/
	
	
	global pdta			"$proj/Inputs"
	global pdo   		"$proj/analysis_subsidies" 	 // path do-files
	global po 	  		"$proj/output/intermediate"  // Output for analysis
	global pp 	  		"$proj/output/final" 		 // path paper output
	
	*--> Intermediate outputs
	global pol 	  		"$po/log" 	
	global pot 	  		"$po/tables" 	
	global poe 			"$pot/excel"	
	global pof 	  		"$po/figures" 	
	global pov 	  		"$po/viz" 		
	global pos 			"$po/ster"      
	global PYTHONPATH 	`"$pdo/_programs/phyton"' // * path of phyton scripts for tables 
	
	*--> Final outputs 
	global ppt      "$pp\tables"    // path to paper tables 
	global ppf 	  	"$pp\figures"  // path to paper figures
	global pst 	  	"$ps\tables"   // path to slides tables 
	global psf 	  	"$ps\figures"  // path to slides figures 
	
	cap mkdir "${pol}"
	cap mkdir "${pot}"
	cap mkdir "${poe}"
	cap mkdir "${pof}"
	cap mkdir "${pov}"
	cap mkdir "${pos}"
	
	*Note:!! always that you want to save a table, figure, ster file, ect; you need to use the global define for each type of files + the directory of the analysis. For eaxample :  "$pot/31_an" saves tables for analysis 31_an
	global prepo "$po/_repo"	//path repo
	cap mkdir "$po/_repo"
	


/*===============================================================================================
							Log and loading programs 
 ==============================================================================================*/

* Initialize log and record system parameters

	cap log close
	cap mkdir "${po}/log"
	local datetime : display %tcCCYY.NN.DD!_HH.MM.SS `=clock("$S_DATE $S_TIME", "DMYhms")'
	local logfile "$po/log/`datetime'.log"
	log using "`logfile'", text
	
	display "Begin date and time: $S_DATE $S_TIME"
	display "User: `c(username)'"


	* Stata programs and R scripts that are cross sectional and reused for several do-files in the paper
	adopath ++ "$pdo/_programs"
	
	*download new packages either from github or from repec. We turn off this line, in principle could be dangerous to have always the lastest packages.
	
		*include "$proj/scripts/_programs/_install_stata_packages.do"
		
		* if "$DisableR"!="1" rscript using "$proj/scripts/_programs/_install_R_packages.R" //  R packages can be installed manually (see README) or installed automatically by uncommenting the following line
	
	*Required packages 	written by others 
	sysdir set PERSONAL "$pdo/_libraries/Stata"  // This is not right, PELAOOOOO
	mata: mata mlib index
	
	* Stata and R version control
	version 16.1
	*if "$DisableR"!="1" rscript using "$MyProject/scripts/programs/_rversion.R", args(3.6 4.0.1 1 0)


/*===============================================================================================
===============================================================================================
===============================================================================================

								Subsidies algorithm 

===============================================================================================
===============================================================================================
===============================================================================================
==============================================================================================*/

/*===============================================================================================
					0. Project_parameters
 ==============================================================================================*/
	
	*dis "Loading settings:"
	*include "$pdo\settings.do"
	
	
	
/*===============================================================================================
					1. Descriptives 
 ==============================================================================================*/
	
	*Rebuild the welfare aggregate ...
	include "$pdo\1_cleaning_cons\11_poverty_numbers.do"
	* POverty stats 
	include "$pdo\1_cleaning_cons\12_stats_pov.do"
	
 
/*===============================================================================================
					2. Identification assumptions
 ==============================================================================================*/
	
		
	
	
	
	* Push to git_hub folder (results we care about, so git_hub makes automatic back_up: pendent a useful manual back_up, because we do not want to back up everything)

	
* End log
display  "End date and time: $S_DATE $S_TIME"
log close

** EOF
