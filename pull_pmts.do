


*==================================================================================
*==============       Pulling list of paramters						===========
*==================================================================================



/*---------------------------------
 Inflation scenario 
*---------------------------------*/

	preserve
			import excel using "$pdta/${xls_nm_pmts}.xlsx", clear sheet(Inputs Inflation) first
			keep   COICOP ITEM PriceIncreaseformat1g
			rename *, lower
			
			format item %20s
			ren priceincreaseformat1g price_increase
			label var price_increase "Price increase (1+g)"
			
			collapse (mean) price_increase (first) item, by(coicop) // No weights for now because coicop and list are unique [aw=weights]
			tempfile delta_prices
			save `delta_prices', replace 
			
	restore


/*---------------------------------
 List of parameters 
*---------------------------------*/
	
	preserve
			
			import excel using "$pdta/${xls_nm_pmts}.xlsx", clear sheet(Ind_parameters) first
			
			/*---------------------------------
			Sam aggregation
			*---------------------------------*/

			levelsof value  if stata_lbl=="io", local(temp_loc_io)
			global io `temp_loc_io'
			
			/*---------------------------------
			SP passtrough 
			*---------------------------------*/

			levelsof value  if stata_lbl=="spp", local(temp)
			global spp `temp'
			
			
			/*---------------------------------
			SP Method 
			*---------------------------------*/

			levelsof value  if stata_lbl=="spp_method", local(temp)
			global sppm `temp'
			
			/*---------------------------------
			SP concentration threshold 
			*---------------------------------*/

			levelsof value  if stata_lbl=="spp_threshold", local(temp)
			global sppt `temp'
			
			
			/*---------------------------------
			Price effect 
			*---------------------------------*/

			levelsof value  if stata_lbl=="p_effect", local(temp)
			global peffect `temp'
			
			
			
	restore

	
			