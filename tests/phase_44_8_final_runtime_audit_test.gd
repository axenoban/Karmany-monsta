extends Node


func _ready() -> void:
	print("")
	print("========================================")
	print("KARMANY MONSTA - FASE 44.8 AUDITORIA FINAL")
	print("========================================")

	var report := KarmanyPhase44FinalRuntimeAudit.build_report()
	var families_value: Variant = report.get("families", {})
	if families_value is Dictionary:
		var families: Dictionary = families_value
		for family_value in KarmanyPhase44FinalRuntimeAudit.FAMILY_ORDER:
			var family_id := String(family_value)
			var row_value: Variant = families.get(family_id, {})
			if row_value is Dictionary:
				print(
					KarmanyPhase44FinalRuntimeAudit.format_family_line(
						family_id,
						row_value
					)
				)

	var global_value: Variant = report.get("global", {})
	if global_value is Dictionary:
		print(KarmanyPhase44FinalRuntimeAudit.format_global_line(global_value))

	var errors := KarmanyPhase44FinalRuntimeAudit.validate_report(report)
	print("")
	print("========================================")
	if errors.is_empty():
		print("FASE 44.8 OK - 205/205 componentes reconciliados; FULLY=14 PARTIAL=155 DATA_ONLY=36 PENDING=0.")
	else:
		for error_message in errors:
			push_error("FASE 44.8 TEST ERROR: %s" % error_message)
		push_error("FASE 44.8 ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("========================================")
