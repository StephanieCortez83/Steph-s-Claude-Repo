using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ACS.Core.Validation
{
    public enum ValidationCategoryTypeCode
    {
        [Display(Name = "Bad Argument", ShortName = "100", Description = "One more errors occurred with your request.")]
        BadArgument = 100,

        [Display(Name = "Business Rule", ShortName = "200", Description = "")]
        BusinessRule = 200,

        [Display(Name = "Bad Filter Query", ShortName = "300", Description = "Invalid filter query")]
        BadFilter = 300,

        [Display(Name = "Bad Sort Query", ShortName = "400", Description = "Invalid sort")]
        BadSort = 400,

        [Display(Name = "Null Value", ShortName = "500", Description = "Null value found")]
        NullValue = 500
    }

    public enum ValidationDetailTypeCode
    {
        [Display(Name = "Required", ShortName = "100.1", Description = "{0} is required.")]
        Required = 1001,
        [Display(Name = "Unique", ShortName = "100.2", Description = "{0} must be unique.")]
        Unique = 1002,
        [Display(Name = "Minimum Length", ShortName = "100.3", Description = "{0} must have at least {1} characters or digits.")]
        MinLength = 1003,
        [Display(Name = "Maximum Length", ShortName = "100.4", Description = "{0} cannot be longer than {1} characters or digits.")]
        MaxLength = 1004,
        [Display(Name = "Invalid Value", ShortName = "100.5", Description = "Invalid {0}")]
        InvalidValue = 1005,

        [Display(Name = "Date Out of Range", ShortName = "200.1", Description = "Invalid {0}")]
        DateOutOfRange = 2001, 
        [Display(Name = "Future Date", ShortName = "200.2", Description = "{0} cannot occur in the future.")]
        FutureDate = 2002,
        [Display(Name = "Past Date", ShortName = "200.3", Description = "{0} cannot occur in the past.")]
        PastDate = 2003,
        [Display(Name = "Domain Mismatch", ShortName = "200.4", Description = "")]
        DomainMismatch = 2004,
        [Display(Name = "User Acknowledgement Required", ShortName = "200.5", Description = "")]
        UserAcknowledgementRequired = 2005,
        [Display(Name = "Missing Required Data", ShortName = "200.6", Description = "")]
        MissingRequiredData = 2006,
        [Display(Name = "Invalid Status", ShortName = "200.7", Description = "")]
        InvalidStatus = 2007,
        [Display(Name = "Target Data Found", ShortName = "200.8", Description = "")]
        TargetDataFound = 2008,
        [Display(Name = "Conflict", ShortName = "200.9", Description = "")]
        Conflict = 2009,

        [Display(Name = "Invalid Filter Query Format", ShortName = "300.1", Description = "Invalid filter query {0}. Queries should be a comma-delimited list formatted as fieldName:[operator]operand.")]
        InvalidFilterFormat = 3001,

        [Display(Name = "Invalid Sort Format", ShortName = "400.1", Description = "Invalid sort {0}. Queries should be a comma-delimited list formatted as +fieldName (ascending) or -fieldName (descending)")]
        InvalidSortFormat = 4001,

        [Display(Name = "Resource not fond", ShortName = "400.4", Description = "{0} is not found.")]
        NotFound = 4004,

        [Display(Name = "Null Value Found", ShortName = "500.1", Description = "{0} cannot be null.")]
        NullValueRequired = 5001,

        [Display(Name = "Duplicate Value Found", ShortName = "600.1", Description = "{0} is a duplicate.")]
        Duplicate = 6001,
        [Display(Name = "Limit Exceeded", ShortName = "600.2", Description = "The limit for {0} has been exceeded.")]
        LimitExceeded = 6002
    }
}
