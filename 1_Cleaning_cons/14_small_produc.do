/*============================================================================================
 ======================================================================================
 ======================================================================================

Project:   Subsidies Rwanda
Author:    EPL (DV & MM) PE (JCP)
Creation Date:  July 10 2022
Objective: Defining small producer 
	

----------------------------------------------------
Notes: Two definition of small producers 

 ============================================================================================
 ============================================================================================*/


use `dta_13_prod', clear 


*Definition 1: more than 51% of crop is defined as small crop 
// It was created in dofile 13_agric_inc_dbase and commented 

*Definition 2: Quantities sold (available for small, large and non-agricultural production) are higher than 5%

if "$sppm"=="market concentration" {
	bysort coicop province region: egen tot_sales=total(value_sold)
	gen share_reg_prov=value_sold/tot_sales
	
	gen small_prod=share_reg_prov<${sppt}
	replace small_prod=1 if share_reg_prov==.
	
	dis as error  "Running here in market concentration "
	ta small_prod
}

*Definition 3: Landlords. Less intuitive from a market perspective but it may be more appealing from a political economy perspective

else if "$sppm"=="land concentration" {
	
	*share land
	bysort hhid: replace land=. if _n!=1
	bysort province region: egen tot_land=total(land)
	gen share_land=land/tot_land
	
	*small producer
	gen small_prod=share_land<${sppt}
	bysort hhid: ereplace small_prod=mean(small_prod)
	replace small_prod=1 if share_land==.
	
	 dis as error "Running here in land concentration "
	ta small_prod
}

save "$po/dta/prod_hhid_coicop.dta" , replace 

