using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Template
{
    public class Template
    {
        public List<TemplateSetting> Settings { get; set; }

        public List<TemplateVariable> Variables { get; set; }

        public List<TemplatePropertySet> PropertySets { get; set; }
    }

    public class TemplatePropertySet
    {
        public List<TemplateProperty> Properties { get; set; }
    }

    public class TemplateSetting
    {
        public string Name { get; set; }

        public string Value { get; set; }
    }

    public class TemplateVariable
    {
        public string Name { get; set; }

        public string Value { get; set; }
    }

    public class TemplateProperty
    {
        public string Type { get; set; }

        public string Value { get; set; }
    }
}
