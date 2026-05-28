using System;
using System.IO;
using System.Text;
using System.Net.Mail;
using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects;
using CCSBusinessObjects.Utility;
using CCSBusinessObjects.DAO;
using CCSBusinessObjects.InputTransforms;
using CCSBusinessObjects.OutputTransforms;
using CCSBusinessObjects.Transmitters;

namespace CCSImport
{
	/// <summary>
	/// This class uses the MailBee components to read email.  It is not a part of the business objects project so that
	/// we can keep that project clean of 3rd party DLLs.
	/// </summary>
	public class EmailExport
	{
		#region Fields
		private IRequestManager m_RequestManager;
		#endregion Fields

		private EmailExport() 
		{
			// Hidden
		}

		public EmailExport(IRequestManager aRequestManager)
		{
			m_RequestManager = aRequestManager;
		}

		#region Methods
		public void DoExport(int facilityID, String filePattern) 
		{

			LogDAO log = new LogDAO(m_RequestManager);
			AppConfiguration cfg = AppConfiguration.Instance();

			Facility facility = new Facility(facilityID,m_RequestManager);
			ServiceAgreement sa = facility.ActiveServiceAgreement;

			if ((sa == null) || (facility == null))
			{
				log.Write("Email Export Process Failed.  There is no active service agreement for facility " + facilityID.ToString(),BatchLogItem.ERROR_CODE_EXCEPTION, facilityID, "EMAIL EXPORT");
				ErrorMessages errmsgs = m_RequestManager.ErrorMessages;
				ErrorMessage errMsg = new ErrorMessage(160,ErrorMessage.ERROR_MESSAGE_SEVERITY_EXCEPTION);
				errMsg.AddMessageData("%1",facilityID.ToString());
				errmsgs.Add(errMsg);
				return;
			}

			try 
			{
                log.Write(facility.Name + ": Email Export beginning at " + DateTime.Now.ToString(), BatchLogItem.ERROR_CODE_START_MESSAGE, facility.FacilityID, "EMAIL EXPORT");

				// Prepare the data for the mail message
				String outputDirectory = sa.DeliverTo;
				String recipients = sa.ExportDeliveryNotification;
				String sender = EMAILTransmitter.EMAIL_SENDER;
				String subject = "CCS Transmission for: " + DateTime.Now.ToString();
				String msgBody = "Chart results for " + DateTime.Now.ToShortDateString() + " are attached.  You may also download these files from our web site at https://www.clinicalcodingsolutions.com";

				MailMessage msgMail = new MailMessage();
                EmailUtility.AddRecipientsToMailMessage(recipients, msgMail);
                msgMail.From = new System.Net.Mail.MailAddress(sender); 
				msgMail.Subject = subject;
				msgMail.Body = msgBody;

				// Gather up all matching files and add them as attachments
				DirectoryInfo dirInfo = new DirectoryInfo(outputDirectory );
				System.IO.FileInfo[] fileInfo = dirInfo.GetFiles(filePattern);

				if (fileInfo.Length > 0) 
				{

					// Drop in any attachments
					for(int i=0; i< fileInfo.Length; i++) 
					{
						msgMail.Attachments.Add(new Attachment(fileInfo[i].FullName));
					}
					log.Write(facility.Name +  ": Email formatted for delivery at " + DateTime.Now.ToString(),BatchLogItem.ERROR_CODE_INFO, facilityID, "EMAIL EXPORT");

					// Send the mail
                    SmtpClient smtp = new SmtpClient(AppConfiguration.Instance().SMTPServer);
                    smtp.Send(msgMail);

                    // Clean up
                    msgMail.Dispose();

                    log.Write(facility.Name + ": Email Export Sent at " + DateTime.Now.ToString(), BatchLogItem.ERROR_CODE_COMPLETE_MESSAGE, facility.FacilityID, "EMAIL EXPORT");

					// Move all of the files that were sent to the archive output directory
					for(int i=0; i< fileInfo.Length; i++) 
					{				
						String archiveDirectory = outputDirectory + "ARCHIVE\\";
						if (!Directory.Exists(archiveDirectory)) 
						{
							Directory.CreateDirectory(archiveDirectory);
						}
						String newName = archiveDirectory + fileInfo[i].Name;
						fileInfo[i].MoveTo(newName);
					}

                    log.Write(facility.Name + ": Email Exports moved to archive directory at " + DateTime.Now.ToString(), BatchLogItem.ERROR_CODE_COMPLETE_MESSAGE, facility.FacilityID, "EMAIL EXPORT");
				}
				else 
				{
                    log.Write(facility.Name + ": Email Exports found no files to deliver so no email was sent." + DateTime.Now.ToString(), BatchLogItem.ERROR_CODE_COMPLETE_MESSAGE, facility.FacilityID, "EMAIL EXPORT");
				}

			}
			catch (Exception ex) 
			{
                log.Write("Email export failed:" + ex.Message.ToString(), BatchLogItem.ERROR_CODE_EXCEPTION, facility.FacilityID,  "EMAIL EXPORT"); 
				ErrorMessages errmsgs = m_RequestManager.ErrorMessages;
				ErrorMessage errMsg = new ErrorMessage(161,ErrorMessage.ERROR_MESSAGE_SEVERITY_EXCEPTION);
				errMsg.AddMessageData("%1",ex.Message.ToString());
				errmsgs.Add(errMsg);
			}
			finally 
			{
			}
		}

		#endregion Methods

	}
}
