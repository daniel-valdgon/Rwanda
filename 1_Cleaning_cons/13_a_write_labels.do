


count
local n = r(N)
qui compress

tempname hdl
tempfile labels_small

if "`formulario'"=="7d" {
file open `hdl' using "$pdo/1_Cleaning_cons/13_c_labels_large.do", write replace
}
else if "`formulario'"=="7e" {
file open `hdl' using "$pdo/1_Cleaning_cons/13_b_labels_small.do", write replace
}
else if "`formulario'"=="7f" {
file open `hdl' using "$pdo/1_Cleaning_cons/13_e_labels_other_non_food.do", write replace
}
else if "`formulario'"=="7g" {
file open `hdl' using "$pdo/1_Cleaning_cons/13_d_labels_inputs.do", write replace
}

file write `hdl' "*** This file was created by VarLabels.do" _n
file write `hdl' `"*** on `= c(current_date)' at `= c(current_time)'. "' _n
file write `hdl' "*** " _n
file write `hdl' "********************************************** " _n
file write `hdl' _n
file write `hdl' _n


forvalues x = 1/`n' {
	
	else if "`formulario'"=="7d" {
		
		file write `hdl' "capture label variable v_sold_7d`=code[`x']' "
		file write `hdl' `""value sold last 12 mt: `=label[`x']'""' 
		file write `hdl' _n
	
		file write `hdl' "capture label variable q_sold_7d`=code[`x']' "
		file write `hdl' `""quant sold last 12 mt: `=label[`x']'""' 
		file write `hdl' _n
	}
	if "`formulario'"=="7e" {

		file write `hdl' "capture label variable v_sold_7e`=code[`x']' "
		file write `hdl' `""value sold last 12 mt: `=label[`x']'""' 
		file write `hdl' _n
		
		file write `hdl' "capture label variable q_sold_7e`=code[`x']' "
		file write `hdl' `""quant sold last 12 mt: `=label[`x']'""' 
		file write `hdl' _n
		
		file write `hdl' "capture label variable q_cons_7e`=code[`x']' "
		file write `hdl' `""quant own cons annualized: `=label[`x']'""' 
		file write `hdl' _n
	}
	
	else if "`formulario'"=="7f" {
		
		file write `hdl' "capture label variable v_spent_7f`=code[`x']' "
		file write `hdl' `""value sold last 12 mt:  `=label[`x']'""' 
		file write `hdl' _n
	
	}
	else if "`formulario'"=="7g" {
		
		file write `hdl' "capture label variable v_spent_7g`=code[`x']' "
		file write `hdl' `""amount spent in last 12 mt: `=label[`x']'""' 
		file write `hdl' _n
	
	}

}

file close `hdl'

