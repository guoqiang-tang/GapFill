# GapFill
This code package is designed to infill and reconstruct missing values in precipitation and temperature observations from station data. Based on this package, we developed a serially complete dataset (SCD) of precipitation, minimum temperature, and maximum temperature from 1979 to 2018 over North America. The dataset is available on Zenodo (https://doi.org/10.5281/zenodo.3735534).  

Function descriptions:
1. "data_read" contains functions that can (1) read and reformat original GHCN-D, GSOD, ECCC, and Mexico datasets, and (2) read and resample ERA5, MERRA2, and JRA55 reanalysis data with temperature downscaled using a lapse rate-based method.



Contact information:  
Guoqiang Tang (guoqiang.tang@usask.ca),  Martyn P. Clark (martyn.clark@usask.ca)

Reference:
Guoqiang Tang, Martyn P. Clark, Andrew J. Newman, Andrew Wood, Simon Michael Papalexiou, Vincent Vionnet, and Paul H. Whitfield. A serially complete precipitation and temperature dataset in North America from 1979 to 2018. Earth System Science Data Discussion. 2020
