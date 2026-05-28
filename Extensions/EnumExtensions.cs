using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Extensions
{
    public static class EnumExtensions
    {
        /// <summary>
        /// Gets a description property from an enum field's System.ComponentModel.DataAnnotations.Display attribute.
        /// </summary>
        /// <param name="value">The enum field.</param>
        /// <returns>The display name property for this enum value; if it doesn't exist it will return the enum name.</returns>
        public static string GetDisplayDescription(this Enum value)
        {
            var fieldInfoList = value.GetType().GetFields();

            foreach (var fieldInfo in fieldInfoList)
            {
                if (fieldInfo.Name == value.ToString())
                {
                    var attrs = fieldInfo.GetCustomAttributes(typeof(DisplayAttribute), false);

                    if (attrs.Length > 0)
                    {
                        return ((DisplayAttribute)attrs[0]).Description;
                    }
                }
            }

            return value.ToString();
        }

        /// <summary>
        /// Gets a name from an enum field's System.ComponentModel.DataAnnotations.Display attribute.
        /// </summary>
        /// <param name="value">The enum field.</param>
        /// <returns>The display name property for this enum value; if it doesn't exist it will return the enum name.</returns>
        public static string GetDisplayName(this Enum value)
        {
            if (value != null)
            {
                var fieldInfoList = value.GetType().GetFields();

                foreach (var fieldInfo in fieldInfoList)
                {
                    if (fieldInfo.Name == value.ToString())
                    {
                        var attrs = fieldInfo.GetCustomAttributes(typeof(DisplayAttribute), false);

                        if (attrs.Length > 0)
                        {
                            return ((DisplayAttribute) attrs[0]).Name;
                        }
                    }
                }

                return value.ToString();
            }

            return string.Empty;
        }

        /// <summary>
        /// Gets a short name from an enum field's System.ComponentModel.DataAnnotations.Display attribute.
        /// </summary>
        /// <param name="value">The enum field.</param>
        /// <returns>The short name property for this enum value; if it doesn't exist it will return the enum name.</returns>
        public static string GetDisplayShortName(this Enum value)
        {
            var fieldInfoList = value.GetType().GetFields();

            foreach (var fieldInfo in fieldInfoList)
            {
                if (fieldInfo.Name == value.ToString())
                {
                    var attrs = fieldInfo.GetCustomAttributes(typeof(DisplayAttribute), false);

                    if (attrs.Length > 0)
                    {
                        return ((DisplayAttribute)attrs[0]).GetShortName();
                    }
                }
            }

            return value.ToString();
        }

        /// <summary>
        /// Takes an enum value and compares it against one or more possible matching enum values.
        /// </summary>
        /// <param name="selected">The value being compared.</param>
        /// <param name="list">The list of matching enum values.</param>
        /// <returns>True if the value is contained in the possible values.</returns>
        public static bool In(this Enum selected, params Enum[] list)
        {
            return list.Contains(selected);
        }

        /// <summary>
        /// Try to parse an Enum by its ShortName Display attribute value.
        /// </summary>
        /// <typeparam name="T">An Enum to try to parse to.</typeparam>
        /// <param name="shortName">The short name to look for in an enum.</param>
        /// <param name="enumValue">The corresponding enum value, if successful.</param>
        /// <returns>True if the parse was successful, false if not.</returns>
        public static bool TryParseByShortName<T>(string shortName, out T enumValue) where T : struct
        {
            enumValue = (T)(object)0;
            var type = typeof(T);
            var success = false;

            try
            {
                foreach (Enum enumField in Enum.GetValues(typeof(T)))
                {
                    var name = Enum.GetName(typeof(T), Convert.ToInt32(enumField));

                    //check by enum name first and if it matches, return
                    if (name.Equals(shortName, StringComparison.InvariantCultureIgnoreCase))
                    {
                        enumValue = (T)(object)enumField;
                        success = true;
                        break;
                    }

                    var field = (type).GetField(name);
                    if (field != null)
                    {
                        if (System.Attribute.GetCustomAttribute(field, typeof(DisplayAttribute)) is DisplayAttribute attr)
                        {
                            if (attr.ShortName.Equals(shortName, StringComparison.InvariantCultureIgnoreCase))
                            {
                                enumValue = (T)(object)enumField;
                                success = true;
                                break;
                            }
                        }
                    }
                }
            }
            catch
            {
                success = false;
            }

            return success;
        }
    }
}
