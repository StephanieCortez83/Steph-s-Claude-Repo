using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using ACS.Core.Common.Regex;
using ACS.Core.Extensions;
using ACS.Core.Sql;
using Newtonsoft.Json;

namespace ACS.Core.Template
{
    /// <summary>
    /// The basis for all TemplateManagers that will deserialize T4 Templates into type Template.
    /// </summary>
    public class TemplateManager
    {
        #region internals

        protected Regex AlphaTextRegex = new Regex(Pattern.Extract.AlphaText);
        protected Regex DisplayNameRegex = new Regex(@"(?<=[A-Z])(?=[A-Z][a-z]) | (?<=[^A-Z])(?=[A-Z]) | (?<=[A-Za-z])(?=[^A-Za-z])", RegexOptions.IgnorePatternWhitespace);
        protected Regex VariableRegex = new Regex("%([A-Za-z0-9\\-]+)%");

        #endregion

        #region properties

        /// <summary>
        /// The source database to template off of.
        /// </summary>
        public string ConnectionString
        {
            get
            {
                if (!string.IsNullOrWhiteSpace(_connectionString))
                    return _connectionString;

                var connectionStringSetting = Template.Settings?.FirstOrDefault(s => s.Name.Equals("ConnectionString", StringComparison.InvariantCultureIgnoreCase));

                if (connectionStringSetting == null)
                    throw new Exception("ConnectionString is required");

                _connectionString = connectionStringSetting.Value;

                return _connectionString;
            }
        }

        /// <summary>
        /// The namespace to generate for classes.
        /// </summary>
        public string Namespace
        {
            get
            {
                if (!string.IsNullOrWhiteSpace(_namespace))
                    return _namespace;

                var namespaceSetting = Template.Settings?.FirstOrDefault(s => s.Name.Equals("Namespace", StringComparison.InvariantCultureIgnoreCase));

                if (namespaceSetting == null)
                    throw new Exception("Namespace is required");

                _namespace = namespaceSetting.Value;

                return _namespace;
            }
        }

        public string IgnorePrefix
        {
            get
            {
                if (!string.IsNullOrWhiteSpace(_ignorePrefix))
                    return _ignorePrefix;

                var ignorePrefixSetting = Template.Settings?.FirstOrDefault(s => s.Name.Equals("IgnorePrefix", StringComparison.InvariantCultureIgnoreCase));

                _ignorePrefix = ignorePrefixSetting?.Value ?? string.Empty;

                return _ignorePrefix;
            }
        }

        /// <summary>
        /// The directory where the template file is located.
        /// </summary>
        public string TemplateBaseFilePath { get; private set; }

        /// <summary>
        /// The Template file name.
        /// </summary>
        public string TemplateName { get; private set; }

        /// <summary>
        /// The deserialized template.
        /// </summary>
        public Template Template => _template ?? (_template = GetTemplate());

        private string _connectionString;
        private string _ignorePrefix;
        private string _namespace;
        private Template _template;

        #endregion

        #region constructor

        public TemplateManager(string templateBaseFilePath, string templateName)
        {
            TemplateBaseFilePath = templateBaseFilePath;
            TemplateName = templateName;
        }

        #endregion

        #region methods

        /// <summary>
        /// Read in the template file and deserialize it to a Template object.
        /// </summary>
        /// <returns>A TemplatePropertySet object.</returns>
        public Template GetTemplate()
        {
            try
            {
                var qualifiedPath = Path.Combine(TemplateBaseFilePath, TemplateName);
                var file = File.ReadAllText(qualifiedPath);

                var template = JsonConvert.DeserializeObject<Template>(file);

                // look for any variable usage in the Property values and do variable 
                // replacement
                foreach (var templatePropertySet in template.PropertySets)
                {
                    foreach (var templateProperty in templatePropertySet.Properties)
                        templateProperty.Value = ReplaceVariables(templateProperty.Value);
                }

                return template;
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
                throw;
            }
        }

        /// <summary>
        /// Iterate through the Variables collection, if any, and replace the template variables with those values.
        /// </summary>
        /// <param name="value">The value to search against the Variables collection.</param>
        /// <returns>The Variables value, if found incoming string, otherwise the original string is returned.</returns>
        public string ReplaceVariables(string value)
        {
            // look for variables with starting and ending with %
            var regexMatch = VariableRegex.Match(value);

            if (regexMatch.Success && Template?.Variables != null && this.Template.Variables.Any())
            {
                // if it starts and ends with %, it's a variable, so extract the core value and make sure it matches 
                // a variable name
                var matchingVariable = this.Template.Variables.FirstOrDefault(v => v.Name.Equals(regexMatch.Groups[1].Value, StringComparison.InvariantCultureIgnoreCase));

                if (matchingVariable != null)
                    return matchingVariable.Value;
            }

            return value;
        }

        /// <summary>
        /// Check to see if a SqlServerColumn should be validated for max length.
        /// </summary>
        /// <param name="column">The column to check.</param>
        /// <returns>True if a max length check is required..</returns>
        public bool ShouldValidateMaxLength(SqlServerColumn column)
        {
            switch (column.DataType)
            {
                case SqlServerDataTypeCode.Char:
                case SqlServerDataTypeCode.NChar:
                case SqlServerDataTypeCode.NVarChar:
                case SqlServerDataTypeCode.VarChar:
                    {
                        return column.MaxLength > 0;
                    }
                default:
                    {
                        return false;
                    }
            }
        }

        /// <summary>
        /// Check to see if a SqlServerColumn should be validated as required.
        /// </summary>
        /// <param name="column">The column to check.</param>
        /// <returns>True if required.</returns>
        public bool ShouldValidateRequired(SqlServerColumn column)
        {
            return !column.IsPrimaryKey && !column.IsNullable;
        }

        #endregion

        #region property set methods

        /// <summary>
        /// Gets a list of additional classes to inject through the constructor
        /// </summary>
        /// <returns>A list of classes to inject.</returns>
        public List<string> GetAdditionalInjectionInterfaces(string entityName)
        {
            var propertySet = GetSourceTableTemplatePropertySet(entityName);
            var additionalInjectionInterfaceList = new List<string>();

            var additionalInjectionInterfacesProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("AdditionalInjectionInterfaces", StringComparison.InvariantCultureIgnoreCase));

            if (additionalInjectionInterfacesProperty != null)
            {
                var additionalInjectionInterfaces = additionalInjectionInterfacesProperty.Value.Split(';');

                if (additionalInjectionInterfaces.Any())
                    additionalInjectionInterfaceList = additionalInjectionInterfaces.ToList();
            }

            return additionalInjectionInterfaceList;
        }

        /// <summary>
        /// Get a list of database tables from the Template property sets.
        /// </summary>
        /// <returns>A list of tables.</returns>
        public List<TemplateProperty> GetSourceTables()
        {
            var tableTemplatePropertyList = new List<TemplateProperty>();

            foreach (var propertySet in Template.PropertySets)
            {
                // find the the table property in each property set
                var tableTemplateProperty = propertySet.Properties.FirstOrDefault(p => p.Type.Equals("SourceTable", StringComparison.InvariantCultureIgnoreCase));

                if (tableTemplateProperty != null)
                    tableTemplatePropertyList.Add(tableTemplateProperty);
            }

            return tableTemplatePropertyList;
        }

        /// <summary>
        /// Gather the list of property sets corresponding to a given SourceTable property in the same TemplatePropertySet.
        /// </summary>
        /// <param name="tableName">The table name to search for.</param>
        /// <returns>A TemplatePropertySet if one is found for a table name.</returns>
        public TemplatePropertySet GetSourceTableTemplatePropertySet(string tableName)
        {
            foreach (var propertySet in Template.PropertySets)
            {
                var tableTemplateProperty = propertySet.Properties.FirstOrDefault(p => p.Type.Equals("SourceTable", StringComparison.InvariantCultureIgnoreCase) && p.Value.ToString().Equals(tableName, StringComparison.InvariantCultureIgnoreCase));

                if (tableTemplateProperty != null)
                    return propertySet;
            }

            return null;
        }

        /// <summary>
        /// Gather the list of property set values corresponding to a given entity property name.
        /// </summary>
        /// <param name="entityName">The entity name to search for.</param>
        /// <param name="propertyName">The property for which values will be returned.</param>
        /// <returns>A list of string values of the given property.</returns>
        public List<string> GetSpecifiedSourceTablePropertySetValues(string entityName, string propertyName)
        {
            var propertySet = GetSourceTableTemplatePropertySet(entityName);
            var propertyValues = new List<string>();

            var property = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals(propertyName, StringComparison.InvariantCultureIgnoreCase));

            if (property != null)
            {
                var values = property.Value.Split(',');

                if (values.Any())
                    propertyValues = values.ToList();
            }

            return propertyValues;
        }

        public List<TemplateProperty> GetSourceViews()
        {
            var viewTemplatePropertyList = new List<TemplateProperty>();

            foreach (var propertySet in Template.PropertySets)
            {
                // find the the view property in each property set
                var viewTemplateProperty = propertySet.Properties.FirstOrDefault(p => p.Type.Equals("SourceView", StringComparison.InvariantCultureIgnoreCase));

                if (viewTemplateProperty != null)
                    viewTemplatePropertyList.Add(viewTemplateProperty);
            }

            return viewTemplatePropertyList;
        }

        /// <summary>
        /// Gather the list of property sets corresponding to a given SourceView property in the same TemplatePropertySet.
        /// </summary>
        /// <param name="viewName">The view name to search for.</param>
        /// <returns>A TemplatePropertySet if one is found for a view name.</returns>
        public TemplatePropertySet GetSourceViewTemplatePropertySet(string viewName)
        {
            foreach (var propertySet in Template.PropertySets)
            {
                var viewTemplateProperty = propertySet.Properties.FirstOrDefault(p => p.Type.Equals("SourceView", StringComparison.InvariantCultureIgnoreCase) && p.Value.ToString().Equals(viewName, StringComparison.InvariantCultureIgnoreCase));

                if (viewTemplateProperty != null)
                    return propertySet;
            }

            return null;
        }

        /// <summary>
        /// Gets a list of columns that should be prevented from having write operations
        /// </summary>
        /// <param name="entityName">The entity to examine exclusions for.</param>
        /// <returns>A list of columns to ignore for inserts or updates.</returns>
        public List<string> GetWriteColumnExclusions(string entityName)
        {
            var propertySet = GetSourceTableTemplatePropertySet(entityName);
            var writeColumnExclusionList = new List<string>();

            var writeColumnExclusionListProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("WriteColumnExclusionList", StringComparison.InvariantCultureIgnoreCase));

            if (writeColumnExclusionListProperty != null)
            {
                var writeColumnExclusions = writeColumnExclusionListProperty.Value.Split(',');

                if (writeColumnExclusions.Any())
                    writeColumnExclusionList = writeColumnExclusions.ToList();
            }

            var ignoreDefaultWriteColumnExclusionListProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("IgnoreDefaultWriteColumnExclusionList", StringComparison.InvariantCultureIgnoreCase));
            var ignoreDefaultWriteColumnExclusionList = false;

            if (ignoreDefaultWriteColumnExclusionListProperty != null)
                bool.TryParse(ignoreDefaultWriteColumnExclusionListProperty.Value, out ignoreDefaultWriteColumnExclusionList);

            if (ignoreDefaultWriteColumnExclusionList) return writeColumnExclusionList;

            if (!writeColumnExclusionList.Contains("CREATION_DATE_TIME"))
                writeColumnExclusionList.Add("CREATION_DATE_TIME");

            if (!writeColumnExclusionList.Contains("CHANGED_DATE_TIME"))
                writeColumnExclusionList.Add("CHANGED_DATE_TIME");

            if (!writeColumnExclusionList.Contains("DateTimeCreated"))
                writeColumnExclusionList.Add("DateTimeCreated");

            if (!writeColumnExclusionList.Contains("DateTimeLastUpdated"))
                writeColumnExclusionList.Add("DateTimeLastUpdated");

            return writeColumnExclusionList;
        }

        public Hashtable GetTypeCodeOverrides(string entityName)
        {
            var propertySet = GetSourceTableTemplatePropertySet(entityName);
            var typeOverrideList = new Hashtable();

            var typeOverrideListProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("TypeCodeOverrideList", StringComparison.InvariantCultureIgnoreCase));

            if (typeOverrideListProperty != null)
            {
                var typeOverrides = typeOverrideListProperty.Value.Split(',');

                if (typeOverrides.Any())
                {
                    foreach (var typeOverride in typeOverrides)
                    {
                        var typeOverridePair = typeOverride.Split('=');

                        if (typeOverridePair.Any())
                        {
                            if (!typeOverrideList.ContainsKey(typeOverridePair[0]))
                                typeOverrideList.Add(typeOverridePair[0], typeOverridePair[1]);
                        }
                    }
                }
            }

            return typeOverrideList;
        }

        /// <summary>
        /// Used to determine if a column should be left out of any insert or update queries.
        /// </summary>
        /// <param name="entity">The entity to examine exclusions for.</param>
        /// <param name="column">The column to check against the exclusion list.</param>
        /// <returns>True if it should be excluded from write operations.</returns>
        public bool IsWriteColumnExclusion(SqlServerEntity entity, SqlServerColumn column)
        {
            var writeColumnExclusions = GetWriteColumnExclusions(entity.Name);
            return writeColumnExclusions.Any(w => w.Equals(column.Name, StringComparison.InvariantCultureIgnoreCase));
        }

        /// <summary>
        /// Determin if a column will be annotated with a Mask attribute and mask value.
        /// </summary>
        /// <param name="entity">The entity to examine masked columns for.</param>
        /// <param name="column">The column to check against the mask list.</param>
        /// <returns>True if column has been marked for masking.</returns>
        public bool IsMaskedColumn(SqlServerEntity entity, SqlServerColumn column)
        {
            var maskedColumns = GetSpecifiedSourceTablePropertySetValues(entity.Name, "MaskedColumns");
            return maskedColumns.Any(w => w.Equals(column.Name, StringComparison.InvariantCultureIgnoreCase));
        }

        /// <summary>
        /// Gets a property set property that indicates if an audit log action should be generated on Save.
        /// </summary>
        /// <param name="entityName">The entity to look for in the property set list.</param>
        /// <returns>True if an audit should be generated.</returns>
        public TemplateProperty GetGenerateAuditProperty(string entityName)
        {
            var propertySet = GetSourceTableTemplatePropertySet(entityName);

            var generateAuditProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("GenerateAudit", StringComparison.InvariantCultureIgnoreCase));

            return generateAuditProperty;
        }

        /// <summary>
        /// Gets a property set property that indicates if an unscoped get/select method should be generated.
        /// </summary>
        /// <param name="entityName">The entity to look for in the property set list.</param>
        /// <returns>True if an unscoped read should generated.</returns>
        public TemplateProperty GetGenerateUnscopedReadProperty(string entityName)
        {
            var propertySet = GetSourceTableTemplatePropertySet(entityName);

            var generateUnscopedReadProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("GenerateUnscopedRead", StringComparison.InvariantCultureIgnoreCase));

            return generateUnscopedReadProperty;
        }

        /// <summary>
        /// Gets a property set property that indicates if the creation user id set should be generated.
        /// </summary>
        /// <param name="entityName">The entity to look for in the property set list.</param>
        /// <returns>A TemplateProperty that indicates if the creating user id set should generated.</returns>
        public TemplateProperty GetGenerateUserIdCreatedProperty(string entityName)
        {
            var propertySet = GetSourceTableTemplatePropertySet(entityName);

            var generateUnscopedReadProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("GenerateUserIdCreated", StringComparison.InvariantCultureIgnoreCase));

            return generateUnscopedReadProperty;
        }

        /// <summary>
        /// Gets a property set property that indicates the column that should be set as creating user id.
        /// </summary>
        /// <param name="entityName">The entity to look for in the property set list.</param>
        /// <returns>A TemplateProperty that indicates which column should be set as creating user id.</returns>
        public TemplateProperty GetUserIdCreatedColumnProperty(string entityName)
        {
            var propertySet = GetSourceTableTemplatePropertySet(entityName);

            var userIdCreatedColumnProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("UserIdCreatedColumn", StringComparison.InvariantCultureIgnoreCase));

            return userIdCreatedColumnProperty;
        }

        /// <summary>
        /// Gets a property set property that indicates if the updating user id set should be generated.
        /// </summary>
        /// <param name="entityName">The entity to look for in the property set list.</param>
        /// <returns>A TemplateProperty that indicates if a the updating user id set should generated.</returns>
        public TemplateProperty GetGenerateUserIdUpdatedProperty(string entityName)
        {
            var propertySet = GetSourceTableTemplatePropertySet(entityName);

            var generateUnscopedReadProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("GenerateUserIdUpdated", StringComparison.InvariantCultureIgnoreCase));

            return generateUnscopedReadProperty;
        }

        /// <summary>
        /// Gets a property set property that indicates the column that should be set as creating user id.
        /// </summary>
        /// <param name="entityName">The entity to look for in the property set list.</param>
        /// <returns>A TemplateProperty that indicates which column should be set as creating user id.</returns>
        public TemplateProperty GetUserIdUpdatedColumnProperty(string entityName)
        {
            var propertySet = GetSourceTableTemplatePropertySet(entityName);

            var userIdUpdatedColumnProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("UserIdUpdatedColumn", StringComparison.InvariantCultureIgnoreCase));

            return userIdUpdatedColumnProperty;
        }

        /// <summary>
        /// Looks for a GenerateAudit property in an entity's property set and parses its value.
        /// </summary>
        /// <param name="entity">The entity to look a GenerateAudit property set for.</param>
        /// <returns>True if audit generation should occur.</returns>
        public bool GenerateAudit(SqlServerEntity entity)
        {
            var generateAuditProperty = GetGenerateAuditProperty(entity.Name);

            if (generateAuditProperty != null)
            {
                var success = bool.TryParse(generateAuditProperty.Value, out var generateAudit);

                if (success)
                    return generateAudit;
            }

            return false;
        }

        /// <summary>
        /// Used to determine if an insert should be generated.
        /// </summary>
        /// <param name="entity">The entity to look a GenerateCreate property set for.</param>
        /// <returns>True if a create should be generated.</returns>
        public bool GenerateWrite(SqlServerEntity entity)
        {
            var propertySet = GetSourceTableTemplatePropertySet(entity.Name);

            var generateInsertProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("GenerateWrite", StringComparison.InvariantCultureIgnoreCase));

            if (generateInsertProperty != null)
            {
                var success = bool.TryParse(generateInsertProperty.Value, out var generateInsert);

                if (success)
                    return generateInsert;
            }

            return true;
        }

        /// <summary>
        /// Used to determine if get/selects should be generated.
        /// </summary>
        /// <param name="entity">The entity to look a GenerateRead property set for.</param>
        /// <returns>True if read/select should be generated.</returns>
        public bool GenerateRead(SqlServerEntity entity)
        {
            var propertySet = GetSourceTableTemplatePropertySet(entity.Name);

            var generateSelectProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("GenerateRead", StringComparison.InvariantCultureIgnoreCase));

            if (generateSelectProperty != null)
            {
                var success = bool.TryParse(generateSelectProperty.Value, out var generateSelect);

                if (success)
                    return generateSelect;
            }

            return true;
        }

        /// <summary>
        /// Looks for a GenerateUnscopedRead property in an entity's property set and parses its value.
        /// </summary>
        /// <param name="entity">The entity to look a GenerateUnscopedRead property set for.</param>
        /// <returns>Defaults to false. True if audit generation should occur.</returns>
        public bool GenerateUnscopedRead(SqlServerEntity entity)
        {
            var generateUnscopedReadProperty = GetGenerateUnscopedReadProperty(entity.Name);

            if (generateUnscopedReadProperty != null)
            {
                var success = bool.TryParse(generateUnscopedReadProperty.Value, out var generateUnscopedRead);

                if (success)
                    return generateUnscopedRead;
            }

            return false;
        }

        /// <summary>
        /// Used to determine if a delete should be generated.
        /// </summary>
        /// <param name="entity">The entity to look a GenerateDelete property set for.</param>
        /// <returns>True if a delete should be generated.</returns>
        public bool GenerateDelete(SqlServerEntity entity)
        {
            var propertySet = GetSourceTableTemplatePropertySet(entity.Name);

            var generateDeleteProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("GenerateDelete", StringComparison.InvariantCultureIgnoreCase));

            if (generateDeleteProperty != null)
            {
                var success = bool.TryParse(generateDeleteProperty.Value, out var generateDelete);

                if (success)
                    return generateDelete;
            }

            return true;
        }

        /// <summary>
        /// Looks for a GenerateUserIdCreatedProperty property in an entity's property set and parses its value.
        /// </summary>
        /// <param name="entity">The entity to look a GenerateUserIdCreatedProperty property set for.</param>
        /// <returns>Defaults to true. False if no date/time created set generation should occur.</returns>
        public bool GenerateUserIdCreated(SqlServerEntity entity)
        {
            var generateUserIdCreatedProperty = GetGenerateUserIdCreatedProperty(entity.Name);

            if (generateUserIdCreatedProperty != null)
            {
                var success = bool.TryParse(generateUserIdCreatedProperty.Value, out var generateUserIdCreated);

                if (success)
                    return generateUserIdCreated;
            }

            return true;
        }

        /// <summary>
        /// Looks for a UserIdCreatedColumnProperty property in an entity's property set and parses its value.
        /// </summary>
        /// <param name="entity">The entity to look a UserIdCreatedColumnProperty property set for.</param>
        /// <returns>Defaults to ChangingUserProfileId, otherwise it will return what is in the TemplateProperty.</returns>ChangingUserProfileId
        public string GetUserIdCreatedColumn(SqlServerEntity entity)
        {
            var dateTimeCreatedColumnProperty = GetUserIdCreatedColumnProperty(entity.Name);

            if (dateTimeCreatedColumnProperty != null && !string.IsNullOrWhiteSpace(dateTimeCreatedColumnProperty.Value))
                return dateTimeCreatedColumnProperty.Value;

            return AssumePascalCase(entity.Name) ? "CreatedByUserProfileId" : "CREATING_USER_PROFILE_ID";
        }

        /// <summary>
        /// Looks for a GenerateUserIdUpdatedProperty property in an entity's property set and parses its value.
        /// </summary>
        /// <param name="entity">The entity to look a GenerateUserIdUpdatedProperty property set for.</param>
        /// <returns>Defaults to true. False if no date/time created set generation should occur.</returns>
        public bool GenerateUserIdUpdated(SqlServerEntity entity)
        {
            var generateUserIdUpdatedProperty = GetGenerateUserIdUpdatedProperty(entity.Name);

            if (generateUserIdUpdatedProperty != null)
            {
                var success = bool.TryParse(generateUserIdUpdatedProperty.Value, out var generateUserIdUpdated);

                if (success)
                    return generateUserIdUpdated;
            }

            return true;
        }

        /// <summary>
        /// Looks for a UserIdUpdatedColumnProperty property in an entity's property set and parses its value.
        /// </summary>
        /// <param name="entity">The entity to look a UserIdUpdatedColumnProperty property set for.</param>
        /// <returns>Defaults to ChangingUserProfileId, otherwise it will return what is in the TemplateProperty.</returns>ChangingUserProfileId
        public string GetUserIdUpdatedColumn(SqlServerEntity entity)
        {
            var dateTimeUpdatedColumnProperty = GetUserIdUpdatedColumnProperty(entity.Name);

            if (dateTimeUpdatedColumnProperty != null && !string.IsNullOrWhiteSpace(dateTimeUpdatedColumnProperty.Value))
                return dateTimeUpdatedColumnProperty.Value;

            return AssumePascalCase(entity.Name) ? "LastUpdatedByUserProfileId" : "CHANGING_USER_PROFILE_ID";
        }

        /// <summary>
        /// Used to determine if an IsValid property and a Validate method should be generated.
        /// </summary>
        /// <param name="entity">The entity to look a GenerateValidate property set for.</param>
        /// <returns>True if a validate should be generated.</returns>
        public bool GenerateValidate(SqlServerEntity entity)
        {
            var propertySet = GetSourceTableTemplatePropertySet(entity.Name);

            var generateValidateProperty = propertySet?.Properties.FirstOrDefault(p => p.Type.Equals("GenerateValidate", StringComparison.InvariantCultureIgnoreCase));

            if (generateValidateProperty != null)
            {
                var success = bool.TryParse(generateValidateProperty.Value, out var generateValidate);

                if (success)
                    return generateValidate;
            }

            return true;
        }

        #endregion property set methods

        #region generation formatting methods

        /// <summary>
        /// Convert database column names to standardized .Net names for fields/properties.
        /// </summary>
        /// <param name="value">The column name to convert.</param>
        /// <returns>A standardized, Pascal-cased field/property name.</returns>
        public string ToPropertyName(string value)
        {
            var splitName = value.Split('_');
            var newNameParts = new List<string>();

            foreach (var name in splitName)
            {
                var newName = ToPascalCase(name);
                newNameParts.Add(newName);
            }

            return string.Join(string.Empty, newNameParts);
        }

        /// <summary>
        /// Convert a value to Camel-case.
        /// </summary>
        /// <param name="value">The value to convert to Camel-case.</param>
        /// <returns>A Camel-cased value.</returns>
        public string ToCamelCase(string value)
        {
            var cleanValue = ScrubIllegalCharacters(value);

            return cleanValue.Trim().Substring(0, 1).ToLower() + cleanValue.Substring(1);
        }

        /// <summary>
        /// Convert a value to Pascal-case.
        /// </summary>
        /// <param name="value">The value to convert to Pascal-case.</param>
        /// <returns>A Pascal-cased value.</returns>
        public string ToPascalCase(string value)
        {
            var cleanValue = ScrubIllegalCharacters(value);

            return cleanValue.Trim().Substring(0, 1).ToUpper() + cleanValue.Trim().Substring(1, cleanValue.Length - 1).ToLower();
        }

        public string ToDisplayName(string value)
        {
            return DisplayNameRegex.Replace(value, " ");
        }

        /// <summary>
        /// Remove characters that are illegal for .Net property/field names.
        /// </summary>
        /// <param name="value">The field/property name to scrub.</param>
        /// <returns>A cleaned up field/property name.</returns>
        public string ScrubIllegalCharacters(string value)
        {
            return value.Replace(" ", string.Empty)
                .Replace("?", string.Empty)
                .Replace("-", string.Empty)
                .Replace("\\", string.Empty)
                .Replace("/", string.Empty)
                .Replace(",", string.Empty)
                .Replace("[", string.Empty)
                .Replace("]", string.Empty)
                .Replace("#", "Number")
                .Replace("%", "Percent")
                .Replace("$", "Dollars");
        }

        /// <summary>
        /// Translate SQL Server data types to .Net data types.
        /// </summary>
        /// <param name="column">The the column to translate.</param>
        /// <returns>The .Net data type that corresponds to the SQL Server data type.</returns>
        public string ToDotNetDataType(SqlServerColumn column)
        {
            var columnName = column.Name;
            var typeCodeOverrides = GetTypeCodeOverrides(column.SqlServerEntityName);

            if (typeCodeOverrides.ContainsKey(column.Name))
                columnName = typeCodeOverrides[column.Name].ToString();

            if (columnName.EndsWith("TYPE_CODE") || columnName.EndsWith("TypeCode")) return columnName.ToPascalCase();

            switch (column.DataType)
            {
                case SqlServerDataTypeCode.BigInt:
                    {
                        return DotNetDataTypeCode.Int64.GetDisplayShortName();
                    }
                case SqlServerDataTypeCode.Binary:
                case SqlServerDataTypeCode.Image:
                case SqlServerDataTypeCode.VarBinary:
                    {
                        return DotNetDataTypeCode.ByteArray.GetDisplayShortName();
                    }
                case SqlServerDataTypeCode.Bit:
                    {
                        return DotNetDataTypeCode.Boolean.GetDisplayShortName();
                    }
                case SqlServerDataTypeCode.Char:
                    {
                        return DotNetDataTypeCode.Char.GetDisplayShortName();
                    }
                case SqlServerDataTypeCode.DateTime:
                case SqlServerDataTypeCode.DateTime2:
                case SqlServerDataTypeCode.SmallDateTime:
                    {
                        return DotNetDataTypeCode.DateTime.GetDisplayShortName();
                    }
                case SqlServerDataTypeCode.Decimal:
                case SqlServerDataTypeCode.Money:
                case SqlServerDataTypeCode.Numeric:
                    {
                        return DotNetDataTypeCode.Decimal.GetDisplayShortName();
                    }
                case SqlServerDataTypeCode.Float:
                    {
                        return DotNetDataTypeCode.Double.GetDisplayShortName();
                    }
                case SqlServerDataTypeCode.Int:
                    {
                        return DotNetDataTypeCode.Int.GetDisplayShortName();
                    }
                case SqlServerDataTypeCode.NChar:
                case SqlServerDataTypeCode.NVarChar:
                case SqlServerDataTypeCode.Text:
                case SqlServerDataTypeCode.VarChar:
                case SqlServerDataTypeCode.Xml:
                    {
                        return DotNetDataTypeCode.String.GetDisplayShortName();
                    }
                case SqlServerDataTypeCode.Real:
                    {
                        return DotNetDataTypeCode.Single.GetDisplayShortName();
                    }
                case SqlServerDataTypeCode.SmallInt:
                    {
                        return DotNetDataTypeCode.Int16.GetDisplayShortName();
                    }
                case SqlServerDataTypeCode.TinyInt:
                    {
                        return DotNetDataTypeCode.Byte.GetDisplayShortName();
                    }
                case SqlServerDataTypeCode.UniqueIdentifier:
                    {
                        return DotNetDataTypeCode.Guid.GetDisplayShortName();
                    }
                default:
                    return null;
            }
        }

        /// <summary>
        /// Translate a .Net data type to a SqlDBType
        /// </summary>
        /// <param name="dotNetDataTypeName">The .Net data type to search for.</param>
        /// <returns>The SqlDBType.</returns>
        public string ToSqlDBType(string dotNetDataTypeName)
        {
            if (dotNetDataTypeName.EndsWith("TYPE_CODE") || dotNetDataTypeName.EndsWith("TypeCode"))
                dotNetDataTypeName = "byte";

            var success = EnumExtensions.TryParseByShortName(dotNetDataTypeName, out DotNetDataTypeCode dotNetDataType);

            if (success)
            {
                switch (dotNetDataType)
                {
                    case DotNetDataTypeCode.Boolean:
                        {
                            return "SqlDbType.Bit";
                        }
                    case DotNetDataTypeCode.Byte:
                        {
                            return "SqlDbType.TinyInt";
                        }
                    case DotNetDataTypeCode.DateTime:
                        {
                            return "SqlDbType.DateTime";
                        }
                    case DotNetDataTypeCode.Decimal:
                        {
                            return "SqlDbType.Decimal";
                        }
                    case DotNetDataTypeCode.Double:
                        {
                            return "SqlDbType.Float";
                        }
                    case DotNetDataTypeCode.Guid:
                        {
                            return "SqlDbType.UniqueIdentifier";
                        }
                    case DotNetDataTypeCode.Int:
                        {
                            return "SqlDbType.Int";
                        }
                    case DotNetDataTypeCode.Int16:
                        {
                            return "SqlDbType.SmallInt";
                        }
                    case DotNetDataTypeCode.Int64:
                        {
                            return "SqlDbType.BigInt";
                        }
                    case DotNetDataTypeCode.String:
                        {
                            return "SqlDbType.VarChar";
                        }
                    default:
                        return string.Empty;
                }
            }

            return string.Empty;
        }

        /// <summary>
        /// Get the default value for types when an entity is initialized.
        /// </summary>
        /// <param name="dotNetDataTypeName">The .Net data type to search for.</param>
        /// <returns>The default value.</returns>
        public string GetDefaultDataValue(string dotNetDataTypeName)
        {
            if (dotNetDataTypeName.EndsWith("?"))
                return "null";

            if (dotNetDataTypeName.EndsWith("TypeCode"))
                return "0";

            var success = EnumExtensions.TryParseByShortName(dotNetDataTypeName, out DotNetDataTypeCode dotNetDataType);

            if (success)
            {
                switch (dotNetDataType)
                {
                    case DotNetDataTypeCode.Boolean:
                        {
                            return "false";
                        }
                    case DotNetDataTypeCode.Byte:
                        {
                            return "byte.MinValue";
                        }
                    case DotNetDataTypeCode.DateTime:
                        {
                            return "DateTime.MinValue";
                        }
                    case DotNetDataTypeCode.Decimal:
                        {
                            return "decimal.MinValue";
                        }
                    case DotNetDataTypeCode.Double:
                        {
                            return "double.MinValue";
                        }
                    case DotNetDataTypeCode.Guid:
                        {
                            return "Guid.Empty";
                        }
                    case DotNetDataTypeCode.Int:
                        {
                            return "int.MinValue";
                        }
                    case DotNetDataTypeCode.Int16:
                        {
                            return "Int16.MinValue";
                        }
                    case DotNetDataTypeCode.Int64:
                        {
                            return "Int64.MinValue";
                        }
                    case DotNetDataTypeCode.String:
                        {
                            return "string.Empty";
                        }
                    default:
                        return string.Empty;
                }
            }

            return string.Empty;
        }

        /// <summary>
        /// Get the SqlReader method used to extract data from a reader.
        /// </summary>
        /// <param name="column">The SqlServerColumn to translate into a Sql read method.</param>
        /// <returns>The SqlReader method.</returns>
        public string GetSqlReaderMethod(SqlServerColumn column)
        {
            var statement = string.Empty;

            if (column.Name.EndsWith("TYPE_CODE") || column.Name.EndsWith("TypeCode"))
            {
                var columnName = column.Name.ToPascalCase();
                var typeName = columnName;

                var typeCodeOverrides = GetTypeCodeOverrides(column.SqlServerEntityName);

                if (typeCodeOverrides.ContainsKey(column.Name))
                    typeName = typeCodeOverrides[column.Name].ToString().ToPascalCase();

                statement += column.IsNullable ? $"({typeName}?)" : $"({columnName})";
            }

            var dotNetDataTypeName = ToDotNetDataType(column);
            statement += "reader.";

            var success = EnumExtensions.TryParseByShortName(dotNetDataTypeName, out DotNetDataTypeCode dotNetDataType);

            if (dotNetDataTypeName.EndsWith("TypeCode"))
                dotNetDataType = column.DataType == SqlServerDataTypeCode.TinyInt ? DotNetDataTypeCode.Byte : DotNetDataTypeCode.Int;

            switch (dotNetDataType)
            {
                case DotNetDataTypeCode.Boolean:
                    {
                        statement += "GetBoolean";
                        break;
                    }
                case DotNetDataTypeCode.Byte:
                    {
                        statement += "GetByte";
                        break;
                    }
                case DotNetDataTypeCode.DateTime:
                    {
                        statement += "GetDateTime";
                        break;
                    }
                case DotNetDataTypeCode.Decimal:
                    {
                        statement += "GetDecimal";
                        break;
                    }
                case DotNetDataTypeCode.Double:
                    {
                        statement += "GetDouble";
                        break;
                    }
                case DotNetDataTypeCode.Guid:
                    {
                        statement += "GetGuid";
                        break;
                    }
                case DotNetDataTypeCode.Int:
                    {
                        statement += "GetInt32";
                        break;
                    }
                case DotNetDataTypeCode.Int16:
                    {
                        statement += "GetShort";
                        break;
                    }
                case DotNetDataTypeCode.Int64:
                    {
                        statement += "GetInt64";
                        break;
                    }
                case DotNetDataTypeCode.String:
                    {
                        statement += "GetString";
                        break;
                    }
                default:
                    {
                        statement += string.Empty;
                        break;
                    }
            }

            return statement;
        }

        /// <summary>
        /// Get a two-dimensional list of SQLServerColumns that are members of foreign keys
        /// and non-unique indexes that might be used in SQL queries.
        /// </summary>
        /// <param name="table">The table to generate the list of non-unique column sets.</param>
        /// <returns>A two-dimensional list of SqlServerColumns where the outermost dimension is the column
        /// set belonging to a foreign key or non unique index and the innermost dimension is composed
        /// of the member columns of that set.</returns>
        public List<List<SqlServerColumn>> GetNonUniqueReferenceColumnSetList(SqlServerTable table)
        {
            var columnSetList = new List<List<SqlServerColumn>>();
            var uniquePredicateList = new List<string>();

            // go thru the list of indexes and build a list of non-unique indexes and member columns
            foreach (var index in table.Indexes)
            {
                var columnSet = new Dictionary<string, List<SqlServerColumn>>();

                if (!columnSet.ContainsKey(index.IndexName))
                    columnSet.Add(index.IndexName, index.MemberColumns);

                // if it's non-unique, go ahead and add the reference
                if (columnSet.Any() && !index.IsUnique)
                {
                    columnSetList.AddRange(columnSet.Select(c => c.Value));
                }
                else
                {
                    // build a list of unique indexes so that a FK reference isn't included
                    var predicate = GetDelimitedColumnNames(columnSet.SelectMany(c => c.Value).ToList(), "_AND_");
                    uniquePredicateList.Add(predicate);
                }
            }

            // go thru the list of foreign keys and add any that aren't referenced as unique indexes
            foreach (var foreignKey in table.ForeignKeys)
            {
                var canAddColumn = true;

                var columnSet = new List<SqlServerColumn>();

                // build a list of foreign key member columns
                foreach (var relationship in foreignKey.Relationships)
                    columnSet.Add(relationship.ForeignKeyColumn);

                // build a where predicate for comparison
                var predicate = GetDelimitedColumnNames(columnSet, "_AND_");

                // try to see if the foreign key has already been added as an index
                foreach (var columnSetColumnList in columnSetList)
                {
                    // make sure the FK hasn't been added to the list already by comparing it to everything that's been added so far
                    var existingPredicate = GetDelimitedColumnNames(columnSetColumnList, "_AND_");

                    if (predicate.Equals(existingPredicate, StringComparison.InvariantCultureIgnoreCase))
                    {
                        canAddColumn = false;
                        break;
                    }
                }

                // make sure the FK isn't already referenced as a unique index
                if (uniquePredicateList.Any(u => u.Equals(predicate, StringComparison.InvariantCultureIgnoreCase)))
                    canAddColumn = false;

                if (canAddColumn && columnSet.Any())
                    columnSetList.Add(columnSet);
            }

            return columnSetList;
        }

        /// <summary>
        /// Get a two-dimensional list of SQLServerColumns that are members of unique indexes that might be used in SQL queries.
        /// </summary>
        /// <param name="table">The table to generate the list of unique column sets.</param>
        /// <returns>A two-dimensional list of SqlServerColumns where the outermost dimension is the column
        /// set belonging to a unique index and the innermost dimension is composed
        /// of the member columns of that set.</returns>
        public List<List<SqlServerColumn>> GetUniqueReferenceColumnSetList(SqlServerTable table)
        {
            var columnSetList = new List<List<SqlServerColumn>>();

            // go thru the list of indexes and build a list of non-unique indexes and member columns
            foreach (var index in table.Indexes.Where(i => i.IsUnique))
            {
                var columnSet = new Dictionary<string, List<SqlServerColumn>>();

                if (!columnSet.ContainsKey(index.IndexName))
                    columnSet.Add(index.IndexName, index.MemberColumns);

                if (columnSet.Any())
                    columnSetList.AddRange(columnSet.Select(c => c.Value));
            }

            return columnSetList;
        }

        /// <summary>
        /// Transform a list of SqlServerColumn into a delimited string. Often used to generate
        /// part of a sproc or method name by multiple columns.
        /// </summary>
        /// <param name="columns">A list of columns to delimit.</param>
        /// <param name="delimiter">The delimiter to join the columns by.</param>
        /// <param name="formatFieldName">If set to true, this will format the column names in a proper .Net style.</param>
        /// <returns>A string of delimited SqlServerColumnNames.</returns>
        public string GetDelimitedColumnNames(List<SqlServerColumn> columns, string delimiter, bool formatFieldName = false, bool formatIdColumn = false)
        {
            var result = string.Empty;

            for (var i = 0; i < columns.Count; i++)
            {
                result += formatFieldName ? (columns[i].IsPrimaryKey && formatIdColumn ? "Id" : columns[i].FormattedName) : columns[i].Name;

                if (i < columns.Count - 1)
                    result += delimiter;
            }

            return result;
        }

        public string GetColumnArguments(List<SqlServerColumn> columns, bool includeType)
        {
            var argumentList = new List<string>();

            foreach (var column in columns)
            {
                var result = string.Empty;

                if (includeType)
                    result += ToDotNetDataType(column) + " ";

                result += column.Name.ToPascalCase().ToCamelCase();

                argumentList.Add(result);
            }

            return string.Join(", ", argumentList);
        }

        public string GetColumnArguments(List<SqlServerColumn> columns, bool includeType, bool formatIdColumn = false)
        {
            var argumentList = GetColumnArgumentsList(columns, includeType, formatIdColumn);

            return string.Join(", ", argumentList);
        }

        public List<string> GetColumnArgumentsList(List<SqlServerColumn> columns, bool includeType, bool formatIdColumn = false)
        {
            var argumentList = new List<string>();

            foreach (var column in columns)
            {
                var result = string.Empty;

                if (includeType)
                    result += ToDotNetDataType(column) + " ";

                result += column.IsPrimaryKey && formatIdColumn ? "id" : column.FormattedName.ToCamelCase();

                argumentList.Add(result);
            }

            return argumentList;
        }

        public List<string> GetColumnArgumentTypeList(List<SqlServerColumn> columns)
        {
            return columns.Select(ToDotNetDataType).ToList();
        }

        #endregion

        #region utility methods

        public bool AssumePascalCase(string value)
        {
            var alphaText = AlphaTextRegex.Match(value).Value;
            return !alphaText.Replace("_", string.Empty).All(char.IsUpper);
        }

        #endregion utility methods
    }
}
