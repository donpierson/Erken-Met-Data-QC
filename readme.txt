

                                   Main Program ErkenHrQc_4

1) Reads input data logger file (expected format based on Erken Data logger program)
2) Creates a level0 file by adding in all missing hourly rows.  This produces a file that has 
   a line for every possible hour in the time interval between the first and last line of the 
   input file.
3) Runs quality control steps that remove outliers
4) Runs quality control steps that remove repeating values
5) Runs quality control steps that rapidly changing values
6) Produces summary graphs of each processed variable over the entire data period
7) Writes a level1 output file that that of exactly the same format at the level 0 one 
   but has replaced questionable values with NaN

For every meteorological parameter a log file is created is created which logs every value 
that was removed from the level 1 file and which quality control criteria that was
responsible for the removal 

The thresholds for each quality control procedure as applied to each different meteorological
variable are contained in in the main program. 

                                Procedures called by the Main Program  

QCMaxMin.pro     Removes variable values that exceed a maximum or minimum threshold.  There is an option
                 that allows a slightly negative values that are greater than the negative threshold to 
                 be replaced by 0 rather than NaN.
                 
QCMaxMin2.pro    Same as above but monthly threshold values are used rather than a single universal threshold
                 This is useful for variables that show distinct seasonal patterns of variation

QCRepeat.pro     Removes values after a threshold number of repeating values has been exceeded.

QCSpike.pro      Remove values of a variable that shows a rate of change that occurs more rapidly 
                 than would be physically realistic.

QCSetMissing.pro Used to set all values of a variable missing from a sensor that is known to be 
                 failing
                 
GapFill.pro      Searches an input file for missing rows given an expected time interval between
                 rows.  When found a line is added with the missing time value and NaN values for 
                 all the remaining varaibles (columns in array).

Float2IsoTime.pro Time conversion takes floating values for year, month, day, hour and minute and 
                  produces a time string that is in ISO standard format YYYY-MM-DD hh:mm.               