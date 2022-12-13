<?php
class New_Invoices_model extends CI_Model {

    private $codeIgniter;

    public function __construct() {
        $this->codeIgniter = &get_instance();
        $this->codeIgniter->load->library('flux/common');
    }

    public function getFilter($invoiceId) {
        $query = $this->db->get_where('invoices', array('id' => $invoiceId));
        $invoice = $query->row();

        $filter = new stdClass();
        $filter->accountid = $invoice->accountid;
        $filter->invoiceid = $invoice->id;
        //$filter->notes = $invoice->invoice_note;
        $filter->notes = $invoice->notes;
        $filter->fromdate = DateTime::createFromFormat('Y-m-d H:i:s', $invoice->from_date);
        $filter->fromdate->setTime(0, 0, 0);

        $filter->todate = DateTime::createFromFormat('Y-m-d H:i:s', $invoice->to_date);
        $filter->todate->setTime(23, 59, 59);

        return $filter;
    }

    /*public function getCalls($filter) {
        $query = $this->db->get_where('cdrs', array(
            'accountid' => $filter->accountid,
            'callstart >=' => $filter->fromdate->format('Y-m-d H:i:s'),
            'callstart <=' => $filter->todate->format('Y-m-d H:i:s'),
            'calltype' => 'STANDARD',
            'disposition' => 'NORMAL_CLEARING',
            'debit >' => 0,
            'billseconds >' => 0,
            'invoiceid' => 0
        ));

        $cdrs = $query->result_object();

        $numbers = array();

        foreach ($cdrs as $key => $cdr) {
            $number = preg_replace("/[^0-9]/", '', explode(' ', $cdr->callerid)[0]);

            if (!isset($numbers[$number])) {
                $numbers[$number] = new stdClass();
                $numbers[$number]->number = $number;
                $numbers[$number]->calls = array();
                $numbers[$number]->callsDuration = 0.00;
                $numbers[$number]->callsValue = 0.00;
                $numbers[$number]->lineNumber = count($numbers);
            }

            $call = new stdClass();

            $call->destinationPhone = preg_replace("/[^0-9]/", "", $cdr->callednum);
            $call->destinationType = $cdr->notes;

            $call->date = DateTime::createFromFormat('Y-m-d H:i:s', $cdr->callstart);
            $call->date = $call->date->format('d/m/Y H:i:s');

            $call->duration = $cdr->billseconds;
            $call->durationFormatted = gmdate('H:i:s', $call->duration);

            $call->value = $cdr->debit;

            $numbers[$number]->calls[] = $call;
            $numbers[$number]->callsDuration += $call->duration;
            $numbers[$number]->callsValue += $call->value;
        }

        foreach ($numbers as $number) {
            $number->callsDurationFormatted = gmdate('H:i:s', $number->callsDuration);
        }

        return array_values($numbers);
    }*/

    public function getCalls($filter) {
        $query = $this->db->get_where('cdrs', array(
            'accountid' => $filter->accountid,
            'callstart >=' => $filter->fromdate->format('Y-m-d H:i:s'),
            'callstart <=' => $filter->todate->format('Y-m-d H:i:s'),
            'calltype <>' => 'FREE',
            'calltype NOT LIKE' => '%Gratuita%',
            //ALTERACAO NOT IN ('FREE','Gratuita')
            //'call_direction' => 'outbound',
            //'disposition' => 'NORMAL_CLEARING [16]',
            'debit >' => 0,
            'billseconds >' => 0,
            'invoiceid' => 0
        ));

        $cdrs = $query->result_object();

        $numbers = array();

        foreach ($cdrs as $key => $cdr) {
            $number = preg_replace("/[^0-9]/", '', explode(' ', $cdr->callerid)[0]);

            if (!isset($numbers[$number])) {
                $numbers[$number] = new stdClass();
                $numbers[$number]->number = $number;
                $numbers[$number]->calls = array();
                $numbers[$number]->callsDuration = 0.00;
                $numbers[$number]->callsValue = 0.00;
                $numbers[$number]->lineNumber = count($numbers);
            }

            $call = new stdClass();

            $call->destinationPhone = preg_replace("/[^0-9]/", "", $cdr->callednum);
            $call->destinationType = $cdr->calltype;

            $call->date = DateTime::createFromFormat('Y-m-d H:i:s', $cdr->callstart);
            $call->date = $call->date->format('d/m/Y H:i:s');

            $call->duration = $cdr->billseconds;
            $call->durationFormatted = gmdate('H:i:s', $call->duration);

            $call->value = $cdr->debit;

            $numbers[$number]->calls[] = $call;
            $numbers[$number]->callsDuration += $call->duration;
            $numbers[$number]->callsValue += $call->value;
        }

        foreach ($numbers as $number) {
            $number->callsDurationFormatted = gmdate('H:i:s', $number->callsDuration);
        }

        return array_values($numbers);
    }

/*public function getManual($filter) {
 $query = $this->db->get_where('invoice_details', array(
           'invoiceid' => $invoiceId,
            'generate_type' => '1'
            ));
    $manual = $query->result_object();



}*/

   /* public function getPlans($filter) {
        $this->db->select('charges.*');
        $this->db->from('accounts');
        $this->db->join('charges', 'charges.pricelist_id = accounts.pricelist_id');
        $this->db->where('accounts.id', $filter->accountid);

        $query = $this->db->get();
        $charges = $query->result_object();

        $plans = array();

        foreach ($charges as $charge) {
            $plan = new stdClass();
            $plan->name = $charge->description;
            $plan->value = $this->codeIgniter->common->convert_to_currency('', '', $charge->charge);
            $plans[] = $plan;
        }

        return $plans;
    }*/
public function getPlans($filter) {
        $this->db->select('*');
        $this->db->from('packages_view');
       // $this->db->join('packages_view', 'packages_view.pricelist_id = accounts.pricelist_id');
        $this->db->where('accountid', $filter->accountid);

        $query = $this->db->get();
        $charges = $query->result_object();

        $plans = array();

        foreach ($charges as $charge) {
            $plan = new stdClass();
            $plan->name = $charge->package_name;
            $plan->value = $this->codeIgniter->common->convert_to_currency('', '', $charge->price);
            $plans[] = $plan;
        }

        return $plans;
    }
    /*public function getPackages($filter) {
        $this->db->select('packages.*');
        $this->db->from('packages');
        $this->db->join('accounts', 'accounts.pricelist_id = packages.pricelist_id');
        $this->db->where(array(
            'accounts.id' => $filter->accountid,
            'packages.status' => '0'
        ));

        $query = $this->db->get();
        $packages = $query->result_object();

        $invoicePackages = array();

        foreach ($packages as $package) {
            $invoicePackage = new stdClass();
            $invoicePackage->name = $package->package_name;
            $invoicePackage->minutes = gmdate('i:s', $package->includedseconds);

            $counters = $this->db->get_where('counters', array('package_id' => $package->id))->result_object();

            if (empty($counters)) {
                $invoicePackage->usedMinutes = '00:00';
            } else {
                $invoicePackage->usedMinutes = gmdate('i:s', $counters[0]->seconds);
            }

            $invoicePackages[] = $invoicePackage;
        }

        return $invoicePackages;
    }*/
    public function getPackages($filter) {
        $this->db->select('packages_view.*');
        $this->db->from('packages_view');
        $this->db->join('accounts', 'accounts.id = packages_view.accountid');
        $this->db->where(array(
            'accounts.id' => $filter->accountid,
            'packages_view.status' => '0'
        ));

        $query = $this->db->get();
        $packages = $query->result_object();

        $invoicePackages = array();

        foreach ($packages as $package) {
            $invoicePackage = new stdClass();
            $invoicePackage->name = $package->package_name;
            $invoicePackage->minutes = gmdate('i:s', $package->free_minutes);

            $counters = $this->db->get_where('counters', array('package_id' => $package->id))->result_object();

            if (empty($counters)) {
                $invoicePackage->usedMinutes = '00:00';
            } else {
                $invoicePackage->usedMinutes = gmdate('i:s', $counters[0]->used_seconds);
            }

            $invoicePackages[] = $invoicePackage;
        }

        return $invoicePackages;
    }

    public function findAccount($accountid) {
        $query = $this->db->get_where('accounts', array(
            'id' => $accountid
        ));

        return $query->row();
    }

    public function getCustomer($filter) {
        $account = $this->findAccount($filter->accountid);

        $invoiceAccount = new stdClass();
		$invoiceAccount->accountNumber = $account->number;
		$invoiceAccount->companyName = $account->company_name;
        $invoiceAccount->name = (!empty($account->company_name) ? $account->company_name : trim("{$account->first_name} {$account->last_name}"));
        $invoiceAccount->address = (!empty($account->address_1) ? $account->address_1 : $account->address_2);
        $invoiceAccount->city =  $account->city;
        $invoiceAccount->province =  $account->province;
        $invoiceAccount->postalCode =  $account->postal_code;

		$invoiceAccount->cityProvince = "";

		if (!empty($invoiceAccount->city)) {
			$invoiceAccount->cityProvince = $invoiceAccount->city;
		}

		if (!empty($invoiceAccount->province)) {
			if (!empty($invoiceAccount->cityProvince)) {
				$invoiceAccount->cityProvince .= " - ";
			}

			$invoiceAccount->cityProvince .= $invoiceAccount->province;
		}

        return $invoiceAccount;
    }

    public function getCompany($filter) {
        $this->db->select('*');
        $this->db->from('invoice_conf');
        $this->db->where("accountid in ({$filter->accountid}, 1)");
        $this->db->order_by('accountid', 'desc');
        $this->db->limit(1);

        $query = $this->db->get();
        return $query->row();
    }

    public function getCompanyLogo($filter) {
        $company = $this->getCompany($filter);
        $companyPath = (FCPATH . "upload/{$company->logo}");

        if (empty($company->logo) || (!empty($company->logo) && !file_exists($companyPath))) {
            return (FCPATH . '/upload/logo.png');
        }

        return $companyPath;
    }

    public function getExpirationDate($filter) {
        $company = $this->getCompany($filter);

        if ($company->interval > 0) {
            return gmdate("d/m/Y", strtotime($filter->todate->format("Y-m-d H:i:s") . " +" . $company->interval . " days"));
        }

        return gmdate("d/m/Y", strtotime($filter->todate->format("Y-m-d H:i:s") . " +7 days"));
    }

    public function getRange($filter) {
        $account = $this->findAccount($filter->accountid);

        if (!($account->expiry instanceof DateTime)) {
            $account->expiry = DateTime::createFromFormat('Y-m-d H:i:s', $account->expiry);
        }

        if (!($account->first_used instanceof DateTime)) {
            $account->first_used = DateTime::createFromFormat('Y-m-d H:i:s', $account->first_used);
        }

        $range = new stdClass();
        //$range->beginDate = ((!empty($account->first_used) && $filter->fromdate < $account->first_used) ? $account->first_used : $filter->fromdate);
        //$range->endDate = ((!empty($filter->expiry) && $filter->todate > $filter->expiry && $filter->fromdate < $filter->expiry) ? $filter->expiry
          //  : $filter->todate);
        $range->beginDate = $filter->fromdate;
        $range->endDate = $filter->todate;

        $range->beginDate = $range->beginDate->format('d/m/Y');
        $range->endDate = $range->endDate->format('d/m/Y');

        return $range;
    }

    public function summarize($filter, $invoice) {
        $invoice->range = $this->getRange($filter);
        $invoice->expirationDate = $this->getExpirationDate($filter);

        $invoice->total = 0.00;

        $summary = array();
        $summary[] = $this->calculateTotalPlans($invoice);
        $summary[] = $this->calculateTotalCalls($invoice);
        $summary[] = $this->calculateTaxes($invoice);

        return $summary;
    }


    public function summarizeMan($filter, $invoice) {
        $invoice->range = $this->getRange($filter);
        $invoice->expirationDate = $this->getExpirationDate($filter);

        $invoice->total = 0.00;

        $summary = array();
        $summary[] = $this->calculateTotalPlansMan($invoice);
        $summary[] = $this->calculateTotalCalls($invoice);
        $summary[] = $this->calculateTaxesMan($invoice,$filter);

        return $summary;
    }

    private function calculateTotalCalls($invoice) {
        $summaryCalls = new stdClass();
        $summaryCalls->label = "Ligações excedentes";
        $summaryCalls->value = 0.00;

        $invoice->totalCallsDurantion = 0;

        foreach ($invoice->numbers as $number) {
            $summaryCalls->value += $number->callsValue;
            $invoice->totalCallsDurantion += $number->callsDuration;
        }

        $invoice->totalCallsValue = $summaryCalls->value;
        $invoice->totalCallsDurationFormatted = gmdate('H:i:s', $invoice->totalCallsDurantion);

        $invoice->total += $summaryCalls->value;

        return $summaryCalls;
    }

    private function calculateTotalPlans($invoice) {
        $summaryPlans = new stdClass();
        $summaryPlans->label = "Assinatura";
        $summaryPlans->value = 0.00;
        $summaryPlans->description = array();

        foreach ($invoice->plans as $plan) {
            $summaryPlans->value += $plan->value;
            $summaryPlans->description[] = $plan->name;
        }

        $summaryPlans->description = join(", ", $summaryPlans->description);
        $invoice->total += $summaryPlans->value;

        return $summaryPlans;
    }
    
    
    private function calculateTotalPlansMan($invoice) {
        $summaryPlans = new stdClass();
        $summaryPlans->label = "Assinatura";
        $summaryPlans->value = 0.00;
        $summaryPlans->description = array();

        foreach ($invoice->plans as $plan) {
        //    $summaryPlans->value += $plan->value;
            $summaryPlans->description[] = $plan->name;
        }

        $summaryPlans->description = join(", ", $summaryPlans->description);
        $invoice->total += $summaryPlans->value;

        return $summaryPlans;
    }
    
private function calculateTaxesMan($invoice,$filter) {
        $summaryTaxes = new stdClass();
        $summaryTaxes->label = "Invoice Manual";
        $summaryTaxes->value = 0.00;
        $summaryTaxes->description = array();

        //$query = $this->db->get('taxes');
        //$taxes = $query->result_object();
        $this->db->select('*');
        $this->db->from('view_new_invoices');
        $this->db->where(array(
            'accountid' => $filter->accountid,
            'id' => $filter->invoiceid
        ));
        $this->db->limit(1);
        $query = $this->db->get();
        $taxes = $query->result_object();

        foreach ($taxes as $tax) {
            $summaryTaxes->value = $tax->invoice_total;
            //$summaryTaxes->description[] = $tax->taxes_description;
        }
       /* foreach ($manual as $man) {
            $invoice->total += ($invoice->total + ($man->invoice_total));
        }*/

        $summaryTaxes->description = join(", ", $summaryTaxes->description);
        $invoice->total += $summaryTaxes->value;

        return $summaryTaxes;
    }

    private function calculateTaxes($invoice) {
        $summaryTaxes = new stdClass();
        $summaryTaxes->label = "Impostos";
        $summaryTaxes->value = 0.00;
        $summaryTaxes->description = array();

        $query = $this->db->get('taxes');
        $taxes = $query->result_object();
       

        foreach ($taxes as $tax) {
            $summaryTaxes->value = ($invoice->total * ($tax->taxes_rate/100));
            $summaryTaxes->description[] = $tax->taxes_description;
        }

        $summaryTaxes->description = join(", ", $summaryTaxes->description);
        $invoice->total += $summaryTaxes->value;

        return $summaryTaxes;
    }

}