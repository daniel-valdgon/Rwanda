/*============================================================================================
 ======================================================================================
 
Project:   Subsidies Rwanda
Author:    EPL (DV & MM) PE (JCP)
Creation Date:  May 2 2021
Objective: Compute cost push for petroleoum reform and equivalent variation dataset 
----------------------------------------------------
	
 
============================================================================================
============================================================================================*/

local i=0
foreach tax_excise  in 10 20 {
local ++i

*use "${path}\data\RWA_energy_data_test.dta", clear

local t=`tax_excise'/100

global petr_shock = `t'
global dies_shock = `t'

global comm_share  = 1 // share of pertroleium in petroleum products	
global sect_share  = 1 // share of pertroleium in chemical sector	

* calculation the indirect effect using the commodity approach
import excel "${proj}\inputs\RWA-IO_input.xlsx", sheet("commodities") firstrow clear

gen fixed = 0	
	replace fixed = 1 if commodity == "cpetr"
	

gen dp = 0
	replace dp =  (${petr_shock} + ${dies_shock}) / 2 * ${comm_share}  if fixed == 1 
	
costpush commodity_*, fixed(fixed) price(dp) genptot(total_eff_commodity) genpind(ind_eff_commodity) fix
tempfile ind_commodity
save `ind_commodity'


* calculation the indirect effect using the sector approach
import excel  "${proj}\inputs\RWA-IO_input.xlsx", sheet("sectors") firstrow clear

gen fixed = 0	
	replace fixed = 1 if sector == "achem"

gen dp = 0
	replace dp =  (${petr_shock} + ${dies_shock}) / 2 * ${sect_share}  if fixed == 1 
	
costpush sector_*, fixed(fixed) price(dp) genptot(total_eff_sector) genpind(ind_eff_sector) fix
tempfile ind_sector
save `ind_sector'

* merging with hh-level data
import excel "${proj}\inputs\Matching COICOP-SAM_May23.xlsx", sheet("coicop_sector") firstrow clear
rename sam_sector sector
rename sam_commodity commodity 
rename *, lower
drop item
*isid coicop

collapse (first) sector commodity, by(coicop) // we need this to be unique by coicop. ASSUMPTION: WE TAKE JUST THE FIRST (any?) SECTOR and COMMODITY
isid coicop
tempfile coicop
save `coicop'

use "${proj}\outputs\intermediate\dta\cons_hhid_coicop.dta", clear 
global welfare cons_ae_rwf14 
keep ${welfare} hhid coicop
*collapse (sum) ${welfare}, by(hhid coicop) // we need this to be unique by hhid & coicop. FIXED!
isid hhid coicop

merge m:1 coicop using `coicop', nogen assert(match using) keep(match) // we need them all to be matched. FIXED!

gen dir_eff = 0
	replace dir_eff = ${petr_shock} if coicop == "07.2.2.1.01" //petrol
	replace dir_eff = ${dies_shock} if coicop == "07.2.2.1.02" //diesel
	
	gen ${welfare}_dir = ${welfare} * dir_eff
drop dir_eff

tempfile data
save `data'

foreach var in commodity sector {
    use `data', clear
	collapse (sum)  ${welfare} ${welfare}_dir, by(hhid `var')
	merge m:1 `var' using `ind_`var'', nogen assert(match using) keep(match) keepusing(ind_eff_`var') // we need to check that!! FIXED!
	gen ${welfare}_ind_`var' = ${welfare} * ind_eff_`var'
	collapse (sum) ${welfare}_ind_`var', by(hhid)

	tempfile data_`var'
	save `data_`var''
}


use `data', clear
collapse (sum) ${welfare} ${welfare}_dir, by(hhid)
keep ${welfare} ${welfare}_dir hhid
foreach var in commodity sector {
	merge 1:1 hhid using `data_`var'', nogen assert(match)
}

*creating variable for looping reasons
egen cons_ae_rwf14_total=rowtotal(cons_ae_rwf14_dir cons_ae_rwf14_ind_commodity)

ren cons_ae_rwf14 cons_ae_rwf14_benchmark

local list_welf "cons_ae_rwf14_benchmark cons_ae_rwf14_dir cons_ae_rwf14_ind_commodity cons_ae_rwf14_total"
keep hhid `list_welf'

*rename for standarization 

	foreach v in `list_welf' {
		ren `v' `v'_`tax_excise'
				
		label var cons_ae_rwf14_benchmark_`tax_excise' "benchmark level welfare"
		local text_label=substr("`v'",15,3)
		label var `v'_`tax_excise' "change in welfare , `text_label' effect - tax exc of `tax_excise'"
	}

	su ${welfare}_benchmark_* ${welfare}_dir ${welfare}_ind_* ${welfare}_total_*
	
	if `i'==1 {
		tempfile n_tax_sim
		save `n_tax_sim', replace 
	}
	else {
		merge 1:1 hhid using `n_tax_sim', nogen 
		save  `n_tax_sim', replace 
	}
}

use `n_tax_sim', clear 

save "${proj}\outputs\intermediate\dta\cons_hhid_simulated.dta", replace



