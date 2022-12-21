
-----------------------------------------------결제방법 주문유형  주문경로----------------------------------------------
---------------------------------------------------------------------------------------------------------------
SELECT SUM(Ord_Amt)                                                                 AS OrdAmtTotal
     , ROUND(AVG(Ord_Amt))                                                          AS OrdAvgTotal
     , SUM(DECODE(Status,'A',Ord_Amt,0))                                            AS OrdAmtOK   
     , SUM(DECODE(Status,'A',1,      0))                                            AS OrdCntOK   
     , ROUND(SUM(DECODE(Status,'A',Ord_Amt,0)) / SUM(Ord_Amt) * 100, 2)             AS OrdRateOK  
     , SUM(DECODE(Status,'C',Ord_Amt,'R',Ord_Amt,0))                                AS OrdAmtRT   
     , SUM(DECODE(Status,'C',      1,'R',      1,0))                                AS OrdCntRT   
     , ROUND(SUM(DECODE(Status,'C',Ord_Amt,'R',Ord_Amt,0)) / SUM(Ord_Amt) * 100, 2) AS OrdRateRT  
     , SUM(DECODE(Kind_CD, ufCom_CD(:comId)||'O01',Ord_Amt,0))                      AS OrdAmtNew  
     , SUM(DECODE(Kind_CD, ufCom_CD(:comId)||'O02',Ord_Amt,0))                      AS OrdAmtRep  
     , SUM(DECODE(Kind_CD, ufCom_CD(:comId)||'O03',Ord_Amt,0))                      AS OrdAmtADO  
     , SUM(DECODE(Kind_CD, ufCom_CD(:comId)||'O04',Ord_Amt,0))                      AS OrdAmtCon  
     , SUM(DECODE(Path_CD, ufCom_CD(:comId)||'T10',Ord_Amt,0))                      AS OrdAmtHead 
     , SUM(DECODE(Path_CD, ufCom_CD(:comId)||'T20',Ord_Amt,0))                      AS OrdAmtCnt  
     , SUM(DECODE(Path_CD, ufCom_CD(:comId)||'T30',Ord_Amt,0))                      AS OrdAmtMy   
     , SUM(DECODE(Path_CD, ufCom_CD(:comId)||'T40',Ord_Amt,0))                      AS OrdAmtShop 
     , SUM(Rcpt_Cash)                                                               AS RcptCash   
     , SUM(Rcpt_Card)                                                               AS RcptCard   
     , SUM(Rcpt_Bank + Rcpt_VBank)                                                  AS RcptBank   
     , SUM(Rcpt_PrePay + Rcpt_Point + Rcpt_ARS + Rcpt_Coin + Rcpt_Etc)              AS RcptEtc    
  FROM Ord_Mst                                                                                    
 WHERE Com_ID = :comId                                                                            
   AND Status <> 'X'                                                                              
   AND Rcpt_YN = 'Y'    
---------------------------------------------------------------------------------------------------------------
-----------------------------------------------end 결제방법 주문유형  주문경로------------------------------------------