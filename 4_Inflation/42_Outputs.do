

use "$pp/dta/welfare_food.dta" , clear 


/*===============================================================================================
	Figures with food inflation 
 ==============================================================================================*/

gen sub_coicop=substr(coicop,1,2)

gen prod=1 	 if value_sold!=0 & value_sold!=. & sub_coicop=="01" // subcoicop is redundant
replace prod=0 if prod==.

gen c_food=1 if cons!=0 & cons!=. & sub_coicop=="01"
replace c_food=0 if c_food==.

*food consumption share
bysort hhid: egen f_cons_share=total(cons_share) if c_food==1
	bysort hhid: ereplace f_cons_share=mean(f_cons_share)
	replace f_cons_share=0 if c_food==0 &  f_cons_share==.

bysort hhid: egen f_prod_share=total(prod_share) if prod==1
	bysort hhid: ereplace f_prod_share=mean(f_prod_share)
	replace f_prod_share=0 if prod==0 &  f_prod_share==.

bysort hhid: egen f_delta_welfare=total(delta_welfare) if sub_coicop=="01" 
	bysort hhid: ereplace f_delta_welfare=mean(f_delta_welfare)


collapse (sum) cons_ae_rwf14 cons_ae cons quant_sold value_sold cons_share prod_share delta_welfare  (first) small_prod adeqtot pline_ext pline_mod idx cons1_nisr clust province weight pop_wt f_cons_share f_prod_share f_delta_welfare (max) prod c_food, by(hhid )


quantiles cons_ae_rwf14 [aw=pop_wt], gen (qtiles) n(10)

/*===============================================================================================
	Temporal production of statistics in excel 
 ==============================================================================================*/

*Producers 

preserve

	*stats
	collapse (mean) c_food f_cons_share cons_share prod  f_prod_share prod_share f_delta_welfare delta_welfare[aw=pop_wt], by(qtiles)
	

	renames c_food-delta_welfare \ v1-v8
	
	reshape long v, i(qtiles) j(code)
	
	tostring code, replace 
	replace code="c_food" if code=="1"
	replace code="f_cons_share" if code=="2"
	replace code="cons_share" if code=="3"
	replace code="prod" if code=="4"
	replace code="f_prod_share" if code=="5"
	replace code="prod_share" if code=="6"
	replace code="f_delta_welfare" if code=="7"
	replace code="delta_welfare" if code=="8"
	
	export excel using "$pp/figures/deaton_inflation.xlsx",  sheet(stats, replace) firstrow(variables)
	
restore 

preserve 
	gen winners_food_share=f_delta_welfare<0
	gen winners_tot_share=delta_welfare<0 // this may be less because of non-food effects can reduce welfare of net food producers 
	
	gen winners_food=f_delta_welfare if f_delta_welfare<0
	gen losers_food=f_delta_welfare if f_delta_welfare>=0

	gen winners_tot=delta_welfare if delta_welfare<0
	gen losers_tot=delta_welfare if delta_welfare>=0
	
	collapse (mean) winners* losers*  [aw=pop_wt], by(qtiles)
	
	

	
	
	renames winners_food_share-losers_tot \ v1-v6
	
	reshape long v, i(qtiles) j(code)
	
	tostring code, replace 
	replace code="winners_food_share" if code=="1"
	replace code="winners_tot_share" if code=="2"
	replace code="winners_food" if code=="3"
	replace code="winners_tot" if code=="4"
	replace code="losers_food" if code=="5"
	replace code="losers_tot" if code=="6"
	
	export excel using "$pp/figures/deaton_inflation.xlsx",  sheet(stats_win_los, replace) firstrow(variables)
	
restore 
	
