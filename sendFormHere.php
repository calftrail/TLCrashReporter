<?php
	$logDirectory = "logs/";
	$date = date('Y-m-d H-i-s');
    $version = $_POST['version'];
	$description = $_POST['description'];
	$logContents = $_POST['log'];
	$crashReport = $description . "\n\n" . $logContents;
	
	$fileName = $logDirectory . $date;
	$numSuffix = 1;
	while (file_exists($fileName)) {
		$fileName = $fileName . "_" . $numSuffix;
		$numSuffix = $numSuffix + 1;
	}
	$fileName = $fileName . ".log";
	
	file_put_contents($fileName, $crashReport, FILE_APPEND);
?>
