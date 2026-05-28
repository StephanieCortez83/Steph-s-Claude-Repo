using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Common.Configuration
{
    public static class ConnectionString
    {
        public static string ACS => ConfigurationManager.ConnectionStrings["ClinicalCodingSolutionsConnectionString"].ConnectionString;
    }
}
