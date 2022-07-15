
/*===============================================================================================
	Combine consumption and production data at coicop level 
 ==============================================================================================*/

*Consumption Data
use "$po/dta/cons_hhid_coicop.dta" , clear 
keep hhid coicop cons1_nisr cons_ae_rwf14 cons adeqtot pline_ext pline_mod idx cons_ae cons_ae_rwf14 clust province weight pop_wt

*Production data
merge 1:1 hhid coicop using "$po/dta/prod_hhid_coicop.dta"	, keepusing(quant_sold value_sold small_prod)


*Filling up non-merged (but correct) hhid-coicop obs

// from master data
replace cons_ae_rwf14=0 if _merge==2 
replace cons=0 if _merge==2 
replace cons_ae=0 if _merge==2 

foreach v in adeqtot pline_ext pline_mod idx  cons1_nisr province clust weight pop_wt {
bysort hhid: ereplace `v'=mean(`v')
}

// from user data 
bysort hhid: ereplace small_prod=mean(small_prod)
replace small_prod=1 if _merge==1 & small_prod==.

replace quant_sold=0 if _merge==1 
replace value_sold=0 if _merge==1 
drop _merge

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       663,975
        from master                   645,878  (_merge==1)  products consumed but not produce by household j
        from using                     18,097  (_merge==2)  products not consumed but produced by household j

    matched                            27,270  (_merge==3)  products consumed and produced by household j

*/


*Inflation data 
merge m:1 coicop using `vector_prices' , keepusing(sam_${io} ind_eff_${io}  dir_eff ) assert (match using) nogen keep(match) // 21 observations does not match because are coicop with no data on production or consumption 


egen dp_total= rowtotal(dir_eff ind_eff_${io})
label var dp_tot "Change in prices using ${io} level sam"

ren dir_eff 		dp_direct
ren ind_eff_${io} 	dp_indirect



/*===============================================================================================
	Formula 
 ==============================================================================================*/

* We use expenditure in nominal terms to be able to compute the ratio production/total_spending in the same units. Result should be the same if we transform production to real terms and use only consumption in real terms 

*Shares
	bysort hhid : egen tot_exp=total(cons) // /*test compare tot_exp cons1_nisr */ 
	gen prod_share=value_sold/tot_exp 
	
	gen cons_share=cons/tot_exp 

*Formula
gen delta_welfare=(cons_share*dp_${peffect}) - (  (1-small_prod)*(prod_sh)*dp_${peffect} + (small_prod)*(prod_sh)*${spp}*dp_${peffect} )

save "$pp/dta/welfare_food.dta" , replace 
