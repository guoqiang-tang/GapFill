# GapFill
This code package is designed to infill and reconstruct missing values in precipitation and temperature observations from station data. Based on this package, we developed a serially complete dataset (SCD) of precipitation, minimum temperature, and maximum temperature from 1979 to 2018 over North America. The dataset is available on Zenodo (https://doi.org/10.5281/zenodo.3735534).  

Function descriptions:
1. "data_read" contains functions that can (1) read and reformat original GHCN-D, GSOD, ECCC, and Mexico datasets, and (2) read and resample ERA5, MERRA2, and JRA55 reanalysis data with temperature downscaled using a lapse rate-based method.
2. “gauge_merge" contains functions that can identify stations with same locations and merge their seires.
3. "quality_control" contains functions to perform quality control based on methods designed by Durre et al. (2010) for GHCN-D, Hamada et al. (2011) for APHRODITE, and Beck et al. (2019) for MSWEP.
4. ”UnifyData” is a simple function that combines individual station files into a complete file to facilitate following analysis because reading/transferring one large file is more convenient when there are too many individual files.
5. “gauge_rea_match” contains functions that extract reanalysis estimates from “data_rea” corresponding to all stations.
6. “GapFill” contains functions that perform infilling and reconstruction for all stations based on different strategies such as three interpolation methods and quantile mapping. Independent validation of these strategies is carried out using 30% independent samples.
7. “GapFill_ML” contains functions that perform infilling and reconstruction based on machine learning methods. This is independent with “GapFill” because data preparation and training/testing of models are different from interpolation or quantile mapping.
8. “Correct_Save“ contains functions that carry out quantile mapping-based correction and mean value adjustment and output the final estimates.

Contact information:  
Guoqiang Tang (guoqiang.tang@usask.ca),  Martyn P. Clark (martyn.clark@usask.ca)

Reference:  
Beck, H. E., Wood, E. F., Pan, M., Fisher, C. K., Miralles, D. G., van Dijk, A. I. J. M., McVicar, T. R. and Adler, R. F.: MSWEP V2 Global 3-Hourly 0.1° Precipitation: Methodology and Quantitative Assessment, Bull. Am. Meteorol. Soc., 100(3), 473–500, 2019.  
Durre, I., Menne, M. J., Gleason, B. E., Houston, T. G. and Vose, R. S.: Comprehensive Automated Quality Assurance of Daily Surface Observations, J. Appl. Meteorol. Climatol., 49(8), 1615–1633, doi:10.1175/2010JAMC2375.1, 2010.  
Guoqiang Tang, Martyn P. Clark, Andrew J. Newman, Andrew Wood, Simon Michael Papalexiou, Vincent Vionnet, and Paul H. Whitfield. A serially complete precipitation and temperature dataset in North America from 1979 to 2018. Earth System Science Data Discussion. 2020  
Hamada, A., Arakawa, O. and Yatagai, A.: An Automated Quality Control Method for Daily Rain-gauge Data, Glob. Environ. Res., 15(2), 183–192, 2011.
