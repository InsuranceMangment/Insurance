// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Registration{


    address public regulatory_authority;
    mapping(address => bool)public Physician;
    mapping(address => bool)public Insurance_Company;
    mapping(address=>bool)public Patient;
    mapping(address => bool) public registeredPharmacy;


 event RegistrationSmartContractDepolyer (address regulatory_authority);
 event PhysicianRegistered (address indexed regulatory_authority, address indexed Physician);
 event Insurance_CompanyRegistered (address indexed regulatory_authority, address indexed Insurance_Company);
 event PharmacyRegistered (address indexed regulatory_authority, address indexed Pharmacy);
 event PatientRegistred (address indexed regulatory_authority, address indexed Patient);

//Modifiers
modifier onlyregulatory_authority() {
    require(regulatory_authority == msg.sender, "Only the regulatory authority is permitted to run this function");
    _;
}  
//constructor
constructor() {
    regulatory_authority = msg.sender;
}


//Registration Functions
function PhysicianRegistration (address user) public onlyregulatory_authority {
    require (Physician[user] == false, "The physician is already registered");
    Physician [user] = true;
    emit PhysicianRegistered (msg.sender, address(user));
}
function Insurance_CompanyRegistration (address user) public onlyregulatory_authority {
    require (Insurance_Company[user] == false, "The company is already registered");
    Insurance_Company [user] = true;
    emit Insurance_CompanyRegistered (msg.sender, address(user));
}
function PharmacyRegistration(address _Pharmacy) public onlyregulatory_authority{
registeredPharmacy[_Pharmacy] = true;
emit PharmacyRegistred (msg.sender, address(_Pharmacy));
}

function PatientRegisteration (address user) public onlyregulatory_authority{
    require (Patient[user] == false, "The patient is already registered");
    Patient [user] = true;
    emit PatientRegistred (msg.sender, address(user));
}
}



contract Approval{
    Registration public reg_contract; 
    struct PharmacySelect{ //Used to store and map patients to the Pharmacies they select
    address registeredPharmacy;
    bool isSelected;
    }
    mapping(address => PharmacySelect[]) public PharmaciesSelection; //Links Pharmacys to the patients that selected them
    mapping(address => uint) public selectioncounter;
    enum ApprovalRequstState {Pending, Approved}
    ApprovalRequstState public ApprovalState;
    string internal IPFShash;
    enum InsuranceApprovalStatus {Pending, Approved, Rejected}
    InsuranceApprovalStatus public InsuranceApprovalstatus;
    enum  MedicineCollectionState { ReadyForCollection, Collected} 
    MedicineCollectionState public MedicineCollectionstate;
    enum PaymentState {Pending, Paid}
    PaymentState public Paymentstate;
    uint PatientID;
    uint Drug1CRN; 
    uint Drug2CRN; 
    uint Drug3CRN; 
    uint medicationinvoiceID;
    uint Drugstotalcost; 
    uint PaidAmount; 
  


event PharmacyEligible(address _Pharmacy);
event PharmacyIneligible(address _Pharmacy);
event Approved(address _pharmacy);
event prescriptioniscreated (address Physician, uint PatientID, uint Drug1CRN, uint Drug2CRN, uint Drug3CRN, bytes32 _IPFShash);
event ApprovalIsRequested (address _pharmacy, uint PatientID, uint Drug1CRN, uint Drug2CRN, uint Drug3CRN);
event RequestApproval(address Insurance_Company , uint insuranceApprovalstatus,  uint PatientID, address _Pharmacyaddress);
event RequestRejection (address Insurance_Company , uint insuranceApprovalstatus,  uint PatientID, address _Pharmacyaddress);
event medicationisprepread (address _pharmacy, uint PatientID);
event medicationiscollected (address Patient, uint PatientID, bytes32 _IPFShash );
event PaymentIsRequested (address _pharmacy, uint medicationinvoiceID);
event ClaimIsPaid (address Insurance_Company, uint medicationinvoiceID);


modifier onlyPhysician{
         require (reg_contract.Physician(msg.sender), "only the Physician is allowed to execute this function");
         _;
     }
modifier onlyPatients{
         require (reg_contract.Patient(msg.sender), "only the patient is allowed to execute this function");
         _;
     }

modifier onlyInsurance_Company{
         require (reg_contract.Insurance_Company(msg.sender), "only the insurance company is allowed to execute this function");
         _;
     }

modifier onlyRegisteredPharmacies(){
    require(reg_contract.registeredPharmacy(msg.sender), "only a registered Pharmacy can run this function");
    _;
}



constructor(address RegistrationSCaddress){
    reg_contract = Registration(RegistrationSCaddress);
}

function prescriptionCreation (uint _PatientID, uint _Drug1CRN, uint _Drug2CRN, uint _Drug3CRN, string memory _IPFShash) public onlyPhysician {
      PatientID = _PatientID;
      Drug1CRN = _Drug1CRN;
      Drug2CRN= _Drug2CRN; 
      Drug3CRN= _Drug3CRN; 
      emit prescriptioniscreated(msg.sender, PatientID, Drug1CRN, Drug2CRN, Drug3CRN, bytes32(bytes(_IPFShash)));
        
    }

function selectPharmacy(address _Pharmacyaddress) public onlyPatients{
   
require(selectioncounter[msg.sender]<5);
require(reg_contract.registeredPharmacy(_Pharmacyaddress) == true, "only registered Pharmacys can be selected");

PharmaciesSelection[msg.sender].push(PharmacySelect(_Pharmacyaddress, true)); //The patient selects the desired Pharmacy

selectioncounter[msg.sender] += 1; //This counter is used to ensure that each patient only selects a maximum of 5 Pharmacys
ApprovalState = ApprovalRequstState.Pending;
}

function        PharmacyApproval(address _patient) public onlyRegisteredPharmacies{
       require(ApprovalState == ApprovalRequstState.Pending, "Can't give approval as there is no request");
    for(uint i = 0; i < selectioncounter[_patient]; i++){
        if(PharmaciesSelection[_patient][i].registeredPharmacy == msg.sender && PharmaciesSelection[_patient][i].isSelected == true){
            ApprovalState = ApprovalRequstState.Approved;
            emit PharmacyEligible(msg.sender);
            emit Approved(msg.sender);
        }
        else{
            
            emit PharmacyIneligible(msg.sender);
        }
    }  
}


function RequestInsuranceApproval (uint _PatientID, uint _Drug1CRN, uint _Drug2CRN, uint _Drug3CRN) public onlyRegisteredPharmacies{
    PatientID = _PatientID;
      Drug1CRN = _Drug1CRN;
      Drug2CRN= _Drug2CRN; 
      Drug3CRN= _Drug3CRN; 
      InsuranceApprovalstatus=InsuranceApprovalStatus.Pending;
      emit ApprovalIsRequested (msg.sender, PatientID, Drug1CRN, Drug2CRN, Drug3CRN);

}

function InsuranceApproval (InsuranceApprovalStatus _GivingApproval, address _Pharmacyaddress, uint _PatientID) public onlyInsurance_Company{
    require(reg_contract.registeredPharmacy(_Pharmacyaddress) == true, "only registered Pharmacys can be selected");
    require(InsuranceApprovalstatus==InsuranceApprovalStatus.Pending, "Can't give approval as there is no request");
    PatientID = _PatientID;
         if (_GivingApproval == InsuranceApprovalStatus.Approved){
        
        emit RequestApproval(msg.sender, 1 ,PatientID, address(_Pharmacyaddress) );
    }
        if (_GivingApproval == InsuranceApprovalStatus.Rejected){
        
         emit RequestRejection(msg.sender, 2 , PatientID, address(_Pharmacyaddress));
    }

}

function   medication_prepreation (uint _PatientID) public onlyRegisteredPharmacies{ 
PatientID = _PatientID; 
emit medicationisprepread (msg.sender, PatientID);
MedicineCollectionstate= MedicineCollectionState.ReadyForCollection;
}

function   medication_collection ( uint _PatientID, string memory _IPFShash) public onlyPatients{
require(MedicineCollectionstate==MedicineCollectionState.ReadyForCollection, "Can't collect medication scince it is not ready");
PatientID = _PatientID; 
MedicineCollectionstate= MedicineCollectionState.Collected;
emit medicationiscollected (msg.sender, PatientID, bytes32(bytes(_IPFShash)));
}


function paymentrequest  (uint _medicationinvoiceID, uint _Drugstotalcost) public onlyRegisteredPharmacies{
    Drugstotalcost = _Drugstotalcost;
    medicationinvoiceID = _medicationinvoiceID;
    Paymentstate = PaymentState.Pending;
    emit PaymentIsRequested (msg.sender, medicationinvoiceID);
}

function claimpayment  (uint _medicationinvoiceID) public onlyInsurance_Company payable{
medicationinvoiceID = _medicationinvoiceID;
require(Paymentstate == PaymentState.Pending, "Can't claim payment");
require(msg.value == Drugstotalcost, "Paid Amount is not covering the claim");
Paymentstate = PaymentState.Paid;
emit ClaimIsPaid (msg.sender, medicationinvoiceID);
}
function balanceof  () external view returns(uint) {
    return address(this).balance;
}
}
