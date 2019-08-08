;                                          QCSetMissing
;                                          Don Pierson
;                                          IDL 8.5
;                                          Sep 2016
;
;Proceedure that simplyl sets all value of an given input array column to NaN.  This is used to 
;eliminate data that appears to be unusable from the output array, but still allows the data
;to be retained in the input file and input array
;
;Proccedure Parameters
;   InData - main data array
;   LineCount - the number of rows in IsoTime and InData (these should be the same)
;   DataIndex - Array col index associated with the data value to be checked


PRO QCSetMissing, InData, LineCount, DataIndex


FOR I = 0, LineCount-1 DO BEGIN  
  InData(DataIndex,I) = !Values.F_NAN
EndFOR

END