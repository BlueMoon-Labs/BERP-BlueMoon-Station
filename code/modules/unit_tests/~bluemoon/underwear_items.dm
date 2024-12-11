#define PATH_REGEX regex("\\/datum\\/sprite_accessory\\/(underwear|undershirt|socks|bra)\\/")

/**
 * This unit test tests underwear items in the game, and makes sure each legacy sprite item corresponds to an underwear item.
 */
/datum/unit_test/underwear_items

	var/list/sprites_to_items_names = list(
		/datum/sprite_accessory/underwear = "BRIEFS",
		/datum/sprite_accessory/undershirt = "SHIRT",
		/datum/sprite_accessory/bra = "BRA",
		/datum/sprite_accessory/socks = "SOCKS"
	)

	var/list/outputs = list(
		briefs = list(),
		shirt = list(),
		socks = list()
	)

	var/list/files_by_type = list( // thanks linux for not using the fucking root directory
		briefs = 'modular_zzbluemoon/code/modules/clothing/underwear/~generated_files/briefs.dm',
		shirt = 'modular_zzbluemoon/code/modules/clothing/underwear/~generated_files/shirt.dm',
		socks = 'modular_zzbluemoon/code/modules/clothing/underwear/~generated_files/socks.dm'
	)

/datum/unit_test/underwear_items/Run()
	outputs["briefs"] = generate_objects_file(/datum/sprite_accessory/underwear)
	outputs["shirt"] = generate_objects_file(/datum/sprite_accessory/undershirt) + generate_objects_file(/datum/sprite_accessory/bra, FALSE)
	outputs["socks"] = generate_objects_file(/datum/sprite_accessory/socks)

	var/fail = FALSE
	for(var/object_type in outputs)
		var/list/lines = outputs[object_type]
		var/output_file = "[lines.Join("\n")]"
		rustg_file_write(output_file, "data/~generated_files/[object_type].dm")
		var/current = file2text(files_by_type[object_type])
		if(current != output_file)
			log_test("[files_by_type[object_type]] is out of date.")
			fail = TRUE

	if(fail)
		TEST_FAIL("Underwear items generated files are out of date. Run locally by enabling unit tests, (see _compile_options.dm) and copy 'data/~generated_files' to 'modular_zzbluemoon/code/modules/clothing/underwear/~generated_files'")

/datum/unit_test/underwear_items/proc/generate_objects_file(datum/sprite_accessory/sprite_type, header = TRUE)
	var/clothing_name = sprites_to_items_names[sprite_type]

	var/list/output = list()
	if(header)
		output += "/* This file is automatically generated by the unit test. Do not edit it manually, use the [LOWER_TEXT(clothing_name)]_edits.dm file instead."
		output += " * Generating this file is done by running the unit test locally, see the fail message for more details."
		output += " * All items corresponding to [sprite_type] should be here."
		output += " */"
	else
		output += "/// [LOWER_TEXT(clothing_name)] section"

	output += ""

	for(var/sprite in subtypesof(sprite_type))
		if(initial(sprite:from_object))
			continue
		var/sprite_name = "[sprite]"
		sprite_name = replacetext(sprite_name, PATH_REGEX, "")
		output += "[clothing_name]_FROM_SPRITE_ACCESSORY([sprite_name])"

	output += ""

	return output

#undef PATH_REGEX
