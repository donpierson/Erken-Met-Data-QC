;                                           QCMaxdMin.Pro
;                                              IDL 8.5
;                                            Don Pierson


;Proceedure to check meteorological data and replace these data with NAN if the values exceed a maximum or minimum
;threshold.  In the case of minimum values there is also the option of setting the values X
;  1)  X<0 and X> min threshold = 0
;  2)  X < minthreshold = NAN
;the first choice allows slighly negative values (ie radiation or PAR) to be set to 0 rather than NAN
;
;Proccedure Parameters
;   QCFileName - string of path+filename of the file used to output infromation on replaced data points
;   FileLineInfo - string of file header line used in above file and containing info on the parameter checked
;   InFileBaseName = BaseName of input file ie no path used in output header
;   ISOTime - string vector of ISO standard times.  These match the rows in the main data array
;   TimeZone - sting of UTZ time zone that is part of ISO time specification.
;   InData - main data array
;   LineCount - the number of rows in IsoTime and InData (these should be the same)
;   DataIndex - Array col index associated with the data value to be checked
;   MaxValue - Max value above which data is consider invalid
;   MinValue - Min value below which data is consider invalid
;   ZeroFlag - defines how data falling below MinValue are processed 0=choice 2 above,  1=choice 1 above

PRO QCMaxMin, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InData, LineCount,$
    DataIndex, MinValue,MaxValue, ZeroFlag


GET_LUN, QCFileLUN
OPENW, QCFileLUN, QCFileName, Width=500

FileHeader=['Date/Time','TimeZone','EDay','Replaced Value']
HeaderFormat='(A9,%"\t",A8,%"\t",A4,%"\t",A14)
OutFormat ='(A16,%"\t",A5,%"\t",I3,%"\t",F12.3)'

PRINTF, QCFileLUN,FileInfoLine
PRINTF, QCFileLUN, 'Input file = '+InFileBaseName


;----------- Set value exceeding MAX threshold  to NaN

PRINTF, QCFileLUN, ''
PRINTF, QCFileLUN, '*********** Values exceeding '+STRTRIM(STRING(MaxValue),1)+' replaced with missing value (NaN) ***********'
PRINTF, QCFileLUN, ''

PRINTF, QCFileLUN, FileHeader, FORMAT=HeaderFormat

FOR I = 0L, LineCount-1 DO BEGIN
  IF InData(DataIndex,I) GT MaxValue THEN BEGIN
    PRINTF, QCFileLUN, ISOTime(I),TimeZone,FIX(InData(8,I)),InData(DataIndex,I), FORMAT=OutFormat
    InData(DataIndex,I)= !Values.F_NAN
  ENDIF
EndFOR

;----------- Set value exceeding MIN threshold  to NaN

PRINTF, QCFileLUN, ''
PRINTF, QCFileLUN, '*********** Values less than '+STRTRIM(STRING(MinValue),1)+' replaced with missing value (NaN) ***********'
PRINTF, QCFileLUN, ''

PRINTF, QCFileLUN, FileHeader, FORMAT=HeaderFormat

FOR I = 0L, LineCount-1 DO BEGIN
  IF InData(DataIndex,I) LT MinValue THEN BEGIN
    PRINTF, QCFileLUN, ISOTime(I),TimeZone,FIX(InData(8,I)),InData(DataIndex,I), FORMAT=OutFormat
    InData(DataIndex,I)= !Values.F_NAN
  ENDIF
EndFOR

;----------- Set negative values that are greater than MIN threshold = 0.0

IF ZeroFlag EQ 1 THEN BEGIN

  PRINTF, QCFileLUN, ''
  PRINTF, QCFileLUN, '******** Slightly negative values greater than '+STRTRIM(STRING(MinValue),1)+' replaced with 0.0 ********'
  PRINTF, QCFileLUN, ''

  PRINTF, QCFileLUN, FileHeader, FORMAT=HeaderFormat

  FOR I = 0L, LineCount-1 DO BEGIN
    IF InData(DataIndex,I) GE MinValue AND InData(DataIndex,I)LT 0.0 THEN BEGIN
      PRINTF, QCFileLUN, ISOTime(I),TimeZone,FIX(InData(8,I)),InData(DataIndex,I), FORMAT=OutFormat
      InData(DataIndex,I)= 0.0
      ENDIF
  EndFOR

ENDIF

FREE_LUN, QCFileLUN

END