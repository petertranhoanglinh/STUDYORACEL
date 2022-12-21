CREATE OR REPLACE Function STEMI_KOREA.ufTBL_4230_GL (
  SP_Kind                IN VARCHAR2,  -- 'COUNT' / 'DATA'
  SP_Lang                IN VARCHAR2,
  SP_ChkOrder            IN VARCHAR2,  -- '1':Ord_Date, '2': Acc_Date 
  SP_SDate               IN VARCHAR2,
  SP_EDate               IN VARCHAR2,
  --SP_Ord_NO              IN VARCHAR2,--Deleted by Binh
  SP_License             IN VARCHAR2,  --  '1','2','3'
  SP_Status              IN VARCHAR2,
  SP_User_Kind           IN VARCHAR2,
  SP_ChkUserid           IN VARCHAR2,  -- '1','2','3','4','5','6','7'
  SP_Userid              IN VARCHAR2,
  SP_Cnt_CD              IN VARCHAR2,
  SP_Grp_CD              IN VARCHAR2,
  SP_Ctr_CD              IN VARCHAR2,
  SP_Ord_Kind            IN VARCHAR2,
  SP_Ord_Path            IN VARCHAR2,
  SP_Ord_Pay             IN VARCHAR2,
  SP_ChkAddition         IN VARCHAR2,
  SP_Addition            IN VARCHAR2
) 
RETURN TBL_4230          PIPELINED
IS
--------------------------------------------------------------------------------
-- function Name : ufTBL_4230
-- Call from     : (Wownet) Screen 4230 | 주문관리 > 주문검색  
-- Sample        : SELECT * FROM TABLE(ufTBL_4230(:COM_ID
--                                              , :Kind
--                                              , '''||SP_Lang||'''
--                                              , :ChkOrder    
--                                              , :SDate
--                                              , :EDate
--                                              , :Ord_NO     
--                                              , :License    
--                                              , :Status     
--                                              , :User_Kind  
--                                              , :ChkUserid  
--                                              , :Userid     
--                                              , :Cnt_CD     
--                                              , :Grp_CD     
--                                              , :Ctr_CD     
--                                              , :Ord_Kind   
--                                              , :Ord_Path   
--                                              , :Ord_Pay    
--                                              , :ChkAddition
--                                              , :Addition 
--                                              ));

--   Get Data      SELECT *        FROM TABLE(ufTBL_4230('WOWNET', 'DATA', 'KR', '1','20210101', '20210331'
--                                    , '', '', '', '',''  
--                                    , '', '', '', '', '' 
--                                    , '', '', '', '' ));
                                    
--   Get Count     SELECT TO_NUMBER(ordNo) FROM TABLE(ufTBL_4230('WOWNET', 'COUNT', 'KR', '1','20210101', '20210331'
--                                    , '', '', '', '', '' 
--                                    , '', '', '', '', '' 
--                                    , '', '', '', ''));

-- When          : 2021.05.10 
-- Created by    : LKY 
--------------------------------------------------------------------------------
  vType                  Obj_4230;
  vQuery                 LONG;
  
  ------------------------------------------------------------------------------
  -- 동적쿼리에 사용할 커서 선언
  ------------------------------------------------------------------------------
  TYPE CURSOR_TYPE IS REF CURSOR;

  C1 CURSOR_TYPE;

  -- 커서의 데이터를 저장할 레코드변수 선언 
  TYPE REC_DATA IS RECORD (
  Status              VARCHAR2(10 CHAR),
  ordNo               VARCHAR2(20 CHAR),
  ordNoOrg            VARCHAR2(20 CHAR),
  ordDate             VARCHAR2(14 CHAR),
  ordDate2            VARCHAR2(14 CHAR),
  accDate             VARCHAR2(14 CHAR),
  accDate2            VARCHAR2(14 CHAR),
  canDate             VARCHAR2(14 CHAR),
  cntNameOrd          VARCHAR2(45 CHAR),
  licenseCode         VARCHAR2(4 CHAR),
  licenseNO           VARCHAR2(30 CHAR),
  licenseDate         DATE,
  Userid              VARCHAR2(10 CHAR),
  Username            VARCHAR2(45 CHAR),
  userKindName        VARCHAR2(30 CHAR),
  cntNameMem          VARCHAR2(45 CHAR),
  grpName             VARCHAR2(45 CHAR),
  RankName            VARCHAR2(45 CHAR),
  rId                 VARCHAR2(10 CHAR),
  rName               VARCHAR2(60 CHAR),
  omniYN              VARCHAR2(10 CHAR),
  countryName         VARCHAR2(45 CHAR),
  kindCd              VARCHAR2(10 CHAR),
  kindName            VARCHAR2(30 CHAR),
  pathCd              VARCHAR2(10 CHAR),
  pathName            VARCHAR2(30 CHAR),
  sumPdt              VARCHAR2(10 CHAR),
  sumPdtCnt           NUMBER,
  sumPdtQty           NUMBER,
  ordPrice            NUMBER,
  ordVAT              NUMBER,
  ordAmt              NUMBER,
  ordPv1              NUMBER,
  ordPv2              NUMBER,
  ordPv3              NUMBER,
  ordPoint            NUMBER,
  deliNO              VARCHAR2(10 CHAR),
  deliAmt             NUMBER,
  collAmt             NUMBER,
  totalAmt            NUMBER,
  rcptYN              VARCHAR2(10 CHAR),
  rcptRemain          NUMBER,
  rcptTotal           NUMBER,
  rcptCash            NUMBER,
  rcptCard            NUMBER,
  rcptBank            NUMBER,
  rcptVBank           NUMBER,
  rcptPrePay          NUMBER,
  rcptPoint           NUMBER,
  rcptARS             NUMBER,
  rcptCoin            NUMBER,
  rcptEtc             NUMBER,
  adoNo               VARCHAR2(10 CHAR),
  adoCnt              NUMBER,
  adoDate             VARCHAR2(14 CHAR),
  taxInvoYN           VARCHAR2(10 CHAR),
  taxInvoNO           VARCHAR2(20 CHAR),
  taxInvoDate         VARCHAR2(14 CHAR),
  bPAmtSum            NUMBER,
  bPPv1Sum            NUMBER,
  bPPv2Sum            NUMBER,
  bPPv3Sum            NUMBER,
  bPDateCnt           NUMBER,
  bPAmtDay            NUMBER,
  bPAmtPay            NUMBER,
  bPAmtEtc            NUMBER,
  bPRefundDate        VARCHAR2(14 CHAR),
  bPRefundAmt         NUMBER,
  Remark              VARCHAR2(90 CHAR),
  insDate             DATE,
  insUser             VARCHAR2(10 CHAR),
  updDate             DATE,
  updUser             VARCHAR2(10 CHAR),
  ctrCd               VARCHAR2(10 CHAR),
  mUseKana            VARCHAR2(250 Char),
  mUseEnglish         VARCHAR2(250 Char)
  );  

  vData                  REC_DATA; 
  
  TYPE REC_COUNT IS RECORD (
    Count                NUMBER  
  );  

  vData2                 REC_COUNT; 
  
  TYPE REC_SUM IS RECORD (
  sumPdtCnt           NUMBER,
  sumPdtQty           NUMBER,
  ordPrice            NUMBER,
  ordVAT              NUMBER,
  ordAmt              NUMBER,
  ordPv1              NUMBER,
  ordPv2              NUMBER,
  ordPv3              NUMBER,
  ordPoint            NUMBER,
  deliAmt             NUMBER,
  collAmt             NUMBER,
  totalAmt            NUMBER,
  rcptRemain          NUMBER,
  rcptTotal           NUMBER,
  rcptCash            NUMBER,
  rcptCard            NUMBER,
  rcptBank            NUMBER,
  rcptVBank           NUMBER,
  rcptPrePay          NUMBER,
  rcptPoint           NUMBER,
  rcptARS             NUMBER,
  rcptCoin            NUMBER,
  rcptEtc             NUMBER,
  adoCnt              NUMBER,
  bPAmtSum            NUMBER,
  bPPv1Sum            NUMBER,
  bPPv2Sum            NUMBER,
  bPPv3Sum            NUMBER,
  bPDateCnt           NUMBER,
  bPAmtDay            NUMBER,
  bPAmtPay            NUMBER,
  bPAmtEtc            NUMBER,
  bPRefundAmt         NUMBER
  );  

  vData1                  REC_SUM;
  
  vRetCode               VARCHAR2(40);
  vRetStr                VARCHAR2(400);
  vLine                  VARCHAR2(20);
BEGIN
  vLine := '1';
  ------------------------------------------------------------------------------
  -- 데이터를 읽는다.
  ------------------------------------------------------------------------------
  IF SP_Kind = 'DATA' THEN
    vQuery :=           'SELECT /*+INDEX_DESC (A ORD_MST_IDX7)*/  ';
    vQuery := vQuery || '       ufName(A.Com_ID, ''ORD_MST.STATUS'', A.Status) AS Status';                             
    vQuery := vQuery || '     , A.Ord_NO AS ordNo               ';                                                                
    vQuery := vQuery || '     , A.Ord_NO_Org AS ordNoOrg        ';                                                                
    vQuery := vQuery || '     , A.Ord_Date AS ordDate           ';                                                                
    vQuery := vQuery || '     , ufDate('''||SP_Lang||''', ''L'',A.Ord_Date) AS ordDate2 ';                                        
    vQuery := vQuery || '     , A.Acc_Date AS accDate           ';                                                                
    vQuery := vQuery || '     , ufDate('''||SP_Lang||''', ''L'',A.Acc_Date) AS accDate2           ';                              
    vQuery := vQuery || '     , ufDate('''||SP_Lang||''', ''L'',A.Can_Date) AS canDate            ';                              
    vQuery := vQuery || '     , ufName(A.Com_ID, ''CENTER'',  A.Cnt_CD) AS cntNameOrd   ';                             
    vQuery := vQuery || '     , A.License_Code AS licenseCode   ';                                                                
    vQuery := vQuery || '     , A.License_NO AS licenseNO       ';                                                                
    vQuery := vQuery || '     , A.License_Date AS licenseDate   ';                                                                
    vQuery := vQuery || '     , A.Userid                        ';                                                                
    vQuery := vQuery || '     , B.Username                      ';                                                                
    vQuery := vQuery || '     , ufName(A.Com_ID, ''CODE'',  B.User_Kind) AS userKindName';                             
    vQuery := vQuery || '     , ufName(A.Com_ID, ''CENTER'',B.Cnt_CD)    AS cntNameMem  ';                             
    vQuery := vQuery || '     , ufName(A.Com_ID, ''GROUP'', B.Grp_CD)    AS grpName     ';                             
    vQuery := vQuery || '     , ufName(A.Com_ID, ''RANK'',  B.Rank_CD)   AS RankName    ';                             
    vQuery := vQuery || '     , B.R_ID AS rId                   ';                                                                
    vQuery := vQuery || '     , ufName(A.Com_ID, ''USERNAME'',B.R_ID) || ''('' || B.R_ID|| '')'' AS rName  ';          
    vQuery := vQuery || '     , A.Omni_YN AS omniYN             ';                                                                
    vQuery := vQuery || '     , ufName(A.Com_ID, ''COUNTRY'', A.CTR_CD) AS countryName  ';                             
    vQuery := vQuery || '     , A.Kind_CD AS kindCd             ';                                                                
    vQuery := vQuery || '     , ufName(A.Com_ID, ''CODE'',    A.Kind_CD) AS kindName    ';                             
    vQuery := vQuery || '     , A.Path_CD AS pathCd             ';                                                                
    vQuery := vQuery || '     , ufName(A.Com_ID, ''CODE'',    A.Path_CD) AS pathName    ';                             
    vQuery := vQuery || '     , A.Sum_Pdt_Cnt || ''/'' || A.Sum_Pdt_Qty AS sumPdt          ';                                     
    vQuery := vQuery || '     , (Select Count(1) From Ord_Pdt Where Ord_No = A.Ord_No) AS sumPdtCnt      ';                                                                
    vQuery := vQuery || '     , (Select Sum(QTY) From Ord_Pdt Where Ord_No = A.Ord_No) AS sumPdtQty      ';                                                                
    vQuery := vQuery || '     , A.Ord_Price AS ordPrice         ';                                                                
    vQuery := vQuery || '     , A.Ord_VAT AS ordVAT             ';                                                                
    vQuery := vQuery || '     , A.Ord_Amt AS ordAmt             ';                                                                
    vQuery := vQuery || '     , A.Ord_Pv1 AS ordPv1             ';                                                                
    vQuery := vQuery || '     , A.Ord_Pv2 AS ordPv2             ';                                                                
    vQuery := vQuery || '     , A.Ord_Pv3 AS ordPv3             ';                                                                
    vQuery := vQuery || '     , A.Ord_Point AS ordPoint         ';                                                                
    vQuery := vQuery || '     , A.Deli_NO AS deliNO             ';                                                                
    vQuery := vQuery || '     , A.Deli_Amt AS deliAmt           ';                                                                
    vQuery := vQuery || '     , A.Coll_Amt AS collAmt           ';                                                                
    vQuery := vQuery || '     , A.Total_Amt AS totalAmt         ';                                                                
    vQuery := vQuery || '     , ufName(A.Com_ID, ''ORD_MST.RCPT_YN'', A.Rcpt_YN) AS rcptYN ';                          
    vQuery := vQuery || '     , A.Rcpt_Remain AS rcptRemain     ';                                                                
    vQuery := vQuery || '     , A.Rcpt_Total  AS rcptTotal      ';                                                                
    vQuery := vQuery || '     , A.Rcpt_Cash   AS rcptCash       ';                                                                
    vQuery := vQuery || '     , A.Rcpt_Card   AS rcptCard       ';                                                                
    vQuery := vQuery || '     , A.Rcpt_Bank   AS rcptBank       ';                                                                
    vQuery := vQuery || '     , A.Rcpt_VBank  AS rcptVBank      ';                                                                
    vQuery := vQuery || '     , A.Rcpt_PrePay AS rcptPrePay     ';                                                                
    vQuery := vQuery || '     , A.Rcpt_Point  AS rcptPoint      ';                                                                
    vQuery := vQuery || '     , A.Rcpt_ARS    AS rcptARS        ';                                                                
    vQuery := vQuery || '     , A.Rcpt_Coin   AS rcptCoin       ';                                                                
    vQuery := vQuery || '     , A.Rcpt_Etc    AS rcptEtc        ';                                                                
    vQuery := vQuery || '     , A.ADO_NO      AS adoNo          ';                                                                
    vQuery := vQuery || '     , A.ADO_CNT     AS adoCnt         ';                                                                
    vQuery := vQuery || '     , ufDate('''||SP_Lang||''', ''L'',A.ADO_Date) AS adoDate          ';                                
    vQuery := vQuery || '     , A.Tax_Invo_YN AS taxInvoYN      ';                                                                
    vQuery := vQuery || '     , A.Tax_Invo_NO AS taxInvoNO      ';                                                                
    vQuery := vQuery || '     , ufDate('''||SP_Lang||''', ''L'',A.Tax_Invo_Date) AS taxInvoDate ';                                
    vQuery := vQuery || '     , A.BP_Amt_Sum  AS bPAmtSum       ';                                                                
    vQuery := vQuery || '     , A.BP_Pv1_Sum  AS bPPv1Sum       ';                                                                
    vQuery := vQuery || '     , A.BP_Pv2_Sum  AS bPPv2Sum       ';                                                                
    vQuery := vQuery || '     , A.BP_Pv3_Sum  AS bPPv3Sum       ';                                                                
    vQuery := vQuery || '     , A.BP_Date_Cnt AS bPDateCnt      ';                                                                
    vQuery := vQuery || '     , A.BP_Amt_Day  AS bPAmtDay       ';                                                                
    vQuery := vQuery || '     , A.BP_Amt_Pay  AS bPAmtPay       ';                                                                
    vQuery := vQuery || '     , A.BP_Amt_Etc  AS bPAmtEtc       ';                                                                
    vQuery := vQuery || '     , ufDate('''||SP_Lang||''', ''L'',BP_Refund_Date) AS bPRefundDate ';                                
    vQuery := vQuery || '     , A.BP_Refund_Amt AS bPRefundAmt  ';                                                                
    vQuery := vQuery || '     , A.Remark                        ';                                                                
    vQuery := vQuery || '     , A.Ins_Date AS insDate           ';                                                                
    vQuery := vQuery || '     , A.Ins_User AS insUser           ';                                                                
    vQuery := vQuery || '     , A.Upd_Date AS updDate           ';                                                                
    vQuery := vQuery || '     , A.Upd_User AS updUser           ';  
    vQuery := vQuery || '     , B.Ctr_Cd   AS ctrCd             '; 
    vQuery := vQuery || '     , B.Username_Kana AS mUseKana ';
    vQuery := vQuery || '     , ufUsername_English(B.Given_Name, B.Middle_Name, B.Family_Name) AS mUseEnglish ';  
  ELSIF SP_Kind = 'COUNT' THEN                                      
    vQuery :=           'SELECT COUNT(1) AS vCount  ';
  ELSIF SP_Kind = 'SUM' THEN                                      
    vQuery :=           'SELECT ';
    vQuery := vQuery || '       SUM((Select Count(1) From Ord_Pdt Where Ord_No = A.Ord_No)) AS sumPdtCnt      ';                                                                
    vQuery := vQuery || '     , SUM((Select Sum(QTY) From Ord_Pdt Where Ord_No = A.Ord_No)) AS sumPdtQty      ';                                                                
    vQuery := vQuery || '     , SUM(A.Ord_Price)   AS ordPrice       ';                                                                
    vQuery := vQuery || '     , SUM(A.Ord_VAT)     AS ordVAT         ';                                                                
    vQuery := vQuery || '     , SUM(A.Ord_Amt)     AS ordAmt         ';                                                                
    vQuery := vQuery || '     , SUM(A.Ord_Pv1)     AS ordPv1         ';                                                                
    vQuery := vQuery || '     , SUM(A.Ord_Pv2)     AS ordPv2         ';                                                                
    vQuery := vQuery || '     , SUM(A.Ord_Pv3)     AS ordPv3         ';                                                                
    vQuery := vQuery || '     , SUM(A.Ord_Point)   AS ordPoint       ';                                                             
    vQuery := vQuery || '     , SUM(A.Deli_Amt)    AS deliAmt        ';                                                                
    vQuery := vQuery || '     , SUM(A.Coll_Amt)    AS collAmt        ';                                                                
    vQuery := vQuery || '     , SUM(A.Total_Amt)   AS totalAmt       ';                            
    vQuery := vQuery || '     , SUM(A.Rcpt_Remain) AS rcptRemain     ';                                                                
    vQuery := vQuery || '     , SUM(A.Rcpt_Total)  AS rcptTotal      ';                                                                
    vQuery := vQuery || '     , SUM(A.Rcpt_Cash)   AS rcptCash       ';                                                                
    vQuery := vQuery || '     , SUM(A.Rcpt_Card)   AS rcptCard       ';                                                                
    vQuery := vQuery || '     , SUM(A.Rcpt_Bank)   AS rcptBank       ';                                                                
    vQuery := vQuery || '     , SUM(A.Rcpt_VBank)  AS rcptVBank      ';                                                                
    vQuery := vQuery || '     , SUM(A.Rcpt_PrePay) AS rcptPrePay     ';                                                                
    vQuery := vQuery || '     , SUM(A.Rcpt_Point)  AS rcptPoint      ';                                                                
    vQuery := vQuery || '     , SUM(A.Rcpt_ARS)    AS rcptARS        ';                                                                
    vQuery := vQuery || '     , SUM(A.Rcpt_Coin)   AS rcptCoin       ';                                                                
    vQuery := vQuery || '     , SUM(A.Rcpt_Etc)    AS rcptEtc        ';                                                             
    vQuery := vQuery || '     , SUM(A.ADO_CNT)     AS adoCnt         ';                                 
    vQuery := vQuery || '     , SUM(A.BP_Amt_Sum)  AS bPAmtSum       ';                                                                
    vQuery := vQuery || '     , SUM(A.BP_Pv1_Sum)  AS bPPv1Sum       ';                                                                
    vQuery := vQuery || '     , SUM(A.BP_Pv2_Sum)  AS bPPv2Sum       ';                                                                
    vQuery := vQuery || '     , SUM(A.BP_Pv3_Sum)  AS bPPv3Sum       ';                                                                
    vQuery := vQuery || '     , SUM(A.BP_Date_Cnt) AS bPDateCnt      ';                                                                
    vQuery := vQuery || '     , SUM(A.BP_Amt_Day)  AS bPAmtDay       ';                                                                
    vQuery := vQuery || '     , SUM(A.BP_Amt_Pay)  AS bPAmtPay       ';                                                                
    vQuery := vQuery || '     , SUM(A.BP_Amt_Etc)  AS bPAmtEtc       ';                                
    vQuery := vQuery || '     , SUM(A.BP_Refund_Amt) AS bPRefundAmt  '; 
  END IF;
  
  vQuery := vQuery || '  FROM Ord_Mst A           ';
  vQuery := vQuery || '     , Member B            ';
  vQuery := vQuery || '     , Ord_Deli C            ';
  vQuery := vQuery || ' WHERE A.Userid = B.Userid ';
  vQuery := vQuery || '   AND A.Ord_NO = C.Ord_NO ';
  IF SP_ChkOrder = '1' THEN
    IF (NVL(Length(LTrim(SP_SDate)), 0)    <> 0) THEN vQuery := vQuery || ' AND A.Ord_Date >= ''' || SP_SDate || ''' '; END IF;
    IF (NVL(Length(LTrim(SP_EDate)), 0)    <> 0) THEN vQuery := vQuery || ' AND A.Ord_Date <= ''' || SP_EDate || ''' '; END IF;
  ELSIF SP_ChkOrder = '2' THEN
    IF (NVL(Length(LTrim(SP_SDate)), 0)    <> 0) THEN vQuery := vQuery || ' AND A.Acc_Date >= ''' || SP_SDate || ''' '; END IF;
    IF (NVL(Length(LTrim(SP_EDate)), 0)    <> 0) THEN vQuery := vQuery || ' AND A.Acc_Date <= ''' || SP_EDate || ''' '; END IF;
  END IF;
  
  --IF (NVL(Length(LTrim(SP_Ord_NO)), 0)     <> 0) THEN vQuery := vQuery || ' AND A.Ord_NO LIKE ''%' || SP_Ord_NO || '%'' '; END IF; --Deleted by Binh
     IF SP_License = '1' THEN vQuery := vQuery || ' AND A.License_NO   IS NOT NULL ';
  ELSIF SP_License = '2' THEN vQuery := vQuery || ' AND A.License_Code IS NOT NULL ';
  ELSIF SP_License = '3' THEN vQuery := vQuery || ' AND A.License_NO   IS NULL ';
  END IF;
  IF (NVL(Length(LTrim(SP_Status)), 0)     <> 0) THEN
       IF SP_Status = '0' THEN vQuery := vQuery || ' AND A.Status IN (''A'',''C'',''R'') ';
    ELSIF SP_Status = '1' THEN vQuery := vQuery || ' AND A.Status IN (''A'',''C'',''R'',''X'') ';
    ELSE                       vQuery := vQuery || ' AND A.Status = ''' || SP_Status || ''' '; END IF;
  END IF;
  IF (NVL(Length(LTrim(SP_User_Kind)), 0)     <> 0) THEN vQuery := vQuery || ' AND B.User_Kind = ''' || SP_User_Kind || ''' '; END IF;
  IF (NVL(Length(LTrim(SP_Userid)), 0)     <> 0) THEN                                                                            
    IF SP_ChkUserid = '1' THEN vQuery := vQuery || ' AND A.Userid = ''' || SP_Userid     || ''' '; END IF;                                                                                                       
    IF SP_ChkUserid = '2' THEN vQuery := vQuery || ' AND B.P_ID   = ''' || SP_Userid     || ''' '; END IF;
    IF SP_ChkUserid = '3' THEN vQuery := vQuery || ' AND A.Userid IN (SELECT Userid FROM Member START WITH Userid =''' || SP_Userid || ''' CONNECT BY P_ID = PRIOR Userid) '; END IF;
    IF SP_ChkUserid = '4' THEN vQuery := vQuery || ' AND A.Userid IN (SELECT Userid FROM Member START WITH Userid =''' || SP_Userid || ''' CONNECT BY Userid = PRIOR P_ID) '; END IF;
    IF SP_ChkUserid = '5' THEN vQuery := vQuery || ' AND B.R_ID   = ''' || SP_Userid     || ''' '; END IF;
    IF SP_ChkUserid = '6' THEN vQuery := vQuery || ' AND A.Userid IN (SELECT Userid FROM Member START WITH Userid =''' || SP_Userid || ''' CONNECT BY R_ID = PRIOR Userid) '; END IF;
    IF SP_ChkUserid = '7' THEN vQuery := vQuery || ' AND A.Userid IN (SELECT Userid FROM Member START WITH Userid =''' || SP_Userid || ''' CONNECT BY Userid = PRIOR R_ID) '; END IF;
  END IF;
  IF (NVL(Length(LTrim(SP_Cnt_CD)), 0)   <> 0) THEN vQuery := vQuery || ' AND A.Cnt_CD  = ''' || SP_Cnt_CD   || ''' '; END IF;
  IF (NVL(Length(LTrim(SP_Grp_CD)), 0)   <> 0) THEN vQuery := vQuery || ' AND B.Grp_CD  = ''' || SP_Grp_CD   || ''' '; END IF;
  IF (NVL(Length(LTrim(SP_CTR_CD)), 0)   <> 0) THEN vQuery := vQuery || ' AND A.CTR_CD  = ''' || SP_CTR_CD   || ''' '; END IF;
  IF (NVL(Length(LTrim(SP_Ord_Kind)), 0) <> 0) THEN vQuery := vQuery || ' AND A.Kind_CD = ''' || SP_Ord_Kind || ''' '; END IF;
  IF (NVL(Length(LTrim(SP_Ord_Path)), 0) <> 0) THEN vQuery := vQuery || ' AND A.Path_CD = ''' || SP_Ord_Path || ''' '; END IF;
  IF (NVL(Length(LTrim(SP_Ord_Pay)), 0)  <> 0) THEN vQuery := vQuery || ' AND A.Ord_NO IN (SELECT A.Ord_No FROM Ord_Rcpt A, Ord_Money B WHERE A.Money_No = B.Money_No AND B.Kind = ''' || SP_ord_Pay || ''') '; END IF;
  IF (NVL(Length(LTrim(SP_Addition)), 0) <> 0) THEN 
    IF SP_ChkAddition = '1' THEN vQuery := vQuery || ' AND C.R_Name LIKE ''%' || SP_Addition || '%'' '; END IF;
    IF SP_ChkAddition = '2' THEN vQuery := vQuery || ' AND C.B_Name LIKE ''%' || SP_Addition || '%'' '; END IF;
    IF SP_ChkAddition = '3' THEN vQuery := vQuery || ' AND A.Remark LIKE ''%' || SP_Addition || '%'' '; END IF;
    IF SP_ChkAddition = '4' THEN vQuery := vQuery || ' AND A.Ord_NO IN (SELECT b.Ord_NO FROM Ord_Money a, Ord_Rcpt b WHERE encrypt_pkg.kaidoku_card_no(a.Card_NO) LIKE ''%' || SP_Addition || '%'' AND A.MONEY_NO = B.MONEY_NO) '; END IF;
    IF SP_ChkAddition = '5' THEN vQuery := vQuery || ' AND A.Ord_NO IN (SELECT b.Ord_NO FROM Ord_Money a, Ord_Rcpt b WHERE a.Card_App_NO LIKE ''%' || SP_Addition || '%'' AND A.MONEY_NO = B.MONEY_NO) '; END IF;
    IF SP_ChkAddition = '6' THEN vQuery := vQuery || ' AND C.Invoice_NO LIKE ''%' || SP_Addition || '%'' '; END IF;
    IF SP_ChkAddition = '7' THEN vQuery := vQuery || ' AND A.Ord_NO LIKE ''%' || SP_Addition || '%'' '; END IF; --Added by Binh
  END IF;
  
  IF SP_Kind = 'DATA' THEN
    vQuery := vQuery || ' ORDER BY A.Ord_Date DESC      ';  -- Hint 가 제대로 적용이 안되어, 해당 라인 유지.
  END IF;      
  vLine := '2';                                                                                     
  OPEN C1 FOR vQuery;
  vLine := '3';
  LOOP
    IF SP_Kind = 'DATA' THEN
      vLine := '31';
      FETCH C1 INTO vData;
      EXIT WHEN C1%NOTFOUND;
      vLine := '4';
                           
      vType := Obj_4230(  vData.Status             -- STATUS       VARCHAR2 (4000)               
                        , vData.ordNo              -- ORDNO        VARCHAR2 (20) NOT NULL   
                        , vData.ordNoOrg           -- ORDNOORG     VARCHAR2 (20) NOT NULL   
                        , vData.ordDate            -- ORDDATE      VARCHAR2 (8) NOT NULL   
                        , vData.ordDate2           -- ORDDATE2     VARCHAR2 (4000)   
                        , vData.accDate            -- ACCDATE      VARCHAR2 (8)   
                        , vData.accDate2           -- ACCDATE2     VARCHAR2 (4000)   
                        , vData.canDate            -- CANDATE      VARCHAR2 (4000)   
                        , vData.cntNameOrd         -- CNTNAMEORD   VARCHAR2 (4000)   
                        , vData.licenseCode        -- LICENSECODE  VARCHAR2 (4)   
                        , vData.licenseNO          -- LICENSENO    VARCHAR2 (30)
                        , vData.licenseDate        -- LICENSEDATE  DATE   
                        , vData.Userid             -- USERID       VARCHAR2 (10) NOT NULL   
                        , vData.Username           -- USERNAME     VARCHAR2 (45)   
                        , vData.userKindName       -- USERKINDNAME VARCHAR2 (4000)   
                        , vData.cntNameMem         -- CNTNAMEMEM   VARCHAR2 (4000)   
                        , vData.grpName            -- GRPNAME      VARCHAR2 (4000)   
                        , vData.RankName           -- RANKNAME     VARCHAR2 (4000)   
                        , vData.rId                -- RID          VARCHAR2 (10)   
                        , vData.rName              -- RNAME        VARCHAR2 (4000)   
                        , vData.omniYN             -- OMNIYN       VARCHAR2 (1) NOT NULL   
                        , vData.countryName        -- COUNTRYNAME  VARCHAR2 (4000)   
                        , vData.kindCd             -- KINDCD       VARCHAR2 (5) NOT NULL   
                        , vData.kindName           -- KINDNAME     VARCHAR2 (4000)   
                        , vData.pathCd             -- PATHCD       VARCHAR2 (5) NOT NULL   
                        , vData.pathName           -- PATHNAME     VARCHAR2 (4000)   
                        , vData.sumPdt             -- SUMPDT       VARCHAR2 (81)   
                        , vData.sumPdtCnt          -- SUMPDTCNT    NUMBER NOT NULL   
                        , vData.sumPdtQty          -- SUMPDTQTY    NUMBER NOT NULL   
                        , vData.ordPrice           -- ORDPRICE     NUMBER NOT NULL   
                        , vData.ordVAT             -- ORDVAT       NUMBER NOT NULL   
                        , vData.ordAmt             -- ORDAMT       NUMBER NOT NULL   
                        , vData.ordPv1             -- ORDPV1       NUMBER NOT NULL   
                        , vData.ordPv2             -- ORDPV2       NUMBER NOT NULL   
                        , vData.ordPv3             -- ORDPV3       NUMBER NOT NULL   
                        , vData.ordPoint           -- ORDPOINT     NUMBER NOT NULL   
                        , vData.deliNO             -- DELINO       VARCHAR2 (20)   
                        , vData.deliAmt            -- DELIAMT      NUMBER NOT NULL   
                        , vData.collAmt            -- COLLAMT      NUMBER NOT NULL   
                        , vData.totalAmt           -- TOTALAMT     NUMBER NOT NULL   
                        , vData.rcptYN             -- RCPTYN       VARCHAR2 (4000)   
                        , vData.rcptRemain         -- RCPTREMAIN   NUMBER NOT NULL   
                        , vData.rcptTotal          -- RCPTTOTAL    NUMBER NOT NULL   
                        , vData.rcptCash           -- RCPTCASH     NUMBER NOT NULL   
                        , vData.rcptCard           -- RCPTCARD     NUMBER NOT NULL   
                        , vData.rcptBank           -- RCPTBANK     NUMBER NOT NULL   
                        , vData.rcptVBank          -- RCPTVBANK    NUMBER NOT NULL   
                        , vData.rcptPrePay         -- RCPTPREPAY   NUMBER NOT NULL   
                        , vData.rcptPoint          -- RCPTPOINT    NUMBER NOT NULL   
                        , vData.rcptARS            -- RCPTARS      NUMBER NOT NULL   
                        , vData.rcptCoin           -- RCPTCOIN     NUMBER NOT NULL   
                        , vData.rcptEtc            -- RCPTETC      NUMBER NOT NULL   
                        , vData.adoNo              -- ADONO        VARCHAR2 (10)   
                        , vData.adoCnt             -- ADOCNT       NUMBER NOT NULL   
                        , vData.adoDate            -- ADODATE      VARCHAR2 (4000)   
                        , vData.taxInvoYN          -- TAXINVOYN    VARCHAR2 (1)   
                        , vData.taxInvoNO          -- TAXINVONO    VARCHAR2 (20)   
                        , vData.taxInvoDate        -- TAXINVODATE  VARCHAR2 (4000)   
                        , vData.bPAmtSum           -- BPAMTSUM     NUMBER NOT NULL   
                        , vData.bPPv1Sum           -- BPPV1SUM     NUMBER NOT NULL   
                        , vData.bPPv2Sum           -- BPPV2SUM     NUMBER NOT NULL   
                        , vData.bPPv3Sum           -- BPPV3SUM     NUMBER NOT NULL   
                        , vData.bPDateCnt          -- BPDATECNT    NUMBER NOT NULL   
                        , vData.bPAmtDay           -- BPAMTDAY     NUMBER NOT NULL   
                        , vData.bPAmtPay           -- BPAMTPAY     NUMBER NOT NULL   
                        , vData.bPAmtEtc           -- BPAMTETC     NUMBER NOT NULL   
                        , vData.bPRefundDate       -- BPREFUNDDATE VARCHAR2 (4000)   
                        , vData.bPRefundAmt        -- BPREFUNDAMT  NUMBER NOT NULL   
                        , vData.Remark             -- REMARK       VARCHAR2 (90)   
                        , vData.insDate            -- INSDATE      DATE NOT NULL   
                        , vData.insUser            -- INSUSERA     VARCHAR2 (10) NOT NULL   
                        , vData.updDate            -- UPDDATE      DATE   
                        , vData.updUser            -- UPDUSER      VARCHAR2 (10)
                        , vData.ctrCd              -- CTRCD        VARCHAR2(10)
                        , vData.mUseKana
                        , vData.mUseEnglish  
                        );
                                                              
    ELSIF SP_Kind = 'COUNT' THEN                                    
      FETCH C1 INTO vData2;                                         
      EXIT WHEN C1%NOTFOUND;                                        
      
      vType := Obj_4230(  ''  -- vData.Status                                
                        , TO_CHAR(vData2.Count) -- vData.ordNo                                 
                        , ''  -- vData.ordNoOrg                              
                        , ''  -- vData.ordDate                               
                        , ''  -- vData.ordDate2                              
                        , ''  -- vData.accDate                               
                        , ''  -- vData.accDate2                              
                        , ''  -- vData.canDate                               
                        , ''  -- vData.cntNameOrd                            
                        , ''  -- vData.licenseCode                           
                        , ''  -- vData.licenseNO                             
                        , ''  -- vData.licenseDate                           
                        , ''  -- vData.Userid                                
                        , ''  -- vData.Username                              
                        , ''  -- vData.userKindName                          
                        , ''  -- vData.cntNameMem                            
                        , ''  -- vData.grpName                               
                        , ''  -- vData.RankName                              
                        , ''  -- vData.rId                                   
                        , ''  -- vData.rName                                 
                        , ''  -- vData.omniYN                                
                        , ''  -- vData.countryName                           
                        , ''  -- vData.kindCd                                
                        , ''  -- vData.kindName                              
                        , ''  -- vData.pathCd                                
                        , ''  -- vData.pathName                              
                        , ''  -- vData.sumPdt                                
                        , 0  -- vData.sumPdtCnt                             
                        , 0  -- vData.sumPdtQty                             
                        , 0  -- vData.ordPrice                              
                        , 0  -- vData.ordVAT                                
                        , 0  -- vData.ordAmt                                
                        , 0  -- vData.ordPv1                                
                        , 0  -- vData.ordPv2                                
                        , 0  -- vData.ordPv3                                
                        , 0  -- vData.ordPoint                              
                        , ''  -- vData.deliNO                                
                        , 0  -- vData.deliAmt                               
                        , 0  -- vData.collAmt                               
                        , 0  -- vData.totalAmt                              
                        , ''  -- vData.rcptYN                                
                        , 0  -- vData.rcptRemain                            
                        , 0  -- vData.rcptTotal                             
                        , 0  -- vData.rcptCash                              
                        , 0  -- vData.rcptCard                              
                        , 0  -- vData.rcptBank                              
                        , 0  -- vData.rcptVBank                             
                        , 0  -- vData.rcptPrePay                            
                        , 0  -- vData.rcptPoint                             
                        , 0  -- vData.rcptARS                               
                        , 0  -- vData.rcptCoin                              
                        , 0  -- vData.rcptEtc                               
                        , ''  -- vData.adoNo                                 
                        , 0  -- vData.adoCnt                                
                        , ''  -- vData.adoDate                               
                        , ''  -- vData.taxInvoYN                             
                        , ''  -- vData.taxInvoNO                             
                        , ''  -- vData.taxInvoDate                           
                        , 0  -- vData.bPAmtSum                              
                        , 0  -- vData.bPPv1Sum                              
                        , 0  -- vData.bPPv2Sum                              
                        , 0  -- vData.bPPv3Sum                              
                        , 0  -- vData.bPDateCnt                             
                        , 0  -- vData.bPAmtDay                              
                        , 0  -- vData.bPAmtPay                              
                        , 0  -- vData.bPAmtEtc                              
                        , ''  -- vData.bPRefundDate                          
                        , 0  -- vData.bPRefundAmt                           
                        , ''  -- vData.Remark                                
                        , ''  -- vData.insDate                               
                        , ''  -- vData.insUser                               
                        , ''  -- vData.updDate                               
                        , ''  -- vData.updUser
                        , ''  -- vData.ctrCd
                        , ''
                        , ''
                        );      
    ELSIF SP_Kind = 'SUM' THEN
      FETCH C1 INTO vData1;                                         
      EXIT WHEN C1%NOTFOUND;
      
      vType := Obj_4230(  ''  -- vData.Status                                
                        , ''  -- vData.ordNo                                 
                        , ''  -- vData.ordNoOrg                              
                        , ''  -- vData.ordDate                               
                        , ''  -- vData.ordDate2                              
                        , ''  -- vData.accDate                               
                        , ''  -- vData.accDate2                              
                        , ''  -- vData.canDate                               
                        , ''  -- vData.cntNameOrd                            
                        , ''  -- vData.licenseCode                           
                        , ''  -- vData.licenseNO                             
                        , ''  -- vData.licenseDate                           
                        , ''  -- vData.Userid                                
                        , ''  -- vData.Username                              
                        , ''  -- vData.userKindName                          
                        , ''  -- vData.cntNameMem                            
                        , ''  -- vData.grpName                               
                        , ''  -- vData.RankName                              
                        , ''  -- vData.rId                                   
                        , ''  -- vData.rName                                 
                        , ''  -- vData.omniYN                                
                        , ''  -- vData.countryName                           
                        , ''  -- vData.kindCd                                
                        , ''  -- vData.kindName                              
                        , ''  -- vData.pathCd                                
                        , ''  -- vData.pathName                              
                        , ''  -- vData.sumPdt                                
                        , vData1.sumPdtCnt                             
                        , vData1.sumPdtQty                             
                        , vData1.ordPrice                              
                        , vData1.ordVAT                                
                        , vData1.ordAmt                                
                        , vData1.ordPv1                                
                        , vData1.ordPv2                                
                        , vData1.ordPv3                                
                        , vData1.ordPoint                              
                        , ''  -- vData.deliNO                                
                        , vData1.deliAmt                               
                        , vData1.collAmt                               
                        , vData1.totalAmt                              
                        , ''  -- vData.rcptYN                                
                        , vData1.rcptRemain                            
                        , vData1.rcptTotal                             
                        , vData1.rcptCash                              
                        , vData1.rcptCard                              
                        , vData1.rcptBank                              
                        , vData1.rcptVBank                             
                        , vData1.rcptPrePay                            
                        , vData1.rcptPoint                             
                        , vData1.rcptARS                               
                        , vData1.rcptCoin                              
                        , vData1.rcptEtc                               
                        , ''  -- vData.adoNo                                 
                        , vData1.adoCnt                                
                        , ''  -- vData.adoDate                               
                        , ''  -- vData.taxInvoYN                             
                        , ''  -- vData.taxInvoNO                             
                        , ''  -- vData.taxInvoDate                           
                        , vData1.bPAmtSum                              
                        , vData1.bPPv1Sum                              
                        , vData1.bPPv2Sum                              
                        , vData1.bPPv3Sum                              
                        , vData1.bPDateCnt                             
                        , vData1.bPAmtDay                              
                        , vData1.bPAmtPay                              
                        , vData1.bPAmtEtc                              
                        , ''  -- vData.bPRefundDate                          
                        , vData1.bPRefundAmt                           
                        , ''  -- vData.Remark                                
                        , ''  -- vData.insDate                               
                        , ''  -- vData.insUser                               
                        , ''  -- vData.updDate                               
                        , ''  -- vData.updUser
                        , ''  -- vData.ctrCd
                        , ''
                        , ''
                        ); 
    END IF;
                                
    PIPE ROW(vType);
        
  END LOOP;

  RETURN;  
  ------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    RETURN;
END;
/