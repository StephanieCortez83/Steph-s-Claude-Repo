using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using ACS.Core.Common.Attribute;

namespace ACS.Core.Extensions
{
    public static class PropertyExtensions
    {
        public static string GetDisplayName(this PropertyInfo property)
        {
            var displayAttribute = property.GetCustomAttributes(typeof(DisplayAttribute), false);
            var displayName = displayAttribute.Length > 0 ? ((DisplayAttribute)displayAttribute[0]).Name : property.Name;

            return displayName;
        }

        public static string GetDataSourceFieldName(this PropertyInfo property, bool includeSourcePrefix)
        {
            var dataSourceAttributes = property.GetCustomAttributes(typeof(DataSourceAttribute), false);

            if (dataSourceAttributes.Length > 0)
            {
                var dataSourcAttribute = (DataSourceAttribute) dataSourceAttributes[0];
                var dataSourceFieldName = includeSourcePrefix ? $"[{dataSourcAttribute.Source}].[{dataSourcAttribute.FieldName}]" : $"[{dataSourcAttribute.FieldName}]";

                return dataSourceFieldName;
            }

            return string.Empty;
        }
    }
}
