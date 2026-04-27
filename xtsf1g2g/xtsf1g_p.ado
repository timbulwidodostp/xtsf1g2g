*! version 1.0.0  6Jul2020
*! version 1.1.0  8Jul2020


capture program drop xtsf1g_p
program define xtsf1g_p
	version 14
	syntax newvarname [if] [in] , [ xb te_jlms_mean te_jlms_mode te_bc u_mean u_mode te_lb te_ub RESIDuals ]
	marksample touse, novarlist
	tempname mysample
	//display "|`varlist'|"
	local case : word count `xb' `te_jlms_mean' `te_jlms_mode' `te_bc' `residuals' `u_mean' `u_mode' `te_lb' `te_ub'
	if `case' >1 {
		display "{err}only one statistic may be specified"
	exit 498
	}
	if `case' == 0 {
		local n n
		display "expected te, residuals, or alpha"
	}
	generate `mysample' = e(sample)
	quietly summarize `mysample' if `mysample' == 0
	if r(N) > 0 {
		display "{text} (" as result r(N) "{text} missing values generated)"
	}
	if "`xb'" != "" {
		quietly generate `varlist' = .
		mata: st_store(., st_local("varlist"), st_local("mysample"), st_matrix("e(xb)"))
		label variable `varlist' "Linear prediction, bie"
	}
	if "`te_jlms_mean'" != "" {
		quietly generate `varlist' = .
		mata: st_store(., st_local("varlist"), st_local("mysample"), st_matrix("e(eff_mean)"))
		label variable `varlist' "Efficiency, JLMS:= exp(-E[ui|ei])"
	}
  if "`te_lb'" != "" {
		quietly generate `varlist' = .
		mata: st_store(., st_local("varlist"), st_local("mysample"), st_matrix("e(eff_lb)"))
		label variable `varlist' "Lower bound of  exp(-E[ui|ei])"
	}
  if "`te_ub'" != "" {
		quietly generate `varlist' = .
		mata: st_store(., st_local("varlist"), st_local("mysample"), st_matrix("e(eff_ub)"))
		label variable `varlist' "Upper bound of  exp(-E[ui|ei])"
	}
  if "`te_jlms_mode'" != "" {
		quietly generate `varlist' = .
		mata: st_store(., st_local("varlist"), st_local("mysample"), st_matrix("e(eff_mode)"))
		label variable `varlist' "Efficiency, Mode:= exp(-M[ui|ei])"
	}
  if "`te_bc'" != "" {
		quietly generate `varlist' = .
		mata: st_store(., st_local("varlist"), st_local("mysample"), st_matrix("e(eff_bc)"))
		label variable `varlist' "Efficiency, BC:= E[exp(-ui)|ei]"
	}
	if "`residuals'" != "" {
		quietly generate `varlist' = .
		mata: st_store(., st_local("varlist"), st_local("mysample"), st_matrix("e(residuals)"))
		label variable `varlist' "Residuals, bie"
	}
  if "`u_mean'" != "" {
		quietly generate `varlist' = .
		mata: st_store(., st_local("varlist"), st_local("mysample"), st_matrix("e(u_mean)"))
		label variable `varlist' "E[ui|ei]"
	}
  if "`u_mode'" != "" {
		quietly generate `varlist' = .
		mata: st_store(., st_local("varlist"), st_local("mysample"), st_matrix("e(u_mode)"))
		label variable `varlist' "M[ui|ei]"
	}
end
