# Erken-Met-Data-QC
IDL programs used to do quality control checks on the meteorological data collected at the Erken Lab

This archive contains IDL programs that are used to process the meteorological data collected at the Erken laboratory

The program corrects for several different quality control problems.
  1)	Data logger underflow and overflow values (ie -7999) are set to missing values (NaN)
  
  2)	Missing lines in the data file are filled in with lines of missing values. This allows easier comparison and replacement of lines         from another station.
  
  3)	Data ar removed that exceeds a maximum or minimum threshold that is unrealistically high or low.  For some parameters such as wind         speed this is a single fixed value, while for others which have a clear seasonal pattern such as air temperature we use monthly           threshold values.  Values exceeding the thresholds are set to a missing value. 
  
  4)	Data that have exactly the same repeating value are set to missing after a threshold number of repeats. 

  5)	Data that show rapid and unrealistic changes in value or “spiking” behavior are also set to missing.
  
The original data file is always saved as level 0 and separate quality controlled file is saved as level 1 corrected. Level 2 data would fill all the missing values in the level 1 data using data from the nearest SMHI station or by linear interpolation between the missing values.  The date and time of every NaN replacement as well as the value removed from the data set is logged and plotted (Fig X), and these logs can be used to adjust threshold values if needed.  The program can always be rerun to produce updated level 1 files.  
