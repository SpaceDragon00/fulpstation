/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//			TG OVERWRITES

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/// Prevents using a Memento Mori
/obj/item/clothing/neck/necklace/memento_mori/memento(mob/living/carbon/human/user)
	if(IS_BLOODSUCKER(user))
		to_chat(user, "<span class='warning'>The Memento notices your undead soul, and refuses to react..</span>")
		return
	. = ..()

/datum/species/jelly/slime/spec_life(mob/living/carbon/human/H)
	// Prevents Slimeperson 'gaming
	if(HAS_TRAIT(H, TRAIT_NOPULSE))
		return
	. = ..()

/datum/species/jelly/spec_life(mob/living/carbon/human/H)
	// No regeneration for vampires
	if(HAS_TRAIT(H, TRAIT_NOPULSE))
		return
	. = ..()

/// Prevents Bloodsuckers from naturally regenerating Blood - Even while on masquerade
/mob/living/carbon/human/handle_blood(delta_time, times_fired)
	if(IS_BLOODSUCKER(src))
		return
	/// For Vassals -- Bloodsuckers get this removed while on Masquerade, so we don't want to remove the check above.
	if(HAS_TRAIT(src, TRAIT_NOPULSE))
		return
	. = ..()

/mob/living/carbon/natural_bodytemperature_stabilization()
	// Return 0 as your natural temperature. Species proc handle_environment() will adjust your temperature based on this.
	if(HAS_TRAIT(src, TRAIT_COLDBLOODED))
		return 0
	. = ..()

// Overwrites mob/living/life.dm for LifeTick
/mob/living/Life(delta_time = SSMOBS_DT, times_fired)
	. = ..()
	SEND_SIGNAL(src, COMSIG_LIVING_BIOLOGICAL_LIFE, delta_time, times_fired)



// INTEGRATION: Adding Procs and Datums to existing "classes"

/mob/living/proc/HaveBloodsuckerBodyparts(displaymessage = "") // displaymessage can be something such as "rising from death" for Torpid Sleep. givewarningto is the person receiving messages.
	if(!getorganslot(ORGAN_SLOT_HEART))
		if(displaymessage != "")
			to_chat(src, "<span class='warning'>Without a heart, you are incapable of [displaymessage].</span>")
		return FALSE
	if(!get_bodypart(BODY_ZONE_HEAD))
		if(displaymessage != "")
			to_chat(src, "<span class='warning'>Without a head, you are incapable of [displaymessage].</span>")
		return FALSE
	if(!getorgan(/obj/item/organ/brain)) // NOTE: This is mostly just here so we can do one scan for all needed parts when creating a vamp. You probably won't be trying to use powers w/out a brain.
		if(displaymessage != "")
			to_chat(src, "<span class='warning'>Without a brain, you are incapable of [displaymessage].</span>")
		return FALSE
	return TRUE

// EXAMINING
/mob/living/carbon/human/proc/ReturnVampExamine(mob/viewer)
	if(!mind || !viewer.mind)
		return ""
	// Target must be a Vamp
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = mind.has_antag_datum(/datum/antagonist/bloodsucker)
	if(!bloodsuckerdatum)
		return ""
	// Viewer is Target's Vassal?
	if(viewer.mind.has_antag_datum(/datum/antagonist/vassal) in bloodsuckerdatum.vassals)
		var/returnString = "\[<span class='warning'><EM>This is your Master!</EM></span>\]"
		var/returnIcon = "[icon2html('fulp_modules/main_features/bloodsuckers/icons/vampiric.dmi', world, "bloodsucker")]"
		returnString += "\n"
		return returnIcon + returnString
	// Viewer not a Vamp AND not the target's vassal?
	if(!viewer.mind.has_antag_datum((/datum/antagonist/bloodsucker)) && !(viewer in bloodsuckerdatum.vassals))
		return ""
	// Default String
	var/returnString = "\[<span class='warning'><EM>[bloodsuckerdatum.ReturnFullName(1)]</EM></span>\]"
	var/returnIcon = "[icon2html('fulp_modules/main_features/bloodsuckers/icons/vampiric.dmi', world, "bloodsucker")]"

	// In Disguise (Veil)?
	//if (name_override != null)
	//	returnString += "<span class='suicide'> ([real_name] in disguise!) </span>"

	//returnString += "\n"  Don't need spacers. Using . += "" in examine.dm does this on its own.
	return returnIcon + returnString

/mob/living/carbon/human/proc/ReturnVassalExamine(mob/viewer)
	// Am I not even a Vassal? Then I am not marked.
	if(!mind || !viewer.mind)
		return ""
	var/datum/antagonist/vassal/vassaldatum = mind.has_antag_datum(/datum/antagonist/vassal)
	var/datum/antagonist/monsterhunter/monsterhunterdatum = mind.has_antag_datum(/datum/antagonist/monsterhunter)
	if(!vassaldatum || !monsterhunterdatum)
		return ""
	// Vassals and Bloodsuckers recognize eachother, while Monster Hunters can see Vassals.
	if(!IS_BLOODSUCKER(viewer) || !IS_VASSAL(viewer))
		return ""

	// Default String
	var/returnString = "\[<span class='warning'>"
	var/returnIcon = ""
	// Am I Viewer's Vassal?
	if(vassaldatum?.master.owner == viewer.mind)
		returnString += "This [dna.species.name] bears YOUR mark!"
		returnIcon = "[icon2html('fulp_modules/main_features/bloodsuckers/icons/vampiric.dmi', world, "vassal")]"
	// Am I someone ELSE'S Vassal?
	else if(IS_BLOODSUCKER(viewer))
		returnString +=	"This [dna.species.name] bears the mark of <span class='boldwarning'>[vassaldatum.master.ReturnFullName(vassaldatum.master.owner.current,1)]</span>"
		returnIcon = "[icon2html('fulp_modules/main_features/bloodsuckers/icons/vampiric.dmi', world, "vassal_grey")]"
	// Are you serving the same master as I am?
	else if(viewer.mind.has_antag_datum(/datum/antagonist/vassal) in vassaldatum?.master.vassals)
		returnString += "[p_they(TRUE)] bears the mark of your Master"
		returnIcon = "[icon2html('fulp_modules/main_features/bloodsuckers/icons/vampiric.dmi', world, "vassal")]"
	// You serve a different Master than I do.
	else
		returnString += "[p_they(TRUE)] bears the mark of another Bloodsucker"
		returnIcon = "[icon2html('fulp_modules/main_features/bloodsuckers/icons/vampiric.dmi', world, "vassal_grey")]"

	returnString += "</span>\]" // \n"  Don't need spacers. Using . += "" in examine.dm does this on its own.
	return returnIcon + returnString

/// Am I "pale" when examined? - Bloodsuckers on Masquerade will hide this.
/mob/living/carbon/human/proc/ShowAsPaleExamine(mob/user)
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = IS_BLOODSUCKER(user)
	if(bloodsuckerdatum.poweron_masquerade)
		return FALSE
	return TRUE

/*
/mob/living/carbon/proc/scan_blood_volume()
	// Vamps don't show up normally to scanners unless Masquerade power is on ----> scanner.dm
	if(mind)
		var/datum/antagonist/bloodsucker/bloodsuckerdatum = mind.has_antag_datum(/datum/antagonist/bloodsucker)
		if(istype(bloodsuckerdatum) && bloodsuckerdatum.poweron_masquerade)
			return BLOOD_VOLUME_NORMAL
	return blood_volume
*/
