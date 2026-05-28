using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects;
using CCSBusinessObjects.BusinessObjects.Service;
using CCSBusinessObjects.DAO;
using CCSBusinessObjects.DAO.Common;
using NLog;
using NLog.Web;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading;
using System.Web;
using System.Web.UI.WebControls;

namespace CCSWeb.WebPages
{
	public partial class _Warmup : CCSBasePage
	{
		#region internals

		private static Logger _loggerELMAH = NLogBuilder.ConfigureNLog("NLog.config").GetLogger("ELMAH");
		private int _chartId;
		private Chart _chart;
		private ChartDAO chartDao;
		private ServiceAgreement _serviceAgreement;
		private UserProfile _signedOnUserProfile;
		private Stopwatch _stopwatch = new Stopwatch();

		#endregion internals

		#region properties

		public IFacilityDAO FacilityDao { get; set; }
		public IServiceAgreementDAO ServiceAgreementDao { get; set; }
		public IChartPostBillAuditService ChartPostBillAuditService { get; set; }

		#endregion properties

		#region events

		public int Page_Load(object sender, System.EventArgs e, bool useDebugDisplay = true)
		{
			// do not allow this to cause an exception redirection message
			try
			{
				m_RequestManager = new WebRequestManager(HttpContext.Current.Session);
				var warmupDAO = new WarmupDao(m_RequestManager);

				if (!warmupDAO.IsWarmupAllowed())
				{
					_loggerELMAH.Info($"_Warmup Page called at {DateTime.Now} without satisfying state.\r\n");
					if (useDebugDisplay)
					{
						txtDebugInfo.Text = $"_Warmup Page called at {DateTime.Now} (0)\r\n";
						Response.Redirect("News.aspx");
					}

					return 0;
				}

				_loggerELMAH.Info($"_Warmup Page called at {DateTime.Now}\r\n");
				if (useDebugDisplay) txtDebugInfo.Text = $"_Warmup Page called at {DateTime.Now}\r\n";

				if (!IsPostBack)
				{
					if (HttpContext.Current?.Request == null)
					{
						_loggerELMAH.Fatal($"_Warmup Page Cannot access Request object.");
						if (useDebugDisplay) Response.Redirect("News.aspx");
						return -2;
					}

					var urlReferrer = HttpContext.Current?.Request.UrlReferrer?.ToString().Trim().ToLower();
					var validReferrers = new List<string>() {
							"localhost",
							"::0",
							"::1",
							"127.0.0.1",
							"52.185.79.235", // acs-prodalt.tsystem.com, acs.tsystem.com, pulse-mips.corrohealth.com,pulse-multicare.corrohealth.com 
							"168.61.210.50", // dev-acs.tsystem.com, qa-acs.tsystem.com
							"40.77.56.44",	 // staging-acs.tsystem.com
                            // add internal IPs of servers that are allowed.  might need to pull from azure kv in some manner to be safe.
						  };

					//check the referrer to see if valid
					if (!string.IsNullOrEmpty(urlReferrer) && !validReferrers.Contains(urlReferrer))
					{
						_loggerELMAH.Error($"_Warmup Page Invalid access referrer :: {urlReferrer}");
						if (useDebugDisplay) Response.Redirect("News.aspx");
						return -3;
					}

					if (_stopwatch == null)
						_stopwatch = new Stopwatch();

					if (_stopwatch != null)
						_stopwatch.Start();

					m_RequestManager = new WebRequestManager(HttpContext.Current.Session);

					// Make sure our ServiceAgreementDao Property is in the correct state.
					if (ServiceAgreementDao == null)
						ServiceAgreementDao = new ServiceAgreementDAO(m_RequestManager);

					if (!ServiceAgreementDao.IsServiceValid())
						ServiceAgreementDao = new ServiceAgreementDAO(m_RequestManager);

					chartDao = new ChartDAO(m_RequestManager);
					_chartId = chartDao.GetLatestCreatedChartId();

					_chart = new Chart(_chartId, m_RequestManager);
					if (_chart == null || _chart.ChartID != _chartId)
					{
						if (useDebugDisplay) txtDebugInfo.Text += $"\r\n Warmup Exception: Chart Object is invalid. [{_chartId}]\r\n";
						_loggerELMAH.Error($"\r\n Warmup Exception: Chart Object is invalid. [{_chartId}]\r\n");
						throw new Exception($"Warmup Exception: Chart Object is invalid. [{_chartId}]");
					}

					// get its said
					_serviceAgreement = new ServiceAgreement(_chart.ServiceAgreementID, m_RequestManager);
					if (_serviceAgreement == null || _serviceAgreement.ServiceAgreementID != _chart.ServiceAgreementID)
					{
						if (useDebugDisplay) txtDebugInfo.Text += $"\r\n Warmup Exception: Chart SA Object is invalid. [{_chart.ServiceAgreementID}]\r\n";
						_loggerELMAH.Error($"\r\n Warmup Exception: Chart SA Object is invalid. [{_chart.ServiceAgreementID}]\r\n");
						throw new Exception($"Warmup Exception: Chart SA Object is invalid. [{_chart.ServiceAgreementID}]");
					}

					m_RequestManager.SessionManager.SelectedFacilityID = _chart.FacilityID.ToString();

					if (_serviceAgreement.FacilityID != _chart.FacilityID)
					{
						if (useDebugDisplay) txtDebugInfo.Text += $"\r\n Warmup Exception: Chart SA Object is invalid. [{_chart.FacilityID}]\r\n";
						_loggerELMAH.Error($"\r\n Warmup Exception: Chart SA Object is invalid. [{_chart.FacilityID}]\r\n");
						throw new Exception($"Warmup Exception: Chart SA Object is invalid. [{_chart.FacilityID}]");
					}

					// get its assignee
					var upDao = new UserProfileDAO(m_RequestManager);
					_signedOnUserProfile = upDao.Load(_chart.AssignedToUserProfileID);
					if (_signedOnUserProfile == null || _signedOnUserProfile.UserProfileID != _chart.AssignedToUserProfileID)
					{
						if (useDebugDisplay) txtDebugInfo.Text += $"\r\n Warmup Exception: Chart UP Object is invalid. [{_chart.AssignedToUserProfileID}]\r\n";
						_loggerELMAH.Error($"\r\n Warmup Exception: Chart UP Object is invalid. [{_chart.AssignedToUserProfileID}]\r\n");
						throw new Exception($"Warmup Exception: Chart UP Object is invalid. [{_chart.AssignedToUserProfileID}]");
					}

					m_RequestManager.SessionManager.SignedOnUserProfileID = _signedOnUserProfile.UserProfileID.ToStringOrDefault();
					m_RequestManager.SessionManager.SignedOnUserProfile = _signedOnUserProfile;
					RequestManager.SessionManager.SelectedServiceAgreementID = _serviceAgreement.ServiceAgreementID.ToString();

					//!!!!!!!!!!!!!!!!!!!!!!  Initialize a bunch of DLLs  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					new SimpleFacilityProfessionalsListDAO(m_RequestManager).LoadAllForRole(_chart.TimeOfService, _chart.FacilityID, FacilityProfessionalRole.LOCUM_TENENS, FacilityProfessionalRole.PHYSICIAN);
					new ChargeMasterDepartmentDAO(m_RequestManager).Load(_chart.InitialChargeMasterDeptID);
					new SimpleFacilitiesListDAO(m_RequestManager).GetAuthorizedFacilitiesByUserProfileId(Convert.ToInt32(m_RequestManager.SessionManager.SignedOnUserProfileID));
					new SimpleUsersListDAO(m_RequestManager).LoadAllWithChartAuthorityOrAssignedToAndFacilityAccess(Convert.ToInt32(m_RequestManager.SessionManager.SignedOnUserProfileID), _chart.AssignedToUserProfileID, _chart.FacilityID);
					new SimplePatientDispositionListDAO(m_RequestManager).LoadAll(false);
					new ServiceAgreementPendingReasonDAO(m_RequestManager).LoadAllForServiceAgreementAndChart(_chart.ServiceAgreementID, _chart);
					new PatientDispositionMapDAO(m_RequestManager).LoadAllActive(_chart);
					new FacilityFinancialClassDAO(m_RequestManager).LoadForAgreement(_chart.ServiceAgreementID, 0, "ASC");
					new PatientClassDAO(m_RequestManager).LoadEffectiveForChart(_chart);

					var clDAO = new ClinicListDAO(m_RequestManager);
					clDAO.LoadAllForServiceAgreement(_chart.ServiceAgreementID, _chart.TimeOfService);
					clDAO.LoadDefaultClinicIdForServiceAgreement(_chart.ServiceAgreementID);
					new ConsultingPhysicianDAO(m_RequestManager).LoadAllForChart(_chartId);

					using (CCSDBDataContext _db = new CCSDBDataContext(m_RequestManager.DB))
					{
						var arrivalModes = _db.SERVICE_AGREEMENT_ARRIVAL_MODEs
											.Where(m => m.SERVICE_AGREEMENT_ID.Equals(_serviceAgreement.ServiceAgreementID) &&
											(m.EXPIRATION_DATE == null || m.EFFECTIVE_DATE <= _chart.TimeOfService && m.EXPIRATION_DATE >= _chart.TimeOfService))
											.Select(m => new ListItem(m.DESCRIPTION, m.SERVICE_AGREEMENT_ARRIVAL_MODE_ID.ToString())).ToList();
					}

					new ServiceAgreementPayorDAO(m_RequestManager).LoadAllForServiceAgreement(_serviceAgreement.ServiceAgreementID, _chart.TimeOfService);
					new ServiceAgreementTransferFacilityDAO(RequestManager);

					m_RequestManager.SessionManager.SelectedChartID = _chartId.ToString();

					var cmbAssignedTo = m_RequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_REASSIGN_CHARTS) &&
						!ServiceAgreementDao.IsChartAssignmentOnFirstView(_chartId) &&
						!_signedOnUserProfile.HasRight(UserRight.RIGHT_FORCE_BEGIN_CODING);

					new LogNotesListDAO(m_RequestManager).Load(_chartId, "", -1, LogNote.CATEGORY_DASHBOARD_NOTE, 0, "DESC");
					new PatientDispositionMapItemDAO(m_RequestManager).Load(_chart.PatientDispositionMapID);
					new ChargeMasterDepartmentDAO(m_RequestManager).LoadAllActiveObservationDeptsForServiceAgreement(_chart.ServiceAgreementID, _chart.TimeOfService);
					new ServiceAgreementObservationPatientArrivalSourceDAO(m_RequestManager).LoadAllArrivalSourcesForServiceAgreement(_chart.ServiceAgreementID);
					new ServiceAgreementModeOfDepartureDAO(m_RequestManager).LoadAll(_serviceAgreement.ServiceAgreementID);
					new UserProfileDAO(m_RequestManager).IsEmergencyOnlyCoder(m_RequestManager.SessionManager.SignedOnUserProfile.UserProfileID, _chart.FacilityID);
					new ClinicalCodingSolutions();
					new ChartMaster();
					new ServiceAgreementMasterPage();

					// Chart audit page (separate DLLs to load from the the normal chart functionality)
					new ChartAuditIbexToCCSReconciliationDAO(m_RequestManager);
					new ExcludeFromQAReportReasonDAO(m_RequestManager);
					new ChartAuditCommentsDAO(m_RequestManager).Load(_chartId);
					new ChartPhysicianLevelOfServiceeDAO(m_RequestManager).LoadAllForChartIncludingFirstLevel(_chartId);
					ChartPostBillAuditService?.GetChartPostBillAuditByChartId(_chartId);

					var res = Tuple.Create(-1,-1,string.Empty);
					Exception exLast = null;

					try { res = LoadWebFormAsString("~/WebPages/FacilitiesView.aspx"); } catch (Exception ex) { exLast = ex; }
					_loggerELMAH.Info($"\r\n Warmup Fac List: [seconds, length, first 500 chars] :: [{res.Item1},{res.Item1},{res.Item3.TakeFirst(500)}] :: [{(exLast == null ? string.Empty : exLast.Message)}]\r\n");

					exLast = null;
					try { res = LoadWebFormAsString("~/WebPages/ChartsView.aspx"); } catch(Exception ex) { exLast = ex; }
					_loggerELMAH.Info($"\r\n Warmup ChartsView: [seconds, length, first 500 chars] :: [{res.Item1},{res.Item1},{res.Item3.TakeFirst(500)}] :: [{(exLast == null ? string.Empty : exLast.Message)}]\r\n");

					exLast = null;
					try { res = LoadWebFormAsString("~/WebPages/ReportView.aspx"); } catch(Exception ex) { exLast = ex; }
					_loggerELMAH.Info($"\r\n Warmup ReportView: [seconds, length, first 500 chars] :: [{res.Item1},{res.Item1},{res.Item3.TakeFirst(500)}] :: [{(exLast == null ? string.Empty : exLast.Message)}]\r\n");

					exLast = null;
					try { res = LoadWebFormAsString("~/WebPages/MyProfileView.aspx"); } catch(Exception ex) { exLast = ex; }
					_loggerELMAH.Info($"\r\n Warmup MyProfileView: [seconds, length, first 500 chars] :: [{res.Item1},{res.Item1},{res.Item3.TakeFirst(500)}] :: [{(exLast == null ? string.Empty : exLast.Message)}]\r\n");

					exLast = null;
					try { res = LoadWebFormAsString("~/WebPages/ChartDiagnosisCodesICD10StandAlone.aspx"); } catch(Exception ex) { exLast = ex; }
					_loggerELMAH.Info($"\r\n Warmup ChartDiagnosisCodesICD10StandAlone: [seconds, length, first 500 chars] :: [{res.Item1},{res.Item1},{res.Item3.TakeFirst(500)}] :: [{(exLast == null ? string.Empty : exLast.Message)}]\r\n");

					exLast = null;
					try { res = LoadWebFormAsString("~/WebPages/AnalyticalReportViewer.aspx"); } catch (Exception ex) { exLast = ex; Thread.ResetAbort(); }
					_loggerELMAH.Info($"\r\n Warmup Analytics: [seconds, length, first 500 chars] :: [{res.Item1},{res.Item1},{res.Item3.TakeFirst(500)}] :: [{(exLast == null ? string.Empty : exLast.Message)}]\r\n");

					exLast = null;
					try { res = LoadWebFormAsString("~/WebPages/ServiceAgreementDetailsView.aspx"); } catch (Exception ex) { exLast = ex; Thread.ResetAbort(); }
					_loggerELMAH.Info($"\r\n Warmup SA Details: [seconds, length, first 500 chars] :: [{res.Item1},{res.Item1},{res.Item3.TakeFirst(500)}] :: [{(exLast == null ? string.Empty : exLast.Message)}]\r\n");

					if (_stopwatch != null)
					{
						_stopwatch.Stop();
						_loggerELMAH.Info("_Warmup Page process duration: {0.0000}s", _stopwatch.Elapsed.TotalSeconds);
						if (useDebugDisplay) txtDebugInfo.Text += $"_Warmup Page process duration =  {_stopwatch.Elapsed.TotalSeconds}\r\n";

						var debugElmahInfo = warmupDAO.LogWarmupEvent("Warmup"
							, AppConfiguration.Instance().ApplicationName.TakeFirst(60)
							, GetWebsiteUrl()
							, (int)_stopwatch.Elapsed.TotalSeconds);

						if (useDebugDisplay) txtDebugInfo.Text += $"\r\n ELMAH Error record created : {debugElmahInfo}.\r\n";
						return 1;
					}
				}
				else
					if (useDebugDisplay) Response.Redirect("News.aspx");
			}
			catch (Exception ex)
			{
				_loggerELMAH.Error($"_Warmup Page Exception ::{ex.Message} \r\n {ex.StackTrace}\r\n");
				if (useDebugDisplay) Response.Redirect("News.aspx");
				return -10;
			}

			return 0;
		}

		#endregion events

		#region methods

		public string ElmahLogStartup()
		{
			try
			{
				return new WarmupDao(m_RequestManager).LogWarmupEvent("Startup"
					, AppConfiguration.Instance().ApplicationName.TakeFirst(60)
					, GetWebsiteUrl()) ?? string.Empty;
			}
			catch (Exception ex)
			{
				// swallow all errors - do not care why it fails, cannot have it causing trouble
				_loggerELMAH.Error($"ElmahLogStartup() Exception ::{ex.Message} \r\n {ex.StackTrace}\r\n");
				return string.Empty;
			}
		}

		private string GetWebsiteUrl() =>
			AppConfiguration.Instance().WebsiteURL.Replace("https://", string.Empty).Replace("/", string.Empty).TakeFirst(30);

		public static Tuple<int, int, string> LoadWebFormAsString(string uri)
		{
			using (var stringWriter = new StringWriter())
			{
				var stopwatch = new Stopwatch();
				stopwatch.Start();
				HttpContext.Current.Server.Execute(uri, stringWriter);
				stopwatch.Stop();
				var res = stringWriter.ToString();
				return Tuple.Create((int)stopwatch.Elapsed.TotalSeconds, string.IsNullOrWhiteSpace(res) ? -1 : res.Length, res);
			}
		}

		#endregion methods

	}
}
