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
class Voice_broadcast extends CI_Controller {
	function __construct() {
		parent::__construct ();
		$this->load->library('flux/permission');
		$this->load->library("flux/common");
		$this->load->model('db_model');
		$this->load->library('freeswitch_lib');
	}
	public function voice_broadcast() {
		$response_arr = array();
        $where = array("status"=>'1');
	    $voice_broadcast_res =(array) $this->db->get_where( "voice_broadcast", $where)->result_array();
		if(!empty($voice_broadcast_res)){
			foreach($voice_broadcast_res as $key => $value){
				if($value['status'] == '1' ){
					$where = array("id"=>$value['accountid']);
					$account_res =(array) $this->db->get_where( "accounts", $where)->first_row();
					$where1 = array("id"=>$value['sip_device_id']);
					$sipdevice_res =(array) $this->db->get_where( "sip_devices", $where1)->first_row();
					$var = $sipdevice_res['dir_vars'];
					$dir_vars = (array)json_decode($var);
					$name = !empty($dir_vars) ? $dir_vars['effective_caller_id_name'] : (!empty($dir_vars) ? $dir_vars['effective_caller_id_number'] : $sipdevice_res['username']);
					$number = !empty($dir_vars) ? $dir_vars['effective_caller_id_number'] : $sipdevice_res['username'];
					$destination_number = explode(",",$value['destination_number']);
					$domain = $this->common->get_field_name('value','system',array('name'=>'voice_broadcast_host'));
					$domain_explode = explode(',',$domain);

					if (count($domain_explode) > 1){
						$freeswitch_key=array_rand($domain_explode);
						$fs_server = ( array ) $this->db->get_where ( "freeswich_servers",array ("status"=>0,"freeswitch_host" => $domain_explode[$freeswitch_key]))->first_row ();
						$host = $fs_server['freeswitch_host'];
						$password = $fs_server['freeswitch_password'];
						$port = $fs_server['freeswitch_port'];
						$domain = $domain_explode[$freeswitch_key];
					}else{
						$fs_server = ( array ) $this->db->get_where ( "freeswich_servers",array ("status"=>0))->first_row ();
						$host = $fs_server['freeswitch_host'];
						$password = $fs_server['freeswitch_password'];
						$port = $fs_server['freeswitch_port'];
					}
					$this->db->update ( "voice_broadcast", array ("status" => 0), array ("id" => $value['id']));
					$voice_broadcast_port = $this->common->get_field_name('value','system',array('name'=>'voice_broadcast_port'));
					foreach($destination_number as $dest_number){
						$originate_str="api originate {sip_h_P-Voice_broadcast=true,ignore_early_media=true,sip_h_P-Accountcode=".$account_res['number'].",sip_h_P-cb_destination=".$dest_number.",sip_h_P-cb_source=".$dest_number.",variable_effective_caller_id_name=".$dest_number.",origination_caller_id_number=".$dest_number.",effective_caller_id_number=".$dest_number.",Caller-Destination-Number=".$dest_number.",Hunt-Orig-Caller-ID-Number=".$dest_number.",Hunt-Callee-ID-Name=".$dest_number.",sip_h_P-Voice_broadcast_type=".$sipdevice_res['username']."}sofia/default/".$dest_number."@".$domain.":".$voice_broadcast_port." &playback(/opt/flux/web_interface/flux/upload/voice_broadcast/".$value['broadcast'].") xml public ".$number." ".$number." 40";
						$this->reload_freeswitch($originate_str);
					}
					$this->db->update ( "voice_broadcast", array ("status" => 2), array ("id" => $value['id']));
					$response_arr = array ('status' => 'true', 'Please wait, Your call is on the way.',200);
				}else{
					$response_arr = array ('status' => false,'error' => 'Requested service is already completed.',400);
				}
			}
		}else{
			$response_arr = array ('status' => false,'error' => 'Invalid Voice Broadcast found.',400);
		}
		echo json_encode($response_arr);
	}
 	function reload_freeswitch($command){
        $response = '';
        $query = $this->db_model->getSelect("*", "freeswich_servers", array('status'=>0));
        $fs_data = $query->result_array();
        foreach ($fs_data as $fs_key => $fs_value) {
            $fp = $this->freeswitch_lib->event_socket_create($fs_value["freeswitch_host"], $fs_value["freeswitch_port"], $fs_value["freeswitch_password"]);
            if ($fp) {
                $response .= $this->freeswitch_lib->event_socket_request($fp, $command);
                fclose($fp);
            }
        }
        return $response;
    }
}