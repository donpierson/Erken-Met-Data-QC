;********************************************************************************************
;                       ErkenHrQC_4.pro
;                       IDL 8.5
;                       Don Pierson
;                       Dec 2015
;
;
;Program to read in Cumulative hourly data files from Erken Island site and preform data
;checks and quality control.  Tests are preformed on one paramter at time in a sequenctial 
;manner.  This should make it easier to add addition tests to the program as they are
;developed
;
;Original data file is always preserved
;For every paramter/test a file is created listing data delted from QA/QC file
;
;Last Modified
;   Dec 2013 - QA/QC Max Min routine now embeded in IDL proceedures.
;   19 Nov 2015 - QC file output changed to CSV
;   
;   Dec 2015 Gapfilling and time changing routines now in IDL proceedure
;   Feb 2016 Output level0 and Level1 File.  Improved plotting 
;
;****************************************** Main arrays ****************************************
;
;  InData - FltArray
;  0=JDay  
;  1=Year
;  2=Month
;  3=Day
;  4=Hour
;  5=Minute
;  6=XLdate
;  7=ArrayID
;  8=EDay
;  9=TotalRad
;  10=PAR
;  11=AirTemp2
;  12=AirTemp1
;  13=Hum
;  14=VaporPress
;  15=WTemp1
;  16=WTemp3
;  17=Wtemp15
;  18=WS1
;  19=WS2
;  20=WDir
;  21=SDWDir
;  22=MaxWS
;  23=TimeMaxWS
;  24=WScubed
;  25=WLev
;  26=CumRain
;  27=AirPressure
;
;******************************************** User Input *****************************************
;
;------------------------Used by QCMinMax   
;   
;----------QC threholds

MaxTotalRad = [350.0,520.0,750.0,900.0,990.0,1020.0,990.0,910.0,760.0,580.0,390.0,290.0]
MinTotalRad = [-10.0,-10.0,-10.0,-10.0,-10.0,-10.0,-10.0,-10.0,-10.0,-10.0,-10.0,-10.0]

MaxPAR = [650.0,850.0,1230.0,1520.0,1720.0,1840.0,1790.0,1590.0,1300.0,950.0,720.0,630.0]
MinPAR = [-12.0,-12.0,-12.0,-12.0,-12.0,-12.0,-12.0,-12.0,-12.0,-12.0,-12.0,-12.0]

MaxWtemp = [10.0,9.0,10.0,14.0,23.0,27.0,30.0,29.0,28.0,22.0,15.0,12.0]
MinWtemp = [-1.0,-1.0,-1.0,-1.0,-1.0,6.0,11.0,11.0,6.0,1.0,-1.0,-1.0]

MaxAirTemp = [14.0,14.0,18.0,26.0,30.0,35.0,39.0,37.0,31.0,24.0,18.0,15.0]
MinAirTemp = [-25.0,-26.0,-22.0,-11.0,-5.0,0.0,4.0,3.0,-2.0,-8.0,-14.0,-25.0]

MaxWind = 30.0
MinWind = 0.0

MaxWindDir = 360.0
MinWindDir = 0.0

MaxLev = 10.7
MinLev = 9.0

;-----Other 

MonthIndex=2    ; Used by QC routine to indicate what array column has month info

;----------File header info

TimeZone="UCT+1"
ProgramName = 'ErkenHrQC_4.pro'

;----------Parameters used by Gapfill proceedure

MeasIntMin=60.0
TimeOutFlag=1
;
;----------Graph Output
;
DocGraphFlag=0
DiagGraphFlag=1
;
;************************************** Define Input and Output Files *******************************
;
;-------------Define input and output files
;
InFileName=DIALOG_PICKFILE(/Read, PATH='E:\DEP1\IDLWorkspace\Data\', GET_PATH=RunPath)
 
RunTime = SYSTIME()
TimeValues=STRSPLIT(SYSTIME(),/Extract)
TimeStamp=TimeValues(2)+TimeValues(1)+TimeValues(4)

InFileBaseName=FILE_BASENAME(InFileName)                                   ;Infile name without path
OutFileBase = STRSPLIT(InFileBaseName,'.',/Extract)                        ;Infile name without extension
ModFileName = OutFileBase(0)
;STRPUT, ModFileName,'Level1',6
OutFileName1=RunPath+"Level0_"+ModFileName+"_"+TimeStamp+".csv"
OutFileName2=RunPath+"Level1_"+ModFileName+"_"+TimeStamp+".csv"
;
;-------------Open input and output files
; 
GET_LUN, InfileLUN
GET_LUN, OutfileLevel0LUN

OPENR, InfileLUN, InFileName
OPENW, OutFileLevel0LUN, OutFileName1, Width=500

;
;***************************************** Input Data ******************************************
;
;---------------Define input arrays
;
NumInFileLines = FILE_LINES(Infilename)
InData=DBLARR(28,NumInFileLines-4)


InFileHeader = ' '
FileLine=''
FileLineValues = STRARR(25)
LineCount = 0LL

READF,InFileLUN, InFileHeader   ; Skip file header
READF,InFileLUN, InFileHeader   ; Skip file header
READF,InFileLUN, InFileHeader   ; Skip file header
READF,InFileLUN, InFileHeader   ; Skip file header

;----------------Read in data from ASCII tab delinated input file chosen above 
;                Fill in ChlData array

WHILE ~ EOF(InfileLUN) DO BEGIN    ;~ EOF(InfileLUN)   LineCount LE 100
   READF,InfileLUN,FileLine 
   FileLineValues=STRSPLIT(FileLine,",",/Extract,/PRESERVE_NULL)
  
   
;
;----------------Time Conversion.  Change Logger Logger JDay and Time Yr Mon Day hr min
   
   StrYear=STRTRIM(FileLineValues(2),1)
   StrDay=STRTRIM(FileLineValues(3),1)  
   StrTime=STRTRIM(FileLineValues(4),1)       
   
   CamTime2Float, StrYear,StrDay,StrTime,$                ;Input
                  Year,Month,Day,Hour,Minute,EdayOut      ;Output
     
  Jday=JULDAY(Month,Day,Year,Hour,Minute)
  
 ;---------------Convert remaining string values to Floats  
 
   XLDate=DOUBLE(FileLineValues(0))
   ArrayID=FLOAT(FileLineValues(1))
   
   IF FileLineValues(5)EQ "" THEN BEGIN
      TotalRad = !Values.F_NAN
   ENDIF ELSE BEGIN
      TotalRad = FLOAT(FileLineValues(5))
   ENDELSE
   
   IF FileLineValues(6)EQ "" THEN BEGIN
      PAR = !Values.F_NAN
   ENDIF ELSE BEGIN
      PAR = FLOAT(FileLineValues(6))
   ENDELSE
   
   IF FileLineValues(7)EQ "" THEN BEGIN
      AirTemp2 = !Values.F_NAN
   ENDIF ELSE BEGIN
      AirTemp2 = FLOAT(FileLineValues(7))
   ENDELSE
   
   IF FileLineValues(8)EQ "" THEN BEGIN
      AirTemp1 = !Values.F_NAN
   ENDIF ELSE BEGIN
      AirTemp1 = FLOAT(FileLineValues(8))
   ENDELSE
   
   IF FileLineValues(9)EQ "" THEN BEGIN
      Hum = !Values.F_NAN
   ENDIF ELSE BEGIN
      Hum = FLOAT(FileLineValues(9))
   ENDELSE
   
   IF FileLineValues(10)EQ "" THEN BEGIN
     VaporPress = !Values.F_NAN
   ENDIF ELSE BEGIN
     VaporPress = FLOAT(FileLineValues(10))
   ENDELSE
   
   IF FileLineValues(11)EQ "" THEN BEGIN
      WTemp1 = !Values.F_NAN
   ENDIF ELSE BEGIN
      WTemp1 = FLOAT(FileLineValues(11))
   ENDELSE
   
   IF FileLineValues(12)EQ "" THEN BEGIN
      WTemp3 = !Values.F_NAN
   ENDIF ELSE BEGIN
      WTemp3 = FLOAT(FileLineValues(12))
   ENDELSE
   
   IF FileLineValues(13)EQ "" THEN BEGIN
      WTemp15 = !Values.F_NAN
   ENDIF ELSE BEGIN
      WTemp15 = FLOAT(FileLineValues(13))
   ENDELSE
   
   IF FileLineValues(14)EQ "" THEN BEGIN
      WS1 = !Values.F_NAN
   ENDIF ELSE BEGIN
      WS1 = FLOAT(FileLineValues(14))
   ENDELSE
   
   IF FileLineValues(15)EQ "" THEN BEGIN
      WS2 = !Values.F_NAN
   ENDIF ELSE BEGIN
      WS2 = FLOAT(FileLineValues(15))
   ENDELSE
   
   IF FileLineValues(16)EQ "" THEN BEGIN
      WDir = !Values.F_NAN
   ENDIF ELSE BEGIN
      WDir = FLOAT(FileLineValues(16))
   ENDELSE
   
   IF FileLineValues(17)EQ "" THEN BEGIN
      SDWDir = !Values.F_NAN
   ENDIF ELSE BEGIN
      SDWDir = FLOAT(FileLineValues(17))
   ENDELSE
   
   IF FileLineValues(18)EQ "" THEN BEGIN
     WSmax = !Values.F_NAN
   ENDIF ELSE BEGIN
     WSmax = FLOAT(FileLineValues(18))
   ENDELSE
     
   IF FileLineValues(19)EQ "" THEN BEGIN
     TimeWSmax = !Values.F_NAN
   ENDIF ELSE BEGIN
     TimeWSmax = FLOAT(FileLineValues(19))  
   ENDELSE
   
   IF FileLineValues(20)EQ "" THEN BEGIN
      WScubed = !Values.F_NAN
   ENDIF ELSE BEGIN
      WScubed = FLOAT(FileLineValues(20))
   ENDELSE
   
   IF FileLineValues(21)EQ "" THEN BEGIN
     WLev = !Values.F_NAN
   ENDIF ELSE BEGIN
     WLev = FLOAT(FileLineValues(21))
   ENDELSE
   
   IF FileLineValues(22)EQ "" THEN BEGIN
     CumRain = !Values.F_NAN
   ENDIF ELSE BEGIN
     CumRain = FLOAT(FileLineValues(22))
   ENDELSE
   
   IF FileLineValues(23)EQ "" THEN BEGIN
     AirPress = !Values.F_NAN
   ENDIF ELSE BEGIN
     AirPress = FLOAT(FileLineValues(23))
   ENDELSE
   
; -----------------Put data in input array

  InData(0,LineCount)=Jday    
  InData(1,LineCount)=Year
  InData(2,LineCount)=Month
  InData(3,LineCount)=Day
  InData(4,LineCount)=Hour
  InData(5,LineCount)=Minute
  InData(6,LineCount)=XLdate
  InData(7,LineCount)=ArrayID
  InData(8,LineCount)=EDayOut
  InData(9,LineCount)=TotalRad
  InData(10,LineCount)=PAR
  InData(11,LineCount)=AirTemp2
  InData(12,LineCount)=AirTemp1
  InData(13,LineCount)=Hum
  InData(14,LineCount)=VaporPress
  InData(15,LineCount)=WTemp1
  InData(16,LineCount)=WTemp3
  InData(17,LineCount)=Wtemp15
  InData(18,LineCount)=WS1
  InData(19,LineCount)=WS2
  InData(20,LineCount)=WDir
  InData(21,LineCount)=SDWDir
  InData(22,LineCount)=WSmax
  InData(23,LineCount)=TimeWSmax
  InData(24,LineCount)=WScubed
  InData(25,LineCount)=WLev
  InData(26,LineCount)=CumRain
  InData(27,LineCount)=AirPress
    
  LineCount=LineCount+1
ENDWHILE

FREE_LUN, InFileLUN

;************************************* Output Level 0 Data **********************************
;
;----------------Output Level 0 data same as imput data file except
;                Time is in ISO format
;                All data gaps are filled with NaNs
;                
;                
;---------------- File header info used by both level0 and level1 data

FileHeader=['TMSTAMP','RECNBR','SW_Rad_Avg','PAR_Rad_Avg','Air_Temp_HS_Avg','Air_Temp_AS_Avg','RelHumidity_Avg','Vapor_Pressure_Avg','Water_Temp_1m_Avg',$
           'Water_Temp_3m_Avg','Water_Temp_15m_Avg','MeanWS','WindVector','WindDir','StdDevWindDir','WindSpeed_Max','WindSpeed_TMx','WindSpeed3_Avg',$
           'Water_Level_Avg','Rain_Tot','AirPressure_hPa_Avg']

HeaderFormat='(A7,%",",A6,%",",A10,%",",A11,%",",A15,%",",A15,%",",A15,%",",A18,%",",A18,%",",A18,%",",A19,%",",A6,%",",A10,%",",A7,%",",A13,%",",A13,%",",A13,%",",A14,%",",A15,%",",A8,%",",A19)'
OutFormat ='(A16,%",",I6,%",",F8.3,%",",F8.3,%",",F7.3,%",",F7.3,%",",F7.3,%",",F7.3,%",",F7.3,%",",F7.3,%",",F7.3,%",",F7.3,%",",F7.3,%",",F5.1,%",",F6.2,%",",F7.3,%",",F7.0,%",",F9.3,%",",F6.3,%",",F6.2,%",",F8.3)'
;
;
;****************************************** Create Level0 Array ******************************************
;
; Create an array that has all possible 1 hour sampling intervals. If data is missing
; Fill in with NaN.  This will make it easier to merge Island and float data.
; USE Proc GAPFILL

GapFill, InData,MeasIntMin,TimeOutFlag,InDataLevel0,NumRowsOutArray

;------------ Also Replace Logger codes -6999 and 6999 with NaN.  It is best to do this now in the 
;             level 0 file since 1) they already are coded as missing the 6999 values do not print
;             well in the level 0 file

UnderFlowLoc=WHERE(InDataLevel0 EQ -6999)
InDataLevel0(UnderFlowLoc)= !Values.F_NAN

OverFlowLoc=WHERE(InDataLevel0 EQ 6999)
InDataLevel0(OverFlowLoc)= !Values.F_NAN

;
;************************************* Create ISOTime String Array ***************************************
;         NOTE REMOVE THIS AND TRANSFER ISOTIME TO QC PROCEEDURES AT A LATER TIME.
;
;---------Creat a vector of ISO Time strings that correspond to the rows in the levelO (including gaps) file
;         NOTE The only purpose of this array now is to pass ISO times to the QC proceedures.  It would be 
;         better to due the ISO time conversion in the QC routines
;
ISOTime=STRARR(NumRowsOutArray)

For I=0,NumRowsOutArray-1 DO BEGIN
  
  Year = InDataLevel0(1,I)
  Month = InDataLevel0(2,I)
  Day = InDataLevel0(3,I)
  Hour = InDataLevel0(4,I)
  Minute = InDataLevel0(5,I)
  
Float2IsoTime, Year, Month, Day, Hour, Minute,$    ;Input
               IsoTime2                            ;Output
    ISOTime(I)=ISOTime2

Endfor

PRINTF, OutFilelevel0LUN, 'Level 0 Input Data.  Created using '+ProgramName+' on '+RunTime
PRINTF, OutFilelevel0LUN, 'Input file = '+InFileBaseName
PRINTF, OutFilelevel0LUN,' '
PRINTF, OutFilelevel0LUN, FileHeader, FORMAT=HeaderFormat

FOR I = 0L, NumRowsOutArray-1 DO BEGIN

  Year=InDataLevel0[1,I]
  Month=InDataLevel0[2,I]
  Day=InDataLevel0[3,I]
  Hour=InDataLevel0[4,I]
  Minute=InDataLevel0[5,I]

  Float2IsoTime, Year, Month, Day, Hour, Minute,$    ;Input
    IsoTime2                                         ;Output

  PRINTF, OutFilelevel0LUN,ISOTime2,I,InDataLevel0(9,I),InDataLevel0(10,I),InDataLevel0(11,I),InDataLevel0(12,I),InDataLevel0(13,I),$
    InDataLevel0(14,I),InDataLevel0(15,I),InDataLevel0(16,I),InDataLevel0(17,I),InDataLevel0(18,I),InDataLevel0(19,I),InDataLevel0(20,I),InDataLevel0(21,I),InDataLevel0(22,I),$
    InDataLevel0(23,I),InDataLevel0(24,I),InDataLevel0(25,I),InDataLevel0(26,I),InDataLevel0(27,I), FORMAT=OutFormat
ENDFOR

FREE_LUN, OutFileLevel0LUN

;-------------Create a preliminary Level1 array by copying the Level0 array.  All QC will 
;             subsequently be made on the level1 array.  Get rid of the original input
;             array

InDataLevel1=InDataLevel0
UNDEFINE, InData             ;Delete original input array to save memory

;************************************** Quality Control *************************************

;+++++++++++++++++++++++++ Total Rad QC +++++++++++++++++++++++++++++

QCFileName=RunPath+"TotalRad_QC_Loc_"+OutFileBase(0)+"_"+TimeStamp+".tab"
FileInfoLine='Record of quality controled Total Incoming Radiation Data.  Caluclated using '+ProgramName+' on '+RunTime
DataIndex = 9
MinValue = MinTotalRad
MaxValue = MaxTotalRad
ZeroFlag = 1
WinSizeRepeat=6

QCMaxMin2, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    MonthIndex, DataIndex, MinValue,MaxValue, ZeroFlag
    
QCRepeat, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    DataIndex, WinSizeRepeat 
    
          
;+++++++++++++++++++++++++ PAR QC +++++++++++++++++++++++++++++
        
QCFileName=RunPath+"PAR_QC_Loc_"+OutFileBase(0)+"_"+TimeStamp+".tab"
FileInfoLine='Record of quality controled PAR Data.  Caluclated using '+ProgramName+' on '+RunTime
DataIndex = 10
MinValue = MinPAR
MaxValue = MaxPAR
ZeroFlag = 1
WinSizeRepeat=6
        
QCMaxMin2, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    MonthIndex, DataIndex, MinValue,MaxValue, ZeroFlag
    
QCRepeat, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    DataIndex, WinSizeRepeat

;+++++++++++++++++++++++++ Wtemp 1 QC +++++++++++++++++++++++++++++
        
QCFileName=RunPath+"Wtemp1_QC_Loc_"+OutFileBase(0)+"_"+TimeStamp+".tab"
FileInfoLine='Record of quality controled 1m Water Temp Data.  Caluclated using '+ProgramName+' on '+RunTime
DataIndex = 15
MinValue = MinWtemp
MaxValue = MaxWtemp
ZeroFlag = 1
WinSizeRepeat=12
WinSizeSpike=12
MaxWinSize=168
Tol=2.0
        
QCMaxMin2, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    MonthIndex, DataIndex, MinValue,MaxValue, ZeroFlag
    
QCRepeat, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    DataIndex, WinSizeRepeat
    
QCSpike, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    DataIndex, WinSizeSpike ,MaxWinSize, Tol
    
;+++++++++++++++++++++++++ Wtemp 3 QC +++++++++++++++++++++++++++++          
          
QCFileName=RunPath+"Wtemp3_QC_Loc_"+OutFileBase(0)+"_"+TimeStamp+".tab"
FileInfoLine='Record of quality controled 3m Water Temp Data.  Caluclated using '+ProgramName+' on '+RunTime
DataIndex = 16
MinValue = MinWtemp
MaxValue = MaxWtemp
ZeroFlag = 1
WinSizeRepeat=12
WinSizeSpike=12
MaxWinSize=168
Tol=2.0
        
QCMaxMin2, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    MonthIndex, DataIndex, MinValue,MaxValue, ZeroFlag
    
QCRepeat, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    DataIndex, WinSizeRepeat  
    
QCSpike, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    DataIndex, WinSizeSpike ,MaxWinSize, Tol
     
          
;+++++++++++++++++++++++++ Wtemp 15 QC +++++++++++++++++++++++++++++
        
QCFileName=RunPath+"Wtemp15_QC_Loc_"+OutFileBase(0)+"_"+TimeStamp+".tab"
FileInfoLine='Record of quality controled 15m Water Temp Data.  Caluclated using '+ProgramName+' on '+RunTime
DataIndex = 17
MinValue = MinWtemp
MaxValue = MaxWtemp
ZeroFlag = 1
WinSizeRepeat=6
WinSizeSpike=12
MaxWinSize=168
Tol=2.0
        
QCMaxMin2, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    MonthIndex, DataIndex, MinValue,MaxValue, ZeroFlag
    
QCRepeat, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    DataIndex, WinSizeRepeat 

QCSpike, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    DataIndex, WinSizeSpike ,MaxWinSize, Tol
       
          
;+++++++++++++++++++++++++ Air Temp HS QC +++++++++++++++++++++++++++++
;
;-----------Measured by Humidity Sensor
        
QCFileName=RunPath+"AirTemp1_QC_Loc_"+OutFileBase(0)+"_"+TimeStamp+".tab"
FileInfoLine='Record of quality controled Air Temp1 Data.  Caluclated using '+ProgramName+' on '+RunTime
DataIndex = 11
MinValue = MinAirTemp
MaxValue = MaxAirTemp
ZeroFlag = 0
WinSizeRepeat=6
WinSizeSpike=3
MaxWinSize=5
Tol=15.0
        
QCMaxMin2, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    MonthIndex, DataIndex, MinValue,MaxValue, ZeroFlag
    
QCRepeat, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    DataIndex, WinSizeRepeat
    
QCSpike, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    DataIndex, WinSizeSpike ,MaxWinSize, Tol        
          
;+++++++++++++++++++++++++ Air Temp AS +++++++++++++++++++++++++++++
;
;-----------Thermocouple Measured by aspirated shield
        
QCFileName=RunPath+"AirTemp2_QC_Loc_"+OutFileBase(0)+"_"+TimeStamp+".tab"
FileInfoLine='Record of quality controled Air Temp2 Data.  Caluclated using '+ProgramName+' on '+RunTime
DataIndex = 12
MinValue = MinAirTemp
MaxValue = MaxAirTemp
ZeroFlag = 0
WinSizeRepeat=6
WinSizeSpike=3
MaxWinSize=5
Tol=15.0
        
QCMaxMin2, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    MonthIndex, DataIndex, MinValue,MaxValue, ZeroFlag
 
QCRepeat, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    DataIndex, WinSizeRepeat
    
QCSpike, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    DataIndex, WinSizeSpike ,MaxWinSize, Tol        

;+++++++++++++++++++++++++ Wind Speed 1 QC +++++++++++++++++++++++++++++
;
;-----------Mean wind speed
        
QCFileName=RunPath+"WindSpeed1_QC_Loc_"+OutFileBase(0)+"_"+TimeStamp+".tab"
FileInfoLine='Record of quality controled Wind Speed1 Data.  Caluclated using '+ProgramName+' on '+RunTime
DataIndex = 18
MinValue = MinWind
MaxValue = MaxWind
ZeroFlag = 0
WinSize=3
        
QCMaxMin, QCFileName, FileInfoLine,InfileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
          DataIndex, MinValue,MaxValue, ZeroFlag
          
QCRepeat, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
          DataIndex, WinSize 
          
;------Check to see where WS is missing and also set WS3 to missing in the same rows

LocMissingWS=WHERE(FINITE(InDatalevel1(18,*)) EQ 0)
InDataLevel1(24,LocMissingWS)=!Values.F_NAN
                             

;+++++++++++++++++++++++++ Wind Speed 2 QC +++++++++++++++++++++++++++++
;
;-----------Vector wind speed
        
QCFileName=RunPath+"WindSpeed2_QC_Loc_"+OutFileBase(0)+"_"+TimeStamp+".tab"
FileInfoLine='Record of quality controled Wind Speed2 Data.  Caluclated using '+ProgramName+' on '+RunTime
DataIndex = 19
MinValue = MinWind
MaxValue = MaxWind
ZeroFlag = 0
WinSize=3
        
QCMaxMin, QCFileName, FileInfoLine,InfileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
          DataIndex, MinValue,MaxValue, ZeroFlag
          
QCRepeat, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
          DataIndex, WinSize 
          
;------Check to see where WS is missing and also set WS3 to missing in the same rows

LocMissingWS=WHERE(FINITE(InDatalevel1(19,*)) EQ 0)
InDataLevel1(24,LocMissingWS)=!Values.F_NAN                 
          
 ;+++++++++++++++++++++++++ Wind Direction QC +++++++++++++++++++++++++++++

 QCFileName=RunPath+"WindDir_QC_Loc_"+OutFileBase(0)+"_"+TimeStamp+".tab"
 FileInfoLine='Record of quality controled Wind Direction Data.  Caluclated using '+ProgramName+' on '+RunTime
 DataIndex = 20
 MinValue = MinWindDir
 MaxValue = MaxWindDir
 ZeroFlag = 0
 WinSize=6

 QCMaxMin, QCFileName, FileInfoLine,InfileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
           DataIndex, MinValue,MaxValue, ZeroFlag
           
 QCRepeat, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
           DataIndex, WinSize                     
          
;+++++++++++++++++++++++++ Water Level QC +++++++++++++++++++++++++++++
        
QCFileName=RunPath+"WaterLevel_QC_Loc_"+OutFileBase(0)+"_"+TimeStamp+".tab"
FileInfoLine='Record of quality controled Water Level Data.  Caluclated using '+ProgramName+' on '+RunTime
DataIndex = 25
MinValue = MinLev
MaxValue = MaxLev
ZeroFlag = 0
WinSizeRepeat=48
WinsizeSpike=48
MaxWinSize=168
Tol=0.15
        
QCMaxMin, QCFileName, FileInfoLine,InfileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
          DataIndex, MinValue,MaxValue, ZeroFlag
          
;QCRepeat, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
;          DataIndex, WinSizeRepeat

QCSpike, QCFileName, FileInfoLine, InFileBaseName, ISOTime, TimeZone, InDataLevel1, NumRowsOutArray,$
    DataIndex, WinSizeSpike ,MaxWinSize, Tol
    
;+++++++++++++++++++++++++ Humidity QC +++++++++++++++++++++++++++++
;
;     Data is deemed to unrelilable for use.  So at this time all data is repaced with
;     missing values 

DataIndex = 13  

QCSetMissing, InDataLevel1, NumRowsOutArray,DataIndex

;
;
;***************************************** Output QC data ******************************************
;

GET_LUN, OutfileLevel1LUN
OPENW, OutFileLevel1LUN, OutFileName2, Width=500

PRINTF, OutfileLevel1LUN, 'Level 1 Quality Controled Data.  Outliers and errors removed using '+ProgramName+' on '+RunTime
PRINTF, OutfileLevel1LUN, 'Input file = '+InFileBaseName
PRINTF, OutfileLevel1LUN,' '
PRINTF, OutfileLevel1LUN, FileHeader, FORMAT=HeaderFormat

FOR I = 0L, NumRowsOutArray-1 DO BEGIN

Year=InDataLevel1[1,I]
Month=InDataLevel1[2,I]
Day=InDataLevel1[3,I]
Hour=InDataLevel1[4,I]
Minute=InDataLevel1[5,I]

Float2IsoTime, Year, Month, Day, Hour, Minute,$    ;Input
  IsoTime2                                         ;Output
    
PRINTF, OutfileLevel1LUN,ISOTime2,I,InDataLevel1(9,I),InDataLevel1(10,I),InDataLevel1(11,I),InDataLevel1(12,I),InDataLevel1(13,I),$
        InDataLevel1(14,I),InDataLevel1(15,I),InDataLevel1(16,I),InDataLevel1(17,I),InDataLevel1(18,I),InDataLevel1(19,I),InDataLevel1(20,I),InDataLevel1(21,I),InDataLevel1(22,I),$
        InDataLevel1(23,I),InDataLevel1(24,I),InDataLevel1(25,I),InDataLevel1(26,I),InDataLevel1(27,I), FORMAT=OutFormat
ENDFOR

FREE_LUN, OutFileLevel1LUN

;
;************************************* Make Documentation Plots of QC data ***************************************
;

IF DocGraphFlag EQ 1 THEN BEGIN
  
dummy=LABEL_DATE(DATE_FORMAT=['%Y'])
PlotSize=[1000,600]
;
;---------Incoming Radiation
;
GraphTitle='Erken Island Incoming Radiation Data'
Plot_File=RunPath+"Rad_"+OutFileBase(0)+"_"+TimeStamp+".jpg"

DocGraph = Plot(InDataLevel1(0,*),InDataLevel1(9,*), COLOR="blue", DIMENSIONS=PlotSize, LAYOUT=[1,2,1], TITLE=GraphTitle, YTitle="Total SWRad (W/m2)",$
           XTICKFORMAT='LABEL_DATE',XTICKUNITS='TIME',XTICKINTERVAL=2)

DocGraph = Plot(InDataLevel1(0,*),InDataLevel1(10,*), COLOR="blue",DIMENSIONS=PlotSize,/CURRENT, LAYOUT=[1,2,2],$ 
           YTitle="PAR (uE/m2/s)",XTICKFORMAT='LABEL_DATE',XTICKUNITS='TIME',XTICKINTERVAL=2)
           
DocGraph.Save,Plot_File, BITMAP=1, /LANDSCAPE

;
;---------Air Temp
;
GraphTitle='Erken Island Air Temperature Data'
Plot_File=RunPath+"AirTemp_"+OutFileBase(0)+"_"+TimeStamp+".jpg"

DocGraph = Plot(InDataLevel1(0,*),InDataLevel1(11,*), COLOR="blue", DIMENSIONS=PlotSize, LAYOUT=[1,2,1], TITLE=GraphTitle, YTitle="Air Temp HS (C)",$
           XTICKFORMAT='LABEL_DATE',XTICKUNITS='TIME',XTICKINTERVAL=2)

DocGraph = Plot(InDataLevel1(0,*),InDataLevel1(12,*), COLOR="blue",DIMENSIONS=PlotSize,/CURRENT, LAYOUT=[1,2,2],$ 
           YTitle="Air Temp AS (C)",XTICKFORMAT='LABEL_DATE',XTICKUNITS='TIME',XTICKINTERVAL=2)
           
DocGraph.Save,Plot_File, BITMAP=1, /LANDSCAPE

;
;---------Wind Speed
;
GraphTitle='Erken Island Wind Speed Data'
Plot_File=RunPath+"WindSpeed_"+OutFileBase(0)+"_"+TimeStamp+".jpg"

DocGraph = Plot(InDataLevel1(0,*),InDataLevel1(18,*), COLOR="blue", DIMENSIONS=PlotSize, LAYOUT=[1,2,1], TITLE=GraphTitle, YTitle="Vector Wind Speed (m/s)",$
           XTICKFORMAT='LABEL_DATE',XTICKUNITS='TIME',XTICKINTERVAL=2)

DocGraph = Plot(InDataLevel1(0,*),InDataLevel1(19,*), COLOR="blue",DIMENSIONS=PlotSize,/CURRENT, LAYOUT=[1,2,2],$ 
           YTitle="Mean Wind Speed (m/s)",XTICKFORMAT='LABEL_DATE',XTICKUNITS='TIME',XTICKINTERVAL=2)
           
DocGraph.Save,Plot_File, BITMAP=1, /LANDSCAPE

;
;---------Water Temperature
;
GraphTitle='Erken Island Island Water Temperature Data'
Plot_File=RunPath+"Wtemp_"+OutFileBase(0)+"_"+TimeStamp+".jpg"
          
;-----Seperate Plot

DocGraph = Plot(InDataLevel1(0,*),InDataLevel1(15,*), COLOR="blue", DIMENSIONS=PlotSize, LAYOUT=[1,3,1], TITLE=GraphTitle, YTitle="Wtemp 1m (C)",$
           XTICKFORMAT='LABEL_DATE',XTICKUNITS='TIME',XTICKINTERVAL=2)

DocGraph = Plot(InDataLevel1(0,*),InDataLevel1(16,*), COLOR="blue",DIMENSIONS=PlotSize,/CURRENT, LAYOUT=[1,3,2],$ 
           YTitle="Wtemp 3m (C)",XTICKFORMAT='LABEL_DATE',XTICKUNITS='TIME',XTICKINTERVAL=2)
           
DocGraph = Plot(InDataLevel1(0,*),InDataLevel1(17,*), COLOR="blue",DIMENSIONS=PlotSize,/CURRENT, LAYOUT=[1,3,3],$ 
           YTitle="Wtemp 15m (C)",XTICKFORMAT='LABEL_DATE',XTICKUNITS='TIME',XTICKINTERVAL=2)
           
DocGraph.Save,Plot_File, BITMAP=1, /LANDSCAPE
;
;--------Plot Water Temperature Differences

GraphTitle='Erken Island Water Temperature Differences'
Plot_File=RunPath+"WTempDiff_"+OutFileBase(0)+"_"+TimeStamp+".jpg"

SurfTempDiff=FLTARR(NumRowsOutArray)
MeanSurfTemp=FLTARR(NumRowsOutArray)
TotalTempDiff=FLTARR(NumRowsOutArray)

For I = 0, NumRowsOutArray -1 DO BEGIN
    SurfTempDiff(I)=InDataLevel1(15,I)-InDataLevel1(16,I)
    MeanSurfTemp(I)=MEAN(InDataLevel1(15:16,I),/NAN)
    TotalTempDIff(I)=MeanSurfTemp(I)-InDataLevel1(17,I) 
ENDFOR
DocGraph = Plot(InDataLevel1(0,*),SurfTempDiff(*), COLOR="blue", DIMENSIONS=PlotSize, LAYOUT=[1,2,1], TITLE=GraphTitle, YTitle="Temp Diff 1-3 m",$
  XTICKFORMAT='LABEL_DATE',XTICKUNITS='TIME',XTICKINTERVAL=2)
  
DocGraph = Plot(InDataLevel1(0,*),TotalTempDiff(*), COLOR="blue",DIMENSIONS=PlotSize,/CURRENT, LAYOUT=[1,2,2],$
  YTitle="Water Column Temp Diff",XTICKFORMAT='LABEL_DATE',XTICKUNITS='TIME',XTICKINTERVAL=2)
  
DocGraph.Save,Plot_File, BITMAP=1, /LANDSCAPE

;
;---------Water Level
;
GraphTitle='Erken Island Island Water Level Data'
Plot_File=RunPath+"WLev_"+OutFileBase(0)+"_"+TimeStamp+".jpg"

DocGraph = Plot(InDataLevel1(0,*),InDataLevel1(25,*), COLOR="blue", DIMENSIONS=PlotSize, TITLE=GraphTitle, YTitle="Water Level masl",$
           XTICKFORMAT='LABEL_DATE',XTICKUNITS='TIME',XTICKINTERVAL=2)

           
DocGraph.Save,Plot_File, BITMAP=1, /LANDSCAPE

ENDIF

;
;************************************* Make Diagnostic Plots of QC data ***************************************
;

IF DiagGraphFlag EQ 1 THEN BEGIN
  
  ;
  ;---------Incoming Radiation
  ;
  DataIndex = 9
  MaxValue = 3000.0
  MinValue = -100.0
  GraphTitle='Erken Island Hourly Incoming Shortwave Radiation Data'
  AxisTitle="Total SWRad (W/m2)"
  
  QCDiagPlot, DataIndex,InDataLevel0,InDataLevel1,MaxValue,MinValue,GraphTitle,AxisTitle 
  
  ;
  ;---------PAR
  ;
  DataIndex = 10
  MaxValue = 3000.0
  MinValue = -100.0
  GraphTitle="Erken Island Hourly PAR Radiation Data"
  AxisTitle="PAR (uE/m2/s)"

  QCDiagPlot, DataIndex,InDataLevel0,InDataLevel1,MaxValue,MinValue,GraphTitle,AxisTitle
    
  ;
  ;---------Air Temp (HS)
  ;
  DataIndex = 11
  MaxValue = 50.0
  MinValue = -50.0
  GraphTitle="Erken Island Humidity Sensor Air Temperature"
  AxisTitle="Temperature (C)"

  QCDiagPlot, DataIndex,InDataLevel0,InDataLevel1,MaxValue,MinValue,GraphTitle,AxisTitle 

  ;
  ;---------Air Temp (AS)
  ;
  DataIndex = 12
  MaxValue = 50.0
  MinValue = -50.0
  GraphTitle="Erken Island Aspirated Air Temperature"
  AxisTitle="Temperature (C)"

  QCDiagPlot, DataIndex,InDataLevel0,InDataLevel1,MaxValue,MinValue,GraphTitle,AxisTitle  
  

  ;
  ;---------Water Temp 1m
  ;
  DataIndex = 15
  MaxValue = 40.0
  MinValue = -10.0
  GraphTitle="Erken Island 1m Water Temperature"
  AxisTitle="Temperature (C)"

  QCDiagPlot, DataIndex,InDataLevel0,InDataLevel1,MaxValue,MinValue,GraphTitle,AxisTitle  

  ;
  ;---------Water Temp 3m
  ;
  DataIndex = 16
  MaxValue = 40.0
  MinValue = -10.0
  GraphTitle="Erken Island 3m Water Temperature"
  AxisTitle="Temperature (C)"

  QCDiagPlot, DataIndex,InDataLevel0,InDataLevel1,MaxValue,MinValue,GraphTitle,AxisTitle
  
  ;
  ;---------Water Temp 15m
  ;
  DataIndex = 17
  MaxValue = 40.0
  MinValue = -10.0
  GraphTitle="Erken Island 15m Water Temperature"
  AxisTitle="Temperature (C)"

  QCDiagPlot, DataIndex,InDataLevel0,InDataLevel1,MaxValue,MinValue,GraphTitle,AxisTitle    
  
  ;
  ;---------Water Level
  ;
  DataIndex = 25
  MaxValue = 11.0
  MinValue = 9.0
  GraphTitle="Erken Island Lake Water Level"
  AxisTitle="Water Level (masl)"

  QCDiagPlot, DataIndex,InDataLevel0,InDataLevel1,MaxValue,MinValue,GraphTitle,AxisTitle  
   

ENDIF

Print, "Finished"

END