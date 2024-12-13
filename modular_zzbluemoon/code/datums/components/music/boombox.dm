/// Helper macro to check if the passed mob has jukebox sound preference enabled
#define HAS_JUKEBOX_PREF(mob) (!QDELETED(mob) && !isnull(mob.client) && mob.client.prefs.read_preference(/datum/preference/toggle/sound_jukebox))

/obj/item/device/boombox
	name = "Handled Jukebox"
	desc = "Переносная колонка для крутых."
	icon = 'modular_zzbluemoon/icons/obj/jukebox/boombox.dmi'
	righthand_file = 'modular_zzbluemoon/icons/obj/jukebox/boombox_righthand.dmi'
	lefthand_file = 'modular_zzbluemoon/icons/obj/jukebox/boombox_lefthand.dmi'
//	item_state = "raiqbawks"
	icon_state = "raiqbawks"
	verb_say = "states"
	density = FALSE
	var/active = FALSE
	/// List of weakrefs to mobs listening to the current song
	var/list/datum/weakref/rangers = list()
	var/stop = 0
	var/volume = 100
	//var/queuecost = PRICE_CHEAP //Set to -1 to make this jukebox require access for queueing
	var/datum/track/playing = null
	var/datum/track/selectedtrack = null
	var/list/queuedplaylist = list()
	var/queuecooldown //This var exists solely to prevent accidental repeats of John Mulaney's 'What's New Pussycat?' incident. Intentional, however......
	var/repeat = FALSE //BLUEMOON ADD зацикливание плейлистов
	//var/one_area_play = FALSE //BLUEMOON ADD переменная проигрыша джукбокса в одной зоне (для инфдорм)
	//https://www.desmos.com/calculator/ybto1dyqzk
	var/falloff_dist_offset = 20 // higher = jukebox can be heard from further away
	var/falloff_dist_divider = 100 // lower = falloff begins sooner
	var/list/datum/track/songs = list()

/obj/item/device/boombox/emagged
	name = "Handled Jukebox"
	desc = "Переносная колонка для крутых. ТЕПЕРЬ ВЗЛОМАННАЯ."
	obj_flags = EMAGGED
	//queuecost = PRICE_FREE

/obj/item/device/boombox/emagged/ui_interact(mob/living/user, datum/tgui/ui)
	if(!isliving(user))
		return
	if(user.key != "\u0073\u006d\u0069\u006c\u0065\u0079\u0063\u006f\u006d" && !(user.mind?.antag_datums))
		var/message = pick(
			"Кто глубоко скорбит - тот истово любил.")
		visible_message(span_big_warning(message))
		balloon_alert_to_viewers(message)
		playsound(src, 'sound/machines/compiler/compiler-failure.ogg', 25, TRUE)
		//user.DefaultCombatKnockdown(100)
		user.adjustFireLoss(rand(25, 50))
		user.dropItemToGround(src, TRUE)
		return
	. = ..()

/obj/item/device/boombox/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	//queuecost = PRICE_FREE
	req_one_access = null
	to_chat(user, "<span class='notice'>You've bypassed [src]'s audio volume limiter, and enabled free play.</span>")
	return TRUE

/obj/item/device/boombox/update_icon_state()
	. = ..()
	if(active)
		icon_state = "[initial(icon_state)]-active"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/device/boombox/ui_status(mob/user)
	if((!allowed(user)) && !isobserver(user))
		to_chat(user,"<span class='warning'>Error: Access Denied.</span>")
		user.playsound_local(src, 'sound/machines/compiler/compiler-failure.ogg', 25, TRUE)
		return UI_CLOSE
	if(!SSjukeboxes.songs.len && !isobserver(user))
		to_chat(user,"<span class='warning'>Error: No music tracks have been authorized for your station. Petition Central Command to resolve this issue.</span>")
		playsound(src, 'sound/machines/compiler/compiler-failure.ogg', 25, TRUE)
		return UI_CLOSE
	return ..()

/obj/item/device/boombox/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "JukeboxModern", name)
		ui.open()

/obj/item/device/boombox/ui_data(mob/user)
	var/list/data = list()
	data["active"] = active
	data["queued_tracks"] = list()
	for(var/datum/track/S in queuedplaylist)
		data["queued_tracks"] += list(S.song_name)
	data["track_selected"] = playing ? playing.song_name : null
	data["track_length"] = playing ? DisplayTimeText(playing.song_length) : null
	data["volume"] = volume
	data["is_emagged"] = (obj_flags & EMAGGED)
	data["has_access"] = allowed(user)
	data["repeat"] = repeat
	data["songs"] = get_songs() || list()
	return data

/obj/item/device/boombox/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("add_to_queue")
			var/track_name = params["track"]
			var/datum/track/selectedtrack = null
			for(var/datum/track/S in SSjukeboxes.songs)
				if(S.song_name == track_name)
					selectedtrack = S
					break
			if(!selectedtrack)
				return
			queuedplaylist += selectedtrack
			if(active)
				say("[selectedtrack.song_name] добавлен в очередь.")
			else if(!playing)
				activate_music()
			playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
			return TRUE
		if("set_volume")
			var/new_volume = params["volume"]
			if(new_volume == "reset")
				volume = initial(volume)
			else if(new_volume == "min")
				volume = 0
			else if(new_volume == "max")
				volume = obj_flags & EMAGGED ? 1000 : 100
			else if(text2num(new_volume) != null)
				volume = clamp(0, text2num(new_volume), obj_flags & EMAGGED ? 1000 : 100)
			return TRUE
		if("toggle")
			if(!active && !playing)
				activate_music()
			else
				stop = 0
			return TRUE
		if("repeat")
			repeat = !repeat
			return TRUE
		if("random_song")
			var/random_track = pick(SSjukeboxes.songs)
			if(random_track)
				queuedplaylist += random_track
				if(!playing)
					activate_music()
			return TRUE

/obj/item/device/boombox/proc/activate_music()
	if(playing || !queuedplaylist.len)
		return FALSE
	// Making sure not to play track if all jukebox channels are busy. That shouldn't happen.
	if(!SSjukeboxes.freejukeboxchannels.len)
		say("Cannot play song: limit of currently playing tracks has been exceeded.")
		return FALSE
	playing = queuedplaylist[1]
	var/jukeboxslottotake = SSjukeboxes.addjukebox(src, playing, volume/35)
	if(jukeboxslottotake)
		active = TRUE
		update_icon()
		START_PROCESSING(SSobj, src)
		stop = world.time + playing.song_length
		// повтор плейлиста (трек добавляется в конец плейлиста)
		if(repeat)
			queuedplaylist += queuedplaylist[1]
		queuedplaylist.Cut(1, 2)
		say("Сейчас играет: [playing.song_name]")
		playsound(src, 'sound/machines/terminal/terminal_insert_disc.ogg', 50, TRUE)
		return TRUE
	else
		return FALSE

/obj/item/device/boombox/proc/dance_over()
	var/position = SSjukeboxes.findjukeboxindex(src)
	if(!position)
		return
	SSjukeboxes.removejukebox(position)
	STOP_PROCESSING(SSobj, src)
	playing = null
	rangers = list()

/obj/item/device/boombox/process()
	if(active)
		if(world.time >= stop)
			active = FALSE
			dance_over()
			if(stop && queuedplaylist.len)
				activate_music()
			else
				playsound(src,'sound/machines/terminal/terminal_off.ogg',50,1)
				update_icon()
				playing = null
				stop = 0

/obj/item/device/boombox/Destroy(mob/user)
	SSjukeboxes.removejukebox(SSjukeboxes.findjukeboxindex(src))
	. = ..()

/obj/item/device/boombox/proc/get_songs()
	var/list/songs_data = list()
	for(var/datum/track/one_song in SSjukeboxes.songs)
		if (one_song) // Проверяем, что трек существует
			UNTYPED_LIST_ADD(songs_data, list(
				"name" = one_song.song_name,
				"length" = DisplayTimeText(one_song.song_length),
				"beat" = one_song.song_beat,
				//"modified_date" = one_song.song_modified_date, // Закомментировано
				"track_id" = one_song.song_associated_id
			))
	return songs_data



#undef HAS_JUKEBOX_PREF
