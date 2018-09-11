; Ruben Gilbert
; December 9, 2014
;
; Cops and Robbers style game where the goal is to steal the artifacts without being captured by security guards

breed [guards guard]
guards-own []

breed [artifacts artifact]
artifacts-own []

breed [visions vision]
visions-own [target foundWall? foundPlayer?]

turtles-own []
patches-own [wall? myGuard]
globals [player artifact-locations num-guards artifacts-gathered playerCaught? speed score v-range v-angle]

to setup
  ca
  ; setup the world
  import-pcolors "map.png"
  ask patches [
    set wall? false
    if pcolor = 4.3 [set wall? true]
    if wall? = false [set pcolor black]
  ]

  ; make the artifacts
  set artifact-locations []
  set artifact-locations fput patch -125 -129 artifact-locations
  set artifact-locations fput patch -122 -39 artifact-locations
  set artifact-locations fput patch 38 -132 artifact-locations
  set artifact-locations fput patch -36 -118 artifact-locations
  set artifact-locations fput patch -45 39 artifact-locations
  set artifact-locations fput patch 24 5 artifact-locations
  set artifact-locations fput patch 60 40 artifact-locations
  set artifact-locations fput patch 54 130 artifact-locations
  make-artifacts

  ; create the player
  crt 1 [
    set color green
    set size 7
    set player self
    setxy 138 -140        ; hard coded starting location in the bottom right of the world
    set heading 310
  ]

  if mode = "dark" [watch player]   ; adds the effect of sneaking around in a dark area (no other purpose, really)

  ; create the guards based on the difficulty
  if difficulty = "easy" [
    set num-guards 3
    set speed 1
  ]
  if difficulty = "normal" [
    set num-guards 5
    set speed 1.5
  ]
  if difficulty = "hard" [
    set num-guards 7
    set speed 2
  ]
  create-guards num-guards [
    setxy random-xcor random-ycor
    ; prevent spawning on walls, near player, out of bounds, or near another guard
    while [[wall?] of patch-here = true or distance player < 150 or any? other guards in-radius 30 or xcor < min-pxcor + 5 or xcor > max-pxcor - 5 or ycor < min-pycor + 5 or ycor > max-pycor - 5] [
      setxy random-xcor random-ycor
    ]
    set color blue
    set size 7
  ]
  set playerCaught? false
  set artifacts-gathered 0
  set score 0
  ; guard vision range and angle
  set v-range 20
  set v-angle 50
  reset-ticks
end

; OBSERVER
; place the artifacts around the map in predefined areas.  The number of artifacts placed on the map
; is based on the selected difficulty.
to make-artifacts
  let loc1 one-of artifact-locations
  set artifact-locations remove loc1 artifact-locations
  let loc2 one-of artifact-locations
  set artifact-locations remove loc2 artifact-locations
  let loc3 one-of artifact-locations
  set artifact-locations remove loc3 artifact-locations
  let loc4 one-of artifact-locations
  set artifact-locations remove loc4 artifact-locations
  let loc5 one-of artifact-locations
  set artifact-locations remove loc5 artifact-locations
  let loc6 one-of artifact-locations
  set artifact-locations remove loc6 artifact-locations
  let loc7 one-of artifact-locations
  set artifact-locations remove loc7 artifact-locations
  let loc8 one-of artifact-locations
  set artifact-locations remove loc8 artifact-locations

  ; EASY, MEDIUM, OR HARD - at least 1 artifact
  create-artifacts 1 [
    setxy [pxcor] of loc1 [pycor] of loc1
    set shape "star"
    set size 7
    set color orange
  ]

  ; MEDIUM OR HARD - at least 4 artifacts
  if difficulty = "normal" or difficulty = "hard" [
    create-artifacts 1 [
      setxy [pxcor] of loc2 [pycor] of loc2
      set shape "star"
      set size 7
      set color orange
    ]
    create-artifacts 1 [
      setxy [pxcor] of loc3 [pycor] of loc3
      set shape "star"
      set size 7
      set color orange
    ]
    create-artifacts 1 [
      setxy [pxcor] of loc4 [pycor] of loc4
      set shape "star"
      set size 7
      set color orange
    ]
  ]

  ; HARD - 8 artifacts
  if difficulty = "hard" [
    create-artifacts 1 [
      setxy [pxcor] of loc5 [pycor] of loc5
      set shape "star"
      set size 7
      set color orange
    ]
    create-artifacts 1 [
      setxy [pxcor] of loc6 [pycor] of loc6
      set shape "star"
      set size 7
      set color orange
    ]
    create-artifacts 1 [
      setxy [pxcor] of loc7 [pycor] of loc7
      set shape "star"
      set size 7
      set color orange
    ]
    create-artifacts 1 [
      setxy [pxcor] of loc8 [pycor] of loc8
      set shape "star"
      set size 7
      set color orange
    ]
  ]
end

; OBSERVER
; main method to play the game, moves the player and the guards
to move
  ; play game as long as there are artifacts left to gather AND the player has not been caught by a guard
  while [playerCaught? = false and count artifacts > 0] [
    move-player
    move-guards
    adjust-score
  ]

  ifelse playerCaught? = true [
    game-lose
  ]
  [
    game-win
  ]
end

; OBSERVER
; move the player character with the mouse (the player will move towards the mouse's position if it is inside the window)
; Makes for smoother gameplay than buttons
to move-player
  ask player [
    if mouse-inside? and (distancexy mouse-xcor mouse-ycor > 1) [
      facexy mouse-xcor mouse-ycor
      if [wall?] of patch-ahead 1.5 = false [
        fd speed
      ]
    ]
    check-for-artifact
  ]
end

; OBSERVER
; moves guards, displays their vision cones, and has them chase the player if they see him or her
to move-guards
  ask guards [

    ; reset patches to their proper color
    ask patches in-radius (1.5 * v-range) [
      if wall? = false [
        set pcolor black
      ]
    ]

    ; list to keep track of which patches a guard actually has vision of (in their cone of vision)
    let vision-patches []

    ; show the vision range of the guards by illuminating patches
    ask patches in-cone v-range v-angle [
      set myGuard myself
      let v nobody
      ; each patch uses an invisible turtle to detect a wall collision (so each guard doesn't see through walls)
      sprout-visions 1 [
        set foundWall? false
        set target [myGuard] of myself
        set hidden? true
        set v self
      ]

      ; if this patch isn't a wall, check if it is blocked from the guard by a wall
      ifelse wall? = false [
        ask v [check-walls target]
      ]
      [ ; if this patch is already a wall, don't need to check if it is blocked (a wall blocks itself)
        ask v [set foundWall? true]
      ]

      if [foundWall?] of v = false [  ; guard has vision of this patch
        set pcolor yellow
        set vision-patches fput self vision-patches  ; every patch a guard has vision of is inserted into the vision patches list
      ]
    ]

    let playerHere? false  ; temp variable for checking player position relative to guard (from the patch perspective)
    ; check if the player is on one of the patches that the guard has vision of
    ifelse member? player turtles in-cone v-range v-angle and member? (patch [xcor] of player [ycor] of player) vision-patches [
      set playerHere? true
    ]
    [
      set playerHere? false
    ]

    ; if the player is in the guard's vision, chase them
    ifelse playerHere? = true [
      face player
      fd 1.01 * speed                ; GUARD SPEED INCREASES SLIGHTLY WHEN THEY SPOT THE PLAYER
      check-catch                    ; only check if the player has been caught if the guard has vision
    ]
    [ ; else the player is out of vision, continue monitoring the area, guard hasn't found the player
      ; if the guard is in range of an artifact, continue to monitor the area
      rt random 20
      lt random 20
      if [wall?] of patch-ahead 3 = true or any? other guards in-cone 20 60 [  ; avoid walls AND avoid grouping up with other guards
        rt 90
      ]
    ]

    fd .5 * speed
  ]
  ask visions [die]
  tick
end

; VISION TURTLE
; The vision turtle progresses towards its target guard and checks if it walks over a wall at any point.
; If it does walk over a wall, then the guard's vision is obstructed and it can't actually see the patch
; that sprouted the vision turtle.
to check-walls [g]
  while [distance target > 1] [
    face target
    fd 1
    if [wall?] of patch-here = true [
      set foundWall? true
    ]
  ]
end

; PLAYER TURTLE
; checks if the player has found an artifact, adds to the player's score, and removes the artifact from play
to check-for-artifact
  if any? artifacts in-radius 3 [
    ask artifacts in-radius 3 [
      set artifacts-gathered (artifacts-gathered + 1)
      set score score + 100  ; 100 points for stealing an artifact
      die
    ]
  ]
end

; GUARD
; checks to see if the guard has caught up to the player and arrested them
to check-catch
  if distance player < 4 [
    set playerCaught? true
  ]
end

; OBSERVER
; adjusts the player's score based on ticks.  The player is awarded for completing levels faster, so
; every 50 ticks, the player loses 1 points
to adjust-score
  if ticks mod 50 = 0 [
    set score score - 1
  ]
end

; OBSERVER
; end the game and display winning stats
to game-win
  crt 1 [
    setxy 30 0
    set size 0
    set label (word "You win with a score of " score "!")
  ]
end

; OBSERVER
; end the game and display a loss/game over
to game-lose
  crt 1 [
    setxy 40 0
    set size 0
    set label "Game Over!  You were captured."
  ]
end

;----------------------------------------------------------------------------------------------------------------------------------------
; REPORTERS
;----------------------------------------------------------------------------------------------------------------------------------------

to-report num-artifacts
  report count artifacts
end

to-report arts-gather
  report artifacts-gathered
end

to-report rep-score
  report score
end
@#$#@#$#@
GRAPHICS-WINDOW
215
10
825
621
-1
-1
2.0
1
10
1
1
1
0
0
0
1
-150
150
-150
150
0
0
1
ticks
30.0

BUTTON
0
130
63
163
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
0
162
63
195
play
move
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
0
85
138
130
difficulty
difficulty
"easy" "normal" "hard"
2

MONITOR
85
295
191
340
Artifacts Remaining
num-artifacts
17
1
11

MONITOR
2
295
85
340
Artifacts Stolen
arts-gather
17
1
11

CHOOSER
2
250
140
295
mode
mode
"light" "dark"
1

MONITOR
3
340
60
385
Score
rep-score
17
1
11

@#$#@#$#@
## AUTHOR

Ruben Gilbert -- 2014

## WHAT IS IT?

This is a Cops and Robber style game where the player's objective is to steal all of the artifacts in a "museum".  Guards patrol the museum at night to prevent any kind of robbery.  The player's goal is to collect all of the artifacts without being spotted by any guards.  If a guard sees the player, they will chase them as long as the player is within their sight.

## HOW IT WORKS

Guards have a cone of vision from their flashlights (the museum is dark at night).  Player movement is controlled by the mouse (the player character will progress towards the mouse's location as long as its path is not blocked by a wall).  Guards' vision can be blocked by walls (which updates their vision cones).  If a guard sees you, try to break their line of sight by hiding around a wall in the darkness.  Your client is willing to pay $100 per artifact gathered.  But, they are impatient!  They will deduct money from your pay the longer it takes you, so try to steal all the artifacts as quickly as possible.

## HOW TO USE IT

Select a difficulty with the chooser.  Then click "setup" to generate the world, artifacts, and guards.  When you are ready, click "Play".  Guards will begin to patrol the area and the player will be able to move.  

## THINGS TO NOTICE

Guards vision is represented by the cone in front of them.  When a guard walks near a wall, their cone will update to reflect that they cannot see through a wall.

## EXTENDING THE MODEL

I would have liked to include some kind of pathfinding algorithm to make that guards patrol better areas.  But, when I tried to implement the beginning stages of an A* search, Netlogo ran extremely slow.  My world has over 90000 patches, and at higher difficulties there were enough guards to make the search start to lag.  

A better method is probably to have precomputed the shortest distance between all patches before the game begins and then use that data to simply look up shortest paths.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
