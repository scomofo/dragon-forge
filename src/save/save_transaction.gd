class_name SaveTransaction
extends RefCounted

## Mutable staged SaveData copy opened by SaveService.
## Feature systems may mutate staged_save until SaveService commits or rejects it.

var reason: StringName = &""
var slot_id: int = -1
var canonical_path: String = ""
var staged_save: SaveData = null
var post_commit_events: Array[RefCounted] = []
var active: bool = false
