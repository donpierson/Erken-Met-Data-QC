;                                             GapFill.pro
;                                   Written by Don Pierson 22 Dec 2015
;                                               IDL 8.4
;
; Proceedure that looks at an array of data containing data that has an evenly spaced measurement interval
; which is also the same as the time spacing between rows.  Every row is cheched to see that it is the
; expected interval ahead of the last row.  If not then missing rows containing time information are added 
; to the output array.  These missing rows will contain Time information followed by NaNs 
; 
; THE FIRST COLUMN MUST CONTAIN THE IDL JULIAN DATE.
;
; Last Modified
;    30 Dec 2015 Don Pierson TimeOutFlag  Added
;    15 Jan 2016 Don Pierson Number of Array columns now gotten from size so pgm should work will all arrays
;    12 Sep 2016 Don Pierson Checks seconds and increases min if Sec GT 30 Needed to avoid rounding errors
;                even in double precision.  Tested to 1 min meas interval.  
;
;Proceedure Parameters
;   Input:
;     InArray = InputArray DOUBLE PRECISION
;     MeasIntMin = Expected measurment interval (row spacing) minutes.
;     TimeOutFlag = If 0 only Julian day (col 0) is output in gap fill rows
;                   If 1 Year month day hour and min our output in cols (1-5)
;   Output:
;     OutArray = OutputArray DOUBLE PRECISION
;     NumRowsOutArray = Number of rows in the output array (including all gaps)
;

PRO GapFill, InArray,MeasIntMin,TimeOutFlag,OutArray,NumRowsOutArray 

;--------Calculate the number of rows in an array based on the assumtion that there are no missing data between
;        the start and end time and that data are spaced evenly at the interval specified by MeasIntMin.

MeasIntDay=1440.0/MeasIntMin                                                ;Number of measurements made in a day
TimeGap=Double(MeasIntMin/1440.0)                                             ;portion of a day cover by one meas interval 
  
InDataSize = Size(InArray)                                                   ;Dimension of data in InData Array
NonZeroJday=WHERE(InArray(0,*) GT 0.0, NumRowsInData)                       ;Number of rows in Indata that contain acutal data
NumRowsOutArray=LONG((InArray(0,NumRowsInData-1)-InArray(0,0))*MeasIntDay)  ;Number of expected min rows (Jday Ednd -Jday Start)*MeasIntDay

NumColsOutArray=InDataSize(1)                                               ;Total number of cols in the input array

;---------Create a new array OutArray that contains all possible rows at MeasIntMin spacing.
;         If missing add NaNs

OutArray = DBLARR(NumColsOutArray,NumRowsOutArray)                    ;contains all possible rows
RowCount=1L
OutArray(*,0) = InArray(*,0)                                          ;set first rows equal

For I = 1, NumRowsOutArray-1 DO BEGIN
  OutArray(0,I)=OutArray(0,I-1)+TimeGap                               ;Calc Jday for + MeasInt
  CALDAT,OutArray(0,I),Month1,Day1,Year1, Hour1, Min1, Sec1
     IF Sec1 GT 30.0 Then Min1=Min1+1
     IF Min1 EQ 60 Then Min1=0                                        ;Correct for rounding errors ie sec=59.99
  CALDAT,InArray(0,RowCount),Month2,Day2,Year2, Hour2, Min2, Sec2
     IF Sec2 GT 30.0 Then Min2=Min2+1                                 ;Correct for rounding errors
     IF Min2 EQ 60 Then Min2=0

     If Year1 EQ Year2 AND Month1 EQ Month2 AND Day1 EQ Day2 AND Hour1 EQ Hour2 AND Min1 EQ Min2 THEN BEGIN
       OutArray(*,I)=InArray(*,RowCount)
       RowCount=RowCount+1
     Endif Else Begin
       OutArray(0,I)=OutArray(0,I-1)+TimeGap                           ;Calc Jday for + MeasInt
    
     IF TimeOutFlag EQ 1 THEN BEGIN
        CALDAT,OutArray(0,I),Month3,Day3,Year3, Hour3, Min3, Sec3      ;Calc time values associated with Jday
           IF Sec3 GT 30.0 Then Min3=Min3+1
           IF Min3 EQ 60 Then Min3=0                                    ;Correct for rounding errors
        OutArray(1,I)=Year3
        OutArray(2,I)=Month3
        OutArray(3,I)=Day3
        OutArray(4,I)=Hour3
        OutArray(5,I)=Min3
        OutArray(6:NumColsOutArray-1,I)=!Values.F_NAN
      EndIf Else Begin
        OutArray(1:NumColsOutArray-1,I)=!Values.F_NAN
      EndElse  
   EndElse
  
EndFor

END
