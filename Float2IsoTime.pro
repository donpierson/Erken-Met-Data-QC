;                                            Float2IsoTime
;                                   Written by Don Pierson 10 Nov 2015
;                                               IDL 8.4
;                                             
; Proceedure that takes floating values for year, month, day, hour and minute and produces a time string that 
; is in ISO stanadard format YYYY-MM-DD hh:mm.  
; 
;Proceedure Parameters
;   Input:
;     Year = floating value of year
;     Month = floating value of month
;     Day = floating value of day of month
;     Hour = floating value of hour
;     Min = floating value of minute
;   Output:
;     ISOTime = String of time in ISO stanadard format YYYY-MM-DD hh:mm
;      
;     
; 
PRO Float2IsoTime, Year, Month, Day, Hour, Minute,$    ;Input
                   IsoTime                             ;Output
 
                         
             
             StrYear=STRTRIM(STRING(FIX(Year)),2)               ;Trimed variable for creation of final iso date
             
             StrMonth=STRTRIM(STRING(FIX(Month)),2)
             IF STRLEN(StrMonth) EQ 1 THEN StrMonth='0'+StrMonth
             
             StrDay=STRTRIM(STRING(FIX(Day)),2)
             IF STRLEN(StrDay) EQ 1 THEN StrDay='0'+StrDay
             
             StrHour=STRTRIM(STRING(FIX(Hour)),2)
             IF STRLEN(StrHour) EQ 1 THEN StrHour='0'+StrHour
             
             StrMinute=STRTRIM(STRING(FIX(Minute)),2)
             IF STRLEN(StrMinute) EQ 1 THEN StrMinute='0'+StrMinute
               
             IsoTime = StrYear+'-'+StrMonth+'-'+StrDay+' '+StrHour+':'+StrMinute
 
END
               