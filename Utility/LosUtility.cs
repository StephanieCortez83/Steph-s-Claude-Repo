using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web.UI;

namespace ACS.Core.Utility
{
    public class LosUtility
    {
        public static string ToLos(object value)
        {
            var stringWriter = new StringWriter();
            new LosFormatter().Serialize((TextWriter)stringWriter, value);
            return stringWriter.ToString();
        }

        public static object FromLos(string los)
        {
            return new LosFormatter().Deserialize(los);
        }
    }
}
