using System;

namespace ACS.Core.Attribute
{
    [AttributeUsage(AttributeTargets.Field | AttributeTargets.Property, AllowMultiple = false)]
    public class AuditLogProtectAttribute : System.Attribute
    {
        /// <summary>
        /// When this is set, this will provide the value used in
        /// the audit the audit log, rather than thea actual value.
        /// If not set it will set it to string.Empty.
        /// </summary>
        public string DefaultValue { get; private set; }

        public AuditLogProtectAttribute(string defaultValue = "")
        {
            DefaultValue = defaultValue;
        }
    }
}
