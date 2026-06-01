  Use [RevCycleDB]
	GO

  Update [ChartAuditSectionTypeCode]
	Set [ExternalCode] = 'AC'
	Where [Key] = 'Anesthesia';
  Update [ChartAuditSectionTypeCode]
	Set [ExternalCode] = 'CI'
	Where [Key] = 'InfusionInjectionProcedure';
  Update [ChartAuditSectionTypeCode]
	Set [ExternalCode] = 'OB'
	Where [Key] = 'ObservationProcedure';