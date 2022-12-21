-- Load title  IN 
SELECT Kind_CD AS kindCd                                 
     , Code_CD AS codeCd                                 
     , Code_Name AS codeName                             
     , Code_Name_Org AS codeNameOrg                      
     , Code_N1 AS codeN1                                 
     , Code_N2 AS codeN2                                 
     , Code_N3 AS codeN3                                 
     , Code_S1 AS codeS1                                 
     , Code_S2 AS codeS2                                 
     , Code_S3 AS codeS3                                 
     , ufDate(:lang, 'L', Code_D1) AS codeD1             
     , ufDate(:lang, 'L', Code_D2) AS codeD2             
     , ufDate(:lang, 'L', Code_D3) AS codeD3             
     , Sort_NO AS sortNo                                 
     , Use_YN AS useYn                                   
     , DECODE(Use_YN, 'Y','사용','N','미사용') AS UseYNName 
     , Edit_YN AS editYn                                 
     , View_YN AS viewYn                                 
     , Ref_Cnt AS refCnt                                 
     , ufDate(:lang, 'L', Ref_LASt_Date) AS refLAStDate  
     , Ref_Date AS refDate                               
     , Remark AS remark                                  
     , Work_Date AS workDate                             
     , Work_User AS workUser                             
     , ufStatus(Code_CD) AS status                       
  FROM Code                                              
 WHERE Com_Id = :comId                                   
   AND Kind_CD = :kindCd   
   AND use_Yn = 'Y'  
   AND code_N1 =  1     
 ORDER BY Sort_NO, Code_CD    
 
-- Load title  OUT
SELECT Kind_CD AS kindCd                                 
     , Code_CD AS codeCd                                 
     , Code_Name AS codeName                             
     , Code_Name_Org AS codeNameOrg                      
     , Code_N1 AS codeN1                                 
     , Code_N2 AS codeN2                                 
     , Code_N3 AS codeN3                                 
     , Code_S1 AS codeS1                                 
     , Code_S2 AS codeS2                                 
     , Code_S3 AS codeS3                                 
     , ufDate(:lang, 'L', Code_D1) AS codeD1             
     , ufDate(:lang, 'L', Code_D2) AS codeD2             
     , ufDate(:lang, 'L', Code_D3) AS codeD3             
     , Sort_NO AS sortNo                                 
     , Use_YN AS useYn                                   
     , DECODE(Use_YN, 'Y','사용','N','미사용') AS UseYNName 
     , Edit_YN AS editYn                                 
     , View_YN AS viewYn                                 
     , Ref_Cnt AS refCnt                                 
     , ufDate(:lang, 'L', Ref_LASt_Date) AS refLAStDate  
     , Ref_Date AS refDate                               
     , Remark AS remark                                  
     , Work_Date AS workDate                             
     , Work_User AS workUser                             
     , ufStatus(Code_CD) AS status                       
  FROM Code                                              
 WHERE Com_Id = :comId                                   
   AND Kind_CD = :kindCd   
   AND use_Yn = 'Y'  
   AND code_N1 =  -1     
 ORDER BY Sort_NO, Code_CD    
 
 
 -- 5210 SQL LOAD GIRD By Pdt
 SELECT ufName(A.Com_ID,'CODE',A.Status) AS Status                                                              
     , A.Cate_CD                                                                                               
     , ufName(A.Com_ID,'PDT_CATE',A.Cate_CD) AS Cate_Name                                                      
     , DECODE(A.BOM_YN,'Y','세트','N','') AS BOM_YN                                                             
     , A.Pdt_CD                                                                                                
     , ufName(A.Com_ID,'PRODUCT',A.Pdt_CD) AS Pdt_Name                                                         
     , '창고합산' AS Store_Name                                                                                  
     , B.Qty_Be                                                                                                
     , B.In_Sum                                                                                                
     , B.Out_Sum                                                                                               
     , B.Qty_Be + (B.In_Sum - B.Out_Sum) AS Qty_Now                                                            
     , B.In_01                                                                                                 
     , B.In_02                                                                                                 
     , B.In_03                                                                                                 
     , B.In_04                                                                                                 
     , B.In_05                                                                                                 
     , B.In_06                                                                                                 
     , B.In_07                                                                                                 
     , B.In_08                                                                                                 
     , B.In_09                                                                                                 
     , B.In_10                                                                                                 
     , B.In_11                                                                                                 
     , B.In_12                                                                                                 
     , B.In_13                                                                                                 
     , B.In_14                                                                                                 
     , B.IN_Sum AS In_Sum2                                                                                     
     , B.Out_01                                                                                                
     , B.Out_02                                                                                                
     , B.Out_03                                                                                                
     , B.Out_04                                                                                                
     , B.Out_05                                                                                                
     , B.Out_06                                                                                                
     , B.Out_07                                                                                                
     , B.Out_08                                                                                                
     , B.Out_09                                                                                                
     , B.Out_10                                                                                                
     , B.Out_11                                                                                                
     , B.Out_12                                                                                                
     , B.Out_13                                                                                                
     , B.Out_Sum AS Out_Sum2                                                                                   
  FROM Pdt_Mst A                                                                                               
     , (SELECT A.Pdt_CD                                                                                        
             , NVL((SELECT SUM(Qty_In - Qty_Out) FROM Stk_Pdt                                                  
		   WHERE Com_ID = :comId                                                                                 
			 AND (:regDateStart is NULL OR Reg_Date < :regDateStart)                                             
			 AND Pdt_CD = A.Pdt_CD), 0) AS Qty_Be                                                                
             , A.In_01                                                                                         
             , A.In_02                                                                                         
             , A.In_03                                                                                         
             , A.In_04                                                                                         
             , A.In_05                                                                                         
             , A.In_06                                                                                         
             , A.In_07                                                                                         
             , A.In_08                                                                                         
             , A.In_09                                                                                         
             , A.In_10                                                                                         
             , A.In_11                                                                                         
             , A.In_12                                                                                         
             , A.In_13                                                                                         
             , A.In_14                                                                                         
             , A.IN_Sum                                                                                        
             , A.Out_01                                                                                        
             , A.Out_02                                                                                        
             , A.Out_03                                                                                        
             , A.Out_04                                                                                        
             , A.Out_05                                                                                        
             , A.Out_06                                                                                        
             , A.Out_07                                                                                        
             , A.Out_08                                                                                        
             , A.Out_09                                                                                        
             , A.Out_10                                                                                        
             , A.Out_11                                                                                        
             , A.Out_12                                                                                        
             , A.Out_13                                                                                        
             , A.Out_Sum                                                                                       
          FROM (SELECT Pdt_CD                                                                                  
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L11',Qty_IN )),0) AS In_01                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L12',Qty_IN )),0) AS In_02                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L13',Qty_IN )),0) AS In_03                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L14',Qty_IN )),0) AS In_04                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L15',Qty_IN )),0) AS In_05                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L21',Qty_IN )),0) AS In_06                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L22',Qty_IN )),0) AS In_07                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L23',Qty_IN )),0) AS In_08                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L24',Qty_IN )),0) AS In_09                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L25',Qty_IN )),0) AS In_10                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L26',Qty_IN )),0) AS In_11                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L27',Qty_IN )),0) AS In_12                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L28',Qty_IN )),0) AS In_13                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L29',Qty_IN )),0) AS In_14                    
                     , NVL(SUM(Qty_In),0)                          AS IN_Sum                                   
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L51',Qty_IN )),0) AS Out_01                   
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L52',Qty_IN )),0) AS Out_02                   
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L53',Qty_IN )),0) AS Out_03                   
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L54',Qty_IN )),0) AS Out_04                   
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L61',Qty_IN )),0) AS Out_05                   
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L62',Qty_IN )),0) AS Out_06                   
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L63',Qty_IN )),0) AS Out_07                   
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L64',Qty_IN )),0) AS Out_08                   
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L65',Qty_IN )),0) AS Out_09                   
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L66',Qty_IN )),0) AS Out_10                   
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L67',Qty_IN )),0) AS Out_11                   
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L68',Qty_IN )),0) AS Out_12                   
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L69',Qty_IN )),0) AS Out_13                   
                     , NVL(SUM(Qty_Out),0)                         AS Out_Sum                                  
                 FROM (SELECT Pdt_CD                                                                           
                            , Kind_CD                                                                          
                            , SUM(Qty_IN)  AS Qty_IN                                                           
                            , SUM(Qty_Out) AS Qty_Out                                                          
                         FROM Stk_Pdt                                                                          
                        WHERE Com_ID = :comId                                                                  
                          AND Reg_Date BETWEEN NVL(:regDateStart, '00000000') AND NVL(:regDateEnd, '99999999') 
			    		    AND Store_CD LIKE NVL(:storeCD, '%')                                                 
			    		    AND Pdt_CD   LIKE NVL(:pdtCD, '%')                                                   
                        GROUP BY Pdt_CD, Kind_CD)                                                              
                 GROUP BY PDt_CD) A) B                                                                         
 WHERE A.Pdt_CD(+) = B.Pdt_CD                                                                                  
   AND A.Stock_YN = 'Y'                                                                                        
 ORDER BY A.Pdt_CD  

-- 5210 SQL LOAD GIRD By Stock 
SELECT ufName(A.Com_ID,'CODE',A.Status) AS Status                                                               
     , A.Cate_CD                                                                                                
     , ufName(A.Com_ID,'PDT_CATE',A.Cate_CD) AS Cate_Name                                                       
     , DECODE(A.BOM_YN,'Y','세트','N','') AS BOM_YN                                                              
     , A.Pdt_CD                                                                                                 
     , ufName(A.Com_ID,'PRODUCT',A.Pdt_CD) AS Pdt_Name                                                          
     , B.Store_CD                                                                                               
     , ufName(A.Com_ID,'CENTER',B.Store_CD) AS Store_Name                                                       
     , B.Qty_Be                                                                                                 
     , B.In_Sum                                                                                                 
     , B.Out_Sum                                                                                                
     , B.Qty_Be + (B.In_Sum - B.Out_Sum) AS Qty_Now                                                             
     , B.In_01                                                                                                  
     , B.In_02                                                                                                  
     , B.In_03                                                                                                  
     , B.In_04                                                                                                  
     , B.In_05                                                                                                  
     , B.In_06                                                                                                  
     , B.In_07                                                                                                  
     , B.In_08                                                                                                  
     , B.In_09                                                                                                  
     , B.In_10                                                                                                  
     , B.In_11                                                                                                  
     , B.In_12                                                                                                  
     , B.In_13                                                                                                  
     , B.In_14                                                                                                  
     , B.IN_Sum AS In_Sum2                                                                                      
     , B.Out_01                                                                                                 
     , B.Out_02                                                                                                 
     , B.Out_03                                                                                                 
     , B.Out_04                                                                                                 
     , B.Out_05                                                                                                 
     , B.Out_06                                                                                                 
     , B.Out_07                                                                                                 
     , B.Out_08                                                                                                 
     , B.Out_09                                                                                                 
     , B.Out_10                                                                                                 
     , B.Out_11                                                                                                 
     , B.Out_12                                                                                                 
     , B.Out_13                                                                                                 
     , B.Out_Sum AS Out_Sum2                                                                                    
  FROM Pdt_Mst A                                                                                                
     , (SELECT A.Pdt_CD                                                                                         
             , A.Store_CD                                                                                       
             , NVL((SELECT SUM(Qty_In - Qty_Out) FROM Stk_Pdt                                                   
		   WHERE Com_ID = :comId                                                                                  
			 AND (:regDateStart is NULL OR Reg_Date < :regDateStart)                                              
			 AND Pdt_CD = A.Pdt_CD                                                                                
			 AND Store_CD = A.Store_CD), 0) AS Qty_Be                                                             
             , A.In_01                                                                                          
             , A.In_02                                                                                          
             , A.In_03                                                                                          
             , A.In_04                                                                                          
             , A.In_05                                                                                          
             , A.In_06                                                                                          
             , A.In_07                                                                                          
             , A.In_08                                                                                          
             , A.In_09                                                                                          
             , A.In_10                                                                                          
             , A.In_11                                                                                          
             , A.In_12                                                                                          
             , A.In_13                                                                                          
             , A.In_14                                                                                          
             , A.IN_Sum                                                                                         
             , A.Out_01                                                                                         
             , A.Out_02                                                                                         
             , A.Out_03                                                                                         
             , A.Out_04                                                                                         
             , A.Out_05                                                                                         
             , A.Out_06                                                                                         
             , A.Out_07                                                                                         
             , A.Out_08                                                                                         
             , A.Out_09                                                                                         
             , A.Out_10                                                                                         
             , A.Out_11                                                                                         
             , A.Out_12                                                                                         
             , A.Out_13                                                                                         
             , A.Out_Sum                                                                                        
          FROM (SELECT Pdt_CD                                                                                   
                     , Store_CD                                                                                 
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L11',Qty_IN )),0) AS In_01                     
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L12',Qty_IN )),0) AS In_02                     
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L13',Qty_IN )),0) AS In_03                     
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L14',Qty_IN )),0) AS In_04                     
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L15',Qty_IN )),0) AS In_05                     
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L21',Qty_IN )),0) AS In_06                     
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L22',Qty_IN )),0) AS In_07                     
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L23',Qty_IN )),0) AS In_08                     
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L24',Qty_IN )),0) AS In_09                     
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L25',Qty_IN )),0) AS In_10                     
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L26',Qty_IN )),0) AS In_11                     
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L27',Qty_IN )),0) AS In_12                     
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L28',Qty_IN )),0) AS In_13                     
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L29',Qty_IN )),0) AS In_14                     
                     , NVL(SUM(Qty_In),0)                          AS IN_Sum                                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L51',Qty_IN )),0) AS Out_01                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L52',Qty_IN )),0) AS Out_02                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L53',Qty_IN )),0) AS Out_03                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L54',Qty_IN )),0) AS Out_04                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L61',Qty_IN )),0) AS Out_05                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L62',Qty_IN )),0) AS Out_06                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L63',Qty_IN )),0) AS Out_07                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L64',Qty_IN )),0) AS Out_08                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L65',Qty_IN )),0) AS Out_09                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L66',Qty_IN )),0) AS Out_10                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L67',Qty_IN )),0) AS Out_11                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L68',Qty_IN )),0) AS Out_12                    
                     , NVL(SUM(DECODE(Kind_CD,ufCom_CD(:comId)||'L69',Qty_IN )),0) AS Out_13                    
                     , NVL(SUM(Qty_Out),0)                         AS Out_Sum                                   
                  FROM (SELECT Pdt_CD                                                                           
                             , Store_CD                                                                         
                             , Kind_CD                                                                          
                             , SUM(Qty_IN)  AS Qty_IN                                                           
                             , SUM(Qty_Out) AS Qty_Out                                                          
                          FROM Stk_Pdt                                                                          
                         WHERE Com_ID = :comId                                                                  
                           AND Reg_Date BETWEEN NVL(:regDateStart, '00000000') AND NVL(:regDateEnd, '99999999') 
                           AND Store_CD LIKE NVL(:storeCD, '%')                                                 
                           AND Pdt_CD   LIKE NVL(:pdtCD, '%')                                                   
                         GROUP BY Store_CD, Pdt_CD, Kind_CD)                                                    
                 GROUP BY PDt_CD, Store_CD) A) B                                                                
 WHERE A.Pdt_CD(+) = B.Pdt_CD                                                                                   
   AND A.Stock_YN = 'Y'                                                                                         
 ORDER BY A.Pdt_CD, B.Store_CD                                                                                  


 
