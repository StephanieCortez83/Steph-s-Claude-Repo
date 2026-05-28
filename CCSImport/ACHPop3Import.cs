using System;
using MailBee.Pop3Mail;
using MailBee.Mime;
using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.Utility;
using CCSBusinessObjects.DAO;

namespace CCSImport
{
    /// <summary>
    /// This class uses the MailBee components to read email from check for mail at ccsach@clinicalcodingsolutions.com.
    /// It then selects the last message and saves the email attachment to a folder on the FTP server.
    /// </summary>
    public class ACHPop3Import
    {
        #region Fields

        AppConfiguration cfg = AppConfiguration.Instance();

        //private const String MAIL_SERVER = "mail.clinicalcodingsolutions.com";
        //private const String USERNAME = "ccsach";
        //private const String PASSWORD = "ca041310!";

        public String MAIL_SERVER
        {
            get
            {
                return cfg.MailServer; // Can't connect to POP3MailServer (LDH 08/06/2012)
            }
        }
        public String USERNAME
        {
            get
            {
                return cfg.POP3UserID;
            }
        }
        public String PASSWORD
        {
            get
            {
                return cfg.POP3Password;
            }
        }

        private IRequestManager m_RequestManager;
        #endregion Fields

        #region Constructors

        private ACHPop3Import()
        {
            // Hidden
        }

        public ACHPop3Import(IRequestManager aRequestManager)
        {
            m_RequestManager = aRequestManager;
        }

        #endregion Constructors

        #region Methods
        /// <summary>
        /// Gets the mail.
        /// </summary>
        /// <param name="saveFileLocation">The save file location.</param>
        public void GetMail(String saveFileLocation)
        {
            LogDAO batchLog = new LogDAO(m_RequestManager);

            try
            {
                batchLog.Write("Downloading ACH Recon Excel file from " + cfg.EmailAddress_Batch.ToString() + " at " +
                    DateTime.Now.ToString() + " to file location " + saveFileLocation + ".", +
                    ErrorMessage.ERROR_MESSAGE_SEVERITY_INFO, -1, "IMPORT");

                // connect the the server and download the message attachments
                using (Pop3 pop = new Pop3())
                {
                    // Connect to the Pop3 mail server
                    pop.Connect(MAIL_SERVER);
                    pop.Login(USERNAME, PASSWORD);

                    foreach (MailMessage msg in pop.DownloadEntireMessages())
                    {
                        // If message has attachment save to FTP server
                        if (msg.HasAttachments)
                        {
                            try
                            {
                                // Save email attachment to FTP server
                                msg.Attachments.SaveAll(saveFileLocation, true);

                                batchLog.Write("Download of ACH Recon Excel file to file location " + saveFileLocation + " completed successfully at " +
                                    DateTime.Now.ToString() + ".", ErrorMessage.ERROR_MESSAGE_SEVERITY_WARNING, -1, "IMPORT");

                                // Delete the message
                                /* NOTE: Messages flagged for deletion are actually removed 
                                 * from the server on Disconnect method call. Until this moment, 
                                 * the developer can remove the deletion status for all messages 
                                 * flagged as deleted by calling ResetDeletes method.*/
                                pop.DeleteMessage(msg.IndexOnServer);

                            } // End try

                            catch (Exception ex)
                            {
                                batchLog.Write("Download of ACH Recon Excel file failed at " + DateTime.Now.ToString() +
                                    "with error " + ex.ToString(), ErrorMessage.ERROR_MESSAGE_SEVERITY_INFO, -1, "IMPORT");
                            }
                        } // End if

                        else // there are no attachments
                        {
                            // Delete the message
                            /* NOTE: Messages flagged for deletion are actually removed 
                             * from the server on Disconnect method call. Until this moment, 
                             * the developer can remove the deletion status for all messages 
                             * flagged as deleted by calling ResetDeletes method.*/
                            pop.DeleteMessage(msg.IndexOnServer);
                        }

                    } // End for

                    //Disconnect from the server (commits DeleteMessage actions)
                    pop.Disconnect();

                } // End using
            } // End try

            catch (Exception ex)
            {
                batchLog.Write("Download of ACH Recon Excel file failed at " + DateTime.Now.ToString() +
                    "with error " + ex.ToString(), ErrorMessage.ERROR_MESSAGE_SEVERITY_INFO, -1, "IMPORT");
            }
        } // End GetMail
        #endregion Methods

    } // End class ACHPop3Import
} // End namespace CCSImport