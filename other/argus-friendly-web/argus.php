<?php
// $needle is a string, $haystack is a single dimension array
function ldap_array_find( $needle, $haystack , $instance = 1) {
  $i=1;
  foreach ($haystack as $key => $item) {
    if (strstr($item,"=")) {
      $TMP=explode("=",$item);
      if ($needle == $TMP[0]){
        if ($i == $instance) {
          return $key;
        } else {
          $i++;
        }
      }
    }
  }
  return false;
}
?>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="assets/css/fresh-bootstrap-table.css" rel="stylesheet" />
  </head>
  <body>
    <div class="row"> <div class="col-md-10 col-md-offset-1"> <div class="fresh-table">
    <h2 style="width:100%; text-align:center; color:#333;">Durham ARGUS User Mapping</h2>
    <div class="toolbar"></div> 
    <table class="table table-hover table-condensed" id="searchable-table" >
      <thead>
        <tr><th data-field="poolname">Pool User</th><th data-field="name">CN</th><th>VO</th><th>Site</th><th>Country</th><th>Certificate DN</th></tr>
      </thead><tbody>
    <?PHP
      $argus_output = file_get_contents("/mt/admin/argus/userlist2.txt");
      $argus_output = explode("\n",$argus_output);
      // Start at Number one as the first line is a header
      $i=1;
      while (!empty($argus_output[$i])) {
        $user = explode(" - ", $argus_output[$i]);
	$DN2 = str_replace("/",",",substr($user[1],2));
	$DN2 = ldap_explode_dn($DN2, 0);
	$CN = str_replace("cn=","",$DN2[ldap_array_find("cn", $DN2)]);
	$VO = explode(":", $DN2[($DN2[count]-1)]);
	$VO = $VO[(count($VO)-1)];
	$CN = explode(":", $CN);
	$CN = ucwords($CN[0]);

        $OU = ucwords(str_replace("ou=","",$DN2[ldap_array_find("ou", $DN2)]));
	if (ldap_array_find("o", $DN2) !== false) {
 		$O = str_replace("o=","",$DN2[ldap_array_find("o", $DN2)]);
	} else {
		$O = str_replace("dc=","",$DN2[ldap_array_find("dc", $DN2, 2)]);
	}
	if (ldap_array_find("c", $DN2) !== false) {
		$C = str_replace("c=","",$DN2[ldap_array_find("c", $DN2)]);
	} elseif (ldap_array_find("dc", $DN2) !== false) {
		$C = str_replace("dc=","",$DN2[ldap_array_find("dc", $DN2)]);
	} else {
		$C = "";
	}
        echo "<tr>";
	  echo "<td>".$user[0]."</td>";
          echo "<td>".$CN."</td>";
	  echo "<td>".$VO."</td>";
          echo "<td>".$O." / ".$OU."</td>";
          echo "<td>".$C."</td>";
          echo "<td>".substr($user[1],2)."</td>";
        echo "</tr>";
        $i++;
      }
    ?>
    </table>
    </div></div></div>

    <script type="text/javascript" src="assets/js/jquery-1.11.2.min.js"></script>
    <script type="text/javascript" src="assets/js/bootstrap.js"></script>
    <script type="text/javascript" src="assets/js/bootstrap-table.js"></script>
    <script type="text/javascript">
        var $table = $('#searchable-table'),
            full_screen = false;

        $().ready(function(){
            $table.bootstrapTable({
                toolbar: ".toolbar",

                showRefresh: false,
                search: true,
                showToggle: false,
                showColumns: false,
                pagination: true,
                striped: true,
                sortable: true,
                pageSize: 25,
                pageList: [10,15,25,50,100],
                
                formatShowingRows: function(pageFrom, pageTo, totalRows){
                    //do nothing here, we don't want to show the text "showing x of y from..." 
                },
                formatRecordsPerPage: function(pageNumber){
                    return pageNumber + " rows visible";
                },
                icons: {
                    refresh: 'fa fa-refresh',
                    toggle: 'fa fa-th-list',
                    columns: 'fa fa-columns',
                    detailOpen: 'fa fa-plus-circle',
                    detailClose: 'fa fa-minus-circle'
                }
            });
        });

        function operateFormatter(value, row, index) {
            return [
                '<a rel="tooltip" title="Like" class="table-action like" href="javascript:void(0)" title="Like">',
                    '<i class="fa fa-heart"></i>',
                '</a>',
                '<a rel="tooltip" title="Edit" class="table-action edit" href="javascript:void(0)" title="Edit">',
                    '<i class="fa fa-edit"></i>',
                '</a>',
                '<a rel="tooltip" title="Remove" class="table-action remove" href="javascript:void(0)" title="Remove">',
                    '<i class="fa fa-remove"></i>',
                '</a>'
            ].join('');
        }
    
        window.operateEvents = {
            'click .like': function (e, value, row, index) {
                alert('You click like icon, row: ' + JSON.stringify(row));
                console.log(value, row, index);
            },
            'click .edit': function (e, value, row, index) {
                console.log(value, row, index);    
            },
            'click .remove': function (e, value, row, index) {
                alert('You click remove icon, row: ' + JSON.stringify(row));
                console.log(value, row, index);
            }
        };

</script>

</body>
</html>

