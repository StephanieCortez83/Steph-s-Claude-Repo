using System;
using System.IO;
using System.Reflection;
using Microsoft.Office.Interop.Excel;


namespace CCSImport
{
	/// <summary>
	/// Summary description for ExcelUtility.
	/// </summary>
	public class ExcelUtility
	{
		#region Fields
        Microsoft.Office.Interop.Excel.Application m_Excel;
        Microsoft.Office.Interop.Excel._Workbook m_Workbook;
        Microsoft.Office.Interop.Excel._Worksheet m_Sheet;
        Microsoft.Office.Interop.Excel.Range m_Range; 
		#endregion Fields
				
		#region Constructors
		public ExcelUtility()
		{
			SetDefault();
		}
		private void SetDefault() 
		{
			// Start up Excel
			GC.Collect();// clean up any other excel guys hangin' around...
			m_Excel = new Microsoft.Office.Interop.Excel.Application();
			m_Excel.Visible = false;
		}
		#endregion Constructors
		
		#region Properties
		public Microsoft.Office.Interop.Excel.Application ExcelApplication 
		{
			get {return m_Excel;}
		}
		public Microsoft.Office.Interop.Excel._Workbook Workbook 
		{
			get {return m_Workbook;}
		}
		public Microsoft.Office.Interop.Excel._Worksheet Sheet
		{
			get {return m_Sheet;}
		}
		public Microsoft.Office.Interop.Excel.Range Range 
		{
			get {return m_Range;}
		}
		#endregion Properties
				
				
		#region Methods
		public void Open(String fileName) 
		{
			m_Workbook = (Microsoft.Office.Interop.Excel._Workbook)(m_Excel.Workbooks.Open(fileName
				,Missing.Value,Missing.Value,Missing.Value,Missing.Value,Missing.Value,Missing.Value, Missing.Value
				,Missing.Value,Missing.Value,Missing.Value,Missing.Value,Missing.Value,Missing.Value, Missing.Value));
			m_Sheet = (Microsoft.Office.Interop.Excel._Worksheet)m_Workbook.ActiveSheet;
		}
		public void SaveAs(String fileName) 
		{
			m_Workbook.SaveAs( fileName,Microsoft.Office.Interop.Excel.XlFileFormat.xlWorkbookNormal,
				null,null,false,false,Microsoft.Office.Interop.Excel.XlSaveAsAccessMode.xlShared,false,false,null,null,null);
		}
		public void SaveAsCSV(String fileName) 
		{
			m_Workbook.SaveAs( fileName,Microsoft.Office.Interop.Excel.XlFileFormat.xlCSVWindows,
				null,null,false,false,Microsoft.Office.Interop.Excel.XlSaveAsAccessMode.xlShared,false,false,null,null,null);
		}
		public String Cell(int row, int column) 
		{
			return m_Sheet.Cells[row,column].ToString();
		}
		public void Stop() 
		{
			m_Workbook.Close(null,null,null);
			m_Excel.Workbooks.Close();
			m_Excel.Quit();
			System.Runtime.InteropServices.Marshal.ReleaseComObject (m_Range);
			System.Runtime.InteropServices.Marshal.ReleaseComObject (m_Excel);
			System.Runtime.InteropServices.Marshal.ReleaseComObject (m_Sheet);
			System.Runtime.InteropServices.Marshal.ReleaseComObject (m_Workbook);
			m_Sheet=null;
			m_Workbook=null;
			m_Excel = null;
			GC.Collect(); 
		}

		public void ConvertToCSV(String fn, String csvFN) 
		{
			// Start up Excel
			GC.Collect();
			m_Excel = new Microsoft.Office.Interop.Excel.Application();
			m_Excel.Visible = false;

			m_Workbook = (Microsoft.Office.Interop.Excel._Workbook)(m_Excel.Workbooks.Open(fn
				,Missing.Value,Missing.Value,Missing.Value,Missing.Value,Missing.Value,Missing.Value, Missing.Value
				,Missing.Value,Missing.Value,Missing.Value,Missing.Value,Missing.Value,Missing.Value, Missing.Value));

			try 
			{
				m_Excel.DisplayAlerts = false;
				m_Workbook.SaveAs( fn,Microsoft.Office.Interop.Excel.XlFileFormat.xlWorkbookNormal,
					null,null,false,false,Microsoft.Office.Interop.Excel.XlSaveAsAccessMode.xlShared,false,false,null,null,null);

				m_Workbook.SaveAs( csvFN,Microsoft.Office.Interop.Excel.XlFileFormat.xlCSVWindows,
					null,null,false,false,Microsoft.Office.Interop.Excel.XlSaveAsAccessMode.xlShared,false,false,null,null,null);
			}
			finally 
			{

				m_Workbook.Close(false,null,null);
				m_Excel.Workbooks.Close();
				m_Excel.Quit();
				System.Runtime.InteropServices.Marshal.ReleaseComObject (m_Excel);
				System.Runtime.InteropServices.Marshal.ReleaseComObject (m_Workbook);
				m_Workbook=null;
				m_Excel = null;
				GC.Collect(); 
			}

		}

        /// <summary>
        /// Converts the Excel file in the specified path to Excel 2003 format.
        /// </summary>
        /// <param name="path">The path.</param>
        public static void SaveIn2003Format(string path)
        {
            var app = new Application {Visible = false, DisplayAlerts = false};
            Workbook workbook = null;
            var dir = new DirectoryInfo(path);

            // loop through each Excel file in the directory and save it in 2003 format
            foreach (var file in dir.GetFiles("*.xls"))
            {
                try
                {
                    // open the workbook
                    workbook = app.Workbooks.Open(file.FullName, Missing.Value, Missing.Value, Missing.Value,
                                                  Missing.Value, Missing.Value, Missing.Value, Missing.Value,
                                                  Missing.Value, Missing.Value, Missing.Value, Missing.Value,
                                                  Missing.Value, Missing.Value, Missing.Value);

                    try
                    {
                        // save the file in 2003 format
                        workbook.SaveAs(file.FullName.Replace("xlsx", "xls"), XlFileFormat.xlWorkbookNormal,
                                        Type.Missing, Type.Missing, Type.Missing, Type.Missing,
                                        XlSaveAsAccessMode.xlNoChange, XlSaveConflictResolution.xlLocalSessionChanges,
                                        Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    }
                    finally
                    {
                        // close the workbook and release the resources for garbage collection
                        workbook.Close(false, file.FullName, null);
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine("Could not open WorkBook {0} ({1})", file.FullName, ex);
                }
                finally
                {
                    app.Quit();
                    System.Runtime.InteropServices.Marshal.ReleaseComObject(app);
                    if (workbook != null) System.Runtime.InteropServices.Marshal.ReleaseComObject(workbook);
                    GC.Collect();
                }
            }
        } 
		
		#endregion Methods
	}
}