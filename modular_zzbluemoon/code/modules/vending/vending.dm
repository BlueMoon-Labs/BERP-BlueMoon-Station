// Taken from Modular Vending in Bubber
// All entries will become null after Initialize, to free up memory.

/obj/machinery/vending
	// Additions to the `products` list
	var/list/zzbluemoon_products
	// Additions to the `product_categories` list
	var/list/zzbluemoon_product_categories
	// Additions to the `premium` list
	var/list/zzbluemoon_premium
	// Additions to the `contraband` list
	var/list/zzbluemoon_contraband

/obj/machinery/vending/Initialize(mapload)
	if(zzbluemoon_products)
		// We need this, because duplicates screw up the spritesheet!
		for(var/item_to_add in zzbluemoon_products)
			products[item_to_add] = zzbluemoon_products[item_to_add]

	if(zzbluemoon_product_categories)
		for(var/category in zzbluemoon_product_categories)
			var/already_exists = FALSE
			for(var/existing_category in product_categories)
				if(existing_category["name"] == category["name"])
					existing_category["products"] += category["products"]
					already_exists = TRUE
					break

			if(!already_exists)
				product_categories += category

	if(zzbluemoon_premium)
		// We need this, because duplicates screw up the spritesheet!
		for(var/item_to_add in zzbluemoon_premium)
			premium[item_to_add] = zzbluemoon_premium[item_to_add]

	if(zzbluemoon_contraband)
		// We need this, because duplicates screw up the spritesheet!
		for(var/item_to_add in zzbluemoon_contraband)
			contraband[item_to_add] = zzbluemoon_contraband[item_to_add]

	QDEL_NULL(zzbluemoon_products)
	QDEL_NULL(zzbluemoon_product_categories)
	QDEL_NULL(zzbluemoon_premium)
	QDEL_NULL(zzbluemoon_contraband)
	return ..()
