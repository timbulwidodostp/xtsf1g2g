*! version 1.0.0  25May2020
*! version 1.0.1  26May2020
*! version 1.1.0  28May2020
*! version 1.2.0  1Jun2020
*! version 1.2.1  6Jul2020
*! version 1.2.2  11Aug2020
*! version 1.3.0  19Aug2020
*! version 1.3.1  31Aug2020
*! author Oleg Badunenko


if(c(MP)){
	set processors 1
}

// 		xtsf1g depvar [indepvars] [if] [in] [, options]

// 		cost
// 		model
// 		distribution(hnormal, tnormal)
// 		eti
// 		u0imean(varlist[, noconstant])
// 		u0ilnvariance(varlist[, noconstant])
// 		vitlnvariance(varlist[, noconstant])
// 		celessthanone
// 		level


capture program drop xtsf1g
program define xtsf1g, eclass
version 14

  if !replay() {

  syntax varlist(numeric fv min=2) [if] [in]                  ///
		[, noCONStant COST Distribution(string) ///
    UILNVariance(string) VITLNVariance(string) UIMean(string) ///
    CELESSTHANONE ITERate(integer 102) TRACElevel(string) ///
    LEVEL(string) NOLOG ] ///
    [noCI] [noPValues] [noOMITted] [noEMPTYcells] ///
    [VSQUISH] [BASElevels] [ALLBASElevels] [noFVLABel] ///
    [fvwrap(passthru)] [fvwrapon(passthru)] ///
		[CFORMAT(passthru)] [PFORMAT(passthru)] ///
    [SFORMAT(passthru)] [nolstretch]

  tempname b V n1 nt1 R2 R2adj aic bic llopt  ///
   rez fitted shat RSS mypanelvar mytimevar convstatus ///
   u_mean u_mode eff_mean eff_mode eff_bc eff_lb eff_ub ///
   mylevel iter dist uizeromean modelcoefs modelfn ///
   myprod function cnames vitlnvarianceN uilnvarianceN uimeanN

  // handle specifications of uimean uilnvariance vitlnvariance
  foreach opt in uimean uilnvariance vitlnvariance {
		if "``opt''" != "" {
			local `opt'opt ``opt''
			tokenize "``opt'opt'", parse(,)
			fvunab `opt' : `1'
			if "`s(fvops)'" == "" {
		 		confirm numeric var ``opt''
			}
      /* noCONStant */
			if "`3'" != "" {
				local l = length(`"`3'"')
				if `"`3'"' == bsubstr("noconstant", /*
					*/ 1,max(6,`l')) {
					local `opt'nocns "noconstant"
				}
				else {
					di as err "`3' invalid"
					exit 198
				}
			}
		}
	}
  // handle level
  if ("`level'" == "") {
    local mylevel 95
  }
  else 	if `level' < 10 |  `level' > 99.99 {
		display "{p 1 1 7}{error}level() must be between 10 and 99.99 inclusive{p_end}"
		exit 198
	}
  else {
    local mylevel `level'
  }

  // handle distribution and uizeromean
  // dist 1: truncated normalden
  // dist 0: halfnormal
  local distribution = substr("`distribution'", 1, 1)
  if "`uimean'" != "" { // uimean is specified
    if upper("`distribution'") == "H" {
      display as error "distribution() cannot be 'hnormal' if uimean() is specified"
      exit 198
    }
    else if "`distribution'" == "" | upper("`distribution'") == "T" {
      local dist 1
      local uizeromean 0
    }
    else {
			display as error "distribution() is not appropriate"
			exit 198
		}
  }
  else { // uimean is empty
    if "`distribution'" == "" | upper("`distribution'") == "H" {
      local dist 0
      local uizeromean 1
    }
    else if upper("`distribution'") == "T" {
      local dist 1
      local uizeromean 0
    }
    else {
			display as error "distribution() is not appropriate"
			exit 198
		}
  }

  // handle iterate
  if `iterate' < 0  {
		display as error " iterate() must be greater than 0"
		exit 198
	}

  // handle tracelevel
  if "`nolog'" == "" {
    if "`tracelevel'" == ""{
      local tracelevel "value"
    }
    if "`tracelevel'" != "none" & "`tracelevel'" != "value"  & ///
   "`tracelevel'" != "tolerance" & "`tracelevel'" != "step" & ///
   "`tracelevel'" != "paramdiffs" & "`tracelevel'" != "params" & ///
   "`tracelevel'" != "gradient" & "`tracelevel'" != "hessian" {
      di as error "tracelevel() can be specified as follows"
      di as input "none, value, tolerance, step, paramdiffs, params, gradient, or hessian"
      di as text "see help for " as result "mf_optimize##i_tracelevel" as text " for details"
      exit 198
    }
  }
  else {
    local tracelevel "none"
  }


  // handle production/cost function
	if "`cost'" == "" {
		local myprod = -1
		local function "production"
	}
	else {
		local myprod = 1
		local function "cost"
	}

	marksample touse
	// handle the lists
	gettoken depvar indepvars : varlist
	_fv_check_depvar `depvar'
	_rmcoll `indepvars' if `touse', expand `constant'
	local indepvars `r(varlist)'

  markout `touse' `vitlnvariance' `uilnvariance' `uimean'

  quietly count if `touse'==1
	if r(N) == 0 {
		error 2000
	}

  quietly xtset
  local mypanelvar `r(panelvar)'
  local mytimevar `r(timevar)'

  //   regressors
  if "`constant'" == "" {
    local cnames "`indepvars' _cons"
  }
  else {
    local cnames "`indepvars'"
  }

  //   noise
  if "`vitlnvariance'" != "" {
    local vitlnvarianceN = ""
    foreach lname of local vitlnvariance{
      local vitlnvarianceN = "`vitlnvarianceN' ln[var(vit)]:`lname'"
    }
    if "`vitlnvariancenocns'" == "" {
      local cnames "`cnames' `vitlnvarianceN' ln[var(vit)]:_cons"
    }
    else {
      local cnames "`cnames' `vitlnvarianceN'"
    }
  }
  else {
    local cnames "`cnames' ln[var(vit)]:_cons"
  }

  //   inefficiency
  if "`uilnvariance'" != "" {
    local uilnvarianceN = ""
    foreach lname of local uilnvariance{
      local uilnvarianceN = "`uilnvarianceN' ln[var(ui)]:`lname'"
    }
    if "`uilnvariancenocns'" == "" {
      local cnames "`cnames' `uilnvarianceN' ln[var(ui)]:_cons"
    }
    else {
      local cnames "`cnames' `uilnvarianceN'"
    }
  }
  else {
    local cnames "`cnames' ln[var(ui)]:_cons"
  }

  //   inefficiency mean
  if "`uimean'" != "" {
    local uimeanN = ""
    foreach lname of local uimean{
      local uimeanN = "`uimeanN' E[ui|z]:`lname'"
    }
    if "`uimeannocns'" == "" {
      local cnames "`cnames' `uimeanN' E[ui|z]:_cons"
    }
    else {
      local cnames "`cnames' `uimeanN'"
    }
  }
  else if "`uizeromean'" == "0" {
    local cnames "`cnames' E[ui|z]:_cons"
  }

  mata: xtsf1g_vykonaty("`depvar'", "`indepvars'", "`touse'", "`constant'",  ///
    "`mypanelvar'",  "`mytimevar'", "`cost'", "`celessthanone'",             ///
    "`uizeromean'", "`uimean'", "`uimeannocns'",                             ///
    "`uilnvariance'", "`uilnvariancenocns'",                                 ///
    "`vitlnvariance'", "`vitlnvariancenocns'",                               ///
    "`b'", "`V'", "`n1'", "`nt1'",  "`R2'", "`R2adj'",  "`aic'", "`bic'",    ///
    "`u_mean'", "`u_mode'",                                                  ///
    "`eff_mean'", "`eff_mode'", "`eff_bc'",  "`eff_lb'", "`eff_ub'",         ///
    "`iterate'", "`tracelevel'", "`convstatus'", "`mylevel'",                ///
    "`rez'", "`fitted'", "`shat'", "`RSS'", "`llopt'")



  matrix colnames `b'        = `cnames'
  matrix rownames `V'        = `cnames'
	matrix colnames `V'        = `cnames'
  ereturn post `b' `V', esample(`touse') buildfvinfo depname("`depvar'")
  matrix colnames `u_mean'   = "UMean"
  matrix colnames `u_mode'   = "UMode"
	matrix colnames `eff_mean' = "EfficiencyMean"
  matrix colnames `eff_mode' = "EfficiencyMode"
  matrix colnames `eff_bc'   = "EfficiencyBC"
  matrix colnames `eff_lb'   = "EfficiencyCiLb"
  matrix colnames `eff_ub'   = "EfficiencyCiUb"

  ereturn matrix eff_ub      = `eff_ub'
  ereturn matrix eff_lb      = `eff_lb'
  ereturn matrix eff_bc      = `eff_bc'
  ereturn matrix eff_mode    = `eff_mode'
  ereturn matrix eff_mean    = `eff_mean'
  ereturn matrix u_mode      = `u_mode'
  ereturn matrix u_mean      = `u_mean'
  ereturn scalar r2          = `R2'
	ereturn scalar r2_a        = `R2adj'
	ereturn scalar aic         = `aic'
	ereturn scalar bic         = `bic'
	ereturn scalar N           = `n1'
	ereturn scalar sumTi       = `nt1'
  ereturn scalar shat        = `shat'
  ereturn scalar RSS         = `RSS'
  ereturn scalar converged   = `convstatus'
  ereturn scalar level       = `mylevel'
  ereturn scalar ll          = `llopt'
	ereturn matrix residuals   = `rez'
	ereturn matrix xb          = `fitted'


  ereturn local predict "xtsf1g_p"
	ereturn local cmd   "xtsf1g"
	ereturn local cmdline "`0'"

  }
	if replay() {
    syntax, [LEVel(real `c(level)')] [noCI] [noPValues] [noOMITted] [noEMPTYcells] [VSQUISH] [BASElevels] [ALLBASElevels] [noFVLABel] [fvwrap(passthru)] [fvwrapon(passthru)] ///
		[CFORMAT(passthru)] [PFORMAT(passthru)] [SFORMAT(passthru)] [nolstretch]
  }
  if "`nolog'" == "" {
    display
  display as result "Sample:" as input "{hline 22}
  display as input " Number of obs    " as text "= " as result `nt1'
  display as input " Number of groups " as text "= " as result `n1'
  display as result "Diagnostics:" as input "{hline 17}
  display as input " R-squared        " as text "= " as result  %5.4f `R2'
  display as input " Adj R-squared    " as text "= " as result  %5.4f `R2adj'
  display as input " AIC              " as text "= " as result  %5.4f `aic'
  display as input " BIC              " as text "= " as result  %5.4f `bic'
  display as input " Root MSE         " as text "= " as result  %5.4f `shat'
  display as input "{hline 29}"

		display as input _newline " The first-generation estimator of"
    display as text " the " as input "`function' " as text "stochastic frontier model for panel data,"
    display as text " where effciency is" as input " time-invariant"
    display

		ereturn display, level(`mylevel')	`ci' `pvalues' `omitted' `emptycells' `vsquish' `baselevels' `allbaselevels' `fvlabel' `fvwrap' `fvwrapon' `cformat' `pformat' `sformat' `lstretch'
	}

end



capture mata mata drop xtsf1g_vykonaty()

mata:

void xtsf1g_vykonaty( string scalar depvar,                                  ///
  string scalar indepvars, string scalar touse,  string scalar constant, ///
  string scalar mypanelvar, string scalar mytimevar, ///
  string scalar cost, string scalar celessthanone, ///
  string scalar uizeromean0, string scalar uimean, string scalar uimeannocns, ///
  string scalar uilnvariance, string scalar  uilnvariancenocns, ///
  string scalar vitlnvariance, string scalar vitlnvariancenocns, ///
  string scalar bsname,    string scalar vsname,  ///
  string scalar n1name,    string scalar nt1name,  ///
  string scalar R2name,    string scalar R2adjname, ///
  string scalar aicname,   string scalar bicname,
  string scalar u1_name, string scalar u2_name, ///
  string scalar eff1_name, string scalar eff2_name, string scalar eff3_name, ///
  string scalar eff_lb,  string scalar eff_ub, ///
  string scalar iter0,     string scalar tracelevel ,                       ///
  string scalar convstatus,   string scalar level0,                     ///
  string scalar rezname,   string scalar xbname,                            ///
  string scalar shatname,  string scalar RSSname, string scalar LLname)
{

  eff_t_inv = 1

  model = 99999
  level     = strtoreal(level0)
  alpha1    = (100-level)/100
  uizeromean= strtoreal(uizeromean0)

  ids0      = st_data(., mypanelvar, touse)
	ids       = panelsetup(ids0, 1)
	ids       = ids, ids[,2] - ids[,1] :+ 1
 	nobs      = rows(ids)

//   101

  Ti0       = st_data(., mytimevar, touse)
	Ti        = Ti0 :- min(Ti0) :+ 1
  nt        = rows(Ti)
	tLESSmaxT = J(nt,1,.)
  for (i = 1; i <= nobs; i++) {
    tymch1  = panelsubmatrix(Ti,  i, ids)
    tLESSmaxT[ids[i,1]..ids[i,2]] = tymch1 :- max( tymch1 )
  }
	// 102

  // data
  yit       = st_data(., depvar, touse)

  xit       = st_data(., indepvars, touse)
  if (constant == "") {
    xit = xit, J(nt, 1, 1)
  }
  k         = cols(xit)

//   103
  if (vitlnvariance == "") {
    zvit    = J(nt, 1, 1)
    kv      = 1
  }
  else {
    zvit    = st_data(., vitlnvariance, touse)
    if (vitlnvariancenocns == "") {
      zvit  = zvit, J(nt, 1, 1)
    }
    kv      = cols(zvit)
  }
//   zvit

//   104
  if (uilnvariance == ""){
    zui     = J(nobs, 1, 1)
    ku      = 1
  }
  else {
    zui0    = st_data(., uilnvariance, touse)
    if (uilnvariancenocns == "") {
      zui0  = zui0, J(nt, 1, 1)
    }
    ku      = cols(zui0)
    zui = J(nobs,ku,.)
    for (i = 1; i <= nobs; i++) {
      zui[i,] = mean( panelsubmatrix(zui0,  i, ids) )
    }
  }
//   zui


//   105
// if truncated, zdeli, needs to be a column of ones and kdel needs to be 1
  if (uimean == "") {
    if(uizeromean == 1){
      zdeli   = J(nobs, 0, 1)
      kdel    = 0
    }
    else {
      zdeli   = J(nobs, 1, 1)
      kdel    = 1
    }
  }
  else {
    zdeli0  = st_data(., uimean, touse)
    if (uimeannocns == "") {
      zdeli0 = zdeli0, J(nt, 1, 1)
    }
    kdel    = cols(zdeli0)
    zdeli = J(nobs,kdel,.)
    for (i = 1; i <= nobs; i++) {
      zdeli[i,] = mean( panelsubmatrix(zdeli0,  i, ids) )
    }
  }
//   zdeli


//   1054
  if (cost == ""){
    s = -1
    sn1 = -1
  }
  else {
    s = 1
    if (celessthanone == ""){
      sn1 = 1
    }
    else {
      sn1 = -1
    }
  }

//   107

  // starting values

  xxi       = cross(xit,xit)
  ols_b     = invsym( xxi ) * cross(xit,yit)
  ols_res   = yit - xit * ols_b
  ols_res_m = J(nobs,1,.)
  for (i = 1; i <= nobs; i++) {
    ols_res_m[i] = mean( panelsubmatrix(ols_res,  i, ids) )
  }
  ols_res_m_abs = abs(ols_res_m)

  olsZv_b     = invsym( cross(zvit, zvit) ) * cross(zvit,(log(ols_res:^2)))
//   olsZv_b
  olsZu_b     = invsym( cross(zui, zui) ) * cross(zui,(log(ols_res_m:^2)))
//   olsZu_b
  olsZd       = invsym( cross(zdeli, zdeli) ) * cross(zdeli,ols_res_m_abs)
//   olsZd


  if (kdel == 0){
    theta0  = 1.0*ols_b \ .75*olsZv_b \ .75*olsZu_b
  }
  else {
    theta0  = 1.0*ols_b \ .75*olsZv_b \ .75*olsZu_b \ olsZd
  }

//   1072

  if (eff_t_inv == 1) {
    theta0 = theta0'
  }
  else {
    if (model == 3) {
      theta0 = theta0', 0
    }
    else {
      theta0 = theta0', 0, 0
    }
  }
//   theta0


//   1071
  Ktheta    = length(theta0)

  // BC1992: 3
  // K1990modified: 2
  // K1990 :1

//   108
//   model
//   uizeromean
//   eff_t_inv
//   109
//   tracelevel
//   iter0
//   110
  iter = strtoreal(iter0)
//   iter

  myscalars = k, kv, ku, kdel, Ktheta, nobs, nt, s, uizeromean, eff_t_inv, model
//   myscalars

  S  = optimize_init()
  optimize_init_evaluator(S, &xtsf12gen2optimize())
  optimize_init_valueid(S, "log-likelihood")
  optimize_init_iterid(S, "iter")
  optimize_init_evaluatortype(S, "gf2")
	optimize_init_technique(S, "nr")
  optimize_init_tracelevel(S, tracelevel)
  optimize_init_conv_maxiter(S, iter)
//   optimize_init_singularHmethod(S, "hybrid")
  optimize_init_argument(S, 1, yit)
	optimize_init_argument(S, 2, xit)
	optimize_init_argument(S, 3, zui)
	optimize_init_argument(S, 4, zvit)
	optimize_init_argument(S, 5, zdeli)
	optimize_init_argument(S, 6, ids)
	optimize_init_argument(S, 7, Ti)
	optimize_init_argument(S, 8, tLESSmaxT)
	optimize_init_argument(S, 9, myscalars)
	optimize_init_params(S, theta0)
  if (tracelevel != "none"){
    printf("\n\n{input:Log-likelihood maximization using} {result:optimize()} \n\n")
  }
//   211
	bh        = optimize(S)
  vh        = optimize_result_V_oim(S)
//   bh
//   vh
//   211
  st_matrix(bsname,        bh)
// 	212
  //bcov
	st_matrix(vsname,        vh)

  // efficiencies

  bet       = bh[1..k]
  gv        = bh[(k+1)..(k+kv)]
  gu        = bh[(k+kv+1)..(k+kv+ku)]

  xb        = xit * bet'
  eit       = yit - xb

  sigu2i    = exp(zui * gu')

  sigv2it   = exp(zvit * gv')

  if(uizeromean == 0){
    if (kdel == 0){
      mui   = J(nobs, 1, 1)
    }
    else {
      delta = bh[(k+kv+ku+1)..(k+kv+ku+kdel)]
      mui   = zdeli * delta'
    }
  }
  else {
    mui     = J(nobs, 1, 0)
  }
//   lmdi      = mui:/sigu2i
  if(eff_t_inv == 1){
    Git     = J(nt, 1, 1)
  }
  else {
    if (model == 3){
      eta   = bh[Ktheta]
      Git   = exp(-eta*tLESSmaxT)
    }
    else if (model == 2){
      eta   = bh[(Ktheta-1) .. Ktheta]
      Git   = 1 :+ eta[1]*tLESSmaxT + eta[2]*tLESSmaxT:^2
    } else if (model == 1){
      eta   = bh[(Ktheta-1) .. Ktheta]
      Git   = (1 :+ exp(eta[1]*Ti + eta[2]*Ti:^2)):^(-1)
    }
  }
// 219
  u_mean = u_mode = te_jlms_mean = te_jlms_mode = te_bc = te_l = te_u = J(nt, 1, 0)
  for (i = 1; i <= nobs; i++) {
    ei      = panelsubmatrix(eit,  i, ids)
    sigv2i  = panelsubmatrix(sigv2it,  i, ids)
    Gi      = panelsubmatrix(Git,  i, ids)
    s2i     = (1/sigu2i[i] + sum(Gi:^2:/sigv2i))^(-1)
    mi      = (mui[i]/sigu2i[i] + s*sum(ei:*Gi:/sigv2i))*s2i
    zi      = mi / sqrt(s2i)
    p_mean  = mi + sqrt(s2i) * normalden(zi) / normal(zi)
    if (mi >= 0) {
      p_mode= mi
    }
    else {
      p_mode= 0
    }
    u_mean[ids[i,1]..ids[i,2]] = Gi*p_mean
    te_jlms_mean[ids[i,1]..ids[i,2]] = exp(sn1*u_mean[ids[i,1]..ids[i,2]])
    u_mode[ids[i,1]..ids[i,2]] = Gi*p_mode
    te_jlms_mode[ids[i,1]..ids[i,2]] = exp(sn1*u_mode[ids[i,1]..ids[i,2]])
    te_bc[ids[i,1]..ids[i,2]] =
      exp(sn1*mi*Gi + 0.5*s2i*Gi:^2) :* normal(zi :+ sn1 * sqrt(s2i):*Gi)/normal(zi)
    zl    = invnormal( 1 - alpha1 / 2 * normal(zi) )
    zu    = invnormal( 1 - ( 1 - alpha1/2 ) * normal(zi) )
    te_l[ids[i,1]..ids[i,2]]  = exp(Gi*(sn1*mi - zl*sqrt(s2i)))
    te_u[ids[i,1]..ids[i,2]]  = exp(Gi*(sn1*mi - zu*sqrt(s2i)))
  }
//   220
//   te_jlms_mean
  st_matrix(u1_name,        u_mean)
//   221
  st_matrix(u2_name,        u_mode)
//   222
  st_matrix(eff1_name,        te_jlms_mean)
//   221
  st_matrix(eff2_name,        te_jlms_mode)
  st_matrix(eff3_name,        te_bc)
//   223
  st_matrix(eff_lb,        te_l)
//   224
  st_matrix(eff_ub,        te_u)
//   225

  // Diagnostics
  R2        = 1 - cross(eit,eit) / cross(yit,yit)
  R2a       = 1 - (1-R2) * (nt-1) / (nt-k-nobs)

  // Score
  shat2     = variance(eit)
  shat      = sqrt(shat2)
//   998
  RSS       = cross(eit, eit)
//   999
  aic       = log((nt-1)/nt*shat2)+1+2*(k+1)/nt
//   9991
	bic       = log((nt-1)/nt*shat2)+1+(k+1)*log(nt)/nt

  st_numscalar(n1name,     nobs)
// 	217
	st_numscalar(nt1name,    nt)
// 	218
	st_numscalar(R2name,     R2)
// 	219
	st_numscalar(R2adjname,  R2a)
// 	222
	st_numscalar(aicname,    aic)
// 	223
	st_numscalar(bicname,    bic)

  st_matrix(xbname,        xb)
// 	236
	st_numscalar(shatname,   shat)
//   237
  st_numscalar(RSSname,    RSS)
  st_numscalar(LLname,     optimize_result_value(S))
//   238
  st_numscalar(convstatus, optimize_result_converged(S))
//   239
  st_matrix(rezname,       eit)
//   240

}
end


capture mata mata drop xtsf12gen2optimize()
mata:
void xtsf12gen2optimize(real scalar todo, real vector theta,                 ///
	real vector yit,   real matrix xit,                                        ///
  real matrix zui,   real matrix zvit, real matrix zdeli,                    ///
	real matrix ids,   real colvector timevar, real vector tLESSmaxT,          ///
  real rowvector scalars, ///
	llf, grad, H)
{
  real vector bet, gv, gu, eit, sigu2i, sigv2it, delta, mui, lmdi, Git, ///
    eta, ei, sigv2i, Gi, c0, c0a, c0b, c0c, c2, c3, tBC1, tBC2, ///
    Gk, c0d, c0e

  real scalar keta, Ti, sstart, c2s, tymch1, c1, a1i, a2i, d1, d2, d3, d4, ///
    k, kv, ku, kdel, Ktheta, nobs, nt, s, uizeromean, eff_t_inv, model

  real matrix gb, ggu, ggv, gdel, geta, Hb, Hbgu, Hbdel, Hbgv, Hgvgu, ///
    Hgvdel, Hgv, Hdel, Hdelgu, Hgu, Hbeta, Hdeleta, Hetagu, Hetagv, Heta, ///
    xi, zvi, tSK

  k         = scalars[1]
  kv        = scalars[2]
  ku        = scalars[3]
  kdel      = scalars[4]
  Ktheta    = scalars[5]
  nobs      = scalars[6]
  nt        = scalars[7]
  s         = scalars[8]
  uizeromean = scalars[9]
  eff_t_inv = scalars[10]
  model     = scalars[11]

//   2001
  bet       = theta[1..k]
  gv        = theta[(k+1)..(k+kv)]
  gu        = theta[(k+kv+1)..(k+kv+ku)]
//   2002
  eit       = yit - xit * bet'
  sigu2i    = exp(zui * gu')
  sigv2it   = exp(zvit * gv')
//   2003
  if(uizeromean == 0){
//     20031
    if (kdel == 0){
//       200311
      mui   = J(nobs, 1, 1)
    }
    else {
//       200312
      delta = theta[(k+kv+ku+1)..(k+kv+ku+kdel)]
//       delta
      mui   = zdeli * delta'
//       zdeli
    }
  }
  else {
//     20033
    mui     = J(nobs, 1, 0)
  }
//   mui
//   2004
  lmdi      = mui:/sigu2i
//   2005
  if(eff_t_inv == 1){
//     20051
    Git     = J(nt, 1, 1)
    keta    = 0
  }
  else {
//     20052
    if (model == 3){
//       200521
      eta   = theta[Ktheta]
//       200522
      Git   = exp(-eta*tLESSmaxT)
//       200523
      keta  = 1
//       200524
    }
    else if (model == 2){
//       200525
      eta   = theta[(Ktheta-1) .. Ktheta]
//       200526
      Git   = 1 :+ eta[1]*tLESSmaxT + eta[2]*tLESSmaxT:^2
//       200527
      keta  = 2
    } else if (model == 1){
//       200528
      eta   = theta[(Ktheta-1) .. Ktheta]
//       200529
      Git   = (1 :+ exp(eta[1]*timevar + eta[2]*timevar:^2)):^(-1)
//       2005210
      keta  = 2
    }
  }
//   tymch2 = Git, timevar
//   tymch2[1..10,]

//     2006
  llf       = J(nobs,1,.)
  if (todo >= 1) {
    gb      = J(k, nobs, .)
    ggu     = J(nobs, ku, .)
    ggv     = J(kv, nobs, .)
    gdel    = J(nobs, kdel, .)
    geta    = J(nobs, keta, .)
  };

  if (todo >= 2) {
    Hb      = J(k, k, 0)
    Hbgu    = J(k, ku, 0)
    Hbdel   = J(k, kdel, 0)
    Hbgv    = J(k, kv, 0)
    Hgvgu   = J(kv, ku, 0)
    Hgvdel  = J(kv, kdel, 0)
    Hgv     = J(kv, kv, 0)
    Hdel    = J(kdel, kdel, 0)
    Hdelgu  = J(kdel, ku, 0)
    Hgu     = J(ku, ku, 0)
    Hbeta   = J(k, keta, 0)
    Hdeleta = J(kdel, keta, 0)
    Hetagu  = J(ku, keta, 0)
    Hetagv  = J(kv, keta, 0)
    Heta    = J(keta, keta, 0)
  };

//   2007
  for (i = 1; i <= nobs; i++) {
    ei      = panelsubmatrix(eit,  i, ids)
    sigv2i  = panelsubmatrix(sigv2it,  i, ids)
    Gi      = panelsubmatrix(Git,  i, ids)
    Ti      = ids[i,3]
    sstart  = (1/sigu2i[i] :+ sum(Gi:^2:/sigv2i))
    c0      = Gi:/sigv2i
    c0a     = Gi:^2 :/ sigv2i
    c0b     = ei:^2 :/ sigv2i
    c0c     = ei :/ sigv2i
    c2      = ei :* c0
    c2s     = sum(c2)
    tymch1  = lmdi[i] + s*c2s
    llf[i]  = -1/2*log(sstart) - 1/2*(mui[i]*lmdi[i] + sum(ei:^2:/sigv2i)) + 1/2*(tymch1^2)/sstart - Ti/2 * log(2*pi()) -  1/2*sum(log(sigv2i)) - 1/2*log(sigu2i[i]) - lnnormal(mui[i]/sqrt(sigu2i[i]) ) + lnnormal(tymch1/sqrt(sstart) )
//     3000
    if (todo >= 1) {
      xi    = panelsubmatrix(xit,  i, ids)
      zvi   = panelsubmatrix(zvit,  i, ids)
      c1    = (1/sigu2i[i] + sum(Gi:^2:/sigv2i))^(-1)

      c3    = cross( xi, Gi:/sigv2i )
      a1i   = mui[i]/sqrt(sigu2i[i])
      a2i   = tymch1 * sqrt(c1)
      d1    = normalden(a1i)/normal(a1i)
      d2    = normalden(a2i)/normal(a2i)
      d3    = (1 - d2*(a2i + d2))
      d4    = d1*(a1i + d1)
//       3001
      gb[ ,i]  = cross(xi,  c0c :- s*c0 * (lmdi[i]*c1 + s*c2s*c1 + sqrt(c1)*d2))

      ggu[i, ] = zui[i,]* (1/sigu2i[i]*(0.5*c1 + mui[i]*(0.5*mui[i] + 0.5*d1*sqrt(sigu2i[i]) - sqrt(c1)*d2) + a2i*(c1*a2i/2 - sqrt(c1)*mui[i] + c1*d2/2))-0.5)

      ggv[ ,i] = cross(zvi, 0.5*c1*c0a + 0.5*c0b :- 0.5 + a2i*sqrt(c1)*((a2i + d2)*0.5*sqrt(c1)*c0a - s*c2) - s*sqrt(c1)*d2*c2)

      gdel[i,] = zdeli[i,]/sigu2i[i] *(mui[i]*(c1/sigu2i[i] - 1) + s*c2s*c1 - d1 *sqrt(sigu2i[i]) + d2*sqrt(c1))
//       3002
      if(eff_t_inv == 0){
        if (model == 3){
          tBC1 = panelsubmatrix(tLESSmaxT,  i, ids)
          geta[i,] = c1*sum(c0a:*tBC1) - s*sqrt(c1)*d2*sum(c0c:*Gi:*tBC1) + sqrt(c1)*a2i*(sqrt(c1)*(a2i + d2)*sum(c0a:*tBC1) - s*sum(c0c:*Gi:*tBC1))
        }
        else if (model == 2){
          tBC2 = panelsubmatrix(tLESSmaxT,  i, ids), panelsubmatrix(tLESSmaxT,  i, ids) :^ 2
          geta[i,] = -c1 * cross(c0,tBC2) + s*sqrt(c1)*d2*cross(c0c,tBC2) - sqrt(c1)*a2i*(sqrt(c1)*(a2i + d2)*cross(c0,tBC2) - s*cross(c0c,tBC2) )
        }
        else if (model == 1){
          Gk   = Gi:^(-1) :- 1
          c0d  = Gi:^3:*Gk:/sigv2i
          c0e  = ei:*c0a:*Gk
          tSK  = panelsubmatrix(timevar,  i, ids), panelsubmatrix(timevar,  i, ids) :^ 2
          geta[i,] = c1 * cross(c0d, tSK) -  s * sqrt(c1) * d2 * cross(c0e, tSK) + sqrt(c1)*a2i*(sqrt(c1)*(a2i + d2)*cross(c0d, tSK) - s*cross(c0e,tSK) )
        }
      };
    }

//     4000
    if (todo >= 2){
      Hb      = Hb - cross(xi, xi :/ sigv2i) + c1 * c3 * c3' * d3

      Hbgu = Hbgu + s*c3 * zui[i,]*c1*(lmdi[i]*d3 - c1/sigu2i[i]*(lmdi[i] + s*sum(c2)) + sqrt(c1)/(2*sigu2i[i])*d2*(a2i*(a2i + d2) - 1))

      Hbdel   = Hbdel - s*c3 * (zdeli[i,] / sigu2i[i]*d3*c1)

      Hbgv    = Hbgv + cross(xi, -zvi :* c0c + s * zvi :* c0 * (sqrt(c1)*(a2i + d2))) - s * cross(xi,c0) * cross(zvi, -s*c1*c2*d3 + (c1^1.5*c0a)*(a2i + 0.5*d2*(1 - a2i*(a2i + d2))) )'

      Hgvgu = Hgvgu + cross(zvi, c1*s*c2*(mui[i]*d3 - sqrt(c1)*a2i/2*(1+d3)) + c1^1.5*a2i*0.5*c0a*(sqrt(c1)*a2i*0.5*(3+d3) - mui[i]*(1+d3)) + 0.5*c1^1.5*c0a*(sqrt(c1) + d2*(1.5*sqrt(c1)*a2i - mui[i])) - 0.5*c1^1.5*s*d2*c2) * zui[i,]/sigu2i[i]

      Hgvdel = Hgvdel + cross(zvi,-s*c1*c2*d3 + c0a*(0.5*c1^1.5*(a2i*(1+d3) + d2))) * zdeli[i,]/sigu2i[i]

      Hgv = Hgv +  cross(zvi,zvi:*c0a*0.5*c1*(-d2*a2i - a2i^2 -1)) + cross(zvi,c0a ) * cross(zvi,c0a)' *0.5*c1^2*(1 + 0.5*a2i^2*(3+d3) + d2*1.5*a2i) - 0.5 * cross(zvi,zvi :* c0b) + cross(zvi,zvi :* c2)*s*sqrt(c1)*(d2 + a2i) - (d2+a2i*(1+d3))*0.5*c1^1.5*s*(cross(zvi,c2) * cross(zvi,c0a)' + cross(zvi,c0a) *cross(zvi,c2)') + cross(zvi,c2) * cross(zvi,c2)' *c1*d3

      Hdel = Hdel + cross(zdeli[i,]/sigu2i[i] *(- 1 + d3*c1/sigu2i[i] + d4), zdeli[i,])

      Hdelgu = Hdelgu + cross(zdeli[i,],zui[i,])/sigu2i[i]*(c1^1.5/sigu2i[i]*0.5*a2i*(1+d3) - mui[i]*c1/sigu2i[i]*(1+d3) + d2*sqrt(c1)*(0.5*c1/sigu2i[i] - 1) - 0.5*d1*(mui[i]*(a1i + d1) - sqrt(sigu2i[i])) + mui[i] - s*c1*sum(c2))

      Hgu = Hgu + (c1/sigu2i[i]*(0.5*c1 + (sqrt(c1)*a2i - mui[i])^2) - 0.5*(c1 + (sqrt(c1)*a2i - mui[i])^2) + d1*mui[i]/4*(mui[i]*(a1i + d1) - sqrt(sigu2i[i])) + d2*(-d2*2*c1/sigu2i[i]*(mui[i]/sqrt(2) - sqrt(c1/8)*a2i)^2 - c1*a2i/sigu2i[i]*(mui[i] - sqrt(c1)*a2i/2)^2 + sqrt(c1)*mui[i]*(1 - c1/sigu2i[i]) - c1*a2i/2*(1 - 1.5*c1/sigu2i[i])))*cross(zui[i,],zui[i,])/sigu2i[i]
//       4001
      if(eff_t_inv == 0){
        if (model == 3){
//           40011
          Hbeta = Hbeta + s*cross(xi,c0:*tBC1)*sqrt(c1)*(a2i + d2) - s*cross(xi,c0)*c1*(-s*sum(c2:*tBC1)*d3 + sqrt(c1)*a2i*(1 + d3)*sum(c0a:*tBC1) + sqrt(c1)*d2*sum(c0a:*tBC1))

          Hdeleta = Hdeleta + ((sum(c0a:*tBC1)*c1^1.5*(a2i*(1+d3) + d2)-s*c1*sum(c2:*tBC1)*d3)*zdeli[i,]/sigu2i[i])'

          Hetagu = Hetagu + ((sum(c0a:*tBC1)*c1^1.5/sigu2i[i]*(sqrt(c1) -a2i*mui[i]*(1+d3) + sqrt(c1)*a2i^2*0.5*(3+d3) - d2*(mui[i] - 1.5*a2i*sqrt(c1))) + s*c1/sigu2i[i]*sum(c2:*tBC1)*(mui[i]*d3 - d2*0.5*sqrt(c1) - 0.5*sqrt(c1)*a2i*(1+d3)))*zui[i,])'

          Hetagv = Hetagv - cross(zvi,c0a:*tBC1)*c1*(1 + a2i^2 + a2i*d2) + sum(c0a:*tBC1)*cross(zvi,c0a)*c1^2*(1 + 0.5*a2i^2*(3 + d3) + 1.5*a2i*d2) + cross(zvi,c2:*tBC1)*s*sqrt(c1)*(d2 + a2i) + sum(c2:*tBC1)*cross(zvi,c2)*c1*d3 - (a2i*(1+d3) + d2)*s*c1^1.5*(0.5*sum(c2:*tBC1)*cross(zvi,c0a) + sum(c0a:*tBC1)*cross(zvi,c2))

          Heta = Heta - 2*c1*sum(c0a:*tBC1:^2)*(1 + a2i^2 + d2*a2i) + c1^2*sum(c0a:*tBC1)^2*(2 + a2i^2*(3 + d3) + 3*d2*a2i) + sum(c2:*tBC1:^2)*s*sqrt(c1)*(d2 + a2i) - 2*s*c1^1.5*sum(c2:*tBC1)*sum(c0a:*tBC1)*(d2 + a2i*(1 + d3)) + sum(c2:*tBC1)^2*c1*d3

        }
        else if (model == 2){
//           40012
          Hbeta = Hbeta - s*cross(xi,tBC2 :/ sigv2i)*sqrt(c1)*(a2i + d2) - s*(cross(xi,c0)) * cross(tBC2,c1*(s*c0c*d3 - sqrt(c1)*a2i*(1 + d3)*(c0) - sqrt(c1)*d2*(c0)))'

          Hdeleta = Hdeleta + cross(zdeli[i,], cross(tBC2,s*c1*c0c*d3 - c1^1.5*(a2i*(1+d3) + d2)*c0)' / sigu2i[i])

          Hetagu = Hetagu + cross(zui[i,],-cross(c0,tBC2)*c1^1.5/sigu2i[i]*(sqrt(c1) -a2i*mui[i]*(1+d3) + sqrt(c1)*a2i^2*0.5*(3+d3) - d2*(mui[i] - 1.5*a2i*sqrt(c1))) - cross(c0c,tBC2)*s*c1/sigu2i[i]*(mui[i]*d3 - d2*0.5*sqrt(c1) - 0.5*sqrt(c1)*a2i*(1+d3)))

          Hetagv = Hetagv + cross(zvi,tBC2 :* c0)*c1*(1 + a2i^2 + a2i*d2) - cross(zvi,c0a) * cross(c0,tBC2) *c1^2*(1 + 0.5*a2i^2*(3 + d3) + 1.5*a2i*d2) - cross(zvi,tBC2 :* c0c)*s*sqrt(c1)*(d2 + a2i) - cross(zvi,c2) * cross(c0c,tBC2)*c1*d3 + (a2i*(1+d3) + d2)*s*c1^1.5*(0.5*cross(zvi,c0a) * cross(c0c,tBC2) + cross(zvi,c2) * cross(c0,tBC2))

          Heta = Heta - c1*(1 + a2i^2 + a2i*d2)*cross(tBC2,tBC2 :/ sigv2i) + c1^2*(2 + a2i^2*(3 + d3) + d2*a2i*3) * cross( cross(c0,tBC2), cross(c0,tBC2)) - c1^1.5*s*(d2+a2i*(1+d3))*cross(cross(c0c,tBC2),cross(c0,tBC2)) + c1*d3*cross(cross(c0c,tBC2),cross(c0c,tBC2)) - c1^1.5*s*(d2 + a2i*(1+d3))*cross(cross(c0,tBC2),cross(c0c,tBC2))
        }
        else if (model == 1){
//           40013
          Hbeta = Hbeta +  s*cross(xi,tSK :* c0a:*Gk)*sqrt(c1)*(a2i + d2) - s*cross(xi,c0) * cross(tSK,c1*(-s*(ei:*c0a:*Gk)*d3 + sqrt(c1)*a2i*(1 + d3)*(c0d) + sqrt(c1)*d2*(c0d)))'
//           400131
          Hdeleta = Hdeleta + cross(zdeli[i,], s*cross(tSK, -s*c1*(c2:*Gi:*Gk)*d3 + c1^1.5*(a2i*(1+d3) + d2)*c0d)'/sigu2i[i])
//           400132
          Hetagu = Hetagu + cross(zui[i,], cross(c0d,tSK*c1^1.5/sigu2i[i]*(sqrt(c1) -a2i*mui[i]*(1+d3) + sqrt(c1)*a2i^2*0.5*(3+d3) - d2*(mui[i] - 1.5*a2i*sqrt(c1))) ) + cross(c2:*Gi:*Gk, tSK*s*c1/sigu2i[i]*(mui[i]*d3 - d2*0.5*sqrt(c1) - 0.5*sqrt(c1)*a2i*(1+d3)) ) )
//           400133
          Hetagv = Hetagv - cross(zvi,tSK :* c0d)*c1*(1 + a2i^2 + a2i*d2) + cross(zvi,c0a) * cross(c0d,tSK)*c1^2*(1 + 0.5*a2i^2*(3 + d3) + 1.5*a2i*d2) + cross(zvi,tSK:*c2:*Gi:*Gk)*s*sqrt(c1)*(d2 + a2i) + cross(zvi,c2) * cross(c2:*Gi:*Gk,tSK)*c1*d3 - (a2i*(1+d3) + d2)*s*c1^1.5*(0.5*cross(zvi,c0a) * cross(c2:*Gi:*Gk,tSK) + cross(zvi,c2) * cross(c0d,tSK))
//           400134
          Heta = Heta + c1*(1 + a2i^2 + a2i*d2) * cross(tSK, tSK :* c0d :*(1 :- 3*Gi:*Gk)) + c1^2*(2 + a2i^2*(3 + d3) + d2*a2i*3)*cross(cross(c0d,tSK), cross(c0d,tSK)) - s*sqrt(c1)*(a2i + d2)*cross(tSK,tSK :* c0e :*(1 :- 2*Gi:*Gk)) - c1^1.5*s*(d2 + a2i*(1 + d3))*(cross(cross(c0e,tSK), cross(c0d,tSK)) + cross(cross(c0d,tSK), cross(c0e,tSK))) + c1*d3*cross(cross(c0e,tSK), cross(c0e,tSK))
        }
      };
    }
  }

  if(eff_t_inv == 0){
    grad = gb', ggv', ggu, gdel, geta
  }
  else {
    grad = gb', ggv', ggu, gdel
  }

//   colsum(grad)

  if (uizeromean == 1){
    if (eff_t_inv == 1){
//       20301
      H = (Hb \ Hbgv' \ Hbgu'),
        (Hbgv \ Hgv \ Hgvgu'),
        (Hbgu \ Hgvgu \ Hgu)
    }
    else {
//       20302
      H = (Hb \ Hbgv' \ Hbgu' \ Hbeta'),
        (Hbgv \ Hgv \ Hgvgu' \ Hetagv'),
        (Hbgu \ Hgvgu \ Hgu \ Hetagu'),
        (Hbeta \ Hetagv \ Hetagu \ Heta)
//       20302
    }
  }
  else {
    if (eff_t_inv == 1){
//       20303
      H = (Hb \ Hbgv' \ Hbgu' \ Hbdel'),
        (Hbgv \ Hgv \ Hgvgu' \ Hgvdel'),
        (Hbgu \ Hgvgu \ Hgu \ Hdelgu),
        (Hbdel \ Hgvdel \ Hdelgu' \ Hdel)
    }
    else {
//       20304
      H = (Hb \ Hbgv' \ Hbgu' \ Hbdel' \ Hbeta'),
        (Hbgv \ Hgv \ Hgvgu' \ Hgvdel' \ Hetagv'),
        (Hbgu \ Hgvgu \ Hgu \ Hdelgu \ Hetagu'),
        (Hbdel \ Hgvdel \ Hdelgu' \ Hdel \ Hdeleta'),
        (Hbeta \ Hetagv \ Hetagu \ Hdeleta \ Heta)
    }
//     H
  }
//   return
//   2040
}

end
