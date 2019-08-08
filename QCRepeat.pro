;                                          QCRepeat
;                                          Don Pierson
;                                          IDL 8.4
;                                          Dec 2015
;
;Proceedure to check meteorological data and replace these data with NAN if the values repeat (exactly) more
;two times within a moving window defined by WinSize.  Two consecutive equal values are allowed, all other
;repeating values in the series are set to NaN
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



PRO QCRepeat, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InData, LineCount,$
    DataIndex, WinSize


GET_LUN, QCFileLUN
OPENW, QCFileLUN, QCFileName, Width=500, /Append

FileHeader=['Date/Time','TimeZone','EDay','Replaced Value']
HeaderFormat='(A9,%"\t",A8,%"\t",A4,%"\t",A14)
OutFormat ='(A16,%"\t",A5,%"\t",I3,%"\t",F12.3)'

PRINTF,QCFileLUN,'****************************************** REPEATING VALUES ********************************************
PRINTF,QCFileLUN,''
PRINTF, QCFileLUN,FileInfoLine
PRINTF, QCFileLUN, 'Input file = '+InFileBaseName
PRINTF, QCFileLUN, ''
PRINTF, QCFileLUN, FileHeader, FORMAT=HeaderFormat

RepeatFlag=0
FixedValue=0.0
StartCount=LONG(WinSize-1)
FOR I = StartCount, LineCount-1 DO BEGIN
  ArrayStart=(I-WinSize)+1
  WinArray=InData(DataIndex,ArrayStart:I)
  PresentValue=InData(DataIndex,I)
  IF PresentValue EQ 0.0 OR PresentValue EQ 0.2 THEN CONTINUE  ;Do not check for repeating 0 or 0.2 (WindSpd).  Hop to next loop iteration
  IF ARRAY_EQUAL(WinArray,PresentValue) THEN BEGIN             ;If all of the values in the window equal the presnt value
    PRINTF, QCFileLUN, ISOTime(I),TimeZone,FIX(InData(8,I)),InData(DataIndex,I), FORMAT=OutFormat
    FixedValue=InData(DataIndex,I)
    RepeatFlag=1
    InData(DataIndex,I)= !Values.F_NAN
    CONTINUE                             ;goto next loop iteration dont make next test since already set to NaN
  ENDIF
  
  IF RepeatFlag EQ 1 THEN BEGIN
    IF InData(DataIndex,I) EQ FixedValue THEN BEGIN
      PRINTF, QCFileLUN, ISOTime(I),TimeZone,FIX(InData(8,I)),InData(DataIndex,I), FORMAT=OutFormat
      InData(DataIndex,I)= !Values.F_NAN
    ENDIF ELSE BEGIN
      RepeatFlag=0
    ENDELSE
  ENDIF      
EndFOR

FREE_LUN, QCFileLUN

END