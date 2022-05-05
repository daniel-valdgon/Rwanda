



use "merged18.dta", clear

*--> Table 1 
ta poverty [iw=pop_wt] // extreme 15.96 poor 38.22. Note: it does not work with weight neither . pop_wt sums all the population 12mlln, howver there is not a clear correspondance between both weights. 


*--> table 2 needs the EICV4

*--> Table 3 
recode poverty (1 2 =1) (3=0), gen (pov)
ta ur pov   [iw=pop_wt] , row nofreq
ta province pov   [iw=pop_wt] , row nofreq
ta province poverty   [iw=pop_wt] , row nofreq

*--> Table 4 

use "$data\EICV5_Poverty_file", clear
/*Income*/ sum sol_jan [aw= pop_wt], d
/*Gini:*/  ainequal sol_jan [aw= pop_wt]

*The problem is full reconstruction of income. The do-file allow me to arriv eot aggregate consumption in ae, but not in Jan 14 prices. I am not sure which variable is the deflator

* Neither which variable is the poverty line 

*Below I compute the implicit deflator 
	egen nisr = rowtotal( exp1 exp4 exp5 exp6 exp7 exp8 exp9 exp10 exp11 exp12 exp13 exp14_2 exp15_2 exp16_2 exp17 exp18)
	gen nisr_ae=nisr/ae
	
	* the problem is going to january prices of 2014, it seems to use a cluster level deflator, not sure how computed 
	gen k=cons1_ae/sol_jan // there is several deflations one for cluster because they use item level prices...?
	bysort clust: egen kk=sd(k) // almost 0 not strictly for 1% of the observations 
	
			use "merged18.dta", clear
			
			*-- remove things that are counted elsewhere
			replace health = 0
			replace house  = 0
			replace trfout = 0
			replace travel = 0
			
			*-- adult equivalence
				foreach var in nfyr nfmt nfwk food auto autonf  trfin trfout social durables health educ travel rent house water elect wages {
				gen ad`var' = `var' / adeqtot
				gen ln`var' = ln(ad`var') if ad`var'>0
				replace ln`var'= 0 if ln`var'==.
			} 
			
			*-- aggregate
				egen total = rowtotal(nfyr nfmt nfwk food auto autonf  trfin trfout social durables health educ travel rent house water elect wages ), m
			
			*-- remove outliers
				foreach var in nfyr nfmt nfwk food auto autonf  trfin trfout social durables health educ travel rent house water elect wages {
				
				*exceptional expenditures
				
				*outliers
				replace ln`var'= . if ln`var'==0
				
				bysort province: egen mn`var' =  mean(ad`var')
				bysort province: egen mu`var' =  mean(ln`var')
				bysort province: egen sd`var' = sd(ln`var')
				gen outl`var'= (ln`var'>mu`var'+3.5*sd`var') if ln`var'<.
				
				replace  ad`var' = mn`var'  if outl`var'==1
				
				} 
			
				replace nfyr = . if nfyr>20000000 //manually removing some outliers to get same results as official
				egen adtot = rowtotal(ad* ), m
			
			*--> Consumption shares 	
				foreach var in nfyr nfmt nfwk food auto autonf  trfin trfout social durables health educ travel rent house water elect wages {
				gen shrad`var' = ad`var' / adtot
				} 
			
			*-- price adjustment
				gen prcadtot = adtot / idx //  
