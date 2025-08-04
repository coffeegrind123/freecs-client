# Entities

There are the entities present in CS 1.5, notes regarding them.

## armoury_entity

Implemented in `src/server/armoury_entity.qc`

## func_bomb_target

Implemented in `src/server/func_bomb_target.qc`

## func_buyzone

Implemented in `src/server/func_buyzone.qc`

## func_escapezone

Implemented in `src/server/func_escapezone.qc`

## func_grencatch

TO BE IMPLEMENTED

A brush volume that detects grenades entering its volume, triggering
targets when it occurs. The 'grenadetype' key in the entity specifies
either "flash" or "smoke" and will trigger depending on said setting.

Instead of 'target' it respects only the 'triggerongrenade' key as the
target.

A flashbang works only once apparently, the grenade only needs to
touch the trigger (it doesn't need to explode inside of it to trigger
the entity)

## func_hostage_rescue

Implemented in `src/server/func_hostage_rescue.qc`

## func_vip_safetyzone

Implemented in `src/server/func_vip_safetyzone.qc`

## func_weaponcheck

## hostage_entity

Implemented in `src/server/hostage_entity.qc`

## info_bomb_target

Implemented in `src/server/info_bomb_target.qc`

## info_hostage_rescue

Implemented in `src/server/info_hostage_rescue.qc`

## info_map_parameters

Implemented in `src/server/info_map_parameters.qc`

## info_vip_start

Implemented in `src/server/info_vip_start.qc`

## item_thighpack

Bomb Defuse Kit

## weapon_c4

Implemented in `decls/def/weapons/c4.def`

## env_fog

Implemented in Nuclide. 

It is worth noting that DMC has its own variant of this entity, sharing the same name, but with slightly different behaviour.

## func_vehicle

Implemented in Nuclide.

## func_vehiclecontrols

Implemented in Nuclide. 
