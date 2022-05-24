{smcl}
{* *! version 1.0.0  17September2018}{...}
{cmd:help costpush}
{hline}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :{cmd:costpush} {hline 1} Including the Direct and Indirect Effects of Indirect Taxes and Subsidies}{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 23 2}
{opt costpush} {varlist} {ifin} {cmd:,} 
{opt FIXed(varlist max=1 numeric)}
{opt PRICEshock(varlist max=1 numeric)}
{opt genptot(newvarname)}
{opt genpind(newvarname)}
[{opt fix}]


{title:Description}

{pstd}
{cmd:costpush} Creates a vector of indirect and total price 
changes due to price shock. The input data is assumed to be a square matrix where 
each observation i and variable i represent the same sector of the economy, 
and its value is a technology coefficient.

{pstd}
The command outputs the total price shock and indirect price shock for every 
sector due to the change in price (as a percentage of actual prices) across different sectors. To get the total 
impact for each household users must merge the vectors with the calculated shocks 
(at the sector level) to the household expenditure dataset (at household and sector 
level) and multiply the total shock (ie. the variable produced under the genptot
option) with the household’s expenditure on each sector. This will yield the 
change in household expenditure on each sector due to the shock.

{title:Options}

{phang}
{opt fixed} Variable containing the indicator (1=fixed or 0=not fixed) to denote if each sector of the economy has fixed prices. 

{phang}
{opt priceshock} Variable indicating the price shock to each sector (i) of the economy.

{phang}
{opt genptot} New variable name that will be filled with the total price effects for each sector. Variable must not exist in dataset.

{phang}
{opt genpind} New variable name that will be filled with the indirect price effects for each sector. Variable must not exist in dataset.

{phang}
{opt fix} Optional, and requests that when obtaining indirect effects fixed sectors are immune to price changes. Thus indirect for sector i = 0.


{title:Example 1}

clear all
set more off
//3X3 matrix from CEQ ch7 example
set obs 3
gen sec = _n
forval z=1/3{
        gen sector`z' = 0
}

replace sector1 = 40/120 in 1
replace sector1 = 15/120 in 2
replace sector1 =  2/120 in 3

replace sector2 =  5/75 in 1
replace sector2 = 35/75 in 2
replace sector2 = 22/75 in 3

replace sector3 =  7/80 in 1
replace sector3 =  7/80 in 2
replace sector3 = 10/80 in 3

gen fixed = 0
replace fixed = 1 in 2  //Sector 2 is fixed

gen dp = 0
replace dp = 0.1 in 2 //Sector 2 has a 10% price shock (i.e. a price increase)

costpush sector*, fixed(fixed) price(dp) genptot(total) genpind(indirect)
list total indirect
costpush sector*, fixed(fixed) price(dp) genptot(totalfix) genpind(indirectfix) fix
list totalfix indirectfix

//Fictitious household with consumption on all 3 items
//Data is at household sector level
preserve
	clear
	set obs 3
	gen sec = _n
	gen hhid = "100001"
	gen expenditure = 1000*_n
	
	tempfile hhexp
save `hhexp'
restore

//Impact of 10% increase on sector 2 for the household’s expenditure
merge 1:m sec using `hhexp', nogen keep(3)

gen new_expenditure = expenditure*(1+total)


{title:Example 2}

clear all
set more off
//3X3 matrix from CEQ ch7 example
set obs 3
gen sec = _n
forval z=1/3{
        gen sector`z' = 0
}

replace sector1 = 40/120 in 1
replace sector1 = 15/120 in 2
replace sector1 =  2/120 in 3

replace sector2 =  5/75 in 1
replace sector2 = 35/75 in 2
replace sector2 = 22/75 in 3

replace sector3 =  7/80 in 1
replace sector3 =  7/80 in 2
replace sector3 = 10/80 in 3

gen fixed = 0
replace fixed = 1 in 2  //Sector 2 is fixed

gen dp = 0
//Imagine VAT is 12% and you want to see the effect of removing VAT
replace dp = -(1-(1/1.12))  //Obtain percentage change in total price due to removal of VAT

costpush sector*, fixed(fixed) price(dp) genptot(total) genpind(indirect)
list total indirect
costpush sector*, fixed(fixed) price(dp) genptot(totalfix) genpind(indirectfix) fix
list totalfix indirectfix

//Fictitious household with consumption on all 3 items
//Data is at household sector level
preserve
	clear
	set obs 3
	gen sec = _n
	gen hhid = "100001"
	gen expenditure = 1000*_n
	
	tempfile hhexp
save `hhexp'
restore

//Impact of 10% increase on sector 2 for the household’s expenditure
merge 1:m sec using `hhexp', nogen keep(3)

gen new_expenditure = expenditure*(1+total)
//Total amount of money devoted to indirect taxes
gen indirect_tax = total*expenditure

{title:Author:}

{pstd}
Paul Corral{break}
The World Bank - Poverty and Equity Global Practice {break}
Washington, DC{break}
pcorralrodas@worldbank.org{p_end}


{pstd}
Any error or omission is the author's responsibility alone.


