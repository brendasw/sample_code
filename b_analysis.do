* b_analysis.do:  This script reads the "clean_data.dta" generate from a_assembling.do.
*                  carries out all analysis in section B, 
*                  and outputs two graphs and two latex files for tables.

*Set Path and Load Data
use clean_data, clear

* Generate group identifier for four groups
gen group="public, two-year colleges"
replace group="public, four-year colleges" if public==1 & degree_bach==1
replace group="private, four-year colleges" if public==2 & degree_bach==1
replace group="private, two-year colleges" if public==2 & degree_bach==2
encode group, gen(ngroup)

* Generate mean value for graphs
egen mean_grant_state = mean(grant_state), by(year degree_bach public)
replace mean_grant_state = mean_grant_state/1000000

* Draw line plot and save as png
xtline mean_grant_state, i(ngroup) t(year) overlay ytitle("Total Amount (M)") xtitle("Year")
graph export "grant_state.png", as(png) name("Graph")

* Draw another graph with same steps
egen mean_enroll = mean(enroll_ftug), by(year degree_bach public)
xtline mean_enroll , i(ngroup) t(year) overlay ytitle("Enrollment") xtitle("Year")
graph export "enrollment.png", as(png) name("Graph")

* Create treatment variables
gen treatment = 0
replace treatment=1 if public == 1 & degree_bach==2
gen time_treatment=0
replace time_treatment=1 if year == 2015

* Run DD regression 
eststo:regress enroll_ftug treatment##(time_treatment)
eststo:regress enroll_ftug treatment##(time_treatment) if ngroup == 4 | ngroup==2
eststo:regress enroll_ftug treatment##(time_treatment) if ngroup == 4 | ngroup==3
eststo:regress enroll_ftug treatment##(time_treatment) if ngroup == 4 | ngroup==1

eststo:regress enroll_ftug treatment##(time_treatment) grant_state
eststo:regress enroll_ftug treatment##(time_treatment) grant_state if ngroup == 4 | ngroup==2
eststo:regress enroll_ftug treatment##(time_treatment) grant_state if ngroup == 4 | ngroup==3
eststo:regress enroll_ftug treatment##(time_treatment) grant_state if ngroup == 4 | ngroup==1

* Output regression result table to latex
esttab using "regression.tex", style(tex) ///
cells(b(star fmt(3) label(coef.)) t(par fmt(2)) se(fmt(2))) ///
stats(N r2 r2_a, labels(N R-squared "Adj. R-squared")) ///
keep(1.treatment#1.time_treatment 1.treatment 1.time_treatment grant_state _cons) ///
order(1.treatment#1.time_treatment 1.treatment 1.time_treatment grant_state _cons) ///
mgroups("Treatment" "With Control",pattern(1 0 0 0 1 0 0 0) ///
span prefix(\multicolumn{@span}{c}{) suffix(}) ///
erepeat(\cmidrule(lr){@span})) ///
title("Regression DD Results") 

* Load data
import excel "schoolprofile201920.xlsx",clear
* Rename variables
rename (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP) (school_year district_id district_name school_id school_name grades_served safe_school african_american african_american_pct asian asian_pct economically_disadvantaged economically_disadvantaged_pct female female_pct hawaiian_pacisld hawaiian_pacisld_pct hispanic hispanic_pct limited_english_proficient limited_english_proficient_pct male male_pct native_american native_american_pct students_with_disabilities students_with_disabilities_pct total white white_pct african_american_female african_american_male asian_female asian_male hawaiian_pacisld_female hawaiian_pacisld_male hispanic_female hispanic_male native_american_female native_american_male white_female white_male)

* Keep only high schools
keep if grades_served == "Grades 9-12"
* Update data type to numeric
destring , replace
* Get summary statistics
eststo clear
estpost summarize *pct, listwise

* Output to latex
esttab using "descriptive.tex", style(tex) ///
cells("mean(fmt(%17.2fc)) sd(fmt(%17.2fc)) min max count") ///
nonumber nomtitle nonote noobs label collabels("Mean" "SD" "Min" "Max" "N")