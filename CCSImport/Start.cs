using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects;
using CCSBusinessObjects.InputTransforms;
using CCSBusinessObjects.Services;
using CCSBusinessObjects.Utility;
using System;
using System.Linq;
using System.Net;

namespace CCSImport
{
	/// <summary>
	/// Summary description for Start.
	/// </summary>
	public class Start
    {
		#region constants

		public const string RUN_IMPORT_FILE_ARCHIVE = "A";
        public const string RUN_DAILY_PRODUCTION_REPORT = "D";
        public const string RUN_EXPORT = "E";
        public const string RUN_CAMC_DISCHARGE_IMPORT = "H";
        public const string RUN_IMPORT = "I";
        public const string RUN_EMAIL_IMPORT = "M";
        public const string RUN_EMAIL_EXPORT = "EE";
        public const string RUN_REGISTRATION_ONLY_REPORT = "RO";
        public const string RUN_IMPORT_IMAGES = "II";
        public const string RUN_DECRYPT = "DC";
        public const string RUN_ENCRYPT = "EC";
        public const string RUN_SQL = "XS";
        public const string RUN_BUILD_VERIFICATION_TEST = "TST";
        public const string RUN_IMAGE_EXPORT_FOR_DATE_RANGE = "XIDT";
        public const string RUN_DAILY_DUPLICATE_PATIENT_REPORT = "DPL";
        public const string RUN_WEEKLY_PREBILL_AUDIT_ABSTRACT = "WPA";
        public const string RUN_CHART_RECAP_REPORTS = "CRR";
        public const string RUN_DAILY_LATE_FILES_REPORT = "DLFR";
        public const string RUN_WEEKLY_PREBILL_AUDIT_ABSTRACT_FOR_DATE_RANGE = "WPAFDR";
        public const string RUN_DAILY_NO_STOP_TIME_REPORT = "DNSTR";
        public const string RUN_PURGE_OLD_IMAGES = "PI";
        public const string RUN_CHART_RECAP_REPORT_AS_OF_LAST_RUN_DATE = "CRRLRD";
        public const string RUN_PURGE_OLD_IMAGES_FOR_ALL_FACILITIES = "PIA";
        public const string RUN_CHARGE_POSTING_SERVICE = "CPOST";
        public const string RUN_ABSTRACT_PROCEDURE_UPDATE = "APU";
        public const string RUN_CHART_RECAP_REPORT_GIVEN_DATE_RANGE = "CRRDR";
        public const string RUN_RIVERVIEW_IMPORT = "RRI";
        public const string RUN_DATA_CONVERSION_SERVICE = "DCS";
        public const string RUN_SHAWNEE_MISSION_CHARGE_IMPORT = "SMCI";
        public const string RUN_NORTHWESTERN_PHYSICIAN_APPROVAL_FILE_IMPORT = "NWAF";
        public const string RUN_AUTO_APPROVE = "AUTOAPPROVE";
        public const string RUN_REASSIGN_WORK_IN_PROGRESS_TO_UNASSIGNED = "ASSIGN_TO_UNASSIGNED";
        public const string RUN_CCHMC_LOAD_PHYSICIAN_SIGNATURE_FILE = "CCHMC_LOAD_PHYS_SIG";
        public const string RUN_CCHMC_ED_BASE_PHYSICIAN_SIGNATURE_FILE_IMPORT = "CCHMC_ED_BASE_PHYS_SIG";
        public const string RUN_CCHMC_UC_MASON_PHYSICIAN_SIGNATURE_FILE_IMPORT = "CCHMC_UC_MASON_PHYS_SIG";
        public const string RUN_CCHMC_ED_LIBERTY_PHYSICIAN_SIGNATURE_FILE_IMPORT = "CCHMC_ED_LIBERTY_PHYS_SIG";
        public const string RUN_CCHMC_UC_ANDERSON_PHYSICIAN_SIGNATURE_FILE_IMPORT = "CCHMC_UC_ANDERSON_PHYS_SIG";
        public const string RUN_CCHMC_UC_FAIRFIELD_PHYSICIAN_SIGNATURE_FILE_IMPORT = "CCHMC_UC_FAIRFIELD_PHYS_SIG";
        public const string RUN_CCHMC_LOAD_TRANSFER_TO_BASE_FILE = "CCHMC_LOAD_TRANSFER_TO_BASE";
        public const string RUN_CCHMC_TRANSFER_TO_BASE_FILE_IMPORT = "CCHMC_IMPORT_TRANSFER_TO_BASE";
        public const string RUN_MASS_UPDATE_CHARTS_PHYSICIAN_ID = "MASS_UPDATE_PHYSICIAN_ID";
        public const string RUN_MASS_UPDATE_CHARTS_DISPOSITION_IDS = "MASS_UPDATE_DISPOSITION_IDS";
        public const string RUN_CHMC_LOAD_CHARGE_POSTING_DATA = "CHMC_LOAD_CHARGE_POSTING_DATA";
        public const string RUN_PRINCETON_OBS_DISCHARGE_IMPORT = "PRINCETON_OBS_DISCHARGE";
        public const string RUN_PRINCETON_RECON_REPORT = "PRINCETON_RECON_REPORT";
        public const string RUN_PRINCETON_UNATTACHED_IMAGES = "PRINCETON_UNATTACHED_IMAGES";
        public const string RUN_ACH_RECON_REPORT = "ACH_RECON_REPORT";
        public const string RUN_ACH_RECON_GET_MAIL = "ACH_RECON_GET_MAIL";
        public const string RUN_NMH_RECON_REPORT = "NMH_RECON_REPORT";
        public const string RUN_NYP_LOAD_CHARGE_POSTING_DATA = "NYP_RECON_REPORT";
        public const string RUN_CCHMC_RECON_REPORT = "CCHMC_RECON_REPORT";
        public const string RUN_RGH_RECON_REPORT = "RGH_RECON_REPORT";
        public const string RUN_PRMC_RECON_REPORT = "PRMC_RECON_REPORT";
        public const string RUN_COMBINE_FILES_INTO_ONE = "COMBINE_FILES_INTO_ONE";
        public const string RUN_COMBINE_FILES_INTO_ONE_USING_WRITE_FILE = "COMBINE_FILES_INTO_ONE_USING_WRITE_FILE";
        public const string RUN_CCI_EDITS_IMPORT = "CCI_EDITS_IMPORT";
        public const string RUN_CMS_DATA_IMPORT = "CMS_LCD_IMPORT";
        public const string RUN_CMS_LAB_CODE_IMPORT = "CMS_LAB_CODE_IMPORT";
        public const string RUN_CHOA_RECON_REPORT = "CHOA_RECON_REPORT";
        public const string RUN_LOAD_CMS_LAB_CODE_LIST = "LOAD_CMS_LAB_CODE_LIST";
        public const string RUN_LOAD_CHOA_WORK_QUEUE_DATA = "LOAD_CHOA_WORK_QUEUE_DATA";
        public const string RUN_HASH_USER_PROFILE_PASSWORDS = "HASH_USER_PROFILE_PASSWORDS";
        public const string RUN_LIFEPOINT_ATHENS_OBS_DISCHARGE_IMPORT = "LIFEPOINT_ATHENS_OBS_DISCHARGE";
        public const string RUN_LIFEPOINT_ATHENS_CLINIC_DISCHARGE_IMPORT = "LIFEPOINT_ATHENS_CLINIC_DISCHARGE";
        public const string RUN_LIFEPOINT_IMPORT_BILLING_LIST = "LIFEPOINT_IMPORT_BILLING_LIST";
        public const string RUN_LIFEPOINT_UPDATE_BILLING_LIST = "LIFEPOINT_UPDATE_BILLING_LIST";
        public const string RUN_NYP_ACN_CHART_IMPORT = "NYP_ACN_CHART_IMPORT";
        public const string RUN_INACTIVATE_UNUSED_USER_ACCOUNTS = "INACTIVATE_UNUSED_USER_ACCOUNTS";
        public const string RUN_IMPORT_CHOA_IBEX_DOWNLOAD = "IMPORT_CHOA_IBEX_DOWNLOAD";
        //public const string RUN_CODER_BILLING_PROCESS = "CODER_BILLING_PROCESS";
        public const string RUN_CODER_BILLING_EXTRACT = "CODER_BILLING_EXTRACT";
        public const string RUN_UPDATE_REPORT_ITEM_TABLE = "UPDATE_REPORT_ITEM_TABLE";
        public const string RUN_IMPORT_GRANT_MEMORIAL_BILLING_LIST = "IMPORT_GRANT_MEMORIAL_BILLING_LIST";
        public const string RUN_IMPORT_MEDITECH_BILLING_LIST = "IMPORT_MEDITECH_BILLING_LIST";
        //public const string RUN_SPLIT_MULTI_IMAGE_FILE = "SPLIT_MULTI_IMAGE_FILE";
        public const string RUN_IMAGE_IMPORT_NO_BARCODES = "IMPORT_IMAGES_NO_BARCODES";
        public const string RUN_IMAGE_IMPORT_EV_RTF_NO_BARCODES = "IMPORT_IMAGES_EV_RTF_NO_BARCODES";
        public const string RUN_IMAGE_IMPORT_EV_RTF_ACCOUNT_NUMBER_IN_FILE_NAME = "IMPORT_IMAGES_EV_RTF_ACCOUNT_NUMBER_IN_FILE_NAME";
        public const string RUN_IMAGE_IMPORT_EV_PDF_ACCOUNT_NUMBER_IN_FILE_NAME = "IMPORT_IMAGES_EV_PDF_ACCOUNT_NUMBER_IN_FILE_NAME";
        public const string RUN_IMAGE_IMPORT_EV_EXPANDED_PDF_ACCOUNT_NUMBER_IN_FILE_NAME = "IMPORT_IMAGES_EV_EXPANDED_PDF_ACCOUNT_NUMBER_IN_FILE_NAME";
        public const string RUN_IMAGE_IMPORT_VARIABLE_ACCOUNT_NUMBER_IN_FILENAME = "IMPORT_IMAGES_VARIABLE_ACCOUNT_NUMBER_IN_FILENAME";
        public const string RUN_IMAGE_IMPORT_VARIABLE_ACCOUNT_NUMBER_IN_FILENAME_COMBINED = "IMPORT_IMAGES_VARIABLE_ACCOUNT_NUMBER_IN_FILENAME_COMBINED";
        public const string RUN_IMAGE_IMPORT_VARIABLE_ACCOUNT_NUMBER_WITH_DOS_IN_FILENAME = "IMPORT_IMAGES_VARIABLE_ACCOUNT_NUMBER_WITH_DOS_IN_FILENAME";
        public const string RUN_IMAGE_IMPORT_VARIABLE_ACCOUNT_NUMBER_IN_FILENAME_NO_TIF_CONVERSION = "IMPORT_IMAGES_VARIABLE_ACCOUNT_NUMBER_IN_FILENAME_NO_TIF_CONVERSION";
        public const string RUN_IMAGE_IMPORT_VARIABLE_ACCOUNT_NUMBER_IN_FILENAME_COMBINED_NO_TIF_CONVERSION = "IMPORT_IMAGES_VARIABLE_ACCOUNT_NUMBER_IN_FILENAME_COMBINED_NO_TIF_CONVERSION";
        public const string RUN_IMAGE_IMPORT_WITH_RIVERCITY_TRANSFORM = "IMPORT_IMAGES_WITH_RIVERCITY_TRANSFORM";
        //public const string RUN_IMAGE_IMPORT_TIF_OCR_MRN_TRANSFORM = "IMPORT_IMAGES_TIF_OCR_MRN_TRANSFORM";
        public const string RUN_IMAGE_IMPORT_SPECIAL_NAPA_TRANSFORM = "IMPORT_IMAGES_SPECIAL_NAPA_TRANSFORM";
        public const string RUN_NAPA_DICTATION_FILE_MOVE_TO_PENDING_TRANSFORM = "NAPA_DICTATION_FILE_MOVE_TO_PENDING_TRANSFORM";
        public const string RUN_NYP_OSP_CHART_IMPORT = "NYP_OSP_CHART_IMPORT";
        public const string RUN_CHOA_PNP_LIST_DATA_LOAD = "CHOA_PNP_LIST_DATA_LOAD";
        public const string RUN_IMPORT_ADT_FILE_SERVICE = "IMPORT_ADT_FILE_SERVICE";
        public const string RUN_REPORT_SCHEDULER_SERVICE = "REPORT_SCHEDULER_SERVICE";
        public const string RUN_IMPORT_TCH_RECONCILIATION_SERVICE = "IMPORT_TCH_RECONCILIATION_SERVICE";
        public const string RUN_FAILED_REPORT_SUBSCRIPTIONS = "FAILED_REPORT_SUBSCRIPTIONS";
        public const string RUN_ROANE_DISCHARGE_FILES_IMPORT = "ROANE_DISCHARGE_FILES_IMPORT";
        public const string RUN_PEMA_BILLING_REPORT_SPLIT = "PEMA_BILLING_REPORT_SPLIT";
        public const string RUN_IMPORT_CHOA_ASAP_CHARGES_SERVICE = "IMPORT_CHOA_ASAP_CHARGES_SERVICE";
        public const string RUN_IMPORT_OBS_CENSUS_FILE = "IMPORT_OBS_CENSUS_FILE";
        public const string RUN_ST_ANTHONY_OB_CLINIC_IMPORT_OBS_CENSUS_FILE = "IMPORT_OBS_CENSUS_FILE_ST_ANTHONY_OB_CLINIC";
        public const string RUN_IMPORT_DISCHARGE_FILE = "IMPORT_DISCHARGE_FILE";
        public const string RUN_PROCESS_UNATTACHED_IMAGES = "PROCESS_UNATTACHED_IMAGES";
        public const string RUN_COMBINE_EXCEL_FILES = "COMBINE_EXCEL_FILES";
        public const string RUN_IMPORT_CMS_ADDENDUM_SERVICE = "IMPORT_CMS_ADDENDUM_SERVICE";
        public const string RUN_UPDATE_REPORT_ID_SERVICE = "UPDATE_REPORT_ID_SERVICE";
        public const string RUN_IMPORT_ST_ANTHONY_RECON_SERVICE = "IMPORT_ST_ANTHONY_RECON_SERVICE";
        public const string RUN_IMPORT_GE_TICKET_NUMBER_ASSIGNMENT_SERVICE = "IMPORT_GE_TICKET_NUMBER_ASSIGNMENT_SERVICE";
        public const string RUN_COMBINE_MULTIPLE_EXCEL_FILES_FOR_SAME_FACILITY = "COMBINE_MULTIPLE_EXCEL_FILES_FOR_SAME_FACILITY";
        public const string RUN_IMPORT_EPIC_ASAP_CHARGES_SERVICE = "IMPORT_EPIC_ASAP_CHARGES_SERVICE";
        public const string RUN_CHANGE_INPATIENT_PENDING_AWAITING_DISCHARGE_TO_WORK_IN_PROGRESS = "CHANGE_INPATIENT_PENDING_AWAITING_DISCHARGE_TO_WORK_IN_PROGRESS";
        public const string RUN_CREATE_WAYNE_MEMORIAL_ADDITIONAL_DATA_SPREADSHEET = "CREATE_WAYNE_MEMORIAL_ADDTL_DATA_SPREADSHEET";
        public const string RUN_IMPORT_WAYNE_MEMORIAL_ADDITIONAL_DATA_SPREADSHEET = "IMPORT_WAYNE_MEMORIAL_ADDTL_DATA_SPREADSHEET";
        public const string RUN_MOVE_CHARTS_TO_WORK_IN_PROGRESS_SERVICE = "MOVE_CHARTS_TO_WORK_IN_PROGRESS_SERVICE";
        public const string RUN_MOVE_PENDING_NO_EMR_CHARTS_TO_WORK_IN_PROGRESS = "MOVE_PENDING_NO_EMR_CHARTS_TO_WORK_IN_PROGRESS";
        public const string RUN_CHARGE_AMOUNT_UPDATE_ALERT_SERVICE = "CHARGE_AMOUNT_UPDATE_ALERT_SERVICE";
        public const string RUN_IMPORT_ASA_PHYSICIAN_CHARGES_SERVICE = "IMPORT_ASA_PHYSICIAN_CHARGES_SERVICE";
        public const string RUN_IMPORT_LSS_BILLING_LIST = "IMPORT_LSS_BILLING_LIST";
        public const string RUN_IMPORT_ESP_BILLING_LIST = "IMPORT_ESP_BILLING_LIST";
        public const string RUN_STATUS_FEEDBACK_REPORT = "STATUS_FEEDBACK_REPORT";
        public const string RUN_IMPORT_CHARGE_RECON_SERVICE = "IMPORT_CHARGE_RECON_SERVICE";
        public const string RUN_CONVERT_TO_EXCEL_2003_FORMAT_SERVICE = "CONVERT_TO_EXCEL_2003_FORMAT_SERVICE";
        public const string RUN_IMPORT_CABELL_HUNTINGTON_REPORTING_DATA = "IMPORT_CABELL_HUNTINGTON_REPORTING_DATA";
        public const string RUN_CHILDRENS_MERCY_PHYSICIAN_SIGNOFF_SERVICE = "CHILDRENS_MERCY_PHYSICIAN_SIGNOFF_SERVICE";
        public const string RUN_PHYSICIAN_SIGNOFF_SERVICE = "PHYSICIAN_SIGNOFF_SERVICE";
        public const string RUN_CONE_PHYSICIAN_SIGNOFF_SERVICE = "CONE_PHYSICIAN_SIGNOFF_SERVICE";
        public const string RUN_WILLIAMSBURG_RECON_REPORT = "WILLIAMSBURG_RECON_REPORT";
        public const string RUN_IMPORT_VISIT_RECON_SERVICE = "IMPORT_VISIT_RECON_SERVICE";
        public const string RUN_UPDATE_DOWNCODE_DATA_FOR_DATERANGE = "UPDATE_DOWNCODE_DATA_FOR_DATERANGE";
        public const string RUN_COPY_IMAGES_FOR_ACCOUNT_SERVICE = "COPY_IMAGES_FOR_ACCOUNT_SERVICE";
        public const string RUN_CREATE_CHARTS_PENDING_WORKSHEET = "CREATE_CHARTS_PENDING_WORKSHEET";
        public const string RUN_MEDSTAR_DISCHARGE_FILES_IMPORT = "MEDSTAR_DISCHARGE_FILES_IMPORT";
        public const string RUN_TCH_DENVER_UPDATE_PATIENT_CLASS_SERVICE = "TCH_DENVER_UPDATE_PATIENT_CLASS_SERVICE";
        public const string RUN_COMBINE_MULTIPLE_TXT_FILES_WITH_HEADER = "COMBINE_MULTIPLE_TXT_FILES_WITH_HEADER";
        public const string RUN_UPDATE_PENDING_REASON_SERVICE = "UPDATE_PENDING_REASON_SERVICE";
        public const string RUN_IMPORT_UNBILLED_CHART_RECON_SERVICE = "IMPORT_UNBILLED_CHART_RECON_SERVICE";
        public const string RUN_EXTRACT_HL7_MESSAGE_SERVICE = "EXTRACT_HL7_MESSAGE_SERVICE";
        public const string RUN_NETMD_UNBILLED_CHART_RECON_SERVICE = "NETMD_UNBILLED_CHART_RECON_SERVICE";
        public const string RUN_EXPORT_DOCUMENTS_SERVICE = "EXPORT_DOCUMENTS_SERVICE";
        public const string RUN_CHANGE_CHART_STATUS_SERVICE = "CHANGE_CHART_STATUS_SERVICE";
        public const string RUN_UPDATE_CHART_PRIORITY_SERVICE = "UPDATE_CHART_PRIORITY_SERVICE";
        public const string RUN_EXPORT_DOCUMENTS_MULTIPLE_FACILITY = "EXPORT_DOCUMENTS_MULTIPLE_FACILITY";
        public const string RUN_CHANGE_PENDING_CHARTS_WITH_DOS_OF_PRIOR_MONTH_TO_WIP_SERVICE = "CHANGE_PENDING_CHARTS_WITH_DOS_OF_PRIOR_MONTH_TO_WIP";
        public const string RUN_PURGE_DOCUMENTS_MULTIPLE_FACILITY = "PURGE_DOCUMENTS_MULTIPLE_FACILITY";
        public const string RUN_CHOA_UPDATE_PENDING_TO_WORK_IN_PROGRESS_SERVICE = "UPDATE_CHOA_PENDING_TO_WORK_IN_PROGRESS_SERVICE";
        public const string RUN_DAILY_DUPLICATE_PATIENT_REPORT_BY_MRN = "DPLMRN";
        public const string RUN_IMPORT_MEDICAL_SAVANT_DATA_SERVICE = "IMPORT_MEDICAL_SAVANT_DATA_SERVICE";
		public const string RUN_FACILITY_CHART_ARCHIVE_SERVICE = "FACILITY_CHART_ARCHIVE_SERVICE";
        public const string RUN_ICD10_UPDATE = "ICD10_UPDATE";

		#endregion constants

		[STAThread]
        static void Main(string[] args)
        {
			// Variables for testing
			//args[0] = "IMPORT_MEDICAL_SAVANT_DATA_SERVICE";
			//args[0] = "I";
			//args[0] = "E";

			//args[1] = "";

			// Below are the lines to uncomment in order to run in debug for FACILITY_CHART_ARCHIVE_SERVICE
			//args[0] = "FACILITY_CHART_ARCHIVE_SERVICE";
			//args[1] = "236";

			string processID = args[0];
            int facilityID = Convert.ToInt32(args[1]);
            string userID = args[2];
            string password = args[3];
            string sUserGroupID = string.Empty;
            BasicRequestManager requestManager = null;
            string hostName = Dns.GetHostName();
            IPHostEntry ipEntry = Dns.GetHostEntry(hostName);
            IPAddress[] addr = ipEntry.AddressList;
            string hostAddress = addr[0].ToString();
            int secondaryFacilityID = -1;
            int startingRowToCopy;

			try
            {
                requestManager = new BasicRequestManager();
            }
            catch (Exception ex)
            {
                var msg = "Batch process could not create a request manager due to exception " + ex.Message.ToString();
				Console.WriteLine(msg);
                throw new Exception(msg);
            }

			try
			{
                if (new SignOnUserService(requestManager).SignOn(userID, password, hostAddress))
                {
					// For IronPdf/LeadTools Quick testing.  Will remove once LeadTools removal is complete: DACS-4024.
					// Said 2158 = Altus LakeJackson GoRev
					// new EV_PDFImageImportTransformAccountNumberInFileName(requestManager, 2158).ImportImages(true);
					// new EV_Expanded_PDFImageImportTransformAccountNumberInFileName(requestManager, 2158).ImportImages(true);
					// new VariableAccountNumberNoTIFConversionImageImportTransform(requestManager, 2158).ImportImages(true);

					switch (processID)
                    {
                        case RUN_IMPORT:
							new ImportChartsService(requestManager).ImportDailyCharts(facilityID);
                            break;

                        case RUN_RIVERVIEW_IMPORT:
                            new RiverviewImport(requestManager);
                            break;

                        case RUN_PURGE_OLD_IMAGES:
                            PurgeImagesService pisvc = new PurgeImagesService(requestManager);
                            pisvc.PurgeImages(facilityID);
                            break;

                        case RUN_PURGE_OLD_IMAGES_FOR_ALL_FACILITIES:
                            PurgeImagesService paisvc = new PurgeImagesService(requestManager);
                            paisvc.PurgeImagesForAllFacilities();
                            break;

                        case RUN_ABSTRACT_PROCEDURE_UPDATE:
                            UpdateAbstractProceduresService abstractProcedureUpdateService = new UpdateAbstractProceduresService(requestManager);
                            abstractProcedureUpdateService.Run(facilityID);
                            break;

                        case RUN_SHAWNEE_MISSION_CHARGE_IMPORT:
                            ImportShawneeMissionChargeFileService importShawnee = new ImportShawneeMissionChargeFileService(requestManager);
                            importShawnee.Import(args[4]);
                            break;

                        case RUN_NORTHWESTERN_PHYSICIAN_APPROVAL_FILE_IMPORT:
                            ImportNorthwesternPhysicianFileService importNW = new ImportNorthwesternPhysicianFileService(requestManager);
                            importNW.Import(facilityID, args[4]);
                            break;

                        case RUN_AUTO_APPROVE:
                            AutoApproveChartsService autoApproveService = new AutoApproveChartsService(requestManager);
                            autoApproveService.Execute(facilityID);
                            break;

                        case RUN_IMPORT_IMAGES:
                            ImportImagesFromFTPService iisvc = new ImportImagesFromFTPService(requestManager);
                            var replaceExistingImages = true;
                            var sReplace = args[4];
                            if (sReplace.CompareTo("Y") == 0)
                            {
                                replaceExistingImages = true;
                            }
                            else
                            {
                                replaceExistingImages = false;
                            }
                            iisvc.ImportImages(facilityID, replaceExistingImages);
                            break;

                        case RUN_EXPORT:
                            ExportChartsService exsvc = new ExportChartsService(requestManager);
                            exsvc.ExportDailyCharts(facilityID);
                            break;

                        //case RUN_SPLIT_MULTI_IMAGE_FILE:
                        //    iisvc = new ImportImagesFromFTPService(requestManager);
                        //    iisvc.SplitMultipleImageFile(facilityID, args[5], args[6]);
                        //    break;

                        case RUN_IMAGE_IMPORT_NO_BARCODES:
                            iisvc = new ImportImagesFromFTPService(requestManager);
                            var replaceExistingImages2 = true;
                            var sReplace2 = args[4];
                            if (sReplace2.CompareTo("Y") == 0)
                            {
                                replaceExistingImages2 = true;
                            }
                            else
                            {
                                replaceExistingImages2 = false;
                            }
                            iisvc.ImportImagesWithNoBarcodeInPDF(facilityID, replaceExistingImages2, args[5]);
                            break;

                        case RUN_IMAGE_IMPORT_EV_RTF_NO_BARCODES:
                            iisvc = new ImportImagesFromFTPService(requestManager);
                            iisvc.ImportEVImagesWithNoBarcodeInRTF(facilityID, false, "Visit:,VisitID:,VisitID,Acct#:");
                            break;

                        case RUN_IMAGE_IMPORT_EV_RTF_ACCOUNT_NUMBER_IN_FILE_NAME:
                            iisvc = new ImportImagesFromFTPService(requestManager);
                            iisvc.ImportEVImagesWithNoBarcodeInRTFWithAccountNumberInFileName(facilityID, false);
                            break;

                        case RUN_IMAGE_IMPORT_EV_PDF_ACCOUNT_NUMBER_IN_FILE_NAME:
                            iisvc = new ImportImagesFromFTPService(requestManager);
                            iisvc.ImportEVImagesWithNoBarcodeInPDFWithAccountNumberInFileName(facilityID, false);
                            break;

                        case RUN_IMAGE_IMPORT_EV_EXPANDED_PDF_ACCOUNT_NUMBER_IN_FILE_NAME:
                            iisvc = new ImportImagesFromFTPService(requestManager);
                            iisvc.ImportEVImagesWithNoBarcodeInPDFWithAccountNumberInFileNameExpanded(facilityID, false);
                            break;

                        case RUN_IMAGE_IMPORT_VARIABLE_ACCOUNT_NUMBER_IN_FILENAME:
                            iisvc = new ImportImagesFromFTPService(requestManager);
                            replaceExistingImages2 = true;
                            sReplace2 = args[4];
                            if (sReplace2.CompareTo("Y") == 0)
                            {
                                replaceExistingImages2 = true;
                            }
                            else
                            {
                                replaceExistingImages2 = false;
                            }
                            iisvc.ImportImagesWithAccountNumberInVariablePositionInFileName(facilityID, replaceExistingImages2, args[5], args[6]);
                            break;

                        case RUN_IMAGE_IMPORT_VARIABLE_ACCOUNT_NUMBER_IN_FILENAME_COMBINED:
                            iisvc = new ImportImagesFromFTPService(requestManager);
                            replaceExistingImages2 = true;
                            sReplace2 = args[4];
                            if (sReplace2.CompareTo("Y") == 0)
                            {
                                replaceExistingImages2 = true;
                            }
                            else
                            {
                                replaceExistingImages2 = false;
                            }
                            iisvc.ImportImagesWithAccountNumberInVariablePositionInFileName(facilityID, replaceExistingImages2, args[5], args[6], true);
                            break;

                        case RUN_IMAGE_IMPORT_VARIABLE_ACCOUNT_NUMBER_WITH_DOS_IN_FILENAME:
                            iisvc = new ImportImagesFromFTPService(requestManager);
                            replaceExistingImages2 = true;
                            sReplace2 = args[4];
                            if (sReplace2.CompareTo("Y") == 0)
                            {
                                replaceExistingImages2 = true;
                            }
                            else
                            {
                                replaceExistingImages2 = false;
                            }
                            iisvc.ImportImagesWithAccountNumberInVariablePositionWithDOSInFileName(facilityID, replaceExistingImages2, args[5], args[6]);
                            break;

                        case RUN_IMAGE_IMPORT_VARIABLE_ACCOUNT_NUMBER_IN_FILENAME_NO_TIF_CONVERSION:
                            iisvc = new ImportImagesFromFTPService(requestManager);
                            replaceExistingImages2 = true;
                            sReplace2 = args[4];
                            if (sReplace2.CompareTo("Y") == 0)
                            {
                                replaceExistingImages2 = true;
                            }
                            else
                            {
                                replaceExistingImages2 = false;
                            }
                            iisvc.ImportImagesWithAccountNumberInVariablePositionInFileNameNoTIFConversion(facilityID, replaceExistingImages2, args[5], args[6]);
                            break;
                        case RUN_IMAGE_IMPORT_VARIABLE_ACCOUNT_NUMBER_IN_FILENAME_COMBINED_NO_TIF_CONVERSION:
                            iisvc = new ImportImagesFromFTPService(requestManager);
                            replaceExistingImages2 = true;
                            sReplace2 = args[4];
                            if (sReplace2.CompareTo("Y") == 0)
                            {
                                replaceExistingImages2 = true;
                            }
                            else
                            {
                                replaceExistingImages2 = false;
                            }
                            iisvc.ImportImagesWithAccountNumberInVariablePositionInFileNameCombinedNoTIFConversion(facilityID, replaceExistingImages2, args[5], args[6]);
                            break;
                        case RUN_IMAGE_IMPORT_WITH_RIVERCITY_TRANSFORM:
                            iisvc = new ImportImagesFromFTPService(requestManager);
                            var locationID = "-1";

                            if (StringUtility.IsNumeric(args[4]))
                            {
                                locationID = args[4];
                                if (locationID != "-1")
                                {
                                    iisvc.ImportImagesWithRiverCityTransform(facilityID, locationID);
                                }
                            }
                            break;

                        //case RUN_IMAGE_IMPORT_TIF_OCR_MRN_TRANSFORM:
                        //    iisvc = new ImportImagesFromFTPService(requestManager);

                        //    if (args[4] != string.Empty && args[5] != string.Empty)
                        //    {
                        //        iisvc.ImportImagesWithOCR_MRN_Transform(facilityID, args[4], args[5]);
                        //    }
                        //    break;

                        case RUN_IMAGE_IMPORT_SPECIAL_NAPA_TRANSFORM:
                            iisvc = new ImportImagesFromFTPService(requestManager);
                            iisvc.ImportSpecialNapaImageTransform(facilityID, 0, 12);
                            break;

                        case RUN_NAPA_DICTATION_FILE_MOVE_TO_PENDING_TRANSFORM:
                            iisvc = new ImportImagesFromFTPService(requestManager);
                            iisvc.NapaDictationFileMoveToPending(facilityID, 2, 12);
                            break;

                        case RUN_IMAGE_EXPORT_FOR_DATE_RANGE:
                            DateTime startDate = DateTime.Now;
                            DateTime endDate = DateTime.Now.AddDays(1);

                            if (args.Length >= 5)
                            {
                                try
                                {
                                    startDate = Convert.ToDateTime(args[4]);
                                }
                                catch (Exception)
                                {
                                    throw new Exception("Invalid start date");
                                }
                            }

                            if (args.Length >= 6)
                            {
                                try
                                {
                                    endDate = Convert.ToDateTime(args[5]);
                                }
                                catch (Exception)
                                {
                                    throw new Exception("Invalid end date");
                                }
                            }
                            ExportImagesService ximsvc = new ExportImagesService(requestManager);
                            ximsvc.ExportImages(facilityID, startDate, endDate);

                            break;

                        case RUN_REASSIGN_WORK_IN_PROGRESS_TO_UNASSIGNED:
                            ReassignChartsService rcSvc = new ReassignChartsService(requestManager);
                            rcSvc.ReassignWorkInProgressChartsToUnassigned();
                            break;

                        case RUN_CCHMC_LOAD_PHYSICIAN_SIGNATURE_FILE:
                            ImportCCHMCPhysicianSignatureService importPhysSigLoad = new ImportCCHMCPhysicianSignatureService(requestManager);
                            importPhysSigLoad.Load(facilityID, args[4]);
                            break;

                        case RUN_CCHMC_ED_BASE_PHYSICIAN_SIGNATURE_FILE_IMPORT:
                            ImportCCHMCPhysicianSignatureService importPhysSigEDBase = new ImportCCHMCPhysicianSignatureService(requestManager);
                            importPhysSigEDBase.Import(facilityID, "CMCC");
                            break;

                        case RUN_CCHMC_UC_MASON_PHYSICIAN_SIGNATURE_FILE_IMPORT:
                            ImportCCHMCPhysicianSignatureService importPhysSigUCMason = new ImportCCHMCPhysicianSignatureService(requestManager);
                            importPhysSigUCMason.Import(facilityID, "OPM");
                            break;

                        case RUN_CCHMC_ED_LIBERTY_PHYSICIAN_SIGNATURE_FILE_IMPORT:
                            ImportCCHMCPhysicianSignatureService importPhysSigEDLiberty = new ImportCCHMCPhysicianSignatureService(requestManager);
                            importPhysSigEDLiberty.Import(facilityID, "LIB");
                            break;

                        case RUN_CCHMC_UC_ANDERSON_PHYSICIAN_SIGNATURE_FILE_IMPORT:
                            ImportCCHMCPhysicianSignatureService importPhysSigUCAnderson = new ImportCCHMCPhysicianSignatureService(requestManager);
                            importPhysSigUCAnderson.Import(facilityID, "OPA");
                            break;

                        case RUN_CCHMC_UC_FAIRFIELD_PHYSICIAN_SIGNATURE_FILE_IMPORT:
                            ImportCCHMCPhysicianSignatureService importPhysSigUCFairfield = new ImportCCHMCPhysicianSignatureService(requestManager);
                            importPhysSigUCFairfield.Import(facilityID, "OPF");
                            break;

                        case RUN_CCHMC_LOAD_TRANSFER_TO_BASE_FILE:
                            ImportCCHMCTransferToBaseService loadCCHMCTB = new ImportCCHMCTransferToBaseService(requestManager);
                            loadCCHMCTB.Load(facilityID, args[4]);
                            break;

                        case RUN_CCHMC_TRANSFER_TO_BASE_FILE_IMPORT:
                            ImportCCHMCTransferToBaseService importCCHMCTB = new ImportCCHMCTransferToBaseService(requestManager);
                            importCCHMCTB.Import(facilityID, Convert.ToInt32(args[4]));
                            break;

                        case RUN_DAILY_PRODUCTION_REPORT:
                            DailyProductionReportService dprsvc = new DailyProductionReportService(requestManager);
                            sUserGroupID = args[4];
                            dprsvc.RunReport(Convert.ToInt32(facilityID), Convert.ToInt32(sUserGroupID));
                            break;

                        case RUN_CHARGE_POSTING_SERVICE:
                            ChargePostingService cpsvc = new ChargePostingService(requestManager);
                            var sCoderID = args[4];
                            cpsvc.Run(facilityID, sCoderID);
                            break;

                        case RUN_DAILY_LATE_FILES_REPORT:
                            DailyLateFilesReportService dlfrsvc = new DailyLateFilesReportService(requestManager);
                            sUserGroupID = args[4];
                            var sNumberOfDays = args[5];
                            var sRecipients = args[6];
                            dlfrsvc.RunReport(Convert.ToInt32(facilityID), Convert.ToInt32(sUserGroupID), Convert.ToInt32(sNumberOfDays), sRecipients);
                            break;

                        case RUN_DAILY_NO_STOP_TIME_REPORT:
                            DailyNoStopTimeReportService dnstpsvc = new DailyNoStopTimeReportService(requestManager);
                            sUserGroupID = args[4];
                            // arg5 is used for the recipients email address
                            dnstpsvc.RunReport(Convert.ToInt32(facilityID), Convert.ToInt32(sUserGroupID), args[5]);
                            break;

                        case RUN_CHART_RECAP_REPORTS:
                            ChartRecapReportService crrsvc = new ChartRecapReportService(requestManager);
                            int iChartID = -1;
                            try
                            {
                                var sChartID = args[4];
                                iChartID = Convert.ToInt32(sChartID);
                            }
                            catch (Exception)
                            {
                            }
                            crrsvc.GenerateReport(iChartID);
                            break;

                        case RUN_CHART_RECAP_REPORT_AS_OF_LAST_RUN_DATE:
                            ChartRecapReportService crrsvc2 = new ChartRecapReportService(requestManager);
                            crrsvc2.GenerateReportsForChartsWithTimeOfServiceAfterLastRunDate(facilityID);
                            break;

                        case RUN_CHART_RECAP_REPORT_GIVEN_DATE_RANGE:
                            ChartRecapReportService crrsvc3 = new ChartRecapReportService(requestManager);
                            DateTime crrStartDate = Convert.ToDateTime(args[4]);
                            DateTime crrEndDate = Convert.ToDateTime(args[5]);
                            crrsvc3.GenerateReportsGivenDateRange(facilityID, crrStartDate, crrEndDate);
                            break;

                        case RUN_DAILY_DUPLICATE_PATIENT_REPORT:
                            DailyDuplicatePatientReportService ddprsvc = new DailyDuplicatePatientReportService(requestManager);
                            sUserGroupID = args[4];
                            int[] serviceAgreementIds = null;
                            if (args.Length >= 6)
                            {
                                try
                                {
                                    serviceAgreementIds = args[5].Split(',').Select(int.Parse).ToArray();
                                }
                                catch
                                {
                                    // Set serviceAgreementIds to null if the int.Parse conversion above is unsuccessful.
                                    serviceAgreementIds = null;
                                }
                            }
                            ddprsvc.RunReport(Convert.ToInt32(facilityID), Convert.ToInt32(sUserGroupID), serviceAgreementIds);
                            break;

                        case RUN_REGISTRATION_ONLY_REPORT:
                            RegistrationOnlyReportService rorsvc = new RegistrationOnlyReportService(requestManager);
                            sUserGroupID = args[4];
                            TimeSpan oneDay = new TimeSpan(1, 0, 0, 0, 0);
                            rorsvc.RunReport(Convert.ToInt32(facilityID), DateTime.Now.Subtract(oneDay), Convert.ToInt32(sUserGroupID));
                            break;

                        case RUN_EMAIL_IMPORT:
                            PopMailImport emailUtil = new PopMailImport(requestManager);
                            emailUtil.DoMail(facilityID);
                            break;

                        case RUN_IMPORT_FILE_ARCHIVE:
                            ArchiveImportFileService ifasvc = new ArchiveImportFileService(requestManager);
                            ifasvc.Archive(facilityID);
                            break;

                        case RUN_CAMC_DISCHARGE_IMPORT:
                            ImportDischargeFileService idfasvc = new ImportDischargeFileService(requestManager);
                            idfasvc.Import(facilityID, args[4]);
                            break;

                        case RUN_EMAIL_EXPORT:
                            EmailExport svc = new EmailExport(requestManager);
                            // Arg[4] is the file pattern of the files to send - like *.xls
                            svc.DoExport(facilityID, args[4]);
                            break;

                        case RUN_DECRYPT:
                            DecryptFilesOnFTPSiteService dcfsvc = new DecryptFilesOnFTPSiteService(requestManager);
                            if (args.Length == 5)
                            {
                                var sRecurse = args[4];
                                var recurse = (args[4].ToUpper().CompareTo("R") == 0);
                                dcfsvc.Decrypt(facilityID, recurse);
                            }
                            else
                                dcfsvc.Decrypt(facilityID, false);

                            break;

                        case RUN_ENCRYPT:
                            EncryptFilesOnFTPSiteService ecfsvc = new EncryptFilesOnFTPSiteService(requestManager);
                            ecfsvc.Encrypt(facilityID);
                            break;

                        case RUN_SQL:
                            RunSQLCommandService sqlsvc = new RunSQLCommandService(requestManager);
                            sqlsvc.Execute(args[4]);
                            break;

                        case RUN_BUILD_VERIFICATION_TEST:
                            BuildVerificationTestService tstSvc = new BuildVerificationTestService(requestManager);
                            tstSvc.Execute();
                            break;

                        case RUN_WEEKLY_PREBILL_AUDIT_ABSTRACT:
                            WeeklyPrebillAuditAbstractService wpbSvc = new WeeklyPrebillAuditAbstractService(requestManager);
                            wpbSvc.Execute(facilityID);

                            EmailExport emsvc = new EmailExport(requestManager);
                            emsvc.DoExport(facilityID, wpbSvc.FileName);
                            break;

                        case RUN_WEEKLY_PREBILL_AUDIT_ABSTRACT_FOR_DATE_RANGE:
                            WeeklyPrebillAuditAbstractService wpbSvc2 = new WeeklyPrebillAuditAbstractService(requestManager);
                            DateTime wpastartDate = Convert.ToDateTime(args[4]);
                            DateTime wpaendDate = Convert.ToDateTime(args[5]);

                            wpbSvc2.Execute(facilityID, wpastartDate, wpaendDate);

                            //EmailExport emsvc = new EmailExport(requestManager);
                            //emsvc.DoExport(facilityID, wpbSvc.FileName);
                            break;

                        case RUN_DATA_CONVERSION_SERVICE:
                            DataConversionService dcSvc = new DataConversionService(requestManager);
                            int res = dcSvc.DataConversion(facilityID);
                            Console.WriteLine(res.ToString() + " charts were converted for Facility ID: " + facilityID.ToString());
                            Console.WriteLine("Data Conversion Complete");
                            Console.ReadLine();
                            break;

                        case RUN_MASS_UPDATE_CHARTS_PHYSICIAN_ID:
                            MassUpdateChartsService mucSvc = new MassUpdateChartsService(requestManager);
                            int physicianID = Convert.ToInt32(args[4]);
                            mucSvc.UpdateWorkInProgressChartsPhysicianID(facilityID, physicianID);
                            break;

                        case RUN_MASS_UPDATE_CHARTS_DISPOSITION_IDS:
                            MassUpdateChartsService muc2Svc = new MassUpdateChartsService(requestManager);
                            int dispositionID = Convert.ToInt32(args[4]);
                            muc2Svc.UpdateWorkInProgressChartsDispositionIDs(facilityID, dispositionID);
                            break;

                        case RUN_CHMC_LOAD_CHARGE_POSTING_DATA:
                            LoadExcelDataToDatabaseService ledtds = new LoadExcelDataToDatabaseService(requestManager);
                            ledtds.LoadCHMCChargePostingData(args[4], args[5]);
                            break;

                        case RUN_PRINCETON_OBS_DISCHARGE_IMPORT:
                            ImportDischargeFileService impdischrg = new ImportDischargeFileService(requestManager);
                            impdischrg.Import(facilityID, "");
                            break;

                        case RUN_PRINCETON_RECON_REPORT:
                            ImportPrincetonReconReportService iprs = new ImportPrincetonReconReportService(requestManager);
                            iprs.ImportPrincetonReconReport(args[4]);
                            break;

                        case RUN_PRINCETON_UNATTACHED_IMAGES:
                            ImportImagesFromFTPService iiffs = new ImportImagesFromFTPService(requestManager);
                            secondaryFacilityID = Convert.ToInt32(args[4]);
                            iiffs.ProcessPrincetonUnattachedImages(facilityID, secondaryFacilityID);
                            break;

                        case RUN_ACH_RECON_GET_MAIL:
                            ACHPop3Import ap3i = new ACHPop3Import(requestManager);
                            ap3i.GetMail(args[4]);
                            break;

                        case RUN_ACH_RECON_REPORT:
                            LoadExcelDataToDatabaseService ACHledtds = new LoadExcelDataToDatabaseService(requestManager);
                            //ACHledtds.LoadACHChargePostingData("C:\\Test\\ACH\\ED Reconciliation to CCS 5-15-13.xls", "ACH_CHART_RECON");
                            ACHledtds.LoadACHChargePostingData(args[4], args[5]);
                            break;

                        case RUN_NMH_RECON_REPORT:
                            ImportNMHReconReportService inrrs = new ImportNMHReconReportService(requestManager);
                            inrrs.ImportNMHReconReport(args[4], args[5]);
                            break;

                        case RUN_NYP_LOAD_CHARGE_POSTING_DATA:
                            LoadExcelDataToDatabaseService ledtdsNYP = new LoadExcelDataToDatabaseService(requestManager);
                            ledtdsNYP.LoadNYPChargePostingData(args[4], args[5]);
                            break;

                        case RUN_CCHMC_RECON_REPORT:
                            ImportCCHMCReconReportService icrrs = new ImportCCHMCReconReportService(requestManager);
                            icrrs.ImportCCHMCReconReport(args[4]);
                            break;

                        case RUN_RGH_RECON_REPORT:
                            ImportRGHReconReportService irrs = new ImportRGHReconReportService(requestManager);
                            irrs.ImportRGHReconReport(args[4]);
                            break;

                        case RUN_PRMC_RECON_REPORT:
                            ImportPalestineReconReportService iprmcrs = new ImportPalestineReconReportService(requestManager);
                            iprmcrs.ImportPalestineReconReport(args[4]);
                            break;

                        case RUN_COMBINE_FILES_INTO_ONE:
                            CombineMultipleFilesService cmfs = new CombineMultipleFilesService(requestManager);
                            cmfs.CombineFiles(facilityID, args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11]);
                            break;

                        case RUN_COMBINE_FILES_INTO_ONE_USING_WRITE_FILE:
                            CombineMultipleFilesService cmfswf = new CombineMultipleFilesService(requestManager);
                            cmfswf.CombineFilesUsingWriteFile(facilityID, args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11]);
                            break;

                        case RUN_CCI_EDITS_IMPORT:
                            ImportCCIEditsService ices = new ImportCCIEditsService(requestManager);
                            ices.ImportNCCICodingEdits(args[4]);
                            break;

                        //case RUN_CMS_DATA_IMPORT:
                        //    var icds = new ImportCMSDataService(requestManager, new Uri(args[4]), new Uri(args[5]), args[6], args[7].ConvertOrDefault<bool>(), args[8].ConvertOrDefault<bool>());
                        //    icds.LoadCmsBillCode();
                        //    icds.LoadCmsContractorType();
                        //    icds.LoadCmsRegion();
                        //    icds.LoadCmsDMERCRegion();
                        //    icds.LoadCmsState();
                        //    icds.LoadCmsStateRegion();
                        //    icds.LoadCmsReasonChange();
                        //    icds.LoadCmsRevenueCode();
                        //    icds.LoadCmsContractor();
                        //    icds.LoadCmsContractorJurisdiction();
                        //    icds.LoadCmsContractorOversight();
                        //    icds.LoadCmsHcpcCode();
                        //    icds.LoadCmsIcd9Code();
                        //    icds.LoadCmsLcd();
                        //    icds.LoadCmsLcdFutureRetire();
                        //    icds.LoadCmsLcdHcpcCode();
                        //    icds.LoadCmsLcdHcpcCodeGroup();
                        //    icds.LoadCmsLcdIcd9Support();
                        //    icds.LoadCmsLcdIcd9DontSupport();
                        //    icds.LoadCmsLcdXBillCode();
                        //    icds.LoadCmsLcdXContractor();
                        //    icds.LoadCmsLcdXIcd9SupportGroup();
                        //    icds.LoadCmsLcdXPrimaryJurisdiction();
                        //    icds.LoadCmsLcdXReasonChange();
                        //    icds.LoadCmsLcdXRevenueCode();
                        //    icds.LoadCmsUpdatePeriod();
                        //    icds.LoadCmsNcd();
                        //    icds.EmailAccountManagers();
                        //    break;

                        case RUN_CMS_LAB_CODE_IMPORT:
                            new ImportCMSLabCodesService(requestManager, new Uri(args[4]), args[5]).LoadCmsLabCodes();
                            break;

                        case RUN_CHOA_RECON_REPORT:
                            LoadCSVDataToDatabaseService lcdtds = new LoadCSVDataToDatabaseService(requestManager);
                            lcdtds.LoadCHOAChargeReconciliationData(args[4], args[5]);
                            break;

                        case RUN_LOAD_CMS_LAB_CODE_LIST:
                            LoadExcelDataToDatabaseService ledtdsCMS = new LoadExcelDataToDatabaseService(requestManager);
                            ledtdsCMS.CMSLoadLabCodeListData(args[4], args[5], Convert.ToInt32(args[6]));
                            break;

                        case RUN_LOAD_CHOA_WORK_QUEUE_DATA:
                            LoadCSVDataToDatabaseService lcdtdsWQ = new LoadCSVDataToDatabaseService(requestManager);
                            lcdtdsWQ.LoadCHOAWorkQueueReconciliationData(args[4], args[5]);
                            break;

                        //case RUN_HASH_USER_PROFILE_PASSWORDS:
                        //    HashUserProfilePasswordsService hupp = new HashUserProfilePasswordsService(requestManager);
                        //    hupp.HashUserProfilePasswords();
                        //    break;

                        case RUN_LIFEPOINT_ATHENS_OBS_DISCHARGE_IMPORT:
                            ImportDischargeFileService impdischrgAthens = new ImportDischargeFileService(requestManager);
                            impdischrgAthens.Import(facilityID, "");
                            break;

                        case RUN_LIFEPOINT_ATHENS_CLINIC_DISCHARGE_IMPORT:
                            ImportClinicDischargeFileService impClinicDischrgAthens = new ImportClinicDischargeFileService(requestManager);
                            impClinicDischrgAthens.Import(facilityID, "");
                            break;

                        case RUN_LIFEPOINT_IMPORT_BILLING_LIST:
                            ImportLifePointBillingListService ilpbls = new ImportLifePointBillingListService(requestManager);
                            ilpbls.ImportBillingList(facilityID, args[4], "LIFEPOINT_CHARGE_BILLED");//args[5]);
                            break;

                        case RUN_LIFEPOINT_UPDATE_BILLING_LIST:
                            UpdateLifePointBillingListService ulpbls = new UpdateLifePointBillingListService(requestManager);
                            ulpbls.UpdateBillingList(facilityID, args[4], args[5]);
                            break;

                        case RUN_NYP_ACN_CHART_IMPORT:
                            ImportNYPACNCompletedCharts iNYPACNCharts = new ImportNYPACNCompletedCharts(requestManager);
                            iNYPACNCharts.Import(facilityID, args[4], args[5], "ACN");
                            break;

                        case RUN_NYP_OSP_CHART_IMPORT:
                            ImportNYPACNCompletedCharts iNYPOSPCharts = new ImportNYPACNCompletedCharts(requestManager);
                            iNYPOSPCharts.Import(facilityID, args[4], args[5], "OSP");
                            //iNYPOSPCharts.Import(facilityID, "C:\\NYP OSP\\Q1 2011 Files\\CU_CCS_OSP_SEMI_ANNUAL_Test.txt", "", "OSP");
                            break;

                        case RUN_INACTIVATE_UNUSED_USER_ACCOUNTS:
                            InactivateUnusedUserAccountsService iuuas = new InactivateUnusedUserAccountsService(requestManager);
                            iuuas.InactivateUnusedUserAccounts(Convert.ToInt32(args[4]));
                            break;

                        case RUN_IMPORT_CHOA_IBEX_DOWNLOAD:
                            ImportChoaIbexDataService icids = new ImportChoaIbexDataService(requestManager);
                            icids.LoadChoaIbexData(facilityID);
                            break;

                        //case RUN_CODER_BILLING_PROCESS:
                        //    CoderBillingService billService = new CoderBillingService(requestManager);
                        //    billService.RunCoderBillingService(Convert.ToBoolean(args[4]));
                        //    break;

                        case RUN_CODER_BILLING_EXTRACT:
                            CoderBillingService extractService = new CoderBillingService(requestManager);
                            extractService.RunBillingExtract();
                            break;

                        case RUN_UPDATE_REPORT_ITEM_TABLE:
                            ReportItemService ris = new ReportItemService(requestManager);
                            ris.LoadFiles(args[4]);
                            break;

                        case RUN_IMPORT_GRANT_MEMORIAL_BILLING_LIST:
                            ImportGrantMemorialBillingListService igmbls = new ImportGrantMemorialBillingListService(requestManager);
                            igmbls.ImportBillingList();
                            break;

                        case RUN_IMPORT_MEDITECH_BILLING_LIST:
                            ImportMEDITECHBillingListService imbls = new ImportMEDITECHBillingListService(requestManager);
                            imbls.ImportMEDITECHBillingList(facilityID, args[4], args[5]);
                            break;

                        case RUN_IMPORT_LSS_BILLING_LIST:
                            ImportLSSBillingListService irlbls = new ImportLSSBillingListService(requestManager);
                            irlbls.ImportLSSBillingList(facilityID, args[4], args[5]);
                            break;

                        case RUN_CHOA_PNP_LIST_DATA_LOAD:
                            ImportCHOAPNPListService icpnpldl = new ImportCHOAPNPListService(requestManager);
                            //icpnpldl.Load(facilityID, "C:\\ccsftp\\CHOA\\TO_CCS\\ED-Nurse-Practioners-2011-02-11.xls");
                            icpnpldl.Load(facilityID, args[4]);
                            break;

                        case RUN_IMPORT_ADT_FILE_SERVICE:
                            ImportADTFileService iafs = new ImportADTFileService(requestManager);
                            iafs.Import(facilityID, args[4]);
                            break;

                        case RUN_REPORT_SCHEDULER_SERVICE:
                            ReportSchedulerService rss = new ReportSchedulerService(requestManager);
                            rss.SendReport(args[4]);
                            break;

                        case RUN_IMPORT_TCH_RECONCILIATION_SERVICE:
                            ImportTCHReconciliationService itrs = new ImportTCHReconciliationService(requestManager);
                            itrs.LoadTCHReconciliationData(facilityID, args[5]);
                            break;

                        case RUN_FAILED_REPORT_SUBSCRIPTIONS:
                            RunFailedReportSubscriptions rfrs = new RunFailedReportSubscriptions(requestManager);
                            rfrs.RunFailedJobs();
                            break;

                        case RUN_ROANE_DISCHARGE_FILES_IMPORT:
                            ImportDischargeFileService impdischrgRoane = new ImportDischargeFileService(requestManager);
                            impdischrgRoane.Import(facilityID, "");
                            break;

                        case RUN_PEMA_BILLING_REPORT_SPLIT:
                            ReportSchedulerService reportService = new ReportSchedulerService(requestManager);
                            reportService.SplitWorkbook(args[4], args[5], args[6]);
                            break;

                        case RUN_IMPORT_CHOA_ASAP_CHARGES_SERVICE:
                            ImportChoaAsapChargesService icacs = new ImportChoaAsapChargesService(requestManager);
                            icacs.ImportChoaAsapCharges(facilityID, args[4], Boolean.Parse(args[5]));
                            break;

                        case RUN_IMPORT_OBS_CENSUS_FILE:
                            ImportObsCensusFileService impObsCensusService = new ImportObsCensusFileService(requestManager);
                            impObsCensusService.Import(facilityID, "");
                            break;

                        case RUN_ST_ANTHONY_OB_CLINIC_IMPORT_OBS_CENSUS_FILE:
                            ImportObsCensusFileService impObsCensusServiceStAnthonyOBClinic = new ImportObsCensusFileService(requestManager);
                            impObsCensusServiceStAnthonyOBClinic.Import(facilityID, "SDC");
                            break;

                        case RUN_IMPORT_DISCHARGE_FILE:
                            ImportDischargeFileService impDischargeFile = new ImportDischargeFileService(requestManager);
                            impDischargeFile.Import(facilityID, "");
                            break;

                        case RUN_PROCESS_UNATTACHED_IMAGES:
                            ImportImagesFromFTPService iiffs2 = new ImportImagesFromFTPService(requestManager);
                            secondaryFacilityID = Convert.ToInt32(args[4]);
                            iiffs2.ProcessUnattachedImages(facilityID, secondaryFacilityID);
                            break;

                        case RUN_COMBINE_EXCEL_FILES:
                            CombineMultipleFilesService cmfsExcel = new CombineMultipleFilesService(requestManager);
                            secondaryFacilityID = Convert.ToInt32(args[4]);
                            startingRowToCopy = Convert.ToInt32(args[8]);
                            cmfsExcel.CombineExcelFiles(facilityID, secondaryFacilityID, args[5], args[6], args[7], startingRowToCopy);
                            break;

                        case RUN_IMPORT_CMS_ADDENDUM_SERVICE:
                            ImportCMSAddendumService icas = new ImportCMSAddendumService(requestManager);
                            icas.ImportCCIEditFiles(args[4], args[5]);
                            break;

                        case RUN_UPDATE_REPORT_ID_SERVICE:
                            UpdateReportIDService uris = new UpdateReportIDService(requestManager);
                            uris.UpdateReportIDs();
                            break;

                        case RUN_IMPORT_ST_ANTHONY_RECON_SERVICE:
                            ImportStAnthonyReconService isars = new ImportStAnthonyReconService(requestManager);
                            isars.ImportChoaAsapCharges(facilityID, args[4]);
                            break;

                        case RUN_IMPORT_GE_TICKET_NUMBER_ASSIGNMENT_SERVICE:
                            ImportGETicketNumberAssignmentsService iGETicketNumAssignmentService = new ImportGETicketNumberAssignmentsService(requestManager);
                            iGETicketNumAssignmentService.Import(facilityID, "");
                            break;

                        case RUN_COMBINE_MULTIPLE_EXCEL_FILES_FOR_SAME_FACILITY:
                            CombineMultipleFilesService cmbmultfilesExcel = new CombineMultipleFilesService(requestManager);
                            startingRowToCopy = Convert.ToInt32(args[9]);
                            cmbmultfilesExcel.CombineMultipleExcelFilesForSameFacility(facilityID, args[4], args[5], args[6], args[7], args[8], startingRowToCopy);
                            break;

                        case RUN_IMPORT_EPIC_ASAP_CHARGES_SERVICE:
                            ImportEpicAsapChargesService ieacs = new ImportEpicAsapChargesService(requestManager);
                            ieacs.ImportEpicAsapCharges(args[4], args[5], Boolean.Parse(args[6]));
                            break;

                        case RUN_CHANGE_INPATIENT_PENDING_AWAITING_DISCHARGE_TO_WORK_IN_PROGRESS:
                            ChangeChartsStatusService ccss = new ChangeChartsStatusService(requestManager);
                            ccss.ChangeInpatientPendingAwaitingDischargeChartsToWorkInProgress(facilityID, args[4]);
                            break;

                        case RUN_CREATE_WAYNE_MEMORIAL_ADDITIONAL_DATA_SPREADSHEET:
                            WayneMemorialAddtlDataService wmads = new WayneMemorialAddtlDataService(requestManager);
                            wmads.CreateExportSpreadsheetOfCharts(facilityID, args[4], args[5]);
                            break;

                        case RUN_IMPORT_WAYNE_MEMORIAL_ADDITIONAL_DATA_SPREADSHEET:
                            WayneMemorialAddtlDataService wmds = new WayneMemorialAddtlDataService(requestManager);
                            wmds.UpdateChartsFromSpreadsheet(facilityID, args[4]);
                            break;

                        case RUN_MOVE_CHARTS_TO_WORK_IN_PROGRESS_SERVICE:
                            bool fromReceived = false;
                            int? pendingReason = null;

                            try { fromReceived = Convert.ToBoolean(args[5]); } catch { }
                            try { pendingReason = Convert.ToInt32(args[6]); } catch { }

                            new MoveChartsToWorkInProgressService(requestManager).MoveChartsToWorkInProgress(facilityID, Convert.ToInt32(args[4]), fromReceived, pendingReason);
                            break;

                        case RUN_MOVE_PENDING_NO_EMR_CHARTS_TO_WORK_IN_PROGRESS:
                        case RUN_CHANGE_CHART_STATUS_SERVICE:
                            new ChangeChartsStatusService(requestManager).ChangeChartStatus();
                            break;

                        case RUN_CHARGE_AMOUNT_UPDATE_ALERT_SERVICE:
                            ChargeAmountUpdateAlertService cauas = new ChargeAmountUpdateAlertService(requestManager);
                            cauas.AlertAccountManagers();
                            break;

                        case RUN_IMPORT_ASA_PHYSICIAN_CHARGES_SERVICE:
                            ImportASAPhysicianChargesService iapcs = new ImportASAPhysicianChargesService(requestManager);
                            iapcs.ImportASAPhysicianCharges(args[4]);
                            break;

                        case RUN_STATUS_FEEDBACK_REPORT:
                            StatusFeedbackReportService sfrs = new StatusFeedbackReportService(requestManager);
                            sfrs.GenerateReport(Convert.ToInt32(args[4]), args[5], args[6]);
                            break;

                        case RUN_IMPORT_CHARGE_RECON_SERVICE:
                            bool performFileCleanUp;
                            try
                            {
                                //performFileCleanUp = false; 
                                performFileCleanUp = Convert.ToBoolean(args[4]);
                            }
                            catch
                            {
                                performFileCleanUp = true;
                            }
                            new ImportChargeReconService(requestManager).Import(facilityID, performFileCleanUp);
                            break;

                        case RUN_CONVERT_TO_EXCEL_2003_FORMAT_SERVICE:
                            ExcelUtility.SaveIn2003Format(args[4]);
                            break;

                        case RUN_IMPORT_CABELL_HUNTINGTON_REPORTING_DATA:
                            new ImportCabellHuntingtonReportingDataService(requestManager).Import(facilityID, args[4]);
                            break;

                        case RUN_CHILDRENS_MERCY_PHYSICIAN_SIGNOFF_SERVICE:
							int maxDays;
							try { maxDays = Convert.ToInt32(args[5]); }
                            catch { maxDays = 46; } // If no value is passed in, default to 46
							new ChildrensMercyPhysicianSignOffService(requestManager).UpdateCharts(args[4], maxDays);
                            break;

                        case RUN_CHOA_UPDATE_PENDING_TO_WORK_IN_PROGRESS_SERVICE:
                            new UpdateCHOAPendingToWorkInProgressService(requestManager).UpdateCharts(facilityID, args[4]);
                            break;

                        case RUN_WILLIAMSBURG_RECON_REPORT:
                            ImportWilliamsburgReconService iwrs = new ImportWilliamsburgReconService(requestManager);
                            iwrs.ImportWilliamsburgReconReport(args[4]);
                            break;

                        case RUN_IMPORT_VISIT_RECON_SERVICE:
                            try
                            {
                                //performFileCleanUp = false;
                                performFileCleanUp = Convert.ToBoolean(args[4]);
                            }
                            catch
                            {
                                performFileCleanUp = true;
                            }
                            new ImportVisitReconService(requestManager).Import(facilityID, performFileCleanUp);
                            break;

                        case RUN_UPDATE_DOWNCODE_DATA_FOR_DATERANGE:
                            DateTime start;
                            DateTime end;

                            if (DateTime.TryParse(args[4], out start) && DateTime.TryParse(args[5], out end))
                                new UpdateDocumentationEvaluationService(requestManager).SaveDowncodedCharts(new DateRange(start, end));
                            break;

                        case RUN_COPY_IMAGES_FOR_ACCOUNT_SERVICE:
                            CopyFilesService copyFilesSvc = new CopyFilesService(requestManager);
                            copyFilesSvc.CopyImageFilesForAcctFromSpreadsheet(args[4], args[5], args[6], args[7]);
                            break;

                        case RUN_CREATE_CHARTS_PENDING_WORKSHEET:
                            ChartsByPendingReasonService cbprs = new ChartsByPendingReasonService(requestManager);
                            cbprs.CreateExportSpreadsheetOfChartsNoEMR(facilityID, args[4], args[5], args[6]);
                            break;

                        case RUN_MEDSTAR_DISCHARGE_FILES_IMPORT:
                            new ImportDischargeFileService(requestManager).Import(facilityID, "");
                            break;

                        case RUN_TCH_DENVER_UPDATE_PATIENT_CLASS_SERVICE:
                            new TCHDenverUpdatePatientClassService(requestManager).Run(facilityID, Convert.ToInt32(args[4]), args[5], args[6]);
                            break;

                        case RUN_COMBINE_MULTIPLE_TXT_FILES_WITH_HEADER:
                            new CombineMultipleFilesService(requestManager).CombineMultipleTxtFilesWithHeaderService(args[4], args[5], args[6]);
                            break;

                        case RUN_UPDATE_PENDING_REASON_SERVICE:
                            int newPendingReason;
                            int newChartStatusID;
                            try
                            {
                                newPendingReason = Convert.ToInt32(args[6]);
                            }
                            catch
                            {
                                newPendingReason = -1;
                            }
                            try
                            {
                                newChartStatusID = Convert.ToInt32(args[7]);
                            }
                            catch
                            {
                                newChartStatusID = -1;
                            }
                            new ChartsByPendingReasonService(requestManager).UpdateChartsByDischargeDate(facilityID, Convert.ToInt32(args[4]), Convert.ToInt32(args[5]), newPendingReason, newChartStatusID);
                            break;

                        case RUN_IMPORT_UNBILLED_CHART_RECON_SERVICE:
                            try
                            {
                                //performFileCleanUp = false;
                                performFileCleanUp = Convert.ToBoolean(args[4]);
                            }
                            catch
                            {
                                performFileCleanUp = false;
                            }
                            new ImportUnbilledChartReconService(requestManager).Import(facilityID, performFileCleanUp);
                            break;

                        case RUN_EXTRACT_HL7_MESSAGE_SERVICE:
                            new ExtractHL7MessageService(requestManager).ExtractMessages(facilityID, args[4]);
                            break;

                        case RUN_NETMD_UNBILLED_CHART_RECON_SERVICE:
                            new NetMDReconImport(requestManager).Import(args[4], args[5], args[6]);
                            break;

                        case RUN_EXPORT_DOCUMENTS_SERVICE:
                            new ExportImagesService(requestManager).ExportDocuments(args[4]);
                            break;

                        case RUN_UPDATE_CHART_PRIORITY_SERVICE:
                            new UpdateChartPriorityService(requestManager).SetPriorityBasedOnSLA();
                            break;

                        case RUN_EXPORT_DOCUMENTS_MULTIPLE_FACILITY:
                            bool decrypt;
                            bool deleteOriginal;
                            int exportMode;
                            DateTime? endDateOfService = null;
                            NetworkCredential credentials = null;

                            DateTime dt;
                            if (args.Length > 10 && DateTime.TryParse(args[10], out dt))
                            {
                                endDateOfService = dt.Date;
                            }
                            if (args.Length <= 7 || !bool.TryParse(args[7], out decrypt))
                            {
                                decrypt = true;
                            }
                            if (args.Length <= 8 || !bool.TryParse(args[8], out deleteOriginal))
                            {
                                deleteOriginal = false;
                            }
                            if (args.Length <= 9 || !int.TryParse(args[9], out exportMode))
                            {
                                exportMode = 0;
                            }
                            if (args.Length > 12 &&
                                !string.IsNullOrWhiteSpace(args[11]) &&
                                !string.IsNullOrWhiteSpace(args[12]))
                            {
                                if (!string.IsNullOrWhiteSpace(args[13]))
                                {
                                    credentials = new NetworkCredential(args[11], args[12], args[13]);
                                }
                                else
                                {
                                    credentials = new NetworkCredential(args[11], args[12]);
                                }
                            }

                            new ExportImagesService(requestManager).ExportDocuments(Convert.ToInt32(args[4]), args[5], args[6], decrypt, deleteOriginal, exportMode, endDateOfService, credentials: credentials);
                            break;

                        case RUN_CHANGE_PENDING_CHARTS_WITH_DOS_OF_PRIOR_MONTH_TO_WIP_SERVICE:
                            new ChangeChartsStatusService(requestManager).ChangePendingChartsWithDOSOfPriorMonthToWIP(facilityID, Convert.ToInt32(args[4]));
                            break;

                        case RUN_PURGE_DOCUMENTS_MULTIPLE_FACILITY:
                            int exportModePurge;
                            DateTime? endDateOfServicePurge = null;
                            NetworkCredential credentialsPurge = null;

                            DateTime dtPurge;
                            if (args.Length > 7 && DateTime.TryParse(args[7], out dtPurge))
                            {
                                endDateOfServicePurge = dtPurge.Date;
                            }
                            if (args.Length <= 6 || !int.TryParse(args[6], out exportModePurge))
                            {
                                exportModePurge = 0;
                            }
                            if (args.Length > 9 &&
                                !string.IsNullOrWhiteSpace(args[8]) &&
                                !string.IsNullOrWhiteSpace(args[9]))
                            {
                                if (!string.IsNullOrWhiteSpace(args[10]))
                                {
                                    credentialsPurge = new NetworkCredential(args[8], args[9], args[10]);
                                }
                                else
                                {
                                    credentialsPurge = new NetworkCredential(args[8], args[9]);
                                }
                            }

                            new ExportImagesService(requestManager).PurgeDocuments(Convert.ToInt32(args[4]), args[5], exportModePurge, endDateOfServicePurge, credentials: credentialsPurge);
                            break;

                        case RUN_PHYSICIAN_SIGNOFF_SERVICE:
                            new PhysicianSignOffService(requestManager).UpdateCharts(args[4], args[5], Convert.ToInt32(args[6]), Convert.ToInt32(args[7]));
                            break;

                        case RUN_CONE_PHYSICIAN_SIGNOFF_SERVICE:
                            new ConePhysicianSignOffService(requestManager).UpdateCharts(args[4], args[5], Convert.ToInt32(args[6]), Convert.ToInt32(args[7]));
                            break;

                        case RUN_DAILY_DUPLICATE_PATIENT_REPORT_BY_MRN:
                            DailyDuplicatePatientReportService ddprsvc2 = new DailyDuplicatePatientReportService(requestManager);
                            sUserGroupID = args[4];
                            int[] serviceAgreementIds2 = null;
                            if (args.Length >= 6)
                            {
                                try
                                {
                                    serviceAgreementIds2 = args[5].Split(',').Select(int.Parse).ToArray();
                                }
                                catch
                                {
                                    // Set serviceAgreementIds to null if the int.Parse conversion above is unsuccessful.
                                    serviceAgreementIds2 = null;
                                }
                            }
                            ddprsvc2.RunReportByMRNForMultSAs(Convert.ToInt32(facilityID), Convert.ToInt32(sUserGroupID), serviceAgreementIds2);
                            break;

                        case RUN_IMPORT_MEDICAL_SAVANT_DATA_SERVICE:
                            new ImportMedicalSavantDataService(requestManager).Import(facilityID);
                            break;

						case RUN_FACILITY_CHART_ARCHIVE_SERVICE:
							var facilityIds = string.Empty;
							if (args.Length > 4)
								facilityIds = args[4];
							new FacilityChartArchivingService(requestManager).ArchiveCharts(facilityIds);
							break;

						default:
                            Console.WriteLine("Unknown process ID:" + processID);
                            break;
                    }
                }
                else
                    Console.WriteLine("Invalid user ID and password:" + processID);
            }
            finally
            {
                requestManager.EndRequest();
            }
        }

        /// <summary>
        /// Prints out any error messages pending on the request to the console.
        /// </summary>
        /// <param name="aRequestManager">The request manager</param>
        public static void PrintErrors(IRequestManager aRequestManager)
        {
            if (aRequestManager.ErrorMessages.Count <= 0)
                return;

            Console.WriteLine("Errors:");

            foreach (ErrorMessage err in aRequestManager.ErrorMessages)
                Console.WriteLine(err.ToString());
        }
    }
}