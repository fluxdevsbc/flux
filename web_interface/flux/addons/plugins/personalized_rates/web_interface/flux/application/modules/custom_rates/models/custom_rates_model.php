<?php
// ##############################################################################
// Flux SBC - Unindo pessoas e negócios
//
// Copyright (C) 2022 Flux Telecom
// Daniel Paixao <daniel@flux.net.br>
// Flux SBC Version 4.0 and above
// License https://www.gnu.org/licenses/agpl-3.0.html
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// ##############################################################################
class custom_rates_model extends CI_Model {
	function __construct() {
		parent::__construct ();
	}
	function get_custom_rate($flag, $start = 0, $limit = 0, $export = true) {
		$this->db_model->build_search ( 'custom_rate_list_search' );
		if ($this->session->userdata ( 'logintype' ) == 1 || $this->session->userdata ( 'logintype' ) == 5) {
			$account_data = $this->session->userdata ( "accountinfo" );
			$reseller = $account_data ['id'];
			$where = array (
					"reseller_id" => $reseller
			);
		} else {
			$where = array ();
		}

		$this->db_model->build_search ( 'custom_rate_list_search' );
		$where['pricelist_id'] = '0';
		if ($flag) {
			if ($export)
				$this->db->limit ( $limit, $start );
			$result = $this->db_model->select ( "*", "routes", $where, "id", "desc", $limit, $start );
		} else {
			$result = $this->db_model->countQuery ( "*", "routes", $where );
		}
		return $result;
	}
	function get_custom_rate_for_user($flag, $start = 0, $limit = 0, $export = true) {
		$this->db_model->build_search ( 'custom_rate_list_search' );

		$account_data = $this->session->userdata ( "accountinfo" );

		$where = array (
				"pricelist_id" => $account_data ["pricelist_id"]
		);

		$this->db_model->build_search ( 'custom_rate_list_search' );
		if ($flag) {
			if ($export)
				$this->db->limit ( $limit, $start );
			$result = $this->db_model->select ( "*", "routes", $where, "id", "ASC", $limit, $start );
		} else {
			$result = $this->db_model->countQuery ( "*", "routes", $where );
		}
		return $result;
	}
	// ==============================================
	function get_custom_rate_list($flag, $start = 0, $limit = 0) {
		$where = array();
		$this->db_model->build_search ( 'custom_rate_list_search' );
		if ($this->session->userdata ( 'logintype' ) == 1 || $this->session->userdata ( 'logintype' ) == 5) {
			$account_data = $this->session->userdata ( "accountinfo" );
			$where = array (
					"reseller_id" => $account_data ['id']
			);
		}
		if ($this->session->userdata ( 'advance_batch_delete' ) == 1) {
				if(!empty($where)){
					$this->db->where ( $where );
				}else{
					$where = array (
						'reseller_id' => '0'
					);
					$this->db->where ( $where );

				}
				$this->db->delete ( "routes" );
			$this->session->set_userdata ( 'advance_batch_delete', '0' );
			$this->session->unset_userdata ( 'advance_batch_delete' );
		}
		$this->db_model->build_search ( 'custom_rate_list_search' );
		$where['pricelist_id'] = '0';
		$where['accountid <>'] = '0';
		if ($flag) {
			$query = $this->db_model->select ( "*", "routes", $where, "id,reseller_id", "DESC", $limit, $start );
		} else {
			$query = $this->db_model->countQuery ( "*", "routes", $where );
		}
		//echo $this->db->last_query(); exit;
		return $query;
	}
	function getunblocked_pattern_list($accountid, $flag, $start = 0, $limit = 0) {
		$this->db_model->build_search ( 'custom_rate_list_search' );
		if ($this->session->userdata ( 'logintype' ) == 1 || $this->session->userdata ( 'logintype' ) == 5) {
			$account_data = $this->session->userdata ( "accountinfo" );
			$reseller = $account_data ['id'];
			$where = array (
					"reseller_id" => $reseller,
					"status" => "0"
			);
		} else {
			$where = array (
					"status" => "0",
					'reseller_id' => '0'
			);
		}
		$where1 = '(pattern NOT IN (select blocked_patterns from block_patterns where accountid = "' . $accountid . '"))';
		$this->db->where ( $where1 );
		if ($flag) {
			$query = $this->db_model->select ( "*", "routes", $where, "id", "ASC", $limit, $start );
			// echo "<pre>"; print_r($query); exit;
		} else {
			$query = $this->db_model->countQuery ( "*", "routes", $where );
		}
		return $query;
	}
	function getunblocked_package_pattern($accountid, $flag, $start = 0, $limit = 0) {
		$this->db_model->build_search ( 'custom_rate_list_search' );
		if ($this->session->userdata ( 'logintype' ) == 1 || $this->session->userdata ( 'logintype' ) == 5) {
			$account_data = $this->session->userdata ( "accountinfo" );
			$reseller = $account_data ['id'];
			$where = array (
					"reseller_id" => $reseller,
					"status" => "0"
			);
		} else {
			$where = array (
					"status" => "0",
					'reseller_id' => '0'
			);
		}
		$where1 = '(pattern NOT IN (select DISTINCT patterns from package_patterns where package_id = "' . $accountid . '"))';
		$this->db->where ( $where1 );
		if ($flag) {
			$query = $this->db_model->select ( "*", "routes", $where, "id", "ASC", $limit, $start );
		} else {
			$query = $this->db_model->countQuery ( "*", "routes", $where );
		}
		return $query;
	}
	function get_custom_rate_list_for_user($flag, $start = 0, $limit = 0) {
		$this->db_model->build_search ( 'user_rates_list_search' );

		$account_data = $this->session->userdata ( "accountinfo" );
		$where = array (
				"pricelist_id" => $account_data ["pricelist_id"],
				"status" => '0'
		);

		$this->db_model->build_search ( 'custom_rate_list_search' );
		if ($flag) {
			$query = $this->db_model->select ( "*", "routes", $where, "id", "ASC", $limit, $start );
		} else {
			$query = $this->db_model->countQuery ( "*", "routes", $where );
		}
		return $query;
	}
	function add_custom_rate($add_array) {
		unset ( $add_array ["action"] );
		
		$add_array ['creation_date'] = gmdate ( 'Y-m-d H:i:s' );
		$add_array ['last_modified_date'] = gmdate ( 'Y-m-d H:i:s' );
		
		if ($this->session->userdata ( 'logintype' ) == 1 || $this->session->userdata ( 'logintype' ) == 5) {
			$account_data = $this->session->userdata ( "accountinfo" );
			$reseller = $account_data ['id'];
			$add_array ['reseller_id'] = $reseller;
		}
		$add_array ['pattern'] = "^" . $add_array ['pattern'] . ".*";
		
		$this->insert_if_not_exitst ( $add_array, "routes" );
		
		return true;
	}
	function edit_custom_rate($data, $id) {
		unset ( $data ["action"] );
		/*
		 * FLUX 4.0
		 * Edit tile last modified date update
		 */
		$data ['last_modified_date'] = gmdate ( 'Y-m-d H:i:s' );
		/**
		 * *****************************************************
		 */
		$data ['pattern'] = "^" . $data ['pattern'] . ".*";
		$this->db->where ( "id", $id );
		$this->db->update ( "routes", $data );
	}
	function remove_custom_rate($id) {
		$this->db->where ( "id", $id );
		$this->db->delete ( "routes" );
		return true;
	}
	function get_trunk_name($field_value) {
		$this->db->where ( "name", $field_value );
		$query = $this->db->get ( 'trunks' );
		$data = $query->result ();
		if ($query->num_rows () > 0) {
			return $data [0]->id;
		} else {
			return '';
		}
	}

	function custom_rate_batch_update($update_array) {
		$this->db_model->build_search ( 'custom_rate_list_search' );
		if ($this->session->userdata ( 'logintype' ) == 1 || $this->session->userdata ( 'logintype' ) == 5) {
			$account_data = $this->session->userdata ( "accountinfo" );
			$this->db->where ( "reseller_id", $account_data ['id'] );
		}
		$this->db->where ("pricelist_id","0");
		$updateflg = $this->db_model->build_batch_update_array ( $update_array );
		if ($updateflg)
			return $this->db->update ( "routes" );
		else
			return false;
	}
	function getreseller_rates_list($flag, $start = 0, $limit = 0, $export = false) {
		$this->db_model->build_search ( 'resellerrates_list_search' );
		$account_data = $this->session->userdata ( "accountinfo" );
		$where = array (
				"status" => "0",
				"pricelist_id" => $account_data ["pricelist_id"]
		);
		if ($flag) {
			$query = $this->db_model->select ( "*", "routes", $where, "id", "ASC", $limit, $start );
		} else {
			$query = $this->db_model->countQuery ( "*", "routes", $where );
		}
		return $query;
	}
	/**
	 * ***********
	 * FLUX 4.0
	 * Rate insert
	 * ************
	 */
	/**
	 *
	 * @param string $table_name
	 */
	function insert_if_not_exitst($add_array, $table_name) {
		$db = get_instance()->db->conn_id;
		$insert_str = "Insert into $table_name (";
		$insert_key = "";
		$insert_value = "";
		$update_str = "";
		foreach ( $add_array as $key => $value ) {
			if ($key != 'id') {
				$insert_key .= $key . ",";
				//$insert_value .= "'" . mysqli_real_escape_string ( $db, $value ) . "',";
				//$update_str .= $key . " = '" . mysqli_real_escape_string ( $db, $value ) . "',";
				$insert_value .= "'" .  $value  . "',";
				$update_str .= $key . " = '" . $value  . "',";
			}
		}
		$insert_key = rtrim ( $insert_key, "," );
		$insert_value = rtrim ( $insert_value, "," );
		$update_str = rtrim ( $update_str, "," );
		$insert_str .= $insert_key . ") values" . "(" . $insert_value . ")  ON DUPLICATE KEY UPDATE $update_str";
		$this->db->query ( $insert_str );
	}
	
	function get_ratedeck_details($pattern){
		$this->db->where ($pattern);
		$query=$this->db_model->select ( "*", "ratedeck","","","","","");
		return $query;
		
	}
}
