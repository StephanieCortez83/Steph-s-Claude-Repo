using System;

namespace ACS.Core.Attribute
{
    [AttributeUsage(AttributeTargets.All, AllowMultiple = false)]
    public class AuditLogIgnoreAttribute : System.Attribute
    {
    }
}
