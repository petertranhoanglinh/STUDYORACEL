CREATE OR REPLACE PACKAGE BODY WOWNET_V6.Order_PKG AS
/* -------------------------------------------------------------------------- */
/* Company Name : WOWCNS                                                      */
/* Schema  KInd : Package                                                     */
/* Schema  Name : Order_PKG                                                   */
/* Work    Date : 2021-03-09 Create by Hwang                                  */
/* Remark       : Order Information Menagement Package                        */
/* -------------------------------------------------------------------------- */
/* Package Member : 1) Order_Batch_SP     [Update]                            */
/*                  2) Money_SP           [Insert, Update]                    */
/*                  3) Money_Del_SP       [Delete]                            */
/*                  4) ORD_RCPT_INS_SP    [Insert, Update]                    */
/*                  5) TMP_ORD_MST_INS_SP [Insert, Update]                    */
/*                  6) TMP_ORD_PDT_INS_SP [Insert, Update]                    */
/*                  7) Tmp_Ord_Del_SP     [Delete]                            */
/*                  8) Tmp_Ord_Money_Ins_SP [Insert, Update]                  */
/*                  9) Tmp_Ord_Money_Del_SP [Delete]                          */
/*                 10) Tmp_Ord_PDT_Clear_SP [Delete]                          */
/*                 11) Tmp_Ord_PDT_Change_SP [Update]                         */
/*                 12) Tmp_Ord_Deli_Ins_SP[Insert]                            */
/*                 13) ORD_INS_SP         [Insert]                            */
/*                 14) Log_Ord_Error_SP   [Insert]                            */
/*                 15) Ord_Tmp_Chk_SP     [Select]                            */
/*                 16) Pg_Pay_SP          [Insert]                            */
/*                 16-1) Pg_Pay_Web_SP    [Insert]                            */
/*                 17) Ord_Mst_Info_UPD_SP[Update]                            */
/*                 18) Ord_Pdt_UPD_SP     [Update]                            */
/*                 19) Ord_Money_UPD_SP   [Update]                            */
/*                 20) Ord_DeliInfo_UPD_SP[Update]                            */
/*                 21) Ord_Cancel_SP      [Update]                            */
/*                 22) Ord_Return_SP      [Update]                            */
/*                 23) Ord_Pdt_Tmp_SP     [Insert]                            */
/*                 24) Ord_Money_Tmp_SP   [Insert]                            */
/*                 25) ORD_MST_BP_SP      [Insert]                            */
/*                 26) Ord_Deli_BP_SP     [Insert]                            */
/*                 27) ORD_PDT_INS_SP     [Insert]                            */
/*                 28) Ord_Money_SP       [Insert/Update]                     */
/*                 29) ORD_BP_CHK_SP      [Insert/Update]                     */
/*                 30) ORD_IMPORT_SP      [Insert]                            */
/*                 31) ORD_IMPORT_DO_SP   [Insert]                            */
/*                 32) ORD_Money_CHK_SP   [Update]                            */
/*                 33) VACC_RCPT_INS_SP   [Update]                            */
/* -------------------------------------------------------------------------- */
/* 6.0 반품                                                                   */
/* 1. 주문반품 마스터 : ORDER_PKG.ORD_MST_BP_SP                               */  
/* 2. 주문반품 배송 : ORDER_PKG.Ord_Deli_BP_SP                                */
/* 3. 주문반품 상품 : ORDER_PKG.ORD_PDT_INS_SP                                */
/* 4. 주문반품 입금 : ORDER_PKG.MONEY_SP                                      */




/* -------------------------------------------------------------------------- */
/* Package Member : Order_Batch_SP [Update]                                   */
/* Work    Date   : 2021-03-09 Created by Hwang                               */
/* -------------------------------------------------------------------------- */
PROCEDURE Order_Batch_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)                                                                                      
  SP_Ord_NO             IN  VARCHAR2, --    NOT NULL 주문번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리)
  SP_Acc_Date           IN  VARCHAR2, --        NULL 승인일자(YYYYMMDD)
  SP_Cnt_CD             IN  VARCHAR2, --    NOT NULL 주문센터코드 (Center.Cnt_CD)
  SP_Kind_CD            IN  VARCHAR2, --    NOT NULL 주문유형코드 (Code.Code_CD) 신규주문/재구매/오토십...
  SP_Path_CD            IN  VARCHAR2, --    NOT NULL 주문경로코드 (Code.Code_CD) 본사/센터/마이오피스/...
  SP_Remark             IN  VARCHAR2, --        NULL 비고사항                                                                                                       
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, --    NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --        NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --        NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --        NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --        NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --        NULL 장치구분 (PC, PHONE, TABLET) 
  SP_IP_Addr            IN  VARCHAR2, --        NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --        NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, --    [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  --    [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  v                     Ord_Mst%ROWTYPE; -- 테이블 변수 Bi？n table
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Lang_CD INTO vLang_CD
    FROM SM_User
   WHERE Userid = SP_Work_User;

  ------------------------------------------------------------------------------
  -- [저장, 수정 공통 체크사항] 필수입력항목의 미입력 및 입력데이터 오류여부 등을 체크한다.
  -- [M？c ki？m tra chung đ？ l？u va s？a đ？i] Ki？m tra xem m？c ch？a đ？？c nh？p c？a h？ng m？c c？n nh？p va m？c nh？p d？ li？u co b？ l？i hay khong.
  ------------------------------------------------------------------------------
  IF (NVL(Length(LTrim(SP_Com_ID)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회사아이디를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF (NVL(Length(LTrim(SP_Ord_NO)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문번호를 선택하시기 바랍니다.', vLang_CD); 
    RETURN;  
  END IF;

  ------------------------------------------------------------------------------
  -- 데이터를 변경한다.Thay đ？i d？ li？u
  ------------------------------------------------------------------------------
  UPDATE Ord_Mst
     SET Acc_Date = SP_Acc_Date  -- 승인일자
       , Cnt_CD   = SP_Cnt_CD    -- 주문센터코드 (Center.Cnt_CD)
       , Kind_CD  = SP_Kind_CD   -- 주문유형코드 (Code.Code_CD) 신규주문/재구매/오토십...
       , Path_CD  = SP_Path_CD   -- 주문경로코드 (Code.Code_CD) 본사/센터/마이오피스/...
       , Remark   = SP_Remark    -- 비고사항                                                                                                                            
       , Upd_Date = SYSDATE      -- 작업일자(타임스탬프)
       , Upd_User = SP_Work_User -- 작업자번호 
   WHERE Ord_NO   = SP_Ord_NO;   -- 주문번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리)
  ------------------------------------------------------------------------------
  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 수정되었습니다.', vLang_CD); -- đa đ？？c s？a binh th？？ng
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  ------------------------------------------------------------------------------
  Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage('수정', vLang_CD), ufMessage('주문번호 :', vLang_CD) || ' ' || SP_Ord_NO );
  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;










/* -------------------------------------------------------------------------- */
/* Package Member : Money_SP [Insert, Update]                                 */
/* Work    Date   : 2021-03-09 Created by Hwang                               */
/* -------------------------------------------------------------------------- */
PROCEDURE Money_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)                                                                                      
  SP_Money_NO           IN  VARCHAR2, -- PK NOT NULL 입금번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리)
  SP_Money_NO_Org       IN  VARCHAR2, --        NULL 원입금번호(정상입금시 Money_NO와 같은 번호가 들어간다.)
  SP_Userid             IN  VARCHAR2, --    NOT NULL 회원번호 (Member.Userid)
  SP_Reg_Date           IN  VARCHAR2, --    NOT NULL 등록일자(YYYYMMDD)
  SP_Can_Date           IN  VARCHAR2, --        NULL 취소일자(YYYYMMDD)    
  SP_Kind               IN  VARCHAR2, --    NOT NULL 결제구분(Code.Code_CD) - CASH 현금 / BANK 무통장 / CARD 신용카드 / VBANK 가상계좌 / PREPAY 선결제 / POINT 포인트 / ARS ARS결제 / COIN 코인 / ETC 기타
  SP_Amt                IN  NUMBER,   --    NOT NULL 입금액
  SP_Amt_Used           IN  NUMBER,   --    NOT NULL 사용한 금액
  SP_Amt_Balance        IN  NUMBER,   --    NOT NULL 미사용 잔액 
  SP_Card_CD            IN  VARCHAR2, --    NOT NULL 신용카드결제시 : 카드사코드 / 무통장송금시 : 회사 은행코드 (Bank.Bank_CD) 
  SP_Card_NO            IN  VARCHAR2, --        NULL 신용카드결제시 : 카드번호   / 무통장송금시 : 회사 입금계좌
  SP_Card_Holder        IN  VARCHAR2, --        NULL 신용카드결제시 : 카드소유주명
  SP_Card_CMS_Rate      IN  NUMBER,   --    NOT NULL 신용카드 수수료율
  SP_Card_Install       IN  NUMBER,   --    NOT NULL 신용카드 할부개월수
  SP_Card_YYMM          IN  VARCHAR2, --        NULL 신용카드 유효년월(YYMM)
  SP_Card_App_NO        IN  VARCHAR2, --        NULL 승인번호
  SP_Card_App_Date      IN  VARCHAR2, --        NULL 승인일자(YYYYMMDD)
  SP_Self_YN            IN  VARCHAR2, --    NOT NULL 본인결제여부(Y/N)
  SP_Use_YN             IN  VARCHAR2, --    NOT NULL 사용여부(Y/N)
  SP_Remark             IN  VARCHAR2, --        NULL 비고사항
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, --    NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --        NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --        NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --        NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --        NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --        NULL 장치구분 (PC, PHONE, TABLET) 
  SP_IP_Addr            IN  VARCHAR2, --        NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --        NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_KeyValue           OUT VARCHAR2, --    [리턴값] 주문번호
  SP_RetCode            OUT VARCHAR2, --    [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  --    [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  v                     Ord_Money%ROWTYPE; -- 테이블 변수 Bi？n table
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vIns_Upd              VARCHAR2(6); -- 저장, 수정-- L？u, s？a
  vCard_No              Ord_Money.Card_No%TYPE; -- 하이픈 포함 카드번호      
  vSeq                  PLS_INTEGER;
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Lang_CD INTO vLang_CD
    FROM SM_User
   WHERE Userid = SP_Work_User;
  
  ------------------------------------------------------------------------------
  -- 등록된 데이터가 있는지 체크한다. (저장 또는 수정 처리용)
  -- Ki？m tra xem co d？ li？u đa đ？ng ky hay khong. (L？u ho？c x？ ly s？a đ？i)
  ------------------------------------------------------------------------------
  BEGIN
    SELECT * INTO v
      FROM Ord_Money
     WHERE Money_NO = SP_Money_NO;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN v.Money_NO := '-1';
  END;

  IF v.Money_NO = '-1' THEN vIns_Upd := 'INS'; ELSE vIns_Upd := 'UPD'; END IF;
  -- [저장, 수정 공통 체크사항] 필수입력항목의 미입력 및 입력데이터 오류여부 등을 체크한다.
  -- [M？c ki？m tra chung đ？ l？u va s？a đ？i] Ki？m tra xem m？c ch？a đ？？c nh？p c？a h？ng m？c c？n nh？p va m？c nh？p d？ li？u co b？ l？i hay khong.
  ------------------------------------------------------------------------------
  IF (NVL(Length(LTrim(SP_Com_ID)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회사아이디를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF (NVL(Length(LTrim(SP_Userid)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회원을 입력하시기 바랍니다.', vLang_CD); 
    RETURN;  
  END IF;

  IF (NVL(Length(LTrim(SP_Reg_Date)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('입금일자를 입력하시기 바랍니다.', vLang_CD); 
    RETURN;  
  END IF;

  IF (NVL(Length(LTrim(SP_Kind)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('입금구분 선택하시기 바랍니다.', vLang_CD); 
    RETURN;  
  END IF;

  IF (NVL(Length(LTrim(SP_Amt)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('입금액을 입력하시기 바랍니다.', vLang_CD); 
    RETURN;  
  END IF;

  IF (SP_Use_YN = 'N') AND (NVL(Length(LTrim(SP_Can_Date)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('사용하지 않을 경우에는 반드시 취소일자를 입력해야 합니다.', vLang_CD); 
    RETURN;  
  END IF;

  ------------------------------------------------------------------------------
  -- 카드로 결제한 경우 
  ------------------------------------------------------------------------------
  --IF (SP_Kind = 'CARD') THEN 
  IF SP_Kind IN (ufCom_CD(SP_Com_ID)||'s02') THEN 
    IF (NVL(Length(LTrim(SP_Card_CD)), 0) = 0) THEN  
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('카드사를 선택하시기 바랍니다.', vLang_CD); 
      RETURN;  
    END IF;

    IF (NVL(Length(LTrim(SP_Card_NO)), 0) = 0) THEN  
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('카드번호를 입력하시기 바랍니다.', vLang_CD); 
      RETURN;  
    END IF;

    IF (NVL(Length(LTrim(SP_Card_Holder)), 0) = 0) THEN  
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('카드소유주명을 입력하시기 바랍니다.', vLang_CD); 
      RETURN;  
    END IF;

    IF (NVL(Length(LTrim(SP_Card_Install)), 0) = 0) THEN  
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('카드 할부개월수를 입력하시기 바랍니다.', vLang_CD); 
      RETURN;  
    END IF;

    IF (NVL(Length(LTrim(SP_Card_YYMM)), 0) = 0) THEN  
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('카드 유효기간(년/월)을 입력하시기 바랍니다.', vLang_CD); 
      RETURN;  
    END IF;
    
    ------------------------------------------------------------------------------
    -- 카드 번호는 하이픈 생성 한다. 
    ------------------------------------------------------------------------------
    vCard_No := UFADD_HYPHEN(SP_Card_NO,'CARD',vLang_CD);    
  END IF;

  ------------------------------------------------------------------------------
  -- 무통장입금으로 결제한 경우 
  ------------------------------------------------------------------------------
  IF SP_Kind IN (ufCom_CD(SP_Com_ID)||'s03') THEN 
    ------------------------------------------------------------------------------
    -- 계좌 번호는 하이픈을 생성하지 않는다. 
    ------------------------------------------------------------------------------
    vCard_No := SP_Card_NO;
    ------------------------------------------------------------------------------
  END IF;

  ------------------------------------------------------------------------------
  -- 저장 L？u
  ------------------------------------------------------------------------------
  IF vIns_Upd = 'INS' THEN
    ----------------------------------------------------------------------------
    /*
    v.Money_NO := TO_CHAR(SYSDATE, 'YYYYMMDD-HH24MISS') || '-';

    SELECT COUNT(1) + 1 INTO vSeq
      FROM Ord_Money
     WHERE Money_NO LIKE v.Money_NO || '%';
     
    v.Money_NO := v.Money_NO || '-' || LPAD(vSeq, 3, '0'); 
    */
    
    IF SP_Money_NO IS NOT NULL THEN -- 이미 생성한 입금번호가 있는경우 ( PG 연동 ) / 22.05.20 최지운
        v.Money_NO := SP_Money_NO;
    ELSE
        v.Money_NO := TO_CHAR(SYSDATE, 'YYMMDD-HHMISS-') || LPAD(SEQ_MONEY.NEXTVAL, 3, 0);
    END IF;
    
    
    ----------------------------------------------------------------------------
    -- 데이터를 저장한다. L？u d？ li？u
    ----------------------------------------------------------------------------
    INSERT INTO Ord_Money
           ( Com_ID        -- 회사번호 (Company.Com_ID)                                                                                                           
           , Money_NO      -- 입금번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리)
           , Money_NO_Org  -- 입금번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리)
           , Seq           -- SEQ 순번
           , Userid        -- 회원번호 (Member.Userid)
           , Reg_Date      -- 등록일자(YYYYMMDD)
           , Can_Date      -- 취소일자(YYYYMMDD)    
           , Kind          -- 결제구분(Code.Code_CD) - CASH 현금 / BANK 무통장 / CARD 신용카드 / VBANK 가상계좌 / PREPAY 선결제 / POINT 포인트 / ARS ARS결제 / COIN 코인 / ETC 기타
           , Amt           -- 입금액
           , Amt_Used      -- 사용한 금액
           , Amt_Balance   -- 미사용 잔액 
           , Card_CD       -- 신용카드결제시 : 카드사코드 / 무통장송금시 : 회사 은행코드 (Bank.Bank_CD) 
           , Card_NO       -- 신용카드결제시 : 카드번호   / 무통장송금시 : 회사 입금계좌
           , Card_Holder   -- 신용카드결제시 : 카드소유주명
           , Card_CMS_Rate -- 신용카드 수수료율
           , Card_Install  -- 신용카드 할부개월수
           , Card_YYMM     -- 신용카드 유효년월(YYMM)
           , Card_App_NO   -- 승인번호
           , Card_App_Date -- 승인일자(YYYYMMDD)
           , Self_YN       -- 본인결제여부(Y/N)
           , Use_YN        -- 사용여부(Y/N)
           , Remark        -- 비고사항
           , Ins_User )
    VALUES ( SP_Com_ID        
           , v.Money_NO     
           , v.Money_NO
           , 1     
           , SP_Userid       
           , SP_Reg_Date     
           , SP_Can_Date     
           , SP_Kind         
           , SP_Amt          
           , SP_Amt_Used     
           , SP_Amt_Balance  
           , SP_Card_CD      
           , Encrypt_PKG.Enc_Card(vCard_No)      
           , SP_Card_Holder  
           , SP_Card_CMS_Rate
           , SP_Card_Install 
           , SP_Card_YYMM    
           , SP_Card_App_NO  
           , SP_Card_App_Date
           , SP_Self_YN      
           , SP_Use_YN       
           , SP_Remark       
           , SP_Work_User );
           
    ----------------------------------------------------------------------------
    SP_RetCode  := 'OK';
    SP_RetStr  := ufMessage('정상적으로 저장되었습니다.', vLang_CD); -- đa đ？？c l？u binh th？？ng
    SP_KeyValue := v.Money_NO;
    ----------------------------------------------------------------------------
  END IF;

  ------------------------------------------------------------------------------
  -- 수정 S？a 
  ------------------------------------------------------------------------------
  IF vIns_Upd = 'UPD' THEN
    ----------------------------------------------------------------------------
    -- 데이터를 변경한다.Thay đ？i d？ li？u
    ----------------------------------------------------------------------------
    UPDATE Ord_Money
       SET Com_ID        = SP_Com_ID         -- 회사번호 (Company.Com_ID)                                                                                                           
         , Money_NO_Org  = SP_Money_NO_Org   -- 원입금번호(정상입금시 Money_NO와 같은 번호가 들어간다.)
         , Userid        = SP_Userid         -- 회원번호 (Member.Userid)
         , Reg_Date      = SP_Reg_Date       -- 등록일자(YYYYMMDD)
         , Can_Date      = SP_Can_Date       -- 취소일자(YYYYMMDD)    
         , Kind          = SP_Kind           -- 결제구분(Code.Code_CD) - CASH 현금 / BANK 무통장 / CARD 신용카드 / VBANK 가상계좌 / PREPAY 선결제 / POINT 포인트 / ARS ARS결제 / COIN 코인 / ETC 기타
         , Amt           = SP_Amt            -- 입금액
         , Amt_Used      = SP_Amt_Used       -- 사용한 금액
         , Amt_Balance   = SP_Amt_Balance    -- 미사용 잔액 
         , Card_CD       = SP_Card_CD        -- 신용카드결제시 : 카드사코드 / 무통장송금시 : 회사 은행코드 (Bank.Bank_CD) 
         , Card_NO       = Encrypt_PKG.Enc_Card(vCard_No)        -- 신용카드결제시 : 카드번호   / 무통장송금시 : 회사 입금계좌
         , Card_Holder   = SP_Card_Holder    -- 신용카드결제시 : 카드소유주명
         , Card_CMS_Rate = SP_Card_CMS_Rate  -- 신용카드 수수료율
         , Card_Install  = SP_Card_Install   -- 신용카드 할부개월수
         , Card_YYMM     = SP_Card_YYMM      -- 신용카드 유효년월(YYMM)
         , Card_App_NO   = SP_Card_App_NO    -- 승인번호
         , Card_App_Date = SP_Card_App_Date  -- 승인일자(YYYYMMDD)
         , Self_YN       = SP_Self_YN        -- 본인결제여부(Y/N)
         , Use_YN        = SP_Use_YN         -- 사용여부(Y/N)
         , Remark        = SP_Remark         -- 비고사항                                                                                                                            
         , Upd_Date      = SYSDATE           -- 작업일자(타임스탬프)
         , Upd_User      = SP_Work_User      -- 작업자번호 
     WHERE Money_NO      = SP_Money_NO;      -- 입금번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리)

    ----------------------------------------------------------------------------
    SP_RetCode := 'OK';
    SP_RetStr  := ufMessage('정상적으로 수정되었습니다.', vLang_CD); -- đa đ？？c s？a binh th？？ng
    ----------------------------------------------------------------------------
  END IF;

  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  ------------------------------------------------------------------------------
  Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage(vIns_Upd, vLang_CD), ufMessage('입금번호 :', vLang_CD) || ' ' || v.Money_NO );
  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Money_SP [Insert, Update] - END -                         */
/* -------------------------------------------------------------------------- */











/* -------------------------------------------------------------------------- */
/* Package Member : Money_Del_SP [Delete]                                     */
/* Work    Date   : 2021-03-09 Created by Hwang                               */
/* -------------------------------------------------------------------------- */
PROCEDURE Money_Del_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)
  SP_Money_NO           IN  VARCHAR2, -- PK NOT NULL 입금번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리)
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, --    NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --        NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --        NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --        NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --        NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --        NULL 장치구분 (PC, PHONE, TABLET) 
  SP_IP_Addr            IN  VARCHAR2, --        NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --        NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  v                     Ord_Money%ROWTYPE; -- 테이블 변수 Bi？n table
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Lang_CD INTO vLang_CD
    FROM SM_User
   WHERE Userid = SP_Work_User;
  
  ------------------------------------------------------------------------------
  -- 해당 데이터를 읽는다. đ？c d？ li？u phu h？p
  ------------------------------------------------------------------------------
  SELECT * INTO v
    FROM Ord_Money
   WHERE Money_NO = SP_Money_NO;

  ------------------------------------------------------------------------------
  -- 데이터를 삭제한다.Xoa d？ li？u
  ------------------------------------------------------------------------------
  DELETE FROM Ord_Money
   WHERE Money_NO = SP_Money_NO;

  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 삭제되었습니다.', vLang_CD); -- đa đ？？c xoa binh th？？ng

  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  ------------------------------------------------------------------------------
  Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage('삭제', vLang_CD), ufMessage('입금번호 :', vLang_CD) || ' ' || SP_Money_NO );
  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Money_Del_SP [Delete] - END -                             */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : VACC_RCPT_INS_SP [Insert, Update]                          */
/* Work    Date   : 2021-06-30 Created by Hwang                               */
/* -------------------------------------------------------------------------- */
PROCEDURE VACC_RCPT_INS_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)
  SP_Ord_NO             IN  ORD_RCPT.Ord_NO%TYPE,
  SP_Money_NO           IN  ORD_RCPT.Money_NO%TYPE,
  SP_Userid             IN  VARCHAR2, --    NOT NULL 회원번호 (Member.Userid)
  SP_Amt                IN  ORD_RCPT.Amt%TYPE,
  SP_Work_User          IN  ORD_RCPT.Work_User%TYPE,
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, --    NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --        NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --        NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --        NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --        NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --        NULL 장치구분 (PC, PHONE, TABLET) 
  SP_IP_Addr            IN  VARCHAR2, --        NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --        NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vKind                 Ord_Money.Kind%TYPE;
  vAcc_Date             Ord_Mst.Acc_Date%TYPE;
  vCnt                  PLS_INTEGER;
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Ctr_Cd INTO vLang_CD
    FROM Member
   WHERE COM_ID = SP_Com_ID
     AND Userid = SP_Work_User;
  
  ------------------------------------------------------------------------------
  -- 해당 결제정보에서 결제유형을 읽어온다.
  -- 1:현금,2:무통장,3:신용카드,4:포인트,5:기타
  ------------------------------------------------------------------------------
  SELECT SUBSTR(Kind, 3) INTO vKind 
    FROM Ord_Money
   WHERE Com_ID = SP_Com_ID
     AND Money_NO = SP_Money_NO;
          
  ------------------------------------------------------------------------------
  -- 입금정보에 처리한 금액에 대해 사용금액을 업데이트한다.
  ------------------------------------------------------------------------------
  UPDATE ORD_MONEY
     SET Amt_Used = Amt_Used + SP_Amt
   WHERE Money_NO = SP_Money_NO;
   
  ------------------------------------------------------------------------------
  -- 주문데이터를 업데이트한다.
  -----------------------------------------------------------------------------
  IF    vKind = 's01' THEN UPDATE ORD_MST SET Rcpt_Cash   = Rcpt_Cash   + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO; 
  ELSIF vKind = 's02' THEN UPDATE ORD_MST SET Rcpt_Card   = Rcpt_Card   + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO;
  ELSIF vKind = 's03' THEN UPDATE ORD_MST SET Rcpt_Bank   = Rcpt_Bank   + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO; 
  ELSIF vKind = 's04' THEN UPDATE ORD_MST SET RCPT_VBank  = RCPT_VBank  + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO; 
  ELSIF vKind = 's05' THEN UPDATE ORD_MST SET RCPT_PREPAY = RCPT_PREPAY + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO; 
  ELSIF vKind = 's06' THEN UPDATE ORD_MST SET Rcpt_Point  = Rcpt_Point  + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO;
  ELSIF vKind = 's07' THEN UPDATE ORD_MST SET RCPT_ARS    = RCPT_ARS    + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO;
  ELSIF vKind = 's08' THEN UPDATE ORD_MST SET RCPT_Coin   = RCPT_Coin   + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO; 
  ELSIF vKind = 's09' THEN UPDATE ORD_MST SET Rcpt_Etc    = Rcpt_Etc    + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO; 
  END IF;
  
  UPDATE ORD_MST
     SET Rcpt_YN   = 'Y'
   WHERE Ord_NO    = SP_Ord_NO
     AND Rcpt_YN   = 'N'
     AND Total_Amt = Rcpt_Total;

  ----------------------------------------------------------------------------
  -- 해당 주문서의 입금완료여부 및 승인일자 등록여부를 읽는다. 
  ----------------------------------------------------------------------------
  SELECT COUNT(1) INTO vCnt
    FROM Ord_Mst
   WHERE Ord_NO = SP_Ord_NO
     AND Rcpt_YN = 'Y';

  IF vCnt = 1 THEN 
    ----------------------------------------------------------------------------
    -- 해당 주문서의 입금데이터 중에서 가장 마지막 입금일자를 읽는다.
    ----------------------------------------------------------------------------
    SELECT MAX(B.Reg_Date) INTO vAcc_Date
      FROM Ord_Rcpt A
         , Ord_Money B
     WHERE A.Money_NO = B.Money_NO
       AND A.Ord_NO = SP_Ord_NO;
     
    UPDATE ORD_MST
       SET Acc_Date = vAcc_Date
     WHERE Ord_NO  = SP_Ord_NO;
     
    UPDATE ORD_RCPT
       SET AMT     = SP_Amt
     WHERE MONEY_NO  = SP_Money_NO;     
  END IF;
  
  COMMIT;

  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  ------------------------------------------------------------------------------
  Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage('UPD', vLang_CD), ufMessage('입금번호 :', vLang_CD) || ' ' || SP_Money_NO );
  
  ------------------------------------------------------------------------------
  -- 주문결제처리 변경로그(Ord_Rcpt_Log)테이블에 데이터를 기록한다.
  -- 1:저장,2:수정,3:삭제 
  ------------------------------------------------------------------------------
  --MONEY_PKG.Ord_Rcpt_Log_SP(SP_Ord_NO, SP_Money_NO, '1', SP_Work_User);
  SP_RetCode  := 'OK';
  SP_RetStr  := ufMessage('정상적으로 저장되었습니다.', vLang_CD); -- đa đ？？c l？u binh th？？ng
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('error:'|| SUBSTR(SQLERRM, 12,100));
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;  
END;
/* -------------------------------------------------------------------------- */
/* Package Member : VACC_RCPT_INS_SP [Insert, Update] - END -                 */
/* -------------------------------------------------------------------------- */
/* -------------------------------------------------------------------------- */
/* Package Member : ORD_RCPT_INS_SP [Insert, Update] - END -                  */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : TMP_ORD_MST_INS_SP [Insert]                               */
/* Work    Date   : 2021-03-22 Created by Lee                                 */
/* -------------------------------------------------------------------------- */
PROCEDURE TMP_ORD_MST_INS_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)
  SP_ORD_NO_TMP         IN  NUMBER,   --    NOT NULL 임시주문번호 (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP) S？ tu？n t？m th？i (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP)
  SP_SID                IN  VARCHAR2, --        NULL 세션아이디(비로그인 주문등록시에 사용) ID phien (đ？？c s？ d？ng khi đ？ng ky đ？n đ？t hang khong đ？ng nh？p)
  SP_ORD_DATE           IN  VARCHAR2, --    NOT NULL 주문일자(YYYYMMDD) Ngay đ？t hang (YYYYMMDD)
  SP_ACC_DATE           IN  VARCHAR2, --        NULL 승인일자(YYYYMMDD) Ngay phe duy？t (YYYYMMDD)
  SP_USERID             IN  VARCHAR2, --    NOT NULL 회원번호 (Member.Userid) S？ thanh vien (Member.Userid)
  SP_CNT_CD             IN  VARCHAR2, --    NOT NULL 주문센터코드(Center.Cnt_CD) Ma trung tam đ？t hang (Center.Cnt_CD)
  SP_KIND_CD            IN  VARCHAR2, --    NOT NULL 주문유형코드(Code.Code_CD) 신규주문/재구매/오토십... Ma lo？i đ？n đ？t hang (Code.Code_CD) đ？n hang m？i / Mua l？i / T？ đ？ng ...
  SP_PATH_CD            IN  VARCHAR2, --    NOT NULL 주문경로 (Code.Code_CD) đ？？ng d？n đ？t hang (Code.Code_CD)
  SP_RCPT_TOTAL         IN  NUMBER,   --    NOT NULL 결제금액-합계 T？ng s？ ti？n thanh toan
  SP_RCPT_CASH          IN  NUMBER,   --    NOT NULL 결제금액-현금 S？ ti？n thanh toan - ti？n m？t (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_CARD          IN  NUMBER,   --    NOT NULL 결제금액-카드 S？ ti？n thanh toan - th？ (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_BANK          IN  NUMBER,   --    NOT NULL 결제금액-무통장 (환경설정에서 사용여부 설정가능)S？ ti？n thanh toan - chuy？n kho？n ngan hang (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_VBANK         IN  NUMBER,   --    NOT NULL 결제금액-가상계좌 (환경설정에서 사용여부 설정가능)S？ ti？n thanh toan - Tai kho？n ？o (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_PREPAY        IN  NUMBER,   --    NOT NULL 결제금액-선결제 (환경설정에서 사용여부 설정가능) S？ ti？n thanh toan - Tr？ tr？？c (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_POINT         IN  NUMBER,   --    NOT NULL 결제금액-포인트 (환경설정에서 사용여부 설정가능)S？ ti？n thanh toan - đi？m (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_ARS           IN  NUMBER,   --    NOT NULL 결제금액-ARS (환경설정에서 사용여부 설정가능)S？ ti？n thanh toan - ARS (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_COIN          IN  NUMBER,   --    NOT NULL 결제금액-코인 (환경설정에서 사용여부 설정가능)S？ ti？n thanh toan - Coin (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_ETC           IN  NUMBER,   --    NOT NULL 결제금액-기타 (환경설정에서 사용여부 설정가능)S？ ti？n thanh toan - Khac (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_REMARK             IN  VARCHAR2, --        NULL 비고사항 Nh？n xet
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호 ID ng？？i lam vi？c
  SP_Work_Kind          IN  VARCHAR2, --    NOT NULL 작업경로 W:WOWNET, M:MYOFFICE
  SP_Direct_YN          IN  VARCHAR2, --    NOT NULL 바로구매여부 Y/N
  ------------------------------------------------------------------------------
  SP_KeyValue           OUT VARCHAR2, -- [리턴값]
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  v                     ORD_MST_TMP%ROWTYPE; -- 테이블 변수 Bi？n table
  vTmp                  NUMBER;
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vIns_Upd              VARCHAR2(6);    -- 저장, 수정-- L？u, s？a
  vORD_NO_TMP           NUMBER;
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  IF SP_Work_Kind = 'M'  THEN
    SELECT Ctr_Cd INTO vLang_CD
      FROM Member
     WHERE COM_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  ELSE
    SELECT Lang_CD INTO vLang_CD
        FROM SM_User
       WHERE COM_ID = SP_Com_ID
         AND Userid = SP_Work_User;  
  END IF;
  
  ------------------------------------------------------------------------------
  -- 등록된 데이터가 있는지 체크한다. (저장 또는 수정 처리용)
  -- Ki？m tra xem co d？ li？u đa đ？ng ky hay khong. (L？u ho？c x？ ly s？a đ？i)
  ------------------------------------------------------------------------------
  IF (NVL(Length(LTrim(SP_ORD_DATE)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문일자를 입력하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  IF (NVL(Length(LTrim(SP_USERID)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회원번호를 입력하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  IF (NVL(Length(LTrim(SP_CNT_CD)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문센터코드를 선택하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  IF (SP_Work_Kind = 'W') THEN
    IF (NVL(Length(LTrim(SP_KIND_CD)), 0) = 0) THEN  
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('주문유형코드를 선택하세요.', vLang_CD); 
      RETURN;  
    END IF;
  END IF;
  
  IF (NVL(Length(LTrim(SP_PATH_CD)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문경로를 선택하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  ------------------------------------------------------------------------------
  -- 등록된 데이터가 있는지 체크한다. (저장 또는 수정 처리용)
  -- Ki？m tra xem co d？ li？u đa đ？ng ky hay khong. (L？u ho？c x？ ly s？a đ？i)
  ------------------------------------------------------------------------------
  BEGIN
    SELECT * INTO v
      FROM ORD_MST_TMP
     WHERE COM_ID = SP_COM_ID
       AND ORD_NO_TMP = SP_ORD_NO_TMP;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN v.ORD_NO_TMP := '-1';
  END;
  
  IF v.ORD_NO_TMP = '-1' THEN vIns_Upd := 'INS'; ELSE vIns_Upd := 'UPD'; END IF;
  
  
  IF vIns_Upd = 'INS' THEN
    ----------------------------------------------------------------------------
    -- 장바구니 번호를 발번한다.
    ----------------------------------------------------------------------------
    vORD_NO_TMP := SEQ_Tmp.nextval; 
    
    
    ----------------------------------------------------------------------------
    -- 데이터를 저장한다. L？u d？ li？u
    ----------------------------------------------------------------------------
    INSERT INTO ORD_MST_TMP
           ( COM_ID
           , ORD_NO_TMP                
           , SID           
           , ORD_DATE    
           , ACC_DATE  
           , USERID        
           , CNT_CD  
           , KIND_CD      
           , STATUS        
           , PATH_CD            
           , REMARK 
           , WORK_USER
           , WORK_Kind
           , Direct_YN     
           )
    VALUES ( SP_COM_ID        
           , vORD_NO_TMP    
           , SP_SID           
           , SP_ORD_DATE
           , SP_ACC_DATE      
           , SP_USERID        
           , SP_CNT_CD
           , SP_KIND_CD        
           , 'BEFORE'        
           , SP_PATH_CD      
           , SP_REMARK       
           , SP_WORK_USER
           , SP_Work_Kind
           , SP_Direct_YN
           );
  
    ----------------------------------------------------------------------------
    SP_RetCode  := 'OK';
    SP_RetStr  := ufMessage('정상적으로 저장되었습니다.', vLang_CD); -- đa đ？？c l？u binh th？？ng
    SP_KeyValue := vORD_NO_TMP;
    ----------------------------------------------------------------------------     
  ELSE
    ----------------------------------------------------------------------------
    -- 데이터를 변경한다.Thay đ？i d？ li？u
    ----------------------------------------------------------------------------
    UPDATE ORD_MST_TMP
       SET SID          = SP_SID
         , ORD_DATE     = SP_ORD_DATE
         , ACC_DATE     = SP_ACC_DATE
         , USERID       = SP_USERID
         , CNT_CD       = SP_CNT_CD
         , KIND_CD      = SP_KIND_CD
         , PATH_CD      = SP_PATH_CD
         , RCPT_TOTAL   = SP_RCPT_TOTAL
         , RCPT_CASH    = SP_RCPT_CASH
         , RCPT_CARD    = SP_RCPT_CARD
         , RCPT_BANK    = SP_RCPT_BANK
         , RCPT_VBANK   = SP_RCPT_VBANK
         , RCPT_PREPAY  = SP_RCPT_PREPAY
         , RCPT_POINT   = SP_RCPT_POINT
         , RCPT_ARS     = SP_RCPT_ARS
         , RCPT_COIN    = SP_RCPT_COIN
         , RCPT_ETC     = SP_RCPT_ETC
         , REMARK       = SP_REMARK
         , WORK_DATE    = SYSDATE
         , WORK_USER    = SP_WORK_USER      
     WHERE ORD_NO_TMP = SP_ORD_NO_TMP;

    ----------------------------------------------------------------------------
    SP_RetCode := 'OK';
    SP_RetStr  := ufMessage('정상적으로 수정되었습니다.', vLang_CD); -- đa đ？？c s？a binh th？？ng
    SP_KeyValue := SP_ORD_NO_TMP;
    ----------------------------------------------------------------------------  
  END IF;


  --COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('error:'|| SUBSTR(SQLERRM, 12,100));
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : TMP_ORD_MST_INS_SP [Insert] - END -                       */
/* -------------------------------------------------------------------------- */









/* -------------------------------------------------------------------------- */
/* Package Member : TMP_ORD_PDT_INS_SP [Insert]                               */
/* Work    Date   : 2021-03-22 Created by Lee                                 */
/* -------------------------------------------------------------------------- */
PROCEDURE TMP_ORD_PDT_INS_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)
  SP_ORD_NO_TMP         IN  NUMBER,   --    NOT NULL 임시주문번호 (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP) S？ tu？n t？m th？i (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP)
  SP_PDT_SEQ            IN  NUMBER,   --    NOT NULL 주문상품순번 đ？t mua s？n ph？m
  SP_USERID             IN  VARCHAR2, --    NOT NULL 회원번호(Member.Userid) S？ thanh vien (Member.Userid)
  SP_PDT_CD             IN  VARCHAR2, --    NOT NULL 상품코드(Pdt_Mst.Pdt_CD) Ma s？n ph？m (Pdt_Mst.Pdt_CD)
  SP_PDT_OPTION         IN  VARCHAR2, --        NULL 상품 옵션정보 Thong tin l？a ch？n s？n ph？m
  SP_PDT_KIND           IN  VARCHAR2, --    NOT NULL 상품구분 - NOR 일반상품 / STM 세트마스터 / STD 세트구성품 / GFT 기프트증정품 Phan lo？i s？n ph？m - S？n ph？m chung c？a NOR / B？ chinh STM / Thanh ph？n b？ STD / Qua t？ng GFT
  SP_QTY                IN  NUMBER,   --    NOT NULL 수량 S？ l？？ng
  SP_PRICE              IN  NUMBER,   --    NOT NULL 단가 đ？n gia
  SP_VAT                IN  NUMBER,   --    NOT NULL 부가세 Thu？ VAT
  SP_AMT                IN  NUMBER,   --    NOT NULL 금액 S？ ti？n
  SP_PV1                IN  NUMBER,   --    NOT NULL PV1
  SP_PV2                IN  NUMBER,   --    NOT NULL PV2
  SP_PV3                IN  NUMBER,   --    NOT NULL PV3
  SP_POINT              IN  NUMBER,   --    NOT NULL 적립포인트 Thu nh？p đi？m
  SP_PDT_STATUS         IN  VARCHAR2, --    NOT NULL 입출고구분(ORD:주문, C-I:교환입고, C-O:교환출고, RT:반품, CAN:취소) Phan lo？i giao nh？n va nh？n (ORD: đ？t hang, C-I: bien lai trao đ？i, C-O: giao d？ch trao đ？i, RT: tr？ l？i, CAN: h？y b？)
  SP_SERIAL_NO          IN  VARCHAR2, --        NULL 일련번호 S？ se-ri
  SP_REMARK             IN  VARCHAR2, --        NULL 비고사항 Nh？n xet
  SP_ORD_YN             IN  VARCHAR2, --        NULL 주문가능상품(Y/N) Co th？ đ？t hang s？n ph？m hay khong (Y/N)
  SP_DELI_SEQ           IN  NUMBER,   --    NOT NULL 배송순번 (다중배송 또는 하나의 주문서에 2개 이상의 박스로 배송할 경우 용도로 사용함) Th？ t？ giao hang (đ？？c s？ d？ng cho nhi？u l？n giao hang ho？c giao hang trong m？t h？p khi đ？t hang t？ 2 s？n ph？m tr？ len)
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호 ID ng？？i lam vi？c
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  v                     ORD_PDT_TMP%ROWTYPE; -- 테이블 변수 Bi？n table
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vIns_Upd              VARCHAR2(6);    -- 저장, 수정-- L？u, s？a
  vWork_Kind            VARCHAR2(1);
  vError                NUMBER;
  vCnt                  NUMBER;
  vMax                  NUMBER;
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Work_Kind INTO vWork_Kind
    FROM Ord_Mst_Tmp
   WHERE Com_Id = SP_Com_Id
     AND Ord_No_Tmp = SP_ORD_NO_TMP;

  IF vWork_Kind = 'M' THEN
    SELECT Ctr_Cd INTO vLang_CD
      FROM Member
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User; 
  ELSE 
    SELECT Lang_CD INTO vLang_CD
      FROM SM_User
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  END IF;
vError := 1;

  ------------------------------------------------------------------------------
  -- 등록된 데이터가 있는지 체크한다. (저장 또는 수정 처리용)
  -- Ki？m tra xem co d？ li？u đa đ？ng ky hay khong. (L？u ho？c x？ ly s？a đ？i)
  ------------------------------------------------------------------------------
  IF (NVL(Length(LTrim(SP_ORD_NO_TMP)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('임시주문번호가 없습니다. 장바구니를 확인하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  IF (NVL(Length(LTrim(SP_PDT_CD)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('등록할 상품이 없습니다. 장바구니를 확인하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  
  IF SP_QTY <= 0 THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('상품수량이 없습니다. 상품수량을 확인하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  
  IF vWork_Kind = 'W' THEN
    IF SP_AMT <= 0 THEN
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('주문하실 상품금액을 확인하세요.', vLang_CD); 
      RETURN;  
    END IF;
  END IF;
  
  BEGIN
    SELECT * INTO v
      FROM ORD_PDT_TMP
     WHERE COM_ID = SP_COM_ID
       AND ORD_NO_TMP = SP_ORD_NO_TMP
       AND PDT_CD = SP_PDT_CD;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN v.ORD_NO_TMP := '-1';
  END;

  IF v.ORD_NO_TMP = '-1' THEN vIns_Upd := 'INS'; ELSE vIns_Upd := 'UPD'; END IF;
  
  vError := 2;
  IF vIns_Upd = 'INS' THEN
    ----------------------------------------------------------------------------
    --
    SELECT COUNT(1) INTO vCnt
      FROM ORD_PDT_TMP 
     WHERE COM_ID = SP_COM_ID
       AND ORD_NO_TMP = SP_ORD_NO_TMP
       AND PDT_SEQ = SP_PDT_SEQ;
       
    SELECT MAX(Pdt_Seq) INTO vMax
      FROM ORD_PDT_TMP 
     WHERE COM_ID = SP_COM_ID
       AND ORD_NO_TMP = SP_ORD_NO_TMP;
       
    IF vCnt > 0 THEN vMax := vMax + 1; ELSE vMax := SP_PDT_SEQ; END IF;
    
    
    -- 데이터를 저장한다. L？u d？ li？u
    ----------------------------------------------------------------------------
    INSERT INTO ORD_PDT_TMP
           ( Com_ID     
           , ORD_NO_TMP 
           , PDT_SEQ    
           , USERID     
           , PDT_CD     
           , PDT_OPTION 
           , PDT_KIND   
           , QTY        
           , PRICE      
           , VAT        
           , AMT        
           , PV1        
           , PV2        
           , PV3        
           , POINT      
           , PDT_STATUS 
           , SERIAL_NO  
           , REMARK     
           , ORD_YN       
           , DELI_SEQ   
           , Work_User  
           )
     VALUES( SP_Com_ID     
           , SP_ORD_NO_TMP 
           , vMax
           , SP_USERID     
           , SP_PDT_CD     
           , SP_PDT_OPTION 
           , SP_PDT_KIND   
           , SP_QTY        
           , SP_PRICE      
           , SP_VAT        
           , SP_AMT        
           , SP_PV1        
           , SP_PV2        
           , SP_PV3        
           , SP_POINT      
           , SP_PDT_STATUS 
           , SP_SERIAL_NO  
           , SP_REMARK     
           , SP_ORD_YN       
           , SP_DELI_SEQ   
           , SP_Work_User  
           );
           
  ELSE
  vError := 3;
    ----------------------------------------------------------------------------
    -- 데이터를 변경한다.Thay đ？i d？ li？u
    ----------------------------------------------------------------------------
    UPDATE ORD_PDT_TMP
       SET PDT_OPTION = SP_PDT_OPTION
         , PDT_KIND   = SP_PDT_KIND
         , QTY        = SP_QTY
         , PRICE      = SP_PRICE
         , VAT        = SP_VAT
         , AMT        = SP_AMT
         , PV1        = SP_PV1
         , PV2        = SP_PV2
         , PV3        = SP_PV3
         , POINT      = SP_POINT
         , PDT_STATUS = SP_PDT_STATUS
         , SERIAL_NO  = SP_SERIAL_NO
         , REMARK     = SP_REMARK
         , ORD_YN     = SP_ORD_YN 
         , DELI_SEQ   = SP_DELI_SEQ
         , Work_User  = SP_Work_User
     WHERE PDT_CD     = SP_PDT_CD
       AND ORD_NO_TMP = SP_ORD_NO_TMP;
      
  END IF;
  vError := 4;

  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 등록되었습니다.', vLang_CD);

  --COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100) || vError;
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : TMP_ORD_PDT_INS_SP [Insert] - END -                       */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : Tmp_Ord_Del_SP [Delete]                                   */
/* Work    Date   : 2021-03-22 Created by Lee                                 */
/* -------------------------------------------------------------------------- */
PROCEDURE Tmp_Ord_Del_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)
  SP_Ord_NO_Tmp         IN  NUMBER,   --    NOT NULL 임시주문번호 (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP) S？ tu？n t？m th？i (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP)
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호 ID ng？？i lam vi？c
  ------------------------------------------------------------------------------
  SP_KeyValue           OUT VARCHAR2, -- [리턴값]
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vWork_Kind            VARCHAR2(1);
  vUserid               Ord_Mst_Tmp.Userid%TYPE;
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Work_Kind, Userid INTO vWork_Kind, vUserid
    FROM Ord_Mst_Tmp
   WHERE Com_Id = SP_Com_Id
     AND Ord_No_Tmp = SP_ORD_NO_TMP;

  ------------------------------------------------------------------------------
  -- 호출처에 따른 사용언어 확인.
  ------------------------------------------------------------------------------
  IF vWork_Kind = 'M' THEN
    SELECT Ctr_Cd INTO vLang_CD
      FROM Member
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User; 
  ELSE 
    SELECT Lang_CD INTO vLang_CD
      FROM SM_User
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  END IF;
  
  ------------------------------------------------------------------------------
  -- 회원의 모든 임시 주문 데이터 삭제.
  ------------------------------------------------------------------------------
  FOR C1 IN (SELECT Ord_NO_Tmp
               FROM Ord_Mst_Tmp
              WHERE Com_ID = SP_Com_ID
                AND Userid = vUserid
                AND Work_Kind = vWork_Kind
                  ) LOOP
                  
  DELETE FROM Ord_Deli_Tmp 
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO_Tmp = C1.Ord_NO_Tmp;
     
  DELETE FROM Ord_Money_Tmp 
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO_Tmp = C1.Ord_NO_Tmp;                     
                  
  DELETE FROM Ord_Pdt_Tmp 
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO_Tmp = C1.Ord_NO_Tmp;

  DELETE FROM Ord_Mst_Tmp 
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO_Tmp = C1.Ord_NO_Tmp;
     
  END LOOP;

  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 삭제되었습니다.', vLang_CD);
  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Tmp_Ord_Del_SP [Delete] - END -                           */
/* -------------------------------------------------------------------------- */









/* -------------------------------------------------------------------------- */
/* Package Member : Tmp_Ord_Money_Ins_SP [Insert/Update]                      */
/* Work    Date   : 2021-04-01 Created by Lee                                 */
/* -------------------------------------------------------------------------- */
PROCEDURE Tmp_Ord_Money_Ins_SP (
  SP_COM_ID             IN VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID) S？ cong ty (Company.Com_ID)
  SP_MONEY_NO           IN VARCHAR2, --    NOT NULL 입금번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리) S？ ti？n g？i (YYMMDD-HHMISS- + day 3 ch？ s？, t？ng s？ 17 ch？ s？)
  SP_MONEY_NO_Org       IN VARCHAR2, --    NOT NULL 원입금번호(정상입금시 Money_NO와 같은 번호가 들어간다.
  SP_ORD_NO_TMP         IN NUMBER,   --    NOT NULL 임시주분번호 (SEQ_Tmp 시퀀스 사용) S？ tu？n t？m th？i (s？ d？ng chu？i SEQ_Tmp)
  SP_SEQ                IN NUMBER,   --    NOT NULL 결제순번 (SEQ_Tmp 시퀀스 사용) Th？ t？ thanh toan (SEQ_Tmp) S？ d？ng th？ t？)
  SP_USERID             IN VARCHAR2, --    NOT NULL 회원번호 S？ thanh vien
  SP_KIND               IN VARCHAR2, --    NOT NULL 결제구분(Code.Code_CD) - CASH 현금 / BANK 무통장 / CARD 신용카드 / VBANK 가상계좌 / PREPAY 선결제 / POINT 포인트 / COIN 코인 / ETC 기타 Phan lo？i thanh toan (Code.Code_CD) -CASH Ti？n m？t / Ngan hang ngan hang / Th？ tin d？ng CARD / Tai kho？n ？o VBANK / Tr？ tr？？c TR？ / đi？m / COIN Coin / ETC Khac
  SP_REG_DATE           IN VARCHAR2, --    NOT NULL 등록일자 (YYYYMMDD) Ngay đ？ng ky (YYYYMMDD)
  SP_AMT                IN NUMBER,   --    NOT NULL 입금액 S？ ti？n ky g？i
  SP_AMT_USED           IN NUMBER,   --    NOT NULL 사용한 금액 S？ l？？ng s？ d？ng
  SP_REMARK             IN VARCHAR2, --        NULL 비고사항 Nh？n xet
  SP_CARD_CD            IN VARCHAR2, --    NOT NULL 신용카드결제시 : 카드사코드 / 무통장송금시 : 회사 은행코드 (Bank.Bank_CD) Thanh toan th？ tin d？ng: Ma cong ty th？ / Chuy？n kho？n ngan hang: Ma ngan hang (Bank.Bank_CD)
  SP_CARD_RATE          IN NUMBER,   --        NULL 카드수수료율 Phi th？
  SP_CARD_INSTALL       IN NUMBER,   --    NOT NULL 신용카드 할부개월수 Thang tr？ gop th？ tin d？ng
  SP_CARD_NO            IN VARCHAR2, --        NULL 신용카드결제시 : 카드번호   / 무통장송금시 : 회사 입금계좌 Thanh toan th？ tin d？ng: S？ th？ / Chuy？n kho？n ngan hang: Tai kho？n chuy？n kho？n ngan hang
  SP_CARD_HOLDER        IN VARCHAR2, --        NULL 신용카드결제시 : 카드소유주명 Thanh toan b？ng th？ tin d？ng: ten ch？ th？
  SP_CARD_YYMM          IN VARCHAR2, --        NULL 신용카드 유효년월(YYMM) Ngay th？ tin d？ng co hi？u l？c (YYMM)
  SP_CARD_APP_NO        IN VARCHAR2, --        NULL 승인번호 S？ phe duy？t
  SP_CARD_APP_DATE      IN VARCHAR2, --        NULL 승인일자(YYYYMMDD) Ngay phe duy？t (YYYYMMDD)
  SP_WORK_USER          IN VARCHAR2, --    NOT NULL 작업자번호 ID ng？？i lam vi？c
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  v                     ORD_MONEY_TMP%ROWTYPE; -- 테이블 변수 Bi？n table
  vLang_CD              VARCHAR2(2);           -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vMoney_No             VARCHAR2(17);          -- 저장, 수정-- L？u, s？a
  vStatus               VARCHAR2(7);           -- ORD_MST_TMP.STATUS 상태값
  vWork_Kind            VARCHAR2(1);
  vCard_No              Ord_Money.Card_No%TYPE; -- 하이픈 포함 카드번호
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------  
  SELECT Work_Kind INTO vWork_Kind
    FROM Ord_Mst_Tmp
   WHERE Com_Id = SP_Com_Id
     AND Ord_No_Tmp = SP_ORD_NO_TMP;

  IF vWork_Kind = 'M' THEN
    SELECT Ctr_Cd INTO vLang_CD
      FROM Member
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User; 
  ELSE 
    SELECT Lang_CD INTO vLang_CD
      FROM SM_User
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  END IF;
    
  
  ------------------------------------------------------------------------------
  -- 데이터 체크.
  ------------------------------------------------------------------------------
  IF (NVL(Length(LTrim(SP_ORD_NO_TMP)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('임시주문번호가 없습니다. 장바구니를 확인하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  IF (NVL(Length(LTrim(SP_KIND)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('결제구분을 확인하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  IF SP_AMT <= 0 THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('입금금액을 확인하세요.', vLang_CD); 
    RETURN;  
  END IF;
  

  ------------------------------------------------------------------------------
  -- 카드를 제외한 나머지 건들은 기존 데이터를 삭제하고 재등록한다.
  ------------------------------------------------------------------------------
  IF SP_KIND NOT IN (ufCom_CD(SP_Com_ID)||'s02') THEN 
    DELETE FROM ORD_MONEY_TMP
     WHERE COM_ID = SP_COM_ID
       AND ORD_NO_TMP = SP_ORD_NO_TMP
       AND KIND = SP_KIND;
  END IF;
  
 
  ------------------------------------------------------------------------------
  -- 쇼핑몰결제시 카드결제 단건 잔류시  삭제.
  ------------------------------------------------------------------------------
  IF vWork_Kind = 'M' THEN
    DELETE FROM ORD_MONEY_TMP
     WHERE COM_ID = SP_COM_ID
       AND ORD_NO_TMP = SP_ORD_NO_TMP
       AND KIND = SP_KIND;
  END IF; 

  ----------------------------------------------------------------------------
  -- 입금번호를 발번한다. (YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리)
  -- 카드와 가상계좌는 자동발번하지 않는다.
  ----------------------------------------------------------------------------
  IF SP_KIND NOT IN (ufCom_CD(SP_Com_ID)||'s02', ufCom_CD(SP_Com_ID)||'s04') THEN 
    vMoney_No := TO_CHAR(SYSDATE, 'YYMMDD-HHMISS-') || LPAD(SEQ_MONEY.NEXTVAL, 3, 0);
  ELSE
    vMoney_No := SP_MONEY_NO;  
  END IF;
  
  ------------------------------------------------------------------------------
  -- 카드 번호는 하이픈 생성 한다. 
  ------------------------------------------------------------------------------
  IF SP_KIND IN (ufCom_CD(SP_Com_ID)||'s02') THEN
    vCard_No := UFADD_HYPHEN(SP_Card_NO,'CARD',vLang_CD);
  ELSIF SP_KIND IN (ufCom_CD(SP_Com_ID)||'s04') THEN
    vCard_No := SP_Card_NO;
  END IF;
  
    
  ----------------------------------------------------------------------------
  -- 데이터를 저장한다. L？u d？ li？u
  ----------------------------------------------------------------------------
  INSERT INTO ORD_MONEY_TMP
         ( COM_ID        
         , ORD_NO_TMP    
         , SEQ
         , MONEY_NO      
         , MONEY_NO_ORG  
         , USERID        
         , KIND          
         , REG_DATE      
         , AMT           
         , AMT_USED      
         , REMARK        
         , CARD_CD       
         , CARD_RATE     
         , CARD_INSTALL  
         , CARD_NO       
         , CARD_HOLDER   
         , CARD_YYMM     
         , CARD_APP_NO   
         , CARD_APP_DATE      
         , WORK_USER      
         )
   VALUES( SP_COM_ID        
         , SP_ORD_NO_TMP    
         , SP_SEQ
         , vMoney_No      
         , SP_MONEY_NO_Org  
         , SP_USERID        
         , SP_KIND          
         , SP_REG_DATE      
         , SP_AMT           
         , SP_AMT_USED      
         , SP_REMARK        
         , SP_CARD_CD       
         , SP_CARD_RATE     
         , SP_CARD_INSTALL  
         , vCard_No       
         , SP_CARD_HOLDER   
         , SP_CARD_YYMM     
         , SP_CARD_APP_NO   
         , SP_CARD_APP_DATE 
         , SP_WORK_USER
         );
  
  ----------------------------------------------------------------------------
  -- 입력한 데이터가 카드면 상태값 업데이트
  ----------------------------------------------------------------------------
  IF SP_KIND = ufCom_CD(SP_Com_ID)||'s02' THEN
    SELECT STATUS INTO vStatus 
      FROM ORD_MST_TMP
     WHERE COM_ID = SP_COM_ID
       AND ORD_NO_TMP = SP_ORD_NO_TMP;
    
    IF vStatus = 'BEFORE' THEN
      UPDATE ORD_MST_TMP
         SET STATUS = 'AFTER'
       WHERE COM_ID = SP_COM_ID
         AND ORD_NO_TMP = SP_ORD_NO_TMP;
       
    END IF;
    
  END IF; 
  

  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 삭제되었습니다.', vLang_CD);
  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Tmp_Ord_Money_Ins_SP [Insert/Update] - END -              */
/* -------------------------------------------------------------------------- */









/* -------------------------------------------------------------------------- */
/* Package Member : Tmp_Ord_Money_Del_SP [Delete]                             */
/* Work    Date   : 2021-04-01 Created by Lee                                 */
/* -------------------------------------------------------------------------- */
PROCEDURE Tmp_Ord_Money_Del_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)
  SP_Money_No           IN  VARCHAR2, --    NOT NULL 임시입금확인번호
  SP_SEQ                IN  NUMBER,   --    NOT NULL 결제순번 (SEQ_Tmp 시퀀스 사용) Th？ t？ thanh toan (SEQ_Tmp) S？ d？ng th？ t？)
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호 ID ng？？i lam vi？c
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vPathCd               VARCHAR2(5);
BEGIN
  SELECT Lang_CD INTO vLang_CD
    FROM SM_User
   WHERE Com_ID = SP_Com_ID
     AND Userid = SP_Work_User;
       
  DELETE FROM Ord_Money_Tmp 
   WHERE Com_ID = SP_Com_ID
     AND Money_No = SP_Money_No
     AND SEQ = SP_SEQ;

  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 삭제되었습니다.', vLang_CD);
  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Tmp_Ord_Money_Del_SP [Delete] - END -                     */
/* -------------------------------------------------------------------------- */









/* -------------------------------------------------------------------------- */
/* Package Member : Tmp_Ord_PDT_Clear_SP [Delete]                             */
/* Work    Date   : 2021-04-01 Created by Lee                                 */
/* -------------------------------------------------------------------------- */
PROCEDURE Tmp_Ord_PDT_Clear_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)
  SP_Ord_NO_Tmp         IN  NUMBER,   --    NOT NULL 임시주문번호 (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP) S？ tu？n t？m th？i (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP)
  SP_PDT_CD             IN  VARCHAR2, --        NULL 상품코드(Pdt_Mst.Pdt_CD) Ma s？n ph？m (Pdt_Mst.Pdt_CD)
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호 ID ng？？i lam vi？c
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
BEGIN
  ------------------------------------------------------------------------------
  -- PDT_CD가 있으면 해당 상품삭제. 없으면 전체삭제
  -- If SP_PDT_CD is null, delete all. If there is a value, only the product code is deleted.
  ------------------------------------------------------------------------------
  IF SP_PDT_CD IS NULL THEN 
    DELETE FROM Ord_Pdt_Tmp 
     WHERE Com_ID = SP_Com_ID
       AND Ord_NO_Tmp = SP_Ord_NO_Tmp;
     
  ELSE
    DELETE FROM Ord_Pdt_Tmp 
     WHERE Com_ID = SP_Com_ID
       AND Ord_NO_Tmp = SP_Ord_NO_Tmp
       AND PDT_CD = SP_PDT_CD;
     
  END IF;
     

  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 삭제되었습니다.', vLang_CD);
  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Tmp_Ord_PDT_Clear_SP [Delete] - END -                     */
/* -------------------------------------------------------------------------- */









/* -------------------------------------------------------------------------- */
/* Package Member : Tmp_Ord_PDT_Change_SP [Insert]                            */
/* Work    Date   : 2021-04-01 Created by Lee                                 */
/* -------------------------------------------------------------------------- */
PROCEDURE Tmp_Ord_PDT_Change_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)
  SP_ORD_NO_TMP         IN  NUMBER,   --    NOT NULL 임시주문번호 (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP) S？ tu？n t？m th？i (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP)
  SP_PDT_SEQ            IN  NUMBER,   --    NOT NULL 주문상품순번 đ？t mua s？n ph？m
  SP_PDT_CD             IN  VARCHAR2, --    NOT NULL 상품코드(Pdt_Mst.Pdt_CD) Ma s？n ph？m (Pdt_Mst.Pdt_CD)
  SP_PDT_OPTION         IN  VARCHAR2, --        NULL 상품 옵션정보 Thong tin l？a ch？n s？n ph？m
  SP_PDT_KIND           IN  VARCHAR2, --    NOT NULL 상품구분 - NOR 일반상품 / STM 세트마스터 / STD 세트구성품 / GFT 기프트증정품 Phan lo？i s？n ph？m - S？n ph？m chung c？a NOR / B？ chinh STM / Thanh ph？n b？ STD / Qua t？ng GFT
  SP_QTY                IN  NUMBER,   --    NOT NULL 수량 S？ l？？ng
  SP_PRICE              IN  NUMBER,   --    NOT NULL 단가 đ？n gia
  SP_VAT                IN  NUMBER,   --    NOT NULL 부가세 Thu？ VAT
  SP_AMT                IN  NUMBER,   --    NOT NULL 금액 S？ ti？n
  SP_PV1                IN  NUMBER,   --    NOT NULL PV1
  SP_PV2                IN  NUMBER,   --    NOT NULL PV2
  SP_PV3                IN  NUMBER,   --    NOT NULL PV3
  SP_POINT              IN  NUMBER,   --    NOT NULL 적립포인트 Thu nh？p đi？m
  SP_PDT_STATUS         IN  VARCHAR2, --    NOT NULL 입출고구분(ORD:주문, C-I:교환입고, C-O:교환출고, RT:반품, CAN:취소) Phan lo？i giao nh？n va nh？n (ORD: đ？t hang, C-I: bien lai trao đ？i, C-O: giao d？ch trao đ？i, RT: tr？ l？i, CAN: h？y b？)
  SP_SERIAL_NO          IN  VARCHAR2, --        NULL 일련번호 S？ se-ri
  SP_REMARK             IN  VARCHAR2, --        NULL 비고사항 Nh？n xet
  SP_ORD_YN             IN  VARCHAR2, --        NULL 주문가능상품(Y/N) Co th？ đ？t hang s？n ph？m hay khong (Y/N)
  SP_DELI_SEQ           IN  NUMBER,   --    NOT NULL 배송순번 (다중배송 또는 하나의 주문서에 2개 이상의 박스로 배송할 경우 용도로 사용함) Th？ t？ giao hang (đ？？c s？ d？ng cho nhi？u l？n giao hang ho？c giao hang trong m？t h？p khi đ？t hang t？ 2 s？n ph？m tr？ len)
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호 ID ng？？i lam vi？c
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  v                     ORD_PDT_TMP%ROWTYPE; -- 테이블 변수 Bi？n table
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vIns_Upd              VARCHAR2(6);    -- 저장, 수정-- L？u, s？a
BEGIN
  ----------------------------------------------------------------------------
  -- 데이터를 변경한다.Thay đ？i d？ li？u
  ----------------------------------------------------------------------------
  UPDATE ORD_PDT_TMP
     SET PDT_SEQ    = SP_PDT_SEQ  
       , PDT_OPTION = SP_PDT_OPTION
       , PDT_KIND   = SP_PDT_KIND
       , QTY        = SP_QTY
       , PRICE      = SP_PRICE
       , VAT        = SP_VAT
       , AMT        = SP_AMT
       , PV1        = SP_PV1
       , PV2        = SP_PV2
       , PV3        = SP_PV3
       , POINT      = SP_POINT
       , PDT_STATUS = SP_PDT_STATUS
       , SERIAL_NO  = SP_SERIAL_NO
       , REMARK     = SP_REMARK
       , ORD_YN     = SP_ORD_YN 
       , DELI_SEQ   = SP_DELI_SEQ
       , Work_User  = SP_Work_User
   WHERE COM_ID     = SP_COM_ID
     AND PDT_CD     = SP_PDT_CD
     AND ORD_NO_TMP = SP_ORD_NO_TMP;
  

  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 등록되었습니다.', vLang_CD);

  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Tmp_Ord_PDT_Change_SP [Insert] - END -                    */
/* -------------------------------------------------------------------------- */









/* -------------------------------------------------------------------------- */
/* Package Member : Tmp_Ord_Deli_Ins_SP [Insert]                              */
/* Work    Date   : 2021-04-02 Created by Lee                                 */
/* -------------------------------------------------------------------------- */
PROCEDURE Tmp_Ord_Deli_Ins_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)
  SP_ORD_NO_TMP         IN  NUMBER,   --    NOT NULL 임시주문번호 (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP) S？ tu？n t？m th？i (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP)
  SP_DELI_SEQ           IN  NUMBER,   --    NOT NULL 배송순번 (다중배송 또는 하나의 주문서에 2개 이상의 박스로 배송할 경우 용도로 사용함) Th？ t？ giao hang (đ？？c s？ d？ng cho nhi？u l？n giao hang ho？c giao hang đ？n nhi？u h？p trong m？t đ？n hang)
  SP_USERID             IN  VARCHAR2, --    NOT NULL 회원번호 (Member.Userid) S？ thanh vien (Member.Userid)
  SP_DELI_KIND          IN  VARCHAR2, --    NOT NULL 배송방법(TAKE:방문수령, DELI-M:택배-회원주소지, DELI-C:택배-센터주소지[센터수령]) Ph？？ng th？c giao hang (NH？N: bien lai truy c？p, DELI-M: đ？a ch？ c？a thanh vien chuy？n phat nhanh, DELI-C: đ？a ch？ trung tam chuy？n phat nhanh [trung tam nh？n hang])
  SP_DELI_AMT           IN  NUMBER,   --    NOT NULL 배송비 Phi v？n chuy？n
  SP_STORE_CD           IN  VARCHAR2, --        NULL 물류[출고]창고코드 (Center.Cnt_CD)  H？u c？n [V？n chuy？n] Ma kho (Center.Cnt_CD)
  SP_COURIER_CD         IN  VARCHAR2, --        NULL 택배업체코드 (Center.Cnt_CD) Ma chuy？n phat nhanh (Center.Cnt_CD)
  SP_ORD_DATE           IN  VARCHAR2, --    NOT NULL 주문일자(YYYYMMDD) Ngay đ？t hang (YYYYMMDD)
  SP_SEND_DATE          IN  VARCHAR2, --        NULL 출고지시일자(YYYYMMDD) Ngay giao hang (YYYYMMDD)
  SP_SEND_USER          IN  VARCHAR2, --        NULL 촐고지시 담당자 (SM_User.Userid) Ng？？i ph？ trach (SM_User.Userid)
  SP_TERM_DATE          IN  VARCHAR2, --        NULL 배송완료일자(YYYYMMDD) Ngay hoan thanh giao hang (YYYYMMDD)
  SP_TERM_USER          IN  VARCHAR2, --        NULL 배송완료 담당자 (SM_User.Userid) Nhan vien giao hang đa hoan thanh (SM_User.Userid)
  SP_INVOICE_NO         IN  VARCHAR2, --        NULL 송장번호 S？ hoa đ？n
  SP_DELI_USER_INFO     IN  VARCHAR2, --        NULL 묶음 상품에대한 지정회원 번호(해당개발은 추후진행) S？ thanh vien đ？？c ch？ đ？nh cho s？n ph？m đi kem (vi？c phat tri？n nay s？ đ？？c th？c hi？n sau)
  SP_REMARK             IN  VARCHAR2, --        NULL 물류담당자(또는 3PL)에게 전달할 메시지 Tin nh？n s？ đ？？c g？i đ？n ng？？i qu？n ly h？u c？n (ho？c 3PL)
  SP_B_NAME             IN  VARCHAR2, --        NULL 구매자 - 이름 Ten ng？？i mua
  SP_B_TEL              IN  VARCHAR2, --        NULL 구매자 - 전화번호 đi？n tho？i ng？？i mua
  SP_B_MOBILE           IN  VARCHAR2, --        NULL 구매자 - 이동전화 đi？n tho？i ng？？i mua
  SP_B_E_MAIL           IN  VARCHAR2, --        NULL 구매자 - E-Mail 주소 đ？a ch？ email ng？？i mua
  SP_B_POST             IN  VARCHAR2, --        NULL 구매자 - 우편번호 Ma ng？？i mua
  SP_B_STATE            IN  VARCHAR2, --        NULL 구매자 - 시/도/(외국)주,성 Ng？？i mua-Thanh ph？ / T？nh / (N？？c ngoai) Bang, T？nh
  SP_B_CITY             IN  VARCHAR2, --        NULL 구매자 - 도시  Thanh ph？ ng？？i mua
  SP_B_COUNTY           IN  VARCHAR2, --        NULL 구매자 - 카운티 Qu？n-ng？？i mua
  SP_B_ADDR1            IN  VARCHAR2, --        NULL 구매자 - 주소 1 đ？a ch？ ng？？i mua 1
  SP_B_ADDR2            IN  VARCHAR2, --        NULL 구매자 - 주소 2 đ？a ch？ ng？？i mua 2
  SP_B_USERID           IN  VARCHAR2, --        NULL 구매자 - 회원번호
  SP_B_BIRTHDAY         IN  VARCHAR2, --        NULL 구매자 - 생년월일
  SP_R_MEMO             IN  VARCHAR2, --        NULL 구매자 - 메모
  SP_R_NAME             IN  VARCHAR2, --        NULL 배송지 - 이름 (센터수령의 경우 센터명 + 회원명(회원번호) 기재)  G？i đ？n ten (Trong tr？？ng h？p nh？n trung tam, nh？p ten trung tam + ten thanh vien (s？ thanh vien))
  SP_R_TEL              IN  VARCHAR2, --        NULL 배송지 - 전화번호 (센터수령일 경우 전화번호는 센터 전화번호 기재) G？i đ？n s？ đi？n tho？i (N？u trung tam đ？？c ch？n, s？ đi？n tho？i la s？ đi？n tho？i trung tam)
  SP_R_MOBILE           IN  VARCHAR2, --        NULL 배송지 - 이동전화 (센터수령일 경우 핸드폰번호는 회원 핸드폰번호 기재) đ？a ch？ giao hang - đi？n tho？i di đ？ng (Trong tr？？ng h？p nh？n trung tam, s？ đi？n tho？i di đ？ng la s？ đi？n tho？i di đ？ng c？a thanh vien)
  SP_R_E_MAIL           IN  VARCHAR2, --        NULL 배송지 - E-Mail 주소 G？i đ？n đ？a ch？ email
  SP_R_POST             IN  VARCHAR2, --        NULL 배송지 - 우편번호 G？i ma b？u đi？n
  SP_R_STATE            IN  VARCHAR2, --        NULL 배송지 - 시/도/(외국)주,성 G？i đ？n thanh ph？ / t？nh / (n？？c ngoai) Nha n？？c, t？nh
  SP_R_CITY             IN  VARCHAR2, --        NULL 배송지 - 도시  G？i đ？n thanh ph？
  SP_R_COUNTY           IN  VARCHAR2, --        NULL 배송지 - 카운티 G？i đ？n qu？n
  SP_R_ADDR1            IN  VARCHAR2, --        NULL 배송지 - 주소 1 G？i đ？n đ？a ch？ 1
  SP_R_ADDR2            IN  VARCHAR2, --        NULL 배송지 - 주소 2 G？i đ？n đ？a ch？ 2
  SP_DELI_PDT_CD        IN  VARCHAR2, --        NULL 배송비 생성 시 만들어질 배송상품 코드(PDT_MST.PDT_CD). Ma s？n ph？m v？n chuy？n s？ đ？？c t？o ra khi t？o ra phi v？n chuy？n.(PDT_MST.PDT_CD)
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호 ID ng？？i lam vi？c
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  v                     ORD_PDT_TMP%ROWTYPE; -- 테이블 변수 Bi？n table
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vIns_Upd              VARCHAR2(6);    -- 저장, 수정-- L？u, s？a
  vWork_Kind            VARCHAR2(1);
BEGIN  
  SELECT Work_Kind INTO vWork_Kind
    FROM Ord_Mst_Tmp
   WHERE Com_Id = SP_Com_Id
     AND Ord_No_Tmp = SP_ORD_NO_TMP;

  IF vWork_Kind = 'M' THEN
    SELECT Ctr_Cd INTO vLang_CD
      FROM Member
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User; 
  ELSE 
    SELECT Lang_CD INTO vLang_CD
      FROM SM_User
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  END IF;
  
  ------------------------------------------------------------------------------
  -- 데이터 체크.
  ------------------------------------------------------------------------------
  IF (NVL(Length(LTrim(SP_ORD_NO_TMP)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('배송정보의 임시주문번호가 없습니다. 배송정보를 확인하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  IF (NVL(Length(LTrim(SP_ORD_DATE)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('배송정보의 주문일자가  없습니다. 배송정보를 확인하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  IF (NVL(Length(LTrim(SP_DELI_KIND)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('배송방법을 선택해주세요.', vLang_CD); 
    RETURN;  
  END IF;   
  
  IF SP_DELI_AMT <> 0 THEN
    IF SP_DELI_PDT_CD IS NULL THEN
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('배송비 코드가 없습니다. 배송상품 코드를 확인하세요.', vLang_CD); 
      RETURN;  
    END IF;
  END IF;


  ------------------------------------------------------------------------------
  -- 기존 장바구니 테이블정보를 삭제한다.
  ------------------------------------------------------------------------------
  DELETE FROM ORD_DELI_TMP


   WHERE COM_ID = SP_COM_ID
     AND ORD_NO_TMP = SP_ORD_NO_TMP;
     
  ----------------------------------------------------------------------------
  -- 데이터를 저장한다. L？u d？ li？u
  ----------------------------------------------------------------------------
  INSERT INTO ORD_DELI_TMP
         ( COM_ID        
         , ORD_NO_TMP    
         , DELI_SEQ          
         , USERID            
         , DELI_KIND         
         , DELI_AMT          
         , STORE_CD          
         , COURIER_CD        
         , ORD_DATE          
         , SEND_DATE         
         , SEND_USER         
         , TERM_DATE         
         , TERM_USER         
         , INVOICE_NO        
         , DELI_USER_INFO    
         , REMARK            
         , B_NAME            
         , B_TEL             
         , B_MOBILE          
         , B_E_MAIL          
         , B_POST            
         , B_STATE           
         , B_CITY            
         , B_COUNTY          
         , B_ADDR1           
         , B_ADDR2           
         , B_USERID          
         , B_BIRTHDAY        
         , R_MEMO            
         , R_NAME            
         , R_TEL             
         , R_MOBILE          
         , R_E_MAIL          
         , R_POST            
         , R_STATE           
         , R_CITY            
         , R_COUNTY          
         , R_ADDR1           
         , R_ADDR2           
         , DELI_PDT_CD
         , WORK_USER      
         )
   VALUES( SP_COM_ID        
         , SP_ORD_NO_TMP    
         , SP_DELI_SEQ          
         , SP_USERID            
         , SP_DELI_KIND         
         , SP_DELI_AMT          
         , SP_STORE_CD          
         , SP_COURIER_CD        
         , SP_ORD_DATE          
         , SP_SEND_DATE         
         , SP_SEND_USER         
         , SP_TERM_DATE         
         , SP_TERM_USER         
         , SP_INVOICE_NO        
         , SP_DELI_USER_INFO    
         , SP_REMARK            
         , SP_B_NAME            
         , SP_B_TEL             
         , SP_B_MOBILE          
         , SP_B_E_MAIL          
         , SP_B_POST            
         , SP_B_STATE           
         , SP_B_CITY            
         , SP_B_COUNTY          
         , SP_B_ADDR1           
         , SP_B_ADDR2           
         , SP_B_USERID          
         , SP_B_BIRTHDAY        
         , SP_R_MEMO            
         , SP_R_NAME            
         , SP_R_TEL             
         , SP_R_MOBILE          
         , SP_R_E_MAIL          
         , SP_R_POST            
         , SP_R_STATE           
         , SP_R_CITY            
         , SP_R_COUNTY          
         , SP_R_ADDR1           
         , SP_R_ADDR2      
         , SP_DELI_PDT_CD     
         , SP_WORK_USER
         );   


  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 등록되었습니다.', vLang_CD);

  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Tmp_Ord_Deli_Ins_SP [Insert] - END -                      */
/* -------------------------------------------------------------------------- */









/* -------------------------------------------------------------------------- */
/* Package Member : ORD_INS_SP [Insert]                                       */
/* Work    Date   : 2021-03-29 Created by JOO                                 */
/* -------------------------------------------------------------------------- */
PROCEDURE ORD_INS_SP (
  SP_Com_ID             IN  VARCHAR2,   -- 회사번호 (Company.Com_ID) S？ cong ty (Company.Com_ID);
  SP_Userid             IN  VARCHAR2,   -- 회원번호(Member.Userid) S？ thanh vien (Member.Userid)
  SP_Ord_No_Tmp         IN  NUMBER,     -- 임시주분번호 (SEQ_Tmp 시퀀스 사용) S？ tu？n t？m th？i (s？ d？ng chu？i SEQ_Tmp)
  SP_Acc_Date           IN  VARCHAR2,   -- 승인일자(YYYYMMDD) Ngay phe duy？t (YYYYMMDD)
  SP_Ctr_Cd             IN  VARCHAR2,   -- 국가코드(Country.CTR_CD) -> 통화단위 및 환율 표시용으로 사용 Ma qu？c gia (Country.CTR_CD) -> đ？？c s？ d？ng đ？ hi？n th？ đ？n v？ ti？n t？ va t？ gia h？i đoai
  SP_Work_User          IN  VARCHAR2,   -- 최초 작업자번호 ID ng？？i lam vi？c đ？u tien       
  ------------------------------------------------------------------------------
  SP_KeyValue           OUT VARCHAR2, -- [리턴값] 주문번호
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  v                     Ord_Mst_Tmp%ROWTYPE; 
  vLang_CD              VARCHAR2(2); 
  vIns_Upd              VARCHAR2(6);    
  vCnt                  NUMBER; 
  vRank_Cd              VARCHAR2(3);
  vMobile               VARCHAR2(20);
  vSms_Ok               VARCHAR2(2);
  vPdt_Seq              NUMBER; 
  vOrd_No               VARCHAR2(20);
  vWork_Kind            VARCHAR2(1);
  vCtr_Cd               VARCHAR2(2);
  
  
  vL_Ord_PP_Dir         VARCHAR2(1);  -- 주문후 자동 출고지시여부(Y,N) - 직접수령 
  vL_Ord_PP_Deli        VARCHAR2(1);  -- 주문후 자동 출고지시여부(Y,N) - 택배
  vL_Ord_PP_Cnt         VARCHAR2(1);  -- 주문후 자동 출고지시여부(Y,N) - 센터수령 
       
  ------------------------------------------------------------------------------
  -- 배송비관련  금액/ 배송비 코드
  ------------------------------------------------------------------------------
  vStore_Cd             VARCHAR2(5); 
  vCourier_Cd           VARCHAR2(5); 
  vDeli_Amt             NUMBER;   
  vDeli_Pdt_Cd          VARCHAR2(10);
  vDeli_Kind            VARCHAR2(6);
  vOrd_Deli_Pdt         VARCHAR2(2);
  ------------------------------------------------------------------------------
  -- Ord_Money 변수 
  ------------------------------------------------------------------------------
  vRcpt_Cash            NUMBER;
  vRcpt_Card            NUMBER;
  vRcpt_Bank            NUMBER;
  vRcpt_Vbank           NUMBER;
  vRcpt_Prepay          NUMBER;
  vRcpt_Point           NUMBER;
  vRcpt_Ars             NUMBER; 
  vRcpt_Coin            NUMBER;
  vRcpt_Etc             NUMBER;
  vRcpt_Yn              VARCHAR2(2);
  vRcpt_Cnt             NUMBER;
  vAmt_Use              NUMBER;   
  vUse_Yn               VARCHAR2(2);
  vMoney_Kind           VARCHAR2(3);
  vAmt                  NUMBER;
  vTmp                  NUMBER;
  ------------------------------------------------------------------------------
  -- 금액 비교 
  ------------------------------------------------------------------------------
  vRcpt_Amt             NUMBER; 
  vPdt_Total_Amt        NUMBER;
  vTotal_Amt            NUMBER;
  vOrd_Point            NUMBER;
  ------------------------------------------------------------------------------
  -- 에러 발생 확인 
  ------------------------------------------------------------------------------
  vError_Point          NUMBER;
  vStk_Kind             VARCHAR2(5 Char);
  ------------------------------------------------------------------------------
  -- Log Seq 
  ------------------------------------------------------------------------------
  vLog_Seq              NUMBER;
BEGIN
  ------------------------------------------------------------------------------
  -- [시작시간]프로시저 실행시간 체크 및 정상성공여부 확인. 
  ------------------------------------------------------------------------------
  SELECT Seq_Log.NEXTVAL INTO vLog_Seq FROM Dual;
  Log_Work_Time_SP(SP_Com_ID, vLog_Seq, 'ORD', 'ORD_INS_SP', SP_Work_User , '[Start Time]');

  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Work_Kind INTO vWork_Kind
    FROM Ord_Mst_Tmp
   WHERE Com_Id = SP_Com_Id
     AND Ord_No_Tmp = SP_ORD_NO_TMP;

  IF vWork_Kind = 'M' THEN
    SELECT NVL(MAX(Ctr_Cd),'KR') INTO vLang_CD
      FROM Member
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User; 
  ELSE 
    SELECT Lang_CD INTO vLang_CD
      FROM SM_User

     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  END IF;
  
  
  ------------------------------------------------------------------------------
  -- 출고 지시여부 체크
  ------------------------------------------------------------------------------
  SELECT L_Ord_PP_Dir   
       , L_Ord_PP_Deli  
       , L_Ord_PP_Cnt   
    INTO vL_Ord_PP_Dir
       , vL_Ord_PP_Deli
       , vL_Ord_PP_Cnt        
    FROM SM_CONFIG
   WHERE Com_Id = SP_Com_Id;
  ------------------------------------------------------------------------------
  -- 주문번호 생성 (YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리) 
  ------------------------------------------------------------------------------
  vOrd_No := TO_CHAR(SYSDATE,'YYYYMMDDHHMISS') + SEQ_ORDER.nextval();
  vError_Point := 1; 
  
  ------------------------------------------------------------------------------
  -- 배송비 / 배송코드 체크 /   Ord_Deli_Tmp  :  Area_Cd  / Ctr_Cd 추가 해야함. [확인필요]   
  ------------------------------------------------------------------------------
  vError_Point := 3;
  BEGIN
    SELECT  Store_Cd,  Courier_Cd
      INTO vStore_Cd, vCourier_Cd
      FROM Ord_Deli_Tmp
     WHERE Com_ID = SP_Com_Id
       AND Ord_No_Tmp = SP_Ord_No_Tmp;    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN 
      vStore_Cd   :='';
      vCourier_Cd :='';
  END;
          
  vError_Point := 4;
  ------------------------------------------------------------------------------
  SELECT TO_NUMBER(UFDELI_AMT(SP_Com_Id 
                            , SP_Ord_No_Tmp 
                            , SP_Ctr_Cd 
                            , vStore_Cd
                            , ''          -- Area_Cd  
                            , vCourier_Cd
                            , 'A'         -- A : 금액리턴  
                   )) 
    INTO vDeli_Amt
    FROM DUAL;
      
  IF vDeli_Amt = -1 THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('배송비를 확인할 수 없습니다.', vLang_CD);  
  END IF;
    
  vError_Point := 5; 
  ------------------------------------------------------------------------------   
  SELECT UFDELI_AMT(SP_Com_Id 
                  , SP_Ord_No_Tmp 
                  , SP_Ctr_Cd 
                  , vStore_Cd
                  , ''          -- Area_Cd  
                  , vCourier_Cd
                  , 'P'         -- P : 배송비 상품코드 리턴  
                  ) 
    INTO vDeli_Pdt_Cd
    FROM DUAL;    
 
  ------------------------------------------------------------------------------
  -- 임시테이블에 택배비 상품저장  
  ------------------------------------------------------------------------------
  -- 배송비가 발생했을경우 임시상품에 저장 한다.
     
  vError_Point := 6;
  
  IF vDeli_Amt > 0 THEN
    SELECT NVL(MAX(Pdt_Seq) + 1,1) INTO vPdt_Seq 
      FROM Ord_Pdt_Tmp 
     WHERE Com_Id = SP_Com_Id 
       AND Ord_No_Tmp = SP_Ord_No_Tmp;
        
    ----------------------------------------------------------------------------
    -- 데이터를 저장한다. L？u d？ li？u
    ---------------------------------------------------------------------------- 
    INSERT INTO Ord_Pdt_Tmp
           ( Com_ID     
           , Ord_No_Tmp 
           , Pdt_Seq    
           , Userid     
           , Pdt_Cd     
           , Pdt_Option 
           , Pdt_Kind   
           , Qty        
           , Price      
           , Vat        
           , Amt        
           , Pv1        
           , Pv2        
           , Pv3        
           , Point      
           , Pdt_Status 
           , Serial_No  
           , Remark     
           , Ord_Yn       
           , Deli_Seq   
           , Work_User  
           )
     VALUES( SP_Com_ID     
           , SP_Ord_No_Tmp 
           , vPdt_Seq    
           , SP_Userid     
           , vDeli_Pdt_Cd     
           , ''           -- SP_Pdt_Option   
           , 'NOR'        -- 일반상품 SP_Pdt_Kind   
           , 1            -- SP_Qty        
           , 0            -- SP_Price      
           , 0            -- SP_Vat        
           , vDeli_Amt    -- SP_Amt        
           , 0            -- SP_Pv1        
           , 0            -- SP_Pv2        
           , 0            -- SP_Pv3        
           , 0            -- SP_Point      
           , 'ORD'        -- SP_Pdt_Status 
           , ''           -- SP_Serial_No  
           , ''           -- SP_Remark     
           , 'Y'          -- SP_Ord_Yn       
           , 1            -- SP_Deli_Seq   
           , 'admin'      -- SP_Work_User  
           );      
  END IF;
     
  vError_Point := 7;

  ------------------------------------------------------------------------------
  -- 배송비는 회원의 국가코드별로 체크한다. Choi > Add > 2022.01.28
  ------------------------------------------------------------------------------  
  SELECT Ctr_Cd INTO vCtr_Cd
    FROM Member
   WHERE Com_ID = SP_Com_ID
     AND Userid = SP_Userid;

  ------------------------------------------------------------------------------
  -- ORD_MST 생성
  ------------------------------------------------------------------------------
  INSERT INTO Ord_Mst ( Com_Id
                      , Ord_No
                      , Ord_No_Org
                      , Userid
                      , Ord_Date
                      , Acc_Date
                      , Status
                      , Ctr_Cd
                      , Cnt_Cd
                      , Kind_Cd
                      , Path_Cd
                      , Proc_Cd
                      , Omni_Yn
                      , Remark 
                      , Curr_Amt
                      , Ord_Price
                      , Ord_Vat
                      , Ord_Amt
                      , Ord_Pv1
                      , Ord_Pv2
                      , Ord_Pv3
                      , Ord_Point
                      , Deli_No
                      , Deli_Amt
                      , Coll_Amt
                      , Total_Amt
                      , Rcpt_Yn
                      , Rcpt_Total
                      , Rcpt_Cash
                      , Rcpt_Card
                      , Rcpt_Bank
                      , Rcpt_vBank
                      , Rcpt_PrePay
                      , Rcpt_Point
                      , Rcpt_Ars
                      , Rcpt_Coin
                      , Rcpt_Etc
                      , Rcpt_Remain
                      , Tax_Invo_Yn
                      , Tax_Invo_No
                      , Tax_Invo_Date
                      , Bp_Amt_Sum
                      , Bp_Pv1_Sum
                      , Bp_Pv2_Sum
                      , Bp_Pv3_Sum
                      , Bp_Date_Cnt
                      , Bp_Amt_Day
                      , Bp_Amt_Pay
                      , Bp_Amt_Etc
                      , Bp_Refund_Date
                      , Bp_Refund_Amt
                      , Ins_Date
                      , Ins_User
                      , Upd_Date
                      , Upd_User)  
    SELECT Com_Id
         , vOrd_No
         , vOrd_No AS Ord_No_Org 
         , Userid 
         , TO_CHAR(SYSDATE,'YYYYMMDD') -- (장바구니 ORD_DATE TMP 생성일자이기때문에 주문에서는 당일건으로 생성) 
         , SP_Acc_Date     -- Acc_Date 
         , 'A'             -- Status
         , vCtr_Cd         -- Ctr_Cd
         , Cnt_Cd          -- Cnt_Cd
         , Kind_CD         -- 필드 추가필요 주문구분 : [KIND_CD]
         , Path_Cd         -- Path_Cd
         , ufCom_CD(SP_Com_Id)||'J20'         -- 필드 추가필요 진행단계 : [PROC_CD]    -- 주문 / 주문완료
         , 'N'             -- Omni_YN   [소비자 주문여부 ????]      -- 
         , ''              -- Remark    [Ord_Deli_Tmp Remark 참조]  -- 정보값 필드로 받아야 함!!!!!!
         , 0               -- Curr_Amt  [환율 테이블 참조 필요] 
         , Ord_Price     -- Ord_Price 
         , Ord_Vat       -- Ord_Vat   
         , Ord_Amt       -- Ord_Amt   
         , Ord_Pv1       -- Ord_Pv1   
         , Ord_Pv2       -- Ord_Pv2   
         , Ord_Pv3       -- Ord_Pv3 
         , Ord_Point       -- Ord_Point  
         , ''              -- Deli_No   
         , vDeli_Amt       -- Deli_Amt 배송비 금액 
         , 0               -- Coll_Amt 
         , Ord_Amt + vDeli_Amt     -- Total_Amt (배송비 + 주문 + 기타 금액 합산)
         ---------------------------------------------------------------------------
         , 'N'             -- Rcpt_YN 
         , 0               -- Rcpt_Total 
         , 0               -- Rcpt_Cash  
         , 0               -- Rcpt_Card
         , 0               -- Rcpt_Bank
         , 0               -- Rcpt_VBank
         , 0               -- Rcpt_PrePay
         , 0               -- Rcpt_Point
         , 0               -- Rcpt_ARS  
         , 0               -- Rcpt_Coin
         , 0               -- Rcpt_Etc
         , 0               -- Rcpt_Remain 
         , ''              -- Tax_Invo_YN 
         , ''              -- Tax_Invo_NO
         , ''              -- Tax_Invo_Date  
         , 0               -- BP_Amt_Sum
         , 0               -- BP_Pv1_Sum  
         , 0               -- BP_Pv2_Sum  
         , 0               -- BP_Pv3_Sum    
         , 0               -- BP_Date_Cnt
         , 0               -- BP_Amt_Day
         , 0               -- BP_Amt_Pay
         , 0               -- BP_Amt_Etc
         , 0               -- BP_Refund_Date
         , 0               -- BP_Refund_Amt  
         , SYSDATE         -- Ins_Date
         , SP_Work_User    -- Ins_User 
         , ''              -- Upd_Date
         , ''              -- Upd_User
      FROM Ord_Mst_Tmp A
        ,  (SELECT Ord_No_Tmp
                 , SUM(Price * Qty)  AS Ord_Price
                 , SUM(Vat * Qty)    AS Ord_Vat
                 , SUM(Amt * Qty)    AS Ord_Amt
                 , SUM(Pv1 * Qty)    AS Ord_Pv1
                 , SUM(Pv2 * Qty)    AS Ord_Pv2
                 , SUM(Pv3 * Qty)    AS Ord_Pv3
                 , SUM(Point * Qty)  AS Ord_Point
              FROM Ord_Pdt_Tmp   
             WHERE Com_Id       = SP_Com_Id
               AND Ord_No_Tmp = SP_Ord_No_Tmp
               AND Ord_Yn ='Y'
               AND PDT_CD <> vDeli_Pdt_Cd
             GROUP BY Ord_No_Tmp
           ) B
     WHERE A.Com_Id       = SP_Com_Id
       AND A.Ord_No_Tmp = B.Ord_No_Tmp
       AND A.Ord_No_Tmp = SP_Ord_No_Tmp; 

  ------------------------------------------------------------------------------
  -- Log_Ord_Mst - (로그) 주문마스터 저장 
  ------------------------------------------------------------------------------
  --Log_Ord_Mst_SP(SP_Com_Id, SP_Ord_No,'1', SP_Work_User);
  
  SELECT Ord_Point INTO vOrd_Point
    FROM Ord_Mst
   WHERE Com_Id = SP_Com_Id 
     AND Ord_No = vOrd_No ;
  
  IF (vOrd_Point > 0) THEN 
    INSERT INTO Mem_Point
       ( Seq
       , Com_ID
       , Reg_Date          
       , Userid    
       , Username        
       , Kind_CD
       , Kind_Name
       , Ord_No
       , Amt               
       , Remark
       , Work_User)
    VALUES(SEQ_POINT.NextVal
       , SP_Com_ID
       , SP_Acc_Date          
       , SP_Userid            
       , UFNAME(SP_Com_ID,'USERNAME',SP_Userid)
       , '12'              
       , UFNAME(SP_Com_ID,'CODE','12')
       , vOrd_No
       , vOrd_Point
       , ''
       , SP_Work_User );
  END IF;
  
  ------------------------------------------------------------------------------
  -- 주문합계금액
  ------------------------------------------------------------------------------
  SELECT Total_Amt INTO vTotal_Amt 
    FROM Ord_Mst
   WHERE Com_Id = SP_Com_Id 
     AND Ord_No = vOrd_No ;
     
  vError_Point := 9; 
  ------------------------------------------------------------------------------
  -- 주문 상품 저장 
  ------------------------------------------------------------------------------
  INSERT INTO Ord_Pdt( Com_Id
                     , Ord_No
                     , Ord_No_Org
                     , Pdt_Seq
                     , Userid
                     , Pdt_Cd
                     , Pdt_Option 
                     , Pdt_Kind
                     , Qty
                     , Price
                     , Vat
                     , Amt 
                     , Pv1
                     , Pv2
                     , Pv3
                     , Point
                     , Pdt_Status
                     , Serial_No
                     , Remark
                     , Work_Date
                     , Work_User 
              ) SELECT SP_Com_Id AS Com_Id
                     , vOrd_No   AS Ord_No
                     , vOrd_No   AS Ord_No_Org
                     , Pdt_Seq
                     , SP_Userid
                     , Pdt_Cd
                     , Pdt_Option
                     , Pdt_Kind
                     , Qty
                     , Price   AS Price
                     , Vat     AS Vat
                     , Amt     AS Amt
                     , Pv1     AS Pv1
                     , Pv2     AS Pv2
                     , Pv3     AS Pv3
                     , Point   AS Point
                     , Pdt_Status
                     , Serial_No
                     , Remark
                     , SYSDATE
                     , SP_Work_User
                  FROM Ord_Pdt_Tmp 
                 WHERE Com_Id = SP_Com_Id
                   AND Ord_No_Tmp = SP_Ord_No_Tmp
                   AND Ord_Yn ='Y'; 
   
  ------------------------------------------------------------------------------
  -- Log_Ord_Pdt - (로그) 주문상품 저장 
  ------------------------------------------------------------------------------
  --Log_Ord_Pdt_SP(SP_Com_Id, SP_Ord_No,'1', SP_Work_User);      
  vError_Point := 10;
  ------------------------------------------------------------------------------
  -- 배송지 정보 저장 
  ------------------------------------------------------------------------------
  INSERT INTO Ord_Deli( Com_Id
                      , Ord_No
                      , Deli_Seq
                      , Userid 
                      , Deli_Kind
                      , Deli_Amt
                      , Store_Cd
                      , Courier_Cd
                      , Ord_Date
                      , Send_Date
                      , Send_User
                      , Remark
                      , B_Userid
                      , B_Name
                      , B_BirthDay
                      , B_Tel
                      , B_Mobile
                      , B_E_Mail
                      , B_Post
                      , B_State
                      , B_City
                      , B_County
                      , B_Addr1
                      , B_Addr2
                      , R_Name
                      , R_Tel
                      , R_Mobile
                      , R_E_Mail
                      , R_Post
                      , R_State
                      , R_City
                      , R_County
                      , R_Addr1
                      , R_Addr2
                      , R_Memo
                      , Work_Date
                      , Work_User)
                 SELECT Com_Id
                      , vOrd_No
                      , Deli_Seq
                      , Userid
                      , Deli_Kind
                      , Deli_Amt
                      , Store_Cd
                      , Courier_Cd
                      , Ord_Date
                      , Send_Date
                      , Send_User
                      , Remark
                      , SP_Userid AS B_Userid   --, ''  AS B_Userid -- 필드없음  필요함.!!!!
                      , B_Name
                      , ''  AS B_BirthDay          -- 필드없음  필요함.!!!!
                      , B_Tel
                      , B_Mobile
                      , B_E_Mail
                      , B_Post
                      , B_State
                      , B_City
                      , B_County
                      , B_Addr1
                      , B_Addr2  
                      , R_Name
                      , R_Tel
                      , R_Mobile
                      , R_E_Mail
                      , R_Post
                      , R_State
                      , R_City
                      , R_County
                      , R_Addr1
                      , R_Addr2
                      , '' AS R_Memo      -- 필드없음  필요함.!!!!
                      , SYSDATE AS Work_Date
                      , SP_Work_User
                   FROM Ord_Deli_Tmp
                  WHERE Com_Id = SP_Com_Id
                    AND Ord_No_Tmp = SP_Ord_No_Tmp;  
   
  ------------------------------------------------------------------------------
  -- 환경설정에 따라 Ord_Deli_Pdt [배송상품 정보 ]생성 
  -- 직접수령 / 택배 / 센터수령 중 
  ------------------------------------------------------------------------------
  SELECT Deli_Kind INTO vDeli_Kind 
    FROM Ord_Deli
   WHERE Com_Id = SP_Com_Id
     AND Ord_No = vOrd_No;
  
  vOrd_Deli_Pdt :='N';
      
  IF (vDeli_Kind = 'TAKE') AND (vL_Ord_PP_Dir ='Y')  THEN 
    vOrd_Deli_Pdt :='Y';
  ELSIF (vDeli_Kind = 'DELI-M') AND (vL_Ord_PP_Deli ='Y') THEN
    vOrd_Deli_Pdt :='Y';
  ELSIF (vDeli_Kind = 'DELI-C') AND (vL_Ord_PP_Cnt ='Y') THEN 
   vOrd_Deli_Pdt :='Y';
  END IF;     
      
  IF vOrd_Deli_Pdt ='Y' THEN 
    ----------------------------------------------------------------------------
    -- 자동출고 처리한다.
    -- 1. 출고데이터 생성 (ORD_DELI_PDT) - 직접수령은 생성하지 않는다.
    -- 2. ORD_PDT.QTY_PP / QTY_STK 갱신
    -- 3. ORD_DELI.SEND_DATE / SEND_USER / TERM_DATE / TERM_USER 갱신
    -- 4. 상품의 출고여부에 따른 재고처리.
    ----------------------------------------------------------------------------
    --IF (vDeli_Kind <> 'TAKE') THEN
      INSERT INTO Ord_Deli_Pdt( Com_Id
                              , Userid
                              , Ord_No
                              , Deli_Seq
                              , Pdt_Seq
                              , Pdt_Cd
                              , Qty 
                              , Box_Cnt
                              , Box_Rate
                              , Remark
                              , Work_Date
                              , Work_User)  
                       SELECT A.Com_Id
                            , A.Userid
                            , A.Ord_No
                            , B.Deli_Seq
                            , A.Pdt_Seq
                            , A.Pdt_Cd
                            , A.Qty
                            , 0 AS Box_Cnt
                            , C.Pdt_Box_Rate AS Box_Rate
                            , B.REMARK
                            , SYSDATE
                            , A.Work_User
                         FROM Ord_Pdt A 
                            , Ord_Deli B 
                            , Pdt_Mst C
                        WHERE A.Ord_No = B.Ord_No
                          AND A.Pdt_Cd = C.Pdt_Cd
                          AND A.Com_Id = SP_Com_Id
                          AND A.ORD_NO = vOrd_No;
                          
    --END IF;
    
    UPDATE Ord_Pdt
       SET Qty_PP = Qty
         , Qty_Stk = Qty
     WHERE Com_Id = SP_Com_Id
       AND Ord_No = vOrd_No;
       
    UPDATE Ord_Deli
       SET Send_Date = TO_CHAR(SYSDATE, 'YYYYMMDD')
         , Send_User = SP_Work_User
         , Term_Date = TO_CHAR(SYSDATE, 'YYYYMMDD')
         , Term_User = SP_Work_USer
     WHERE Com_ID = SP_Com_ID
       AND Ord_NO = vOrd_NO;
      
    ----------------------------------------------------------------------------
    -- 해당 상품의 재고관리여부 및 재고차감방법을 읽는다.
    -- PDT_MST.STOCK_SUB IS '재고차감구분 (PDT 상품에서 차감 / BOM 구성품에서 차감) Kh？u tr？ t？n kho (tr？ t？ s？n ph？m PDT / kh？u tr？ t？ thanh ph？n BOM)'
    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    -- 재고관리를 할 경우, 자동출고 처리까지 되는 경우 
    -- 입출고테이블에 해당 정보를 저장한다.
    ----------------------------------------------------------------------------     
    FOR C1 IN (SELECT A.Ord_NO
                    , A.Pdt_Seq
                    , A.Pdt_CD
                    , A.Pdt_Status
                    , A.Qty
                    , B.Stock_Sub
                    , B.Stock_YN
                    , B.Bom_YN
                    , B.Store_CD 
                 FROM Ord_Pdt A
                    , Pdt_Mst B                    
                WHERE A.Pdt_CD = B.Pdt_CD
                  AND A.Com_ID = SP_Com_ID
                  AND A.Ord_NO = vOrd_NO
                    ) LOOP 
      
      vStk_Kind := ufName(SP_Com_ID, 'CODE.PDT_STATUS', C1.Pdt_Status);
      
      IF SP_Com_ID = 'DEMO'THEN
        vStore_CD := NVL(C1.Store_Cd, '00000');
      ELSE
        vStore_CD := NVL(C1.Store_Cd, ufCom_CD(SP_Com_Id)||'C10');
      END IF; 
      
      IF ((C1.Stock_YN = 'Y') OR (C1.Bom_YN = 'Y')) THEN
        IF C1.Stock_Sub = 'PDT' THEN -- 상품에서 차감 
          INSERT INTO Stk_Pdt
               ( Com_ID
               , Reg_NO
               , Reg_Date  
               , Kind_CD
               , Pdt_CD
               , Store_CD
               , Qty_IN
               , Qty_Out
               , Ord_NO
               , Deli_Seq
               , Pdt_Seq
               , Remark
               , Work_User)
          VALUES(SP_Com_ID
               , SEQ_PK.Nextval
               , TO_CHAR(SYSDATE, 'YYYYMMDD') -- C1.Term_Date    
               , vStk_Kind        --'A', -- 판매출고
               , C1.Pdt_CD
               , vStore_CD
               , 0 -- vQty_IN
               , C1.Qty -- vQty_OUT     --C1.Ord_Pdt_Qty,
               , C1.Ord_NO
               , '1' -- C1.Deli_Seq
               , C1.Pdt_Seq
               , ''    --'출고등록 : ' || vDeli_NO,
               , SP_Work_User);
        ELSIF C1.Stock_Sub = 'BOM' THEN -- 구성품에에서 차감
          -- 셋트상푼 정보를 읽는다.
          FOR C2 IN (SELECT A.Comp_CD, A.Qty
                       FROM Pdt_Bom A,
                            Pdt_Mst B
                      WHERE A.Comp_CD = B.Pdt_CD
                        AND A.Pdt_CD = C1.Pdt_CD
                        AND B.Stock_YN = 'Y') LOOP
            INSERT INTO Stk_Pdt
                 ( Com_ID
                 , Reg_NO
                 , Reg_Date  
                 , Kind_CD
                 , Pdt_CD
                 , Store_CD
                 , Qty_IN
                 , Qty_Out
                 , Ord_NO
                 , Deli_Seq
                 , Pdt_Seq
                 , Remark                 
                 , Work_User)
            VALUES(SP_Com_ID
                 , SEQ_PK.Nextval
                 , TO_CHAR(SYSDATE, 'YYYYMMDD')   -- C1.Send_Date   
                 , vStk_Kind             --'A', -- 판매출고
                 , C2.Comp_CD
                 , C1.Store_Cd  
                 , 0 -- vQty_IN * C2.Qty     --0,
                 , C1.Qty * C2.Qty    --C2.Qty * C1.Ord_Pdt_Qty,
                 , C1.Ord_NO
                 , '1' -- C1.Deli_Seq
                 , C1.Pdt_Seq
                 , ''    --'출고등록 : ' || vDeli_NO,
                 , SP_Work_User);        
          END LOOP;
        END IF;
      END IF;       
    END LOOP;
  END IF;
  
  ------------------------------------------------------------------------------
  -- 입금정보저장 
  ------------------------------------------------------------------------------
  vRcpt_Amt    := 0;

  vRcpt_Cash   := 0;
  vRcpt_Card   := 0;
  vRcpt_Bank   := 0;
  vRcpt_Vbank  := 0;
  vRcpt_Prepay := 0;
  vRcpt_Point  := 0;
  vRcpt_Ars    := 0;
  vRcpt_Coin   := 0;
  vRcpt_Etc    := 0;
  vRcpt_Yn     := 'N';
  vUse_Yn      := 'Y';
  vRcpt_Cnt    := 0;  -- 미입금건이포함여부 체크 변수
  vError_Point := 11;
  
  FOR C1 IN (SELECT *
               FROM Ord_Money_Tmp
              WHERE Com_Id = SP_Com_Id
                AND Ord_No_Tmp = SP_Ord_No_Tmp )LOOP
  
    -- 현금 
    IF    C1.Kind = ufCom_CD(SP_Com_Id)||'s01' THEN  vRcpt_Cash   := vRcpt_Cash   + C1.Amt;  vAmt_Use := C1.Amt; vRcpt_Cnt := vRcpt_Cnt + 0;  
    --  신용카드
    ELSIF C1.Kind = ufCom_CD(SP_Com_Id)||'s02' THEN  vRcpt_Card   := vRcpt_Card   + C1.Amt;  vAmt_Use := C1.Amt; vRcpt_Cnt := vRcpt_Cnt + 0;
    -- 무통장
    ELSIF C1.Kind = ufCom_CD(SP_Com_Id)||'s03' THEN  
        IF vWork_Kind ='M' THEN 
          vRcpt_Bank   := 0;  vAmt_Use := 0; vRcpt_Cnt := vRcpt_Cnt + 1; vUse_Yn :='N'; -- vRcpt_Bank   + C1.Amt;
        ELSE
         vRcpt_Bank   := vRcpt_Bank   + C1.Amt;  vAmt_Use := C1.Amt; vRcpt_Cnt := vRcpt_Cnt +0; 
        END IF;
        
        -- 와우넷, 마이오피스 모두 입금처리를 해야한다. 
        vRcpt_Bank   := 0;  vAmt_Use := 0; vRcpt_Cnt := vRcpt_Cnt + 1; vUse_Yn :='Y'; -- vRcpt_Bank   + C1.Amt;  
          
    -- 가상계좌
    ELSIF C1.Kind = ufCom_CD(SP_Com_Id)||'s04' THEN  
        IF vWork_Kind ='M' THEN 
          vRcpt_Vbank  := 0;  vAmt_Use := 0; vRcpt_Cnt := vRcpt_Cnt + 1; vUse_Yn :='N'; -- vRcpt_Vbank  + C1.Amt;
        ELSE
          vRcpt_Vbank  := vRcpt_Vbank  + C1.Amt;  vAmt_Use := C1.Amt; vRcpt_Cnt := vRcpt_Cnt + 0;
        END IF;
        
        -- 가상계좌는 후입금처리(결제사 Noti처리)를 해야한다. 이광호_20211108  
        vRcpt_Vbank  := 0;  vAmt_Use := 0; vRcpt_Cnt := vRcpt_Cnt + 1; vUse_Yn :='Y'; -- vRcpt_Vbank  + C1.Amt;
         
    -- 선결제
    ELSIF C1.Kind = ufCom_CD(SP_Com_Id)||'s05' THEN  vRcpt_Prepay := vRcpt_Prepay + C1.Amt;  vAmt_Use := C1.Amt; vRcpt_Cnt := vRcpt_Cnt + 0;
    -- 포인트
    ELSIF C1.Kind = ufCom_CD(SP_Com_Id)||'s06' THEN  vRcpt_Point  := vRcpt_Point  + C1.Amt;  vAmt_Use := C1.Amt; vRcpt_Cnt := vRcpt_Cnt + 0;
    -- ARS 결제
    ELSIF C1.Kind = ufCom_CD(SP_Com_Id)||'s07' THEN  vRcpt_Ars    := vRcpt_Ars    + C1.Amt;  vAmt_Use := C1.Amt; vRcpt_Cnt := vRcpt_Cnt + 0;
    -- 코인
    ELSIF C1.Kind = ufCom_CD(SP_Com_Id)||'s08' THEN  vRcpt_Coin   := vRcpt_Coin   + C1.Amt;  vAmt_Use := C1.Amt; vRcpt_Cnt := vRcpt_Cnt + 0;
    -- 기타
    ELSIF C1.Kind = ufCom_CD(SP_Com_Id)||'s09' THEN  vRcpt_Etc    := vRcpt_Etc    + C1.Amt;  vAmt_Use := C1.Amt; vRcpt_Cnt := vRcpt_Cnt + 0;
    
    END IF; 
    
    ----------------------------------------------------------------------------
    -- vRcpt_Amt : 결제 금액 합산  비교값  
    ----------------------------------------------------------------------------
    /*
    IF ( C1.Kind = ufCom_CD(SP_Com_Id)||'s03') OR (C1.Kind = ufCom_CD(SP_Com_Id)||'s04')THEN  --미입금건의 합계금액은 0 
      vRcpt_Amt := 0; 
    ELSE 
      vRcpt_Amt := vRcpt_Amt +C1.Amt;
    END IF;
    */
    vRcpt_Amt := vRcpt_Cash + vRcpt_Card + vRcpt_Bank + vRcpt_Vbank + vRcpt_Prepay + vRcpt_Point + vRcpt_Ars + vRcpt_Coin + vRcpt_Etc;

    --SELECT DECODE(COUNT(*), 0 , 'INS','UPD') INTO vMoney_Kind
    --  FROM Ord_Money
    -- WHERE Com_ID = C1.Com_Id
    --   AND Money_No = C1.Money_No;
    --IF vMoney_Kind = 'INS' THEN
    ----------------------------------------------------------------------------\
    -- 전제조건 : 기등록한 입금을 불러 오는 경우 > ORD_MONEY_TMP.MONEY_NO_ORG IS NOT NULL  (ORD_MONEY_TMP.MONEY_NO_ORG = 원 입금번호) 
    --            신규 결제(현금/카드/무통장/등등) > ORD_MONEY_TMP.MONEY_NO_ORG IS NULL  
    ----------------------------------------------------------------------------
    IF NVL(C1.Money_NO_Org, '-') = '-' THEN
      INSERT INTO Ord_Money(Com_Id
                      , Money_No
                      , Money_No_Org
                      , Seq
                      , Userid
                      , Reg_Date
                      , Kind
                      , Amt
                      , Amt_Used
                      , Amt_Balance
                      , Use_Yn
                      , Remark 
                      , Card_Cd
                      , Card_No
                      , Card_Holder
                      , Card_Cms_Rate
                      , Card_Install 
                      , Card_YYMM
                      , Card_App_No
                      , Card_App_Date
                      , Self_Yn
                      , Ins_Date
                      , Ins_User
                      , Upd_Date
                      , Upd_User
              )Values( C1.Com_Id
                     , C1.Money_No
                     , C1.Money_No                  -- Money_No_Org
                     , C1.Seq
                     , C1.UserId
                     , TO_CHAR(SYSDATE,'YYYYMMDD') --  Reg_Date
                     , C1.Kind
                     , C1.Amt
                     , vAmt_Use --C1.Amt_Used
                     , (C1.Amt-C1.Amt_Used)        -- Amt_Balance
                     , vUse_Yn                     -- Use_Yn
                     , ''                          -- Remark  필드없음. 추가필요!!!!
                     , C1.Card_Cd
                     , Encrypt_PKG.Enc_Card(C1.Card_No)
                     , C1.Card_Holder
                     , C1.Card_Rate                -- Card_Cms_Rate
                     , C1.Card_Install
                     , C1.Card_YYMM
                     , C1.Card_App_No
                     , C1.Card_App_Date 
                     , 'Y'                          --  Self_YN          --본인 결제여부 확인필요 
                     , SYSDATE                      -- Ins_Date
                     , SP_Work_User                 -- Ins_User
                     , SYSDATE                      -- Upd_Date
                     , SP_Work_User                 -- Upd_User
                    ); 
    ELSE
      --------------------------------------------------------------------------
      -- 예외 상황 체크.
      -- 1. 해당 입금번호가 있는지.
      -- 2. 입금 잔액이 사용할려는 금액 이상인지.
      --------------------------------------------------------------------------
      SELECT COUNT(1) INTO vTmp
        FROM Ord_Money
       WHERE Money_NO = C1.Money_NO_Org
         AND Com_ID   = C1.Com_ID;

      IF vTmp = 0 THEN
        SP_RetCode := 'ERROR';
        SP_RetStr  := ufMessage('입금내역이 확인되지 않습니다.', vLang_CD);
        ROLLBACK;
        RETURN; 
      END IF;
      
      SELECT Amt - Amt_Used INTO vAmt
        FROM Ord_Money
       WHERE Money_NO = C1.Money_NO_Org
         AND Com_ID   = C1.Com_ID;
         
      IF vAmt < C1.Amt THEN
        SP_RetCode := 'ERROR';
        SP_RetStr  := ufMessage('사용할려는 입금의 잔액이 부족합니다.', vLang_CD);
        ROLLBACK;
        RETURN; 
      END IF;
      
      UPDATE Ord_Money
         SET Amt_Used    = Amt_Used + C1.Amt
           , Amt_Balance = Amt - (Amt_Used + C1.Amt)      --BinhNV add -2021.08.21
       WHERE Money_NO = C1.Money_NO_Org
         AND Com_ID   = C1.Com_ID;
    END IF;
    
    ---------------------------------------------------------------------------- 
    -- Ord_Rcpt 저장 
    ----------------------------------------------------------------------------
    INSERT INTO Ord_Rcpt( Com_Id
                        , Ord_No
                        , Money_No
                        , Userid
                        , Amt
                        , Remark
                        , Work_Date
                        , Work_User
                )Values(  C1.Com_Id
                        , vOrd_No
                        , C1.Money_No
                        , C1.Userid
                        , vAmt_Use
                        , ''           -- Remark
                        , SYSDATE      -- Work_Date
                        , SP_Work_User -- Work_User
                );  
                
  END LOOP;
  
  vError_Point := 12;
  
  ------------------------------------------------------------------------------
  -- 주문 상품 금액 
  ------------------------------------------------------------------------------
   SELECT SUM(Amt * Qty) INTO vPdt_Total_Amt
     FROM Ord_Pdt  
    WHERE Com_Id = SP_Com_Id 
      AND Ord_No = vOrd_No;   
      
  vError_Point := 13;
  
  --DBMS_OUTPUT.PUT_LINE('vTotal_Amt: '|| vTotal_Amt);
  --DBMS_OUTPUT.PUT_LINE('vPdt_Total_Amt: '|| vPdt_Total_Amt);
  ------------------------------------------------------------------------------
  -- 주문합계 와 주문 상품 금액을 비교한다. 
  ------------------------------------------------------------------------------
  IF vTotal_Amt <> vPdt_Total_Amt THEN 
    SP_RetCode := 'ERROR';
    --SP_RetStr  := ufMessage('주문합계금액과 주문상품 금액이 일치하지 않습니다.', vLang_CD);
    SP_RetStr  := ufMessage('주문합계금액('||vTotal_Amt||') 과 주문상품 금액 ('||vPdt_Total_Amt||')이 일치하지 않습니다.', vLang_CD);
    ROLLBACK;
    RETURN;
  END IF;
  
  ------------------------------------------------------------------------------
  -- 주문합산과 입금 금액을 비교한다. 마이오피스의 경우 무통장금액과 가상계좌 금액은 입금전이기때문에 비교 제외 
  ------------------------------------------------------------------------------
  IF (vRcpt_Cnt < 1) THEN
  
    IF vTotal_Amt <> vRcpt_Amt THEN 
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('주문합계금액과 입금 금액이 일치하지 않습니다.'|| vTotal_Amt ||','|| vRcpt_Amt, vLang_CD);
    --SP_RetStr  := ufMessage('주문합계금액('||vTotal_Amt||') 과 입금 금액('||vRcpt_Amt||')이 일치하지 않습니다.', vLang_CD);
      ROLLBACK;
      RETURN;
    END IF;
  
  END IF;
  
  ------------------------------------------------------------------------------
  -- 주문상품합산과 입금 금액을 비교한다. 마이오피스의 경우 무통장금액과 가상계좌 금액은 입금전이기때문에 비교 제외 
  ------------------------------------------------------------------------------
  IF (vRcpt_Cnt < 1) THEN
    IF vPdt_Total_Amt <> vRcpt_Amt THEN 
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('주문상품 금액과 입금 금액이 일치하지 않습니다.', vLang_CD);
      --SP_RetStr  := ufMessage('주문상품 금액('||vPdt_Total_Amt||') 과 입금 금액('||vRcpt_Amt||')이 일치하지 않습니다.', vLang_CD);
      ROLLBACK;
      RETURN;
    END IF;
  END IF;
  vError_Point := 15;
 
  ------------------------------------------------------------------------------
  --  입금 금액과  합계금액이 다른경우는 입금완료 처리하지않는다.
  ------------------------------------------------------------------------------
  
  IF vRcpt_Amt <>  vTotal_Amt THEN
    vRcpt_Yn := 'N';
  ELSE
    vRcpt_Yn := 'Y';
  END IF; 
 
  ------------------------------------------------------------------------------- 
  -- Ord_Mst 테이블의 입금정보를 업데이트한다.
  -------------------------------------------------------------------------------
  UPDATE Ord_Mst
     SET Rcpt_Yn     = vRcpt_Yn
       , Rcpt_Cash   = vRcpt_Cash
       , Rcpt_Card   = vRcpt_Card              
       , Rcpt_Bank   = vRcpt_Bank   
       , Rcpt_Vbank  = vRcpt_Vbank  
       , Rcpt_Prepay = vRcpt_Prepay 
       , Rcpt_Point  = vRcpt_Point  
       , Rcpt_Ars    = vRcpt_Ars    
       , Rcpt_Coin   = vRcpt_Coin   
       , Rcpt_Etc    = vRcpt_Etc   
       , Rcpt_Total  = vRcpt_Amt 
   WHERE Com_Id = SP_Com_Id 
     AND Ord_No = vOrd_No;  
     
  IF (vRcpt_Point > 0) THEN 
    INSERT INTO Mem_Point
       ( Seq
       , Com_ID
       , Reg_Date          
       , Userid    
       , Username        
       , Kind_CD
       , Kind_Name
       , Ord_No
       , Amt               
       , Remark
       , Work_User)
    VALUES(SEQ_POINT.NextVal
       , SP_Com_ID
       , SP_Acc_Date          
       , SP_Userid            
       , UFNAME(SP_Com_ID,'USERNAME',SP_Userid)
       , '22'              
       , UFNAME(SP_Com_ID,'CODE','22')
       , vOrd_No
       , -vRcpt_Point
       , ''
       , SP_Work_User );
  END IF;
     
  --MEMBER_POINT_PKG.MEM_POINT_INS_SP('0', SP_Com_Id, SP_Acc_Date, SP_Userid, '22', -vRcpt_Point, '', SP_Work_User);
  
  vError_Point := 16;
  ------------------------------------------------------------------------------- 
  -- Member 테이블에 마지막 주문일자로 현재일자를 업데이트 한다.
  -------------------------------------------------------------------------------
  UPDATE Member
     SET Date_Ord = v.Ord_Date
   WHERE Com_Id = SP_Com_Id  
     AND Userid = SP_Userid;
   
  ------------------------------------------------------------------------------- 
  -- 정상 완료될경우 TMP 테이블은 삭제한다. 
  -- 장바구니의 일부상품만을 구매하는 경우, 구매 상품만을 삭제 + 나머지 정보는 유지 되어야 한다.
  -- > Case1. Ord_Pdt_Tmp 에서 해당 상품만 삭제.
  -------------------------------------------------------------------------------
  SELECT COUNT(1) INTO vCnt
    FROM Ord_Pdt_Tmp
   WHERE Ord_NO_Tmp = SP_Ord_No_Tmp
     AND Ord_Yn <> 'Y';

  IF vCnt = 0 THEN
    DELETE FROM Ord_Money_Tmp WHERE Ord_No_Tmp = SP_Ord_No_Tmp;
    DELETE FROM Ord_Deli_Tmp  WHERE Ord_No_Tmp = SP_Ord_No_Tmp;
    DELETE FROM Ord_Pdt_Tmp   WHERE Ord_No_Tmp = SP_Ord_No_Tmp;
    DELETE FROM Ord_Mst_Tmp   WHERE Ord_No_Tmp = SP_Ord_No_Tmp;
  ELSE
    DELETE FROM Ord_Money_Tmp WHERE Ord_No_Tmp = SP_Ord_No_Tmp;
    DELETE FROM Ord_Deli_Tmp  WHERE Ord_No_Tmp = SP_Ord_No_Tmp;
    DELETE FROM Ord_Pdt_Tmp   WHERE Ord_No_Tmp = SP_Ord_No_Tmp AND Ord_YN = 'Y';
    Update Ord_Mst_Tmp Set Status = 'BEFORE' WHERE Ord_No_Tmp = SP_Ord_No_Tmp;
  END IF;    
 
  vError_Point := 17;
  
  ---------------------------------------------------------------------------- 
  -- 마이오피스로 주문했을 떄, 생성된 남은 바로구매 결제건들을 삭제한다.
  ----------------------------------------------------------------------------
  IF vWork_Kind = 'M' THEN
    Delete FROM Ord_Deli_Tmp  WHERE Ord_No_Tmp IN ( SELECT Ord_No_Tmp FROM Ord_Mst_Tmp WHERE Com_ID = SP_Com_ID AND Direct_YN = 'Y' AND Work_Kind = 'M' AND Userid = SP_Userid );
    Delete FROM Ord_Pdt_Tmp   WHERE Ord_No_Tmp IN ( SELECT Ord_No_Tmp FROM Ord_Mst_Tmp WHERE Com_ID = SP_Com_ID AND Direct_YN = 'Y' AND Work_Kind = 'M' AND Userid = SP_Userid );
    Delete FROM Ord_Money_Tmp WHERE Ord_No_Tmp IN ( SELECT Ord_No_Tmp FROM Ord_Mst_Tmp WHERE Com_ID = SP_Com_ID AND Direct_YN = 'Y' AND Work_Kind = 'M' AND Userid = SP_Userid );
    Delete FROM Ord_Mst_Tmp   WHERE Com_ID = SP_Com_ID AND Direct_YN = 'Y' AND Work_Kind = 'M' AND Userid = SP_Userid;
  END IF;
  
  
  vError_Point := 18;
  
  ------------------------------------------------------------------------------ 
  -- 특판일경우 관련 프로시저 호출한다. 
  ------------------------------------------------------------------------------
  
  ------------------------------------------------------------------------------ 
  -- SMS 허용인원만 SMS 발송한다.
  ------------------------------------------------------------------------------
  /*
  IF vSms_Ok = 'Y' THEN
  
  END IF; 
  */
  
  ------------------------------------------------------------------------------
  SP_KeyValue := vOrd_No;
  SP_RetCode  := 'OK';
  SP_RetStr   := ufMessage('정상적으로 등록되었습니다.', vLang_CD);
    
  COMMIT;
  
  ------------------------------------------------------------------------------
  -- [종료시간]프로시저 실행시간 체크 및 정상성공여부 확인. 
  ------------------------------------------------------------------------------
  Log_Work_Time_SP(SP_Com_ID, vLog_Seq, 'ORD', 'ORD_INS_SP', SP_Work_User , '[Complete]');

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100) ||' / Error-PointNumber : '||vError_Point;
    
    DBMS_OUTPUT.PUT_LINE('SP_RetCode: '|| SP_RetCode);
    DBMS_OUTPUT.PUT_LINE('SP_RetStr : '|| SP_RetStr); 
    ROLLBACK;
    Order_PKG.Log_Ord_Error_SP(SP_Com_Id, SP_Ord_No_Tmp, vOrd_No,'', SP_RetStr, SP_Work_User );
    
    ----------------------------------------------------------------------------
    -- [종료시간]프로시저 실행시간 체크 및 정상성공여부 확인. 
    ----------------------------------------------------------------------------
    Log_Work_Time_SP(SP_Com_ID, vLog_Seq, 'ORD', 'ORD_INS_SP', SP_Work_User , '[Exception]');
END;
/* -------------------------------------------------------------------------- */
/* Package Member : ORD_INS_SP [Insert] - END -                               */
/* -------------------------------------------------------------------------- */





/* -------------------------------------------------------------------------- */
/* Package Member : Log_Ord_Error [Insert]                                    */
/* Work    Date   : 2021-03-31 Created by Joo                                 */
/* -------------------------------------------------------------------------- */
PROCEDURE Log_Ord_Error_SP  (
  SP_Com_ID             IN  VARCHAR2,   -- 회사번호 (Company.Com_ID) S？ cong ty (Company.Com_ID);
  SP_Ord_No_Tmp         IN  VARCHAR2,   -- 임시주분번호 (SEQ_Tmp 시퀀스 사용) S？ tu？n t？m th？i (s？ d？ng chu？i SEQ_Tmp)
  SP_Ord_No             IN  VARCHAR2,   -- 주문번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리) S？ th？ t？ (YYMMDD-HHMISS- + day 3 ch？ s？, t？ng s？ 17 ch？ s？)
  SP_Kind               IN  VARCHAR2,   -- 결제유형(Code.Code_CD) Lo？i thanh toan (Code.Code_CD)
  SP_Error_Msg          IN  VARCHAR2,   -- 에러메세지 Thong bao l？i
  SP_Work_User          IN  VARCHAR2    -- 최초 작업자번호 ID ng？？i lam vi？c đ？u tien
  ------------------------------------------------------------------------------
)
IS
BEGIN
  
  INSERT INTO Log_Ord_Error ( Com_ID
                            , Reg_NO 
                            , Ord_NO_Tmp 
                            , Ord_NO 
                            , Kind
                            , Error_Msg
                            , Work_Date
                            , Work_User
                    )VALUES( SP_Com_ID
                           , SEQ_Log.Nextval  
                           , SP_Ord_No_Tmp 
                           , SP_Ord_No
                           , SP_Kind 
                           , SP_Error_Msg
                           , SYSDATE 
                           , SP_Work_User
                            );  

  COMMIT;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Log_Ord_Error_SP [Insert] - END -                         */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Order  : Ord_Tmp_Chk_SP [Insert]                                   */
/* Work    Date   : 2021-04-01 Created by Joo                                 */
/* Memo           : 장바구니 체크 프로시저                                    */
/* -------------------------------------------------------------------------- */
-- EXEC ORDER_PKG_JYH.ORD_TMP_CHK_SP('WOWNET','6','admin_KR',:SP_RETCODE,:SP_RETSTR);
PROCEDURE Ord_Tmp_Chk_SP  (
  SP_Com_ID             IN  VARCHAR2,   -- 회사번호 (Company.Com_ID) S？ cong ty (Company.Com_ID);
  SP_Ord_No_Tmp         IN  VARCHAR2,   -- 임시주분번호 (SEQ_Tmp 시퀀스 사용) S？ tu？n t？m th？i (s？ d？ng chu？i SEQ_Tmp)
  SP_Work_User          IN  VARCHAR2,   -- 최초 작업자번호 ID ng？？i lam vi？c đ？u tien      
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2,   -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2    -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vLang_CD              VARCHAR2(2);
  v                     Ord_Mst_Tmp%ROWTYPE; 
  vCnt                  NUMBER;
  vOrd_Amt              NUMBER;
  vDeli_Amt             NUMBER;
  vTotal_Amt            NUMBER;
  vRcpt_Amt             NUMBER;
  
  vStatus               VARCHAR2(5);
  vSale_Sdate           VARCHAR2(8);
  vSale_Edate           VARCHAR2(8);
  vSale_Min_Qty         NUMBER;
  vSale_Max_Qty         NUMBER;
  vToday                VARCHAR2(8);
  vWork_Kind            VARCHAR2(1);
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Work_Kind INTO vWork_Kind
    FROM Ord_Mst_Tmp
   WHERE Com_Id = SP_Com_Id
     AND Ord_No_Tmp = SP_ORD_NO_TMP;

  IF vWork_Kind = 'M' THEN
    SELECT Ctr_Cd INTO vLang_CD
      FROM Member
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User; 
  ELSE 
    SELECT Lang_CD INTO vLang_CD
      FROM SM_User
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  END IF;

  ------------------------------------------------------------------------------
  -- 1) 존재하는 장바구니건 체크 
  ------------------------------------------------------------------------------
  BEGIN  
    SELECT * INTO v
      FROM Ord_Mst_Tmp
     WHERE Com_ID = SP_Com_Id 
       AND Ord_No_Tmp = SP_Ord_No_Tmp;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN v.Ord_No_Tmp := '-1';
  END;

  IF v.ORD_NO_TMP = '-1' THEN 
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문이 존재하지 않습니다.', vLang_CD);
    
    --DBMS_OUTPUT.PUT_LINE('SP_RetCode: '|| SP_RetCode);
    --DBMS_OUTPUT.PUT_LINE('SP_RetStr : '|| SP_RetStr);
    
    RETURN;
  END IF;       
  ------------------------------------------------------------------------------
  -- 2) 존재하는 회원 여부 체크  
  ------------------------------------------------------------------------------
  BEGIN
    SELECT COUNT(1) 
      INTO vCnt 
      FROM Member
     WHERE Com_ID = SP_Com_Id  
       AND Userid = v.Userid;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN vCnt := '-1';
  END;

  IF vCnt = '-1' THEN 
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회원이 존재하지 않습니다.', vLang_CD);
    
    --DBMS_OUTPUT.PUT_LINE('SP_RetCode: '|| SP_RetCode);
    --DBMS_OUTPUT.PUT_LINE('SP_RetStr : '|| SP_RetStr);
    
    RETURN;     
  END IF;
  
  ------------------------------------------------------------------------------
  -- 3) 상품금액 / 입금 금액 일치여부 체크 
  ------------------------------------------------------------------------------
  
  ------------------------------------------------------------------------------
  --배송비 금액
  ------------------------------------------------------------------------------
  SELECT Deli_Amt  INTO vDeli_Amt 
    FROM Ord_Deli_Tmp
   WHERE Com_ID = SP_Com_Id
     AND Ord_No_Tmp = SP_Ord_No_Tmp;
  ------------------------------------------------------------------------------
  -- 주문 상품 합계 금액 
  ------------------------------------------------------------------------------
  SELECT Sum(Amt * Qty) INTO vOrd_Amt
    FROM Ord_Pdt_Tmp
   WHERE Com_ID = SP_Com_Id
     AND Ord_No_Tmp = SP_Ord_No_Tmp
     AND Ord_YN = 'Y';
    
  vTotal_Amt := vOrd_Amt + vDeli_Amt;

  ------------------------------------------------------------------------------
  -- 입금금액 합계 금액 
  ------------------------------------------------------------------------------
  SELECT Sum(Amt) INTO vRcpt_Amt
    FROM Ord_Money_Tmp
   WHERE Com_ID = SP_Com_Id
     AND Ord_No_Tmp = SP_Ord_No_Tmp;
         
  IF vTotal_Amt <> vRcpt_Amt THEN 
  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문금액과 입금금액이 일치하지않습니다.', vLang_CD);
    
    --DBMS_OUTPUT.PUT_LINE('SP_RetCode: '|| SP_RetCode);
    --DBMS_OUTPUT.PUT_LINE('SP_RetStr : '|| SP_RetStr);
    
    RETURN;
    
  END IF;   
     
  ------------------------------------------------------------------------------
  -- 4) 주문가능 상품
  --    상품 상태 체크
  --    상품 일자 체크   
  --    주문가능 수량 체크   
  ------------------------------------------------------------------------------
  vToday := TO_CHAR(SYSDATE,'YYYYMMDD');
  
  FOR C1 IN ( SELECT *
                FROM Ord_Pdt_Tmp
               WHERE Com_Id     = SP_Com_Id
                 AND Ord_No_Tmp = SP_Ord_No_Tmp 
             )LOOP
  
    SELECT Status 
         , Sale_Sdate
         , NVL(Sale_Edate,'29990101')
         , Sale_Min_Qty
         , Sale_Max_Qty
      INTO vStatus 
         , vSale_Sdate
         , vSale_Edate
         , vSale_Min_Qty
         , vSale_Max_Qty     
      FROM Pdt_Mst
     WHERE Com_Id     = C1.Com_Id
       AND Pdt_Cd     = C1.Pdt_Cd;  
     
     ---------------------------------------------------------------------------     
     -- 하나라도 정상판매중 포함되지않을경우  
     ---------------------------------------------------------------------------
     IF vStatus <> ufCom_CD(SP_Com_Id)||'P10' THEN 
       SP_RetCode := 'ERROR';
       SP_RetStr  := ufMessage('상품의 판매상태를 확인해주시기 바랍니다.', vLang_CD);
       --DBMS_OUTPUT.PUT_LINE('SP_RetCode: '|| SP_RetCode);
       --DBMS_OUTPUT.PUT_LINE('SP_RetStr : '|| SP_RetStr);
       RETURN;
     END IF;
     ---------------------------------------------------------------------------     
     -- 상품등록일자가 주문일자보다 빠른경우 
     ---------------------------------------------------------------------------
     IF  vSale_Sdate  >  vToday THEN 
       SP_RetCode := 'ERROR';
       SP_RetStr  := ufMessage('주문할수 없는 상품이 포함되어있습니다.', vLang_CD);
       --DBMS_OUTPUT.PUT_LINE('SP_RetCode: '|| SP_RetCode);
       --DBMS_OUTPUT.PUT_LINE('SP_RetStr : '|| SP_RetStr);
       RETURN;
     END IF;
     ---------------------------------------------------------------------------     
     -- 상품종료일자가 주문일자 보다 지난 경우  
     ---------------------------------------------------------------------------
     IF  vToday > vSale_Edate THEN 
       SP_RetCode := 'ERROR';
       SP_RetStr  := ufMessage('주문할수 없는 상품이 포함되어있습니다.', vLang_CD);
       --DBMS_OUTPUT.PUT_LINE('SP_RetCode: '|| SP_RetCode);
       --DBMS_OUTPUT.PUT_LINE('SP_RetStr : '|| SP_RetStr);
       RETURN;
     END IF;  
     
     ---------------------------------------------------------------------------     
     -- 주문 가능 최대수량 체크   
     ---------------------------------------------------------------------------
     -- 기본 최대가능수량이 0 이기때문에 0인경우는 수량제한을 하지않는다.
     ---------------------------------------------------------------------------
     IF vSale_Max_Qty > 0 THEN 
       IF C1.QTY > vSale_Max_Qty  THEN 
         SP_RetCode := 'ERROR';
         SP_RetStr  := ufMessage('주문 가능 수량을 초과하였습니다.', vLang_CD);
         --DBMS_OUTPUT.PUT_LINE('SP_RetCode: '|| SP_RetCode);
         --DBMS_OUTPUT.PUT_LINE('SP_RetStr : '|| SP_RetStr);
       END IF;
     END IF;         
             
  END LOOP;           
  
  SP_RetCode  := 'OK';
  SP_RetStr   := ufMessage('등록가능', vLang_CD);
  
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    
    --DBMS_OUTPUT.PUT_LINE('SP_RetCode: '|| SP_RetCode);
    --DBMS_OUTPUT.PUT_LINE('SP_RetStr : '|| SP_RetStr); 
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Tmp_Chk_SP [Select] - END -                           */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Order  : Pg_Pay_SP [Insert]                                        */
/* Work    Date   : 2021-04-23 Created by Joo                                 */
/* Memo           : 선결제 저장 프로시저                                      */
/* -------------------------------------------------------------------------- */
PROCEDURE Pg_Pay_SP  (
  SP_Com_ID                IN  VARCHAR2,   -- 회사번호 (Company.Com_ID) S？ cong ty (Company.Com_ID);
  --SP_Reg_NO                IN  VARCHAR2,   --   등록번호 (SEQ_PK 시퀀스 사용) 
  SP_Kind_CD               IN  VARCHAR2,   -- 결제타입코드(Code.Code_CD)
  SP_Mid                   IN  VARCHAR2,   -- 상점아이디
  SP_Userid                IN  VARCHAR2,   --  회원번호 (Member.Userid)
  SP_Amt                   IN  VARCHAR2,   -- 금액
  SP_Card_App_Date         IN  VARCHAR2,   -- 승인일자(YYYYMMDD)
  SP_Card_App_NO           IN  VARCHAR2,   -- 승인번호
  SP_Result_CD             IN  VARCHAR2,   -- 결과코드
  SP_Result_MSG            IN  VARCHAR2,   -- 결과메시지
  SP_Status                IN  VARCHAR2,   -- 진행단계(BEFORE 결제진행전/ TRY 결제시도 / PROCESS 결제진행중)
  SP_Card_CD               IN  VARCHAR2,   -- 신용카드결제시 : 카드사코드 / 무통장송금시 : 회사 은행코드 (Bank.Bank_CD)
  SP_Card_Install          IN  VARCHAR2,   -- 신용카드 할부개월수
  --SP_Money_NO              IN  VARCHAR2,   --  입금번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리)
  --SP_Work_Date             IN  VARCHAR2,   -- 작업일자
  SP_Work_User             IN  VARCHAR2,   -- 작업자번호 
  ------------------------------------------------------------------------------
  SP_RetCode               OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr                OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)IS

  vCom_ID   VARCHAR2(10);
  v         Ord_Money%ROWTYPE;
  vSeq      PLS_INTEGER;           
BEGIN

  v.Money_NO := TO_CHAR(SYSDATE, 'YYYYMMDD-HH24MISS') || '-';

  SELECT COUNT(1) + 1 INTO vSeq
    FROM Ord_Money
   WHERE Money_NO LIKE v.Money_NO || '%';
     
  v.Money_NO := v.Money_NO || LPAD(vSeq, 3, '0'); 
   
    INSERT INTO PG_PrePay ( Com_ID       
                          , Reg_NO       
                          , Kind_CD      
                          , Mid          
                          , Userid       
                          , Amt          
                          , Card_App_Date
                          , Card_App_NO  
                          , Result_CD    
                          , Result_MSG   
                          , Status       
                          , Card_CD      
                          , Card_Install 
                          , Money_NO     
                          , Work_Date    
                          , Work_User    
                  )VALUES(  SP_Com_ID       
                          , SEQ_PK.NextVal       
                          , SP_Kind_CD      
                          , SP_Mid          
                          , SP_Userid       
                          , SP_Amt          
                          , SP_Card_App_Date
                          , SP_Card_App_NO  
                          , SP_Result_CD    
                          , SP_Result_MSG   
                          , SP_Status       
                          , SP_Card_CD      
                          , SP_Card_Install 
                          , v.Money_NO     
                          , SYSDATE    
                          , SP_Work_User    
                  ); 
                  
  SP_RetCode := v.Money_NO;                  
  COMMIT;                      
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    --DBMS_OUTPUT.PUT_LINE('SP_RetCode: '|| SP_RetCode);
    --DBMS_OUTPUT.PUT_LINE('SP_RetStr : '|| SP_RetStr); 
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Pg_Pay_SP [Insert] - END -                                */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Mst_Info_UPD [Update]                                 */
/* Work    Date   : 2021-05-11 Created by Jang                                */
/* Memo           : 주문수정 - 일반정보 탭 수정 프로시저                      */
/* -------------------------------------------------------------------------- */
PROCEDURE Ord_Mst_Info_UPD_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID) S？ cong ty (Company.Com_ID)
  SP_Ord_NO             IN  VARCHAR2, --    NOT NULL 주문번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리) S？ th？ t？ (YYMMDD-HHMISS- + day 3 ch？ s？, t？ng s？ 17 ch？ s？)
  SP_Userid             IN  VARCHAR2, --    NOT NULL 회원번호(Member.Userid) S？ thanh vien (Member.Userid)
  SP_Cnt_Cd             IN  VARCHAR2, --    NOT NULL 주문센터코드(Center.Cnt_CD) Ma trung tam đ？t hang (Center.Cnt_CD)
  SP_Ord_Date           IN  VARCHAR2, --    NOT NULL 주문일자(YYYYMMDD) Ngay đ？t hang (YYYYMMDD)
  SP_Acc_Date           IN  VARCHAR2, --        NULL 승인일자(YYYYMMDD) Ngay phe duy？t (YYYYMMDD)
  SP_Kind_Cd            IN  VARCHAR2, --    NOT NULL 주문유형코드(Code.Code_CD) 신규주문/재구매/오토십... Ma lo？i đ？n đ？t hang (Code.Code_CD) đ？n hang m？i / Mua l？i / T？ đ？ng ...
  SP_Path_Cd            IN  VARCHAR2, --    NOT NULL 주문경로코드(Code.Code_CD) 본사/센터/마이오피스/... Ma đ？？ng d？n đ？t hang (Code.Code_CD) Tr？ s？ / Trung tam / My Office / ...
  SP_Remark             IN  VARCHAR2, --        NULL 비고사항 Nh？n xet
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호  
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, --    NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --        NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --        NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --        NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --        NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --        NULL 장치구분 (PC, PHONE, TABLET)
  SP_IP_Addr            IN  VARCHAR2, --        NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --        NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  v                     Ord_Mst%ROWTYPE; -- 테이블 변수 Bi？n table
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vO_Ord_Date           VARCHAR2(1); -- 2022.08.22 황우상 추가 
  vO_Acc_Date           VARCHAR2(1); -- 2022.08.22 황우상 추가
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  IF SP_Log_Kind = 'MYOFFICE' THEN
    SELECT Ctr_Cd INTO vLang_CD
      FROM Member
     WHERE COM_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  ELSE
    SELECT Lang_CD INTO vLang_CD
      FROM SM_User
     WHERE COM_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  END IF;
  
  IF Trim(SP_Com_ID) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회사아이디를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Ord_NO) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문번호를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Userid) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회원번호를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Cnt_CD) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문센터를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Ord_Date) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문일을 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Kind_Cd) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문유형을 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Path_Cd) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문경로를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  SELECT * INTO v
    FROM ORD_MST
   WHERE ORD_NO = SP_Ord_NO;    

  ------------------------------------------------------------------------------
  -- 회원번호를 변경할수없다.
  ------------------------------------------------------------------------------
  IF v.Userid <> SP_Userid THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := '주문 회원을 변경하실수 없습니다.'; -- SM_Message에 추가해서 ufMessage()호출로 변경해야한다.
    RETURN;  
  END IF;
  
  ------------------------------------------------------------------------------
  -- 주문일자와 승인일자를 변경한다. -- 2022.08.22 황우상 추가 
  ------------------------------------------------------------------------------
  SELECT O_Ord_Date, O_Acc_Date INTO vO_Ord_Date, vO_Acc_Date
    FROM SM_Config
   WHERE Com_ID = SP_Com_ID;
   
  IF (vO_Ord_Date = 'N') AND (v.Ord_Date <> SP_Ord_date) THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := '주문일자를 변경할 수 없습니다.'; -- SM_Message에 추가해서 ufMessage()호출로 변경해야한다.
    RETURN;  
  END IF;
  
  IF (vO_Acc_Date = 'N') AND (v.Acc_Date <> SP_Acc_date) THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := '승인일자를 변경할 수 없습니다.'; -- SM_Message에 추가해서 ufMessage()호출로 변경해야한다.
    RETURN;  
  END IF;

  ------------------------------------------------------------------------------
  -- 데이터를 변경한다.Thay đ？i d？ li？u
  ------------------------------------------------------------------------------
  UPDATE ORD_MST
     SET Userid   = SP_Userid
       , Cnt_Cd   = SP_Cnt_Cd
       , Ord_Date = SP_Ord_Date
       , Acc_Date = SP_Acc_Date
       , Kind_Cd  = SP_Kind_Cd
       , Path_Cd  = SP_Path_Cd
       , Remark   = SP_Remark
       , Upd_Date = SYSDATE
       , Upd_User = SP_Work_User
   WHERE Com_ID   = SP_Com_ID
     AND Ord_NO   = SP_Ord_NO;
     
  ----------------------------------------------------------------------------
  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 수정되었습니다.', vLang_CD); -- đa đ？？c s？a binh th？？ng
  ----------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  -- log_SP : '일반정보 수정' -> ufMessage추가로 변경.
  ------------------------------------------------------------------------------
  Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage('UPD', vLang_CD), SP_Ord_NO || ' 소비자, 배송지 수정');
  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Mst_Info_UPD_SP [Update] - END -                      */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Pdt_UPD_SP [Update]                                   */
/* Work    Date   : 2021-05-11 Created by Jang                                */
/* Memo           : 주문수정 - 주문상품 탭 수정 프로시저                      */
/* -------------------------------------------------------------------------- */
PROCEDURE Ord_Pdt_UPD_SP (
  SP_Work_Kind          IN  VARCHAR2, --    NOT NULL 작업 종류 (D:Delete, N:Normal(Insert/Update))
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID) S？ cong ty (Company.Com_ID)
  SP_Ord_NO             IN  VARCHAR2, --    NOT NULL 주문번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리)
  SP_Pdt_Seq            IN  NUMBER,   --    NOT NULL 주문상품순번 đ？t mua s？n ph？m
  SP_Userid             IN  VARCHAR2, --    NOT NULL 회원번호(Member.Userid) S？ thanh vien (Member.Userid)
  SP_Pdt_CD             IN  VARCHAR2, --    NOT NULL 상품코드(Pdt_Mst.Pdt_CD) Ma s？n ph？m (Pdt_Mst.Pdt_CD)
  SP_Pdt_Option         IN  VARCHAR2, --        NULL 상품 옵션정보 Thong tin l？a ch？n s？n ph？m
  SP_Pdt_Kind           IN  VARCHAR2, --    NOT NULL 상품구분 - NOR 일반상품 / STM 세트마스터 / STD 세트구성품 / GFT 기프트증정품 Phan lo？i s？n ph？m - S？n ph？m chung c？a NOR / B？ chinh STM / Thanh ph？n b？ STD / Qua t？ng GFT
  SP_Qty                IN  NUMBER,   --    NOT NULL 수량 S？ l？？ng
  SP_Price              IN  NUMBER,   --    NOT NULL 단가 đ？n gia
  SP_Vat                IN  NUMBER,   --    NOT NULL 부가세 Thu？ VAT
  SP_Amt                IN  NUMBER,   --    NOT NULL 금액 S？ ti？n
  SP_Pv1                IN  NUMBER,   --    NOT NULL PV1
  SP_Pv2                IN  NUMBER,   --    NOT NULL PV2
  SP_Pv3                IN  NUMBER,   --    NOT NULL PV3
  SP_Point              IN  NUMBER,   --    NOT NULL 적립포인트 Thu nh？p đi？m
  SP_Pdt_Status         IN  VARCHAR2, --    NOT NULL 입출고구분(ORD:주문, C-I:교환입고, C-O:교환출고, RT:반품, CAN:취소) Phan lo？i giao nh？n va nh？n (ORD: đ？t hang, C-I: bien lai trao đ？i, C-O: giao d？ch trao đ？i, RT: tr？ l？i, CAN: h？y b？)
  SP_Serial_NO          IN  VARCHAR2, --        NULL 일련번호 S？ se-ri
  SP_Remark             IN  VARCHAR2, --        NULL 비고사항 Nh？n xet
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호 ID ng？？i lam vi？c
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, -- NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --     NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --     NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --     NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --     NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --     NULL 장치구분 (PC, PHONE, TABLET)
  SP_IP_Addr            IN  VARCHAR2, --     NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --     NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vTmp                  PLS_INTEGER;
  vPdt_Seq              PLS_INTEGER;
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  IF SP_Log_Kind = 'MYOFFICE' THEN
    SELECT Ctr_Cd INTO vLang_CD
      FROM Member
     WHERE COM_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  ELSE
    SELECT Lang_CD INTO vLang_CD
      FROM SM_User
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  END IF; 

  ------------------------------------------------------------------------------
  -- [저장, 수정 공통 체크사항] 필수입력항목의 미입력 및 입력데이터 오류여부 등을 체크한다.
  -- [M？c ki？m tra chung đ？ l？u va s？a đ？i] Ki？m tra xem m？c ch？a đ？？c nh？p c？a h？ng m？c c？n nh？p va m？c nh？p d？ li？u co b？ l？i hay khong.
  ------------------------------------------------------------------------------
  IF Trim(SP_Work_Kind) IS NULL THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('작업종류를 입력하시기 바랍니다.', vLang_CD);
    RETURN;
  END IF;

  IF Trim(SP_Com_ID) IS NULL THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회사아이디를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty
    RETURN;
  END IF;

  IF Trim(SP_Ord_NO) IS NULL THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문번호를 입력하시기 바랍니다.', vLang_CD);
    RETURN;
  END IF;

  IF Trim(SP_Pdt_Seq) IS NULL THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문상품순번을 입력하시기 바랍니다.', vLang_CD);
    RETURN;
  END IF;

  IF Trim(SP_Userid) IS NULL THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회원번호를 입력하시기 바랍니다.', vLang_CD);
    RETURN;
  END IF;

  IF Trim(SP_Pdt_CD) IS NULL THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('상품코드를 입력하시기 바랍니다.', vLang_CD);
    RETURN;
  END IF;

  IF Trim(SP_Pdt_Kind) IS NULL THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('상품구분을 입력하시기 바랍니다.', vLang_CD);
    RETURN;
  END IF;

  IF SP_Work_Kind = 'D' THEN
    DELETE FROM Ord_Pdt
     WHERE COM_ID  = SP_Com_ID
       AND Ord_NO  = SP_Ord_NO
       AND Pdt_Seq = SP_Pdt_Seq;
  ELSE
    SELECT COUNT(*) INTO vTmp
      FROM Ord_Pdt
     WHERE COM_ID  = SP_Com_ID
       AND Ord_NO  = SP_Ord_NO
       AND Pdt_Seq = SP_Pdt_Seq;
    
    IF vTmp = 0 THEN
      SELECT NVL(MAX(Pdt_Seq),0)+1 INTO vPdt_Seq
        FROM Ord_Pdt
       WHERE COM_ID = SP_Com_ID 
         AND Ord_NO = SP_Ord_NO;
       
      INSERT INTO Ord_Pdt
                ( Com_Id
                , Ord_No
                , Ord_No_Org
                , Pdt_Seq
                , Userid
                , Pdt_Cd
                , Pdt_Option 
                , Pdt_Kind
                , Qty
                , Price
                , Vat
                , Amt 
                , Pv1
                , Pv2
                , Pv3
                , Point
                , Pdt_Status
                , Serial_No
                , Remark
                , Work_Date
                , Work_User )
         VALUES ( SP_Com_Id
                , SP_Ord_No
                , SP_Ord_No
                , vPdt_Seq
                , SP_Userid
                , SP_Pdt_Cd
                , SP_Pdt_Option
                , SP_Pdt_Kind
                , SP_Qty
                , SP_Price
                , SP_Vat
                , SP_Amt 
                , SP_Pv1
                , SP_Pv2
                , SP_Pv3
                , SP_Point
                , SP_Pdt_Status
                , SP_Serial_No
                , SP_Remark
                , SYSDATE
                , SP_Work_User );
    ELSE
      UPDATE Ord_Pdt
         SET Pdt_Cd     = SP_Pdt_Cd
           , Pdt_Option = SP_Pdt_Option
           , Pdt_Kind   = SP_Pdt_Kind
           , Qty        = SP_Qty
           , Price      = SP_Price
           , Vat        = SP_Vat
           , Amt        = SP_Amt 
           , Pv1        = SP_Pv1
           , Pv2        = SP_Pv2
           , Pv3        = SP_Pv3
           , Point      = SP_Point
           , Pdt_Status = SP_Pdt_Status
           , Serial_No  = SP_Serial_No
           , Remark     = SP_Remark
       WHERE COM_ID  = SP_Com_ID    
         AND Ord_NO  = SP_Ord_NO
         AND Pdt_Seq = SP_Pdt_Seq;
    END IF;
  END IF;
  
  
  ------------------------------------------------------------------------------
  -- 주문마스터 수정일자를 변경한다.
  ------------------------------------------------------------------------------
  UPDATE ORD_MST
     SET Upd_Date = SYSDATE
       , Upd_User = SP_Work_User
   WHERE Com_ID   = SP_Com_ID
     AND Ord_NO   = SP_Ord_NO;
     

  ----------------------------------------------------------------------------
  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 수정되었습니다.', vLang_CD); -- đa đ？？c s？a binh th？？ng
  ----------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  ------------------------------------------------------------------------------
  Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage('UPD', vLang_CD), '주문 상품 수정');

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Ord_PDT_UPD_SP [Update] - END -                           */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Money_UPD_SP [Update]                                 */
/* Work    Date   : 2021-05-11 Created by Jang                                */
/* Memo           : 주문수정 - 결제내역 탭 수정 프로시저                      */
/* -------------------------------------------------------------------------- */
PROCEDURE Ord_Money_UPD_SP (
  SP_Com_ID             IN  VARCHAR2, -- NOT NULL 회사번호 (Company.Com_ID) S？ cong ty (Company.Com_ID)
  SP_Ord_NO             IN  VARCHAR2, -- NOT NULL 주문번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리) S？ th？ t？ (YYMMDD-HHMISS- + day 3 ch？ s？, t？ng s？ 17 ch？ s？)
  SP_Ins_Kind           IN  VARCHAR2, -- NOT NULL 작업구분 (INS: 추가 / UPD: 변경 / DEL: 삭제)
  SP_Kind               IN  VARCHAR2, -- NOT NULL 결제구분(Com_CD 미포함. s01~s09) 
  SP_Rcpt_Amt           IN  NUMBER, -- NOT NULL 입금금액(Ord_Rcpt.Amt)
  SP_AmtUsed            IN  NUMBER, -- NOT NULL 입금 가능한 잔액(Ord_Money.Amt - Ord_Money.Amt_Used)
  SP_Seq                IN  NUMBER, -- NOT NULL 입금순서(Ord_Money.Seq)
  SP_Money_Amt          IN  NUMBER, -- NOT NULL 입금총액(Ord_Money.Amt)
  SP_Money_No           IN  VARCHAR2, -- NOT NULL 입금번호(Ord_Money.Money_No)
  SP_Card_CD            IN  VARCHAR2, --     NULL 신용카드결제시 : 카드사코드 / 무통장송금시 : 회사 은행코드
  SP_Card_NO            IN  VARCHAR2, --     NULL 신용카드결제시 : 카드번호   / 무통장송금시 : 회사 입금계좌
  SP_Card_Holder        IN  VARCHAR2, --     NULL 신용카드결제시 : 카드소유주명
  SP_Card_YYMM          IN  VARCHAR2, --     NULL 신용카드 유효년월(YYMM)
  SP_Card_Install       IN  VARCHAR2, --     NULL 신용카드 할부개월수
  SP_Card_App_Date      IN  VARCHAR2, --     NULL 카드 승인일자
  SP_Card_App_No        IN  VARCHAR2, --     NULL 카드 승인번호
  SP_Self_YN            IN  VARCHAR2, -- NOT NULL 본인결제여부(Y/N)
  SP_Remark             IN  VARCHAR2, --     NULL 비고사항
  SP_Userid             IN  VARCHAR2, -- NOT NULL 회원번호
  SP_Work_Kind          IN  VARCHAR2, -- NOT NULL 작업경로 (W:와우넷, M:마이오피스)
  SP_Work_User          IN  VARCHAR2, -- NOT NULL 작업자번호
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, -- NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --     NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --     NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --     NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --     NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --     NULL 장치구분 (PC, PHONE, TABLET)
  SP_IP_Addr            IN  VARCHAR2, --     NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --     NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vMoney_NO             ORD_MONEY.MONEY_NO%TYPE;
  vSeq                  PLS_INTEGER;
  vCard_No              Ord_Money.Card_No%TYPE; -- 하이픈 포함 카드번호
  vRcpt_Amt             ORD_Rcpt.Amt%TYPE;
  vChk_YN               VARCHAR2(2);
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  IF SP_Log_Kind = 'MYOFFICE' THEN
    SELECT Ctr_Cd INTO vLang_CD
      FROM Member
     WHERE COM_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  ELSE
    SELECT Lang_CD INTO vLang_CD
      FROM SM_User
     WHERE COM_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  END IF; 

  ------------------------------------------------------------------------------
  -- [저장, 수정 공통 체크사항] 필수입력항목의 미입력 및 입력데이터 오류여부 등을 체크한다.
  -- [M？c ki？m tra chung đ？ l？u va s？a đ？i] Ki？m tra xem m？c ch？a đ？？c nh？p c？a h？ng m？c c？n nh？p va m？c nh？p d？ li？u co b？ l？i hay khong.
  ------------------------------------------------------------------------------
  IF Trim(SP_Com_ID) IS NULL THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회사아이디를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty
    RETURN;
  END IF;
  
  IF Trim(SP_Ord_NO) IS NULL THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문번호를 입력하시기 바랍니다.', vLang_CD);
    RETURN;
  END IF;
  
  IF Trim(SP_Ins_Kind) IS NULL THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('작업종류를 입력하시기 바랍니다.', vLang_CD);
    RETURN;
  END IF;

  IF Trim(SP_Kind) IS NULL THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('결제구분을 입력하시기 바랍니다.', vLang_CD);
    RETURN;
  END IF;

  IF Trim(SP_Userid) IS NULL THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회원번호를 입력하시기 바랍니다.', vLang_CD);
    RETURN;
  END IF;

  IF Trim(SP_Self_YN) IS NULL THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('본인결제 여부를 선택하세요.', vLang_CD);
    RETURN;
  END IF;
  

  IF SP_Ins_Kind = 'INS' THEN
    ----------------------------------------------------------------------------
    -- 결제번호를 생성한다.
    ----------------------------------------------------------------------------
    IF SP_Money_No IS NULL THEN
      vMoney_NO := TO_CHAR(SYSDATE, 'YYYYMMDD-HH24MISS') || '-';

      SELECT COUNT(1) + 1 INTO vSeq
        FROM Ord_Money
       WHERE Com_ID = SP_Com_ID
         AND Money_NO LIKE vMoney_NO || '%';
       
      vMoney_NO := vMoney_NO || LPAD(vSeq, 3, '0');
    ELSE
      vMoney_NO := SP_Money_No;
    END IF;
       
    ----------------------------------------------------------------------------
    -- 결제순번을 생성한다.
    ----------------------------------------------------------------------------
    IF SP_Seq = 0 THEN
      SELECT COUNT(1) + 1 INTO vSeq
        FROM Ord_Money
       WHERE Com_ID   = SP_Com_ID
         AND Money_NO = vMoney_NO;
    ELSE
      vSeq := SP_Seq;
    END IF;
    
    IF SP_Kind IN ('s02') THEN
    ----------------------------------------------------------------------------
    -- 카드 번호는 하이픈 생성 한다. 
    ----------------------------------------------------------------------------
      vCard_No := UFADD_HYPHEN(SP_Card_NO,'CARD',vLang_CD);
    ELSE 
      vCard_No := SP_Card_NO;
    END IF; 
    ----------------------------------------------------------------------------
    -- 결제정보를 저장한다.
    ----------------------------------------------------------------------------
    INSERT INTO Ord_Money
           ( Com_ID
           , Money_NO
           , Money_NO_Org
           , Seq
           , Userid
           , Reg_Date
           , Can_Date
           , Kind
           , Amt
           , Amt_Used
           , Amt_Balance
           , Use_YN
           , Remark
           , Card_CD
           , Card_NO
           , Card_Holder
           , Card_CMS_Rate
           , Card_Install
           , Card_YYMM
           , Card_App_NO
           , Card_App_Date
           --, Self_YN
           --, Ins_Date
           --, Ins_User
           , Upd_Date
           , Upd_User)
    VALUES ( SP_Com_ID
           , vMoney_NO
           , vMoney_NO
           , vSeq
           , SP_Userid
           , TO_CHAR(SYSDATE,'YYYYMMDD')
           , ''
           , ufCom_CD(SP_Com_ID) || SP_Kind
           , SP_Money_Amt
           , SP_Rcpt_Amt
           , SP_Money_Amt - SP_Rcpt_Amt
           , 'Y'
           , SP_Remark
           , SP_Card_CD
           , Encrypt_PKG.Enc_Card(vCard_No)
           , SP_Card_Holder
           , 0
           , SP_Card_Install
           , SP_Card_YYMM
           , SP_Card_App_No
           , SP_Card_App_Date
           --, 'Y'
           --, C1.Ins_Date
           --, C1.Ins_User
           , SYSDATE
           , SP_Work_User);

    ------------------------------------------------------------------------------
    -- 결제처리정보를 저장한다.
    ------------------------------------------------------------------------------
    INSERT INTO Ord_Rcpt
           ( Com_ID
           , Ord_NO
           , Money_NO
           , Userid
           , Amt
           , Remark
           , Work_Date
           , Work_User)
    VALUES ( SP_Com_ID
           , SP_Ord_NO
           , vMoney_NO
           , SP_Userid
           , SP_Rcpt_Amt
           , ''
           , SYSDATE
           , SP_Work_User);
    
  ELSIF SP_Ins_Kind = 'UPD' THEN
    ------------------------------------------------------------------------------
    -- 무통장, 가상계좌건만 수정이 가능.
    -- 업데이트는 사용금액이 0인 금액만 사용금액으로 처리해준다. 0이상인 경우 이미 입금이 완료된 금액이므로 수정을 하지 않음.
    ------------------------------------------------------------------------------
    IF SP_Kind NOT IN ('s03', 's04') THEN
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('무통장 또는 가상계좌건만 입금수정이 가능합니다.', vLang_CD);
      RETURN;
    END IF;
    
    SELECT Amt INTO vRcpt_Amt 
      FROM Ord_Rcpt
     WHERE Com_ID   = SP_Com_ID
       AND Ord_NO   = SP_Ord_NO
       AND Money_NO = SP_Money_No;
      
    IF vRcpt_Amt > 0 THEN
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('이미 입금금액이 있는 입금은 수정할 수 없습니다.', vLang_CD);
      RETURN;
    END IF;
    
    IF SP_Rcpt_Amt > SP_Money_Amt THEN
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('입금하실 금액이 실제 입금액보다 많습니다.', vLang_CD);
      RETURN;
    END IF;
    
    UPDATE Ord_Money
       SET AMT_USED = AMT_USED + SP_Rcpt_Amt
     WHERE Com_ID   = SP_Com_ID
       AND Money_NO = SP_Money_No
       AND Seq      = SP_Seq;
    
    UPDATE Ord_Rcpt
       SET AMT      = SP_Rcpt_Amt
     WHERE Com_ID   = SP_Com_ID
       AND Money_NO = SP_Money_No
       AND Ord_NO   = SP_Ord_NO;   
    
  ELSIF SP_Ins_Kind = 'DEL' THEN
    IF SP_Kind IN ('s02', 's05') THEN
    ----------------------------------------------------------------------------
    -- 카드형 코드는 Ord_Money 복구해주고, Rcpt 삭제.
    ----------------------------------------------------------------------------
      SELECT Amt INTO vRcpt_Amt 
        FROM Ord_Rcpt
       WHERE Com_ID   = SP_Com_ID
         AND Ord_NO   = SP_Ord_NO
         AND Money_NO = SP_Money_No;      
         
      UPDATE Ord_Money
         SET AMT_USED = AMT_USED - vRcpt_Amt
       WHERE Com_ID   = SP_Com_ID
         AND Money_NO = SP_Money_No
         AND Seq      = SP_Seq;
               
      SELECT CASE WHEN Amt < Amt_Used THEN
               'N' 
             ELSE
               'Y'
             END INTO vChk_YN 
        FROM Ord_Money
       WHERE Com_ID   = SP_Com_ID
         AND Money_NO = SP_Money_No
         AND Seq      = SP_Seq;         
         
      IF vChk_YN = 'N' THEN
        SP_RetCode := 'ERROR';
        SP_RetStr  := '[' || SP_Money_No || ']' || ufMessage('입금액과 사용금액이 상이합니다.', vLang_CD);
        RETURN;
      END IF;   
              
      DELETE FROM Ord_Rcpt
       WHERE Com_ID   = SP_Com_ID
         AND Money_NO = SP_Money_No
         AND Ord_NO   = SP_Ord_NO;
      
    ELSE
    ----------------------------------------------------------------------------
    -- 비카드형 코드는 Ord_Money 삭제, Rcpt 삭제
    ----------------------------------------------------------------------------
      DELETE FROM Ord_Rcpt
       WHERE Com_ID   = SP_Com_ID
         AND Money_NO = SP_Money_No
         AND Ord_NO   = SP_Ord_NO;
         
      
      DELETE FROM Ord_Money
       WHERE Com_ID   = SP_Com_ID
         AND Money_NO = SP_Money_No
         AND Seq      = SP_Seq;
         
    END IF;
  
  END IF;
  
 

  
  ------------------------------------------------------------------------------
  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 수정되었습니다.', vLang_CD); -- đa đ？？c s？a binh th？？ng
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  ------------------------------------------------------------------------------
  Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage('UPD', vLang_CD), '입금정보 수정');

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Money_UPD_SP [Update] - END -                         */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : Ord_DeliInfo_UPD [Update]                                 */
/* Work    Date   : 2021-05-11 Created by Jang                                */
/* Memo           : 주문수정 - 소비자/배송지 탭 수정 프로시저                 */
/* -------------------------------------------------------------------------- */
PROCEDURE Ord_DeliInfo_UPD_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID) S？ cong ty (Company.Com_ID)
  SP_Ord_NO             IN  VARCHAR2, --    NOT NULL 주문번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리) S？ th？ t？ (YYMMDD-HHMISS- + day 3 ch？ s？, t？ng s？ 17 ch？ s？)
  SP_B_Userid           IN  VARCHAR2, --        NULL 구매자 - 회원번호(Member.Userid). 소비자주문의 경우 회원번호에 NULL 처리  S？ ng？？i mua thanh vien (Member.Userid). Trong tr？？ng h？p đ？n đ？t hang c？a ng？？i tieu dung, NULL đ？？c x？ ly theo s？ thanh vien
  SP_B_Name             IN  VARCHAR2, --        NULL 구매자 - 이름 Ten ng？？i mua
  SP_B_Birthday         IN  VARCHAR2, --        NULL 구매자 - 생년월일(YYYYMMDD) Ngay sinh c？a ng？？i mua (YYYYMMDD)
  SP_B_Tel              IN  VARCHAR2, --        NULL 구매자 - 전화번호 đi？n tho？i ng？？i mua
  SP_B_Mobile           IN  VARCHAR2, --        NULL 구매자 - 이동전화 đi？n tho？i ng？？i mua
  SP_B_E_Mail           IN  VARCHAR2, --        NULL 구매자 - E-Mail 주소 đ？a ch？ email ng？？i mua
  SP_B_Post             IN  VARCHAR2, --        NULL 구매자 - 우편번호 Ma ng？？i mua
  SP_B_Addr1            IN  VARCHAR2, --        NULL 구매자 - 주소 1 đ？a ch？ ng？？i mua 1
  SP_B_Addr2            IN  VARCHAR2, --        NULL 구매자 - 주소 2 đ？a ch？ ng？？i mua 2
  SP_Deli_Kind          IN  VARCHAR2, --    NOT NULL 수령구분(T:방문수령, D:택배-회원주소지, C:택배-센터주소지[센터수령]) Phan lo？i bien nh？n (T: bien lai truy c？p, D: đ？a ch？ thanh vien chuy？n phat nhanh, C: đ？a ch？ trung tam chuy？n phat nhanh [bien nh？n trung tam])
  SP_Store_Cd           IN  VARCHAR2, --    NOT NULL 물류[출고]창고코드(Center.Cnt_CD)  H？u c？n [V？n chuy？n] Ma kho (Center.Cnt_CD)
  SP_Courier_Cd         IN  VARCHAR2, --    NOT NULL 택배업체코드(Center.Cnt_CD) Ma chuy？n phat nhanh (Center.Cnt_CD)
  SP_R_Name             IN  VARCHAR2, --        NULL 배송지 - 이름 (센터수령의 경우 센터명 + 회원명(회원번호) 기재)  G？i đ？n ten (Trong tr？？ng h？p nh？n trung tam, nh？p ten trung tam + ten thanh vien (s？ thanh vien))
  SP_R_Tel              IN  VARCHAR2, --        NULL 배송지 - 전화번호 (센터수령일 경우 전화번호는 센터 전화번호 기재) G？i đ？n s？ đi？n tho？i (N？u nh？n đ？？c trung tam, s？ đi？n tho？i la s？ đi？n tho？i trung tam)
  SP_R_Mobile           IN  VARCHAR2, --        NULL 배송지 - 이동전화 (센터수령일 경우 핸드폰번호는 회원 핸드폰번호 기재) đ？a ch？ giao hang - đi？n tho？i di đ？ng (Trong tr？？ng h？p nh？n trung tam, s？ đi？n tho？i di đ？ng la s？ đi？n tho？i di đ？ng c？a thanh vien)
  SP_R_E_Mail           IN  VARCHAR2, --        NULL 배송지 - E-Mail 주소 G？i đ？n đ？a ch？ E-mail
  SP_R_Post             IN  VARCHAR2, --        NULL 배송지 - 우편번호 G？i ma b？u đi？n
  SP_R_Addr1            IN  VARCHAR2, --        NULL 배송지 - 주소 1 G？i đ？n đ？a ch？ 1
  SP_R_Addr2            IN  VARCHAR2, --        NULL 배송지 - 주소 2 G？i đ？n đ？a ch？ 2
  SP_R_Memo             IN  VARCHAR2, --        NULL 배송메모  Ghi nh？ v？n chuy？n
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호  
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, --    NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --        NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --        NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --        NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --        NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --        NULL 장치구분 (PC, PHONE, TABLET)
  SP_IP_Addr            IN  VARCHAR2, --        NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --        NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  v                     Ord_Mst%ROWTYPE; -- 테이블 변수 Bi？n table
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  IF SP_Log_Kind = 'MYOFFICE' THEN
    SELECT Ctr_Cd INTO vLang_CD
      FROM Member
     WHERE COM_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  ELSE
    SELECT Lang_CD INTO vLang_CD
      FROM SM_User
     WHERE COM_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  END IF; 

  IF Trim(SP_Com_ID) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회사아이디를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Ord_NO) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문번호를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Deli_Kind) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('배송방법을 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;
  
  /* [20210823_이광호] 주문단계에서 물류/배송정보를 기입하지 않아 수정 불가. 
  IF Trim(SP_Store_CD) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('물류창고를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Courier_CD) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('배송업체를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;
  */

  ------------------------------------------------------------------------------
  -- 데이터를 변경한다.Thay đ？i d？ li？u
  ------------------------------------------------------------------------------
  UPDATE ORD_DELI
     SET B_Userid   = SP_B_Userid
       , B_Name     = SP_B_Name
       , B_Birthday = SP_B_Birthday
       , B_Tel      = SP_B_Tel
       , B_Mobile   = SP_B_Mobile
       , B_E_Mail   = SP_B_E_Mail
       , B_Post     = SP_B_Post
       , B_Addr1    = SP_B_Addr1
       , B_Addr2    = SP_B_Addr2
       , Deli_Kind  = SP_Deli_Kind
       , Store_Cd   = SP_Store_Cd
       , Courier_Cd = SP_Courier_Cd
       , R_Name     = SP_R_Name
       , R_Tel      = SP_R_Tel
       , R_Mobile   = SP_R_Mobile
       , R_E_Mail   = SP_R_E_Mail
       , R_Post     = SP_R_Post
       , R_Addr1    = SP_R_Addr1
       , R_Addr2    = SP_R_Addr2
       , R_Memo     = SP_R_Memo
   WHERE Com_ID     = SP_Com_ID
     AND Ord_NO     = SP_Ord_NO;
  ----------------------------------------------------------------------------
  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 수정되었습니다.', vLang_CD); -- đa đ？？c s？a binh th？？ng
  ----------------------------------------------------------------------------


  ------------------------------------------------------------------------------
  -- 주문마스터 수정일자를 변경한다.
  ------------------------------------------------------------------------------
  UPDATE ORD_MST
     SET Upd_Date = SYSDATE
       , Upd_User = SP_Work_User
   WHERE Com_ID   = SP_Com_ID
     AND Ord_NO   = SP_Ord_NO;
     
  
  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  -- log_SP : '소비자, 배송지 수정' -> ufMessage추가로 변경.
  ------------------------------------------------------------------------------
  Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage('UPD', vLang_CD), SP_Ord_NO || ' 소비자, 배송지 수정');
  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Ord_DeliInfo_UPD_SP [Update] - END -                      */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Cancel_SP [Update]                                    */
/* Work    Date   : 2021-05-21 Created by Lee                                 */
/* Memo           : 주문검색 - 주문취소 프로시저                              */
/* -------------------------------------------------------------------------- */
PROCEDURE Ord_Cancel_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID) S？ cong ty (Company.Com_ID)
  SP_Ord_NO             IN  VARCHAR2, --    NOT NULL 주문번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리) S？ th？ t？ (YYMMDD-HHMISS- + day 3 ch？ s？, t？ng s？ 17 ch？ s？)
  SP_Can_Date           IN  VARCHAR2, --        NULL 승인일자(YYYYMMDD) Ngay phe duy？t (YYYYMMDD)
  SP_Remark             IN  VARCHAR2, --        NULL 비고사항 Nh？n xet
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, --    NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --        NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --        NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --        NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --        NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --        NULL 장치구분 (PC, PHONE, TABLET)
  SP_IP_Addr            IN  VARCHAR2, --        NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --        NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vTmp                  PLS_INTEGER;
  vUserid               Ord_Mst.Userid%TYPE;
  vOrd_Date             Ord_Mst.Ord_Date%TYPE;
  vOrd_Point            Ord_Mst.Ord_Point%TYPE;
  vRcpt_Point           Ord_Mst.Rcpt_Point%TYPE;
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  IF SP_Log_Kind = 'MYOFFICE' THEN
    SELECT Ctr_Cd INTO vLang_CD
      FROM Member
     WHERE COM_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  ELSE
    SELECT Lang_CD INTO vLang_CD
      FROM SM_User
     WHERE COM_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  END IF; 

  ------------------------------------------------------------------------------
  -- 출고건 있을 경우, 주문 취소 불가.
  ------------------------------------------------------------------------------
  SELECT COUNT(1) INTO vTmp
    FROM Ord_Deli_Pdt
   WHERE (Ord_NO, Deli_Seq, Pdt_Seq, Pdt_CD)
                  IN (SELECT Ord_NO, Deli_Seq, Pdt_Seq, Pdt_CD
                        FROM Ord_Pdt
                       WHERE Ord_NO = SP_Ord_NO);
                         
  IF vTmp > 0 THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('출고지시(완료)건이 존재 합니다. 취소 하실 수 없습니다.', vLang_CD); -- 
    RETURN;
  END IF;  
  
  SELECT COUNT(1) INTO vTmp
    FROM Stk_Pdt
   WHERE (Ord_NO, Deli_Seq, Pdt_Seq)
                  IN (SELECT Ord_NO, Deli_Seq, Pdt_Seq
                        FROM Ord_Pdt
                       WHERE Ord_NO = SP_Ord_NO);
                         
  IF vTmp > 0 THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('해당 주문의 재고수량이 존재 합니다. 취소 하실 수 없습니다.', vLang_CD); -- 
    RETURN;    
  END IF; 

  ------------------------------------------------------------------------------
  -- 데이터를 변경한다.Thay đ？i d？ li？u
  ------------------------------------------------------------------------------
  UPDATE ORD_Mst
     SET Status     = 'X'
       , Can_Date   = NVL(SP_Can_Date, TO_CHAR(SYSDATE, 'YYYYMMDD'))
       , Upd_Date   = SYSDATE
       , Upd_User   = SP_Work_User
   WHERE Com_ID     = SP_Com_ID
     AND Ord_NO     = SP_Ord_NO;
     
  UPDATE Ord_Pdt
     SET Pdt_Status = 'CAN'
   WHERE Com_ID     = SP_Com_ID
     AND Ord_NO     = SP_Ord_NO;
     
  ------------------------------------------------------------------------------
  --  마지막 주문일자를 읽어서 회원정보에 반영한다.
  ------------------------------------------------------------------------------
  SELECT Ord_Point INTO vOrd_Point
    FROM Ord_Mst
   WHERE Com_Id = SP_Com_Id 
     AND Ord_No = SP_Ord_NO;
  
  SELECT Rcpt_Point INTO vRcpt_Point
    FROM Ord_Mst
   WHERE Com_Id = SP_Com_Id 
     AND Ord_No = SP_Ord_NO;
  
  SELECT Userid INTO vUserid
    FROM Ord_Mst
   WHERE Ord_NO = SP_Ord_NO;

  SELECT NVL(MAX(Ord_Date),'') INTO vOrd_Date
    FROM Ord_Mst
   WHERE Com_ID = SP_Com_ID
     AND Status <> 'X'
     AND Userid = vUserid;
   
  UPDATE Member
     SET Date_Ord = vOrd_Date
   WHERE Userid   = vUserid;  
   
   
  IF (vRcpt_Point > 0) THEN 
    INSERT INTO Mem_Point
       ( Seq
       , Com_ID
       , Reg_Date          
       , Userid    
       , Username        
       , Kind_CD
       , Kind_Name
       , Ord_No
       , Amt               
       , Remark
       , Work_User)
    VALUES(SEQ_POINT.NextVal
       , SP_Com_ID
       , NVL(SP_Can_Date, TO_CHAR(SYSDATE, 'YYYYMMDD'))        
       , vUserid            
       , UFNAME(SP_Com_ID,'USERNAME',vUserid)
       , '12'              
       , UFNAME(SP_Com_ID,'CODE','12')
       , SP_Ord_NO
       , vRcpt_Point
       , ''
       , SP_Work_User );
  END IF;  
  
  IF (vOrd_Point > 0) THEN 
    INSERT INTO Mem_Point
       ( Seq
       , Com_ID
       , Reg_Date          
       , Userid    
       , Username        
       , Kind_CD
       , Kind_Name
       , Ord_No
       , Amt               
       , Remark
       , Work_User)
    VALUES(SEQ_POINT.NextVal
       , SP_Com_ID
       , NVL(SP_Can_Date, TO_CHAR(SYSDATE, 'YYYYMMDD'))          
       , vUserid            
       , UFNAME(SP_Com_ID,'USERNAME',vUserid)
       , '22'              
       , UFNAME(SP_Com_ID,'CODE','22')
       , SP_Ord_NO
       , -vOrd_Point
       , ''
       , SP_Work_User );
  END IF; 
  ----------------------------------------------------------------------------
  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 취소되었습니다.', vLang_CD); -- đa đ？？c s？a binh th？？ng
  ----------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  -- log_SP : '소비자, 배송지 수정' -> ufMessage추가로 변경.
  ------------------------------------------------------------------------------
  Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage('UPD', vLang_CD), SP_Ord_NO || ' 주문취소');
  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Cancel_SP [Update] - END -                            */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : Ord_TurnBack_SP [Update]                                  */
/* Work    Date   : 2022-01-12 Created by Tai                                 */
/* Memo           : 주문검색 - 주문취소 프로시저                                          */
/* -------------------------------------------------------------------------- */
PROCEDURE Ord_TurnBack_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID) S？ cong ty (Company.Com_ID)
  SP_Ord_NO             IN  VARCHAR2, --    NOT NULL 주문번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리) S？ th？ t？ (YYMMDD-HHMISS- + day 3 ch？ s？, t？ng s？ 17 ch？ s？)
  SP_Can_Date           IN  VARCHAR2, --        NULL 승인일자(YYYYMMDD) Ngay phe duy？t (YYYYMMDD)
  SP_Remark             IN  VARCHAR2, --        NULL 비고사항 Nh？n xet
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, --    NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --        NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --        NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --        NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --        NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --        NULL 장치구분 (PC, PHONE, TABLET)
  SP_IP_Addr            IN  VARCHAR2, --        NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --        NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vTmp                  PLS_INTEGER;
  vUserid               Ord_Mst.Userid%TYPE;
  vOrd_Point            Ord_Mst.Ord_Point%TYPE;
  vRcpt_Point           Ord_Mst.Rcpt_Point%TYPE;
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  IF SP_Log_Kind = 'MYOFFICE' THEN
    SELECT Ctr_Cd INTO vLang_CD
      FROM Member
     WHERE COM_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  ELSE
    SELECT Lang_CD INTO vLang_CD
      FROM SM_User
     WHERE COM_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  END IF; 

  ------------------------------------------------------------------------------
  -- 데이터를 변경한다.Thay đ？i d？ li？u
  ------------------------------------------------------------------------------
  UPDATE ORD_Mst
     SET Status     = 'A'
       , Can_Date   = ''
       , Upd_Date   = SYSDATE
       , Upd_User   = SP_Work_User
   WHERE Com_ID     = SP_Com_ID
     AND Ord_NO     = SP_Ord_NO;
     
  UPDATE Ord_Pdt
     SET Pdt_Status = 'ORD'
   WHERE Com_ID     = SP_Com_ID
     AND Ord_NO     = SP_Ord_NO;
     
  ------------------------------------------------------------------------------
  --  마지막 주문일자를 읽어서 회원정보에 반영한다.
  ------------------------------------------------------------------------------
  SELECT Ord_Point INTO vOrd_Point
    FROM Ord_Mst
   WHERE Com_Id = SP_Com_Id 
     AND Ord_No = SP_Ord_NO;
  
  SELECT Rcpt_Point INTO vRcpt_Point
    FROM Ord_Mst
   WHERE Com_Id = SP_Com_Id 
     AND Ord_No = SP_Ord_NO;
  
  SELECT Userid INTO vUserid
    FROM Ord_Mst
   WHERE Ord_NO = SP_Ord_NO;  
   
  IF (vRcpt_Point > 0) THEN 
    INSERT INTO Mem_Point
       ( Seq
       , Com_ID
       , Reg_Date          
       , Userid    
       , Username        
       , Kind_CD
       , Kind_Name
       , Ord_No
       , Amt               
       , Remark
       , Work_User)
    VALUES(SEQ_POINT.NextVal
       , SP_Com_ID
       , NVL(SP_Can_Date, TO_CHAR(SYSDATE, 'YYYYMMDD'))        
       , vUserid            
       , UFNAME(SP_Com_ID,'USERNAME',vUserid)
       , '22'              
       , UFNAME(SP_Com_ID,'CODE','22')
       , SP_Ord_NO
       , -vRcpt_Point
       , ''
       , SP_Work_User );
  END IF;  
  
  IF (vOrd_Point > 0) THEN 
    INSERT INTO Mem_Point
       ( Seq
       , Com_ID
       , Reg_Date          
       , Userid    
       , Username        
       , Kind_CD
       , Kind_Name
       , Ord_No
       , Amt               
       , Remark
       , Work_User)
    VALUES(SEQ_POINT.NextVal
       , SP_Com_ID
       , NVL(SP_Can_Date, TO_CHAR(SYSDATE, 'YYYYMMDD'))          
       , vUserid            
       , UFNAME(SP_Com_ID,'USERNAME',vUserid)
       , '12'              
       , UFNAME(SP_Com_ID,'CODE','12')
       , SP_Ord_NO
       , vOrd_Point
       , ''
       , SP_Work_User );
  END IF; 
  ----------------------------------------------------------------------------
  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 취소되었습니다.', vLang_CD); -- đa đ？？c s？a binh th？？ng
  ----------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  -- log_SP : '소비자, 배송지 수정' -> ufMessage추가로 변경.
  ------------------------------------------------------------------------------
  Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage('UPD', vLang_CD), SP_Ord_NO || ' 주문취소');
  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Ord_TurnBack_SP [Update] - END -                          */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Return_SP [Insert]                                    */
/* Work    Date   : 2021-05-21 Created by Lee                                 */
/* Memo           : 주문검색 - 전체반품 프로시저                              */
/* -------------------------------------------------------------------------- */
PROCEDURE Ord_Return_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID) S？ cong ty (Company.Com_ID)
  SP_Ord_NO             IN  VARCHAR2, --    NOT NULL 주문번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리) S？ th？ t？ (YYMMDD-HHMISS- + day 3 ch？ s？, t？ng s？ 17 ch？ s？)
  SP_Acc_Date           IN  VARCHAR2, --        NULL 승인일자(YYYYMMDD) Ngay phe duy？t (YYYYMMDD)
  SP_Remark             IN  VARCHAR2, --        NULL 비고사항 Nh？n xet
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, --    NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --        NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --        NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --        NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --        NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --        NULL 장치구분 (PC, PHONE, TABLET)
  SP_IP_Addr            IN  VARCHAR2, --        NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --        NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_KeyValue           OUT VARCHAR2, -- [리턴값] 주문번호
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  v                     Ord_Mst%ROWTYPE; -- 테이블 변수 Bi？n table
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vTmp                  PLS_INTEGER;
  vUserid               Ord_Mst.Userid%TYPE;
  vOrd_Date             Ord_Mst.Ord_Date%TYPE;
  vOrd_NO               Ord_Mst.Ord_NO%TYPE;
  vMoney_NO             Ord_Money.Money_NO%TYPE;
  vOrd_Deli_Pdt         VARCHAR2(1);
  vSeq                  PLS_INTEGER;
  vStk_Kind             STK_PDT.KIND_CD%TYPE;
  vStore_CD             STK_PDT.STORE_CD%TYPE;  
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Lang_CD INTO vLang_CD
    FROM SM_User
   WHERE Userid = SP_Work_User;

  ------------------------------------------------------------------------------
  -- 주문번호 생성 (YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리) 
  ------------------------------------------------------------------------------
  vOrd_No := TO_CHAR(SYSDATE,'YYYYMMDDHHMISS') + SEQ_ORDER.nextval();
  ------------------------------------------------------------------------------
  -- ORD_MST 생성
  ------------------------------------------------------------------------------
  INSERT INTO Ord_Mst ( Com_Id
                      , Ord_No
                      , Ord_No_Org
                      , Userid
                      , Ord_Date
                      , Acc_Date
                      , Status
                      , Ctr_Cd
                      , Cnt_Cd
                      , Kind_Cd
                      , Path_Cd
                      , Proc_Cd
                      , Omni_Yn
                      , Remark 
                      , Curr_Amt
                      , Ord_Price
                      , Ord_Vat
                      , Ord_Amt
                      , Ord_Pv1
                      , Ord_Pv2
                      , Ord_Pv3
                      , Deli_No
                      , Deli_Amt
                      , Coll_Amt
                      , Total_Amt
                      , Rcpt_Yn
                      , Rcpt_Total
                      , Rcpt_Cash
                      , Rcpt_Card
                      , Rcpt_Bank
                      , Rcpt_vBank
                      , Rcpt_PrePay
                      , Rcpt_Point
                      , Rcpt_Ars
                      , Rcpt_Coin
                      , Rcpt_Etc
                      , Rcpt_Remain
                      , Tax_Invo_Yn
                      , Tax_Invo_No
                      , Tax_Invo_Date
                      , Bp_Amt_Sum
                      , Bp_Pv1_Sum
                      , Bp_Pv2_Sum
                      , Bp_Pv3_Sum
                      , Bp_Date_Cnt
                      , Bp_Amt_Day
                      , Bp_Amt_Pay
                      , Bp_Amt_Etc
                      , Bp_Refund_Date
                      , Bp_Refund_Amt
                      , Ins_Date
                      , Ins_User
                      , Upd_Date
                      , Upd_User)  
    SELECT Com_Id
         , vOrd_No
         , Ord_No AS Ord_No_Org 
         , Userid 
         , TO_CHAR(SYSDATE, 'YYYYMMDD') -- (당일건으로 생성) 
         , TO_CHAR(SYSDATE, 'YYYYMMDD') -- Acc_Date 
         , 'R'             -- Status
         , Ctr_CD          -- Ctr_Cd
         , Cnt_Cd          -- Cnt_Cd
         , Kind_CD         -- 필드 추가필요 주문구분 : [KIND_CD]
         , Path_Cd         -- Path_Cd
         , ufCom_CD(SP_Com_Id)||'J50'         -- 필드 추가필요 진행단계 : [PROC_CD]    -- 반품 / 배송완료
         , 'N'             -- Omni_YN   [소비자 주문여부 ????]      -- 
         , ''              -- Remark    [Ord_Deli_Tmp Remark 참조]  -- 정보값 필드로 받아야 함!!!!!!
         , 0               -- Curr_Amt  [환율 테이블 참조 필요] 
         , -Ord_Price     -- Ord_Price 
         , -Ord_Vat       -- Ord_Vat   
         , -Ord_Amt       -- Ord_Amt   
         , -Ord_Pv1       -- Ord_Pv1   
         , -Ord_Pv2       -- Ord_Pv2   
         , -Ord_Pv3       -- Ord_Pv3   
         , ''              -- Deli_No   
         , -Deli_Amt       -- Deli_Amt 배송비 금액 
         , 0               -- Coll_Amt 
         , -Total_Amt     -- Total_Amt (배송비 + 주문 + 기타 금액 합산)
         ---------------------------------------------------------------------------
         , 'Y'             -- Rcpt_YN 
         , -Rcpt_Total 
         , -Rcpt_Cash  
         , -Rcpt_Card
         , -Rcpt_Bank
         , -Rcpt_VBank
         , -Rcpt_PrePay
         , -Rcpt_Point
         , -Rcpt_ARS  
         , -Rcpt_Coin
         , -Rcpt_Etc
         , -Rcpt_Remain 
         , ''              -- Tax_Invo_YN 
         , ''              -- Tax_Invo_NO
         , ''              -- Tax_Invo_Date  
         , 0               -- BP_Amt_Sum
         , 0               -- BP_Pv1_Sum  
         , 0               -- BP_Pv2_Sum  
         , 0               -- BP_Pv3_Sum    
         , 0               -- BP_Date_Cnt
         , 0               -- BP_Amt_Day
         , 0               -- BP_Amt_Pay
         , 0               -- BP_Amt_Etc
         , 0               -- BP_Refund_Date
         , 0               -- BP_Refund_Amt  
         , SYSDATE         -- Ins_Date
         , SP_Work_User    -- Ins_User 
         , ''              -- Upd_Date
         , ''              -- Upd_User
      FROM Ord_Mst A
     WHERE A.Com_Id = SP_Com_Id
       AND A.Ord_No = SP_Ord_No; 

  --vError_Point := 9; 
  ------------------------------------------------------------------------------
  -- 주문 상품 저장 
  ------------------------------------------------------------------------------
  INSERT INTO Ord_Pdt( Com_Id
                     , Ord_No
                     , Ord_No_Org
                     , Pdt_Seq
                     , Userid
                     , Pdt_Cd
                     , Pdt_Option 
                     , Pdt_Kind
                     , Qty
                     , Price
                     , Vat
                     , Amt 
                     , Pv1
                     , Pv2
                     , Pv3
                     , Point
                     , Pdt_Status
                     , Serial_No
                     , Remark
                     , Work_Date
                     , Work_User 
              ) SELECT SP_Com_Id AS Com_Id
                     , vOrd_No   AS Ord_No
                     , Ord_No   AS Ord_No_Org
                     , Pdt_Seq
                     , Userid
                     , Pdt_Cd
                     , Pdt_Option
                     , Pdt_Kind
                     , Qty
                     , -Price * Qty  AS Price
                     , -Vat * Qty    AS Vat
                     , -Amt * Qty    AS Amt
                     , -Pv1 * Qty    AS Pv1
                     , -Pv2 * Qty    AS Pv2
                     , -Pv3 * Qty    AS Pv3
                     , -Point * Qty    AS Point
                     , 'RT' AS Pdt_Status
                     , Serial_No
                     , Remark
                     , SYSDATE
                     , SP_Work_User
                  FROM Ord_Pdt 
                 WHERE Com_Id = SP_Com_Id
                   AND Ord_No = SP_Ord_No; 
   
  --vError_Point := 10;
  ------------------------------------------------------------------------------
  -- 배송지 정보 저장 
  ------------------------------------------------------------------------------
  INSERT INTO Ord_Deli( Com_Id
                      , Ord_No
                      , Deli_Seq
                      , Userid 
                      , Deli_Kind
                      , Deli_Amt
                      , Store_Cd
                      , Courier_Cd
                      , Ord_Date
                      , Send_Date
                      , Send_User
                      , Remark
                      , B_Userid
                      , B_Name
                      , B_BirthDay
                      , B_Tel
                      , B_Mobile
                      , B_E_Mail
                      , B_Post
                      , B_State
                      , B_City
                      , B_County
                      , B_Addr1
                      , B_Addr2
                      , R_Name
                      , R_Tel
                      , R_Mobile
                      , R_E_Mail
                      , R_Post
                      , R_State
                      , R_City
                      , R_County
                      , R_Addr1
                      , R_Addr2
                      , R_Memo
                      , Work_Date
                      , Work_User)
                 SELECT Com_Id
                      , vOrd_No
                      , Deli_Seq
                      , Userid
                      , Deli_Kind
                      , -Deli_Amt
                      , Store_Cd
                      , Courier_Cd
                      , Ord_Date
                      , TO_CHAR(SYSDATE, 'YYYYMMDD') -- Send_Date
                      , SP_Work_User                 -- Send_User
                      , Remark
                      , Userid AS B_Userid   
                      , B_Name
                      , ''  AS B_BirthDay     
                      , B_Tel
                      , B_Mobile
                      , B_E_Mail
                      , B_Post
                      , B_State
                      , B_City
                      , B_County
                      , B_Addr1
                      , B_Addr2  
                      , R_Name
                      , R_Tel
                      , R_Mobile
                      , R_E_Mail
                      , R_Post
                      , R_State
                      , R_City
                      , R_County
                      , R_Addr1
                      , R_Addr2
                      , '' AS R_Memo      -- 필드없음  필요함.!!!!
                      , SYSDATE AS Work_Date
                      , SP_Work_User
                   FROM Ord_Deli
                  WHERE Com_Id   = SP_Com_Id
                    AND Ord_No   = SP_Ord_No
                    AND Deli_Seq = 1;  
   
  ------------------------------------------------------------------------------
  -- 환경설정에 따라 Ord_Deli_Pdt [배송상품 정보 ]생성 
  -- 직접수령 / 택배 / 센터수령 중 
  ------------------------------------------------------------------------------
  
  /*SELECT Deli_Kind INTO vDeli_Kind 
    FROM Ord_Deli
   WHERE Com_Id = SP_Com_Id
     AND Ord_No = vOrd_No;
  
  vOrd_Deli_Pdt :='N';
      
  IF (vDeli_Kind = 'TAKE') AND (vL_Ord_PP_Dir ='Y')  THEN 
    vOrd_Deli_Pdt :='Y';
  ELSIF (vDeli_Kind = 'DELI-M') AND (vL_Ord_PP_Deli ='Y') THEN
    vOrd_Deli_Pdt :='Y';
  ELSIF (vDeli_Kind = 'DELI-C') AND (vL_Ord_PP_Cnt ='Y') THEN 
   vOrd_Deli_Pdt :='Y';
  END IF;*/     
   
  vOrd_Deli_Pdt :='Y';   
  IF vOrd_Deli_Pdt ='Y' THEN 
  
    INSERT INTO Ord_Deli_Pdt( Com_Id
                            , Userid
                            , Ord_No
                            , Deli_Seq
                            , Pdt_Seq
                            , Pdt_Cd
                            , Qty 
                            , Box_Cnt
                            , Box_Rate
                            , Remark
                            , Work_Date
                            , Work_User)  
                     SELECT A.Com_Id
                          , A.Userid
                          , A.Ord_No
                          , B.Deli_Seq
                          , A.Pdt_Seq
                          , A.Pdt_Cd
                          , A.Qty
                          , 0 AS Box_Cnt
                          , C.Pdt_Box_Rate AS Box_Rate
                          , B.REMARK
                          , SYSDATE
                          , A.Work_User
                       FROM Ord_Pdt A 
                          , Ord_Deli B 
                          , Pdt_Mst C
                      WHERE A.Ord_No = B.Ord_No
                        AND A.Pdt_Cd = C.Pdt_Cd
                        AND A.Com_Id = SP_Com_Id
                        AND A.ORD_NO = vOrd_No;
  
    IF SP_Com_ID = 'MADEBYDR' THEN
      UPDATE Ord_Pdt
         SET Qty_PP = Qty
           , Qty_Stk = Qty
       WHERE Com_Id = SP_Com_Id
         AND Ord_No = vOrd_No;
         
      UPDATE Ord_Deli
         SET Send_Date = TO_CHAR(SYSDATE, 'YYYYMMDD')
           , Send_User = SP_Work_User
           , Term_Date = TO_CHAR(SYSDATE, 'YYYYMMDD')
           , Term_User = SP_Work_USer
       WHERE Com_ID = SP_Com_ID
         AND Ord_NO = vOrd_No;
         
      ----------------------------------------------------------------------------
      -- 해당 상품의 재고관리여부 및 재고차감방법을 읽는다.
      -- PDT_MST.STOCK_SUB IS '재고차감구분 (PDT 상품에서 차감 / BOM 구성품에서 차감) Kh？u tr？ t？n kho (tr？ t？ s？n ph？m PDT / kh？u tr？ t？ thanh ph？n BOM)'
      ----------------------------------------------------------------------------
      ----------------------------------------------------------------------------
      -- 재고관리를 할 경우, 자동출고 처리까지 되는 경우 
      -- 입출고테이블에 해당 정보를 저장한다.
      ----------------------------------------------------------------------------     
      FOR C1 IN (SELECT A.Ord_NO
                      , A.Pdt_Seq
                      , A.Pdt_CD
                      , A.Pdt_Status
                      , A.Qty
                      , B.Stock_Sub
                      , B.Stock_YN
                      , B.Bom_YN
                      , B.Store_CD 
                   FROM Ord_Pdt A
                      , Pdt_Mst B                    
                  WHERE A.Pdt_CD = B.Pdt_CD
                    AND A.Com_ID = SP_Com_ID
                    AND A.Ord_NO = vOrd_No
                      ) LOOP 
        
        vStk_Kind := ufName(SP_Com_ID, 'CODE.PDT_STATUS', C1.Pdt_Status);
        
        IF SP_Com_ID = 'DEMO'THEN
          vStore_CD := NVL(C1.Store_Cd, '00000');
        ELSIF SP_Com_ID = 'MADEBYDR' THEN
          vStore_CD := NVL(C1.Store_Cd, ufCom_CD(SP_Com_Id)||'004');   -- MADEBYDR : DEFAULT 06004
        ELSE
          vStore_CD := NVL(C1.Store_Cd, ufCom_CD(SP_Com_Id)||'010');  
        END IF; 
        
        IF ((C1.Stock_YN = 'Y') OR (C1.Bom_YN = 'Y')) THEN
          IF C1.Stock_Sub = 'PDT' THEN -- 상품에서 차감 
            INSERT INTO Stk_Pdt
                 ( Com_ID
                 , Reg_NO
                 , Reg_Date  
                 , Kind_CD
                 , Pdt_CD
                 , Store_CD
                 , Qty_IN
                 , Qty_Out
                 , Ord_NO
                 , Deli_Seq
                 , Pdt_Seq
                 , Remark
                 , Work_User)
            VALUES(SP_Com_ID
                 , SEQ_PK.Nextval
                 , TO_CHAR(SYSDATE, 'YYYYMMDD') -- C1.Term_Date    
                 , vStk_Kind        --'A', -- 판매출고
                 , C1.Pdt_CD
                 , vStore_CD
                 , C1.Qty -- vQty_IN
                 , 0      -- vQty_OUT     --C1.Ord_Pdt_Qty,
                 , C1.Ord_NO
                 , '1' -- C1.Deli_Seq
                 , C1.Pdt_Seq
                 , ''    --'출고등록 : ' || vDeli_NO,
                 , SP_Work_User);
          ELSIF C1.Stock_Sub = 'BOM' THEN -- 구성품에에서 차감
            -- 셋트상푼 정보를 읽는다.
            FOR C2 IN (SELECT A.Comp_CD, A.Qty
                         FROM Pdt_Bom A,
                              Pdt_Mst B
                        WHERE A.Comp_CD = B.Pdt_CD
                          AND A.Pdt_CD = C1.Pdt_CD
                          AND B.Stock_YN = 'Y') LOOP
              INSERT INTO Stk_Pdt
                   ( Com_ID
                   , Reg_NO
                   , Reg_Date  
                   , Kind_CD
                   , Pdt_CD
                   , Store_CD
                   , Qty_IN
                   , Qty_Out
                   , Ord_NO
                   , Deli_Seq
                   , Pdt_Seq
                   , Remark                 
                   , Work_User)
              VALUES(SP_Com_ID
                   , SEQ_PK.Nextval
                   , TO_CHAR(SYSDATE, 'YYYYMMDD')   -- C1.Send_Date   
                   , vStk_Kind             --'A', -- 판매출고
                   , C2.Comp_CD
                   , C1.Store_Cd  
                   , C1.Qty * C2.Qty -- vQty_IN * C2.Qty     --0,
                   , 0               --C2.Qty * C1.Ord_Pdt_Qty,
                   , C1.Ord_NO
                   , '1' -- C1.Deli_Seq
                   , C1.Pdt_Seq
                   , ''    --'출고등록 : ' || vDeli_NO,
                   , SP_Work_User);        
            END LOOP;
          END IF;
        END IF;       
      END LOOP;             
    END IF;
  END IF;
  
  ------------------------------------------------------------------------------
  -- 입금정보저장 
  ------------------------------------------------------------------------------
  /*vRcpt_Amt    := 0;

  vRcpt_Cash   := 0;
  vRcpt_Card   := 0;
  vRcpt_Bank   := 0;
  vRcpt_Vbank  := 0;
  vRcpt_Prepay := 0;
  vRcpt_Point  := 0;
  vRcpt_Ars    := 0;
  vRcpt_Coin   := 0;
  vRcpt_Etc    := 0;*/
  
  --vError_Point := 11;
  
  FOR C1 IN (SELECT A.*, B.Amt AS Real_Amt
               FROM Ord_Money A
                  , Ord_Rcpt  B
              WHERE A.Money_NO = B.Money_NO
                AND A.Com_Id   = SP_Com_Id
                AND B.Ord_No   = SP_Ord_No ) LOOP
    /*-- 현금 
    IF    C1.Kind = '0OM01' THEN  vRcpt_Cash   := vRcpt_Cash   + C1.Amt;  vAmt_Use := C1.Amt; 
    --  신용카드
    ELSIF C1.Kind = '0OM02' THEN  vRcpt_Card   := vRcpt_Card   + C1.Amt;  vAmt_Use := C1.Amt; 
    -- 무통장
    ELSIF C1.Kind = '0OM03' THEN  vRcpt_Bank   := vRcpt_Bank   + C1.Amt;  vAmt_Use := C1.Amt; 
    -- 가상계좌
    ELSIF C1.Kind = '0OM04' THEN  vRcpt_Vbank  := vRcpt_Vbank  + C1.Amt;  vAmt_Use := C1.Amt; 
    -- 선결제
    ELSIF C1.Kind = '0OM05' THEN  vRcpt_Prepay := vRcpt_Prepay + C1.Amt;  vAmt_Use := C1.Amt;
    -- 포인트
    ELSIF C1.Kind = '0OM06' THEN  vRcpt_Point  := vRcpt_Point  + C1.Amt;  vAmt_Use := C1.Amt;
    -- ARS 결제
    ELSIF C1.Kind = '0OM07' THEN  vRcpt_Ars    := vRcpt_Ars    + C1.Amt;  vAmt_Use := C1.Amt;
    -- 코인
    ELSIF C1.Kind = '0OM08' THEN  vRcpt_Coin   := vRcpt_Coin   + C1.Amt;  vAmt_Use := C1.Amt;
    -- 기타
    ELSIF C1.Kind = '0OM09' THEN  vRcpt_Etc    := vRcpt_Etc   + C1.Amt;  vAmt_Use := C1.Amt;
    
    END IF;*/ 
    
    ----------------------------------------------------------------------------
    -- vRcpt_Amt : 결제 금액 합산  비교값  
    ----------------------------------------------------------------------------
    --vRcpt_Amt := vRcpt_Amt +C1.Amt; 
    
    vMoney_NO := TO_CHAR(SYSDATE, 'YYYYMMDD-HH24MISS') || '-';

    SELECT COUNT(1) + 1 INTO vSeq
      FROM Ord_Money
     WHERE Money_NO LIKE vMoney_NO || '%';
     
    vMoney_NO := vMoney_NO || '-' || LPAD(vSeq, 3, '0');    
    
    INSERT INTO Ord_Money(Com_Id
                        , Money_No
                        , Money_No_Org
                        , Seq
                        , Userid
                        , Reg_Date
                        , Kind
                        , Amt
                        , Amt_Used
                        , Amt_Balance
                        , Use_Yn
                        , Remark 
                        , Card_Cd
                        , Card_No
                        , Card_Holder
                        , Card_Cms_Rate
                        , Card_Install 
                        , Card_YYMM
                        , Card_App_No
                        , Card_App_Date
                        , Self_Yn
                        , Ins_Date
                        , Ins_User
                        , Upd_Date
                        , Upd_User
                )Values( C1.Com_Id
                       , vMoney_NO
                       , C1.Money_No                  -- Money_No_Org
                       , C1.Seq
                       , C1.UserId
                       , TO_CHAR(SYSDATE,'YYYYMMDD') --  Reg_Date
                       , C1.Kind
                       , -C1.Real_Amt
                       , -C1.Real_Amt
                       , 0        -- Amt_Balance
                       , 'Y'                         -- Use_Yn
                       , ''                          -- Remark  필드없음. 추가필요!!!!
                       , C1.Card_Cd
                       , C1.Card_No
                       , C1.Card_Holder
                       , C1.Card_Cms_Rate            -- Card_Cms_Rate
                       , C1.Card_Install
                       , C1.Card_YYMM
                       , C1.Card_App_No
                       , C1.Card_App_Date 
                       , 'Y'                          --  Self_YN          --본인 결제여부 확인필요 
                       , SYSDATE                      -- Ins_Date
                       , SP_Work_User                 -- Ins_User
                       , SYSDATE                      -- Upd_Date
                       , SP_Work_User                 -- Upd_User
                      ); 
    ---------------------------------------------------------------------------- 
    -- Ord_Rcpt 저장 
    ----------------------------------------------------------------------------
    INSERT INTO Ord_Rcpt( Com_Id
                        , Ord_No
                        , Money_No
                        , Userid
                        , Amt
                        , Remark
                        , Work_Date
                        , Work_User
                )Values(  C1.Com_Id
                        , vOrd_No
                        , vMoney_No
                        , C1.Userid
                        , -C1.Real_Amt
                        , ''           -- Remark
                        , SYSDATE      -- Work_Date
                        , SP_Work_User -- Work_User
                );  
  END LOOP;
       
  ------------------------------------------------------------------------------
  --  마지막 주문일자를 읽어서 회원정보에 반영한다.
  ------------------------------------------------------------------------------
  SELECT Userid INTO vUserid
    FROM Ord_Mst
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO = SP_Ord_NO;

  SELECT NVL(MAX(Ord_Date),'') INTO vOrd_Date
    FROM Ord_Mst
   WHERE Com_ID = SP_Com_ID
     AND Status <> 'X'
     AND Userid = vUserid;
   
  UPDATE Member
     SET Date_Ord = vOrd_Date
   WHERE Com_ID = SP_Com_ID
     AND Userid   = vUserid;     
  ----------------------------------------------------------------------------
  SP_KeyValue := vOrd_NO;
  SP_RetCode  := 'OK';
  SP_RetStr  := ufMessage('정상적으로 저장되었습니다.', vLang_CD); -- đa đ？？c l？u binh th？？ng
  ----------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  -- log_SP : '소비자, 배송지 수정' -> ufMessage추가로 변경.
  ------------------------------------------------------------------------------
  Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage('UPD', vLang_CD), SP_Ord_NO || ' 전체반품('|| vOrd_NO || ')');
  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Return_SP [Update] - END -                            */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Del_SP [Delete]                                       */
/* Work    Date   : 2021-05-21 Created by Lee                                 */
/* Memo           : 주문검색 - 주문삭제 프로시저                              */
/* -------------------------------------------------------------------------- */
PROCEDURE Ord_Del_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID) S？ cong ty (Company.Com_ID)
  SP_Ord_NO             IN  VARCHAR2, --    NOT NULL 주문번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리) S？ th？ t？ (YYMMDD-HHMISS- + day 3 ch？ s？, t？ng s？ 17 ch？ s？)
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, --    NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --        NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --        NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --        NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --        NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --        NULL 장치구분 (PC, PHONE, TABLET)
  SP_IP_Addr            IN  VARCHAR2, --        NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --        NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vTmp                  PLS_INTEGER;
  vUserid               Ord_Mst.Userid%TYPE;
  vOrd_Date             Ord_Mst.Ord_Date%TYPE;
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Lang_CD INTO vLang_CD
    FROM SM_User
   WHERE Userid = SP_Work_User;

  ------------------------------------------------------------------------------
  -- 삭제할 주문의 회원정보 확인한다.
  ------------------------------------------------------------------------------
  SELECT Userid INTO vUserid
    FROM Ord_Mst
   WHERE Ord_NO = SP_Ord_NO;
  ------------------------------------------------------------------------------
  -- 주문삭제 불가 조건을 체크한다. 출고여부 / 입금 유형 여부
  ------------------------------------------------------------------------------
  
  ------------------------------------------------------------------------------
  -- 데이터를 변경한다.Thay đ？i d？ li？u
  ------------------------------------------------------------------------------
  FOR C1 IN (SELECT Deli_Seq, Pdt_Seq, Pdt_CD
               FROM Ord_Deli_Pdt
              WHERE Com_ID = SP_Com_ID
                AND Ord_NO = SP_Ord_NO
                   ) LOOP
    DELETE FROM Stk_Pdt      WHERE Com_ID = SP_Com_ID AND Ord_NO = SP_Ord_NO AND Deli_Seq = C1.Deli_Seq AND Pdt_Seq = C1.Pdt_Seq;                 
    DELETE FROM Ord_Deli_Pdt WHERE Com_ID = SP_Com_ID AND Ord_NO = SP_Ord_NO AND Deli_Seq = C1.Deli_Seq AND Pdt_Seq = C1.Pdt_Seq AND Pdt_CD = C1.Pdt_CD;
  END LOOP;
   
  ------------------------------------------------------------------------------
  -- 입금유형별 삭제 또는 재사용 조건을 체크한다.
  -- > 잔액이 남은 입금 유무
  -- > 다른 주문에 사용한 입금 처리
  -- > 카드 / 가상계좌 / 포인트 입금의 처리. 재사용 처리 VS 삭제
  ------------------------------------------------------------------------------
  
  ------------------------------------------------------------------------------
  -- 입금 / 입금처리 내역을 삭제한다.
  ------------------------------------------------------------------------------
  FOR C1 IN (SELECT Money_NO
               FROM Ord_Rcpt
              WHERE Com_ID = SP_Com_ID
                AND Ord_NO = SP_Ord_NO
                  ) LOOP
                  
    DELETE FROM Ord_Money WHERE Com_ID = SP_Com_ID AND Money_NO = C1.Money_NO;
    DELETE FROM Ord_Rcpt  WHERE Com_ID = SP_Com_ID AND Money_NO = C1.Money_NO AND Ord_NO = SP_Ord_NO;
  END LOOP;
  
  DELETE FROM Ord_Deli WHERE Com_ID = SP_Com_ID AND Ord_NO = SP_Ord_NO;     
  DELETE FROM Ord_Pdt  WHERE Com_ID = SP_Com_ID AND Ord_NO = SP_Ord_NO;     
  DELETE FROM Ord_Mst  WHERE Com_ID = SP_Com_ID AND Ord_NO = SP_Ord_NO;
     
  ------------------------------------------------------------------------------
  --  마지막 주문일자를 읽어서 회원정보에 반영한다.
  ------------------------------------------------------------------------------
  SELECT NVL(MAX(Ord_Date),'') INTO vOrd_Date
    FROM Ord_Mst
   WHERE Com_ID = SP_Com_ID
     AND Status <> 'X'
     AND Userid = vUserid;
   
  UPDATE Member
     SET Date_Ord = vOrd_Date
   WHERE Userid   = vUserid;     
  ----------------------------------------------------------------------------
  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 삭제되었습니다.', vLang_CD); -- đa đ？？c s？a binh th？？ng
  ----------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  -- log_SP : '소비자, 배송지 수정' -> ufMessage추가로 변경.
  ------------------------------------------------------------------------------
  Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage('DEL', vLang_CD), SP_Ord_NO || ' 주문삭제');
  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Del_SP [Delete] - END -                               */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Pdt_Tmp_SP [Insert]                                   */
/* Work    Date   : 2021-06-17 Created by Im                                  */
/* Memo           : 주문상품 임시저장 프로시저                                */
/* -------------------------------------------------------------------------- */
PROCEDURE Ord_Pdt_Tmp_SP (
  SP_Cnt                IN  NUMBER,
  SP_Com_ID             IN  VARCHAR2, -- NOT NULL 회사번호 S？ cong ty
  SP_Ord_NO             IN  VARCHAR2, --     NULL 주문번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리) S？ th？ t？ (YYMMDD-HHMISS- + day 3 ch？ s？, t？ng s？ 17 ch？ s？)
  SP_Pdt_Seq            IN  NUMBER,   -- NOT NULL 주문상품순번 đ？t mua s？n ph？m
  SP_Userid             IN  VARCHAR2, -- NOT NULL 회원번호(Member.Userid) S？ thanh vien (Member.Userid)
  SP_Pdt_CD             IN  VARCHAR2, -- NOT NULL 상품코드(Pdt_Mst.Pdt_CD) Ma s？n ph？m (Pdt_Mst.Pdt_CD)
  SP_Pdt_Option         IN  VARCHAR2, --     NULL 상품 옵션정보 Thong tin l？a ch？n s？n ph？m
  SP_Pdt_Kind           IN  VARCHAR2, -- NOT NULL 상품구분 - NOR 일반상품 / STM 세트마스터 / STD 세트구성품 / GFT 기프트증정품 Phan lo？i s？n ph？m - S？n ph？m chung c？a NOR / B？ chinh STM / Thanh ph？n b？ STD / Qua t？ng GFT
  SP_Qty                IN  NUMBER,   -- NOT NULL 수량 S？ l？？ng
  SP_Price              IN  NUMBER,   -- NOT NULL 단가 đ？n gia
  SP_Vat                IN  NUMBER,   -- NOT NULL 부가세 Thu？ VAT
  SP_Amt                IN  NUMBER,   -- NOT NULL 금액 S？ ti？n
  SP_Pv1                IN  NUMBER,   -- NOT NULL PV1
  SP_Pv2                IN  NUMBER,   -- NOT NULL PV2
  SP_Pv3                IN  NUMBER,   -- NOT NULL PV3
  SP_Point              IN  NUMBER,   -- NOT NULL 적립포인트 Thu nh？p đi？m
  SP_Pdt_Status         IN  VARCHAR2, -- NOT NULL 입출고구분(ORD:주문, C-I:교환입고, C-O:교환출고, RT:반품, CAN:취소) Phan lo？i giao nh？n va nh？n (ORD: đ？t hang, C-I: bien lai trao đ？i, C-O: giao d？ch trao đ？i, RT: tr？ l？i, CAN: h？y b？)
  SP_Serial_NO          IN  VARCHAR2, --     NULL 일련번호 S？ se-ri
  SP_Remark             IN  VARCHAR2, --     NULL 비고사항 Nh？n xet
  SP_Ord_YN             IN  VARCHAR2, --     NULL 주문가능상품(Y/N) Co th？ đ？t hang s？n ph？m hay khong (Y/N)
  SP_Deli_Seq           IN  NUMBER,   -- NOT NULL 배송순번 (다중배송 또는 하나의 주문서에 2개 이상의 박스로 배송할 경우 용도로 사용함) Th？ t？ giao hang (đ？？c s？ d？ng cho nhi？u l？n giao hang ho？c giao hang trong m？t h？p khi đ？t hang t？ 2 s？n ph？m tr？ len)
  SP_Work_User          IN  VARCHAR2, -- NOT NULL 작업자번호 ID ng？？i lam vi？c
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, -- NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --     NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --     NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --     NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --     NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --     NULL 장치구분 (PC, PHONE, TABLET)
  SP_IP_Addr            IN  VARCHAR2, --     NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --     NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Lang_CD INTO vLang_CD
    FROM SM_User
   WHERE Com_ID = SP_Com_ID
     AND Userid = SP_Work_User;

  ------------------------------------------------------------------------------
  -- [저장, 수정 공통 체크사항] 필수입력항목의 미입력 및 입력데이터 오류여부 등을 체크한다.
  -- [M？c ki？m tra chung đ？ l？u va s？a đ？i] Ki？m tra xem m？c ch？a đ？？c nh？p c？a h？ng m？c c？n nh？p va m？c nh？p d？ li？u co b？ l？i hay khong.
  ------------------------------------------------------------------------------
  IF Trim(SP_Com_ID) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회사아이디를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Ord_NO) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문번호를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Pdt_Seq) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('상품순번을 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Userid) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회원번호를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Pdt_CD) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('상품코드를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Pdt_Kind) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('상품구분을 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Pdt_Status) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('입출고구분을 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  ------------------------------------------------------------------------------
  -- 임시테이블을 삭제한다.
  ------------------------------------------------------------------------------
  IF SP_Cnt = 1 THEN
    DELETE FROM Ord_Pdt_Tmp
     WHERE Com_ID = SP_Com_ID
       AND Ord_NO = SP_Ord_NO;
  END IF;

  ------------------------------------------------------------------------------
  -- 주문상품을 저장한다.
  ------------------------------------------------------------------------------
  INSERT INTO Ord_Pdt_Tmp
         ( Com_ID
         , Ord_NO
         , Pdt_Seq
         , Userid
         , Pdt_CD
         , Pdt_Option
         , Pdt_Kind
         , Qty
         , Price
         , Vat
         , Amt
         , Pv1
         , Pv2
         , Pv3
         , Point
         , Pdt_Status
         , Serial_NO
         , Remark
         , Ord_YN
         , Deli_Seq
         , Work_Date
         , Work_User
         , Ord_NO_Tmp)
  VALUES ( SP_Com_ID
         , SP_Ord_NO
         , SP_Pdt_Seq
         , SP_Userid
         , SP_Pdt_CD
         , SP_Pdt_Option
         , SP_Pdt_Kind
         , SP_Qty
         , SP_Price
         , SP_Vat
         , SP_Amt
         , SP_Pv1
         , SP_Pv2
         , SP_Pv3
         , SP_Point
         , SP_Pdt_Status
         , SP_Serial_NO
         , SP_Remark
         , SP_Ord_YN
         , SP_Deli_Seq
         , SYSDATE
         , SP_Work_User
         , SP_Ord_NO);

  ------------------------------------------------------------------------------
  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 수정되었습니다.', vLang_CD); -- đa đ？？c s？a binh th？？ng
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  ------------------------------------------------------------------------------
  Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage('INS', vLang_CD), ufMessage('주문번호 :', vLang_CD) || ' ' || SP_Ord_NO );
  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Pdt_Tmp_SP [Insert] - END -                           */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Money_Tmp_SP [Insert]                                 */
/* Work    Date   : 2021-06-21 Created by Im                                  */
/* Memo           : 결제정보 임시저장 프로시저                                */
/* -------------------------------------------------------------------------- */
PROCEDURE Ord_Money_Tmp_SP (
  SP_Cnt                IN  NUMBER,
  SP_Com_ID             IN  VARCHAR2, -- NOT NULL 회사번호 (Company.Com_ID) S？ cong ty (Company.Com_ID)
  SP_Ord_NO             IN  NUMBER,   -- NOT NULL 임시주분번호 (SEQ_Tmp 시퀀스 사용) S？ tu？n t？m th？i (s？ d？ng chu？i SEQ_Tmp)
  SP_Seq                IN  NUMBER,   -- NOT NULL 결제순번 (SEQ_Tmp 시퀀스 사용) Th？ t？ thanh toan (SEQ_Tmp) S？ d？ng th？ t？)
  SP_Money_NO           IN  VARCHAR2, -- NOT NULL 입금번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리) S？ ti？n g？i (YYMMDD-HHMISS- + day 3 ch？ s？, t？ng s？ 17 ch？ s？)
  SP_Money_NO_Org       IN  VARCHAR2, --     NULL 원입금번호(정상입금시 Money_NO와 같은 번호가 들어간다.) S？ ti？n g？i ban đ？u (cung s？ v？i Money_NO đ？？c nh？p cho ti？n g？i thong th？？ng)
  SP_Userid             IN  VARCHAR2, -- NOT NULL 회원번호 S？ thanh vien
  SP_Kind               IN  VARCHAR2, -- NOT NULL 결제구분(Code.Code_CD) - CASH 현금 / BANK 무통장 / CARD 신용카드 / VBANK 가상계좌 / PREPAY 선결제 / POINT 포인트 / COIN 코인 / ETC 기타 Phan lo？i thanh toan (Code.Code_CD) -CASH Ti？n m？t / Ngan hang ngan hang / Th？ tin d？ng CARD / Tai kho？n ？o VBANK / Tr？ tr？？c TR？ / đi？m / COIN Coin / ETC Khac
  SP_Reg_Date           IN  VARCHAR2, -- NOT NULL 등록일자 (YYYYMMDD) Ngay đ？ng ky (YYYYMMDD)
  SP_Amt                IN  NUMBER,   -- NOT NULL 입금액 S？ ti？n ky g？i
  SP_Amt_Used           IN  NUMBER,   -- NOT NULL 사용한 금액 S？ l？？ng s？ d？ng
  SP_Remark             IN  VARCHAR2, --     NULL 비고사항 Nh？n xet
  SP_Card_CD            IN  VARCHAR2, --     NULL 신용카드결제시 : 카드사코드 / 무통장송금시 : 회사 은행코드 (Bank.Bank_CD) Thanh toan th？ tin d？ng: Ma cong ty th？ / Chuy？n kho？n ngan hang: Ma ngan hang (Bank.Bank_CD)
  SP_Card_Rate          IN  NUMBER,   --     NULL 카드수수료율 Phi th？
  SP_Card_Install       IN  NUMBER,   -- NOT NULL 신용카드 할부개월수 Thang tr？ gop th？ tin d？ng
  SP_Card_NO            IN  VARCHAR2, --     NULL 신용카드결제시 : 카드번호   / 무통장송금시 : 회사 입금계좌 Thanh toan th？ tin d？ng: S？ th？ / Chuy？n kho？n ngan hang: Tai kho？n chuy？n kho？n ngan hang
  SP_Card_Holder        IN  VARCHAR2, --     NULL 신용카드결제시 : 카드소유주명 Thanh toan b？ng th？ tin d？ng: ten ch？ th？
  SP_Card_YYMM          IN  VARCHAR2, --     NULL 신용카드 유효년월(YYMM) Ngay th？ tin d？ng co hi？u l？c (YYMM)
  SP_Card_App_NO        IN  VARCHAR2, --     NULL 승인번호 S？ phe duy？t
  SP_Card_App_Date      IN  VARCHAR2, --     NULL 승인일자(YYYYMMDD) Ngay phe duy？t (YYYYMMDD)
  SP_Work_User          IN  VARCHAR2, -- NOT NULL 작업자번호 ID ng？？i lam vi？c
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, -- NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --     NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --     NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --     NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --     NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --     NULL 장치구분 (PC, PHONE, TABLET)
  SP_IP_Addr            IN  VARCHAR2, --     NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --     NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vCard_Rate            BANK.AMT_FEE%TYPE;
  vCard_No              Ord_Money.Card_No%TYPE; -- 하이픈 포함 카드번호
  vWork_Kind            VARCHAR2(1);
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
 SELECT Work_Kind INTO vWork_Kind
    FROM Ord_Mst_Tmp
   WHERE Com_Id = SP_Com_Id
     AND Ord_No_Tmp = SP_Ord_NO;

  IF vWork_Kind = 'M' THEN
    SELECT Ctr_Cd INTO vLang_CD
      FROM Member
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User; 
  ELSE 
    SELECT Lang_CD INTO vLang_CD
      FROM SM_User
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  END IF;

  ------------------------------------------------------------------------------
  -- [저장, 수정 공통 체크사항] 필수입력항목의 미입력 및 입력데이터 오류여부 등을 체크한다.
  -- [M？c ki？m tra chung đ？ l？u va s？a đ？i] Ki？m tra xem m？c ch？a đ？？c nh？p c？a h？ng m？c c？n nh？p va m？c nh？p d？ li？u co b？ l？i hay khong.
  ------------------------------------------------------------------------------
  IF Trim(SP_Com_ID) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회사아이디를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Ord_NO) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문번호를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Seq) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('결제순번을 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Money_NO) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('입금번호를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Userid) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회원번호를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Kind) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('결제구분을 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF Trim(SP_Reg_Date) IS NULL THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('등록일을 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;
  
  IF SP_Kind IN (ufCom_CD(SP_Com_ID)||'s02') THEN
  ------------------------------------------------------------------------------
  -- 카드 번호는 하이픈 생성 한다. 
  ------------------------------------------------------------------------------
    vCard_No := UFADD_HYPHEN(SP_Card_NO,'CARD',vLang_CD);
  ELSE   
    vCard_No := SP_Card_NO;
  END IF; 
  

  ------------------------------------------------------------------------------
  -- 임시테이블을 삭제한다.
  ------------------------------------------------------------------------------
  IF SP_Cnt = 1 THEN
    DELETE FROM Ord_Money_Tmp
     WHERE Com_ID     = SP_Com_ID
       AND Ord_NO_Tmp = SP_Ord_NO;
  END IF;

  ------------------------------------------------------------------------------
  -- 카드수수료를 읽는다.
  ------------------------------------------------------------------------------
  BEGIN
    SELECT Amt_Fee INTO vCard_Rate
      FROM Bank
     WHERE Com_ID  = SP_Com_ID
       AND Bank_CD = SP_Card_CD;
  EXCEPTION
    WHEN OTHERS THEN vCard_Rate := 0;
  END;

  ------------------------------------------------------------------------------
  -- 결제정보를 저장한다.
  ------------------------------------------------------------------------------
  INSERT INTO Ord_Money_Tmp
         ( Com_ID
         , Ord_NO_Tmp
         , Seq
         , Money_NO
         , Money_NO_Org
         , Userid
         , Kind
         , Reg_Date
         , Amt
         , Amt_Used
         , Remark
         , Card_CD
         , Card_Rate
         , Card_Install
         , Card_NO
         , Card_Holder
         , Card_YYMM
         , Card_App_NO
         , Card_App_Date
         , Work_Date
         , Work_User)
  VALUES ( SP_Com_ID
         , SP_Ord_NO
         , SP_Seq
         , SP_Money_NO
         , SP_Money_NO_Org
         , SP_Userid
         , SP_Kind
         , SP_Reg_Date
         , SP_Amt
         , SP_Amt_Used
         , SP_Remark
         , SP_Card_CD
         , vCard_Rate
         , SP_Card_Install
         , vCard_No
         , SP_Card_Holder
         , SP_Card_YYMM
         , SP_Card_App_NO
         , SP_Card_App_Date
         , SYSDATE
         , SP_Work_User);

  ------------------------------------------------------------------------------
  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 수정되었습니다.', vLang_CD); -- đa đ？？c s？a binh th？？ng
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  ------------------------------------------------------------------------------
  Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage('INS', vLang_CD), ufMessage('주문번호 :', vLang_CD) || ' ' || SP_Ord_NO );
  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Money_Tmp_SP [Insert] - END -                         */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : ORD_MST_BP_SP [Insert]                                    */
/* Work    Date   : 2021-07-28 Created by Lee                                 */
/* Memo           : 주문반품 마스터 정보 저장                                 */
/* -------------------------------------------------------------------------- */
PROCEDURE ORD_MST_BP_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)
  SP_ORD_NO             IN  VARCHAR2,  --    NOT NULL 임시주문번호 (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP) S？ tu？n t？m th？i (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP)
  SP_ORD_DATE           IN  VARCHAR2, --    NOT NULL 주문일자(YYYYMMDD) Ngay đ？t hang (YYYYMMDD)
  SP_ACC_DATE           IN  VARCHAR2, --        NULL 승인일자(YYYYMMDD) Ngay phe duy？t (YYYYMMDD)  
  SP_USERID             IN  VARCHAR2, --    NOT NULL 회원번호 (Member.Userid) S？ thanh vien (Member.Userid)
  SP_CNT_CD             IN  VARCHAR2, --    NOT NULL 주문센터코드(Center.Cnt_CD) Ma trung tam đ？t hang (Center.Cnt_CD)
  SP_KIND_CD            IN  VARCHAR2, --    NOT NULL 주문유형코드(Code.Code_CD) 신규주문/재구매/오토십... Ma lo？i đ？n đ？t hang (Code.Code_CD) đ？n hang m？i / Mua l？i / T？ đ？ng ...
  SP_PATH_CD            IN  VARCHAR2, --    NOT NULL 주문경로 (Code.Code_CD) đ？？ng d？n đ？t hang (Code.Code_CD)
  SP_RCPT_TOTAL         IN  NUMBER,   --    NOT NULL 결제금액-합계 T？ng s？ ti？n thanh toan
  SP_RCPT_CASH          IN  NUMBER,   --    NOT NULL 결제금액-현금 S？ ti？n thanh toan - ti？n m？t (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_CARD          IN  NUMBER,   --    NOT NULL 결제금액-카드 S？ ti？n thanh toan - th？ (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_BANK          IN  NUMBER,   --    NOT NULL 결제금액-무통장 (환경설정에서 사용여부 설정가능)S？ ti？n thanh toan - chuy？n kho？n ngan hang (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_VBANK         IN  NUMBER,   --    NOT NULL 결제금액-가상계좌 (환경설정에서 사용여부 설정가능)S？ ti？n thanh toan - Tai kho？n ？o (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_PREPAY        IN  NUMBER,   --    NOT NULL 결제금액-선결제 (환경설정에서 사용여부 설정가능) S？ ti？n thanh toan - Tr？ tr？？c (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_POINT         IN  NUMBER,   --    NOT NULL 결제금액-포인트 (환경설정에서 사용여부 설정가능)S？ ti？n thanh toan - đi？m (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_ARS           IN  NUMBER,   --    NOT NULL 결제금액-ARS (환경설정에서 사용여부 설정가능)S？ ti？n thanh toan - ARS (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_COIN          IN  NUMBER,   --    NOT NULL 결제금액-코인 (환경설정에서 사용여부 설정가능)S？ ti？n thanh toan - Coin (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_RCPT_ETC           IN  NUMBER,   --    NOT NULL 결제금액-기타 (환경설정에서 사용여부 설정가능)S？ ti？n thanh toan - Khac (Co th？ cai đ？t tinh n？ng s？ d？ng hay khong trong cai đ？t c？u hinh)
  SP_BP_Date_Cnt        IN  NUMBER,   --             반품일수
  SP_BP_Amt_Day         IN  NUMBER,   --             기간공제금액
  SP_BP_Amt_Etc         IN  NUMBER,   --             기간공제금액 
  SP_BP_Refund_Date     IN  VARCHAR2, --             환불일자  
  SP_BP_Refund_Amt      IN  NUMBER,   --             환불금액  
  SP_REMARK             IN  VARCHAR2, --        NULL 비고사항 Nh？n xet
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호 ID ng？？i lam vi？c
  SP_Work_Kind          IN  VARCHAR2, --    NOT NULL 작업경로 W:WOWNET, M:MYOFFICE
  ------------------------------------------------------------------------------
  SP_KeyValue           OUT VARCHAR2, -- [리턴값]
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vO                    Ord_Mst%ROWTYPE; -- 테이블 변수 Bi？n table
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vTmp                  PLS_INTEGER;
  vOrd_NO               Ord_Mst.Ord_NO%TYPE;
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Lang_CD INTO vLang_CD
    FROM SM_User
   WHERE Userid = SP_Work_User;
   
  ------------------------------------------------------------------------------
  -- 주문번호 생성 (YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리) 
  ------------------------------------------------------------------------------
  vOrd_No := TO_CHAR(SYSDATE,'YYYYMMDDHHMISS') + SEQ_ORDER.nextval();
  ------------------------------------------------------------------------------
  -- ORD_MST 생성
  ------------------------------------------------------------------------------
  INSERT INTO Ord_Mst
            ( Com_Id
            , Ord_No
            , Ord_No_Org
            , Userid
            , Ord_Date
            , Acc_Date
            , Status
            , Ctr_Cd
            , Cnt_Cd
            , Kind_Cd
            , Path_Cd
            , Proc_Cd
            , Omni_Yn
            , Remark 
            , Curr_Amt
            --------------------------------------------------------------------
            , Rcpt_YN
            --------------------------------------------------------------------
            , Rcpt_Total
            , Rcpt_Cash
            , Rcpt_Card
            , Rcpt_Bank
            , Rcpt_vBank
            , Rcpt_PrePay
            , Rcpt_Point
            , Rcpt_Ars
            , Rcpt_Coin
            , Rcpt_Etc
            , Rcpt_Remain
            , Bp_Date_Cnt
            , Bp_Amt_Day
            , Bp_Amt_Pay
            , Bp_Amt_Etc
            , Bp_Refund_Date
            , Bp_Refund_Amt
            , Ins_Date
            , Ins_User
            , Upd_Date
            , Upd_User)  
     VALUES ( SP_Com_Id
            , vOrd_No
            , SP_Ord_No 
            , SP_Userid 
            , SP_Ord_Date 
            , SP_Acc_Date 
            , 'R'             -- Status
            , vLang_CD        -- vO.Ctr_CD -- Ctr_Cd
            , SP_Cnt_Cd       -- Cnt_Cd
            , SP_Kind_CD      -- 필드 추가필요 주문구분 : [KIND_CD]
            , SP_Path_Cd      -- Path_Cd
            , ufCom_CD(SP_Com_Id)||'J50'         -- 필드 추가필요 진행단계 : [PROC_CD]    -- 반품 / 배송완료
            , 'N'             -- Omni_YN   [소비자 주문여부 ????]      -- 
            , ''              -- Remark    [Ord_Deli_Tmp Remark 참조]  -- 정보값 필드로 받아야 함!!!!!!
            , 0               -- Curr_Amt  [환율 테이블 참조 필요] 
            --------------------------------------------------------------------
            , 'N'
            --------------------------------------------------------------------
            , SP_Rcpt_Total 
            , SP_Rcpt_Cash  
            , SP_Rcpt_Card
            , SP_Rcpt_Bank
            , SP_Rcpt_VBank
            , SP_Rcpt_PrePay
            , SP_Rcpt_Point
            , SP_Rcpt_ARS  
            , SP_Rcpt_Coin
            , SP_Rcpt_Etc
            , 0               -- Rcpt_Remain 
            , SP_BP_Date_Cnt
            , SP_BP_Amt_Day
            , 0               -- BP_Amt_Pay
            , SP_BP_Amt_Etc
            , SP_BP_Refund_Date
            , SP_BP_Refund_Amt  
            , SYSDATE         -- Ins_Date
            , SP_Work_User    -- Ins_User 
            , ''              -- Upd_Date
            , ''              -- Upd_User
            );  
            
  SP_KeyValue := vOrd_No;
  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 등록되었습니다.', vLang_CD);            
--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;  
END;
/* -------------------------------------------------------------------------- */
/* Package Member : ORD_MST_BP_SP [Insert] - END -                            */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Deli_BP_SP [Insert / Update]                          */
/* Work    Date   : 2021-07-28 Created by Lee                                 */
/* Memo           : 주문반품 배송 정보 저장                                   */
/* -------------------------------------------------------------------------- */
PROCEDURE Ord_Deli_BP_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)
  SP_ORD_NO             IN  VARCHAR2, --    NOT NULL 임시주문번호 (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP) S？ tu？n t？m th？i (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP)
  SP_DELI_SEQ           IN  NUMBER,   --    NOT NULL 배송순번 (다중배송 또는 하나의 주문서에 2개 이상의 박스로 배송할 경우 용도로 사용함) Th？ t？ giao hang (đ？？c s？ d？ng cho nhi？u l？n giao hang ho？c giao hang đ？n nhi？u h？p trong m？t đ？n hang)
  SP_USERID             IN  VARCHAR2, --    NOT NULL 회원번호 (Member.Userid) S？ thanh vien (Member.Userid)
  SP_DELI_KIND          IN  VARCHAR2, --    NOT NULL 배송방법(TAKE:방문수령, DELI-M:택배-회원주소지, DELI-C:택배-센터주소지[센터수령]) Ph？？ng th？c giao hang (NH？N: bien lai truy c？p, DELI-M: đ？a ch？ c？a thanh vien chuy？n phat nhanh, DELI-C: đ？a ch？ trung tam chuy？n phat nhanh [trung tam nh？n hang])
  SP_DELI_AMT           IN  NUMBER,   --    NOT NULL 배송비 Phi v？n chuy？n
  SP_STORE_CD           IN  VARCHAR2, --        NULL 물류[출고]창고코드 (Center.Cnt_CD)  H？u c？n [V？n chuy？n] Ma kho (Center.Cnt_CD)
  SP_ORD_DATE           IN  VARCHAR2, --    NOT NULL 주문일자(YYYYMMDD) Ngay đ？t hang (YYYYMMDD)
  SP_REMARK             IN  VARCHAR2, --        NULL 물류담당자(또는 3PL)에게 전달할 메시지 Tin nh？n s？ đ？？c g？i đ？n ng？？i qu？n ly h？u c？n (ho？c 3PL)
  --SP_DELI_PDT_CD      IN  VARCHAR2, --        NULL 배송비 생성 시 만들어질 배송상품 코드(PDT_MST.PDT_CD). Ma s？n ph？m v？n chuy？n s？ đ？？c t？o ra khi t？o ra phi v？n chuy？n.(PDT_MST.PDT_CD)
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호 ID ng？？i lam vi？c
  SP_Work_Kind          IN  VARCHAR2, --    NOT NULL 작업경로 W:WOWNET, M:MYOFFICE
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  v                     ORD_DELI%ROWTYPE; -- 테이블 변수 Bi？n table
  vLang_CD              VARCHAR2(2);      -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vIns_Upd              VARCHAR2(6);      -- 저장, 수정-- L？u, s？a
BEGIN  
  IF SP_Work_Kind = 'M' THEN
    SELECT Ctr_Cd INTO vLang_CD
      FROM Member
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User; 
  ELSE 
    SELECT Lang_CD INTO vLang_CD
      FROM SM_User
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  END IF;
  
  ------------------------------------------------------------------------------
  -- 데이터 체크.
  ------------------------------------------------------------------------------
  IF (NVL(Length(LTrim(SP_ORD_NO)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('배송정보의 주문번호가 없습니다. 배송정보를 확인하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  IF (NVL(Length(LTrim(SP_ORD_DATE)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('배송정보의 주문일자가  없습니다. 배송정보를 확인하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  IF (NVL(Length(LTrim(SP_DELI_KIND)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('배송방법을 선택해주세요.', vLang_CD); 
    RETURN;  
  END IF;   
  
  /*IF SP_DELI_AMT <> 0 THEN
    IF SP_DELI_PDT_CD IS NULL THEN
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('배송비 코드가 없습니다. 배송상품 코드를 확인하세요.', vLang_CD); 
      RETURN;  
    END IF;
  END IF;*/
  ------------------------------------------------------------------------------
  -- 등록된 데이터가 있는지 체크한다. (저장 또는 수정 처리용)
  -- Ki？m tra xem co d？ li？u đa đ？ng ky hay khong. (L？u ho？c x？ ly s？a đ？i)
  ------------------------------------------------------------------------------
  BEGIN
    SELECT * INTO v
      FROM Ord_Deli
     WHERE Com_ID   = SP_Com_ID
       AND Ord_NO   = SP_Ord_NO
       AND Deli_Seq = SP_Deli_Seq;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN v.Ord_NO := '-1';
  END;

  IF v.Ord_NO = '-1' THEN vIns_Upd := 'INS'; ELSE vIns_Upd := 'UPD'; END IF;
  ----------------------------------------------------------------------------
  -- 데이터를 저장한다. L？u d？ li？u
  ----------------------------------------------------------------------------
  IF vIns_Upd = 'INS' THEN
    INSERT INTO ORD_DELI
           ( COM_ID        
           , ORD_NO    
           , DELI_SEQ          
           , USERID            
           , DELI_KIND         
           , DELI_AMT          
           , STORE_CD          
           , ORD_DATE          
           , REMARK            
           --, DELI_PDT_CD
           , WORK_USER      
           )
     VALUES( SP_COM_ID        
           , SP_ORD_NO    
           , SP_DELI_SEQ          
           , SP_USERID            
           , SP_DELI_KIND         
           , SP_DELI_AMT          
           , SP_STORE_CD          
           , SP_ORD_DATE          
           , SP_REMARK            
           --, SP_DELI_PDT_CD     
           , SP_WORK_USER
           );
  ELSE
    UPDATE Ord_Deli
       SET Userid     = SP_Userid
         , Deli_Kind  = SP_Deli_Kind
         , Deli_Amt   = SP_Deli_Amt
         , Store_CD   = SP_Store_CD
         , Ord_Date   = SP_Ord_Date
         , Remark     = SP_Remark
         --, Deli_Pdt_CD= SP_Deli_Pdt_CD
         , Work_Date  = SYSDATE
         , Work_User  = SP_Work_User
     WHERE Com_ID   = SP_Com_ID
       AND Ord_NO   = SP_Ord_NO
       AND Deli_Seq = SP_Deli_Seq;
  END IF;


  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 등록되었습니다.', vLang_CD);

  COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Deli_BP_SP [Insert] - END -                           */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : ORD_PDT_INS_SP [Insert]                                   */
/* Work    Date   : 2021-07-28 Created by Lee                                 */
/* Memo           : ORD_PDT 에 직접 저장(반품상품)                            */
/* -------------------------------------------------------------------------- */
PROCEDURE ORD_PDT_INS_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)
  SP_ORD_NO             IN  VARCHAR2,   --    NOT NULL 임시주문번호 (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP) S？ tu？n t？m th？i (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP)
  SP_PDT_SEQ            IN  NUMBER,   --    NOT NULL 주문상품순번 đ？t mua s？n ph？m
  SP_USERID             IN  VARCHAR2, --    NOT NULL 회원번호(Member.Userid) S？ thanh vien (Member.Userid)
  SP_PDT_CD             IN  VARCHAR2, --    NOT NULL 상품코드(Pdt_Mst.Pdt_CD) Ma s？n ph？m (Pdt_Mst.Pdt_CD)
  SP_PDT_OPTION         IN  VARCHAR2, --        NULL 상품 옵션정보 Thong tin l？a ch？n s？n ph？m
  SP_PDT_KIND           IN  VARCHAR2, --    NOT NULL 상품구분 - NOR 일반상품 / STM 세트마스터 / STD 세트구성품 / GFT 기프트증정품 Phan lo？i s？n ph？m - S？n ph？m chung c？a NOR / B？ chinh STM / Thanh ph？n b？ STD / Qua t？ng GFT
  SP_QTY                IN  NUMBER,   --    NOT NULL 수량 S？ l？？ng
  SP_PRICE              IN  NUMBER,   --    NOT NULL 단가 đ？n gia
  SP_VAT                IN  NUMBER,   --    NOT NULL 부가세 Thu？ VAT
  SP_AMT                IN  NUMBER,   --    NOT NULL 금액 S？ ti？n
  SP_PV1                IN  NUMBER,   --    NOT NULL PV1
  SP_PV2                IN  NUMBER,   --    NOT NULL PV2
  SP_PV3                IN  NUMBER,   --    NOT NULL PV3
  SP_POINT              IN  NUMBER,   --    NOT NULL 적립포인트 Thu nh？p đi？m
  SP_PDT_STATUS         IN  VARCHAR2, --    NOT NULL 입출고구분(ORD:주문, C-I:교환입고, C-O:교환출고, RT:반품, CAN:취소) Phan lo？i giao nh？n va nh？n (ORD: đ？t hang, C-I: bien lai trao đ？i, C-O: giao d？ch trao đ？i, RT: tr？ l？i, CAN: h？y b？)
  SP_SERIAL_NO          IN  VARCHAR2, --        NULL 일련번호 S？ se-ri
  SP_REMARK             IN  VARCHAR2, --        NULL 비고사항 Nh？n xet
  SP_DELI_SEQ           IN  NUMBER,   --    NOT NULL 배송순번 (다중배송 또는 하나의 주문서에 2개 이상의 박스로 배송할 경우 용도로 사용함) Th？ t？ giao hang (đ？？c s？ d？ng cho nhi？u l？n giao hang ho？c giao hang trong m？t h？p khi đ？t hang t？ 2 s？n ph？m tr？ len)
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호 ID ng？？i lam vi？c
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  v                     ORD_PDT%ROWTYPE; -- 테이블 변수 Bi？n table
  vLang_CD              VARCHAR2(2);     -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vIns_Upd              VARCHAR2(6);     -- 저장, 수정-- L？u, s？a
  vWork_Kind            VARCHAR2(1);
  vOrd_Deli_Pdt         VARCHAR2(1);     -- 반품시 자동입고처리 여부(Y / N).
  vStk_Kind             STK_PDT.KIND_CD%TYPE;
  vStore_CD             STK_PDT.STORE_CD%TYPE;
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  --SELECT Work_Kind INTO vWork_Kind
  --  FROM Ord_Mst_Tmp
  -- WHERE Com_Id = SP_Com_Id
  --   AND Ord_No_Tmp = SP_ORD_NO;
  
  vWork_Kind := 'W';

  IF vWork_Kind = 'M' THEN
    SELECT Ctr_Cd INTO vLang_CD
      FROM Member
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User; 
  ELSE 
    SELECT Lang_CD INTO vLang_CD
      FROM SM_User
     WHERE Com_ID = SP_Com_ID
       AND Userid = SP_Work_User;
  END IF;

  ------------------------------------------------------------------------------
  -- 등록된 데이터가 있는지 체크한다. (저장 또는 수정 처리용)
  -- Ki？m tra xem co d？ li？u đa đ？ng ky hay khong. (L？u ho？c x？ ly s？a đ？i)
  ------------------------------------------------------------------------------
  IF (NVL(Length(LTrim(SP_ORD_NO)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('주문번호가 없습니다. 반품주문을 확인하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  IF (NVL(Length(LTrim(SP_PDT_CD)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('등록할 상품이 없습니다. 반품주문을 확인하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  IF SP_QTY <= 0 THEN
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('상품수량이 없습니다. 상품수량을 확인하세요.', vLang_CD); 
    RETURN;  
  END IF;
  
  IF vWork_Kind = 'W' THEN
    IF SP_AMT = 0 THEN
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('주문하실 상품금액을 확인하세요.', vLang_CD); 
      RETURN;  
    END IF;
  END IF;
  
  BEGIN
    SELECT * INTO v
      FROM ORD_PDT
     WHERE COM_ID  = SP_COM_ID
       AND ORD_NO  = SP_ORD_NO
       AND PDT_SEQ = SP_PDT_SEQ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN v.ORD_NO := '-1';
  END;
  
  v.ORD_NO := '-1';
  IF v.ORD_NO = '-1' THEN vIns_Upd := 'INS'; ELSE vIns_Upd := 'UPD'; END IF;
  
  IF vIns_Upd = 'INS' THEN
    ----------------------------------------------------------------------------
    -- 데이터를 저장한다. L？u d？ li？u
    ----------------------------------------------------------------------------
    INSERT INTO ORD_PDT
           ( Com_ID     
           , ORD_NO 
           , ORD_NO_ORG
           , PDT_SEQ    
           , USERID     
           , PDT_CD     
           , PDT_OPTION 
           , PDT_KIND   
           , QTY        
           , PRICE      
           , VAT        
           , AMT        
           , PV1        
           , PV2        
           , PV3        
           , POINT      
           , PDT_STATUS 
           , SERIAL_NO  
           , REMARK     
           , Work_User  
           )
     VALUES( SP_Com_ID     
           , SP_ORD_NO 
           , SP_ORD_NO 
           , SP_PDT_SEQ    
           , SP_USERID     
           , SP_PDT_CD     
           , SP_PDT_OPTION 
           , SP_PDT_KIND   
           , SP_QTY        
           , SP_PRICE      
           , SP_VAT        
           , SP_AMT        
           , SP_PV1        
           , SP_PV2        
           , SP_PV3        
           , SP_POINT      
           , SP_PDT_STATUS 
           , SP_SERIAL_NO  
           , SP_REMARK     
           , SP_Work_User  
           );
  ELSE
    ----------------------------------------------------------------------------
    -- 데이터를 변경한다.Thay đ？i d？ li？u
    ----------------------------------------------------------------------------
    UPDATE ORD_PDT
       SET PDT_OPTION = SP_PDT_OPTION
         , PDT_KIND   = SP_PDT_KIND
         , QTY        = SP_QTY
         , PRICE      = SP_PRICE
         , VAT        = SP_VAT
         , AMT        = SP_AMT
         , PV1        = SP_PV1
         , PV2        = SP_PV2
         , PV3        = SP_PV3
         , POINT      = SP_POINT
         , PDT_STATUS = SP_PDT_STATUS
         , SERIAL_NO  = SP_SERIAL_NO
         , REMARK     = SP_REMARK
         , Work_User  = SP_Work_User
     WHERE PDT_SEQ    = SP_PDT_SEQ
       AND ORD_NO     = SP_ORD_NO;
      
  END IF;
  
  ------------------------------------------------------------------------------
  -- 환경설정에 따라 Ord_Deli_Pdt [배송상품 정보 ]생성 
  -- 메이드바이닥터 > 반품접수 = 입고처리완료 처리 
  ------------------------------------------------------------------------------
  IF SP_Com_ID = 'MADEBYDR' THEN
    vOrd_Deli_Pdt :='Y';
  ELSE
    vOrd_Deli_Pdt :='N';
  END IF;
      
  IF vOrd_Deli_Pdt ='Y' THEN 
    ----------------------------------------------------------------------------
    -- 자동출고 처리한다.
    -- 1. 출고데이터 생성 (ORD_DELI_PDT) - 직접수령은 생성하지 않는다.
    -- 2. ORD_PDT.QTY_PP / QTY_STK 갱신
    -- 3. ORD_DELI.SEND_DATE / SEND_USER / TERM_DATE / TERM_USER 갱신
    -- 4. 상품의 출고여부에 따른 재고처리.
    ----------------------------------------------------------------------------
    INSERT INTO Ord_Deli_Pdt
                   ( Com_Id
                   , Userid
                   , Ord_No
                   , Deli_Seq
                   , Pdt_Seq
                   , Pdt_Cd
                   , Qty 
                   , Box_Cnt
                   , Box_Rate
                   , Remark
                   , Work_Date
                   , Work_User)
            VALUES ( SP_Com_ID
                   , SP_USERID
                   , SP_ORD_NO
                   , SP_DELI_SEQ
                   , SP_PDT_SEQ
                   , SP_PDT_CD
                   , SP_QTY
                   , 0
                   , 0
                   , ''
                   , SYSDATE
                   , SP_WORK_USER);
                          
    UPDATE Ord_Pdt
       SET Qty_PP = Qty
         , Qty_Stk = Qty
     WHERE Com_Id = SP_Com_Id
       AND Ord_No = SP_ORD_NO
       AND PDT_SEQ = SP_PDT_SEQ;
       
    UPDATE Ord_Deli
       SET Send_Date = TO_CHAR(SYSDATE, 'YYYYMMDD')
         , Send_User = SP_Work_User
         , Term_Date = TO_CHAR(SYSDATE, 'YYYYMMDD')
         , Term_User = SP_Work_USer
     WHERE Com_ID = SP_Com_ID
       AND Ord_NO = SP_Ord_NO;
      
    ----------------------------------------------------------------------------
    -- 해당 상품의 재고관리여부 및 재고차감방법을 읽는다.
    -- PDT_MST.STOCK_SUB IS '재고차감구분 (PDT 상품에서 차감 / BOM 구성품에서 차감) Kh？u tr？ t？n kho (tr？ t？ s？n ph？m PDT / kh？u tr？ t？ thanh ph？n BOM)'
    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    -- 재고관리를 할 경우, 자동출고 처리까지 되는 경우 
    -- 입출고테이블에 해당 정보를 저장한다.
    ----------------------------------------------------------------------------     
    FOR C1 IN (SELECT A.Ord_NO
                    , A.Pdt_Seq
                    , A.Pdt_CD
                    , A.Pdt_Status
                    , A.Qty
                    , B.Stock_Sub
                    , B.Stock_YN
                    , B.Bom_YN
                    , B.Store_CD 
                 FROM Ord_Pdt A
                    , Pdt_Mst B                    
                WHERE A.Pdt_CD = B.Pdt_CD
                  AND A.Com_ID = SP_Com_ID
                  AND A.Ord_NO = SP_Ord_NO
                    ) LOOP 
      
      vStk_Kind := ufName(SP_Com_ID, 'CODE.PDT_STATUS', C1.Pdt_Status);
      
      IF SP_Com_ID = 'DEMO'THEN
        vStore_CD := NVL(C1.Store_Cd, '00000');
      ELSE
        vStore_CD := NVL(C1.Store_Cd, ufCom_CD(SP_Com_Id)||'C10');
      END IF; 
      
      IF ((C1.Stock_YN = 'Y') OR (C1.Bom_YN = 'Y')) THEN
        IF C1.Stock_Sub = 'PDT' THEN -- 상품에서 차감 
          INSERT INTO Stk_Pdt
               ( Com_ID
               , Reg_NO
               , Reg_Date  
               , Kind_CD
               , Pdt_CD
               , Store_CD
               , Qty_IN
               , Qty_Out
               , Ord_NO
               , Deli_Seq
               , Pdt_Seq
               , Remark
               , Work_User)
          VALUES(SP_Com_ID
               , SEQ_PK.Nextval
               , TO_CHAR(SYSDATE, 'YYYYMMDD') -- C1.Term_Date    
               , vStk_Kind        --'A', -- 판매출고
               , C1.Pdt_CD
               , vStore_CD
               , C1.Qty -- vQty_IN
               , 0      -- vQty_OUT     --C1.Ord_Pdt_Qty,
               , C1.Ord_NO
               , '1' -- C1.Deli_Seq
               , C1.Pdt_Seq
               , ''    --'출고등록 : ' || vDeli_NO,
               , SP_Work_User);
        ELSIF C1.Stock_Sub = 'BOM' THEN -- 구성품에에서 차감
          -- 셋트상푼 정보를 읽는다.
          FOR C2 IN (SELECT A.Comp_CD, A.Qty
                       FROM Pdt_Bom A,
                            Pdt_Mst B
                      WHERE A.Comp_CD = B.Pdt_CD
                        AND A.Pdt_CD = C1.Pdt_CD
                        AND B.Stock_YN = 'Y') LOOP
            INSERT INTO Stk_Pdt
                 ( Com_ID
                 , Reg_NO
                 , Reg_Date  
                 , Kind_CD
                 , Pdt_CD
                 , Store_CD
                 , Qty_IN
                 , Qty_Out
                 , Ord_NO
                 , Deli_Seq
                 , Pdt_Seq
                 , Remark                 
                 , Work_User)
            VALUES(SP_Com_ID
                 , SEQ_PK.Nextval
                 , TO_CHAR(SYSDATE, 'YYYYMMDD')   -- C1.Send_Date   
                 , vStk_Kind             --'A', -- 판매출고
                 , C2.Comp_CD
                 , C1.Store_Cd  
                 , C1.Qty * C2.Qty -- vQty_IN * C2.Qty     --0,
                 , 0               --C2.Qty * C1.Ord_Pdt_Qty,
                 , C1.Ord_NO
                 , '1' -- C1.Deli_Seq
                 , C1.Pdt_Seq
                 , ''    --'출고등록 : ' || vDeli_NO,
                 , SP_Work_User);        
          END LOOP;
        END IF;
      END IF;       
    END LOOP;
  END IF;   
  
  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 등록되었습니다.', vLang_CD);

  --COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : ORD_PDT_INS_SP [Insert] - END -                           */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Money_SP [Insert, Update]                             */
/* Work    Date   : 2021-08-20 Created by LEE                                 */
/* Memo : Wownet > 반품등록[4040]                                             */
/* -------------------------------------------------------------------------- */
PROCEDURE Ord_Money_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)                                                                                      
  SP_Money_NO           IN  VARCHAR2, -- PK NOT NULL 입금번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리)
  SP_Money_NO_Org       IN  VARCHAR2, --        NULL 원입금번호(정상입금시 Money_NO와 같은 번호가 들어간다.)
  SP_Ord_NO             IN  VARCHAR2, --    NOT NULL, -- 주문번호
  SP_Userid             IN  VARCHAR2, --    NOT NULL 회원번호 (Member.Userid)
  SP_Reg_Date           IN  VARCHAR2, --    NOT NULL 등록일자(YYYYMMDD)
  SP_Can_Date           IN  VARCHAR2, --        NULL 취소일자(YYYYMMDD)    
  SP_Kind               IN  VARCHAR2, --    NOT NULL 결제구분(Code.Code_CD) - CASH 현금 / BANK 무통장 / CARD 신용카드 / VBANK 가상계좌 / PREPAY 선결제 / POINT 포인트 / ARS ARS결제 / COIN 코인 / ETC 기타
  SP_Amt                IN  NUMBER,   --    NOT NULL 입금액
  SP_Amt_Used           IN  NUMBER,   --    NOT NULL 사용한 금액
  SP_Amt_Balance        IN  NUMBER,   --    NOT NULL 미사용 잔액 
  SP_Card_CD            IN  VARCHAR2, --    NOT NULL 신용카드결제시 : 카드사코드 / 무통장송금시 : 회사 은행코드 (Bank.Bank_CD) 
  SP_Card_NO            IN  VARCHAR2, --        NULL 신용카드결제시 : 카드번호   / 무통장송금시 : 회사 입금계좌
  SP_Card_Holder        IN  VARCHAR2, --        NULL 신용카드결제시 : 카드소유주명
  SP_Card_CMS_Rate      IN  NUMBER,   --    NOT NULL 신용카드 수수료율
  SP_Card_Install       IN  NUMBER,   --    NOT NULL 신용카드 할부개월수
  SP_Card_YYMM          IN  VARCHAR2, --        NULL 신용카드 유효년월(YYMM)
  SP_Card_App_NO        IN  VARCHAR2, --        NULL 승인번호
  SP_Card_App_Date      IN  VARCHAR2, --        NULL 승인일자(YYYYMMDD)
  SP_Self_YN            IN  VARCHAR2, --    NOT NULL 본인결제여부(Y/N)
  SP_Use_YN             IN  VARCHAR2, --    NOT NULL 사용여부(Y/N)
  SP_Remark             IN  VARCHAR2, --        NULL 비고사항
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, --    NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --        NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --        NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --        NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --        NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --        NULL 장치구분 (PC, PHONE, TABLET) 
  SP_IP_Addr            IN  VARCHAR2, --        NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --        NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_KeyValue           OUT VARCHAR2, --    [리턴값] 주문번호
  SP_RetCode            OUT VARCHAR2, --    [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  --    [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  v                     Ord_Money%ROWTYPE; -- 테이블 변수 Bi？n table
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vIns_Upd              VARCHAR2(6); -- 저장, 수정-- L？u, s？a
  vCard_No              Ord_Money.Card_No%TYPE; -- 하이픈 포함 카드번호      
  vSeq                  PLS_INTEGER;
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Lang_CD INTO vLang_CD
    FROM SM_User
   WHERE Userid = SP_Work_User;
  
  ------------------------------------------------------------------------------
  -- 등록된 데이터가 있는지 체크한다. (저장 또는 수정 처리용)
  -- Ki？m tra xem co d？ li？u đa đ？ng ky hay khong. (L？u ho？c x？ ly s？a đ？i)
  ------------------------------------------------------------------------------
  BEGIN
    SELECT * INTO v
      FROM Ord_Money
     WHERE Money_NO = SP_Money_NO;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN v.Money_NO := '-1';
  END;

  IF SP_Amt = 0 THEN
    SP_RetCode := 'OK';
    SP_RetStr  := ufMessage('미처리 입금내역', vLang_CD);
    RETURN;
  END IF;
  
  IF v.Money_NO = '-1' THEN vIns_Upd := 'INS'; ELSE vIns_Upd := 'UPD'; END IF;
  -- [저장, 수정 공통 체크사항] 필수입력항목의 미입력 및 입력데이터 오류여부 등을 체크한다.
  -- [M？c ki？m tra chung đ？ l？u va s？a đ？i] Ki？m tra xem m？c ch？a đ？？c nh？p c？a h？ng m？c c？n nh？p va m？c nh？p d？ li？u co b？ l？i hay khong.
  ------------------------------------------------------------------------------
  IF (NVL(Length(LTrim(SP_Com_ID)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회사아이디를 입력하시기 바랍니다.', vLang_CD); -- Vui long nh？p ID cong ty 
    RETURN;  
  END IF;

  IF (NVL(Length(LTrim(SP_Userid)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('회원을 입력하시기 바랍니다.', vLang_CD); 
    RETURN;  
  END IF;

  IF (NVL(Length(LTrim(SP_Reg_Date)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('입금일자를 입력하시기 바랍니다.', vLang_CD); 
    RETURN;  
  END IF;

  IF (NVL(Length(LTrim(SP_Kind)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('입금구분 선택하시기 바랍니다.', vLang_CD); 
    RETURN;  
  END IF;

  IF (NVL(Length(LTrim(SP_Amt)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('입금액을 입력하시기 바랍니다.', vLang_CD); 
    RETURN;  
  END IF;

  IF (SP_Use_YN = 'N') AND (NVL(Length(LTrim(SP_Can_Date)), 0) = 0) THEN  
    SP_RetCode := 'ERROR';
    SP_RetStr  := ufMessage('사용하지 않을 경우에는 반드시 취소일자를 입력해야 합니다.', vLang_CD); 
    RETURN;  
  END IF;

  ------------------------------------------------------------------------------
  -- 카드로 결제한 경우 
  ------------------------------------------------------------------------------
  --IF (SP_Kind = 'CARD') THEN 
  IF SP_Kind IN (ufCom_CD(SP_Com_ID)||'s02') THEN 
    IF (NVL(Length(LTrim(SP_Card_CD)), 0) = 0) THEN  
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('카드사를 선택하시기 바랍니다.', vLang_CD); 
      RETURN;  
    END IF;

    IF (NVL(Length(LTrim(SP_Card_NO)), 0) = 0) THEN  
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('카드번호를 입력하시기 바랍니다.', vLang_CD); 
      RETURN;  
    END IF;

    IF (NVL(Length(LTrim(SP_Card_Holder)), 0) = 0) THEN  
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('카드소유주명을 입력하시기 바랍니다.', vLang_CD); 
      RETURN;  
    END IF;

    IF (NVL(Length(LTrim(SP_Card_Install)), 0) = 0) THEN  
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('카드 할부개월수를 입력하시기 바랍니다.', vLang_CD); 
      RETURN;  
    END IF;

    IF (NVL(Length(LTrim(SP_Card_YYMM)), 0) = 0) THEN  
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('카드 유효기간(년/월)을 입력하시기 바랍니다.', vLang_CD); 
      RETURN;  
    END IF;
  END IF;

  ------------------------------------------------------------------------------
  -- 무통장입금으로 결제한 경우 
  ------------------------------------------------------------------------------
  --IF (SP_Kind = 'BANK') THEN
  IF SP_Kind IN (ufCom_CD(SP_Com_ID)||'s03') THEN 
    IF (NVL(Length(LTrim(SP_Card_CD)), 0) = 0) THEN  
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('은행을 선택하시기 바랍니다.', vLang_CD); 
      RETURN;  
    END IF;

    IF (NVL(Length(LTrim(SP_Card_NO)), 0) = 0) THEN  
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('계좌번호를 입력하시기 바랍니다.', vLang_CD); 
      RETURN;  
    END IF;

    IF (NVL(Length(LTrim(SP_Card_Holder)), 0) = 0) THEN  
      SP_RetCode := 'ERROR';
      SP_RetStr  := ufMessage('입금자명을 입력하시기 바랍니다.', vLang_CD); 
      RETURN;  
    END IF;
    ------------------------------------------------------------------------------
    -- 계좌 번호는 하이픈을 생성하지 않는다. 
    ------------------------------------------------------------------------------
    vCard_No := SP_Card_NO;
    ------------------------------------------------------------------------------
  ELSE
    ------------------------------------------------------------------------------
    -- 카드 번호는 하이픈 생성 한다. 
    ------------------------------------------------------------------------------
    vCard_No := UFADD_HYPHEN(SP_Card_NO,'CARD',vLang_CD);
    ------------------------------------------------------------------------------
  END IF;

  ------------------------------------------------------------------------------
  -- 저장 L？u
  ------------------------------------------------------------------------------
  IF vIns_Upd = 'INS' THEN
    v.Money_NO := TO_CHAR(SYSDATE, 'YYMMDD-HHMISS-') || LPAD(SEQ_MONEY.NEXTVAL, 3, 0);
    
    ----------------------------------------------------------------------------
    -- 데이터를 저장한다. L？u d？ li？u
    ----------------------------------------------------------------------------
    INSERT INTO Ord_Money
           ( Com_ID        -- 회사번호 (Company.Com_ID)                                                                                                           
           , Money_NO      -- 입금번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리)
           , Money_NO_Org  -- 입금번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리)
           , Seq           -- SEQ 순번
           , Userid        -- 회원번호 (Member.Userid)
           , Reg_Date      -- 등록일자(YYYYMMDD)
           , Can_Date      -- 취소일자(YYYYMMDD)    
           , Kind          -- 결제구분(Code.Code_CD) - CASH 현금 / BANK 무통장 / CARD 신용카드 / VBANK 가상계좌 / PREPAY 선결제 / POINT 포인트 / ARS ARS결제 / COIN 코인 / ETC 기타
           , Amt           -- 입금액
           , Amt_Used      -- 사용한 금액
           , Amt_Balance   -- 미사용 잔액 
           , Card_CD       -- 신용카드결제시 : 카드사코드 / 무통장송금시 : 회사 은행코드 (Bank.Bank_CD) 
           , Card_NO       -- 신용카드결제시 : 카드번호   / 무통장송금시 : 회사 입금계좌
           , Card_Holder   -- 신용카드결제시 : 카드소유주명
           , Card_CMS_Rate -- 신용카드 수수료율
           , Card_Install  -- 신용카드 할부개월수
           , Card_YYMM     -- 신용카드 유효년월(YYMM)
           , Card_App_NO   -- 승인번호
           , Card_App_Date -- 승인일자(YYYYMMDD)
           , Self_YN       -- 본인결제여부(Y/N)
           , Use_YN        -- 사용여부(Y/N)
           , Remark        -- 비고사항
           , Ins_User )
    VALUES ( SP_Com_ID        
           , v.Money_NO     
           , v.Money_NO
           , 1     
           , SP_Userid       
           , SP_Reg_Date     
           , SP_Can_Date     
           , SP_Kind         
           , SP_Amt          
           , SP_Amt_Used     
           , SP_Amt_Balance  
           , SP_Card_CD      
           , Encrypt_PKG.Enc_Card(vCard_No)      
           , SP_Card_Holder  
           , SP_Card_CMS_Rate
           , SP_Card_Install 
           , SP_Card_YYMM    
           , SP_Card_App_NO  
           , SP_Card_App_Date
           , SP_Self_YN      
           , SP_Use_YN       
           , SP_Remark       
           , SP_Work_User );
           
    ------------------------------------------------------------------------------
    -- 입금처리정보를 저장한다.
    ------------------------------------------------------------------------------
    INSERT INTO ORD_RCPT
           (Com_ID,
            Ord_NO,
            Money_NO,
            Amt,
            Userid,
            Work_User)
    VALUES (SP_Com_ID,
            SP_Ord_NO,
            v.Money_NO,
            SP_Amt,
            SP_Userid,
            SP_Work_User);            
    ----------------------------------------------------------------------------
    SP_RetCode  := 'OK';
    SP_RetStr  := ufMessage('정상적으로 저장되었습니다.', vLang_CD); -- đa đ？？c l？u binh th？？ng
    SP_KeyValue := v.Money_NO;
    ----------------------------------------------------------------------------
  END IF;

  ------------------------------------------------------------------------------
  -- 수정 S？a 
  ------------------------------------------------------------------------------
  IF vIns_Upd = 'UPD' THEN
    ----------------------------------------------------------------------------
    -- 데이터를 변경한다.Thay đ？i d？ li？u
    ----------------------------------------------------------------------------
    UPDATE Ord_Money
       SET Com_ID        = SP_Com_ID         -- 회사번호 (Company.Com_ID)                                                                                                           
         , Money_NO_Org  = SP_Money_NO_Org   -- 원입금번호(정상입금시 Money_NO와 같은 번호가 들어간다.)
         , Userid        = SP_Userid         -- 회원번호 (Member.Userid)
         , Reg_Date      = SP_Reg_Date       -- 등록일자(YYYYMMDD)
         , Can_Date      = SP_Can_Date       -- 취소일자(YYYYMMDD)    
         , Kind          = SP_Kind           -- 결제구분(Code.Code_CD) - CASH 현금 / BANK 무통장 / CARD 신용카드 / VBANK 가상계좌 / PREPAY 선결제 / POINT 포인트 / ARS ARS결제 / COIN 코인 / ETC 기타
         , Amt           = SP_Amt            -- 입금액
         , Amt_Used      = SP_Amt_Used       -- 사용한 금액
         , Amt_Balance   = SP_Amt_Balance    -- 미사용 잔액 
         , Card_CD       = SP_Card_CD        -- 신용카드결제시 : 카드사코드 / 무통장송금시 : 회사 은행코드 (Bank.Bank_CD) 
         , Card_NO       = Encrypt_PKG.Enc_Card(vCard_No)        -- 신용카드결제시 : 카드번호   / 무통장송금시 : 회사 입금계좌
         , Card_Holder   = SP_Card_Holder    -- 신용카드결제시 : 카드소유주명
         , Card_CMS_Rate = SP_Card_CMS_Rate  -- 신용카드 수수료율
         , Card_Install  = SP_Card_Install   -- 신용카드 할부개월수
         , Card_YYMM     = SP_Card_YYMM      -- 신용카드 유효년월(YYMM)
         , Card_App_NO   = SP_Card_App_NO    -- 승인번호
         , Card_App_Date = SP_Card_App_Date  -- 승인일자(YYYYMMDD)
         , Self_YN       = SP_Self_YN        -- 본인결제여부(Y/N)
         , Use_YN        = SP_Use_YN         -- 사용여부(Y/N)
         , Remark        = SP_Remark         -- 비고사항                                                                                                                            
         , Upd_Date      = SYSDATE           -- 작업일자(타임스탬프)
         , Upd_User      = SP_Work_User      -- 작업자번호 
     WHERE Money_NO      = SP_Money_NO;      -- 입금번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리)

    SELECT COUNT(1) INTO vSeq 
      FROM Ord_Rcpt
     WHERE Com_ID = SP_Com_ID
       AND Ord_NO = SP_Ord_NO
       AND Money_NO = SP_Money_NO;
    ------------------------------------------------------------------------------
    -- 입금처리정보를 저장한다.
    ------------------------------------------------------------------------------
    IF vSeq = 0 THEN
      INSERT INTO ORD_RCPT
             (Com_ID,
              Ord_NO,
              Money_NO,
              Amt,
              Userid,
              Work_User)
      VALUES (SP_Com_ID,
              SP_Ord_NO,
              SP_Money_NO,
              SP_Amt,
              SP_Userid,
              SP_Work_User);
    ELSE
      UPDATE Ord_Rcpt
         SET Amt = SP_Amt
       WHERE Com_ID = SP_Com_ID
         AND Ord_NO = SP_Ord_NO
         AND Money_NO = SP_Money_NO;
    END IF;
    ----------------------------------------------------------------------------
    SP_RetCode := 'OK';
    SP_RetStr  := ufMessage('정상적으로 수정되었습니다.', vLang_CD); -- đa đ？？c s？a binh th？？ng
    ----------------------------------------------------------------------------
  END IF;

  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  ------------------------------------------------------------------------------
  --Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage(vIns_Upd, vLang_CD), ufMessage('입금번호 :', vLang_CD) || ' ' || v.Money_NO );
  --COMMIT;

--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Ord_Money_SP [Insert, Update] - END -                     */
/* -------------------------------------------------------------------------- */









/* -------------------------------------------------------------------------- */
/* Package Member : ORD_BP_CHK_SP [Insert / Update / Delete]                  */
/* Work    Date   : 2021-07-28 Created by Lee                                 */
/* Memo           : 주문반품 체크프로시져(+오류시 반품데이터 삭제)            */
/* -------------------------------------------------------------------------- */
PROCEDURE ORD_BP_CHK_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)
  SP_ORD_NO             IN  VARCHAR2,   --    NOT NULL 임시주문번호 (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP) S？ tu？n t？m th？i (ORD_MST_TMP.ORD_NO_TMP, ORD_PDT_TMP_FK_ORD_NO_TMP)
  SP_InCode             IN  VARCHAR2, --    NOT NULL (OK 반품등록 성공시 체크+처리, ERR 반품등록 실패시 처리(데이터 삭제))    
  SP_InStr              IN  VARCHAR2, --    NOT NULL (OK 반품등록 성공시 메시지, ERR 반품등록 실패시  메시지 -> 그대로 리턴 메시지)    
  SP_REMARK             IN  VARCHAR2, --        NULL 물류담당자(또는 3PL)에게 전달할 메시지 Tin nh？n s？ đ？？c g？i đ？n ng？？i qu？n ly h？u c？n (ho？c 3PL)
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호 ID ng？？i lam vi？c
  SP_Work_Kind          IN  VARCHAR2, --    NOT NULL 작업경로 W:WOWNET, M:MYOFFICE
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vTmp                  PLS_INTEGER;
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vO                    ORD_MST%ROWTYPE;
  vUsername             MEMBER.Username%TYPE;
  vMobile               MEMBER.Mobile%TYPE;
  vCnt                  PLS_INTEGER;
  vStock_Sub            Pdt_Mst.Stock_Sub%TYPE;
  vStock_YN             Pdt_Mst.Stock_YN%TYPE;
  vBom_YN               Pdt_Mst.BOM_YN%TYPE;
  vDeli_Seq             Stk_Pdt.Deli_Seq%TYPE;
  vStore_CD             Ord_Deli.Store_CD%TYPE;
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Lang_CD INTO vLang_CD
    FROM SM_User
   WHERE Userid = SP_Work_User;
  vTmp := 0;
  
  ------------------------------------------------------------------------------
  --   반품 상품 체크.
  ------------------------------------------------------------------------------
  SELECT COUNT(1) INTO vTmp
    FROM Ord_Pdt 
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO = SP_Ord_NO;
   
  IF (vTmp = 0) THEN   --  AND (SP_Classify <> 'VBANK')
    SP_RetCode := '0';
    SP_RetStr  := ufMessage('반품상품정보가 등록되지 않았습니다.', vLang_CD);
    RETURN;
  END IF;
  
  SELECT COUNT(1) INTO vTmp
    FROM Ord_Pdt 
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO = SP_Ord_NO
     AND Qty = 0;
   
  IF( vTmp >= 1) THEN
    SP_RetCode := '0';
    SP_RetStr  := ufMessage('수량이 0인 상품이 등록 되었습니다.', vLang_CD);
    RETURN;
  END IF;
  
  SELECT * INTO vO
    FROM Ord_Mst
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO = SP_Ord_NO;
          
  SELECT Deli_Seq, NVL(Store_CD,'-') INTO vDeli_Seq, vStore_CD
    FROM Ord_Deli
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO = SP_Ord_NO;
     
  IF vStore_CD = '-' THEN
    SP_RetCode := '0';
    SP_RetStr  := ufMessage('원주문 확인 바랍니다.(미출고주문)', vLang_CD);
    RETURN;
  END IF;
     
  -----------------------------------------------------------------------------
  -- 자동주문에 대한 반품인경우, 자동주문 취소 처리.
  -----------------------------------------------------------------------------
  --IF NVL(vO.ADO_NO, '-') <> '-' THEN
  --  UPDATE ADO_Mst
  --     SET Status = 'END'    -- 0 철회, 1 정상, 2 종료, 3 해지
  --   WHERE Com_ID = SP_Com_ID
  --     AND ADO_NO = vO.ADO_NO;
  --END IF;     
      
  UPDATE Ord_Mst A
     SET Ord_Price = (SELECT SUM(QTY*Price) FROM Ord_Pdt WHERE Com_ID = SP_Com_ID AND Ord_NO = A.Ord_NO) - BP_Amt_Day - BP_Amt_Etc
       , Ord_Vat   = (SELECT SUM(QTY*Vat  ) FROM Ord_Pdt WHERE Com_ID = SP_Com_ID AND Ord_NO = A.Ord_NO)
       , Ord_Amt   = (SELECT SUM(QTY*Amt  ) FROM Ord_Pdt WHERE Com_ID = SP_Com_ID AND Ord_NO = A.Ord_NO) - BP_Amt_Day - BP_Amt_Etc
       , Ord_PV1   = (SELECT SUM(QTY*PV1  ) FROM Ord_Pdt WHERE Com_ID = SP_Com_ID AND Ord_NO = A.Ord_NO)
       , Ord_PV2   = (SELECT SUM(QTY*PV2  ) FROM Ord_Pdt WHERE Com_ID = SP_Com_ID AND Ord_NO = A.Ord_NO)
       , Ord_PV3   = (SELECT SUM(QTY*PV3  ) FROM Ord_Pdt WHERE Com_ID = SP_Com_ID AND Ord_NO = A.Ord_NO)
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO = SP_Ord_NO;
     
  UPDATE Ord_Mst
     SET Rcpt_YN = 'Y'
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO = SP_Ord_NO
     AND Ord_Amt = Rcpt_Total;
  
  -----------------------------------------------------------------------------
  -- 반품주문에 대한 알림톡 (환불완료(반품))
  -- SEND_KAKAO_AT_SP(COM_ID, USERNAME, MOBILE, ORD_NO, '15');
  -----------------------------------------------------------------------------
  IF SP_Com_ID = 'MADEBYDR' THEN
    SELECT Username, Mobile INTO vUsername, vMobile
      FROM Member
     WHERE Userid = vO.Userid;
   
    KAKAOTALK.SEND_KAKAO_AT_SP(SP_Com_ID, vUsername, vMobile, SP_Ord_NO, '15');
  END IF;
  
  -----------------------------------------------------------------------------
  -- 반품주문에 대한 재고처리.
  -- 반품입고 상품만 재고처리 한다. 반품출고건은 출고지시 등록통해 처리.
  -----------------------------------------------------------------------------
  SELECT COUNT(1) INTO vCnt
    FROM Stk_Pdt
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO = SP_Ord_NO;
     
  IF vCnt = 0 THEN
    FOR C1 IN (SELECT Ord_NO, Pdt_CD, Pdt_Seq, Pdt_Status, Qty, DECODE(Pdt_Status, 'C-I', ufCom_CD(Com_ID) || 'L12', 'RT', ufCom_CD(Com_ID) || 'L13') AS Stk_Kind
                 FROM Ord_Pdt
                WHERE Com_ID = SP_Com_ID
                  AND Ord_NO = SP_Ord_NO
                  AND Pdt_Status IN ('C-I', 'RT')
                  ) LOOP
        ----------------------------------------------------------------------------
        -- 해당 상품의 재고관리여부 및 재고차감방법을 읽는다.
        -- PDT_MST.STOCK_SUB IS '재고차감구분 (PDT 상품에서 차감 / BOM 구성품에서 차감) Kh？u tr？ t？n kho (tr？ t？ s？n ph？m PDT / kh？u tr？ t？ thanh ph？n BOM)'
        ----------------------------------------------------------------------------
        SELECT Stock_Sub, Stock_YN, Bom_YN INTO vStock_Sub, vStock_YN, vBom_YN
          FROM Pdt_Mst
         WHERE Com_ID = SP_Com_ID
           AND Pdt_CD = C1.Pdt_CD;
        ----------------------------------------------------------------------------
        -- 재고관리를 할 경우, 자동출고 처리까지 되는 경우 
        -- 입출고테이블에 해당 정보를 저장한다.
        ----------------------------------------------------------------------------
        IF ((vStock_YN = 'Y') OR (vBom_YN = 'Y')) THEN
          IF vStock_Sub = 'PDT' THEN -- 상품에서 차감 
            INSERT INTO Stk_Pdt
                 ( Com_ID
                 , Reg_NO
                 , Reg_Date  
                 , Kind_CD
                 , Pdt_CD
                 , Store_CD
                 , Qty_IN
                 , Qty_Out
                 , Ord_NO
                 , Deli_Seq
                 , Pdt_Seq
                 , Remark
                 , Work_User)
            VALUES(SP_Com_ID
                 , SEQ_PK.Nextval
                 , vO.Ord_Date
                 , C1.Stk_Kind        --'A', -- 판매출고
                 , C1.Pdt_CD
                 , vStore_CD
                 , C1.Qty  -- Qty_IN
                 , 0 -- vQty_OUT     --C1.Ord_Pdt_Qty,
                 , C1.Ord_NO
                 , vDeli_Seq
                 , C1.Pdt_Seq
                 , ''    --'출고등록 : ' || vDeli_NO,
                 , SP_Work_User);
          ELSIF vStock_Sub = 'BOM' THEN -- 구성품에에서 차감
            -- 셋트상푼 정보를 읽는다.
            FOR C2 IN (SELECT A.Comp_CD, A.Qty
                         FROM Pdt_Bom A,
                              Pdt_Mst B
                        WHERE B.Com_ID  = SP_Com_ID
                          AND A.Comp_CD = B.Pdt_CD
                          AND A.Pdt_CD = C1.Pdt_CD
                          AND B.Stock_YN = 'Y') LOOP
              INSERT INTO Stk_Pdt
                   ( Com_ID
                   , Reg_NO
                   , Reg_Date  
                   , Kind_CD
                   , Pdt_CD
                   , Store_CD
                   , Qty_IN
                   , Qty_Out
                   , Ord_NO
                   , Deli_Seq
                   , Pdt_Seq
                   , Remark                 
                   , Work_User)
              VALUES(SP_Com_ID
                   , SEQ_PK.Nextval
                   , vO.Ord_Date
                   , C1.Stk_Kind             --'A', -- 판매출고
                   , C2.Comp_CD
                   , vStore_CD
                   , C1.Qty * C2.Qty     --0,
                   , 0 -- vQty_Out * C2.Qty    --C2.Qty * C1.Ord_Pdt_Qty,
                   , C1.Ord_NO
                   , vDeli_Seq
                   , C1.Pdt_Seq
                   , ''    --'출고등록 : ' || vDeli_NO,
                   , SP_Work_User);        
            END LOOP;
          END IF;
        END IF;
        
        UPDATE Ord_Pdt
           SET Qty_PP = Qty
             , Qty_Stk = Qty
         WHERE Com_ID = SP_Com_ID
           AND Ord_NO = SP_Ord_NO;
    END LOOP;  
  END IF;
  ----------------------------------------------------------------------------
  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 저장되었습니다.', vLang_CD); -- đa đ？？c l？u binh th？？ng
  ----------------------------------------------------------------------------  
END;
/* -------------------------------------------------------------------------- */
/* Package Member : ORD_BP_CHK_SP [Insert / Update / Delete] - END -          */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : ORD_IMPORT_SP [Insert]                                    */
/* Work    Date   : 2021-10-28 Created by Lee                                 */
/* Memo           : 주문엑셀 업로드 프로시져(임시데이터 생성)                 */
/* -------------------------------------------------------------------------- */
PROCEDURE ORD_IMPORT_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)                                                                                      
  SP_SEQ_NO             IN  NUMBER,   -- ORD_IMPORT.SEQ_NO        %TYPE,
  SP_XLS_NO             IN  VARCHAR2, -- ORD_IMPORT.XLS_NO        %TYPE,
  SP_USERID             IN  VARCHAR2, -- ORD_IMPORT.USERID        %TYPE,
  SP_USERNAME           IN  VARCHAR2, -- ORD_IMPORT.USERNAME      %TYPE,
  SP_ORD_DATE           IN  VARCHAR2, -- ORD_IMPORT.ORD_DATE      %TYPE,
  SP_PDT_CD             IN  VARCHAR2, -- ORD_IMPORT.PDT_CD        %TYPE,
  SP_PDT_NAME           IN  VARCHAR2, -- ORD_IMPORT.PDT_NAME      %TYPE,
  SP_QTY                IN  NUMBER,   -- ORD_IMPORT.QTY           %TYPE,
  SP_MONEY_KIND         IN  VARCHAR2, -- ORD_IMPORT.MONEY_KIND    %TYPE,
  SP_DELI_KINDS         IN  VARCHAR2, -- ORD_IMPORT.DELI_KINDS    %TYPE,
  SP_R_NAME             IN  VARCHAR2, -- ORD_IMPORT.R_NAME        %TYPE,
  SP_R_TEL              IN  VARCHAR2, -- ORD_IMPORT.R_TEL         %TYPE,
  SP_R_MOBILE           IN  VARCHAR2, -- ORD_IMPORT.R_MOBILE      %TYPE,
  SP_R_POST             IN  VARCHAR2, -- ORD_IMPORT.R_POST        %TYPE,
  SP_R_ADDR1            IN  VARCHAR2, -- ORD_IMPORT.R_ADDR1       %TYPE,
  SP_R_ADDR2            IN  VARCHAR2, -- ORD_IMPORT.R_ADDR2       %TYPE,
  SP_R_MEMO             IN  VARCHAR2, -- ORD_IMPORT.R_MEMO        %TYPE,
  SP_RCPT_TOTAL         IN  NUMBER,   -- ORD_IMPORT.RCPT_TOTAL    %TYPE,
  SP_INS_USER           IN  VARCHAR2, -- ORD_IMPORT.INS_USER      %TYPE,
  SP_RetCode            OUT VARCHAR2,
  SP_RetStr             OUT VARCHAR2
)
IS
  vTmp                  PLS_INTEGER;
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vORD_NO               ORD_IMPORT.ORD_NO%TYPE;
  vPDT_CD               ORD_IMPORT.PDT_CD%TYPE;
  vREMARK               ORD_IMPORT.REMARK%TYPE;
  vOrd_Date             VARCHAR2(10);
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Lang_CD INTO vLang_CD
    FROM SM_User
   WHERE Userid = SP_INS_USER;
   
  vOrd_Date := REPLACE(SP_Ord_Date, '-','');
  
  -- 중복된자료 확인
  SELECT COUNT(1), MAX(ORD_NO), MAX(PDT_CD) INTO vTmp, vORD_NO, vPDT_CD
    FROM ORD_IMPORT
   WHERE COM_ID   = SP_COM_ID
     AND ORD_DATE = vORD_DATE
     AND SEQ_NO   = SP_SEQ_NO
     AND PDT_CD   = SP_PDT_CD;

  IF vTmp > 0 THEN
    vREMARK  := '중복된 자료(' || SP_Ord_Date ||'-'|| SP_SEQ_NO ||'-'|| vPDT_CD || ')';
  ELSE 
    vREMARK  := '';
  END IF;
  
  SELECT COUNT(1) INTO vTmp
    FROM Member
   WHERE Userid = SP_USERID;
   
  IF vTmp = 0 THEN
    vREMARK  := '미확인 회원번호(' || SP_Ord_Date ||'-'|| SP_SEQ_NO ||'-'|| SP_USERID || ')';  
  END IF;
  
  SELECT COUNT(1) INTO vTmp
    FROM Pdt_Mst
   WHERE Pdt_CD = SP_Pdt_CD;
   
  IF vTmp = 0 THEN
    vREMARK  := '미확인 번호(' || SP_Ord_Date ||'-'|| SP_SEQ_NO ||'-'|| SP_USERID || ')';  
  END IF;

  ------------------------------------------------------------------------------
  -- 주문마스터를 저장한다.
  ------------------------------------------------------------------------------
  INSERT INTO ORD_IMPORT
       ( COM_ID
       , SEQ_NO
       , XLS_NO
       , USERID
       , USERNAME
       , ORD_DATE
       , MONEY_KIND
       , DELI_KINDS
       , PDT_CD
       , PDT_NAME
       , QTY
       , R_NAME
       , R_TEL
       , R_MOBILE
       , R_POST
       , R_ADDR1
       , R_ADDR2
       , R_MEMO
       , RCPT_TOTAL
       , REMARK
       , INS_DATE
       , INS_USER)
  VALUES(SP_COM_ID
       , SP_SEQ_NO
       , SP_XLS_NO
       , SP_USERID
       , SP_USERNAME
       , SP_ORD_DATE
       , SP_MONEY_KIND
       , SP_DELI_KINDS
       , SP_PDT_CD
       , SP_PDT_NAME
       , ABS(SP_QTY)
       , SP_R_NAME
       , SP_R_TEL
       , SP_R_MOBILE
       , SP_R_POST
       , SP_R_ADDR1
       , SP_R_ADDR2
       , SUBSTR(Replace(SP_R_MEMO,chr(10),' '),   1,360)
       , SP_RCPT_TOTAL
       , vREMARK
       , SYSDATE
       , SP_INS_USER);
   
  SP_RetCode  := 'OK';
  SP_RetStr   := ufMessage('주문마스터 저장완료', vLang_CD);
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : ORD_IMPORT_SP [Insert] - END -                            */
/* -------------------------------------------------------------------------- */










/* -------------------------------------------------------------------------- */
/* Package Member : ORD_IMPORT_DO_SP [Insert]                                 */
/* Work    Date   : 2021-10-28 Created by Lee                                 */
/* Memo           : 주문엑셀 업로드 프로시져(실제주문데이터 생성)             */
/* -------------------------------------------------------------------------- */
PROCEDURE ORD_IMPORT_DO_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)                                                                                      
  SP_SEQ_NO             IN  NUMBER,   -- ORD_IMPORT.SEQ_NO        %TYPE,
  SP_INS_USER           IN  VARCHAR2, -- ORD_IMPORT.INS_USER      %TYPE,
  SP_RetCode            OUT VARCHAR2,
  SP_RetStr             OUT VARCHAR2
)
IS
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vOrd                  ORD_MST%ROWTYPE;
  vDel                  ORD_Deli%ROWTYPE;
  vCNT                  PLS_INTEGER;
  vCNT_CD               VARCHAR2(5);
  vRcpt_Cash            NUMBER; 
  vRcpt_Bank            NUMBER;
  vRcpt_Card            NUMBER;
  vRcpt_Point           NUMBER;
  vRcpt_Etc             NUMBER;
  vORD_TOT              NUMBER;
  vPrice                NUMBER;
  vVat                  NUMBER;
  vAmt                  NUMBER;
  vPV1                  NUMBER;
  vPV2                  NUMBER;
  vPV3                  NUMBER;
  vRank_CD              MEMBER.Rank_CD%TYPE;  
  vTmp                  PLS_INTEGER;
  vOrd_NO               ORD_PDT.Ord_NO%TYPE;
  vPdt_Seq              ORD_PDT.Pdt_Seq%TYPE;
  vUSERID               MEMBER.USERID%TYPE;
  vREMARK               ORD_IMPORT.REMARK%TYPE;
  vKeyValue             VARCHAR2(20);
  vRetCode              VARCHAR2(20);
  vRetStr               VARCHAR2(200);
  vStore_CD             ORD_DELI.Store_CD%TYPE;
  vCourier_CD           ORD_DELI.Courier_CD%TYPE;  
  vError_Point          NUMBER;
BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Lang_CD INTO vLang_CD
    FROM SM_User
   WHERE Userid = SP_INS_USER;

  ------------------------------------------------------------------------------
  -- 주문마스터를 저장한다.
  ------------------------------------------------------------------------------
  FOR C1 IN (SELECT XLS_NO
                  , ''             AS Ord_NO
                  , ORD_DATE
                  , ORD_DATE       AS Acc_Date
                  , Userid
                  , 'B'            AS KIND_CD   -- B2B 주문
                  , 'B'            AS PATH_CD
                  , MAX(MONEY_KIND) AS MONEY_KIND
                  , MAX(R_NAME    ) AS R_NAME  
                  , MAX(R_TEL     ) AS R_TEL   
                  , MAX(R_MOBILE  ) AS R_MOBILE
                  , MAX(R_POST    ) AS R_POST  
                  , MAX(R_ADDR1   ) AS R_ADDR1  
                  , MAX(R_ADDR2   ) AS R_ADDR2  
                  , MAX(R_MEMO    ) AS R_MEMO
               FROM ORD_IMPORT
              WHERE COM_ID  = SP_COM_ID
                AND SEQ_NO  = SP_SEQ_NO
                AND ORD_NO IS NULL
              GROUP BY Xls_NO, Ord_Date, Userid
              ORDER BY ORD_DATE, XLS_NO) LOOP
              
    SELECT RANK_CD, Cnt_CD INTO vRank_CD, vCnt_CD
      FROM Member
     WHERE Userid = C1.Userid;
     
    vRcpt_Cash  := 0; 
    vRcpt_Bank  := 0;
    vRcpt_Card  := 0;
    vRcpt_Point := 0;
    vRcpt_Etc   := 0;     
    --==========================================================================
    -- 주문 자료를 처리 한다,
    ----------------------------------------------------------------------------
    IF    C1.MONEY_Kind = 'E01'         Then vRcpt_Cash := 1;
    ELSIF C1.MONEY_Kind IN('E02','E08') Then vRcpt_Bank := 1;
    ELSIF C1.MONEY_Kind IN('E03','E07') Then vRcpt_Card := 1;
    ELSE                                     vRcpt_Etc  := 1;
    END IF;
    ------------------------------------------------------------------------------
    -- 주문번호 생성 (YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리) 
    ------------------------------------------------------------------------------
    vOrd_No := TO_CHAR(SYSDATE,'YYYYMMDDHHMISS') + SEQ_ORDER.nextval();

    ------------------------------------------------------------------------------
    -- ORD_MST 생성
    ------------------------------------------------------------------------------
    INSERT INTO Ord_Mst 
              ( Com_Id
              , Ord_No
              , Ord_No_Org
              , Userid
              , Ord_Date
              , Acc_Date
              , Status
              , Ctr_Cd
              , Cnt_Cd
              , Kind_Cd
              , Path_Cd
              , Proc_Cd
              , Omni_Yn
              , Remark 
              , Curr_Amt
              , Deli_No
              , Deli_Amt
              , Coll_Amt
              , Rcpt_Yn
              , Ins_Date
              , Ins_User
              , Upd_Date
              , Upd_User)
       VALUES ( SP_Com_Id
              , vOrd_No
              , vOrd_No
              , C1.Userid
              , REPLACE(C1.Ord_Date, '-', '')
              , REPLACE(C1.Acc_Date, '-', '')
              , 'A'  -- Status
              , 'KR' -- Ctr_Cd
              , vCnt_Cd
              , ufCom_CD(SP_Com_Id)||'O01'  -- Kind_Cd
              , ufCom_CD(SP_Com_Id)||'T40'  -- Path_Cd
              , ufCom_CD(SP_Com_Id)||'J20'  -- Proc_Cd
              , 'N' -- Omni_Yn
              , '' -- Remark 
              , 0  -- Curr_Amt
              , '' -- Deli_No
              , 0  -- Deli_Amt
              , 0  -- Coll_Amt
              , 'N' -- Rcpt_Yn
              , SYSDATE -- Ins_Date
              , SP_INS_USER
              , SYSDATE
              , SP_INS_USER);  

    ------------------------------------------------------------------------------
    -- 배송지 정보 저장 
    ------------------------------------------------------------------------------
    vCourier_CD := '';
    BEGIN
      SELECT MIN(Cnt_CD) INTO vStore_CD
        FROM Center
       WHERE Com_ID = SP_Com_ID
         AND Kind_CD = ufCom_CD(SP_Com_Id)||'C10';
    EXCEPTION
      WHEN OTHERS THEN
        vStore_CD := '';    
    END;
       
    INSERT INTO Ord_Deli
              ( Com_Id
              , Ord_No
              , Deli_Seq
              , Userid 
              , Deli_Kind
              , Deli_Amt
              , Store_Cd
              , Courier_Cd
              , Ord_Date
              , Send_Date
              , Send_User
              , Remark
              , B_Userid
              , B_Name
              , B_BirthDay
              , B_Tel
              , B_Mobile
              , B_E_Mail
              , B_Post
              , B_State
              , B_City
              , B_County
              , B_Addr1
              , B_Addr2
              , R_Name
              , R_Tel
              , R_Mobile
              , R_E_Mail
              , R_Post
              , R_State
              , R_City
              , R_County
              , R_Addr1
              , R_Addr2
              , R_Memo
              , Work_Date
              , Work_User)
       VALUES ( SP_Com_Id
              , vOrd_No
              , 1 -- Deli_Seq
              , C1.Userid 
              , 'DELI-M' -- Deli_Kind(DELI-M 택배(회원주소), DELI-T 방문수령,  DELI-C 택배(센터수령)
              , 0  -- Deli_Amt
              , vStore_Cd
              , vCourier_Cd
              , REPLACE(C1.Ord_Date, '-', '')
              , '' -- Send_Date
              , '' -- Send_User
              , '' -- Remark
              , '' -- B_Userid
              , '' -- B_Name
              , '' -- B_BirthDay
              , '' -- B_Tel
              , '' -- B_Mobile
              , '' -- B_E_Mail
              , '' -- B_Post
              , '' -- B_State
              , '' -- B_City
              , '' -- B_County
              , '' -- B_Addr1
              , '' -- B_Addr2
              , C1.R_Name
              , C1.R_Tel
              , C1.R_Mobile
              , '' -- C1.R_E_Mail
              , C1.R_Post
              , '' -- C1.R_State
              , '' -- C1.R_City
              , '' -- C1.R_County
              , C1.R_Addr1
              , C1.R_Addr2
              , C1.R_Memo
              , SYSDATE
              , SP_Ins_User);

    ----------------------------------------------------------------------------
    -- 주문상품을 저장한다.
    ----------------------------------------------------------------------------
    vPdt_Seq := 0;
    FOR C2 IN (SELECT QTY  
                    , PDT_CD
                    , PDT_NAME
                    , 'ORD' AS Pdt_Status
                 FROM ORD_IMPORT
                WHERE COM_ID     = SP_COM_ID
                  AND SEQ_NO     = SP_SEQ_NO
                  AND ORD_DATE   = C1.ORD_DATE
                  AND XLS_NO     = C1.XLS_NO
                  ) LOOP

      ------------------------------------------------------------------------------
      -- 주문상품을 저장한다.
      ------------------------------------------------------------------------------
      BEGIN
        SELECT A.PRICE, A.VAT, A.AMT, A.PV1, A.PV2, A.PV3
          INTO  vPrice,  vVat,  vAmt,  vPV1,  vPV2,  vPV3
          FROM PDT_AMT A
             , (SELECT PDT_CD, MAX(REG_DATE) AS REG_DATE
                  FROM PDT_AMT
                 WHERE REG_DATE <= TO_CHAR(TO_DATE(C1.Ord_Date,'YYYYMMDD'),'YYYYMMDD')
                   AND Pdt_CD = C2.Pdt_CD
                 GROUP BY PDT_CD
               ) B
         WHERE A.REG_DATE = B.REG_DATE
           AND A.PDT_CD   = B.PDT_CD;
      EXCEPTION
        WHEN OTHERS THEN
          SP_RETCODE := '0';
          SP_RETSTR  := C2.Pdt_CD || ' 상품 직급금액 등록 확인!!!';
          --ROLLBACK;  -- 와우넷에서 롤백처리. 
          RETURN;  
      END;
        
      SELECT COUNT(1) INTO vTmp 
        FROM Ord_Pdt
       WHERE Ord_NO = vOrd_NO
         AND Pdt_CD = C2.Pdt_CD;
           
      IF vTmp = 0 THEN
        vPdt_Seq := vPdt_Seq + 1;   
        INSERT INTO ORD_PDT
              (Com_ID
             , Ord_NO
             , Ord_NO_Org
             , Pdt_Seq
             , Userid
             , Pdt_CD
             , Pdt_Option
             , PDT_KIND
             , Qty
             , Price
             , Vat
             , Amt
             , Pv1
             , Pv2
             , Pv3
             , Pdt_Status
             , Remark)
        VALUES (SP_Com_ID
             , vOrd_NO
             , vOrd_NO
             , vPdt_Seq
             , C1.Userid
             , C2.PDT_CD
             , ''
             , '1'
             , C2.Qty
             , vPrice                          -- Price
             , vVat               -- Ord_Vat
             , vAmt                                -- Ord_Amt
             , vPV1                               -- Ord_Pv
             , vPV2                               -- Ord_Pv
             , vPV3                               -- Ord_Pv
             , '1'                                            -- IO_Kind
             , '');            -- Remark
      ELSE
        SELECT Pdt_Seq INTO vPdt_Seq 
          FROM Ord_Pdt
         WHERE Ord_NO = vOrd_NO
           AND Pdt_CD = C2.Pdt_CD;      
      
        UPDATE Ord_Pdt
           SET Qty = Qty + C2.Qty
         WHERE Ord_NO = vOrd_NO
           AND Pdt_Seq = vPdt_Seq;
      END IF;
    END LOOP;
      
    IF (vRcpt_Card = 1) THEN
      UPDATE Ord_Mst A
         SET Ord_Price  = (SELECT SUM(QTY*PRICE) FROM ORD_PDT WHERE ORD_NO = A.ORD_NO)
           , Ord_Vat    = (SELECT SUM(QTY*VAT  ) FROM ORD_PDT WHERE ORD_NO = A.ORD_NO)
           , Ord_Amt    = (SELECT SUM(QTY*AMT  ) FROM ORD_PDT WHERE ORD_NO = A.ORD_NO)
           , Ord_PV1    = (SELECT SUM(QTY*PV1  ) FROM ORD_PDT WHERE ORD_NO = A.ORD_NO)
           , Ord_PV2    = (SELECT SUM(QTY*PV2  ) FROM ORD_PDT WHERE ORD_NO = A.ORD_NO)
           , Ord_PV3    = (SELECT SUM(QTY*PV3  ) FROM ORD_PDT WHERE ORD_NO = A.ORD_NO)
           , Rcpt_Total = (SELECT SUM(QTY*AMT  ) FROM ORD_PDT WHERE ORD_NO = A.ORD_NO)
           , Rcpt_YN    = 'Y'
       WHERE Ord_NO = vOrd_NO;
    ELSE
      UPDATE Ord_Mst A
         SET Ord_Price  = (SELECT SUM(QTY*PRICE) FROM ORD_PDT WHERE ORD_NO = A.ORD_NO)
           , Ord_Vat    = (SELECT SUM(QTY*VAT  ) FROM ORD_PDT WHERE ORD_NO = A.ORD_NO)
           , Ord_Amt    = (SELECT SUM(QTY*AMT  ) FROM ORD_PDT WHERE ORD_NO = A.ORD_NO)
           , Ord_PV1    = (SELECT SUM(QTY*PV1  ) FROM ORD_PDT WHERE ORD_NO = A.ORD_NO)
           , Ord_PV2    = (SELECT SUM(QTY*PV2  ) FROM ORD_PDT WHERE ORD_NO = A.ORD_NO)
           , Ord_PV3    = (SELECT SUM(QTY*PV3  ) FROM ORD_PDT WHERE ORD_NO = A.ORD_NO)
           , Rcpt_Total = 0
           , Rcpt_YN    = 'N'
       WHERE Ord_NO = vOrd_NO;
    END IF;


    UPDATE ORD_IMPORT
       SET ORD_NO    = vOrd_NO
         , REMARK    = vREMARK 
     WHERE COM_ID    = SP_COM_ID
       AND SEQ_NO    = SP_SEQ_NO
       AND ORD_DATE  = C1.ORD_DATE
       AND XLS_NO    = C1.XLS_NO;
  END LOOP;
     
  SP_RetCode  := 'OK';
  SP_RetStr   := ufMessage('주문자료 등록이 완료되었습니다.', vLang_CD);

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END; 
/* -------------------------------------------------------------------------- */
/* Package Member : ORD_IMPORT_DO_SP [Insert] - END -                         */
/* -------------------------------------------------------------------------- */






/* -------------------------------------------------------------------------- */
/* Package Member : ORD_Money_CHK_SP [Update]                                 */
/* Work    Date   : 2021-11-08 Created by LKH                                 */
/* Memo           : 주문수정 체크프로시져                                     */
/* -------------------------------------------------------------------------- */
PROCEDURE ORD_Money_CHK_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)
  SP_ORD_NO             IN  VARCHAR2,   --    NOT NULL 주문번호
  SP_Work_User          IN  VARCHAR2, --    NOT NULL 작업자번호 ID ng？？i lam vi？c
  SP_Work_Kind          IN  VARCHAR2, --    NOT NULL 작업경로 W:WOWNET, M:MYOFFICE
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vTmp                  PLS_INTEGER;
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
  vO                    ORD_MST%ROWTYPE;  
  vRcpt_Amt             ORD_RCPT.AMT%TYPE;
  vRcpt_Total           ORD_MST.RCPT_TOTAL%TYPE;
  vRcpt_Cash            ORD_MST.RCPT_CASH%TYPE;
  vRcpt_Card            ORD_MST.RCPT_CARD%TYPE;
  vRcpt_Bank            ORD_MST.RCPT_BANK%TYPE;
  vRcpt_VBank           ORD_MST.RCPT_VBANK%TYPE;
  vRcpt_Prepay          ORD_MST.RCPT_PREPAY%TYPE;
  vRcpt_Point           ORD_MST.RCPT_POINT%TYPE;
  vRcpt_ARS             ORD_MST.RCPT_ARS%TYPE;
  vRcpt_Coin            ORD_MST.RCPT_COIN%TYPE;
  vRcpt_ETC             ORD_MST.RCPT_ETC%TYPE;
  vRcpt_Remain          ORD_MST.RCPT_REMAIN%TYPE;

BEGIN
  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  SELECT Lang_CD INTO vLang_CD
    FROM SM_User
   WHERE Userid = SP_Work_User;
  
  ------------------------------------------------------------------------------
  -- Ord_Rcpt와 Ord_Mst의 금액 체크.
  ------------------------------------------------------------------------------
  SELECT SUM(AMT) INTO vRcpt_Amt
    FROM Ord_Rcpt 
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO = SP_Ord_NO;
  
  SELECT * INTO vO
    FROM Ord_Mst
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO = SP_Ord_NO;
  
  IF vO.Rcpt_YN = 'Y' THEN   --  AND (SP_Classify <> 'VBANK')
    SP_RetCode := '0';
    SP_RetStr  := ufMessage('이미 입금이 완료된 주문입니다.', vLang_CD);
    RETURN;
  END IF;
  
  IF vRcpt_Amt <> vO.Total_Amt THEN
    SP_RetCode := '0';
    SP_RetStr  := ufMessage('주문금액과 입금금액이 상이합니다.', vLang_CD);
    RETURN;
  END IF;
  
  SELECT NVL(SUM(B.Amt), 0) INTO vRcpt_Cash
    FROM Ord_Money A, Ord_Rcpt B
   WHERE A.Com_ID = SP_Com_ID
     AND A.Money_NO = B.Money_NO
     AND A.Kind = ufCom_cd(A.Com_ID) || 's01'
     AND B.Ord_NO = SP_Ord_NO;
     
  SELECT NVL(SUM(B.Amt), 0) INTO vRcpt_Card
    FROM Ord_Money A, Ord_Rcpt B
   WHERE A.Com_ID = SP_Com_ID
     AND A.Money_NO = B.Money_NO
     AND A.Kind = ufCom_cd(A.Com_ID) || 's02'
     AND B.Ord_NO = SP_Ord_NO;
     
  SELECT NVL(SUM(B.Amt), 0) INTO vRcpt_Bank
    FROM Ord_Money A, Ord_Rcpt B
   WHERE A.Com_ID = SP_Com_ID
     AND A.Money_NO = B.Money_NO
     AND A.Kind = ufCom_cd(A.Com_ID) || 's03'
     AND B.Ord_NO = SP_Ord_NO;
     
  SELECT NVL(SUM(B.Amt), 0) INTO vRcpt_VBank
    FROM Ord_Money A, Ord_Rcpt B
   WHERE A.Com_ID = SP_Com_ID
     AND A.Money_NO = B.Money_NO
     AND A.Kind = ufCom_cd(A.Com_ID) || 's04'
     AND B.Ord_NO = SP_Ord_NO;
 
  SELECT NVL(SUM(B.Amt), 0) INTO vRcpt_Prepay
    FROM Ord_Money A, Ord_Rcpt B
   WHERE A.Com_ID = SP_Com_ID
     AND A.Money_NO = B.Money_NO
     AND A.Kind = ufCom_cd(A.Com_ID) || 's05'
     AND B.Ord_NO = SP_Ord_NO;
     
  SELECT NVL(SUM(B.Amt), 0) INTO vRcpt_Point
    FROM Ord_Money A, Ord_Rcpt B
   WHERE A.Com_ID = SP_Com_ID
     AND A.Money_NO = B.Money_NO
     AND A.Kind = ufCom_cd(A.Com_ID) || 's06'
     AND B.Ord_NO = SP_Ord_NO;
     
  SELECT NVL(SUM(B.Amt), 0) INTO vRcpt_ARS
    FROM Ord_Money A, Ord_Rcpt B
   WHERE A.Com_ID = SP_Com_ID
     AND A.Money_NO = B.Money_NO
     AND A.Kind = ufCom_cd(A.Com_ID) || 's07'
     AND B.Ord_NO = SP_Ord_NO;
     
  SELECT NVL(SUM(B.Amt), 0) INTO vRcpt_Coin
    FROM Ord_Money A, Ord_Rcpt B
   WHERE A.Com_ID = SP_Com_ID
     AND A.Money_NO = B.Money_NO
     AND A.Kind = ufCom_cd(A.Com_ID) || 's08'
     AND B.Ord_NO = SP_Ord_NO;
     
  SELECT NVL(SUM(B.Amt), 0) INTO vRcpt_ETC
    FROM Ord_Money A, Ord_Rcpt B
   WHERE A.Com_ID = SP_Com_ID
     AND A.Money_NO = B.Money_NO
     AND A.Kind = ufCom_cd(A.Com_ID) || 's09'
     AND B.Ord_NO = SP_Ord_NO;
     
  vRcpt_Total := vRcpt_Cash + vRcpt_Card + vRcpt_Bank + vRcpt_VBank + vRcpt_Prepay + vRcpt_Point + vRcpt_ARS + vRcpt_Coin + vRcpt_ETC;
      
  UPDATE Ord_Mst A
     SET RCPT_TOTAL  = vRcpt_Total
       , RCPT_CASH   = vRcpt_Cash
       , RCPT_CARD   = vRcpt_Card
       , RCPT_BANK   = vRcpt_Bank
       , RCPT_VBANK  = vRcpt_VBank
       , RCPT_PREPAY = vRcpt_Prepay
       , RCPT_POINT  = vRcpt_Point
       , RCPT_ARS    = vRcpt_ARS
       , RCPT_COIN   = vRcpt_Coin
       , RCPT_ETC    = vRcpt_ETC
       , RCPT_REMAIN = (Total_Amt - vRcpt_Total)
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO = SP_Ord_NO;
     
  UPDATE Ord_Mst
     SET Rcpt_YN = 'Y'
   WHERE Com_ID = SP_Com_ID
     AND Ord_NO = SP_Ord_NO;
     
  COMMIT;   
     
  ----------------------------------------------------------------------------
  SP_RetCode := 'OK';
  SP_RetStr  := ufMessage('정상적으로 저장되었습니다.', vLang_CD); -- đa đ？？c l？u binh th？？ng
  ----------------------------------------------------------------------------  
  
--------------------------------------------------------------------------------
-- 예외처리 X？ ly ngo？i l？
--------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : ORD_BP_CHK_SP [Insert / Update / Delete] - END -          */
/* -------------------------------------------------------------------------- */






/* -------------------------------------------------------------------------- */
/* Package Member : ORD_RCPT_INS_SP [Insert, Update]                          */
/* Work    Date   : 2021-06-30 Created by Hwang                               */
/* -------------------------------------------------------------------------- */
PROCEDURE ORD_RCPT_INS_SP (
  SP_Com_ID             IN  VARCHAR2, --    NOT NULL 회사번호 (Company.Com_ID)
  SP_Ord_NO             IN  ORD_RCPT.Ord_NO%TYPE,
  SP_Money_NO           IN  ORD_RCPT.Money_NO%TYPE,
  SP_Userid             IN  VARCHAR2, --    NOT NULL 회원번호 (Member.Userid)
  SP_Amt                IN  ORD_RCPT.Amt%TYPE,
  SP_Work_User          IN  ORD_RCPT.Work_User%TYPE,
  ------------------------------------------------------------------------------
  SP_Log_Kind           IN  VARCHAR2, --    NOT NULL 구분 (MYOFFICE / WOWNET / ADMIN)
  SP_Form_NO            IN  VARCHAR2, --        NULL 폼번호
  SP_Btn_Name           IN  VARCHAR2, --        NULL 작업버튼
  SP_PC_Name            IN  VARCHAR2, --        NULL 컴퓨터명 / 브라우져명
  SP_PC_User            IN  VARCHAR2, --        NULL 컴퓨터 사용자명 / 브라우져 버전
  SP_PC_Kind            IN  VARCHAR2, --        NULL 장치구분 (PC, PHONE, TABLET) 
  SP_IP_Addr            IN  VARCHAR2, --        NULL 아이피 어드레스
  SP_Mac_Addr           IN  VARCHAR2, --        NULL 맥 어드레스
  ------------------------------------------------------------------------------
  SP_RetCode            OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr             OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)
IS
  vKind                 Ord_Money.Kind%TYPE;
  vO_Acc_Kind           VARCHAR2(1);
  vAcc_Date             Ord_Mst.Acc_Date%TYPE;
  vCnt                  PLS_INTEGER;
  vLang_CD              VARCHAR2(2); -- 담당자 사용언어코드 (Country.CTR_CD) Ma ngon ng？ s？ d？ng cho ng？？i ph？ trach
BEGIN

  ------------------------------------------------------------------------------
  -- 메시지 다국어 처리를 위해 담당자의 사용언어코드를 읽는다.
  -- đ？c ma ngon ng？ s？ d？ng c？a ng？？i ph？ trach đ？ x？ ly tin nh？n đa ngon ng？
  ------------------------------------------------------------------------------
  IF SP_Log_Kind = 'MYOFFICE' THEN
    SELECT CTR_CD INTO vLang_CD
    FROM MEMBER
   WHERE COM_ID = SP_Com_ID
     AND Userid = SP_Work_User;
  ELSE
  SELECT Lang_CD INTO vLang_CD
    FROM SM_User
   WHERE COM_ID = SP_Com_ID
     AND Userid = SP_Work_User;
  END IF;
  
  ------------------------------------------------------------------------------
  -- 해당 결제정보에서 결제유형을 읽어온다.
  -- 1:현금,2:무통장,3:신용카드,4:포인트,5:기타
  ------------------------------------------------------------------------------
  SELECT SUBSTR(Kind, 3) INTO vKind 
    FROM Ord_Money
   WHERE Com_ID = SP_Com_ID
     AND Money_NO = SP_Money_NO;
  ------------------------------------------------------------------------------
  -- 입금처리정보를 저장한다.
  ------------------------------------------------------------------------------
  INSERT INTO ORD_RCPT
         (Com_ID,
          Ord_NO,
          Money_NO,
          Amt,
          Userid,
          Work_User)
  VALUES (SP_Com_ID,
          SP_Ord_NO,
          SP_Money_NO,
          SP_Amt,
          SP_Userid,
          SP_Work_User);          
          
  ------------------------------------------------------------------------------
  -- 입금정보에 처리한 금액에 대해 사용금액을 업데이트한다.
  ------------------------------------------------------------------------------
  UPDATE ORD_MONEY
     SET Amt_Used = Amt_Used + SP_Amt
   WHERE Money_NO = SP_Money_NO;
   
  ------------------------------------------------------------------------------
  -- 주문데이터를 업데이트한다.
  -----------------------------------------------------------------------------
  IF    vKind = 's01' THEN UPDATE ORD_MST SET Rcpt_Cash   = Rcpt_Cash   + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO; 
  ELSIF vKind = 's02' THEN UPDATE ORD_MST SET Rcpt_Card   = Rcpt_Card   + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO;
  ELSIF vKind = 's03' THEN UPDATE ORD_MST SET Rcpt_Bank   = Rcpt_Bank   + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO; 
  ELSIF vKind = 's04' THEN UPDATE ORD_MST SET RCPT_VBank  = RCPT_VBank  + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO; 
  ELSIF vKind = 's05' THEN UPDATE ORD_MST SET RCPT_PREPAY = RCPT_PREPAY + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO; 
  ELSIF vKind = 's06' THEN UPDATE ORD_MST SET Rcpt_Point  = Rcpt_Point  + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO;
  ELSIF vKind = 's07' THEN UPDATE ORD_MST SET RCPT_ARS    = RCPT_ARS    + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO;
  ELSIF vKind = 's08' THEN UPDATE ORD_MST SET RCPT_Coin   = RCPT_Coin   + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO; 
  ELSIF vKind = 's09' THEN UPDATE ORD_MST SET Rcpt_Etc    = Rcpt_Etc    + SP_Amt, Rcpt_Total = Rcpt_Total + SP_Amt WHERE Ord_NO = SP_Ord_NO; 
  END IF;
  
  UPDATE ORD_MST
     SET Rcpt_YN = 'Y'
   WHERE Ord_NO  = SP_Ord_NO
     AND Rcpt_YN = 'N'
     AND Ord_Amt = Rcpt_Total;
  ------------------------------------------------------------------------------
  -- 입금처리시 승인일자 반영일 경우 주문마스터의 승인일자를 갱신한다. 
  ------------------------------------------------------------------------------
  --SELECT O_Acc_Kind INTO vO_Acc_Kind FROM SM_config;
  vO_Acc_Kind := '3';
  
  IF vO_Acc_Kind = '3' THEN 
    ----------------------------------------------------------------------------
    -- 해당 주문서의 입금완료여부 및 승인일자 등록여부를 읽는다. 
    ----------------------------------------------------------------------------
    SELECT COUNT(1) INTO vCnt
      FROM Ord_Mst
     WHERE Ord_NO = SP_Ord_NO
       AND Rcpt_YN = 'Y';

    IF vCnt = 1 THEN 
      ----------------------------------------------------------------------------
      -- 해당 주문서의 입금데이터 중에서 가장 마지막 입금일자를 읽는다.
      ----------------------------------------------------------------------------
      SELECT MAX(B.Reg_Date) INTO vAcc_Date
        FROM Ord_Rcpt A
           , Ord_Money B
       WHERE A.Money_NO = B.Money_NO
         AND A.Ord_NO = SP_Ord_NO;
   
      UPDATE ORD_MST
         SET Acc_Date = vAcc_Date
       WHERE Ord_NO  = SP_Ord_NO;
    END IF;
  END IF;
  ------------------------------------------------------------------------------
  -- 로그를 저장한다. (로그 버튼은 다국어처리, 메시지는 한국어로만 저장한다.)
  -- L？u nh？t ky. (Nut nh？t ky đ？？c x？ ly b？ng đa ngon ng？ va tin nh？n ch？ đ？？c l？u b？ng ti？ng Han.)
  ------------------------------------------------------------------------------
  Log_PKG.Log_SP (SP_Com_ID, SP_Work_User, SP_Log_Kind, SP_Form_NO, SP_PC_Name, SP_PC_User, SP_PC_Kind, SP_IP_Addr, SP_Mac_Addr, ufMessage('UPD', vLang_CD), ufMessage('입금번호 :', vLang_CD) || ' ' || SP_Money_NO );
  
  ------------------------------------------------------------------------------
  -- 주문결제처리 변경로그(Ord_Rcpt_Log)테이블에 데이터를 기록한다.
  -- 1:저장,2:수정,3:삭제 
  ------------------------------------------------------------------------------
  --MONEY_PKG.Ord_Rcpt_Log_SP(SP_Ord_NO, SP_Money_NO, '1', SP_Work_User);
END;
/* -------------------------------------------------------------------------- */
/* Package Member : ORD_RCPT_INS_SP [Insert, Update] - END -                  */
/* -------------------------------------------------------------------------- */



/* -------------------------------------------------------------------------- */
/* Package Order  : Pg_Pay_SP [Insert]                                        */
/* Work    Date   : 2021-04-23 Created by Joo                                 */
/* Memo           : 선결제 저장 프로시저                                      */
/* -------------------------------------------------------------------------- */
PROCEDURE Pg_Pay_Web_SP  (
  SP_Com_ID                IN  VARCHAR2,   -- 회사번호 (Company.Com_ID) S？ cong ty (Company.Com_ID);
  --SP_Reg_NO                IN  VARCHAR2,   --   등록번호 (SEQ_PK 시퀀스 사용) 
  SP_Kind_CD               IN  VARCHAR2,   -- 결제타입코드(Code.Code_CD)
  SP_Mid                   IN  VARCHAR2,   -- 상점아이디
  SP_Userid                IN  VARCHAR2,   --  회원번호 (Member.Userid)
  SP_Amt                   IN  VARCHAR2,   -- 금액
  SP_Card_App_Date         IN  VARCHAR2,   -- 승인일자(YYYYMMDD)
  SP_Card_App_NO           IN  VARCHAR2,   -- 승인번호
  SP_Result_CD             IN  VARCHAR2,   -- 결과코드
  SP_Result_MSG            IN  VARCHAR2,   -- 결과메시지
  SP_Status                IN  VARCHAR2,   -- 진행단계(BEFORE 결제진행전/ TRY 결제시도 / PROCESS 결제진행중)
  SP_Card_CD               IN  VARCHAR2,   -- 신용카드결제시 : 카드사코드 / 무통장송금시 : 회사 은행코드 (Bank.Bank_CD)
  SP_Card_Install          IN  VARCHAR2,   -- 신용카드 할부개월수
  SP_Money_NO              IN  VARCHAR2,   --  입금번호(YYMMDD-HHMISS- + 시퀀스3자리. 총 17자리)
  --SP_Work_Date             IN  VARCHAR2,   -- 작업일자
  SP_Work_User             IN  VARCHAR2,   -- 작업자번호 
  ------------------------------------------------------------------------------
  SP_RetCode               OUT VARCHAR2, -- [리턴값] 결과코드
  SP_RetStr                OUT VARCHAR2  -- [리턴값] 결과내용
  ------------------------------------------------------------------------------
)IS

  vCom_ID   VARCHAR2(10);
  v         Ord_Money%ROWTYPE;
  vSeq      PLS_INTEGER;           
BEGIN

  v.Money_NO := TO_CHAR(SYSDATE, 'YYYYMMDD-HH24MISS') || '-';

  SELECT COUNT(1) + 1 INTO vSeq
    FROM Ord_Money
   WHERE Money_NO LIKE v.Money_NO || '%';
     
  v.Money_NO := v.Money_NO || LPAD(vSeq, 3, '0'); 
   
    INSERT INTO PG_PrePay ( Com_ID       
                          , Reg_NO       
                          , Kind_CD      
                          , Mid          
                          , Userid       
                          , Amt          
                          , Card_App_Date
                          , Card_App_NO  
                          , Result_CD    
                          , Result_MSG   
                          , Status       
                          , Card_CD      
                          , Card_Install 
                          , Money_NO     
                          , Work_Date    
                          , Work_User    
                  )VALUES(  SP_Com_ID       
                          , SEQ_PK.NextVal       
                          , SP_Kind_CD      
                          , SP_Mid          
                          , SP_Userid       
                          , SP_Amt          
                          , SP_Card_App_Date
                          , SP_Card_App_NO  
                          , SP_Result_CD    
                          , SP_Result_MSG   
                          , SP_Status       
                          , SP_Card_CD      
                          , SP_Card_Install 
                          , SP_Money_NO  
                          , SYSDATE    
                          , SP_Work_User    
                  ); 
                  
  SP_RetCode := v.Money_NO;                  
  COMMIT;                      
EXCEPTION
  WHEN OTHERS THEN
    SP_RetCode := SUBSTR(SQLERRM,  1,  9);
    SP_RetStr  := SUBSTR(SQLERRM, 12,100);
    --DBMS_OUTPUT.PUT_LINE('SP_RetCode: '|| SP_RetCode);
    --DBMS_OUTPUT.PUT_LINE('SP_RetStr : '|| SP_RetStr); 
    ROLLBACK;
END;
/* -------------------------------------------------------------------------- */
/* Package Member : Pg_Pay_Web_SP [Insert] - END -                                */
/* -------------------------------------------------------------------------- */


END Order_PKG;
/
