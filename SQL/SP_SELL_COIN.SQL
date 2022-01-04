create procedure sell_Coin(
	seller_Address_SP VARCHAR , 
    buyer_address_sp VARCHAR , 
	coin_id_sp  varchar,
    quantity_SP numeric)
language plpgsql     
as
$$
declare 
v_coin varchar ;
v_money numeric  ;
v_price numeric  ;
begin
-- check coin
 select quantity into v_coin from accountCoin where addresscoin = seller_Address_SP
 and coin_id = coin_id_sp;
-- check money 
 select balance into v_monEy from accounts where address = buyer_address_sp
 and coin_id = coin_id_sp ;
 -- get v_price 
 select price into v_price from coin where coin_id = coin_id_sp;
 -- update coin seller 
 if(quantity_SP < v_coin and v_money <  (quantity_Sp * v_price)) then 
 UPDATE ACCOUNTCOIN SET QUANTITY = QUANTITY - quantity_SP 
 WHERE  ADDRESSCOIN = seller_Address_SP AND COIN_ID = coin_id_sp;
 
 -- update coin buyer 
 UPDATE ACCOUNTCOIN SET QUANTITY = QUANTITY + QUANTITY_SP
 WHERE ADDRESSCOIN = buyer_address_sp and 
 COIN_ID = coin_id_sp;
 
 -- update money seller
 update accounts set balance = balance + (quantity_sp * v_price)
 where address = seller_Address_SP;
 
 -- update money buyer
 
 update accounts set balance = balance - (quantity_sp * v_price)
 where address = buyer_address_sp;
 
 end if ;
end;
$$;

