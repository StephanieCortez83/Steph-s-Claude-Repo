using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Extensions
{
    public static class ObjectExtensions
    {
        public static List<string> CompareTo<T>(this T currentObject, T previousObject, bool formatToCamelCase = true)
        {
            var propertyChanges = new List<string>();

            // get the property list for each object
            var previousObjectProperties = previousObject.GetType().GetProperties();
            var currentObjectProperties = currentObject.GetType().GetProperties();

            // cycle through the current object's property list and find its match on the previous
            foreach (var currentProperty in currentObjectProperties)
            {
                var isDifferent = false;

                // get the current property value
                var currentPropertyRawValue = currentProperty.GetValue(currentObject, null);

                // find the corresponding property on the previous object
                var previousProperty = previousObjectProperties.FirstOrDefault(p => p.Name == currentProperty.Name);

                if (previousProperty != null)
                {
                    var previousPropertyRawValue = previousProperty.GetValue(previousObject, null);

                    // evaluate the property type and determine if it's really empty by checking against nulls
                    if (currentProperty.PropertyType == typeof(DateTime) || currentProperty.PropertyType == typeof(DateTime?))
                    {
                        var currentValue = (DateTime?) currentPropertyRawValue;
                        var previousValue = (DateTime?) previousPropertyRawValue;

                        if (previousValue != currentValue)
                            isDifferent = true;
                    }
                    else if (currentProperty.PropertyType == typeof(int) || currentProperty.PropertyType == typeof(int?))
                    {
                        var currentValue = (int?) currentPropertyRawValue;
                        var previousValue = (int?) previousPropertyRawValue;

                        if (previousValue != currentValue)
                            isDifferent = true;
                    }
                    else if (currentProperty.PropertyType == typeof(decimal) || currentProperty.PropertyType == typeof(decimal?))
                    {
                        var currentValue = (decimal?)currentPropertyRawValue;
                        var previousValue = (decimal?)previousPropertyRawValue;

                        if (previousValue != currentValue)
                            isDifferent = true;
                    }
                    else if (currentProperty.PropertyType == typeof(Enum))
                    {
                        var currentValue = (Enum)currentPropertyRawValue;
                        var previousValue = (Enum)previousPropertyRawValue;

                        if (!Equals(previousValue, currentValue))
                            isDifferent = true;
                    }
                    else
                    {
                        var currentValue = currentPropertyRawValue != null ? currentPropertyRawValue.ToString() : string.Empty;
                        var previousValue = previousPropertyRawValue != null ? previousPropertyRawValue.ToString() : string.Empty;

                        if (!currentValue.Equals(previousValue))
                            isDifferent = true;
                    }

                    if (isDifferent)
                        propertyChanges.Add(formatToCamelCase ? previousProperty.Name.ToCamelCase() : previousProperty.Name);
                }
            }

            return propertyChanges;
        }
    }
}
