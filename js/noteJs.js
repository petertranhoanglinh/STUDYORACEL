function getUserKind(){
    var dataUser = [];
        $.ajax({
            url: "/system/1020/search/" + 'U',
            type: "GET",
            success: function (result) {
            len = result.length;
                for (var i = 0; i < result.length; i++) {
                    if (result[i].useYn == 'Y' && result[i].codeCd != userCompany.comCd + 'U00' && result[i].codeCd != userCompany.comCd + 'U01') {
                        if(document.getElementById(result[i].codeCd).checked){
                            dataUser.push(result[i].codeCd.substring(3));
                        }
                    }
                }		
            }
        });
        return dataUser;
    }



for(var i = 0 ; i < lenUser ; i ++){
        if(document.getElementById('userkind'+i).checked){
                  userKind.push($('#userkind'+i+'').val().substring(3));
        }
  }
for(var i = 0 ; i < lenRank ; i ++){
        if(document.getElementById('userRank'+i).checked){
                  rankKind.push($('#userRank'+i+'').val().substring(2));
        }
  }



  $.ajaxSetup({ async:false });
  //  ưu tiên chạy trước 
  $.ajaxSetup({ async:true });


  //check rowItem wowGird
  function getCheckedRowItems() {
    var checkedItems = AUIGrid.getCheckedRowItems(wowGird.myGridID);
    var str = "";
    var rowItem;
    for(var i=0, len = checkedItems.length; i<len; i++) {
       rowItem = checkedItems[i];
       if(str === ''){
           str = rowItem.item.userid;
       }else {
           str += ',' +	rowItem.item.userid;
       }
    }
    return str;
 }
