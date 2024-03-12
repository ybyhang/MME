;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;*******************************************
function array_to_string(var_arr)
begin
  dims=dimsizes(var_arr)
  rank=dimsizes(dims)
  if rank.gt.1
    print("This function is for 1-D arrays")
    exit
  end if
  var_str=""
  if isatt(var_arr,"join")
    spc=var_arr_at_join
  else
    spc=" "
  end if

  do i = 0,dims-2
    var_str=var_str+var_arr(i)+spc
  end do
  var_str=var_str+var_arr(dims-1)
  return(var_str)
end

function string_to_array(str)
begin
  if .not.isatt(str,"separator")
    str_at_separator=","
    cmd="echo "+str+" | tr [:blank:] ',' "
    str=systemfunc(cmd)
  end if
  nstr=systemfunc("echo "+str+" | tr "+str_at_separator+" \\n | wc -l")
  istr=stringtoint(nstr)
  str_arr=new((/istr/),"string")

  do i = 0, istr-1
    CMD="echo "+str+" | awk -F"
    CMD=CMD+str_at_separator+" '{print $"+(i+1)+"}'"
    str_arr(i)=systemfunc(CMD)
  end do
  return(str_arr)
end
;*******************************************
begin
;************************************************
; 1. set parameters
;************************************************
  Var   = (/"t2m","prec","sst"/) ; t2m or tmp2m
  nvar  = dimsizes(Var)

  hcst_set = 2019

  syr    = 1991  ; 1979 for NCEP R2, 1982 for GHCN
  eyr    = 2010
  yyyy   = ispan(syr,eyr,1)
  nyr    = eyr-syr+1

  nlon   = 144
  nlat   = 73
  month  = (/"JFM","FMA","MAM","AMJ","MJJ","JJA","JAS","ASO","SON","OND","NDJ","DJF"/)
  nmon   = dimsizes(month)
 
  Model  = (/"APCC_SCOPS","BCC_CSM1.1M","BOM_ACCESS-S2","CMCC_SPS3.5","CWB_TCWB1Tv1.1",\
             "ECCC_CANSIPSv2.1","HMC_SL-AV", "JMA_MRI-CPS","KMA_GLOSEA","METFR_SYS8",\
             "NASA_GEOS-S2S-2.1","NCEP_CFSv2","PNU_CGCMv2.0","UKMO_GLOSEA6"/)

  nModel = dimsizes(Model)

  FillValue = 1e20

  OutDir = "/MME"
;*******************************************
; 2. read input file & cal. anomaly
;*******************************************
  indir = "/DATA/HINDCAST"+hcst_set+"/" 

  do ivar = 0, nvar-1

  do imon = 0, nmon-1
  
    u200 = new((/nModel,nyr,nlat,nlon/),"float",FillValue)      
    u202 = new((/nModel,nlat,nlon/),"float",FillValue)      

    do i = 0, nModel-1 
      infil1 = indir + Model(i) + "/" + Var(ivar) + "_anom_" + syr + eyr + "_" + month(imon) + ".nc"
      infil2 = indir + Model(i) + "/" + Var(ivar) + "_clim_" + syr + eyr + "_" + month(imon) + ".nc"
      in1    = addfile(infil1,"r")
      dat1   = in1->$Var(ivar)$
      u200(i,:,:,:) = dat1(:,:,:)

      in2    = addfile(infil2,"r")
      dat2   = in2->$Var(ivar)$
      u202(i,:,:) = dat2(:,:)

      delete(infil1)
      delete(in1)
      delete(dat1)
      delete(infil2)
      delete(in2)
      delete(dat2)
    end do                                        ; year

    u200!0      = "model"
    u200&model  = ispan(1,nModel,1)

    u202!0      = "model"
    u202&model  = ispan(1,nModel,1)

    clim1       = dim_avg_n_Wrap(u200,0)
    clim2       = dim_avg_n_Wrap(u202,0)

;*******************************************
; 3. write output files
;*******************************************
    if(.not.isfilepresent(OutDir))then
       system("mkdir -p " + OutDir)
    end if

    outfil1 = OutDir + "/" + Var(ivar) + "_anom_" + syr + eyr + "_" + month(imon) + ".nc"
    system("/bin/rm -f "+outfil1)
    fout1 = addfile(outfil1,"c")
    fout1->$Var(ivar)$ = clim1

    outfil2 = OutDir + "/" + Var(ivar) + "_clim_" + syr + eyr + "_" + month(imon) + ".nc"
    system("/bin/rm -f "+outfil2)
    fout2 = addfile(outfil2,"c")
    fout2->$Var(ivar)$ = clim2

    globalAtt                    = True
    globalAtt@history            = "Created by YBYhang" + " At " + systemfunc("date")
    globalAtt@title              = "Anomaly for " + Var(ivar) 
    globalAtt@hindcast_period    = sprinti("%0.4i",syr) + "-" + sprinti("%0.4i",eyr)
    globalAtt@MME_Models         = array_to_string(Model) 
    fileattdef( fout1, globalAtt )
    fileattdef( fout2, globalAtt )

    delete(u200)
    delete(clim1)
    delete(outfil1)
    delete(u202)
    delete(clim2)
    delete(outfil2)

  end do                          ; month

  end do                          ; variable
end
