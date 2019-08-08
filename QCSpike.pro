;                                          QCSpike
;                                          Don Pierson
;                                          IDL 8.4
;                                          Jan 2016
;
;Proceedure to check meteorological data and replace these data with NAN if the values show a rapid change.
;Change is detected by calculating the median of a window in front of the measurement and then checking 
;how far (in absolute units) the value is from the median
;
;Proccedure Parameters
;   QCFileName - string of path+filename of the file used to output information on replaced data points
;   FileLineInfo - string of file header line used in above file and containing info on the parameter checked
;   InFileBaseName = BaseName of input file ie no path used in output header
;   ISOTime - string vector of ISO standard times.  These match the rows in the main data array
;   TimeZone - sting of UCT zone that is part of ISO time specification.
;   InData - main data array
;   LineCount - the number of rows in IsoTime and InData (these should be the same)
;   DataIndex - Array col index associated with the data value to be checked
;   WinSize - size of window used to check for equal consecutive data values
;   MaxWinSize-Maximum size to allow the above window to expand in presence of NaN in file lines
;   Tol - absolute difference over which data are rejected.



PRO QCSpike, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InData, LineCount,$
    DataIndex, WinSize, MaxWinSize, Tol


GET_LUN, QCFileLUN
OPENW, QCFileLUN, QCFileName, Width=500, /Append

FileHeader=['Date/Time','TimeZone','EDay','Replaced Value','Run Median','Change','Num+NaNs','Num Used']
HeaderFormat='(A9,%"\t",A8,%"\t",A4,%"\t",A14,%"\t",A10,%"\t",A10,%"\t",A8,%"\t",A8)
OutFormat ='(A16,%"\t",A5,%"\t",I3,%"\t",F12.3,%"\t",F7.2,%"\t",F7.2,%"\t",I4,%"\t",I4)'

PRINTF,QCFileLUN,'****************************************** SPIKING VALUES ********************************************
PRINTF,QCFileLUN,''
PRINTF, QCFileLUN,FileInfoLine
PRINTF, QCFileLUN, 'Input file = '+InFileBaseName
PRINTF, QCFileLUN, ''
PRINTF, QCFileLUN, FileHeader, FORMAT=HeaderFormat

;-----------Compare the present value to the median of the next WinSize number of elements. In each itteration 
;           check that there are WinSize finite elements (ie no NaNs).  IF not extend the array forward until you
;           have WinSize elements.  This was done since large missing gaps would allow spikes to be missed.
;           While doing this in the While loop two checks are made first the loop is not allowed to extend beyond
;           a threshold that would be expected to allow the values to change significantly, and a check is made
;           to prevent the window from extending beyond the end of the file.
;

StopCount=LONG(WinSize)

FOR I = 0, LineCount-(StopCount+1) DO BEGIN
  PresentValue=InData(DataIndex,I)
  IF FINITE(PresentValue,/NAN) THEN CONTINUE      ;Hop over evaluation of missing values
  WinArray=InData(DataIndex,I+1:I+WinSize)
  ArrayLoc=Where(FINITE(WinArray), ArrayCount)    ;Check to see there are WinSize number of finite values in the array ie excluding NaNs
  IF  ArrayCount LT WinSize THEN BEGIN
  WinGrow = WinSize
      WHILE ArrayCount LT WinSize DO BEGIN                      ;If # of finite #s < WinSize then extend array back until you have WinSize elements.
        WinGrow=WinGrow+1
        If WinGrow GT MaxWinSize THEN BREAK                     ;Do Not go forward more than and excepted threshold
        IF I+WinGrow GT LineCount-1 THEN GOTO, jumpout          ;This prevent trying to expand beyond the end of the file                        
        WinArray=InData(DataIndex,I+1:I+WinGrow)
        ArrayLoc=Where(FINITE(WinArray), ArrayCount)
      ENDWHILE
  ENDIF
  WinMed=MEDIAN(WinArray)
  Spike = ABS(PresentValue-WinMed)
  ;Spike = ((ABS(PresentValue-WinMed))/WinMed)*100
  IF Spike GT Tol THEN BEGIN             
    PRINTF, QCFileLUN, ISOTime(I),TimeZone,FIX(InData(8,I)),InData(DataIndex,I),WinMed,Spike,N_ELEMENTS(WinArray),ArrayCount, FORMAT=OutFormat
;    PRINTF,QCFileLUN, WinArray
;    PRINTF,QCFileLUN, ""
    InData(DataIndex,I)= !Values.F_NAN
  ENDIF
EndFOR
jumpout:
FREE_LUN, QCFileLUN

END