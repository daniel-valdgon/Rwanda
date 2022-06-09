

*Stats of the direct effect 
use "${proj}\outputs\intermediate\dta\cons_hhid_coicop.dta", clear 

gen dir_eff = 0
	replace dir_eff = cons_ae_rwf14 if coicop == "07.2.2.1.01" //petrol
	replace dir_eff =cons_ae_rwf14 if coicop == "07.2.2.1.02" //diesel

gen total_cons=cons_ae_rwf14*adeqtot
gen tot_dir_eff=dir_eff*adeqtot


collapse (sum) cons_ae_rwf14 dir_eff total_cons tot_dir_eff (first) adeqtot pop_wt, by(hhid)

gen coverage=tot_dir_eff>0 & tot_dir_eff!=.

quantiles cons_ae_rwf14 [aw=pop_wt], gen (q) n(10)

gen share= 100*dir_eff/cons_ae_rwf14 



collapse (mean) share cons_ae_rwf14 dir_eff  coverage adeqtot (sum) total_cons tot_dir_eff [iw=pop_wt], by(q)



*Stats of the indirect effect 

*Sctter of prices 



use  "${proj}\outputs\intermediate\dta\cons_hhid_simulated.dta", replace

gen tot_dir_eff=dir_eff*adeqtot












