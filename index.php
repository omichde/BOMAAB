<?php
header('Content-type: application/json; charset=utf-8');
$actionList['dl'] = array('header' => 'Downloads for %s', 'productTypes' => "('1', '1F', '1T', 'F1')");
$actionList['iap'] = array('header' => 'IAPs for %s', 'productTypes' => "('IA1', 'IA9', 'IAY', 'FI1')");

if (strlen($_SERVER["QUERY_STRING"]) && in_array($_SERVER["QUERY_STRING"], array_keys($actionList)))
	$action = $actionList[$_SERVER["QUERY_STRING"]];
else
	$action = $actionList['dl'];	// default dl

require ("db.php");
$db = new bom_db();

$productList = array();
$db->query_all ("select distinct(Title) from sales order by Title");
foreach ($db->arr as $entry)
	$productList[] = $entry["Title"];

$output['graph']['title'] = sprintf ($action['header'], date('Y-m-d', mktime(0, 0, 0, date("m"), date("d")-1, date("Y"))));
$output['graph']['datasequences'] = array();
foreach ($productList as $product) {
	$blockValid = false;
	$block['title'] = (strlen($product) > 20 ? substr($product, 0, 20).'...' : $product);
	$block['datapoints'] = array();
	for ($off=-30; $off < -1; $off++) {	// last 30 days until yesterday
		$date = date('Y-m-d', mktime(0, 0, 0, date("m"), date("d")+$off, date("Y")));
		if ($db->query ("select sum(units) as cc from sales where Title='{PROD}' and ProductTypeIdentifier in ".$action['productTypes']." and BeginDate='{DATE}' and EndDate='{DATE}'", array('PROD' => $product, 'DATE' => $date)) &&
			$db->d["cc"] > 0) {
			$block['datapoints'][] = array ('title' => substr($date, 5), 'value' => $db->d["cc"]);
			$blockValid = true;
		}
		else
			$block['datapoints'][] = array ('title' => substr($date, 5), 'value' => 0);
	}
	if ($blockValid)
		$output['graph']['datasequences'][] = $block;
}
echo json_encode($output);
?>