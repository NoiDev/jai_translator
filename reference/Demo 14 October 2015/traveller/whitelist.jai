// We put the whitelists in one separate, very simple file,
// so that they are easy to audit!

// If you see a change to the whitelist file come through source control,
// you know to pay attention!

is_whitelisted_for_entity_pointers :: (owner : *Type_Info_Struct, member: *Type_Info_Struct_Member) -> bool {
    if owner.name == "Entity_Manager" return true;
    if owner.name == "Bullet" && member.name == "emitter" return true;   // To do: Refactor so we don't need this any more!
    
    return false;
}
