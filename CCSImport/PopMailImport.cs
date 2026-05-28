using System;
using System.IO;
using System.Text;
using MailBee;
using MailBee.Pop3Mail;
using MailBee.Mime;
using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects;
using CCSBusinessObjects.Utility;
using CCSBusinessObjects.DAO;
using CCSBusinessObjects.InputTransforms;
using CCSBusinessObjects.DocumentImaging;

namespace CCSImport
{
	/// <summary>
	/// This class uses the MailBee components to read email.  It is not a part of the business objects project so that
	/// we can keep that project clean of 3rd party DLLs.
	/// </summary>
	public class PopMailImport
	{
		#region Fields
		private IRequestManager m_RequestManager;
		#endregion Fields

		private PopMailImport()  
		{
			// Hidden
		}

		public PopMailImport(IRequestManager aRequestManager)
		{
			m_RequestManager = aRequestManager;
		}

		#region Methods
		public void DoMail(int facilityID) 
		{
			int ignored = 0;
			int processed = 0;
			LogDAO log = new LogDAO(m_RequestManager);
			AppConfiguration cfg = AppConfiguration.Instance();

			Pop3 pop = new Pop3();

			ServiceAgreementDAO saDAO = new ServiceAgreementDAO(m_RequestManager);
			ServiceAgreement sa = saDAO.LoadCurrentForFacility(facilityID);

			if (sa == null) 
			{
				log.Write("Email Process Failed.  There is no active service agreement for facility " + facilityID.ToString(),BatchLogItem.ERROR_CODE_EXCEPTION);
				ErrorMessages errmsgs = m_RequestManager.ErrorMessages;
				ErrorMessage errMsg = new ErrorMessage(160,ErrorMessage.ERROR_MESSAGE_SEVERITY_EXCEPTION);
				errMsg.AddMessageData("%1",facilityID.ToString());
				errmsgs.Add(errMsg);
				return;
			}

			Facility facility = sa.Facility;
			String popAccount = sa.InboundEmailAccountName;
			String password = sa.InboundEmailPassword;
			String outputDirectory = sa.ImportDirectory;
			String startsWith = sa.InboundEmailSubject.Trim().ToUpper();
            String imagingStartsWith = sa.InboundEmailSubjectForImages.Trim().ToUpper();
			String mailServer = cfg.MailServer;

			try 
			{

				log.Write(facility.Name +  ": Starting Email Import Process at " + DateTime.Now.ToString(),BatchLogItem.ERROR_CODE_START_MESSAGE);

				// Attempt to connect to the server
				log.Write(facility.Name +  ": Connecting to " + mailServer + " at " + DateTime.Now.ToString());
				pop.Connect(mailServer);

				// Log on to the server given he POP account name
				log.Write(facility.Name +  ": Logging on as " + popAccount + " at " + DateTime.Now.ToString());
				pop.Login(popAccount, password);

				// Retrieve messages
				log.Write(facility.Name +  ": Retrieving mail at " + DateTime.Now.ToString());
				MailMessageCollection msgs = pop.DownloadMessageHeaders(); 

				log.Write(facility.Name + ": Looking for messages that have a subject line of: " + startsWith );

				log.Write(facility.Name +  ": Found " + msgs.Count.ToString() + " email message(s) at " + DateTime.Now.ToString());
				foreach (MailMessage msg in msgs)
				{
					String subject = msg.Subject.Trim().ToUpper();
					bool mailProblem = false;

                    // Determine whether the email should be processed.  It will be processed if its subject
                    // line matches the subject line specified in the service agreement for a census import
                    // or a imaging import.  If the imagingStartsWith has a length of 1, is an asteric and the subject line is
                    // blank, also process images.
                    bool emailShouldBeProcessed = false;
                    emailShouldBeProcessed = subject.StartsWith(startsWith) 
                        || (StringUtility.IsNumeric(subject))
                        || ((imagingStartsWith.Length > 0) && (subject.StartsWith(imagingStartsWith))
                        || ( (imagingStartsWith.Length==1) && ((imagingStartsWith[0]=='*') && (subject.Trim().Length == 0)) )
                        );

					// Only process imports that have the matching subject line as per the service agreement
					if (emailShouldBeProcessed)
					{
						log.Write(facility.Name +  ": Found email with charts file at " + DateTime.Now.ToString());
						MailMessage thisMessage = pop.DownloadEntireMessage(msg.IndexOnServer);

						// If the charts are suppose to be in an attachment
						if (sa.InboundEmailChartsLocation == ServiceAgreement.EMAIL_CHARTS_ARE_IN_ATTACHMENTS) 
						{
							processed ++;
							// For every attachment from the attachments collection...
							foreach (Attachment attach in thisMessage.Attachments)
							{
								log.Write(facility.Name +  ": Attachment has name:" + attach.Name + " and file name: " + attach.Filename + " original name:" + attach.FilenameOriginal);
								// Some email systems send other crud as an attachment.  Use this as a method to bypass the other
								// crud and make sure we are only processing charts.
								if (   (attach.Name.Trim().Length != 0)
                                    || (IsImageFile(attach.Filename))
                                    || (IsImageFile(attach.FilenameOriginal))
                                   )
								{
									if (attach.IsTnef)
									{
										log.Write(facility.Name +  ": Decoding TNEF attachment at " + DateTime.Now.ToString());
										MailBee.Mime.AttachmentCollection tnefs = attach.GetAttachmentsFromTnef();
										foreach(Attachment tnefAttach in tnefs) 
										{
											String fn  = CleanFileName(outputDirectory + tnefAttach.Name);
											if (IsExcelFile(fn)) 
											{
												log.Write(facility.Name +  ": Saving TNEF as " + fn + "  at " + DateTime.Now.ToString());
												tnefAttach.Save(fn, true);

                                                // If the excel file is suppose to be converted, convert it
                                                if (sa.InboundFileConvertExcelToCSV)
                                                {
                                                    log.Write(facility.Name + ": Convert " + fn + "  to CSV format at" + DateTime.Now.ToString());
                                                    ConvertExcelToCSV(sa, fn, thisMessage, facility);
                                                }
											}
											else 
											{
                                                if (IsImageFile(tnefAttach.Name) || (IsImageFile(tnefAttach.Filename)) || (IsImageFile(tnefAttach.FilenameOriginal)))
                                                {
                                                    SaveImageFile(tnefAttach, sa);
                                                }
                                                else
                                                {
                                                    if (IsMetaPrtFile(fn))
                                                    {
                                                        String newMetaPrtFileName = GetNewMetaPrtFN(outputDirectory, fn);
                                                        log.Write(facility.Name + ": Saving TNEF METAPRT as " + newMetaPrtFileName + "  at " + DateTime.Now.ToString());
                                                        tnefAttach.Save(newMetaPrtFileName, true);
                                                    }
                                                    else
                                                    {
                                                        String newfn = GetFileNameFromTransform(sa, thisMessage.DateReceived);
                                                        log.Write(facility.Name + ": Saving " + tnefAttach.Name + " as " + newfn + "  at " + DateTime.Now.ToString());
                                                        tnefAttach.Save(newfn, true);
                                                    }
                                                }
											}
										}
									}
									else 
									{
										// Save the attachment to the output directory using its original name
										String fn = CleanFileName(outputDirectory + attach.Filename);
										if (IsExcelFile(fn)) 
										{
											log.Write(facility.Name +  ": Saving " + fn + "  at " + DateTime.Now.ToString());
											attach.Save(fn, true);

                                            // If the excel file is suppose to be converted, convert it
                                            if (sa.InboundFileConvertExcelToCSV)
                                            {
                                                log.Write(facility.Name + ": Convert " + fn + "  to CSV format at " + DateTime.Now.ToString());
                                                ConvertExcelToCSV(sa, fn, thisMessage, facility);
                                            }
										}									
										else 
										{
                                            if (IsImageFile(fn) || IsImageFile(attach.FilenameOriginal))
                                            {
                                                SaveImageFile(attach, sa);
                                            }
                                            else
                                            {
                                                if (IsMetaPrtFile(fn))
                                                {
                                                    String newMetaPrtFileName = GetNewMetaPrtFN(outputDirectory,fn);
                                                    log.Write(facility.Name + ": Saving METAPRT as " + newMetaPrtFileName + "  at " + DateTime.Now.ToString());
                                                    attach.Save(newMetaPrtFileName, true);
                                                }
                                                else
                                                {
                                                    String newfn = GetFileNameFromTransform(sa, thisMessage.DateReceived);
                                                    log.Write(facility.Name + ": Saving " + attach.Filename + " as " + newfn + "  at " + DateTime.Now.ToString());
                                                    attach.Save(newfn, true);
                                                }
                                            }
										}
									}
								}
								else 
								{
									log.Write(facility.Name +  ": Skipping attachment with blank file name that also does not appear to be an image." );
								}
							}
						}
						else 
						{
							// Charts data could be in the message body
							String fn = GetFileNameFromTransform(sa, thisMessage.DateReceived);

							// Create an instance of StreamWriter to write text to a file.
							try 
							{
								log.Write(facility.Name +  ": Writing message body to file " + fn);
								if (File.Exists(fn)) 
								{
									File.Delete(fn);
								}
								StreamWriter sw = File.CreateText(fn);
								sw.Write(msg.BodyPlainText);
								sw.Close();
								log.Write(facility.Name +  ": File has been written.");
							}
							catch (Exception ex) 
							{
								mailProblem = true;
								log.Write(facility.Name +  ": Exception occurred writing message body to file.",BatchLogItem.ERROR_CODE_EXCEPTION);
								log.Write(facility.Name +  ": " + ex.Message.ToString());
							}


						}

						try 
						{
							// Clean up message
							if (!mailProblem) 
							{
								pop.DeleteMessage(msg.IndexOnServer);
							}
						}
						catch (Exception) 
						{
							log.Write(facility.Name +  ": Unable to delete email message after processing.",BatchLogItem.ERROR_CODE_INFO);
						}

					}
					else
					{
						ignored ++;
					}

				}
			}
			catch (Exception ex) 
			{

				log.Write("Email import failed:" + ex.Message.ToString(),BatchLogItem.ERROR_CODE_EXCEPTION); 
				ErrorMessages errmsgs = m_RequestManager.ErrorMessages;
				ErrorMessage errMsg = new ErrorMessage(161,ErrorMessage.ERROR_MESSAGE_SEVERITY_EXCEPTION);
				errMsg.AddMessageData("%1",ex.Message.ToString());
				errmsgs.Add(errMsg);
			}
			finally 
			{
				try 
				{
					pop.Disconnect();
				}
				catch (Exception) 
				{
				}
			}

			// Write closing message
			log.Write(facility.Name +  ": " + processed.ToString() + " messages processed and " + ignored.ToString() + " messages ignored.",BatchLogItem.ERROR_CODE_COMPLETE_MESSAGE);

		}

		private String ChangeXLStoCSV(String inFN) 
		{
			return inFN.ToUpper().Replace(".XLS",".CSV");
		}

		private bool IsExcelFile(String fn) 
		{
			return (fn.Trim().ToUpper().EndsWith(".XLS"));
		}

        private bool IsMetaPrtFile(String fn)
        {
            return (fn.ToUpper().Contains("METAPRT"));
        }


        private bool IsImageFile(String fn)
        {
            bool res = false;
            String afn = fn.Trim().ToUpper();
            res = afn.EndsWith(".PDF");
            res = res || afn.EndsWith(".TIF");
            res = res || afn.EndsWith(".TIFF");
            return (res);
        }

        /// <summary>
        /// Constructs the metaprt output directory given the service agreements base
        /// directory (the new directory is the base directory + \\Metaprt.  The old file
        /// name is converted to the new file name so that the metaprt files are placed in a
        /// separate directory from the census files.  The metaprt file name is converted to
        /// a unique name so no overlay occurs if they send us stuff twice.
        /// </summary>
        /// <param name="outputDirectory"></param>
        /// <param name="oldFN"></param>
        /// <returns></returns>
        private String GetNewMetaPrtFN(String outputDirectory, String oldFN)
        {
            String newDirectory = outputDirectory + "METAPRT";
            if (!Directory.Exists(newDirectory))
            {
                Directory.CreateDirectory(newDirectory);
            }
            
            DateTime dt = DateTime.Now;
            String dtString = dt.Year.ToString()
                            + dt.Month.ToString().PadLeft(2, '0')
                            + dt.Day.ToString().PadLeft(2, '0')
                            + dt.Hour.ToString().PadLeft(2, '0')
                            + dt.Minute.ToString().PadLeft(2, '0')
                            + dt.Second.ToString().PadLeft(2, '0');

            String newFN = Path.GetFileNameWithoutExtension(oldFN)+ "_" + dtString + Path.GetExtension(oldFN);
            String fullFileName = newDirectory + "\\" + newFN;
            return fullFileName;
        }

        /// <summary>
        /// Saves an image attachment to an email into the service agreements import directory
        /// in the imaging section.
        /// </summary>
        /// <param name="attachment"></param>
        /// <param name="sa"></param>
        private void SaveImageFile(Attachment attachment, ServiceAgreement sa)
        {
            LogDAO log = new LogDAO(m_RequestManager);

            // Use the input transform of this service agreement to determine where to place
            // the images and what to name them.
            ImageImportTransformManager iitm = new ImageImportTransformManager(m_RequestManager);
            IImageImportTransform transform = iitm.GetTransform(sa.ImagingMethodID, sa.ServiceAgreementID);

            // Locate the imaging parent directory for this service agreement.  If it isn't
            // found, create it.
            String rootImagingDirectory = transform.GetRootImagingDirectory();
            if (!Directory.Exists(rootImagingDirectory))
            {
                Directory.CreateDirectory(rootImagingDirectory);
            }

            // Locate the directory for today's images.  If it isn't found, create it.
            String currentImagingDirectory = transform.GetCurrentImagingDirectory(DateTime.Now);
            if (!Directory.Exists(currentImagingDirectory))
            {
                Directory.CreateDirectory(currentImagingDirectory);
            }

            String newfn = transform.GetImportImageFileName(attachment.Filename, DateTime.Now, currentImagingDirectory);

            // Save the image
            log.Write(sa.Facility.Name + ": Saving image file " + attachment.Filename + " as " + newfn + "  at " + DateTime.Now.ToString());
            attachment.Save(newfn, true);

        }

		private String CleanFileName(String oldFileName) 
		{
			// Excel can't handle brackets in the file name during CSV conversion.
			String newFileName = oldFileName.Trim().Replace("[","");
			newFileName = newFileName.Replace("]","");
			return newFileName;
		}

		private void ConvertExcelToCSV(ServiceAgreement sa, String fn, MailMessage thisMessage, Facility facility) 
		{
			ExcelUtility excelUtil = new ExcelUtility();
			LogDAO log = new LogDAO(m_RequestManager);
			// If file is excel, convert it to CSV for import preperation
			try 
			{
				String fnAsCSV = GetFileNameFromTransform(sa,thisMessage.DateReceived);
				log.Write(facility.Name + ": Writing " + fnAsCSV);
				excelUtil.ConvertToCSV(fn,fnAsCSV);
				// Delete the excel formatted file as we now have the CSV
				if (File.Exists(fn)) 
				{
					File.Delete(fn);
				}
			}
			catch (Exception ex) 
			{
				log.Write("Email import failed in ConvertExcelToCSV:" + ex.Message.ToString(),BatchLogItem.ERROR_CODE_EXCEPTION); 
				ErrorMessages errmsgs = m_RequestManager.ErrorMessages;
				ErrorMessage errMsg = new ErrorMessage(161,ErrorMessage.ERROR_MESSAGE_SEVERITY_EXCEPTION);
				errMsg.AddMessageData("%1",ex.Message.ToString());
				errmsgs.Add(errMsg);
			}
		}

		private String GetFileNameFromTransform(ServiceAgreement sa, DateTime dt) 
		{
			String res = "";
			InputTransformManager itm = new InputTransformManager(m_RequestManager);
			IInputTransform transform = itm.GetTransform(sa.ImportMethodID, sa.ServiceAgreementID);

			if (transform != null) 
			{
				res = transform.GetImportFileName(dt);
			}
			else 
			{
				res = "";
			}
			return res;
		}

		#endregion Methods

	}
}
