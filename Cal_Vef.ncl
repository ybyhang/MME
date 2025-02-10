function AFC_ACC(model_ano,obs_ano,nlon,nlat)
 
begin
 
  ; 1. setup
  ; 1-1. definition of variable
  acc     = new((/1/),"float", 1e20)
 
  ; 1-2. constant value
  pi = 3.14159
  lat=model_ano&lat
 
  ; 2. mail calculation
  wlat    = cos(lat*pi/180.0)
  wlat2   = conform(model_ano(lat|:,lon|:),wlat,(/0/))
  v_model = sum(wlat2*(model_ano^2))
  v_obs   = sum(wlat2*(obs_ano^2))
  cov     = sum(wlat2*model_ano*obs_ano)
  acc     = cov / sqrt(v_model*v_obs)
 
;  printVarSummary(wlat2)
 
  delete(wlat)
  delete(wlat2)
  delete(v_model)
  delete(v_obs)
 
  return(acc)
 
end

;===============================================================

;function AFC_RMSE(model_ano,obs_ano, nlon,nlat)
function AFC_RMSE(model_ano,obs_ano)
 
begin
 
  ; 1. setup
  ; 1-1. definition of variable
  rms      = new((/1/),"float", 1e20)
 
  ; 1-2. constant value
  pi=3.14159
  lat=model_ano&lat
  
  ; 2. mail calculation
  wlat  = cos(lat*pi/180.0)
  wlat2 = conform(model_ano(lat|:,lon|:),wlat,(/0/))
  rms   = sqrt(sum(wlat2*((model_ano-obs_ano)^2))/sum(wlat2))
  
  ; 3. release memory
  delete(wlat)
  delete(wlat2)
  
  ; 4. output
  return(rms)
 
end
