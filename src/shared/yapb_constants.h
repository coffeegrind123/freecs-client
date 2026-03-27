/*
 * YaPB for FreeCS — QuakeC port of YaPB bot AI
 * Based on YaPB by YaPB Project Developers (MIT License)
 *
 * constants.h — Task IDs, difficulty levels, personalities, weapon types
 */

/* Bot tasks — matches YaPB Task enum */
#define TASK_NORMAL          0
#define TASK_PAUSE           1
#define TASK_MOVETOPOSITION  2
#define TASK_FOLLOWUSER      3
#define TASK_PICKUPITEM      4
#define TASK_CAMP            5
#define TASK_PLANTBOMB       6
#define TASK_DEFUSEBOMB      7
#define TASK_ATTACK          8
#define TASK_HUNT            9
#define TASK_SEEKCOVER       10
#define TASK_THROWEXPLOSIVE  11
#define TASK_THROWFLASHBANG  12
#define TASK_THROWSMOKE      13
#define TASK_DOUBLEJUMP      14
#define TASK_ESCAPEFROMBOMB  15
#define TASK_SHOOTBREAKABLE  16
#define TASK_HIDE            17
#define TASK_BLIND           18
#define TASK_SPRAYPAINT      19
#define TASK_MAX             20

/* Task priorities (desire values) — from YaPB TaskPri namespace */
#define TASKPRI_NORMAL        35.0
#define TASKPRI_PAUSE         36.0
#define TASKPRI_CAMP          37.0
#define TASKPRI_SPRAYPAINT    38.0
#define TASKPRI_FOLLOWUSER    39.0
#define TASKPRI_MOVETOPOS     50.0
#define TASKPRI_DEFUSEBOMB    89.0
#define TASKPRI_PLANTBOMB     89.0
#define TASKPRI_ATTACK        90.0
#define TASKPRI_SEEKCOVER     91.0
#define TASKPRI_HIDE          92.0
#define TASKPRI_THROWGRENADE  99.0
#define TASKPRI_DOUBLEJUMP    99.0
#define TASKPRI_ESCAPEFROMBOMB 100.0
#define TASKPRI_SHOOTBREAKABLE 100.0
#define TASKPRI_BLIND         100.0
#define TASKPRI_PICKUPITEM    45.0
#define TASKPRI_HUNT          41.0

/* Personalities — matches YaPB Personality enum */
#define PERSONALITY_NORMAL   0
#define PERSONALITY_RUSHER   1
#define PERSONALITY_CAREFUL  2

/* Difficulty levels — matches YaPB Difficulty enum */
#define DIFFICULTY_NOOB      0
#define DIFFICULTY_EASY      1
#define DIFFICULTY_NORMAL    2
#define DIFFICULTY_HARD      3
#define DIFFICULTY_EXPERT    4

/* Aim flags */
#define AIM_NAVPOINT         (1<<0)
#define AIM_CAMP             (1<<1)
#define AIM_PREDICTENEMY     (1<<2)
#define AIM_LASTENEMY        (1<<3)
#define AIM_ENTITY           (1<<4)
#define AIM_ENEMY            (1<<5)
#define AIM_GRENADE          (1<<6)
#define AIM_OVERRIDE         (1<<7)

/* Sensing states */
#define STATE_SEEING_ENEMY        (1<<0)
#define STATE_HEARING_ENEMY       (1<<1)
#define STATE_SUSPECT_ENEMY       (1<<2)
#define STATE_PICKUP_ITEM         (1<<3)
#define STATE_THROW_HE            (1<<4)
#define STATE_THROW_FB            (1<<5)
#define STATE_THROW_SG            (1<<6)

/* Collision states */
#define COLLISION_UNDECIDED  0
#define COLLISION_PROBING    1
#define COLLISION_NOMOVE     2
#define COLLISION_JUMP       3
#define COLLISION_DUCK       4
#define COLLISION_STRAFELEFT 5
#define COLLISION_STRAFERIGHT 6

/* Weapon types — matches YaPB WeaponType enum */
#define WEAPONTYPE_MELEE     0
#define WEAPONTYPE_PISTOL    1
#define WEAPONTYPE_SHOTGUN   2
#define WEAPONTYPE_ZOOMRIFLE 3
#define WEAPONTYPE_RIFLE     4
#define WEAPONTYPE_SMG       5
#define WEAPONTYPE_SNIPER    6
#define WEAPONTYPE_HEAVY     7

/* Map flags */
#define MAPFLAG_DEMOLITION   (1<<0)
#define MAPFLAG_HOSTAGE      (1<<1)
#define MAPFLAG_ASSASSINATION (1<<2)
#define MAPFLAG_ESCAPE       (1<<3)
#define MAPFLAG_KNIFEARENA   (1<<4)
#define MAPFLAG_FIGHTYARD    (1<<5)

/* Goal tactics */
#define TACTIC_DEFENSIVE     0
#define TACTIC_CAMP          1
#define TACTIC_OFFENSIVE     2
#define TACTIC_GOAL          3
#define TACTIC_RESCUE        4
