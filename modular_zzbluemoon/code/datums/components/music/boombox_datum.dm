
/datum/controller/subsystem/jukeboxes/proc/addboombox(obj/item/device/boombox, datum/track/T, jukefalloff = 1)
	if(!istype(T))
		CRASH("[src] tried to play a song with a nonexistant track")
	var/channeltoreserve = pick(freejukeboxchannels)
	if(!channeltoreserve)
		return FALSE
	freejukeboxchannels -= channeltoreserve
	var/list/youvegotafreejukebox = list(T, channeltoreserve, boombox, jukefalloff)
	activejukeboxes.len++
	activejukeboxes[activejukeboxes.len] = youvegotafreejukebox

	//Due to changes in later versions of 512, SOUND_UPDATE no longer properly plays audio when a file is defined in the sound datum. As such, we are now required to init the audio before we can actually do anything with it.
	//Downsides to this? This means that you can *only* hear the boombox audio if you were present on the server when it started playing, and it means that it's now impossible to add loops to the jukebox track list.
	var/sound/song_to_init = sound(T.song_path)
	song_to_init.status = SOUND_MUTE
	for(var/mob/M in GLOB.player_list)
		if(!M.client)
			continue
		if(!(M.client.prefs.read_preference(/datum/preference/toggle/sound_instruments)))
			continue

		M.playsound_local(M, null, (boombox.volume / 2), channel = youvegotafreejukebox[2], sound_to_use = song_to_init)
	return activejukeboxes.len

/datum/controller/subsystem/jukeboxes/proc/findboomboxindex(obj/item/device/boombox)
	if(length(activejukeboxes))
		for(var/list/jukeinfo in activejukeboxes)
			if(boombox in jukeinfo)
				return activejukeboxes.Find(jukeinfo)
	return FALSE
