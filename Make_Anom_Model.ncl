;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;*******************************************
; Basic Variables : PREC, T2M
;*******************************************
begin
;************************************************
; 1. set parameters
;************************************************
  Var    = (/"prec","t2m","sst"/) 
  nVar   = dimsizes(Var)

  syr    = 1991  
  eyr    = 2010
  yyyy   = ispan(syr,eyr,1)
  nyr    = eyr-syr+1

  nlon   = 144
  nlat   = 73
  month  = (/"JFM","FMA","MAM","AMJ","MJJ","JJA","JAS","ASO","SON","OND","NDJ","DJF"/)
  dir    = (/"JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"/)
  nmon   = dimsizes(month)
 
  Model = ("APCC_SCOPS","BCC_CSM1.1M","BOM_ACCESS","CMCC_SPS3.5","CWB_TCWB1TV1.1","JMA_MRI-CPS2","KMA_GLOSEA5GC2","METFR","MSC_CANSIPSV2","NASA","NCEP","PNU_CGCMV2.0","UKMO","HMC") 
  nModel = dimsizes(Model)

  FillValue = 1e20

  OutDir = "" 
;*******************************************
; 2. read input file & cal. anomaly
;*******************************************
  indir = ""

  lat           = fspan(-90.,90.,73)
  lat!0         = "lat"
  lat@long_name = "latitude"
  lat@units     = "degrees_north"
  lat@nlat      = nlat

  lon           = fspan(0.,357.5,144)
  lon!0         = "lon"
  lon@long_name = "longitude"
  lon@units     = "degrees_east"
  lon@nlon      = nlon

  do iv = 0, nVar-1

  do i = 0, nModel-1 
    do imon = 0, nmon-1
      u200 = new((/nyr,nlat,nlon/),"float",FillValue)      

      if (imon.eq.0) then
        yr1 = syr +1
        yr2 = eyr +1
      else
        yr1 = syr 
        yr2 = eyr 
      end if

        do yr = yr1, yr2
          iyr = yr-yr1
            infil = indir + "/" + Model(i) + "/" +  dir(imon) + "/" + yr + "/" + Var(iv) + ".nc"
;            print(infil)

          if (isfilepresent(infil)) then    ; Check if file exists
;            print(infil)
            in    = addfile(infil,"r")
            dat   = in->$Var(iv)$(0:2,:,:,:)

            if (isdouble(dat)) then
              xx = dat
              dat = dble2flt(xx)
              delete(xx)
            end if
            dat@_FillValue = FillValue

            u200(iyr,:,:) = dim_avg_n(dat,(/0,1/))

            delete(infil)
            delete(in)
            delete(dat)
          else
            print(infil)
            print("No File")
            u200(iyr,:,:) = FillValue         
            u200!1        = "lat"
            u200!2        = "lon"
            u200&lat      = lat 
            u200&lon      = lon 
          end if
        end do                                        ; year

        u200!0     = "year"
        u200!1     = "lat"
        u200!2     = "lon"
        u200&year  = ispan(syr,eyr,1)
        u200&lat   = lat 
        u200&lon   = lon 

        clim       = dim_avg_n_Wrap(u200,0)

        ano = u200
        do iyr = 0, nyr-1
          ano(iyr,:,:) = u200(iyr,:,:) - clim(:,:)
        end do

;*******************************************
; 3. write output files
;*******************************************
        if(.not.isfilepresent(OutDir+"/"+Model(i) ))then
          system("mkdir -p " + OutDir+"/"+Model(i) )
        end if

        outfil = OutDir + "/" + Model(i) + "/" + Var(iv) + "_anom_" + syr + eyr + "_" + month(imon) + ".nc"
        system ("/bin/rm -f "+outfil) ; remove any pre-existing file
        fout = addfile(outfil,"c")
        fout->$Var(iv)$ = ano

        outfil1 = OutDir + "/" + Model(i) + "/" + Var(iv) + "_clim_" + syr + eyr + "_" + month(imon) + ".nc"
        system ("/bin/rm -f "+outfil1) ; remove any pre-existing file
        fout = addfile(outfil1,"c")
        fout->$Var(iv)$ = clim

        delete(u200)
        delete(clim)
        delete(ano)
        delete(outfil)
        delete(outfil1)

      end do                        ; month
    end do                          ; model

 end do                             ; varibale
end
