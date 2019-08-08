;                                          QCDiagPlot
;                                          Don Pierson
;                                          IDL 8.5
;                                          Mar 2016
;
;Proceedure to produce diagnositic plots of quality controlled data. The level 1 QC datafile is plotted
;as a time series and on top of that the deleted level 0 points are also plotted.  It is possible from 
;IDL to zoom in and examine the deleted points and decide if the deletions seem warrented
;
;
;Last Modified
;   15 Sep 2016 Don Pierson Added IF statement to prevent trying to produce overplot of removed values, 
;   when there are no removed valuse
;
;Proccedure Parameters
;   
;   DataIndex - Array col index associated with the data value to be checked
;   Level0Array - Data array of level0 data
;   Level1Array - Data array of Level1 data
;   MaxValue - Max Y value to plot - avoid plotting the most extreme error values
;   MinValue - Min Y value to plot - avoid plotting the most extreme error values
;   GraphTitle - String variable containing the graph title
;   AxisTitle - String variable containg the Y axis title
;   
;

PRO QCDiagPlot, DataIndex,Level0Array, Level1Array, MaxValue,MinValue,GraphTitle,AxisTitle

  dummy=LABEL_DATE(DATE_FORMAT=['%Y'])
  PlotSize=[1000,600]

  DataLevel0=Level0Array(DataIndex,*)
  DataLevel1=Level1Array(DataIndex,*)
  Level0Finite=FINITE(DataLevel0)
  Level1Finite=FINITE(DataLevel1)
  FiniteDiff = Level0Finite-Level1Finite
  RemoveLoc=WHERE(FiniteDiff EQ 1)



  DiagGraph = Plot(Level1Array(0,*),Level1Array(DataIndex,*), COLOR="blue", DIMENSIONS=PlotSize, TITLE=GraphTitle, YTitle=AxisTitle,$
    MAX_VAlUE=MaxValue, MIN_VALUE=MinValue, XTICKFORMAT='LABEL_DATE',XTICKUNITS='TIME',XTICKINTERVAL=2)
    
 ; IF RemoveLoc(0) GT 0 THEN BEGIN   ;prevent plot and crash when no elements are found ie RemoveLoc = -1
  IF N_Elements(RemoveLoc) GT 1 THEN BEGIN  
     DiagGraph = ScatterPlot(Level0Array(0,RemoveLoc),Level0Array(DataIndex,RemoveLoc),SYMBOL="o",SYM_COLOR="red",SYM_SIZE=0.4,SYM_FILLED=1,$
       DIMENSIONS=PlotSize,MAX_VAlUE=MaxValue, MIN_VALUE=MinValue, /Overplot)
  ENDIF

END