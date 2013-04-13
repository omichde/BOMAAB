<?php
// bom_db.php
//
// This class actually handles some mysql-stuff in a straight way.
// 2.6: fixed stripslashes bug (json safe)
// 2.5: fixed select check
// 2.4: auto-detection of magic_quotes and mysql_real_escape_string in optional param array
// 2.3: self-selection of server by query
// 2.2: adoption to clustered setup
// 2.1: query_all bug fix
// release 2: named data-array, query_all
//
// (c) oliver@werk01.de

class bom_db {
	var $version = '2.5';
	var $sql = false;
	var $lastresult = false;
	var $lastid = false;
	var $lastquery = '';
	var $d = array();
	var $debug = false;

	function bom_db () {
		$this->access = array ('name' => "itunesconnect", 'host' => "localhost", 'user' => "your-mysql-username", 'password' => "your-mysql-password");
	}

	// connect once...
	function connect () {
		if (false === $this->sql) {
			if (!($sql = mysql_connect ($this->access['host'], $this->access['user'], $this->access['password'])) ||
					!mysql_select_db ($this->access['name'], $sql)) {
				$this->access = false;
				return false;
			}
			mysql_query ('SET CHARACTER SET UTF8', $sql);
			$this->sql = $sql;
		}
		return true;
	}

	// query and strip results immediately...
	function query ($query, $param = false) {
		$this->connect ();
		if (false === $this->sql)
			return false;
		$query = $this->param_replace ($query, $param);
		$this->lastquery = $query;

		if ($this->debug)
			printf ("\n<!-- $query -->\n");

		$result = mysql_query ($query, $this->sql);
		if (false === $result)
			return false;

		if (is_resource($result)) {
			$arr = mysql_fetch_row ($result);
			if (false === $arr)		return false;
			$this->d = array();
			for ($i=0; $i<mysql_num_fields($result); $i++)
				$this->d[mysql_field_name($result, $i)] = (get_magic_quotes_gpc () ? stripslashes($arr[$i]) : $arr[$i]);
			$this->lastresult = $result;
		}
		if (eregi ("(insert|replace).*", $query))
			$this->lastid = mysql_insert_id ($this->sql);
		else
			$this->lastid = false;
		return true;
	}

	// query next...
	function query_next () {
		if (!$this->lastresult)		return false;
		$this->d = array ();
		$arr = mysql_fetch_row ($this->lastresult);
		if (!$arr) {
			mysql_free_result ($this->lastresult);
			$this->lastresult = false;
			return false;
		}
		for ($i=0; $i<mysql_num_fields($this->lastresult); $i++)
			$this->d[mysql_field_name($this->lastresult, $i)] = (get_magic_quotes_gpc () ? stripslashes($arr[$i]) : $arr[$i]);
		return true;
	}

	// queries all (up to max) elements into an array...
	function query_all ($query, $param = false) {
		$this->arr = array ();
		$this->arr[0] = array ('' => '');
		if ($this->query ($query, $param)) {
			$i = 0;
			do
				$this->arr[$i++] = $this->d;
			while ($this->query_next());
			return true;
		}
		return false;
	}

	function param_replace ($query, $param) {
		if (is_array($param) && count($param)) {
			foreach ($param as $key => $value) {
				$query = str_replace ('{'.strtoupper($key).'}', mysql_real_escape_string (get_magic_quotes_gpc () ? stripslashes($value) : $value), $query);
			}
		}
		return $query;
	}

	function error ($mess = '') {
		$result = '';
		if (strlen($mess))
			$result .= 'error: '.$mess;
		$result .= '<p> '.mysql_error ($this->sql)."\n";
		return $result;
	}

}
?>