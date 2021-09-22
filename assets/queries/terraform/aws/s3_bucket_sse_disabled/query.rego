package Cx

import data.generic.common as common_lib

CxPolicy[result] {
	resource := input.document[i].resource.aws_s3_bucket[name]
	ssec := resource.server_side_encryption_configuration
	algorithm := ssec.rule.apply_server_side_encryption_by_default

	check_master_key(algorithm)
	not algorithm.sse_algorithm == "AES256"

	result := {
		"documentId": input.document[i].id,
		"searchKey": sprintf("aws_s3_bucket[%s].server_side_encryption_configuration.rule.apply_server_side_encryption_by_default.sse_algorithm", [name]),
		"issueType": "IncorrectValue",
		"keyExpectedValue": "server_side_encryption_configuration.rule.apply_server_side_encryption_by_default.sse_algorithm is AES256 when key is null",
		"keyActualValue": sprintf("server_side_encryption_configuration.rule.apply_server_side_encryption_by_default.sse_algorithm is %s when key is null", [algorithm.sse_algorithm]),
		"searchLine": common_lib.build_search_line(["resource", "aws_s3_bucket", name, "server_side_encryption_configuration", "rule", "apply_server_side_encryption_by_default", "sse_algorithm"], []),
	}
}

CxPolicy[result] {
	module := input.document[i].module[name]
	keyToCheck := common_lib.get_module_equivalent_key("aws", module.source, "aws_s3_bucket", "server_side_encryption_configuration")

	ssec := module[keyToCheck]
	algorithm := ssec.rule.apply_server_side_encryption_by_default

	check_master_key(algorithm)
	not algorithm.sse_algorithm == "AES256"

	result := {
		"documentId": input.document[i].id,
		"searchKey": sprintf("module[%s].server_side_encryption_configuration.rule.apply_server_side_encryption_by_default.sse_algorithm", [name]),
		"issueType": "IncorrectValue",
		"keyExpectedValue": "server_side_encryption_configuration.rule.apply_server_side_encryption_by_default.sse_algorithm is AES256 when key is null",
		"keyActualValue": sprintf("server_side_encryption_configuration.rule.apply_server_side_encryption_by_default.sse_algorithm is %s when key is null", [algorithm.sse_algorithm]),
		"searchLine": common_lib.build_search_line(["module", name, "server_side_encryption_configuration", "rule", "apply_server_side_encryption_by_default", "sse_algorithm"], []),
	}
}


CxPolicy[result] {
	resource := input.document[i].resource.aws_s3_bucket[name]
	ssec := resource.server_side_encryption_configuration
	algorithm := ssec.rule.apply_server_side_encryption_by_default

	not check_master_key(algorithm)
	algorithm.sse_algorithm == "AES256"

	result := {
		"documentId": input.document[i].id,
		"searchKey": sprintf("aws_s3_bucket[%s].server_side_encryption_configuration.rule.apply_server_side_encryption_by_default.kms_master_key_id", [name]),
		"issueType": "IncorrectValue",
		"keyExpectedValue": "server_side_encryption_configuration.rule.apply_server_side_encryption_by_default.kms_master_key_id is null when algorithm is 'AES256'",
		"keyActualValue": "server_side_encryption_configuration.rule.apply_server_side_encryption_by_default.kms_master_key_id is not null when algorithm is 'AES256'",
		"searchLine": common_lib.build_search_line(["resource", "aws_s3_bucket", name, "server_side_encryption_configuration", "rule", "apply_server_side_encryption_by_default", "kms_master_key_id"], []),
	}
}

CxPolicy[result] {
	module := input.document[i].module[name]
	keyToCheck := common_lib.get_module_equivalent_key("aws", module.source, "aws_s3_bucket", "server_side_encryption_configuration")

	ssec := module[keyToCheck]
	algorithm := ssec.rule.apply_server_side_encryption_by_default

	not check_master_key(algorithm)
	algorithm.sse_algorithm == "AES256"

	result := {
		"documentId": input.document[i].id,
		"searchKey": sprintf("module[%s].server_side_encryption_configuration.rule.apply_server_side_encryption_by_default.kms_master_key_id", [name]),
		"issueType": "IncorrectValue",
		"keyExpectedValue": "server_side_encryption_configuration.rule.apply_server_side_encryption_by_default.kms_master_key_id is null when algorithm is 'AES256'",
		"keyActualValue": "server_side_encryption_configuration.rule.apply_server_side_encryption_by_default.kms_master_key_id is not null when algorithm is 'AES256'",
		"searchLine": common_lib.build_search_line(["module", name, "server_side_encryption_configuration", "rule", "apply_server_side_encryption_by_default", "kms_master_key_id"], []),
	}
}

check_master_key(assed) {
	not common_lib.valid_key(assed, "kms_master_key_id")
}

check_master_key(assed) {
	common_lib.emptyOrNull(assed.kms_master_key_id)
}
