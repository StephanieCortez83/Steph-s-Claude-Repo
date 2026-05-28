using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Sql
{
    public enum SqlServerEntityTypeCode
    {
        Table = 1,
        View = 2,
        StoredProcedure = 3,
        TypeCode = 4
    }

    public enum SqlServerExtendedPropertyTypeCode
    {
        Table = 1,
        View = 2,
        StoredProcedure = 3,
        Column = 4
    }

    public enum SqlServerSysIndexTypeCode
    {
        Heap = 0,
        Clustered = 1,
        NonClustered = 2,
        Xml = 3,
        Spatial = 4,
        ClusteredColumnStore = 5,
        NonClusteredColumnStore = 6,
        NonClusteredHash = 7
    }

    /// <summary>
    /// Corresponds to sys.types.user_type_id; system_type_id will repeat.
    /// </summary>
    public enum SqlServerDataTypeCode
    {
        [Display(ShortName = "image")]
        Image = 34,
        [Display(ShortName = "text")]
        Text = 35,
        [Display(ShortName = "uniqueidentifier")]
        UniqueIdentifier = 36,
        [Display(ShortName = "date")]
        Date = 40,
        [Display(ShortName = "time")]
        Time = 41,
        [Display(ShortName = "datetime2")]
        DateTime2 = 42,
        [Display(ShortName = "datetimeoffset")]
        DateTimeOffset = 43,
        [Display(ShortName = "tinyint")]
        TinyInt = 48,
        [Display(ShortName = "smallint")]
        SmallInt = 52,
        [Display(ShortName = "int")]
        Int = 56,
        [Display(ShortName = "smalldatetime")]
        SmallDateTime = 58,
        [Display(ShortName = "real")]
        Real = 59,
        [Display(ShortName = "money")]
        Money = 60,
        [Display(ShortName = "datetime")]
        DateTime = 61,
        [Display(ShortName = "float")]
        Float = 62,
        [Display(ShortName = "sql_variant")]
        SqlVariant = 98,
        [Display(ShortName = "ntext")]
        NText = 99,
        [Display(ShortName = "bit")]
        Bit = 104,
        [Display(ShortName = "decimal")]
        Decimal = 106,
        [Display(ShortName = "numeric")]
        Numeric = 108,
        [Display(ShortName = "smallmoney")]
        SmallMoney = 122,
        [Display(ShortName = "bigint")]
        BigInt = 127,
        [Display(ShortName = "hierarchyid")]
        HierarchyId = 128,
        [Display(ShortName = "geometry")]
        Geometry = 129,
        [Display(ShortName = "geography")]
        Geography = 130,
        [Display(ShortName = "varbinary")]
        VarBinary = 165,
        [Display(ShortName = "varchar")]
        VarChar = 167,
        [Display(ShortName = "binary")]
        Binary = 173,
        [Display(ShortName = "char")]
        Char = 175,
        [Display(ShortName = "timestamp")]
        Timestamp = 189,
        [Display(ShortName = "nvarchar")]
        NVarChar = 231,
        [Display(ShortName = "nchar")]
        NChar = 239,
        [Display(ShortName = "xml")]
        Xml = 241,
        [Display(ShortName = "bigint")]
        SysName = 256,
        [Display(ShortName = "udt_int")]
        UdtInt = 257,
        [Display(ShortName = "udt_varchar")]
        UdtVarChar = 258
    }
}
