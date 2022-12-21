IF SP_Kind = 'ORD.CASHRCPT_NUM' THEN
    BEGIN
      SELECT SUBSTR(NVL(A.CASHRCPT_NUM,'-'), 1, 20) INTO vReturn
        FROM Ord_Money A
           , Ord_Rcpt B
       WHERE A.Money_NO = B.Money_NO
         AND B.Ord_NO = SP_Code
         AND Rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        vReturn := '';
    END;

  ELSIF SP_Kind = 'ORD.CASHRCPT_TYPE' THEN
    BEGIN
      SELECT DECODE(NVL(A.CASHRCPT_TYPE,'00'),'20','소득공제','30','사업자증빙','미발행') INTO vReturn
        FROM Ord_Money A
           , Ord_Rcpt B
       WHERE A.Money_NO = B.Money_NO
         AND B.Ord_NO = SP_Code
         AND Rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        vReturn := '';
    END;
  END IF;